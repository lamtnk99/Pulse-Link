<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { AlertTriangle, ArrowLeft, BadgeCheck, CheckCircle2, History, MapPinned, Radio, ShieldAlert, XCircle } from '@lucide/vue'
import AlertTimeline from '../components/AlertTimeline.vue'
import LiveTrackingMap from '../components/LiveTrackingMap.vue'
import type { DashboardStats, EmergencyAlert, EmergencyCommitment } from '../types'

const props = defineProps<{
  alerts: EmergencyAlert[]
  activeAlerts: EmergencyAlert[]
  activeAlert: EmergencyAlert | null
  selectedAlertId: string | null
  commitments: EmergencyCommitment[]
  stats: DashboardStats
  isLoading: boolean
}>()

const emit = defineEmits<{
  openSos: []
  selectAlert: [alertId: string]
  cancelAlert: [alert: EmergencyAlert]
  completeAlert: [alert: EmergencyAlert]
  markCommitmentDonated: [alert: EmergencyAlert, commitment: EmergencyCommitment, volumeMl: number]
  updateCommitmentJourney: [alert: EmergencyAlert, commitment: EmergencyCommitment, payload: { destination_type?: 'patient' | 'reserve'; current_step?: string; location_label?: string; publish?: boolean }]
}>()

const waveSummary = computed(() => props.activeAlert?.dispatch_summary ?? {})
const donationVolumes = reactive<Record<number, number>>({})
const donationVolumeOptions = [250, 350, 450]
const editingJourneyCommitment = ref<EmergencyCommitment | null>(null)
const showCompletedModal = ref(false)

const selectedCompletedAlertId = ref<string | null>(null)
const selectedCompletedAlert = computed(() => {
  if (!selectedCompletedAlertId.value) return null
  return props.alerts.find((alert) => alert.id === selectedCompletedAlertId.value) ?? null
})

function selectCompletedAlert(alertId: string) {
  selectedCompletedAlertId.value = alertId
}

function closeCompletedModal() {
  showCompletedModal.value = false
  selectedCompletedAlertId.value = null
}

function markCompletedAlertDonated(alert: EmergencyAlert, commitment: EmergencyCommitment) {
  const volume = donationVolumes[commitment.id] ?? 350
  emit('markCommitmentDonated', alert, commitment, volume)
}

function getJourneyStepLabel(commitment: EmergencyCommitment) {
  const journey = commitment.blood_journey
  if (!journey) return 'Chưa khởi tạo'
  
  const step = journey.steps?.find((s) => s.key === journey.current_step)
  if (step) return step.label

  const stepLabels: Record<string, string> = {
    received: 'Đã tiếp nhận',
    quality_check: 'Đang kiểm tra chất lượng',
    emergency_transport: 'Đang vận chuyển cấp cứu',
    transfused: 'Đã truyền thành công',
    stored: 'Đã lưu trữ an toàn',
  }
  return stepLabels[journey.current_step] ?? journey.current_step
}

function isJourneyCompleted(commitment: EmergencyCommitment) {
  const journey = commitment.blood_journey
  if (!journey) return false
  if (journey.destination_type === 'reserve') {
    return journey.current_step === 'stored'
  }
  return journey.current_step === 'transfused'
}
const journeyForm = reactive({
  destination_type: 'patient' as 'patient' | 'reserve',
  current_step: 'received',
  location_label: '',
  publish: true,
})

