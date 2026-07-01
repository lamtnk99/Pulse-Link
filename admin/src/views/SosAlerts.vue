<script setup lang="ts">
import { computed } from 'vue'
import { AlertTriangle, Radio, ShieldAlert } from '@lucide/vue'
import AlertTimeline from '../components/AlertTimeline.vue'
import LiveTrackingMap from '../components/LiveTrackingMap.vue'
import type { DashboardStats, EmergencyAlert, EmergencyCommitment } from '../types'

const props = defineProps<{
  alerts: EmergencyAlert[]
  activeAlert: EmergencyAlert | null
  commitments: EmergencyCommitment[]
  stats: DashboardStats
  isLoading: boolean
}>()

const emit = defineEmits<{
  openSos: []
}>()

const waveSummary = computed(() => props.activeAlert?.dispatch_summary ?? {})
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

    <section class="grid gap-4 md:grid-cols-4">
      <div class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Đang hoạt động</p>
        <p class="mt-2 text-2xl font-black text-[#E31837]">{{ stats.active_alerts }}</p>
      </div>
      <div class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Đã thông báo</p>
        <p class="mt-2 text-2xl font-black text-slate-950">{{ stats.notified_donors }}</p>
      </div>
      <div class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Đã cam kết</p>
        <p class="mt-2 text-2xl font-black text-emerald-600">{{ stats.committed_donors }}</p>
      </div>
      <div class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Đã đến viện</p>
        <p class="mt-2 text-2xl font-black text-blue-600">{{ stats.arrived_donors }}</p>
      </div>
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
              <span>Vòng 1 · bán kính 5km</span>
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

        <AlertTimeline :alerts="alerts" :commitments="commitments" />
      </div>
    </section>
  </div>
</template>
