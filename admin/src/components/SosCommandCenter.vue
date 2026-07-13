<script setup lang="ts">
import { computed, ref, watch } from 'vue'
import { AlertTriangle, CheckCircle2, HeartPulse, Radio, ShieldCheck, UsersRound, XCircle } from '@lucide/vue'
import LiveTrackingMap from './LiveTrackingMap.vue'
import SosDonorProfileDrawer from './SosDonorProfileDrawer.vue'
import type { DashboardStats, EmergencyAlert, EmergencyCommitment } from '../types'

const props = defineProps<{
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
}>()

const selectedCommitment = ref<EmergencyCommitment | null>(null)

const activeCommitments = computed(() =>
  props.commitments.filter((commitment) => !['cancelled', 'not_needed'].includes(commitment.status)),
)
const enRouteCount = computed(() => props.commitments.filter((commitment) => commitment.status === 'en_route').length)
const donatedCount = computed(() => props.commitments.filter((commitment) => commitment.status === 'donated').length)
const recipientCount = computed(() => props.activeAlert?.dispatch_summary?.recipient_count ?? props.activeAlert?.recipients?.length ?? 0)
const donatedForSelectedAlert = computed(() =>
  props.commitments.filter((commitment) => commitment.status === 'donated').length,
)
const waveSummary = computed(() => props.activeAlert?.dispatch_summary ?? {})
const waves = computed(() => [
  { key: 'local5km', title: 'Vòng 1 · bán kính 15km', subtitle: 'Ưu tiên phản ứng nhanh', count: Number(waveSummary.value.local5km ?? 0) },
  { key: 'province30km', title: 'Vòng 2 · nội tỉnh 30km', subtitle: 'Mở rộng theo năng lực điều phối', count: Number(waveSummary.value.province30km ?? 0) },
  { key: 'inter_province', title: 'Vòng 3 · liên tỉnh', subtitle: 'Chi viện khi cần thiết', count: Number(waveSummary.value.inter_province ?? 0) },
])

watch(
  () => props.commitments,
  (commitments) => {
    if (!selectedCommitment.value) return
    selectedCommitment.value = commitments.find((item) => item.id === selectedCommitment.value?.id) ?? null
  },
  { deep: true },
)

watch(
  () => props.activeAlert?.id,
  () => {
    selectedCommitment.value = null
  },
)

function formatTime(value?: string | null) {
  if (!value) return '--:--'
  return new Intl.DateTimeFormat('vi-VN', { hour: '2-digit', minute: '2-digit', hour12: false }).format(new Date(value))
}

function shortAlertId(alert: EmergencyAlert) {
  return `SOS-${alert.id.split('-')[0].toUpperCase()}`
}

function alertProgress(alert: EmergencyAlert) {
  const donated = alert.commitments?.filter((commitment) => commitment.status === 'donated').length ?? 0
  return `${donated}/${alert.units_needed}`
}

function openDonorProfile(commitment: EmergencyCommitment) {
  selectedCommitment.value = commitment
}

function canCancel(alert: EmergencyAlert) {
  return !alert.commitments?.some((commitment) => commitment.status === 'donated')
}
</script>

