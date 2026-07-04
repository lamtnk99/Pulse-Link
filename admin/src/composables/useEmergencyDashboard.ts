import Echo from 'laravel-echo'
import Pusher from 'pusher-js'
import { computed, ref, watch } from 'vue'
import type {
  AdminUser,
  DashboardStats,
  EmergencyAlert,
  EmergencyCommitment,
  BloodJourney,
  Hospital,
  Province,
  SosPayload,
  Ward,
} from '../types'

interface DashboardResponse {
  data: {
    hospitals: Hospital[]
    stats: DashboardStats
    alerts: EmergencyAlert[]
    commitments: EmergencyCommitment[]
    current_admin?: AdminUser
  }
}

export function useEmergencyDashboard(apiBaseUrl: string) {
  const hospitals = ref<Hospital[]>([])
  const provinces = ref<Province[]>([])
  const wardsByProvince = ref<Record<string, Ward[]>>({})
  const alerts = ref<EmergencyAlert[]>([])
  const commitments = ref<EmergencyCommitment[]>([])
  const stats = ref<DashboardStats>({
    active_alerts: 0,
    notified_donors: 0,
    committed_donors: 0,
    donated_donors: 0,
    upcoming_events: 0,
    scheduled_appointments: 0,
    completed_appointments: 0,
    verified_volume_ml: 0,
  })
  const currentAdmin = ref<AdminUser | null>(null)
  const selectedHospitalId = ref<number | null>(null)
  const selectedAlertId = ref<string | null>(null)
  const isLoading = ref(false)
  const echo = ref<Echo<'reverb'> | null>(null)
  let dashboardRequestId = 0

  const normalizedSelectedHospitalId = computed(() => {
    if (selectedHospitalId.value === null) return null
    const id = Number(selectedHospitalId.value)
    return Number.isFinite(id) ? id : null
  })
  const selectedHospital = computed(() =>
    hospitals.value.find((hospital) => hospital.id === normalizedSelectedHospitalId.value) ?? hospitals.value[0],
  )
  const visibleAlerts = computed(() =>
    alerts.value.filter((alert) => alertBelongsToSelectedHospital(alert)),
  )
  const visibleCommitments = computed(() =>
    commitments.value.filter((commitment) => visibleAlerts.value.some((alert) => alert.id === commitment.alert_id)),
  )
  const activeAlerts = computed(() =>
    visibleAlerts.value.filter((alert) => ['active', 'fulfilled'].includes(alert.status)),
  )
  const activeAlert = computed(() =>
    activeAlerts.value.find((alert) => alert.id === selectedAlertId.value) ?? activeAlerts.value[0] ?? null,
  )
  const activeAlertCommitments = computed(() =>
    activeAlert.value
      ? visibleCommitments.value.filter((commitment) => commitment.alert_id === activeAlert.value?.id)
      : [],
  )
  const notifiedDonorsCount = computed(() => stats.value.notified_donors)
  const committedDonorsCount = computed(() => stats.value.committed_donors)

  async function loadDashboard() {
    const requestId = ++dashboardRequestId
    isLoading.value = true
    try {
      const params = normalizedSelectedHospitalId.value ? `?hospital_id=${normalizedSelectedHospitalId.value}` : ''
      const response = await fetch(`${apiBaseUrl}/api/admin/dashboard${params}`)
      const payload = (await response.json()) as DashboardResponse
      if (requestId !== dashboardRequestId) return

      hospitals.value = payload.data.hospitals
      stats.value = payload.data.stats
      alerts.value = payload.data.alerts
      commitments.value = payload.data.commitments
      currentAdmin.value = payload.data.current_admin ?? null
      selectedHospitalId.value = selectedHospitalId.value ?? hospitals.value[0]?.id ?? null
      syncSelectedAlert()
      connectRealtime()
    } finally {
      if (requestId === dashboardRequestId) {
        isLoading.value = false
      }
    }
  }

  async function loadProvinces() {
    const response = await fetch(`${apiBaseUrl}/api/locations/provinces`)
    const payload = (await response.json()) as { data: Province[] }
    provinces.value = payload.data
  }

  async function loadWards(provinceCode: string) {
    if (wardsByProvince.value[provinceCode]) return wardsByProvince.value[provinceCode]

    const response = await fetch(`${apiBaseUrl}/api/locations/provinces/${provinceCode}/wards`)
    const payload = (await response.json()) as { data: Ward[] }
    wardsByProvince.value = {
      ...wardsByProvince.value,
      [provinceCode]: payload.data,
    }

    return payload.data
  }

  async function activateSos(payload: SosPayload) {
    const response = await fetch(`${apiBaseUrl}/api/admin/emergency-alerts`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(await resolveApiError(response, 'Không thể phát lệnh SOS.'))

    const created = (await response.json()) as { data: EmergencyAlert }
    upsertAlert(created.data)
    selectedAlertId.value = created.data.id
    await loadDashboard()
  }

  async function cancelSos(alert: EmergencyAlert) {
    const response = await fetch(`${apiBaseUrl}/api/admin/emergency-alerts/${alert.id}/cancel`, {
      method: 'POST',
      headers: { Accept: 'application/json' },
    })
    if (!response.ok) throw new Error(await resolveApiError(response, 'Không thể hủy ca SOS.'))

    const payload = (await response.json()) as { data: EmergencyAlert }
    upsertAlert(payload.data)
    syncSelectedAlert()
    await loadDashboard()
  }

  async function completeSos(alert: EmergencyAlert) {
    const response = await fetch(`${apiBaseUrl}/api/admin/emergency-alerts/${alert.id}/complete`, {
      method: 'POST',
      headers: { Accept: 'application/json' },
    })
    if (!response.ok) throw new Error(await resolveApiError(response, 'Không thể hoàn thành ca SOS.'))

    const payload = (await response.json()) as { data: EmergencyAlert }
    upsertAlert(payload.data)
    syncSelectedAlert()
    await loadDashboard()
  }

  async function markCommitmentDonated(alert: EmergencyAlert, commitment: EmergencyCommitment, volumeMl: number) {
    const response = await fetch(`${apiBaseUrl}/api/admin/emergency-alerts/${alert.id}/commitments/${commitment.id}/donated`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ volume_ml: volumeMl }),
    })
    if (!response.ok) throw new Error(await resolveApiError(response, 'Không thể xác nhận hiến máu SOS.'))

    const payload = (await response.json()) as { data: EmergencyCommitment }
    upsertCommitment(payload.data)
    await loadDashboard()
  }

  async function updateCommitmentJourney(
    alert: EmergencyAlert,
    commitment: EmergencyCommitment,
    payload: {
      destination_type?: 'patient' | 'reserve'
      current_step?: string
      location_label?: string
      publish?: boolean
    },
  ) {
    const response = await fetch(`${apiBaseUrl}/api/admin/emergency-alerts/${alert.id}/commitments/${commitment.id}/journey`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(payload),
    })
    if (!response.ok) throw new Error(await resolveApiError(response, 'Không thể cập nhật hành trình giọt máu.'))

    const result = (await response.json()) as { data: BloodJourney }
    upsertCommitment({
      ...commitment,
      blood_journey: result.data,
    })
    await loadDashboard()
  }

  async function resolveApiError(response: Response, fallback: string) {
    try {
      const payload = await response.json() as { message?: string; errors?: Record<string, string[]> }
      const firstFieldError = payload.errors ? Object.values(payload.errors)[0]?.[0] : null
      return firstFieldError ?? payload.message ?? fallback
    } catch {
      return fallback
    }
  }

  function selectAlert(alertId: string) {
    selectedAlertId.value = alertId
  }

  function connectRealtime() {
    if (!normalizedSelectedHospitalId.value || echo.value) return

    window.Pusher = Pusher
    echo.value = new Echo({
      broadcaster: 'reverb',
      key: import.meta.env.VITE_REVERB_APP_KEY ?? 'pulse-link-key',
      wsHost: import.meta.env.VITE_REVERB_HOST ?? '127.0.0.1',
      wsPort: Number(import.meta.env.VITE_REVERB_PORT ?? 8080),
      wssPort: Number(import.meta.env.VITE_REVERB_PORT ?? 8080),
      forceTLS: (import.meta.env.VITE_REVERB_SCHEME ?? 'http') === 'https',
      enabledTransports: ['ws', 'wss'],
    })

    echo.value
      .channel(`hospital.${normalizedSelectedHospitalId.value}`)
      .listen('.emergency.alert.activated', (event: { alert: EmergencyAlert }) => {
        if (!alertBelongsToSelectedHospital(event.alert)) return
        upsertAlert(event.alert)
        selectedAlertId.value = event.alert.id
        stats.value.active_alerts = activeAlerts.value.length
        stats.value.notified_donors = visibleAlerts.value.reduce(
          (total, alert) => total + (alert.recipients?.length ?? 0),
          0,
        )
      })
      .listen('.emergency.commitment.updated', (event: { commitment: EmergencyCommitment }) => {
        if (!activeAlerts.value.some((alert) => alert.id === event.commitment.alert_id)) return
        upsertCommitment(event.commitment)
        stats.value.committed_donors = visibleCommitments.value.filter((commitment) => commitment.status !== 'cancelled').length
        stats.value.donated_donors = visibleCommitments.value.filter((commitment) => commitment.status === 'donated').length
      })
  }

  function upsertAlert(alert: EmergencyAlert) {
    const index = alerts.value.findIndex((item) => item.id === alert.id)
    if (index >= 0) alerts.value[index] = alert
    else alerts.value.unshift(alert)
    syncSelectedAlert()
  }

  function upsertCommitment(commitment: EmergencyCommitment) {
    const index = commitments.value.findIndex((item) => item.id === commitment.id)
    if (index >= 0) commitments.value[index] = commitment
    else commitments.value.unshift(commitment)
  }

  function syncSelectedAlert() {
    if (activeAlerts.value.some((alert) => alert.id === selectedAlertId.value)) return
    selectedAlertId.value = activeAlerts.value[0]?.id ?? null
  }

  function alertBelongsToSelectedHospital(alert: EmergencyAlert) {
    const hospitalId = normalizedSelectedHospitalId.value
    if (!hospitalId) return true

    return Number(alert.hospital?.id) === hospitalId
  }

  watch(selectedHospital, () => {
    selectedAlertId.value = null
    if (!echo.value) return
    echo.value.disconnect()
    echo.value = null
    connectRealtime()
  })

  return {
    hospitals,
    provinces,
    wardsByProvince,
    alerts: visibleAlerts,
    activeAlerts,
    activeAlert,
    activeAlertCommitments,
    commitments,
    stats,
    currentAdmin,
    notifiedDonorsCount,
    committedDonorsCount,
    selectedHospitalId,
    selectedHospital,
    selectedAlertId,
    isLoading,
    loadDashboard,
    loadProvinces,
    loadWards,
    activateSos,
    cancelSos,
    completeSos,
    markCommitmentDonated,
    updateCommitmentJourney,
    selectAlert,
  }
}

declare global {
  interface Window {
    Pusher: typeof Pusher
  }
}
