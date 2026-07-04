<script setup lang="ts">
import type { EmergencyAlert, EmergencyCommitment } from '../types'

defineProps<{
  alerts: EmergencyAlert[]
  commitments: EmergencyCommitment[]
}>()

const commitmentStatusLabels: Record<EmergencyCommitment['status'], string> = {
  committed: 'ÄÃ£ cam káº¿t',
  en_route: 'Äang di chuyá»ƒn',
  donated: 'ÄÃ£ hiáº¿n',
  cancelled: 'Đã hủy',
  not_needed: 'Ca đã đủ',
}

function alertStatusLabel(status: string) {
  if (status === 'active') return 'Äang hoáº¡t Ä‘á»™ng'
  if (status === 'fulfilled') return 'HoÃ n thÃ nh'
  if (status === 'resolved') return 'ÄÃ£ xá»­ lÃ½'
  return status
}
</script>

<template>
  <aside class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
    <div class="flex items-center justify-between">
      <h2 class="text-base font-black text-slate-950">DÃ²ng sá»± kiá»‡n váº­n hÃ nh</h2>
      <span class="rounded-full bg-slate-100 px-2 py-1 text-xs font-bold text-slate-500">Trá»±c tiáº¿p</span>
    </div>

    <div class="mt-4 space-y-3">
      <div v-for="alert in alerts" :key="alert.id" class="rounded-md border border-red-100 bg-red-50 p-3">
        <div class="flex items-center justify-between gap-3">
          <p class="font-black text-red-700">{{ alert.required_blood_type }} - {{ alert.level }}</p>
          <span class="text-xs font-bold uppercase text-red-500">{{ alertStatusLabel(alert.status) }}</span>
        </div>
        <p class="mt-1 text-sm text-slate-700">{{ alert.message }}</p>
        <p class="mt-2 text-xs font-semibold text-slate-500">
          {{ alert.dispatch_summary?.recipient_count ?? alert.recipients?.length ?? 0 }} tÃ¬nh nguyá»‡n viÃªn Ä‘Ã£ nháº­n tin
        </p>
      </div>

      <div v-for="commitment in commitments" :key="commitment.id" class="rounded-md border border-slate-200 p-3">
        <div class="flex items-center justify-between">
          <p class="font-black text-slate-900">{{ commitment.donor?.name }}</p>
          <span class="rounded-full bg-emerald-50 px-2 py-1 text-xs font-bold text-emerald-700">
            {{ commitmentStatusLabels[commitment.status] }}
          </span>
        </div>
        <p class="mt-1 text-sm text-slate-500">
          {{ commitment.donor?.blood_type }} - Dá»± kiáº¿n {{ commitment.eta_minutes ?? '--' }} phÃºt
        </p>
        <p v-if="commitment.status === 'cancelled' && commitment.cancel_reason" class="mt-2 rounded-md bg-slate-50 px-2 py-1 text-xs font-bold text-slate-500">
          {{ commitment.cancel_reason }}
        </p>
      </div>

      <p v-if="alerts.length === 0 && commitments.length === 0" class="rounded-md border border-dashed border-slate-200 p-6 text-center text-sm text-slate-500">
        ChÆ°a cÃ³ luá»“ng kháº©n cáº¥p Ä‘ang hoáº¡t Ä‘á»™ng.
      </p>
    </div>
  </aside>
</template>
