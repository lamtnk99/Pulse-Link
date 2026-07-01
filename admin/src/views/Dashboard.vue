<script setup lang="ts">
import { computed, ref } from 'vue'
import { AlertTriangle, CalendarRange, Droplet, Minus, Plus, TrendingUp, Users } from '@lucide/vue'
import type { DashboardStats, EmergencyAlert, EmergencyCommitment } from '../types'

const props = defineProps<{
  stats: DashboardStats
  activeAlerts: EmergencyAlert[]
  commitments: EmergencyCommitment[]
  isLoading: boolean
}>()

const emit = defineEmits<{
  openSos: []
}>()

interface BloodStock {
  type: string
  units: number
  criticalLimit: number
}

const bloodStocks = ref<BloodStock[]>([
  { type: 'O+', units: 84, criticalLimit: 25 },
  { type: 'O-', units: 12, criticalLimit: 25 },
  { type: 'A+', units: 62, criticalLimit: 25 },
  { type: 'A-', units: 35, criticalLimit: 25 },
  { type: 'B+', units: 98, criticalLimit: 25 },
  { type: 'B-', units: 18, criticalLimit: 25 },
  { type: 'AB+', units: 54, criticalLimit: 25 },
  { type: 'AB-', units: 28, criticalLimit: 25 },
])

const totalBloodUnits = computed(() => bloodStocks.value.reduce((total, stock) => total + stock.units, 0))
const criticalStocks = computed(() => bloodStocks.value.filter((stock) => stock.units < stock.criticalLimit))
const enRouteCommitments = computed(() =>
  props.commitments.filter((commitment) => commitment.status === 'committed' || commitment.status === 'en_route'),
)

function adjustStock(type: string, delta: number) {
  bloodStocks.value = bloodStocks.value.map((stock) =>
    stock.type === type ? { ...stock, units: Math.max(0, stock.units + delta) } : stock,
  )
}

function stockTone(stock: BloodStock) {
  if (stock.units < stock.criticalLimit) return 'bg-[#E31837]'
  if (stock.units < 50) return 'bg-amber-400'
  return 'bg-emerald-500'
}
</script>

