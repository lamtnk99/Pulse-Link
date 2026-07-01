<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { CalendarRange, Filter, Loader2, Plus, RefreshCw, X } from '@lucide/vue'
import type { DonationEvent, Province, Ward } from '../types'

type EventFilter = 'Tất cả' | 'Nháp' | 'Sắp diễn ra' | 'Đang diễn ra' | 'Đã kết thúc'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000'
const events = ref<DonationEvent[]>([])
const provinces = ref<Province[]>([])
const wards = ref<Ward[]>([])
const isLoading = ref(false)
const isSaving = ref(false)
const showModal = ref(false)
const filterStatus = ref<EventFilter>('Tất cả')
const statusFilters: EventFilter[] = ['Tất cả', 'Nháp', 'Sắp diễn ra', 'Đang diễn ra', 'Đã kết thúc']

const form = reactive({
  title: '',
  organizer: 'Bệnh viện Chợ Rẫy',
  description: '',
  date: '2026-07-20',
  startTime: '08:00',
  endTime: '12:00',
  locationName: '',
  provinceCode: '79',
  wardCode: '',
  latitude: 10.7565,
  longitude: 106.6594,
  capacity: 120,
  urgency: 'normal' as 'normal' | 'high',
  imageUrl: 'https://images.unsplash.com/photo-1615461066841-6116e61058f4?auto=format&fit=crop&q=80&w=900',
  isPublished: true,
})

const filteredEvents = computed(() =>
  filterStatus.value === 'Tất cả'
    ? events.value
    : events.value.filter((event) => eventStatus(event) === filterStatus.value),
)
const totalCapacity = computed(() => events.value.reduce((total, event) => total + event.capacity, 0))
const totalBooked = computed(() => events.value.reduce((total, event) => total + event.booked_count, 0))

function eventStatus(event: DonationEvent): EventFilter {
  if (!event.is_published) return 'Nháp'

  const now = new Date()
  const startsAt = new Date(event.starts_at)
  const endsAt = new Date(event.ends_at)
  if (endsAt < now) return 'Đã kết thúc'
  if (startsAt <= now && endsAt >= now) return 'Đang diễn ra'
  return 'Sắp diễn ra'
}

function formatDateTime(value: string) {
  return new Intl.DateTimeFormat('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(new Date(value))
}

async function loadEvents() {
  isLoading.value = true
  try {
    const response = await fetch(`${apiBaseUrl}/api/admin/donation-events`)
    const payload = (await response.json()) as { data: DonationEvent[] }
    events.value = payload.data
  } finally {
    isLoading.value = false
  }
}

async function loadProvinces() {
  const response = await fetch(`${apiBaseUrl}/api/locations/provinces`)
  const payload = (await response.json()) as { data: Province[] }
  provinces.value = payload.data
}

async function loadWards(provinceCode: string) {
  if (!provinceCode) {
    wards.value = []
    return
  }

  const response = await fetch(`${apiBaseUrl}/api/locations/provinces/${provinceCode}/wards`)
  const payload = (await response.json()) as { data: Ward[] }
  wards.value = payload.data
  if (!wards.value.some((ward) => ward.code === form.wardCode)) {
    form.wardCode = wards.value[0]?.code ?? ''
  }
}

function openCreateModal() {
  showModal.value = true
  void loadWards(form.provinceCode)
}

async function createEvent() {
  if (!form.title || !form.locationName || !form.wardCode) return

  isSaving.value = true
  try {
    const response = await fetch(`${apiBaseUrl}/api/admin/donation-events`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        title: form.title,
        organizer: form.organizer,
        description: form.description,
        starts_at: `${form.date}T${form.startTime}:00`,
        ends_at: `${form.date}T${form.endTime}:00`,
        location_name: form.locationName,
        province_code: form.provinceCode,
        ward_code: form.wardCode,
        latitude: form.latitude,
        longitude: form.longitude,
        urgency: form.urgency,
        image_url: form.imageUrl,
        capacity: form.capacity,
        is_published: form.isPublished,
      }),
    })
    const payload = (await response.json()) as { data: DonationEvent }
    events.value = [payload.data, ...events.value]
    form.title = ''
    form.description = ''
    form.locationName = ''
    form.capacity = 120
    showModal.value = false
  } finally {
    isSaving.value = false
  }
}