const isStepDisabled = (stepKey: string) => {
  const currentJourneyStep = editingJourneyCommitment.value?.blood_journey?.current_step ?? 'received'
  const options = journeyStepOptions.value
  const currentIndex = options.findIndex(opt => opt.key === currentJourneyStep)
  const optionIndex = options.findIndex(opt => opt.key === stepKey)
  
  const destinationTypeChanged = journeyForm.destination_type !== (editingJourneyCommitment.value?.blood_journey?.destination_type ?? 'patient')
  if (destinationTypeChanged) return false
  
  return optionIndex < currentIndex
}
const commitmentStatusLabels: Record<EmergencyCommitment['status'], string> = {
  committed: 'Đã cam kết',
  en_route: 'Đang di chuyển',
  donated: 'Đã hiến',
  cancelled: 'Đã hủy',
  not_needed: 'Ca đã đủ',
}
const selectedAlertStats = computed(() => {
  const alert = props.activeAlert
  const commitments = props.commitments ?? []

  return {
    active_alerts: alert?.status === 'active' ? 1 : 0,
    notified_donors: alert ? (alert.dispatch_summary?.recipient_count ?? alert.recipients?.length ?? 0) : 0,
    committed_donors: commitments.filter((commitment) => !['cancelled', 'not_needed'].includes(commitment.status)).length,
    donated_donors: commitments.filter((commitment) => commitment.status === 'donated').length,
  }
})
const journeyStepOptions = computed(() => {
  if (journeyForm.destination_type === 'reserve') {
    return [
      { key: 'received', label: 'Đã tiếp nhận' },
      { key: 'quality_check', label: 'Đang kiểm tra chất lượng' },
      { key: 'stored', label: 'Đã lưu trữ an toàn tại kho máu bệnh viện/quốc gia' },
    ]
  }

  return [
    { key: 'received', label: 'Đã tiếp nhận' },
    { key: 'quality_check', label: 'Đang kiểm tra chất lượng' },
    { key: 'emergency_transport', label: 'Đang vận chuyển cấp cứu' },
    { key: 'transfused', label: 'Đã truyền cho bệnh nhân thành công' },
  ]
})

const completedAlerts = computed(() =>
  props.alerts.filter((alert) => alert.status === 'fulfilled')
)

watch(
  () => props.commitments,
  (commitments) => {
    commitments.forEach((commitment) => {
      donationVolumes[commitment.id] = commitment.donation_volume_ml ?? donationVolumes[commitment.id] ?? 350
    })
  },
  { immediate: true },
)

function formatAlertTime(value: string) {
  return new Intl.DateTimeFormat('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    day: '2-digit',
    month: '2-digit',
    hour12: false,
  }).format(new Date(value))
}

function markDonated(commitment: EmergencyCommitment) {
  if (!props.activeAlert) return
  const volume = normalizeDonationVolume(commitment.id)
  emit('markCommitmentDonated', props.activeAlert, commitment, volume)
}

function normalizeDonationVolume(commitmentId: number) {
  const rawValue = Number(donationVolumes[commitmentId] ?? 350)
  const volume = donationVolumeOptions.includes(rawValue) ? rawValue : 350
  donationVolumes[commitmentId] = volume
  return volume
}

function donatedCount(alert: EmergencyAlert) {
  return alert.commitments?.filter((commitment) => commitment.status === 'donated').length ?? 0
}

function hasSuccessfulDonation(alert: EmergencyAlert) {
  return donatedCount(alert) > 0
}

function compatibilityModeLabel(alert: EmergencyAlert) {
  return alert.compatibility_mode === 'exact' ? 'Đúng nhóm' : 'Mở rộng tương thích'
}

function broadcastStopped(alert: EmergencyAlert) {
  return alert.status === 'active' && alert.accepting_commitments === false
}

function openJourney(commitment: EmergencyCommitment) {
  editingJourneyCommitment.value = commitment
  journeyForm.destination_type = commitment.blood_journey?.destination_type ?? 'patient'
  journeyForm.current_step = commitment.blood_journey?.current_step ?? 'received'
  journeyForm.location_label = commitment.blood_journey?.location_label ?? props.activeAlert?.hospital?.name ?? ''
  journeyForm.publish = true
}

function closeJourney() {
  editingJourneyCommitment.value = null
}

function saveJourney() {
  if (!editingJourneyCommitment.value) return
  const alert = props.alerts.find((a) => a.id === editingJourneyCommitment.value?.alert_id)
  if (!alert) return
  emit('updateCommitmentJourney', alert, editingJourneyCommitment.value, {
    destination_type: journeyForm.destination_type,
    current_step: journeyForm.current_step,
    location_label: journeyForm.location_label,
    publish: true,
  })
  closeJourney()
}
</script>

