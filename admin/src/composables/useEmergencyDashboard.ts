import Echo from 'laravel-echo'
import Pusher from 'pusher-js'
import { computed, ref, watch } from 'vue'
import type { DashboardStats, EmergencyAlert, EmergencyCommitment, Hospital, Province, SosPayload, Ward } from '../types'

interface DashboardResponse {
  data: {
    hospitals: Hospital[]
    stats: DashboardStats
    alerts: EmergencyAlert[]
    commitments: EmergencyCommitment[]
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
    arrived_donors: 0,
  })
  const selectedHospitalId = ref<number | null>(null)
  const isLoading = ref(false)
  const echo = ref<Echo<'reverb'> | null>(null)

  const selectedHospital = computed(() =>
    hospitals.value.find((hospital) => hospital.id === selectedHospitalId.value) ?? hospitals.value[0],
  )
  const activeAlerts = computed(() => alerts.value.filter((alert) => alert.status === 'active'))
  const activeAlert = computed(() => activeAlerts.value[0] ?? null)
  const notifiedDonorsCount = computed(() => stats.value.notified_donors)
  const committedDonorsCount = computed(() => stats.value.committed_donors)
  const arrivedDonorsCount = computed(() => stats.value.arrived_donors)

  async function loadDashboard() {
    isLoading.value = true
    try {
      const params = selectedHospitalId.value ? `?hospital_id=${selectedHospitalId.value}` : ''
      const response = await fetch(`${apiBaseUrl}/api/admin/dashboard${params}`)
      const payload = (await response.json()) as DashboardResponse
      hospitals.value = payload.data.hospitals
      stats.value = payload.data.stats
      alerts.value = payload.data.alerts
      commitments.value = payload.data.commitments
      selectedHospitalId.value = selectedHospitalId.value ?? hospitals.value[0]?.id ?? null
      connectRealtime()
    } finally {
      isLoading.value = false
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
    const created = (await response.json()) as { data: EmergencyAlert }
    upsertAlert(created.data)
    await loadDashboard()
  }

  function connectRealtime() {
    if (!selectedHospitalId.value || echo.value) return

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
      .channel(`hospital.${selectedHospitalId.value}`)
      .listen('.emergency.alert.activated', (event: { alert: EmergencyAlert }) => {
        upsertAlert(event.alert)
        stats.value.active_alerts = alerts.value.filter((alert) => alert.status === 'active').length
        stats.value.notified_donors = alerts.value.reduce(
          (total, alert) => total + (alert.recipients?.length ?? 0),
          0,
        )
      })
      .listen('.emergency.commitment.updated', (event: { commitment: EmergencyCommitment }) => {
        upsertCommitment(event.commitment)
        stats.value.committed_donors = commitments.value.length
        stats.value.arrived_donors = commitments.value.filter((commitment) => commitment.status === 'arrived').length
      })
  }

  function upsertAlert(alert: EmergencyAlert) {
    const index = alerts.value.findIndex((item) => item.id === alert.id)
    if (index >= 0) alerts.value[index] = alert
    else alerts.value.unshift(alert)
  }

  function upsertCommitment(commitment: EmergencyCommitment) {
    const index = commitments.value.findIndex((item) => item.id === commitment.id)
    if (index >= 0) commitments.value[index] = commitment
    else commitments.value.unshift(commitment)
  }

  watch(selectedHospital, () => {
    if (!echo.value) return
    echo.value.disconnect()
    echo.value = null
    connectRealtime()
  })

  return {
    hospitals,
    provinces,
    wardsByProvince,
    alerts,
    activeAlerts,
    activeAlert,
    commitments,
    stats,
    notifiedDonorsCount,
    committedDonorsCount,
    arrivedDonorsCount,
    selectedHospitalId,
    selectedHospital,
    isLoading,
    loadDashboard,
    loadProvinces,
    loadWards,
    activateSos,
  }
}

declare global {
  interface Window {
    Pusher: typeof Pusher
  }
}
