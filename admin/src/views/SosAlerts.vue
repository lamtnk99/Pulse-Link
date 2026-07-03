<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { AlertTriangle, BadgeCheck, CheckCircle2, Radio, ShieldAlert, XCircle } from '@lucide/vue'
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
}>()

const waveSummary = computed(() => props.activeAlert?.dispatch_summary ?? {})
const donationVolumes = reactive<Record<number, number>>({})
const donationVolumeOptions = [250, 350, 450]
const commitmentStatusLabels: Record<EmergencyCommitment['status'], string> = {
  committed: 'Đã cam kết',
  en_route: 'Đang di chuyển',
  donated: 'Đã hiến',
  cancelled: 'Đã hủy',
}
const selectedAlertStats = computed(() => {
  const alert = props.activeAlert
  const commitments = props.commitments ?? []

  return {
    active_alerts: alert?.status === 'active' ? 1 : 0,
    notified_donors: alert ? (alert.dispatch_summary?.recipient_count ?? alert.recipients?.length ?? 0) : 0,
    committed_donors: commitments.filter((commitment) => commitment.status !== 'cancelled').length,
    donated_donors: commitments.filter((commitment) => commitment.status === 'donated').length,
  }
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
                class="inline-flex h-8 items-center gap-1 rounded-md border border-red-100 px-2 text-[11px] font-black uppercase text-[#E31837] hover:bg-white"
                @click.stop="emit('cancelAlert', alert)"
              >
                <XCircle class="h-3.5 w-3.5" />
                Hủy
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
          class="grid min-h-28 gap-3 border-b border-slate-100 p-4 last:border-b-0 lg:grid-cols-[minmax(240px,1.4fr)_180px_220px_160px] lg:items-center"
        >
          <div class="min-w-0">
            <p class="font-black text-slate-950">{{ commitment.donor?.name }}</p>
            <p class="mt-1 text-xs font-bold text-slate-500">{{ commitment.donor?.blood_type }} · {{ commitment.donor?.phone ?? 'Chưa có SĐT' }}</p>
          </div>
          <div class="min-w-0">
            <p class="text-[11px] font-black uppercase tracking-[0.14em] text-slate-400">Trạng thái</p>
            <span
              class="mt-1 inline-flex min-w-28 justify-center rounded-full px-2 py-1 text-xs font-black"
              :class="commitment.status === 'donated' ? 'bg-amber-50 text-amber-700' : commitment.status === 'cancelled' ? 'bg-slate-100 text-slate-500' : 'bg-emerald-50 text-emerald-700'"
            >
              {{ commitmentStatusLabels[commitment.status] }}
            </span>
          </div>
          <div class="min-w-0">
            <p class="text-[11px] font-black uppercase tracking-[0.14em] text-slate-400">Lượng máu</p>
            <div class="mt-1 flex h-11 w-44 items-center overflow-hidden rounded-md border border-slate-200 bg-white">
              <select
                v-model.number="donationVolumes[commitment.id]"
                class="h-full min-w-0 flex-1 appearance-none bg-white px-4 text-sm font-black tabular-nums text-slate-800 outline-none disabled:bg-slate-50"
                :disabled="commitment.status === 'donated' || commitment.status === 'cancelled'"
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
          <button
            class="inline-flex h-11 w-40 items-center justify-center gap-2 rounded-md px-3 text-xs font-black uppercase tracking-wide transition disabled:cursor-not-allowed disabled:opacity-60 lg:justify-self-end"
            :class="commitment.status === 'donated' ? 'bg-amber-50 text-amber-700' : 'bg-slate-950 text-white hover:bg-slate-800'"
            :disabled="commitment.status === 'donated' || commitment.status === 'cancelled'"
            @click="markDonated(commitment)"
          >
            <BadgeCheck class="h-4 w-4" />
            {{ commitment.status === 'donated' ? 'Đã ghi nhận' : 'Đã hiến' }}
          </button>
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
  </div>
</template>