<template>
  <div class="space-y-5">
    <section class="flex flex-col gap-4 rounded-lg border border-red-100 bg-red-50 p-4 md:flex-row md:items-center md:justify-between">
      <div class="flex items-start gap-3">
        <div class="grid h-10 w-10 place-items-center rounded-md bg-white text-[#E31837]">
          <ShieldAlert class="h-5 w-5" />
        </div>
        <div>
          <p class="text-xs font-black uppercase tracking-[0.22em] text-[#E31837]">Điều phối khẩn cấp</p>
          <h2 class="mt-1 text-xl font-black text-red-950">Bảng giám sát báo động đỏ</h2>
          <p class="mt-1 text-sm text-red-700">Theo dõi tuyến di chuyển, cam kết hiến máu và các vòng phát lệnh SOS.</p>
        </div>
      </div>
      <button
        class="inline-flex h-10 items-center justify-center gap-2 rounded-md bg-[#E31837] px-4 text-xs font-black uppercase tracking-wide text-white shadow-sm shadow-red-500/20 transition hover:bg-red-700 active:scale-[0.98]"
        @click="emit('openSos')"
      >
        <AlertTriangle class="h-4 w-4" />
        Phát lệnh SOS
      </button>
    </section>

    <section class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <div class="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div>
          <h3 class="text-base font-black text-slate-950">Ca SOS đang mở</h3>
          <p class="mt-1 text-xs font-bold text-slate-500">Một bệnh viện có thể phát nhiều ca song song; chọn ca để xem map, sóng và cam kết riêng.</p>
        </div>
        <span class="rounded-full bg-red-50 px-3 py-1 text-xs font-black uppercase text-[#E31837]">
          {{ activeAlerts.length }} ca active
        </span>
        <button
          class="inline-flex h-8 items-center gap-1.5 rounded-md border border-slate-200 bg-white px-3 text-xs font-bold text-slate-700 shadow-sm hover:bg-slate-50 transition"
          @click="showCompletedModal = true"
        >
          <History class="h-3.5 w-3.5 text-slate-500" />
          Lịch sử ca SOS
        </button>
      </div>

      <div v-if="activeAlerts.length" class="mt-4 grid gap-3 lg:grid-cols-2">
        <article
          v-for="alert in activeAlerts"
          :key="alert.id"
          class="cursor-pointer rounded-lg border p-3 transition"
          :class="alert.id === selectedAlertId ? 'border-[#E31837] bg-red-50' : 'border-slate-200 bg-white hover:bg-slate-50'"
          @click="emit('selectAlert', alert.id)"
        >
          <div class="flex items-start justify-between gap-3">
            <div>
              <p class="font-black text-slate-950">{{ alert.hospital?.name ?? 'Bệnh viện' }}</p>
              <p class="mt-1 text-xs font-bold text-slate-500">
                {{ alert.required_blood_type }} · {{ alert.units_needed }} đơn vị · {{ formatAlertTime(alert.created_at) }}
              </p>
            </div>
            <div class="flex shrink-0 flex-wrap justify-end gap-2">
              <button
                class="inline-flex h-8 items-center gap-1 rounded-md border border-emerald-100 bg-emerald-50 px-2 text-[11px] font-black uppercase text-emerald-700 hover:bg-white"
                @click.stop="emit('completeAlert', alert)"
              >
                <CheckCircle2 class="h-3.5 w-3.5" />
                Hoàn thành
              </button>
              <button
                class="inline-flex h-8 items-center gap-1 rounded-md border px-2 text-[11px] font-black uppercase"
                :class="hasSuccessfulDonation(alert)
                  ? 'cursor-not-allowed border-slate-200 bg-slate-100 text-slate-400'
                  : 'border-red-100 text-[#E31837] hover:bg-white'"
                :disabled="hasSuccessfulDonation(alert)"
                :title="hasSuccessfulDonation(alert) ? 'Đã có người hiến máu thành công. Hãy hoàn thành ca SOS.' : 'Hủy ca SOS'"
                @click.stop="emit('cancelAlert', alert)"
              >
                <XCircle class="h-3.5 w-3.5" />
                {{ hasSuccessfulDonation(alert) ? 'Chỉ hoàn thành' : 'Hủy' }}
              </button>
            </div>
          </div>
          <p class="mt-2 line-clamp-2 text-sm text-slate-600">{{ alert.message }}</p>
          <div class="mt-3 flex flex-wrap gap-2">
            <span class="rounded bg-slate-100 px-2 py-1 text-[11px] font-bold text-slate-600">
              Nhận tin: {{ alert.dispatch_summary?.recipient_count ?? alert.recipients?.length ?? 0 }}
            </span>
            <span class="rounded bg-emerald-50 px-2 py-1 text-[11px] font-bold text-emerald-700">
              Cam kết: {{ alert.commitments?.length ?? 0 }}
            </span>
            <span
              class="rounded px-2 py-1 text-[11px] font-bold"
              :class="alert.status === 'fulfilled' ? 'bg-amber-50 text-amber-700' : 'bg-red-50 text-red-700'"
            >
              Đã hiến: {{ donatedCount(alert) }}/{{ alert.units_needed }}
            </span>
            <span v-if="alert.status === 'fulfilled'" class="rounded bg-emerald-50 px-2 py-1 text-[11px] font-black uppercase text-emerald-700">
              Đã đủ máu
            </span>
            <span v-else-if="broadcastStopped(alert)" class="rounded bg-amber-50 px-2 py-1 text-[11px] font-black uppercase text-amber-700">
              Đã đủ · Ngừng phát
            </span>
            <span class="rounded bg-blue-50 px-2 py-1 text-[11px] font-bold text-blue-700">
              {{ compatibilityModeLabel(alert) }}
            </span>
          </div>
        </article>
      </div>

      <p v-else class="mt-4 rounded-md border border-dashed border-slate-200 p-6 text-center text-sm text-slate-500">
        Chưa có ca SOS nào đang hoạt động trong phạm vi bệnh viện hiện tại.
      </p>
    </section>



    <section class="grid gap-4 md:grid-cols-4">
      <div class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Đang hoạt động</p>
        <p class="mt-2 text-2xl font-black text-[#E31837]">{{ selectedAlertStats.active_alerts }}</p>
      </div>
      <div class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Đã thông báo</p>
        <p class="mt-2 text-2xl font-black text-slate-950">{{ selectedAlertStats.notified_donors }}</p>
      </div>
      <div class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Đã cam kết</p>
        <p class="mt-2 text-2xl font-black text-emerald-600">{{ selectedAlertStats.committed_donors }}</p>
      </div>
      <div class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Đã hiến</p>
        <p class="mt-2 text-2xl font-black text-amber-600">{{ selectedAlertStats.donated_donors }}</p>
      </div>
    </section>

    <section class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <div class="flex flex-col gap-2 md:flex-row md:items-center md:justify-between">
        <div>
          <h3 class="text-base font-black text-slate-950">Người đã cam kết</h3>
          <p class="mt-1 text-xs font-bold text-slate-500">Xác nhận hiến thành công để lưu lịch sử, điểm và chứng chỉ SOS cho người hiến.</p>
        </div>
        <span class="rounded-full bg-slate-100 px-3 py-1 text-xs font-black uppercase text-slate-500">
          {{ activeAlert ? activeAlert.required_blood_type : '--' }}
        </span>
      </div>
      <div v-if="activeAlert && commitments.length" class="mt-4 overflow-hidden rounded-lg border border-slate-200">
        <div
          v-for="commitment in commitments"
          :key="commitment.id"
          class="grid min-h-28 gap-3 border-b border-slate-100 p-4 last:border-b-0 lg:grid-cols-[minmax(180px,1.2fr)_120px_140px_180px_150px] lg:items-center"
        >
          <div class="min-w-0">
            <p class="font-black text-slate-950">{{ commitment.donor?.name }}</p>
            <p class="mt-1 text-xs font-bold text-slate-500">{{ commitment.donor?.blood_type }} · {{ commitment.donor?.phone ?? 'Chưa có SĐT' }}</p>
          </div>
          <div class="min-w-0">
            <p class="text-[11px] font-black uppercase tracking-[0.14em] text-slate-400">Trạng thái</p>
            <span
              class="mt-1 inline-flex min-w-28 justify-center rounded-full px-2 py-1 text-xs font-black"
              :class="commitment.status === 'donated' ? 'bg-amber-50 text-amber-700' : ['cancelled', 'not_needed'].includes(commitment.status) ? 'bg-slate-100 text-slate-500' : 'bg-emerald-50 text-emerald-700'"
            >
              {{ commitmentStatusLabels[commitment.status] }}
            </span>
            <p v-if="commitment.status === 'cancelled' && commitment.cancel_reason" class="mt-2 text-xs font-bold leading-snug text-slate-500">
              {{ commitment.cancel_reason }}
            </p>
          </div>
          <div class="min-w-0">
            <p class="text-[11px] font-black uppercase tracking-[0.14em] text-slate-400">Lượng máu</p>
            <p v-if="commitment.status === 'donated'" class="mt-2 text-sm font-black text-slate-800">
              {{ commitment.donation_volume_ml ?? 350 }} ml
            </p>
            <div v-else class="mt-1 flex h-11 w-44 items-center overflow-hidden rounded-md border border-slate-200 bg-white">
              <select
                v-model.number="donationVolumes[commitment.id]"
                class="h-full min-w-0 flex-1 appearance-none bg-white px-4 text-sm font-black tabular-nums text-slate-800 outline-none"
                :disabled="commitment.status === 'cancelled'"
                @blur="normalizeDonationVolume(commitment.id)"
              >
                <option v-for="volume in donationVolumeOptions" :key="volume" :value="volume">
                  {{ volume }}
                </option>
              </select>
              <span class="border-l border-slate-200 px-2 text-xs font-black text-slate-400">ml</span>
            </div>
            <p class="mt-1 text-xs font-bold text-slate-500">ETA {{ commitment.eta_minutes ?? '--' }} phút</p>
          </div>
          <div class="min-w-0">
            <p class="text-[11px] font-black uppercase tracking-[0.14em] text-slate-400">Tiến trình máu</p>
            <p v-if="commitment.status !== 'donated'" class="mt-2 text-sm text-slate-400">
              --
            </p>
            <span
              v-else
              class="mt-1 inline-flex min-w-[140px] justify-center rounded-full px-2.5 py-1 text-xs font-black text-center"
              :class="isJourneyCompleted(commitment) ? 'bg-indigo-50 text-indigo-700' : 'bg-blue-50 text-blue-700 animate-pulse'"
            >
              {{ getJourneyStepLabel(commitment) }}
            </span>
          </div>
          <div class="flex flex-col gap-2 lg:items-end">
            <button
              class="inline-flex h-11 w-40 items-center justify-center gap-2 rounded-md px-3 text-xs font-black uppercase tracking-wide transition disabled:cursor-not-allowed disabled:opacity-60 lg:justify-self-end"
              :class="commitment.status === 'donated' ? 'bg-amber-50 text-amber-700' : 'bg-slate-950 text-white hover:bg-slate-800'"
              :disabled="commitment.status === 'donated' || commitment.status === 'cancelled'"
              @click="markDonated(commitment)"
            >
              <BadgeCheck class="h-4 w-4" />
              {{ commitment.status === 'donated' ? 'Đã ghi nhận' : 'Đã hiến' }}
            </button>
            <button
              v-if="commitment.status === 'donated'"
              class="inline-flex h-11 w-40 items-center justify-center gap-2 rounded-md border border-red-100 bg-red-50 px-3 text-xs font-black uppercase tracking-wide text-[#E31837] transition hover:bg-white lg:justify-self-end"
              @click="openJourney(commitment)"
            >
              <MapPinned class="h-4 w-4" />
              Hành trình
            </button>
          </div>
        </div>
      </div>

      <p v-else class="mt-4 rounded-md border border-dashed border-slate-200 p-6 text-center text-sm text-slate-500">
        Chưa có người hiến nào cam kết cho ca đang chọn.
      </p>
    </section>

    <section class="grid gap-5 xl:grid-cols-[1.45fr_0.85fr]">
      <LiveTrackingMap :alert="activeAlert" :commitments="commitments" :loading="isLoading" />

      <div class="space-y-5">
        <aside class="rounded-lg border border-slate-800 bg-slate-950 p-4 text-white shadow-sm">
          <div class="flex items-center justify-between gap-3 border-b border-white/10 pb-3">
            <div>
              <h3 class="flex items-center gap-2 text-base font-black">
                <Radio class="h-5 w-5 text-[#E31837]" />
                Sóng phát lệnh
              </h3>
              <p class="mt-1 text-xs text-slate-400">Dữ liệu từ thuật toán điều phối gợn sóng.</p>
            </div>
            <span class="rounded bg-[#E31837] px-2 py-1 text-[10px] font-black uppercase">Trực tiếp</span>
          </div>

          <div class="mt-4 space-y-3 text-sm">
            <div class="flex items-center justify-between rounded-md bg-white/5 px-3 py-2">
              <span>Vòng 1 · bán kính 15km</span>
              <strong>{{ waveSummary.local5km ?? 0 }}</strong>
            </div>
            <div class="flex items-center justify-between rounded-md bg-white/5 px-3 py-2">
              <span>Vòng 2 · nội tỉnh 30km</span>
              <strong>{{ waveSummary.province30km ?? 0 }}</strong>
            </div>
            <div class="flex items-center justify-between rounded-md bg-white/5 px-3 py-2">
              <span>Vòng 3 · chi viện liên tỉnh</span>
              <strong>{{ waveSummary.inter_province ?? 0 }}</strong>
            </div>
          </div>
        </aside>

        <AlertTimeline :alerts="activeAlert ? [activeAlert] : alerts" :commitments="commitments" />
      </div>
    </section>

    <div
      v-if="editingJourneyCommitment"
      class="fixed inset-0 z-[60] flex items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm"
      @click.self="closeJourney"
    >
      <div class="w-full max-w-xl rounded-lg bg-white p-5 shadow-2xl">
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="text-xs font-black uppercase tracking-[0.18em] text-[#E31837]">Hành trình giọt máu</p>
            <h3 class="mt-1 text-xl font-black text-slate-950">{{ editingJourneyCommitment.donor?.name }}</h3>
          </div>
          <button class="rounded-md border border-slate-200 px-3 py-2 text-xs font-black text-slate-500 hover:bg-slate-50" @click="closeJourney">
            Đóng
          </button>
        </div>

        <div class="mt-5 grid gap-4">
          <label class="block">
            <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-400">Kịch bản</span>
            <select v-model="journeyForm.destination_type" class="mt-1 h-11 w-full rounded-md border border-slate-200 px-3 text-sm font-bold outline-none focus:border-[#E31837]">
              <option value="patient">Đến thẳng bệnh nhân</option>
              <option value="reserve">Chuyển vào kho dự trữ</option>
            </select>
          </label>

          <label class="block">
            <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-400">Tiến trình hiện tại</span>
            <select v-model="journeyForm.current_step" class="mt-1 h-11 w-full rounded-md border border-slate-200 px-3 text-sm font-bold outline-none focus:border-[#E31837]">
              <option v-for="step in journeyStepOptions" :key="step.key" :value="step.key" :disabled="isStepDisabled(step.key)">
                {{ step.label }}
              </option>
            </select>
          </label>

          <label class="block">
            <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-400">Vị trí mô tả</span>
            <input v-model="journeyForm.location_label" class="mt-1 h-11 w-full rounded-md border border-slate-200 px-3 text-sm font-bold outline-none focus:border-[#E31837]" placeholder="Khoa cấp cứu, kho máu bệnh viện..." />
          </label>

          <label class="flex items-center gap-3 rounded-md bg-red-50 p-3 text-sm font-bold text-red-900">
            <input :checked="true" type="checkbox" class="h-4 w-4 cursor-not-allowed accent-[#E31837]" disabled />
            Công bố và gửi thông báo cho người hiến khi bước hiện tại là bước cuối
          </label>
        </div>

        <div class="mt-5 flex justify-end gap-2">
          <button class="rounded-md border border-slate-200 px-4 py-2 text-sm font-black text-slate-600 hover:bg-slate-50" @click="closeJourney">
            Hủy
          </button>
          <button class="rounded-md bg-[#E31837] px-4 py-2 text-sm font-black text-white hover:bg-red-700" @click="saveJourney">
            Lưu hành trình
          </button>
        </div>
      </div>
    </div>

    <!-- Modal Lịch sử ca SOS đã hoàn thành -->
    <div
      v-if="showCompletedModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm"
      @click.self="closeCompletedModal"
    >
      <div class="w-full max-w-5xl rounded-lg bg-white p-6 shadow-2xl">
        <div class="flex items-start justify-between gap-4 border-b border-slate-100 pb-3">
          <div class="flex items-center gap-2">
            <button
              v-if="selectedCompletedAlert"
              class="mr-2 inline-flex h-8 w-8 items-center justify-center rounded-md border border-slate-200 text-slate-500 hover:bg-slate-50 transition"
              @click="selectedCompletedAlertId = null"
            >
              <ArrowLeft class="h-4 w-4" />
            </button>
            <div>
              <h3 class="text-lg font-black text-slate-950">
                {{ selectedCompletedAlert ? 'Chi tiết ca SOS đã hoàn thành' : 'Lịch sử ca SOS đã hoàn thành' }}
              </h3>
              <p class="mt-1 text-xs text-slate-500">
                {{ selectedCompletedAlert ? 'Xem thông tin chi tiết ca SOS và cập nhật hành trình giọt máu.' : 'Danh sách các ca cấp cứu khẩn cấp đã xong. Chọn một ca để xem chi tiết.' }}
              </p>
            </div>
          </div>
          <button class="rounded-md border border-slate-200 px-3 py-2 text-xs font-black text-slate-500 hover:bg-slate-50" @click="closeCompletedModal">
            Đóng
          </button>
        </div>

        <!-- Chi tiết ca completed -->
        <div v-if="selectedCompletedAlert" class="mt-4 max-h-[60vh] overflow-y-auto pr-1 space-y-5">
          <div class="rounded-lg bg-slate-50 p-4 border border-slate-200">
            <h3 class="font-black text-slate-950 text-base">{{ selectedCompletedAlert?.hospital?.name }}</h3>
            <p class="mt-1 text-xs font-bold text-slate-500">
              Nhóm máu: <span class="text-[#E31837]">{{ selectedCompletedAlert?.required_blood_type }}</span> · 
              Nhu cầu: {{ selectedCompletedAlert?.units_needed }} đơn vị · 
              Thời gian: {{ formatAlertTime(selectedCompletedAlert?.created_at ?? '') }}
            </p>
            <p class="mt-2 text-sm text-slate-600 leading-relaxed">{{ selectedCompletedAlert?.message }}</p>
          </div>

          <div>
            <h4 class="text-sm font-black text-slate-950 mb-3 uppercase tracking-wider">Danh sách người cam kết</h4>
            <div v-if="selectedCompletedAlert?.commitments?.length" class="overflow-hidden rounded-lg border border-slate-200">
              <div
                v-for="commitment in selectedCompletedAlert.commitments"
                :key="commitment.id"
                class="grid min-h-24 gap-3 border-b border-slate-100 p-4 last:border-b-0 lg:grid-cols-[minmax(180px,1.2fr)_120px_140px_180px_150px] lg:items-center bg-white"
              >
                <div class="min-w-0">
                  <p class="font-black text-slate-950">{{ commitment.donor?.name }}</p>
                  <p class="mt-1 text-xs font-bold text-slate-500">{{ commitment.donor?.blood_type }} · {{ commitment.donor?.phone ?? 'Chưa có SĐT' }}</p>
                </div>

                <div class="min-w-0">
                  <p class="text-[10px] font-black uppercase tracking-[0.14em] text-slate-400">Trạng thái</p>
                  <span
                    class="mt-1 inline-flex min-w-24 justify-center rounded-full px-2 py-0.5 text-xs font-black"
                    :class="commitment.status === 'donated' ? 'bg-amber-50 text-amber-700' : ['cancelled', 'not_needed'].includes(commitment.status) ? 'bg-slate-100 text-slate-500' : 'bg-emerald-50 text-emerald-700'"
                  >
                    {{ commitmentStatusLabels[commitment.status] }}
                  </span>
                </div>

                <div class="min-w-0">
                  <p class="text-[10px] font-black uppercase tracking-[0.14em] text-slate-400">Lượng máu</p>
                  <p v-if="commitment.status === 'donated'" class="mt-2 text-sm font-black text-slate-800">
                    {{ commitment.donation_volume_ml ?? 350 }} ml
                  </p>
                  <div v-else class="mt-1 flex h-9 w-36 items-center overflow-hidden rounded-md border border-slate-200 bg-white">
                    <select
                      v-model.number="donationVolumes[commitment.id]"
                      class="h-full min-w-0 flex-1 appearance-none bg-white px-3 text-xs font-black tabular-nums text-slate-800 outline-none"
                      @blur="normalizeDonationVolume(commitment.id)"
                    >
                      <option v-for="volume in donationVolumeOptions" :key="volume" :value="volume">
                        {{ volume }}
                      </option>
                    </select>
                    <span class="border-l border-slate-200 px-2 text-[10px] font-black text-slate-400">ml</span>
                  </div>
                </div>

                <div class="min-w-0">
                  <p class="text-[10px] font-black uppercase tracking-[0.14em] text-slate-400">Tiến trình máu</p>
                  <p v-if="commitment.status !== 'donated'" class="mt-2 text-sm text-slate-400">
                    --
                  </p>
                  <span
                    v-else
                    class="mt-1 inline-flex min-w-[130px] justify-center rounded-full px-2 py-0.5 text-xs font-black text-center"
                    :class="isJourneyCompleted(commitment) ? 'bg-indigo-50 text-indigo-700' : 'bg-blue-50 text-blue-700 animate-pulse'"
                  >
                    {{ getJourneyStepLabel(commitment) }}
                  </span>
                </div>

                <div class="flex flex-col gap-1.5 lg:items-end">
                  <button
                    class="inline-flex h-9 w-32 items-center justify-center gap-1.5 rounded-md px-2.5 text-xs font-black uppercase tracking-wide transition disabled:cursor-not-allowed disabled:opacity-60"
                    :class="commitment.status === 'donated' ? 'bg-amber-50 text-amber-700' : 'bg-slate-950 text-white hover:bg-slate-800'"
                    :disabled="commitment.status === 'donated' || commitment.status === 'cancelled'"
                    @click="markCompletedAlertDonated(selectedCompletedAlert, commitment)"
                  >
                    <BadgeCheck class="h-3.5 w-3.5" />
                    {{ commitment.status === 'donated' ? 'Đã ghi nhận' : 'Đã hiến' }}
                  </button>
                  <button
                    v-if="commitment.status === 'donated'"
                    class="inline-flex h-9 w-32 items-center justify-center gap-1.5 rounded-md border border-red-100 bg-red-50 px-2.5 text-xs font-black uppercase tracking-wide text-[#E31837] transition hover:bg-white"
                    @click="openJourney(commitment)"
                  >
                    <MapPinned class="h-3.5 w-3.5" />
                    Hành trình
                  </button>
                </div>
              </div>
            </div>
            <p v-else class="rounded-md border border-dashed border-slate-200 p-8 text-center text-sm font-bold text-slate-500 bg-white">
              Chưa có người hiến nào cam kết cho ca này.
            </p>
          </div>
        </div>

        <!-- Danh sách ca completed -->
        <div v-else class="mt-4 max-h-[60vh] overflow-y-auto pr-1">
          <div v-if="completedAlerts.length" class="grid gap-3">
            <article
              v-for="alert in completedAlerts"
              :key="alert.id"
              class="flex flex-col justify-between gap-3 rounded-lg border border-slate-200 p-4 transition hover:bg-slate-50 sm:flex-row sm:items-center bg-white"
            >
              <div class="min-w-0 flex-1">
                <p class="font-black text-slate-950">{{ alert.hospital?.name ?? 'Bệnh viện' }}</p>
                <p class="mt-1 text-xs font-bold text-slate-500">
                  Nhóm máu: <span class="text-[#E31837]">{{ alert.required_blood_type }}</span> · 
                  Nhu cầu: {{ alert.units_needed }} đơn vị · 
                  Thời gian: {{ formatAlertTime(alert.created_at) }}
                </p>
                <p class="mt-2 text-sm text-slate-600 line-clamp-1">{{ alert.message }}</p>
              </div>
              <div class="flex items-center gap-3 shrink-0">
                <span class="rounded bg-emerald-50 px-2 py-1 text-[11px] font-bold text-emerald-700">
                  Đã hiến: {{ donatedCount(alert) }}/{{ alert.units_needed }}
                </span>
                <button
                  class="rounded-md bg-slate-950 px-3 py-2 text-xs font-black uppercase text-white hover:bg-slate-800 transition"
                  @click="selectCompletedAlert(alert.id)"
                >
                  Xem chi tiết
                </button>
              </div>
            </article>
          </div>
          <p v-else class="rounded-md border border-dashed border-slate-200 p-8 text-center text-sm text-slate-500">
            Chưa có ca SOS nào hoàn thành trong danh mục này.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>
