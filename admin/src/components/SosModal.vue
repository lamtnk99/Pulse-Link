<script setup lang="ts">
import { computed, reactive } from 'vue'
import type { Hospital, SosPayload } from '../types'

const props = defineProps<{
  hospitals: Hospital[]
  defaultHospitalId: number | null
}>()

const emit = defineEmits<{
  close: []
  submit: [payload: SosPayload]
}>()

const form = reactive<SosPayload>({
  hospital_id: props.defaultHospitalId ?? props.hospitals[0]?.id ?? 1,
  required_blood_type: 'O+',
  level: 'level1',
  units_needed: 4,
  message: 'Báo động đỏ thiếu máu cho ca cấp cứu. Vui lòng phản hồi nếu bạn có thể đến hiến máu.',
  expires_at: new Date(Date.now() + 45 * 60 * 1000).toISOString(),
})

const selectedHospital = computed(() => props.hospitals.find((hospital) => hospital.id === form.hospital_id))
</script>

<template>
  <div class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
    <form class="w-full max-w-xl rounded-lg bg-white p-5 shadow-2xl" @submit.prevent="emit('submit', { ...form })">
      <div class="flex items-start justify-between gap-4 border-b border-slate-200 pb-4">
        <div>
          <p class="text-xs font-black uppercase tracking-[0.22em] text-[#E31837]">Báo động đỏ</p>
          <h2 class="mt-1 text-xl font-black text-slate-950">Phát lệnh SOS khẩn cấp</h2>
          <p class="mt-1 text-sm text-slate-500">{{ selectedHospital?.address }}</p>
        </div>
        <button type="button" class="rounded-md px-2.5 py-2 text-sm font-black text-slate-500 hover:bg-slate-100" @click="emit('close')">
          Đóng
        </button>
      </div>

      <div class="mt-5 grid gap-4 md:grid-cols-2">
        <label class="grid gap-1 text-sm font-bold text-slate-700">
          Bệnh viện
          <select v-model.number="form.hospital_id" class="rounded-md border border-slate-200 px-3 py-2">
            <option v-for="hospital in hospitals" :key="hospital.id" :value="hospital.id">
              {{ hospital.name }} - {{ hospital.province?.full_name ?? hospital.province_code }}
            </option>
          </select>
        </label>

        <label class="grid gap-1 text-sm font-bold text-slate-700">
          Nhóm máu cần
          <select v-model="form.required_blood_type" class="rounded-md border border-slate-200 px-3 py-2">
            <option v-for="bloodType in ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+']" :key="bloodType">
              {{ bloodType }}
            </option>
          </select>
        </label>

        <label class="grid gap-1 text-sm font-bold text-slate-700">
          Cấp điều phối
          <select v-model="form.level" class="rounded-md border border-slate-200 px-3 py-2">
            <option value="level1">Cấp 1 - bán kính 5km</option>
            <option value="level2">Cấp 2 - nội tỉnh 30km</option>
            <option value="level3">Cấp 3 - chi viện liên tỉnh</option>
          </select>
        </label>

        <label class="grid gap-1 text-sm font-bold text-slate-700">
          Số đơn vị máu
          <input v-model.number="form.units_needed" min="1" max="99" type="number" class="rounded-md border border-slate-200 px-3 py-2" />
        </label>
      </div>

      <label class="mt-4 grid gap-1 text-sm font-bold text-slate-700">
        Nội dung phát lệnh
        <textarea v-model="form.message" rows="4" class="rounded-md border border-slate-200 px-3 py-2"></textarea>
      </label>

      <div class="mt-5 flex justify-end gap-3">
        <button type="button" class="rounded-md border border-slate-200 px-4 py-2 text-sm font-bold text-slate-700" @click="emit('close')">
          Hủy
        </button>
        <button type="submit" class="rounded-md bg-[#E31837] px-4 py-2 text-sm font-black uppercase text-white hover:bg-red-700">
          Phát lệnh SOS
        </button>
      </div>
    </form>
  </div>
</template>
