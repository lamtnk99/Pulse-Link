<script setup lang="ts">
import { computed, onMounted, ref, watch } from 'vue'
import { ArrowRight, BarChart3, Loader2, ShieldCheck } from '@lucide/vue'

type RiskRow = {
  blood_type: string
  current_units: number
  threshold_units: number
  shortage_date: string | null
  severity: 'critical' | 'high' | 'medium' | 'safe'
  projected_gap_units: number
}

type ForecastOverview = {
  run: {
    id: number
    generated_at: string | null
    data_quality?: { level?: string; is_demo?: boolean }
  }
  risk_rows: RiskRow[]
}

const props = defineProps<{
  apiBaseUrl: string
  hospitalId: number | null
}>()

const emit = defineEmits<{ openInventory: [] }>()
const overview = ref<ForecastOverview | null>(null)
const isLoading = ref(false)
const error = ref<string | null>(null)

const activeRisks = computed(() =>
  (overview.value?.risk_rows ?? []).filter((row) => row.severity !== 'safe'),
)
const topRisks = computed(() => activeRisks.value.slice(0, 3))
const dataQuality = computed(() => overview.value?.run.data_quality?.level ?? 'chưa có')

function severityClass(severity: RiskRow['severity']) {
  return {
    critical: 'bg-red-100 text-red-700',
    high: 'bg-orange-100 text-orange-700',
    medium: 'bg-amber-100 text-amber-700',
    safe: 'bg-emerald-100 text-emerald-700',
  }[severity]
}

function severityLabel(severity: RiskRow['severity']) {
  return { critical: 'Nghiêm trọng', high: 'Cao', medium: 'Theo dõi', safe: 'An toàn' }[severity]
}

async function load() {
  isLoading.value = true
  error.value = null
  try {
    const hospitalQuery = props.hospitalId ? `?hospital_id=${props.hospitalId}&horizon=7` : '?horizon=7'
    const response = await fetch(`${props.apiBaseUrl}/api/admin/blood-forecasts/overview${hospitalQuery}`)
    if (!response.ok) throw new Error('Không thể tải dự báo kho máu.')
    const payload = await response.json() as { data: ForecastOverview | null }
    overview.value = payload.data
  } catch (loadError) {
    error.value = loadError instanceof Error ? loadError.message : 'Không thể tải dự báo kho máu.'
  } finally {
    isLoading.value = false
  }
}

watch(() => props.hospitalId, load)
onMounted(load)
</script>

<template>
  <section class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
    <div class="flex flex-col gap-3 border-b border-slate-100 pb-4 sm:flex-row sm:items-start sm:justify-between">
      <div>
        <h3 class="flex items-center gap-2 text-base font-black text-slate-950">
          <BarChart3 class="h-5 w-5 text-[#E31837]" />
          Dự báo kho máu 7 ngày
        </h3>
        <p class="mt-1 text-sm text-slate-500">Ưu tiên hành động theo rủi ro tồn kho dự kiến, không chỉ theo số túi hiện tại.</p>
      </div>
      <button class="inline-flex items-center gap-1.5 text-xs font-black uppercase tracking-wide text-[#E31837] hover:text-red-700" @click="emit('openInventory')">
        Xem phân tích
        <ArrowRight class="h-4 w-4" />
      </button>
    </div>

    <div v-if="isLoading" class="flex min-h-32 items-center justify-center text-sm font-semibold text-slate-500">
      <Loader2 class="mr-2 h-4 w-4 animate-spin" /> Đang phân tích dữ liệu kho máu…
    </div>

    <div v-else-if="error" class="mt-4 rounded-md border border-red-100 bg-red-50 p-4 text-sm font-semibold text-red-700">
      {{ error }}
    </div>

    <div v-else-if="!overview" class="mt-4 rounded-md border border-dashed border-slate-200 bg-slate-50 p-5">
      <p class="font-black text-slate-900">Chưa có forecast run hoàn tất</p>
      <p class="mt-1 text-sm text-slate-500">Vào Kho máu & AI để chạy dự báo đầu tiên cho bệnh viện này.</p>
    </div>

    <div v-else class="mt-4 space-y-4">
      <div class="grid gap-3 sm:grid-cols-3">
        <div class="rounded-md bg-red-50 p-3">
          <p class="text-[11px] font-black uppercase tracking-[0.12em] text-red-600">Cần theo dõi</p>
          <p class="mt-1 text-2xl font-black text-slate-950">{{ activeRisks.length }}</p>
          <p class="text-xs font-semibold text-slate-500">nhóm máu</p>
        </div>
        <div class="rounded-md bg-slate-50 p-3">
          <p class="text-[11px] font-black uppercase tracking-[0.12em] text-slate-400">Chất lượng dữ liệu</p>
          <p class="mt-1 text-lg font-black capitalize text-slate-950">{{ dataQuality }}</p>
          <p class="text-xs font-semibold text-slate-500">{{ overview.run.data_quality?.is_demo ? 'Có dữ liệu mô phỏng' : 'Dữ liệu vận hành' }}</p>
        </div>
        <div class="rounded-md bg-emerald-50 p-3">
          <p class="text-[11px] font-black uppercase tracking-[0.12em] text-emerald-700">Forecast run</p>
          <p class="mt-1 text-lg font-black text-slate-950">#{{ overview.run.id }}</p>
          <p class="text-xs font-semibold text-slate-500">đã hoàn tất</p>
        </div>
      </div>

      <div v-if="topRisks.length" class="space-y-2">
        <article v-for="risk in topRisks" :key="risk.blood_type" class="flex items-center justify-between rounded-md border border-slate-100 p-3">
          <div class="flex items-center gap-3">
            <div class="grid h-9 w-9 place-items-center rounded-full bg-red-50 font-black text-[#E31837]">{{ risk.blood_type }}</div>
            <div>
              <p class="text-sm font-black text-slate-950">{{ risk.current_units }}/{{ risk.threshold_units }} túi khả dụng</p>
              <p class="text-xs font-semibold text-slate-500">{{ risk.shortage_date ? `Dự kiến dưới ngưỡng: ${risk.shortage_date}` : 'Cần kiểm tra ngưỡng an toàn' }}</p>
            </div>
          </div>
          <span :class="['rounded-full px-2.5 py-1 text-[10px] font-black uppercase', severityClass(risk.severity)]">{{ severityLabel(risk.severity) }}</span>
        </article>
      </div>
      <div v-else class="flex items-center gap-2 rounded-md bg-emerald-50 p-3 text-sm font-bold text-emerald-700">
        <ShieldCheck class="h-4 w-4" /> Chưa có nhóm máu dự kiến thiếu trong 7 ngày tới.
      </div>
    </div>
  </section>
</template>