<template>
  <div class="space-y-6">
    <section class="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
      <div>
        <p class="text-xs font-black uppercase tracking-[0.24em] text-[#E31837]">Trung tâm điều hành</p>
        <h2 class="mt-2 text-2xl font-black tracking-tight text-slate-950">Tổng quan vận hành hiến máu</h2>
        <p class="mt-1 max-w-2xl text-sm text-slate-500">
          Theo dõi tồn kho máu, cam kết hiến khẩn cấp và trạng thái điều phối theo thời gian thực.
        </p>
      </div>

      <button
        class="inline-flex h-10 items-center justify-center gap-2 rounded-md bg-[#E31837] px-4 text-xs font-black uppercase tracking-wide text-white shadow-sm shadow-red-500/20 transition hover:bg-red-700 active:scale-[0.98]"
        @click="emit('openSos')"
      >
        <AlertTriangle class="h-4 w-4" />
        Phát lệnh SOS
      </button>
    </section>

    <section class="grid gap-4 md:grid-cols-2 xl:grid-cols-4">
      <article class="rounded-lg border border-red-100 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between">
          <div class="grid h-11 w-11 place-items-center rounded-md bg-red-50 text-[#E31837]">
            <AlertTriangle class="h-5 w-5" />
          </div>
          <span class="rounded-full bg-red-50 px-2.5 py-1 text-[11px] font-black uppercase text-[#E31837]">
            {{ isLoading ? 'Đang đồng bộ' : 'Trực tuyến' }}
          </span>
        </div>
        <p class="mt-4 text-xs font-black uppercase tracking-[0.16em] text-slate-400">SOS đang hoạt động</p>
        <div class="mt-1 flex items-end gap-2">
          <strong class="text-3xl font-black text-slate-950">{{ activeAlerts.length }}</strong>
          <span class="pb-1 text-xs font-bold text-red-600">ca báo động đỏ</span>
        </div>
      </article>

      <article class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <div class="grid h-11 w-11 place-items-center rounded-md bg-emerald-50 text-emerald-600">
          <TrendingUp class="h-5 w-5" />
        </div>
        <p class="mt-4 text-xs font-black uppercase tracking-[0.16em] text-slate-400">Người đã cam kết</p>
        <div class="mt-1 flex items-end gap-2">
          <strong class="text-3xl font-black text-slate-950">{{ stats.committed_donors }}</strong>
          <span class="pb-1 text-xs font-bold text-emerald-600">đang điều phối</span>
        </div>
      </article>

      <article class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <div class="grid h-11 w-11 place-items-center rounded-md bg-blue-50 text-blue-600">
          <CalendarRange class="h-5 w-5" />
        </div>
        <p class="mt-4 text-xs font-black uppercase tracking-[0.16em] text-slate-400">Lịch hiến tuần này</p>
        <div class="mt-1 flex items-end gap-2">
          <strong class="text-3xl font-black text-slate-950">145</strong>
          <span class="pb-1 text-xs font-bold text-blue-600">lượt đặt lịch</span>
        </div>
      </article>

      <article class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <div class="grid h-11 w-11 place-items-center rounded-md bg-slate-100 text-slate-700">
          <Users class="h-5 w-5" />
        </div>
        <p class="mt-4 text-xs font-black uppercase tracking-[0.16em] text-slate-400">Đã thông báo</p>
        <div class="mt-1 flex items-end gap-2">
          <strong class="text-3xl font-black text-slate-950">{{ stats.notified_donors }}</strong>
          <span class="pb-1 text-xs font-bold text-slate-500">tình nguyện viên</span>
        </div>
      </article>
    </section>

    <section class="grid gap-5 xl:grid-cols-[1.3fr_0.7fr]">
      <article class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-col gap-3 border-b border-slate-100 pb-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h3 class="flex items-center gap-2 text-base font-black text-slate-950">
              <Droplet class="h-5 w-5 text-[#E31837]" />
              Kho máu theo nhóm
            </h3>
            <p class="mt-1 text-sm text-slate-500">Ngưỡng đỏ tự bật khi tồn kho thấp hơn 25 đơn vị.</p>
          </div>
          <div class="rounded-md bg-slate-50 px-3 py-2 text-right">
            <p class="text-[11px] font-bold uppercase text-slate-400">Tổng tồn kho</p>
            <p class="text-lg font-black text-slate-950">{{ totalBloodUnits }} đơn vị</p>
          </div>
        </div>

        <div class="mt-5 grid grid-cols-2 gap-3 sm:grid-cols-4 xl:grid-cols-8">
          <div
            v-for="stock in bloodStocks"
            :key="stock.type"
            class="rounded-lg border p-3 transition"
            :class="stock.units < stock.criticalLimit ? 'border-red-200 bg-red-50' : 'border-slate-200 bg-white'"
          >
            <div class="flex items-center justify-between">
              <strong class="text-xl font-black" :class="stock.units < stock.criticalLimit ? 'text-[#E31837]' : 'text-slate-950'">
                {{ stock.type }}
              </strong>
              <span
                v-if="stock.units < stock.criticalLimit"
                class="rounded bg-[#E31837] px-1.5 py-0.5 text-[9px] font-black uppercase text-white"
              >
                Nguy cấp
              </span>
            </div>

            <div class="mt-3 h-1.5 overflow-hidden rounded-full bg-slate-100">
              <div
                class="h-full rounded-full transition-all"
                :class="stockTone(stock)"
                :style="{ width: `${Math.min((stock.units / 120) * 100, 100)}%` }"
              />
            </div>

            <div class="mt-3 flex items-center justify-between gap-2">
              <div>
                <p class="text-lg font-black text-slate-950">{{ stock.units }}</p>
                <p class="text-[10px] font-semibold uppercase text-slate-400">đơn vị</p>
              </div>
              <div class="flex gap-1">
                <button
                  class="grid h-7 w-7 place-items-center rounded-md border border-slate-200 text-slate-500 hover:bg-slate-50"
                  :aria-label="`Giảm tồn kho ${stock.type}`"
                  @click="adjustStock(stock.type, -5)"
                >
                  <Minus class="h-3.5 w-3.5" />
                </button>
                <button
                  class="grid h-7 w-7 place-items-center rounded-md border border-slate-200 text-slate-500 hover:bg-slate-50"
                  :aria-label="`Tăng tồn kho ${stock.type}`"
                  @click="adjustStock(stock.type, 5)"
                >
                  <Plus class="h-3.5 w-3.5" />
                </button>
              </div>
            </div>
          </div>
        </div>
      </article>

      <aside class="space-y-4">
        <article class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
          <h3 class="text-sm font-black uppercase tracking-[0.16em] text-slate-500">Nhóm máu cần chú ý</h3>
          <div class="mt-4 space-y-3">
            <div
              v-for="stock in criticalStocks"
              :key="stock.type"
              class="flex items-center justify-between rounded-md border border-red-100 bg-red-50 px-3 py-2"
            >
              <span class="font-black text-[#E31837]">{{ stock.type }}</span>
              <span class="text-sm font-bold text-red-700">{{ stock.units }} đơn vị còn lại</span>
            </div>
            <p v-if="criticalStocks.length === 0" class="rounded-md border border-emerald-100 bg-emerald-50 p-3 text-sm font-bold text-emerald-700">
              Tất cả nhóm máu đang trên ngưỡng an toàn.
            </p>
          </div>
        </article>

        <article class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
          <h3 class="text-sm font-black uppercase tracking-[0.16em] text-slate-500">Dòng cam kết mới</h3>
          <div class="mt-4 space-y-3">
            <div
              v-for="commitment in enRouteCommitments.slice(0, 4)"
              :key="commitment.id"
              class="rounded-md border border-slate-100 bg-slate-50 p-3"
            >
              <div class="flex items-center justify-between">
                <p class="font-black text-slate-900">{{ commitment.donor?.name ?? 'Tình nguyện viên' }}</p>
                <span class="rounded-full bg-emerald-100 px-2 py-0.5 text-[10px] font-black uppercase text-emerald-700">
                  {{ commitment.status === 'en_route' ? 'Đang di chuyển' : 'Đã cam kết' }}
                </span>
              </div>
              <p class="mt-1 text-xs font-semibold text-slate-500">
                {{ commitment.donor?.blood_type ?? '--' }} · Dự kiến {{ commitment.eta_minutes ?? '--' }} phút
              </p>
            </div>
            <p v-if="enRouteCommitments.length === 0" class="rounded-md border border-dashed border-slate-200 p-4 text-center text-sm text-slate-500">
              Chưa có cam kết mới trong phiên trực hiện tại.
            </p>
          </div>
        </article>
      </aside>
    </section>
  </div>
</template>
