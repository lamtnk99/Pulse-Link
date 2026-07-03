<script setup lang="ts">
import type { EmergencyAlert, EmergencyCommitment } from '../types'

defineProps<{
  alerts: EmergencyAlert[]
  commitments: EmergencyCommitment[]
}>()

const commitmentStatusLabels: Record<EmergencyCommitment['status'], string> = {
  committed: 'Đã cam kết',
  en_route: 'Đang di chuyển',
  donated: 'Đã hiến',
  cancelled: 'Đã hủy',
}

function alertStatusLabel(status: string) {
  if (status === 'active') return 'Đang hoạt động'
  if (status === 'fulfilled') return 'Hoàn thành'
  if (status === 'resolved') return 'Đã xử lý'
  return status
}
</script>

<template>
  <aside class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
    <div class="flex items-center justify-between">
      <h2 class="text-base font-black text-slate-950">Dòng sự kiện vận hành</h2>
      <span class="rounded-full bg-slate-100 px-2 py-1 text-xs font-bold text-slate-500">Trực tiếp</span>
    </div>

    <div class="mt-4 space-y-3">
      <div v-for="alert in alerts" :key="alert.id" class="rounded-md border border-red-100 bg-red-50 p-3">
        <div class="flex items-center justify-between gap-3">
          <p class="font-black text-red-700">{{ alert.required_blood_type }} - {{ alert.level }}</p>
          <span class="text-xs font-bold uppercase text-red-500">{{ alertStatusLabel(alert.status) }}</span>
        </div>
        <p class="mt-1 text-sm text-slate-700">{{ alert.message }}</p>
        <p class="mt-2 text-xs font-semibold text-slate-500">
          {{ alert.dispatch_summary?.recipient_count ?? alert.recipients?.length ?? 0 }} tình nguyện viên đã nhận tin
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
          {{ commitment.donor?.blood_type }} - Dự kiến {{ commitment.eta_minutes ?? '--' }} phút
        </p>
      </div>

      <p v-if="alerts.length === 0 && commitments.length === 0" class="rounded-md border border-dashed border-slate-200 p-6 text-center text-sm text-slate-500">
        Chưa có luồng khẩn cấp đang hoạt động.
      </p>
    </div>
  </aside>
</template>