<template>
  <section class="space-y-5">
    <Transition name="sos-alert-swap" mode="out-in">
      <section
        v-if="activeAlert"
        :key="activeAlert.id"
        class="overflow-hidden rounded-2xl bg-gradient-to-r from-[#d9051f] via-[#e31837] to-[#b90b1e] p-5 text-white shadow-lg shadow-red-900/15"
      >
      <div class="flex flex-col gap-5 xl:flex-row xl:items-center xl:justify-between">
        <div class="flex min-w-0 items-start gap-4">
          <div class="grid h-14 w-14 shrink-0 place-items-center rounded-2xl border border-white/20 bg-white/10">
            <AlertTriangle class="h-7 w-7" />
          </div>
          <div class="min-w-0">
            <div class="flex flex-wrap items-center gap-2 text-[11px] font-black uppercase tracking-[0.16em] text-white/75">
              <span class="rounded bg-black/15 px-2 py-1">{{ shortAlertId(activeAlert) }} · {{ activeAlert.required_blood_type }}</span>
              <span>Khởi tạo {{ formatTime(activeAlert.created_at) }}</span>
            </div>
            <h2 class="mt-2 text-xl font-black tracking-tight sm:text-2xl">Yêu cầu truyền máu tại {{ activeAlert.hospital?.name }}</h2>
            <p class="mt-2 max-w-3xl text-sm font-semibold leading-relaxed text-white/85">{{ activeAlert.message }}</p>
          </div>
        </div>
        <div class="flex shrink-0 flex-wrap items-center gap-3 rounded-xl border border-white/15 bg-black/10 p-3">
          <div class="border-r border-white/15 pr-3 text-center">
            <p class="text-[10px] font-black uppercase tracking-[0.14em] text-white/70">Cần thiết</p>
            <p class="mt-1 text-2xl font-black">{{ activeAlert.units_needed }} đv</p>
          </div>
          <div class="border-r border-white/15 pr-3 text-center">
            <p class="text-[10px] font-black uppercase tracking-[0.14em] text-white/70">Đã nhận</p>
            <p class="mt-1 text-2xl font-black text-amber-200">{{ donatedForSelectedAlert }}/{{ activeAlert.units_needed }}</p>
          </div>
          <button class="inline-flex h-10 items-center gap-2 rounded-lg bg-emerald-500 px-3 text-xs font-black uppercase tracking-wide shadow-sm transition hover:bg-emerald-400" @click="emit('completeAlert', activeAlert)">
            <CheckCircle2 class="h-4 w-4" /> Hoàn thành
          </button>
          <button
            class="grid h-10 w-10 place-items-center rounded-lg border border-white/20 transition hover:bg-white/10 disabled:cursor-not-allowed disabled:opacity-40"
            :disabled="!canCancel(activeAlert)"
            :title="canCancel(activeAlert) ? 'Hủy ca SOS' : 'Ca đã có đơn vị máu, chỉ có thể hoàn thành'"
            @click="emit('cancelAlert', activeAlert)"
          >
            <XCircle class="h-5 w-5" />
          </button>
        </div>
      </div>
      </section>

      <section v-else key="safe-state" class="flex flex-col gap-4 rounded-2xl border border-slate-200 bg-white p-5 shadow-sm sm:flex-row sm:items-center sm:justify-between">
      <div class="flex items-center gap-4">
        <div class="grid h-14 w-14 place-items-center rounded-2xl bg-slate-100 text-slate-500"><ShieldCheck class="h-7 w-7" /></div>
        <div>
          <h2 class="text-lg font-black text-slate-950">Hệ thống an toàn & sẵn sàng</h2>
          <p class="mt-1 text-sm font-semibold text-slate-500">Chưa có báo động đỏ hoạt động. Điều phối viên có thể khởi tạo một ca SOS mới khi cần.</p>
        </div>
      </div>
      <button class="inline-flex h-11 items-center justify-center gap-2 rounded-lg bg-[#E31837] px-4 text-xs font-black uppercase tracking-wide text-white shadow-sm shadow-red-500/20 transition hover:bg-red-700" @click="emit('openSos')">
        <AlertTriangle class="h-4 w-4" /> Phát lệnh SOS khẩn cấp
      </button>
      </section>
    </Transition>

    <section v-if="activeAlerts.length" class="rounded-2xl border border-slate-200 bg-white p-4 shadow-sm">
      <div class="mb-3 flex items-center gap-2 text-xs font-black uppercase tracking-[0.14em] text-slate-500">
        <span class="h-2 w-2 rounded-full bg-[#E31837]" /> Chọn ca SOS theo dõi · {{ activeAlerts.length }} đang phát lệnh
      </div>
      <div class="flex gap-3 overflow-x-auto pb-1">
        <button
          v-for="alert in activeAlerts"
          :key="alert.id"
          class="min-w-[250px] rounded-xl border px-4 py-3 text-left transition"
          :class="alert.id === selectedAlertId ? 'border-[#E31837] bg-[#E31837] text-white shadow-sm' : 'border-slate-200 bg-slate-50 text-slate-700 hover:bg-white'"
          @click="emit('selectAlert', alert.id)"
        >
          <div class="flex items-center justify-between gap-3">
            <span class="font-black">{{ alert.hospital?.name ?? 'Bệnh viện' }}</span>
            <span class="rounded px-2 py-0.5 font-mono text-xs" :class="alert.id === selectedAlertId ? 'bg-black/20' : 'bg-white'">{{ alertProgress(alert) }} đv</span>
          </div>
          <p class="mt-1 text-xs font-bold opacity-75">{{ shortAlertId(alert) }} · {{ formatTime(alert.created_at) }} · {{ alert.required_blood_type }} · {{ alert.compatibility_mode === 'exact' ? 'Đúng nhóm' : 'Tương thích' }}</p>
        </button>
      </div>
    </section>

    <section class="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
      <article class="rounded-xl border border-red-100 bg-red-50/60 p-4">
        <p class="text-[11px] font-black uppercase tracking-[0.12em] text-slate-500">Số ca SOS</p>
        <p class="mt-2 text-2xl font-black text-[#E31837]">{{ activeAlerts.length }}</p>
      </article>
      <article class="rounded-xl border border-slate-200 bg-slate-50 p-4">
        <p class="text-[11px] font-black uppercase tracking-[0.12em] text-slate-500">Số lượt phát sóng</p>
        <p class="mt-2 text-2xl font-black text-slate-950">{{ recipientCount }}</p>
      </article>
      <article class="rounded-xl border border-emerald-100 bg-emerald-50/60 p-4">
        <p class="text-[11px] font-black uppercase tracking-[0.12em] text-slate-500">Tình nguyện viên di chuyển</p>
        <p class="mt-2 text-2xl font-black text-emerald-600">{{ enRouteCount }}</p>
      </article>
      <article class="rounded-xl border border-amber-100 bg-amber-50/60 p-4">
        <p class="text-[11px] font-black uppercase tracking-[0.12em] text-slate-500">Đã hiến thành công</p>
        <p class="mt-2 text-2xl font-black text-amber-600">{{ stats.donated_donors ?? donatedCount }}</p>
      </article>
    </section>

    <section class="grid gap-5 xl:grid-cols-[minmax(0,1.6fr)_minmax(300px,0.7fr)]">
      <LiveTrackingMap
        :alert="activeAlert"
        :commitments="commitments"
        :loading="isLoading"
        :selected-commitment-id="selectedCommitment?.id ?? null"
        @select-commitment="openDonorProfile"
      />

      <aside class="rounded-2xl bg-[#090f1d] p-5 text-white shadow-lg shadow-slate-950/10">
        <div class="flex items-start justify-between gap-3 border-b border-white/10 pb-4">
          <div>
            <h3 class="flex items-center gap-2 text-base font-black"><Radio class="h-5 w-5 text-[#E31837]" /> Sóng phát lệnh</h3>
            <p class="mt-1 text-xs font-semibold text-slate-400">Reverb cập nhật theo từng phản hồi điều phối.</p>
          </div>
          <span class="rounded-md bg-[#E31837] px-2 py-1 text-[10px] font-black uppercase">Trực tiếp</span>
        </div>
        <div class="mt-4 space-y-3">
          <article v-for="wave in waves" :key="wave.key" class="rounded-xl border border-white/10 bg-white/[0.035] p-3.5">
            <div class="flex items-center justify-between gap-3">
              <div>
                <p class="font-black">{{ wave.title }}</p>
                <p class="mt-1 text-xs font-semibold text-slate-500">{{ wave.subtitle }}</p>
              </div>
              <span class="font-mono text-xl font-black" :class="wave.count ? 'text-[#ff5369]' : 'text-slate-500'">{{ wave.count }}</span>
            </div>
          </article>
        </div>

        <div class="mt-5 border-t border-white/10 pt-4">
          <div class="flex items-center justify-between">
            <p class="flex items-center gap-2 text-sm font-black"><UsersRound class="h-4 w-4 text-emerald-400" /> Dòng cam kết</p>
            <span class="text-xs font-bold text-slate-400">{{ activeCommitments.length }} người</span>
          </div>
          <button
            v-for="commitment in activeCommitments.slice(0, 4)"
            :key="commitment.id"
            class="mt-3 flex w-full items-center justify-between gap-3 rounded-lg bg-white/[0.035] px-3 py-2.5 text-left transition hover:bg-white/[0.08]"
            @click="openDonorProfile(commitment)"
          >
            <span class="min-w-0">
              <span class="block truncate text-sm font-black">{{ commitment.donor?.name ?? 'Tình nguyện viên' }}</span>
              <span class="mt-0.5 block text-xs font-semibold text-slate-400">{{ commitment.donor?.blood_type ?? '--' }} · ETA {{ commitment.eta_minutes ?? '--' }} phút</span>
            </span>
            <HeartPulse class="h-4 w-4 shrink-0" :class="commitment.status === 'en_route' ? 'text-emerald-400' : 'text-slate-500'" />
          </button>
          <p v-if="activeCommitments.length === 0" class="mt-3 rounded-lg border border-dashed border-white/10 p-4 text-center text-xs font-semibold text-slate-500">Chưa có người hiến cam kết cho ca đang chọn.</p>
        </div>
      </aside>
    </section>

    <SosDonorProfileDrawer :commitment="selectedCommitment" @close="selectedCommitment = null" />
  </section>
</template>

<style scoped>
.sos-alert-swap-enter-active,
.sos-alert-swap-leave-active {
  transition: opacity 160ms ease, transform 160ms ease;
}

.sos-alert-swap-enter-from,
.sos-alert-swap-leave-to {
  opacity: 0;
  transform: translateY(-6px);
}
</style>
