<script setup lang="ts">
import { computed, reactive, watch } from 'vue'
import { Building2, Clock3, MapPin, Radio, X } from '@lucide/vue'
import type { Hospital, SosPayload } from '../types'

const props = defineProps<{
  hospitals: Hospital[]
  defaultHospitalId: number | null
  errorMessage?: string | null
  submitting?: boolean
}>()

const emit = defineEmits<{
  close: []
  submit: [payload: SosPayload]
}>()

const dispatchLevels: Record<SosPayload['level'], { title: string; radius: string; description: string }> = {
  level1: {
    title: 'Cấp 1',
    radius: 'Bán kính 15km',
    description: 'Ưu tiên tình nguyện viên trong vùng phản ứng nhanh gần bệnh viện.',
  },
  level2: {
    title: 'Cấp 2',
    radius: 'Nội tỉnh 30km',
    description: 'Mở rộng tới người hiến cùng tỉnh trong 30km.',
  },
  level3: {
    title: 'Cấp 3',
    radius: 'Chi viện tới 120km',
    description: 'Kích hoạt thêm nhóm liên tỉnh theo thuật toán điều phối.',
  },
}

const form = reactive<SosPayload>({
  hospital_id: props.defaultHospitalId ?? props.hospitals[0]?.id ?? 0,
  required_blood_type: 'O+',
  compatibility_mode: 'compatible',
  level: 'level1',
  units_needed: 4,
  message: 'Báo động đỏ thiếu máu cho ca cấp cứu. Vui lòng phản hồi nếu bạn có thể đến hiến máu.',
  expires_at: new Date(Date.now() + 45 * 60 * 1000).toISOString(),
})

const selectedHospital = computed(() => props.hospitals.find((hospital) => hospital.id === form.hospital_id))
const selectedDispatchLevel = computed(() => dispatchLevels[form.level])
const hasHospitals = computed(() => props.hospitals.length > 0)
const hospitalLocationLabel = computed(() => {
  if (!selectedHospital.value) return 'Chưa có dữ liệu bệnh viện'

  return [
    selectedHospital.value.ward?.full_name,
    selectedHospital.value.province?.full_name ?? selectedHospital.value.province_code,
  ].filter(Boolean).join(', ')
})

function resolveHospitalId() {
  const defaultHospital = props.hospitals.find((hospital) => hospital.id === props.defaultHospitalId)

  return defaultHospital?.id ?? props.hospitals[0]?.id ?? 0
}

function submitSos() {
  if (!selectedHospital.value) return

  emit('submit', { ...form })
}

watch(
  () => [props.defaultHospitalId, props.hospitals.map((hospital) => hospital.id).join(',')],
  () => {
    if (props.hospitals.some((hospital) => hospital.id === form.hospital_id)) return
    form.hospital_id = resolveHospitalId()
  },
  { immediate: true },
)
</script>