watch(
  () => form.provinceCode,
  (provinceCode) => {
    void loadWards(provinceCode)
  },
)

onMounted(async () => {
  await Promise.all([loadEvents(), loadProvinces()])
  await loadWards(form.provinceCode)
})
</script>

<template>
  <div class="space-y-5">
    <section class="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
      <div>
        <p class="text-xs font-black uppercase tracking-[0.22em] text-[#E31837]">Lịch thường quy</p>
        <h2 class="mt-2 text-2xl font-black text-slate-950">Quản lý sự kiện hiến máu</h2>
        <p class="mt-1 text-sm text-slate-500">Dữ liệu được đồng bộ trực tiếp từ Laravel cho Mobile App.</p>
      </div>
      <div class="flex flex-wrap gap-2">
        <button class="inline-flex h-10 items-center gap-2 rounded-md border border-slate-200 px-4 text-xs font-black uppercase text-slate-600" @click="loadEvents">
          <RefreshCw class="h-4 w-4" />
          Làm mới
        </button>
        <button class="inline-flex h-10 items-center gap-2 rounded-md bg-[#E31837] px-4 text-xs font-black uppercase text-white" @click="openCreateModal">
          <Plus class="h-4 w-4" />
          Tạo lịch hiến máu
        </button>
      </div>
    </section>

    <section class="grid gap-4 md:grid-cols-3">
      <article class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Tổng sự kiện</p>
        <p class="mt-1 text-2xl font-black text-slate-950">{{ events.length }}</p>
      </article>
      <article class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Chỉ tiêu tiếp nhận</p>
        <p class="mt-1 text-2xl font-black text-slate-950">{{ totalCapacity }}</p>
      </article>
      <article class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Người đã đặt lịch</p>
        <p class="mt-1 text-2xl font-black text-[#E31837]">{{ totalBooked }}</p>
      </article>
    </section>

    <section class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <div class="flex flex-wrap items-center gap-2">
        <Filter class="h-4 w-4 text-slate-400" />
        <button
          v-for="status in statusFilters"
          :key="status"
          class="rounded-md px-3 py-1.5 text-xs font-bold"
          :class="filterStatus === status ? 'bg-slate-950 text-white' : 'bg-slate-50 text-slate-600 hover:bg-slate-100'"
          @click="filterStatus = status"
        >
          {{ status }}
        </button>
      </div>
    </section>

    <section class="overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm">
      <div v-if="isLoading" class="flex items-center justify-center gap-2 p-8 text-sm font-bold text-slate-500">
        <Loader2 class="h-4 w-4 animate-spin" />
        Đang tải lịch hiến máu...
      </div>
      <table v-else class="w-full min-w-[920px] text-left text-sm">
        <thead class="bg-slate-50 text-[11px] font-black uppercase tracking-[0.16em] text-slate-500">
          <tr>
            <th class="px-5 py-4">Tên sự kiện</th>
            <th class="px-5 py-4">Thời gian</th>
            <th class="px-5 py-4">Địa điểm</th>
            <th class="px-5 py-4 text-center">Đăng ký</th>
            <th class="px-5 py-4 text-center">Còn lại</th>
            <th class="px-5 py-4 text-center">Trạng thái</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100">
          <tr v-for="event in filteredEvents" :key="event.id" class="hover:bg-slate-50/60">
            <td class="px-5 py-4">
              <p class="font-bold text-slate-950">{{ event.title }}</p>
              <p class="mt-1 text-xs text-slate-500">{{ event.organizer }}</p>
            </td>
            <td class="px-5 py-4 text-slate-600">{{ formatDateTime(event.starts_at) }}</td>
            <td class="px-5 py-4 text-slate-600">
              <p>{{ event.location_name }}</p>
              <p class="mt-1 text-xs text-slate-400">{{ event.province?.full_name ?? event.province_code }}</p>
            </td>
            <td class="px-5 py-4 text-center font-black text-emerald-600">{{ event.booked_count }}</td>
            <td class="px-5 py-4 text-center font-black">{{ event.slots_left }}</td>
            <td class="px-5 py-4 text-center">
              <span class="rounded-full px-2.5 py-1 text-xs font-black" :class="eventStatus(event) === 'Đang diễn ra' ? 'bg-emerald-50 text-emerald-700' : eventStatus(event) === 'Sắp diễn ra' ? 'bg-blue-50 text-blue-700' : 'bg-slate-100 text-slate-600'">
                {{ eventStatus(event) }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </section>

    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
      <form class="max-h-[92vh] w-full max-w-3xl overflow-y-auto rounded-lg bg-white p-5 shadow-2xl" @submit.prevent="createEvent">
        <div class="flex items-center justify-between border-b border-slate-200 pb-4">
          <h3 class="flex items-center gap-2 text-lg font-black text-slate-950">
            <CalendarRange class="h-5 w-5 text-[#E31837]" />
            Tạo lịch hiến máu
          </h3>
          <button type="button" class="rounded-md p-2 text-slate-500 hover:bg-slate-100" @click="showModal = false">
            <X class="h-4 w-4" />
          </button>
        </div>
        <div class="mt-4 grid gap-4">
          <input v-model="form.title" required class="rounded-md border border-slate-200 px-3 py-2 text-sm" placeholder="Tên chiến dịch" />
          <textarea v-model="form.description" rows="3" class="rounded-md border border-slate-200 px-3 py-2 text-sm" placeholder="Mô tả ngắn cho màn chi tiết trên Mobile"></textarea>
          <div class="grid gap-3 md:grid-cols-2">
            <input v-model="form.organizer" required class="rounded-md border border-slate-200 px-3 py-2 text-sm" placeholder="Đơn vị tổ chức" />
            <input v-model="form.locationName" required class="rounded-md border border-slate-200 px-3 py-2 text-sm" placeholder="Địa điểm tổ chức" />
          </div>
          <div class="grid gap-3 md:grid-cols-3">
            <input v-model="form.date" required type="date" class="rounded-md border border-slate-200 px-3 py-2 text-sm" />
            <input v-model="form.startTime" required type="time" class="rounded-md border border-slate-200 px-3 py-2 text-sm" />
            <input v-model="form.endTime" required type="time" class="rounded-md border border-slate-200 px-3 py-2 text-sm" />
          </div>
          <div class="grid gap-3 md:grid-cols-2">
            <select v-model="form.provinceCode" required class="rounded-md border border-slate-200 px-3 py-2 text-sm">
              <option v-for="province in provinces" :key="province.code" :value="province.code">{{ province.full_name }}</option>
            </select>
            <select v-model="form.wardCode" required class="rounded-md border border-slate-200 px-3 py-2 text-sm">
              <option v-for="ward in wards" :key="ward.code" :value="ward.code">{{ ward.full_name }}</option>
            </select>
          </div>
          <div class="grid gap-3 md:grid-cols-4">
            <input v-model.number="form.latitude" required type="number" step="0.0000001" class="rounded-md border border-slate-200 px-3 py-2 text-sm" placeholder="Vĩ độ" />
            <input v-model.number="form.longitude" required type="number" step="0.0000001" class="rounded-md border border-slate-200 px-3 py-2 text-sm" placeholder="Kinh độ" />
            <input v-model.number="form.capacity" min="1" required type="number" class="rounded-md border border-slate-200 px-3 py-2 text-sm" placeholder="Chỉ tiêu" />
            <select v-model="form.urgency" class="rounded-md border border-slate-200 px-3 py-2 text-sm">
              <option value="normal">Bình thường</option>
              <option value="high">Cần ưu tiên</option>
            </select>
          </div>
          <input v-model="form.imageUrl" class="rounded-md border border-slate-200 px-3 py-2 text-sm" placeholder="Ảnh đại diện sự kiện" />
          <label class="flex items-center gap-2 text-sm font-bold text-slate-700">
            <input v-model="form.isPublished" type="checkbox" class="h-4 w-4 rounded border-slate-300 text-[#E31837]" />
            Xuất bản để Mobile nhìn thấy ngay
          </label>
        </div>
        <div class="mt-5 flex justify-end gap-3">
          <button type="button" class="rounded-md border border-slate-200 px-4 py-2 text-sm font-bold text-slate-700" @click="showModal = false">Hủy</button>
          <button type="submit" class="inline-flex items-center gap-2 rounded-md bg-[#E31837] px-4 py-2 text-sm font-black text-white">
            <Loader2 v-if="isSaving" class="h-4 w-4 animate-spin" />
            Xác nhận tạo
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
