<script setup lang="ts">
import { computed, reactive, ref, watch } from 'vue'
import { BadgeCheck, Clock3, History, MapPinned, X } from '@lucide/vue'
import SosCommandCenter from '../components/SosCommandCenter.vue'
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

const donationVolumes = reactive<Record<number, number>>({})
const donationVolumeOptions = [250, 350, 450]
const editingJourneyCommitment = ref<EmergencyCommitment | null>(null)
const showCompletedModal = ref(false)
const selectedCompletedAlertId = ref<string | null>(null)

const selectedCompletedAlert = computed(() => {
  if (!selectedCompletedAlertId.value) return null
  return props.alerts.find((alert) => alert.id === selectedCompletedAlertId.value) ?? null
})
const completedAlerts = computed(() => props.alerts.filter((alert) => alert.status === 'fulfilled'))

const commitmentStatusLabels: Record<EmergencyCommitment['status'], string> = {
  committed: 'Đã cam kết',
  en_route: 'Đang di chuyển',
  donated: 'Đã hiến',
  cancelled: 'Đã hủy',
  not_needed: 'Ca đã đủ',
}

const journeyForm = reactive({
  destination_type: 'patient' as 'patient' | 'reserve',
  current_step: 'received',
  location_label: '',
  publish: true,
})

const journeyStepOptions = computed(() => {
  if (journeyForm.destination_type === 'reserve') {
    return [
      { key: 'received', label: 'Đã tiếp nhận' },
      { key: 'quality_check', label: 'Đang kiểm tra chất lượng' },
      { key: 'stored', label: 'Đã lưu trữ an toàn tại kho máu' },
    ]
  }

  return [
    { key: 'received', label: 'Đã tiếp nhận' },
    { key: 'quality_check', label: 'Đang kiểm tra chất lượng' },
    { key: 'emergency_transport', label: 'Đang vận chuyển cấp cứu' },
    { key: 'transfused', label: 'Đã truyền cho bệnh nhân thành công' },
  ]
})

watch(
  () => props.commitments,
  (commitments) => {
    commitments.forEach((commitment) => {
      donationVolumes[commitment.id] = commitment.donation_volume_ml ?? donationVolumes[commitment.id] ?? 350
    })
  },
  { immediate: true },
)

function formatAlertTime(value?: string | null) {
  if (!value) return '--'
  return new Intl.DateTimeFormat('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    day: '2-digit',
    month: '2-digit',
    hour12: false,
  }).format(new Date(value))
}

function normalizeDonationVolume(commitmentId: number) {
  const value = Number(donationVolumes[commitmentId] ?? 350)
  const volume = donationVolumeOptions.includes(value) ? value : 350
  donationVolumes[commitmentId] = volume
  return volume
}

function markDonated(commitment: EmergencyCommitment, alert = props.activeAlert) {
  if (!alert) return
  emit('markCommitmentDonated', alert, commitment, normalizeDonationVolume(commitment.id))
}

function getJourneyStepLabel(commitment: EmergencyCommitment) {
  const journey = commitment.blood_journey
  if (!journey) return 'Chưa khởi tạo'

  return journey.steps?.find((step) => step.key === journey.current_step)?.label ?? journey.current_step
}

function isJourneyCompleted(commitment: EmergencyCommitment) {
  const journey = commitment.blood_journey
  return journey?.destination_type === 'reserve'
    ? journey.current_step === 'stored'
    : journey?.current_step === 'transfused'
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
  const commitment = editingJourneyCommitment.value
  const alert = props.alerts.find((item) => item.id === commitment?.alert_id)
  if (!commitment || !alert) return

  emit('updateCommitmentJourney', alert, commitment, {
    destination_type: journeyForm.destination_type,
    current_step: journeyForm.current_step,
    location_label: journeyForm.location_label,
    publish: true,
  })
  closeJourney()
}

function isStepDisabled(stepKey: string) {
  const current = editingJourneyCommitment.value?.blood_journey?.current_step ?? 'received'
  const currentIndex = journeyStepOptions.value.findIndex((option) => option.key === current)
  const nextIndex = journeyStepOptions.value.findIndex((option) => option.key === stepKey)
  const destinationChanged = journeyForm.destination_type !== (editingJourneyCommitment.value?.blood_journey?.destination_type ?? 'patient')
  return !destinationChanged && nextIndex < currentIndex
}

