<script setup lang="ts">
import { computed } from 'vue'
import { Award, BadgeCheck, Clock3, Droplets, HeartPulse, MapPin, Phone, ShieldCheck, X } from '@lucide/vue'
import type { EmergencyCommitment } from '../types'

const props = defineProps<{
  commitment: EmergencyCommitment | null
}>()

const emit = defineEmits<{ close: [] }>()

const donor = computed(() => props.commitment?.donor)

const status = computed(() => {
  const value = props.commitment?.status
  return {
    committed: { label: 'Đã cam kết', className: 'bg-sky-50 text-sky-700' },
    en_route: { label: 'Đang di chuyển', className: 'bg-emerald-50 text-emerald-700' },
    donated: { label: 'Đã hiến', className: 'bg-amber-50 text-amber-700' },
    cancelled: { label: 'Đã hủy', className: 'bg-slate-100 text-slate-500' },
    not_needed: { label: 'Ca đã đủ', className: 'bg-slate-100 text-slate-500' },
  }[value ?? 'committed'] ?? { label: 'Đang cập nhật', className: 'bg-slate-100 text-slate-500' }
})

function formatDateTime(value?: string | null) {
  if (!value) return 'Chưa có dữ liệu'

  return new Intl.DateTimeFormat('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    day: '2-digit',
    month: '2-digit',
    hour12: false,
  }).format(new Date(value))
}
</script>

<template>
  <Teleport to="body">
    <div v-if="commitment" class="fixed inset-0 z-[70]" @keydown.esc="emit('close')">
      <div class="absolute inset-0 bg-slate-950/35 backdrop-blur-[1px]" @click="emit('close')" />
      <aside class="absolute inset-y-0 right-0 flex w-full max-w-md flex-col bg-white shadow-2xl">
        <header class="flex items-start justify-between gap-4 border-b border-slate-100 px-6 py-5">
          <div class="min-w-0">
            <p class="text-[11px] font-black uppercase tracking-[0.18em] text-[#E31837]">Hồ sơ điều phối SOS</p>
            <h2 class="mt-1 truncate text-xl font-black text-slate-950">{{ donor?.name ?? 'Người hiến' }}</h2>
            <div class="mt-2 flex flex-wrap items-center gap-2">
              <span class="rounded-full bg-red-50 px-2.5 py-1 text-xs font-black text-[#E31837]">{{ donor?.blood_type ?? '--' }}</span>
              <span :class="['rounded-full px-2.5 py-1 text-xs font-black', status.className]">{{ status.label }}</span>
            </div>
          </div>
          <button class="grid h-9 w-9 place-items-center rounded-md border border-slate-200 text-slate-500 transition hover:bg-slate-50" aria-label="Đóng hồ sơ" @click="emit('close')">
            <X class="h-5 w-5" />
          </button>
        </header>

        <div class="flex-1 space-y-5 overflow-y-auto px-6 py-5">
          <section class="grid grid-cols-3 gap-3">
            <div class="rounded-lg bg-red-50 p-3">
              <Droplets class="h-4 w-4 text-[#E31837]" />
              <p class="mt-3 text-lg font-black text-slate-950">{{ donor?.blood_type ?? '--' }}</p>
              <p class="text-[10px] font-bold uppercase tracking-wide text-slate-500">Nhóm máu</p>
            </div>
            <div class="rounded-lg bg-emerald-50 p-3">
              <Award class="h-4 w-4 text-emerald-600" />
              <p class="mt-3 text-lg font-black text-slate-950">{{ donor?.hero_level ?? '--' }}</p>
              <p class="text-[10px] font-bold uppercase tracking-wide text-slate-500">Cấp hiến</p>
            </div>
            <div class="rounded-lg bg-slate-100 p-3">
              <HeartPulse class="h-4 w-4 text-slate-700" />
              <p class="mt-3 text-lg font-black text-slate-950">{{ donor?.total_donations ?? '--' }}</p>
              <p class="text-[10px] font-bold uppercase tracking-wide text-slate-500">Lần hiến</p>
            </div>
          </section>

          <section class="rounded-lg border border-slate-200 p-4">
            <div class="flex items-center gap-2 text-sm font-black text-slate-900">
              <ShieldCheck class="h-4 w-4 text-emerald-600" />
              Xác thực và liên hệ
            </div>
            <div class="mt-3 space-y-3 text-sm">
              <div class="flex items-center justify-between gap-3">
                <span class="text-slate-500">Nhóm máu</span>
                <span class="inline-flex items-center gap-1 font-black text-slate-900">
                  <BadgeCheck v-if="donor?.blood_type_verification_status === 'verified'" class="h-4 w-4 text-emerald-600" />
                  {{ donor?.blood_type_verification_status === 'verified' ? 'Đã xác thực' : 'Tự khai báo' }}
                </span>
              </div>
              <a v-if="donor?.phone" :href="`tel:${donor.phone}`" class="flex items-center justify-between gap-3 rounded-md bg-slate-50 px-3 py-2 font-bold text-slate-700 transition hover:bg-slate-100">
                <span class="flex items-center gap-2"><Phone class="h-4 w-4 text-[#E31837]" /> {{ donor.phone }}</span>
                <span class="text-xs text-[#E31837]">Gọi</span>
              </a>
              <p v-else class="text-sm font-semibold text-slate-400">Chưa có số điện thoại liên hệ.</p>
            </div>
          </section>

          <section class="rounded-lg border border-slate-200 p-4">
            <div class="flex items-center gap-2 text-sm font-black text-slate-900">
              <MapPin class="h-4 w-4 text-[#E31837]" />
              Trạng thái điều phối
            </div>
            <dl class="mt-3 space-y-3 text-sm">
              <div class="flex items-center justify-between gap-3">
                <dt class="text-slate-500">ETA dự kiến</dt>
                <dd class="font-black text-slate-900">{{ commitment.eta_minutes ? `${commitment.eta_minutes} phút` : 'Chưa cập nhật' }}</dd>
              </div>
              <div class="flex items-center justify-between gap-3">
                <dt class="text-slate-500">Cam kết lúc</dt>
                <dd class="font-bold text-slate-900">{{ formatDateTime(commitment.committed_at) }}</dd>
              </div>
              <div class="flex items-center justify-between gap-3">
                <dt class="flex items-center gap-1 text-slate-500"><Clock3 class="h-3.5 w-3.5" /> Vị trí cập nhật</dt>
                <dd class="font-bold text-slate-900">{{ formatDateTime(commitment.last_location_at) }}</dd>
              </div>
            </dl>
            <p class="mt-4 rounded-md bg-slate-50 p-3 text-xs font-semibold leading-relaxed text-slate-500">
              Vị trí chỉ phục vụ điều phối ca SOS đang mở và không được hiển thị sau khi ca kết thúc.
            </p>
          </section>
        </div>
      </aside>
    </div>
  </Teleport>
</template>