<template>
  <div class="fixed inset-0 z-[2000] flex items-start justify-center overflow-y-auto bg-slate-950/60 p-4 py-6 backdrop-blur-sm">
    <form class="relative z-[2001] w-full max-w-5xl overflow-hidden rounded-lg bg-white shadow-2xl" @submit.prevent="submitSos">
      <div class="flex items-start justify-between gap-4 border-b border-slate-200 pb-4">
        <div class="p-5 pb-0">
          <p class="text-xs font-black uppercase tracking-[0.22em] text-[#E31837]">Báo động đỏ</p>
          <h2 class="mt-1 text-xl font-black text-slate-950">Phát lệnh SOS khẩn cấp</h2>
          <p class="mt-1 text-sm text-slate-500">
            Chọn bệnh viện làm tâm điều phối để hệ thống tính bán kính và phát lệnh theo cấp.
          </p>
        </div>
        <button type="button" class="m-5 rounded-md p-2 text-slate-500 hover:bg-slate-100" aria-label="Đóng" @click="emit('close')">
          <X class="h-5 w-5" />
        </button>
      </div>

      <div class="grid min-w-0 gap-5 p-5 lg:grid-cols-[minmax(0,1.45fr)_minmax(280px,0.7fr)]">
        <div class="min-w-0 space-y-4">
          <p v-if="errorMessage" class="rounded-md border border-red-200 bg-red-50 px-3 py-2 text-sm font-bold text-red-700">
            {{ errorMessage }}
          </p>

          <label class="grid gap-1 text-sm font-bold text-slate-700">
            Bệnh viện nhận SOS
            <select v-model.number="form.hospital_id" class="h-11 min-w-0 rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
              <option v-if="!hasHospitals" :value="0">Đang tải danh sách bệnh viện...</option>
              <option v-for="hospital in hospitals" :key="hospital.id" :value="hospital.id">
                {{ hospital.name }} - {{ hospital.province?.full_name ?? hospital.province_code }}
              </option>
            </select>
          </label>

          <div class="grid gap-4 md:grid-cols-2">
            <label class="grid gap-1 text-sm font-bold text-slate-700">
              Nhóm máu cần
              <select v-model="form.required_blood_type" class="h-11 min-w-0 rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
                <option v-for="bloodType in ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+']" :key="bloodType">
                  {{ bloodType }}
                </option>
              </select>
            </label>

            <label class="grid gap-1 text-sm font-bold text-slate-700">
              Số đơn vị máu
              <input v-model.number="form.units_needed" min="1" max="99" type="number" class="h-11 min-w-0 rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" />
            </label>
          </div>

          <label class="grid gap-1 text-sm font-bold text-slate-700">
            Phạm vi nhóm máu nhận SOS
            <select v-model="form.compatibility_mode" class="h-11 min-w-0 rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
              <option value="compatible">Mở rộng tương thích</option>
              <option value="exact">Chỉ đúng nhóm máu đã chọn</option>
            </select>
            <span class="text-xs font-semibold leading-5 text-slate-500">
              {{
                form.compatibility_mode === 'compatible'
                  ? 'Ưu tiên tốc độ: gửi tới các nhóm máu có thể truyền cho nhóm đang cần.'
                  : 'Chỉ gửi tới người hiến có cùng nhóm máu với nhóm đang cần.'
              }}
            </span>
          </label>

          <label class="grid gap-1 text-sm font-bold text-slate-700">
            Cấp điều phối
            <select v-model="form.level" class="h-11 min-w-0 rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
              <option value="level1">Cấp 1 - bán kính 15km</option>
              <option value="level2">Cấp 2 - nội tỉnh 30km</option>
              <option value="level3">Cấp 3 - chi viện liên tỉnh</option>
            </select>
          </label>

          <div class="rounded-lg border border-red-100 bg-red-50 p-4">
            <div class="flex items-start gap-3">
              <div class="grid h-9 w-9 shrink-0 place-items-center rounded-md bg-white text-[#E31837]">
                <Radio class="h-5 w-5" />
              </div>
              <div>
                <p class="text-sm font-black text-red-950">{{ selectedDispatchLevel.title }} · {{ selectedDispatchLevel.radius }}</p>
                <p class="mt-1 text-xs leading-5 text-red-700">{{ selectedDispatchLevel.description }}</p>
              </div>
            </div>
          </div>

          <label class="grid gap-1 text-sm font-bold text-slate-700">
            Nội dung phát lệnh
            <textarea v-model="form.message" rows="4" class="min-w-0 rounded-md border border-slate-200 px-3 py-2 text-sm outline-none focus:border-[#E31837]"></textarea>
          </label>
        </div>

        <aside class="min-w-0 rounded-lg border border-slate-200 bg-slate-50 p-4">
          <div class="flex items-start gap-3">
            <div class="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-white text-[#E31837]">
              <Building2 class="h-5 w-5" />
            </div>
            <div class="min-w-0">
              <p class="break-words font-black text-slate-950">{{ selectedHospital?.name ?? 'Chưa chọn bệnh viện' }}</p>
              <p class="mt-1 text-xs font-bold uppercase tracking-[0.14em] text-slate-400">{{ selectedHospital?.code ?? 'NO-DATA' }}</p>
            </div>
          </div>

          <div class="mt-4 space-y-3 text-sm">
            <div class="rounded-md bg-white p-3">
              <p class="flex items-center gap-2 text-xs font-black uppercase tracking-[0.14em] text-slate-400">
                <MapPin class="h-4 w-4" />
                Địa chỉ
              </p>
              <p class="mt-2 font-bold leading-5 text-slate-800">{{ selectedHospital?.address ?? 'Đang tải...' }}</p>
              <p class="mt-1 text-xs text-slate-500">{{ hospitalLocationLabel }}</p>
            </div>

            <div class="grid gap-3 sm:grid-cols-2 lg:grid-cols-1 xl:grid-cols-2">
              <div class="rounded-md bg-white p-3">
                <p class="text-xs font-black uppercase tracking-[0.14em] text-slate-400">Tọa độ</p>
                <p class="mt-2 font-mono text-xs font-bold text-slate-700">
                  {{ selectedHospital ? `${selectedHospital.latitude.toFixed(4)}, ${selectedHospital.longitude.toFixed(4)}` : '--' }}
                </p>
              </div>
              <div class="rounded-md bg-white p-3">
                <p class="text-xs font-black uppercase tracking-[0.14em] text-slate-400">Hết hạn</p>
                <p class="mt-2 flex items-center gap-1 text-xs font-bold text-slate-700">
                  <Clock3 class="h-3.5 w-3.5" />
                  45 phút
                </p>
              </div>
            </div>

            <div class="rounded-md bg-white p-3">
              <p class="text-xs font-black uppercase tracking-[0.14em] text-slate-400">Liên hệ bệnh viện</p>
              <p class="mt-2 text-xs font-bold text-slate-700">{{ selectedHospital?.contact_phone ?? 'Chưa có số điện thoại' }}</p>
              <p class="mt-1 truncate text-xs text-slate-500">{{ selectedHospital?.contact_email ?? 'Chưa có email' }}</p>
            </div>
          </div>
        </aside>
      </div>

      <div class="flex justify-end gap-3 border-t border-slate-200 p-5">
        <button type="button" class="rounded-md border border-slate-200 px-4 py-2 text-sm font-bold text-slate-700" @click="emit('close')">
          Hủy
        </button>
        <button type="submit" :disabled="!selectedHospital || submitting" class="rounded-md bg-[#E31837] px-4 py-2 text-sm font-black uppercase text-white hover:bg-red-700 disabled:cursor-not-allowed disabled:bg-slate-300">
          {{ submitting ? 'Đang phát lệnh...' : 'Phát lệnh SOS' }}
        </button>
      </div>
    </form>
  </div>
</template>