function selectCompletedAlert(alertId: string) {
  selectedCompletedAlertId.value = alertId
}

function closeCompletedModal() {
  showCompletedModal.value = false
  selectedCompletedAlertId.value = null
}
</script>

<template>
  <div class="space-y-6">
    <SosCommandCenter
      :active-alerts="activeAlerts"
      :active-alert="activeAlert"
      :selected-alert-id="selectedAlertId"
      :commitments="commitments"
      :stats="stats"
      :is-loading="isLoading"
      @open-sos="emit('openSos')"
      @select-alert="emit('selectAlert', $event)"
      @cancel-alert="emit('cancelAlert', $event)"
      @complete-alert="emit('completeAlert', $event)"
    />

    <section class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div class="flex flex-col gap-3 border-b border-slate-100 pb-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Bàn điều phối</p>
          <h3 class="mt-1 text-lg font-black text-slate-950">Người đã cam kết cho ca đang chọn</h3>
          <p class="mt-1 text-sm font-semibold text-slate-500">Xác nhận hiến và cập nhật hành trình máu sau khi điều phối viên đối soát thực tế.</p>
        </div>
        <div class="flex items-center gap-2">
          <span class="rounded-full bg-red-50 px-3 py-1.5 text-xs font-black text-[#E31837]">{{ activeAlert?.required_blood_type ?? '--' }}</span>
          <button class="inline-flex h-9 items-center gap-1.5 rounded-md border border-slate-200 bg-white px-3 text-xs font-black text-slate-600 transition hover:bg-slate-50" @click="showCompletedModal = true">
            <History class="h-4 w-4" /> Lịch sử ca SOS
          </button>
        </div>
      </div>

      <div v-if="activeAlert && commitments.length" class="mt-4 overflow-hidden rounded-xl border border-slate-200">
        <div
          v-for="commitment in commitments"
          :key="commitment.id"
          class="grid gap-4 border-b border-slate-100 p-4 last:border-b-0 xl:grid-cols-[minmax(170px,1.2fr)_125px_150px_170px_145px] xl:items-center"
        >
          <div class="min-w-0">
            <p class="truncate font-black text-slate-950">{{ commitment.donor?.name ?? 'Tình nguyện viên' }}</p>
            <p class="mt-1 text-xs font-bold text-slate-500">{{ commitment.donor?.blood_type ?? '--' }} · {{ commitment.donor?.phone ?? 'Chưa có SĐT' }}</p>
            <p class="mt-1 flex items-center gap-1 text-xs font-bold text-slate-400"><Clock3 class="h-3.5 w-3.5" /> Cập nhật {{ formatAlertTime(commitment.last_location_at) }}</p>
          </div>
          <div>
            <p class="text-[10px] font-black uppercase tracking-[0.12em] text-slate-400">Trạng thái</p>
            <span
              class="mt-1 inline-flex rounded-full px-2.5 py-1 text-xs font-black"
              :class="commitment.status === 'en_route' ? 'bg-emerald-50 text-emerald-700' : commitment.status === 'donated' ? 'bg-amber-50 text-amber-700' : ['cancelled', 'not_needed'].includes(commitment.status) ? 'bg-slate-100 text-slate-500' : 'bg-sky-50 text-sky-700'"
            >{{ commitmentStatusLabels[commitment.status] }}</span>
          </div>
          <div>
            <p class="text-[10px] font-black uppercase tracking-[0.12em] text-slate-400">Lượng máu / ETA</p>
            <p v-if="commitment.status === 'donated'" class="mt-1 text-sm font-black text-slate-900">{{ commitment.donation_volume_ml ?? 350 }} ml</p>
            <div v-else class="mt-1 flex items-center gap-2">
              <select v-model.number="donationVolumes[commitment.id]" class="h-9 rounded-md border border-slate-200 bg-white px-2 text-sm font-black outline-none" :disabled="commitment.status === 'cancelled'" @blur="normalizeDonationVolume(commitment.id)">
                <option v-for="volume in donationVolumeOptions" :key="volume" :value="volume">{{ volume }} ml</option>
              </select>
              <span class="text-xs font-bold text-slate-500">ETA {{ commitment.eta_minutes ?? '--' }}'</span>
            </div>
          </div>
          <div>
            <p class="text-[10px] font-black uppercase tracking-[0.12em] text-slate-400">Hành trình máu</p>
            <p v-if="commitment.status !== 'donated'" class="mt-1 text-sm font-semibold text-slate-400">Chờ xác nhận hiến</p>
            <span v-else class="mt-1 inline-flex rounded-full px-2.5 py-1 text-xs font-black" :class="isJourneyCompleted(commitment) ? 'bg-indigo-50 text-indigo-700' : 'bg-blue-50 text-blue-700'">{{ getJourneyStepLabel(commitment) }}</span>
          </div>
          <div class="flex flex-col gap-2 xl:items-end">
            <button
              class="inline-flex h-10 w-full items-center justify-center gap-1.5 rounded-md px-3 text-xs font-black uppercase tracking-wide transition disabled:cursor-not-allowed disabled:opacity-50 xl:w-36"
              :class="commitment.status === 'donated' ? 'bg-amber-50 text-amber-700' : 'bg-slate-950 text-white hover:bg-slate-800'"
              :disabled="commitment.status === 'donated' || commitment.status === 'cancelled'"
              @click="markDonated(commitment)"
            >
              <BadgeCheck class="h-4 w-4" /> {{ commitment.status === 'donated' ? 'Đã ghi nhận' : 'Xác nhận hiến' }}
            </button>
            <button v-if="commitment.status === 'donated'" class="inline-flex h-9 w-full items-center justify-center gap-1.5 rounded-md border border-red-100 bg-red-50 px-3 text-xs font-black text-[#E31837] transition hover:bg-white xl:w-36" @click="openJourney(commitment)">
              <MapPinned class="h-3.5 w-3.5" /> Hành trình
            </button>
          </div>
        </div>
      </div>
      <p v-else class="mt-4 rounded-xl border border-dashed border-slate-200 bg-slate-50 p-8 text-center text-sm font-semibold text-slate-500">Chưa có người hiến cam kết cho ca đang chọn.</p>
    </section>

    <div v-if="editingJourneyCommitment" class="fixed inset-0 z-[60] flex items-center justify-center bg-slate-950/50 p-4 backdrop-blur-sm" @click.self="closeJourney">
      <div class="w-full max-w-xl rounded-2xl bg-white p-6 shadow-2xl">
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="text-[11px] font-black uppercase tracking-[0.16em] text-[#E31837]">Hành trình giọt máu</p>
            <h3 class="mt-1 text-xl font-black text-slate-950">{{ editingJourneyCommitment.donor?.name }}</h3>
          </div>
          <button class="grid h-9 w-9 place-items-center rounded-md border border-slate-200 text-slate-500 hover:bg-slate-50" @click="closeJourney"><X class="h-5 w-5" /></button>
        </div>
        <div class="mt-5 grid gap-4">
          <label class="block">
            <span class="text-xs font-black uppercase tracking-[0.12em] text-slate-400">Kịch bản</span>
            <select v-model="journeyForm.destination_type" class="mt-1 h-11 w-full rounded-md border border-slate-200 px-3 text-sm font-bold outline-none focus:border-[#E31837]">
              <option value="patient">Đến thẳng bệnh nhân</option>
              <option value="reserve">Chuyển vào kho dự trữ</option>
            </select>
          </label>
          <label class="block">
            <span class="text-xs font-black uppercase tracking-[0.12em] text-slate-400">Bước hiện tại</span>
            <select v-model="journeyForm.current_step" class="mt-1 h-11 w-full rounded-md border border-slate-200 px-3 text-sm font-bold outline-none focus:border-[#E31837]">
              <option v-for="step in journeyStepOptions" :key="step.key" :value="step.key" :disabled="isStepDisabled(step.key)">{{ step.label }}</option>
            </select>
          </label>
          <label class="block">
            <span class="text-xs font-black uppercase tracking-[0.12em] text-slate-400">Vị trí xử lý</span>
            <input v-model="journeyForm.location_label" class="mt-1 h-11 w-full rounded-md border border-slate-200 px-3 text-sm font-bold outline-none focus:border-[#E31837]" placeholder="Khoa cấp cứu, kho máu bệnh viện...">
          </label>
        </div>
        <div class="mt-6 flex justify-end gap-3">
          <button class="h-10 rounded-md border border-slate-200 px-4 text-xs font-black text-slate-600 hover:bg-slate-50" @click="closeJourney">Hủy</button>
          <button class="h-10 rounded-md bg-[#E31837] px-4 text-xs font-black uppercase tracking-wide text-white hover:bg-red-700" @click="saveJourney">Lưu hành trình</button>
        </div>
      </div>
    </div>

    <div v-if="showCompletedModal" class="fixed inset-0 z-[55] flex items-center justify-center bg-slate-950/45 p-4 backdrop-blur-sm" @click.self="closeCompletedModal">
      <div class="max-h-[86vh] w-full max-w-4xl overflow-y-auto rounded-2xl bg-white p-6 shadow-2xl">
        <div class="flex items-start justify-between gap-4">
          <div>
            <p class="text-[11px] font-black uppercase tracking-[0.16em] text-slate-400">Lịch sử vận hành</p>
            <h3 class="mt-1 text-xl font-black text-slate-950">Các ca SOS đã hoàn thành</h3>
          </div>
          <button class="grid h-9 w-9 place-items-center rounded-md border border-slate-200 text-slate-500 hover:bg-slate-50" @click="closeCompletedModal"><X class="h-5 w-5" /></button>
        </div>
        <div v-if="!selectedCompletedAlert" class="mt-5 grid gap-3">
          <button v-for="alert in completedAlerts" :key="alert.id" class="flex flex-col gap-3 rounded-xl border border-slate-200 p-4 text-left transition hover:border-[#E31837] hover:bg-red-50/40 sm:flex-row sm:items-center sm:justify-between" @click="selectCompletedAlert(alert.id)">
            <span>
              <span class="block font-black text-slate-950">{{ alert.hospital?.name ?? 'Bệnh viện' }}</span>
              <span class="mt-1 block text-xs font-bold text-slate-500">{{ alert.required_blood_type }} · {{ alert.units_needed }} đơn vị · {{ formatAlertTime(alert.created_at) }}</span>
            </span>
            <span class="rounded-full bg-emerald-50 px-3 py-1 text-xs font-black text-emerald-700">Đã hoàn thành</span>
          </button>
          <p v-if="completedAlerts.length === 0" class="rounded-xl border border-dashed border-slate-200 p-8 text-center text-sm font-semibold text-slate-500">Chưa có ca SOS hoàn thành.</p>
        </div>
        <div v-else class="mt-5">
          <button class="text-xs font-black text-[#E31837] hover:underline" @click="selectedCompletedAlertId = null">← Danh sách lịch sử</button>
          <h4 class="mt-3 text-lg font-black text-slate-950">{{ selectedCompletedAlert.hospital?.name }}</h4>
          <div class="mt-4 overflow-hidden rounded-xl border border-slate-200">
            <div v-for="commitment in selectedCompletedAlert.commitments" :key="commitment.id" class="flex flex-col gap-3 border-b border-slate-100 p-4 last:border-b-0 sm:flex-row sm:items-center sm:justify-between">
              <div><p class="font-black text-slate-950">{{ commitment.donor?.name }}</p><p class="mt-1 text-xs font-bold text-slate-500">{{ commitment.donor?.blood_type }} · {{ commitmentStatusLabels[commitment.status] }}</p></div>
              <div class="flex items-center gap-3"><span v-if="commitment.status === 'donated'" class="text-sm font-black text-amber-700">{{ commitment.donation_volume_ml ?? 350 }} ml</span><button v-else class="h-9 rounded-md bg-slate-950 px-3 text-xs font-black text-white" @click="markDonated(commitment, selectedCompletedAlert)">Xác nhận hiến</button><button v-if="commitment.status === 'donated'" class="h-9 rounded-md border border-red-100 bg-red-50 px-3 text-xs font-black text-[#E31837]" @click="openJourney(commitment)">Hành trình</button></div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
