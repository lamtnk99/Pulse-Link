<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import {
  Ban,
  ChevronLeft,
  ChevronRight,
  ClipboardCheck,
  Edit3,
  Eye,
  Loader2,
  MoreHorizontal,
  Plus,
  RefreshCw,
  Search,
  X,
} from '@lucide/vue'
import type {
  DonationAppointment,
  DonationAppointmentStatus,
  DonationEvent,
  Hospital,
  PaginatedResponse,
  PaginationMeta,
  Province,
  Ward,
} from '../types'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000'
const events = ref<DonationEvent[]>([])
const selectedEvent = ref<DonationEvent | null>(null)
const hospitals = ref<Hospital[]>([])
const provinces = ref<Province[]>([])
const wards = ref<Ward[]>([])
const isLoading = ref(false)
const isSaving = ref(false)
const showModal = ref(false)
const showCompleteModal = ref(false)
const editingEvent = ref<DonationEvent | null>(null)
const completingAppointment = ref<DonationAppointment | null>(null)
const errorMessage = ref('')
const page = ref(1)
const meta = ref<PaginationMeta>({ current_page: 1, last_page: 1, per_page: 10, total: 0 })
const appointmentSearch = ref('')
const appointmentPage = ref(1)
const appointmentPerPage = 8
const openAppointmentActionId = ref<string | null>(null)

const filters = reactive({
  q: '',
  status: '',
  provinceCode: '',
  hospitalId: null as number | null,
  dateFrom: '',
  dateTo: '',
})

const form = reactive({
  hospitalId: null as number | null,
  title: '',
  organizer: '',
  description: '',
  date: '',
  startTime: '',
  endTime: '',
  locationName: '',
  provinceCode: '79',
  wardCode: '',
  latitude: 10.7565,
  longitude: 106.6594,
  capacity: 120,
  urgency: 'normal' as 'normal' | 'high',
  imageUrl: '',
  isPublished: true,
})

const completeForm = reactive({
  volumeMl: 350,
  screeningStatus: 'eligible' as 'pending' | 'eligible' | 'ineligible',
  screeningNotes: '',
  resultSummary: '',
  publishResult: false,
})

const statusFilters = [
  { value: '', label: 'Tất cả trạng thái' },
  { value: 'upcoming', label: 'Sắp diễn ra' },
  { value: 'running', label: 'Đang diễn ra' },
  { value: 'ended', label: 'Đã kết thúc' },
  { value: 'cancelled', label: 'Đã hủy' },
  { value: 'published', label: 'Đã xuất bản' },
  { value: 'draft', label: 'Nháp' },
]
const volumeOptions = [250, 350, 450]
const appointmentStatusLabels: Record<DonationAppointmentStatus, string> = {
  booked: 'Đã đặt',
  checked_in: 'Đã check-in',
  deferred: 'Tạm hoãn',
  completed: 'Hoàn thành',
  no_show: 'Không đến',
  cancelled: 'Đã hủy',
}

const hasBookings = computed(() => (editingEvent.value?.booked_count ?? 0) > 0)
const modalTitle = computed(() => (editingEvent.value ? 'Sửa lịch hiến máu' : 'Tạo lịch hiến máu'))
const appointmentStats = computed(() => selectedEvent.value?.appointment_stats ?? {
  booked: 0,
  checked_in: 0,
  deferred: 0,
  no_show: 0,
  completed: 0,
  cancelled: 0,
  total_volume_ml: 0,
})
const appointmentVolumeSelections = reactive<Record<string, number>>({})
const filteredAppointments = computed(() => {
  const appointments = selectedEvent.value?.appointments ?? []
  const keyword = appointmentSearch.value.trim().toLowerCase()

  if (!keyword) return appointments

  return appointments.filter((appointment) => {
    const donor = appointment.user
    return [
      donor?.name,
      donor?.phone,
      donor?.blood_type,
      appointment.status,
    ].some((value) => value?.toLowerCase().includes(keyword))
  })
})
const appointmentPageCount = computed(() => Math.max(1, Math.ceil(filteredAppointments.value.length / appointmentPerPage)))
const paginatedAppointments = computed(() => {
  const start = (appointmentPage.value - 1) * appointmentPerPage
  return filteredAppointments.value.slice(start, start + appointmentPerPage)
})
const appointmentRangeStart = computed(() => filteredAppointments.value.length === 0 ? 0 : (appointmentPage.value - 1) * appointmentPerPage + 1)
const appointmentRangeEnd = computed(() => Math.min(appointmentPage.value * appointmentPerPage, filteredAppointments.value.length))

function toDateInput(value: string) {
  const date = new Date(value)
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`
}

function toTimeInput(value: string) {
  const date = new Date(value)
  return `${String(date.getHours()).padStart(2, '0')}:${String(date.getMinutes()).padStart(2, '0')}`
}

function formatDateTime(value: string | null | undefined) {
  if (!value) return '--'
  return new Intl.DateTimeFormat('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(new Date(value))
}

function formatNumber(value: number | undefined) {
  return new Intl.NumberFormat('vi-VN').format(value ?? 0)
}

function volumeForAppointment(appointment: DonationAppointment) {
  return appointmentVolumeSelections[appointment.id] ?? appointment.volume_ml ?? 350
}

function syncAppointmentVolumeSelections() {
  for (const appointment of selectedEvent.value?.appointments ?? []) {
    appointmentVolumeSelections[appointment.id] = appointment.volume_ml ?? appointmentVolumeSelections[appointment.id] ?? 350
  }
}

function eventStatus(event: DonationEvent) {
  if (event.cancelled_at) return 'Đã hủy'
  if (!event.is_published) return 'Nháp'
  const now = new Date()
  const startsAt = new Date(event.starts_at)
  const endsAt = new Date(event.ends_at)
  if (endsAt < now) return 'Đã kết thúc'
  if (startsAt <= now && endsAt >= now) return 'Đang diễn ra'
  return 'Sắp diễn ra'
}

function statusClass(event: DonationEvent) {
  const status = eventStatus(event)
  if (status === 'Đang diễn ra') return 'bg-emerald-50 text-emerald-700'
  if (status === 'Sắp diễn ra') return 'bg-blue-50 text-blue-700'
  if (status === 'Nháp') return 'bg-amber-50 text-amber-700'
  if (status === 'Đã hủy') return 'bg-red-50 text-red-700'
  return 'bg-slate-100 text-slate-600'
}

function appointmentClass(status: DonationAppointmentStatus) {
  if (status === 'completed') return 'bg-emerald-50 text-emerald-700'
  if (status === 'checked_in') return 'bg-blue-50 text-blue-700'
  if (status === 'deferred') return 'bg-amber-50 text-amber-700'
  if (status === 'cancelled' || status === 'no_show') return 'bg-slate-100 text-slate-500'
  return 'bg-red-50 text-[#E31837]'
}

function isTerminalAppointment(appointment: DonationAppointment) {
  return appointment.status === 'cancelled' || appointment.status === 'completed'
}

function resetForm() {
  const firstHospital = hospitals.value[0]
  const nextWeek = new Date()
  nextWeek.setDate(nextWeek.getDate() + 7)

  form.hospitalId = firstHospital?.id ?? null
  form.title = ''
  form.organizer = firstHospital?.name ?? 'Đơn vị tiếp nhận máu'
  form.description = ''
  form.date = toDateInput(nextWeek.toISOString())
  form.startTime = '08:00'
  form.endTime = '12:00'
  form.locationName = firstHospital?.address ?? ''
  form.provinceCode = firstHospital?.province_code ?? '79'
  form.wardCode = firstHospital?.ward_code ?? ''
  form.latitude = firstHospital?.latitude ?? 10.7565
  form.longitude = firstHospital?.longitude ?? 106.6594
  form.capacity = 120
  form.urgency = 'normal'
  form.imageUrl = 'https://images.unsplash.com/photo-1615461066841-6116e61058f4?auto=format&fit=crop&q=80&w=900'
  form.isPublished = true
  errorMessage.value = ''
}

async function loadEvents() {
  isLoading.value = true
  try {
    const params = new URLSearchParams({
      page: String(page.value),
      per_page: String(meta.value.per_page),
    })
    if (filters.status) params.set('status', filters.status)
    if (filters.q.trim()) params.set('q', filters.q.trim())
    if (filters.provinceCode) params.set('province_code', filters.provinceCode)
    if (filters.hospitalId) params.set('hospital_id', String(filters.hospitalId))
    if (filters.dateFrom) params.set('date_from', filters.dateFrom)
    if (filters.dateTo) params.set('date_to', filters.dateTo)

    const response = await fetch(`${apiBaseUrl}/api/admin/donation-events?${params.toString()}`)
    if (!response.ok) await throwApiError(response)
    const payload = (await response.json()) as PaginatedResponse<DonationEvent>
    events.value = payload.data
    meta.value = payload.meta
    page.value = payload.meta.current_page
    if (selectedEvent.value) {
      const stillOnPage = events.value.find((event) => event.id === selectedEvent.value?.id)
      if (stillOnPage) await loadEventDetail(stillOnPage)
    }
  } finally {
    isLoading.value = false
  }
}

async function loadEventDetail(event: DonationEvent) {
  const response = await fetch(`${apiBaseUrl}/api/admin/donation-events/${event.id}`)
  if (!response.ok) await throwApiError(response)
  const payload = (await response.json()) as { data: DonationEvent }
  selectedEvent.value = payload.data
  appointmentSearch.value = ''
  appointmentPage.value = 1
  syncAppointmentVolumeSelections()
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

async function loadHospitals() {
  const response = await fetch(`${apiBaseUrl}/api/admin/dashboard`)
  const payload = (await response.json()) as { data: { hospitals: Hospital[] } }
  hospitals.value = payload.data.hospitals
  if (!filters.hospitalId && hospitals.value.length === 1) filters.hospitalId = hospitals.value[0].id
  if (!form.hospitalId) form.hospitalId = hospitals.value[0]?.id ?? null
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
  editingEvent.value = null
  resetForm()
  showModal.value = true
  void loadWards(form.provinceCode)
}

function openEditModal(event: DonationEvent) {
  editingEvent.value = event
  errorMessage.value = ''
  form.hospitalId = event.hospital?.id ?? null
  form.title = event.title
  form.organizer = event.organizer
  form.description = event.description ?? ''
  form.date = toDateInput(event.starts_at)
  form.startTime = toTimeInput(event.starts_at)
  form.endTime = toTimeInput(event.ends_at)
  form.locationName = event.location_name
  form.provinceCode = event.province_code
  form.wardCode = event.ward_code ?? ''
  form.latitude = event.location.latitude
  form.longitude = event.location.longitude
  form.capacity = event.capacity
  form.urgency = event.urgency
  form.imageUrl = event.image_url ?? ''
  form.isPublished = event.is_published
  showModal.value = true
  void loadWards(form.provinceCode)
}

function buildPayload() {
  const payload: Record<string, unknown> = {
    hospital_id: form.hospitalId,
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
  }

  if (hasBookings.value) {
    for (const key of ['hospital_id', 'starts_at', 'ends_at', 'location_name', 'province_code', 'ward_code', 'latitude', 'longitude']) {
      delete payload[key]
    }
  }

  return payload
}

async function submitEvent() {
  if (!form.title || !form.organizer) return
  if (editingEvent.value && form.capacity < editingEvent.value.booked_count) {
    errorMessage.value = 'Chỉ tiêu tiếp nhận không được nhỏ hơn số người đã đặt lịch.'
    return
  }

  isSaving.value = true
  errorMessage.value = ''
  try {
    const endpoint = editingEvent.value
      ? `${apiBaseUrl}/api/admin/donation-events/${editingEvent.value.id}`
      : `${apiBaseUrl}/api/admin/donation-events`
    const response = await fetch(endpoint, {
      method: editingEvent.value ? 'PUT' : 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(buildPayload()),
    })
    if (!response.ok) await throwApiError(response)

    showModal.value = false
    await loadEvents()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'Không thể lưu lịch hiến máu.'
  } finally {
    isSaving.value = false
  }
}

async function cancelEvent(event: DonationEvent) {
  if (!window.confirm(`Hủy lịch hiến máu "${event.title}"?`)) return
  const cancelReason = window.prompt('Lý do hủy sự kiện', 'Sự kiện được hủy bởi bệnh viện.') ?? undefined
  const response = await fetch(`${apiBaseUrl}/api/admin/donation-events/${event.id}`, {
    method: 'DELETE',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({ cancel_reason: cancelReason }),
  })
  if (!response.ok) await throwApiError(response)
  await loadEvents()
  if (selectedEvent.value?.id === event.id) await loadEventDetail(event)
}

async function appointmentAction(appointment: DonationAppointment, action: 'check-in' | 'cancel' | 'no-show' | 'defer' | 'publish-result', body: Record<string, unknown> = {}) {
  if (!selectedEvent.value) return
  const response = await fetch(`${apiBaseUrl}/api/admin/donation-events/${selectedEvent.value.id}/appointments/${appointment.id}/${action}`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
  })
  if (!response.ok) await throwApiError(response)
  await loadEventDetail(selectedEvent.value)
  await loadEvents()
}

async function deferAppointment(appointment: DonationAppointment) {
  const screeningNotes = window.prompt('Lý do tạm hoãn', appointment.screening_notes ?? '')
  if (screeningNotes === null) return
  await appointmentAction(appointment, 'defer', { screening_notes: screeningNotes })
}

async function noShowAppointment(appointment: DonationAppointment) {
  if (!window.confirm('Đánh dấu người này không đến hiến máu?')) return
  await appointmentAction(appointment, 'no-show')
}

async function cancelAppointment(appointment: DonationAppointment) {
  const cancelReason = window.prompt('Lý do hủy lịch', appointment.cancel_reason ?? '')
  if (cancelReason === null) return
  await appointmentAction(appointment, 'cancel', { cancel_reason: cancelReason })
}

async function handleAppointmentAction(appointment: DonationAppointment, action: string) {
  openAppointmentActionId.value = null
  if (action === 'check-in') {
    await appointmentAction(appointment, 'check-in')
    return
  }

  if (action === 'complete') {
    openCompleteModal(appointment)
    return
  }

  if (action === 'defer') {
    await deferAppointment(appointment)
    return
  }

  if (action === 'no-show') {
    await noShowAppointment(appointment)
    return
  }

  if (action === 'cancel') {
    await cancelAppointment(appointment)
    return
  }

  if (action === 'publish-result') {
    await appointmentAction(appointment, 'publish-result', { publish_result: true })
  }
}

function toggleAppointmentActions(appointment: DonationAppointment) {
  openAppointmentActionId.value = openAppointmentActionId.value === appointment.id ? null : appointment.id
}

function openCompleteModal(appointment: DonationAppointment) {
  completingAppointment.value = appointment
  completeForm.volumeMl = volumeForAppointment(appointment)
  completeForm.screeningStatus = appointment.screening_status ?? 'eligible'
  completeForm.screeningNotes = appointment.screening_notes ?? ''
  completeForm.resultSummary = appointment.result_summary ?? ''
  completeForm.publishResult = appointment.result_published_at !== null && appointment.result_published_at !== undefined
  showCompleteModal.value = true
}

function closeEventModal() {
  showModal.value = false
}

function closeCompleteModal() {
  showCompleteModal.value = false
}

async function submitCompletion() {
  if (!selectedEvent.value || !completingAppointment.value) return
  const response = await fetch(`${apiBaseUrl}/api/admin/donation-events/${selectedEvent.value.id}/appointments/${completingAppointment.value.id}/complete`, {
    method: 'POST',
    headers: {
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      volume_ml: completeForm.volumeMl,
      screening_status: completeForm.screeningStatus,
      screening_notes: completeForm.screeningNotes,
      result_summary: completeForm.resultSummary,
      publish_result: completeForm.publishResult,
    }),
  })
  if (!response.ok) await throwApiError(response)
  showCompleteModal.value = false
  await loadEventDetail(selectedEvent.value)
  await loadEvents()
}

async function throwApiError(response: Response): Promise<never> {
  const payload = await response.json().catch(() => null) as { message?: string; errors?: Record<string, string[]> } | null
  const firstError = payload?.errors ? Object.values(payload.errors)[0]?.[0] : null
  throw new Error(firstError ?? payload?.message ?? 'Yêu cầu không hợp lệ.')
}

function goToPage(nextPage: number) {
  if (nextPage < 1 || nextPage > meta.value.last_page || nextPage === page.value) return
  page.value = nextPage
  void loadEvents()
}

function goToAppointmentPage(nextPage: number) {
  if (nextPage < 1 || nextPage > appointmentPageCount.value || nextPage === appointmentPage.value) return
  appointmentPage.value = nextPage
  openAppointmentActionId.value = null
}

watch(
  () => form.provinceCode,
  (provinceCode) => {
    void loadWards(provinceCode)
  },
)

watch(filters, () => {
  page.value = 1
  void loadEvents()
})

watch(appointmentSearch, () => {
  appointmentPage.value = 1
  openAppointmentActionId.value = null
})

watch(appointmentPageCount, (pageCount) => {
  if (appointmentPage.value > pageCount) {
    appointmentPage.value = pageCount
  }
})

onMounted(async () => {
  await Promise.all([loadHospitals(), loadProvinces()])
  resetForm()
  await loadEvents()
})
</script>

<template>
  <div class="space-y-5">
    <template v-if="!selectedEvent">
      <section class="flex flex-col gap-4 rounded-lg border border-slate-200 bg-white p-4 shadow-sm lg:flex-row lg:items-center lg:justify-between">
        <div>
          <p class="text-xs font-black uppercase tracking-[0.18em] text-[#E31837]">Lịch hiến máu</p>
          <h2 class="mt-1 text-xl font-black text-slate-950">Quản lý sự kiện và danh sách đăng ký</h2>
          <p class="mt-1 text-sm font-semibold text-slate-500">Lọc theo địa bàn, theo bệnh viện, check-in và ghi nhận kết quả hiến máu tại từng lịch.</p>
        </div>
        <div class="flex flex-wrap gap-2">
          <button class="inline-flex h-10 items-center gap-2 rounded-md border border-slate-200 px-3 text-xs font-black uppercase text-slate-600 hover:bg-slate-50" @click="loadEvents">
            <RefreshCw class="h-4 w-4" />
            Tải lại
          </button>
          <button class="inline-flex h-10 items-center gap-2 rounded-md bg-[#E31837] px-3 text-xs font-black uppercase text-white hover:bg-red-700" @click="openCreateModal">
            <Plus class="h-4 w-4" />
            Tạo lịch
          </button>
        </div>
      </section>

      <section class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <div class="grid gap-3 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-6">
        <label class="flex h-10 items-center gap-2 rounded-md border border-slate-200 bg-white px-3 transition focus-within:border-[#E31837] focus-within:ring-2 focus-within:ring-red-50">
          <Search class="h-4 w-4 shrink-0 text-slate-400" />
          <input v-model="filters.q" class="h-full min-w-0 flex-1 border-0 bg-transparent text-sm font-semibold outline-none" placeholder="Tìm tiêu đề, đơn vị, địa điểm" />
        </label>
        <select v-model="filters.status" class="h-10 rounded-md border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[#E31837]">
          <option v-for="status in statusFilters" :key="status.value" :value="status.value">{{ status.label }}</option>
        </select>
        <select v-model="filters.provinceCode" class="h-10 rounded-md border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[#E31837]">
          <option value="">Tất cả tỉnh/thành</option>
          <option v-for="province in provinces" :key="province.code" :value="province.code">{{ province.full_name }}</option>
        </select>
        <select v-model="filters.hospitalId" class="h-10 rounded-md border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[#E31837]">
          <option :value="null">Tất cả bệnh viện</option>
          <option v-for="hospital in hospitals" :key="hospital.id" :value="hospital.id">{{ hospital.name }}</option>
        </select>
        <input v-model="filters.dateFrom" type="date" class="h-10 rounded-md border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[#E31837]" />
        <input v-model="filters.dateTo" type="date" class="h-10 rounded-md border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[#E31837]" />
      </div>
      </section>

      <section class="overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm">
      <div v-if="isLoading" class="grid place-items-center p-10 text-slate-500">
        <Loader2 class="h-6 w-6 animate-spin" />
      </div>
      <div v-else class="overflow-x-auto">
        <table class="w-full table-fixed text-left" style="min-width: 920px">
          <colgroup>
            <col style="width: 31%" />
            <col style="width: 20%" />
            <col style="width: 13%" />
            <col style="width: 9%" />
            <col style="width: 12%" />
            <col style="width: 15%" />
          </colgroup>
          <thead class="whitespace-nowrap border-b border-slate-200 bg-slate-50 text-[11px] font-black uppercase tracking-[0.14em] text-slate-400">
            <tr>
              <th class="px-4 py-3">Sự kiện</th>
              <th class="px-4 py-3">Bệnh viện</th>
              <th class="px-4 py-3">Thời gian</th>
              <th class="px-4 py-3">Đăng ký</th>
              <th class="px-4 py-3">Trạng thái</th>
              <th class="px-4 py-3 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr
              v-for="event in events"
              :key="event.id"
              class="border-b border-slate-100 bg-white last:border-b-0"
            >
              <td class="px-4 py-4 align-middle">
                <p class="truncate font-black text-slate-950">{{ event.title }}</p>
                <p class="mt-1 truncate text-xs font-semibold text-slate-500">{{ event.location_name }}</p>
              </td>
              <td class="px-4 py-4 align-middle">
                <p class="truncate text-sm font-bold text-slate-600">{{ event.hospital?.name ?? event.organizer }}</p>
              </td>
              <td class="px-4 py-4 align-middle text-xs font-bold text-slate-600">{{ formatDateTime(event.starts_at) }}</td>
              <td class="px-4 py-4 align-middle text-sm font-black text-slate-900">{{ event.booked_count }} / {{ event.capacity }}</td>
              <td class="px-4 py-4 align-middle">
                <span class="inline-flex rounded-full px-2 py-1 text-xs font-black" :class="statusClass(event)">{{ eventStatus(event) }}</span>
              </td>
              <td class="px-4 py-4 align-middle">
                <div class="flex justify-end gap-2">
                  <button class="grid h-9 w-9 place-items-center rounded-md border border-slate-200 text-slate-600 hover:bg-slate-50" title="Chi tiết" @click="loadEventDetail(event)">
                    <Eye class="h-4 w-4" />
                  </button>
                  <button class="grid h-9 w-9 place-items-center rounded-md border border-slate-200 text-slate-600 hover:bg-slate-50" title="Sửa" @click="openEditModal(event)">
                    <Edit3 class="h-4 w-4" />
                  </button>
                  <button class="grid h-9 w-9 place-items-center rounded-md border border-red-100 text-[#E31837] hover:bg-red-50 disabled:opacity-40" title="Hủy sự kiện" :disabled="Boolean(event.cancelled_at)" @click="cancelEvent(event)">
                    <Ban class="h-4 w-4" />
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <p v-if="!isLoading && events.length === 0" class="p-8 text-center text-sm text-slate-500">Không có lịch hiến máu phù hợp bộ lọc.</p>
      <div class="flex items-center justify-between border-t border-slate-200 px-4 py-3">
        <p class="text-xs font-bold text-slate-500">Trang {{ meta.current_page }} / {{ meta.last_page }} - {{ formatNumber(meta.total) }} lịch</p>
        <div class="flex gap-2">
          <button class="grid h-8 w-8 place-items-center rounded-md border border-slate-200 text-slate-500 disabled:opacity-40" :disabled="page <= 1" @click="goToPage(page - 1)">
            <ChevronLeft class="h-4 w-4" />
          </button>
          <button class="grid h-8 w-8 place-items-center rounded-md border border-slate-200 text-slate-500 disabled:opacity-40" :disabled="page >= meta.last_page" @click="goToPage(page + 1)">
            <ChevronRight class="h-4 w-4" />
          </button>
        </div>
      </div>
      </section>
    </template>

    <section v-else class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm" @click="openAppointmentActionId = null">
      <div class="flex flex-col gap-3 border-b border-slate-100 pb-4 lg:flex-row lg:items-start lg:justify-between">
        <div>
          <p class="text-xs font-black uppercase tracking-[0.16em] text-[#E31837]">Chi tiết lịch</p>
          <h3 class="mt-1 text-lg font-black text-slate-950">{{ selectedEvent.title }}</h3>
          <p class="mt-1 text-sm font-semibold text-slate-500">{{ selectedEvent.location_name }} · {{ formatDateTime(selectedEvent.starts_at) }}</p>
        </div>
        <div class="flex flex-wrap gap-2">
          <button class="inline-flex h-9 items-center gap-2 rounded-md border border-slate-200 px-3 text-xs font-black uppercase text-slate-600 hover:bg-slate-50" @click="selectedEvent = null">
            <ChevronLeft class="h-4 w-4" />
            Quay lại
          </button>
          <button class="inline-flex h-9 items-center gap-2 rounded-md border border-slate-200 px-3 text-xs font-black uppercase text-slate-600 hover:bg-slate-50" @click="openEditModal(selectedEvent)">
            <Edit3 class="h-4 w-4" />
            Sửa
          </button>
          <button class="inline-flex h-9 items-center gap-2 rounded-md border border-red-100 px-3 text-xs font-black uppercase text-[#E31837] hover:bg-red-50 disabled:opacity-40" :disabled="Boolean(selectedEvent.cancelled_at)" @click="cancelEvent(selectedEvent)">
            <Ban class="h-4 w-4" />
            Hủy
          </button>
        </div>
      </div>

      <div class="mt-4 grid gap-3" style="grid-template-columns: repeat(auto-fit, minmax(170px, 1fr))">
        <div class="rounded-md bg-slate-50 p-3"><p class="text-[11px] font-black uppercase text-slate-400">Đã đặt</p><p class="mt-1 text-xl font-black">{{ appointmentStats.booked }}</p></div>
        <div class="rounded-md bg-blue-50 p-3"><p class="text-[11px] font-black uppercase text-blue-400">Check-in</p><p class="mt-1 text-xl font-black text-blue-700">{{ appointmentStats.checked_in }}</p></div>
        <div class="rounded-md bg-amber-50 p-3"><p class="text-[11px] font-black uppercase text-amber-500">Tạm hoãn</p><p class="mt-1 text-xl font-black text-amber-700">{{ appointmentStats.deferred }}</p></div>
        <div class="rounded-md bg-slate-50 p-3"><p class="text-[11px] font-black uppercase text-slate-400">Không đến</p><p class="mt-1 text-xl font-black">{{ appointmentStats.no_show }}</p></div>
        <div class="rounded-md bg-emerald-50 p-3"><p class="text-[11px] font-black uppercase text-emerald-500">Hoàn thành</p><p class="mt-1 text-xl font-black text-emerald-700">{{ appointmentStats.completed }}</p></div>
        <div class="rounded-md bg-red-50 p-3"><p class="text-[11px] font-black uppercase text-red-400">Tổng ml</p><p class="mt-1 text-xl font-black text-[#E31837]">{{ appointmentStats.total_volume_ml }}</p></div>
      </div>

      <div class="mt-4 flex flex-col gap-3 rounded-lg border border-slate-200 bg-slate-50 p-3 lg:flex-row lg:items-center lg:justify-between">
        <label class="flex h-10 w-full items-center gap-2 rounded-md border border-slate-200 bg-white px-3 transition focus-within:border-[#E31837] focus-within:ring-2 focus-within:ring-red-50 lg:max-w-md">
          <Search class="h-4 w-4 shrink-0 text-slate-400" />
          <input v-model="appointmentSearch" class="h-full min-w-0 flex-1 border-0 bg-transparent text-sm font-semibold outline-none" placeholder="Tìm theo tên, SĐT, nhóm máu" />
        </label>
        <p class="text-xs font-bold text-slate-500">
          Hiển thị {{ appointmentRangeStart }}-{{ appointmentRangeEnd }} / {{ formatNumber(filteredAppointments.length) }} người đăng ký
        </p>
      </div>

      <div class="mt-3 overflow-x-auto rounded-lg border border-slate-200">
        <table class="w-full table-fixed text-left" style="min-width: 1180px">
          <colgroup>
            <col style="width: 22%" />
            <col style="width: 12%" />
            <col style="width: 18%" />
            <col style="width: 13%" />
            <col style="width: 20%" />
            <col style="width: 15%" />
          </colgroup>
          <thead class="bg-slate-50 text-[11px] font-black uppercase tracking-[0.14em] text-slate-400">
            <tr>
              <th class="px-4 py-3">Người đăng ký</th>
              <th class="px-4 py-3">Trạng thái</th>
              <th class="px-4 py-3">Thời gian</th>
              <th class="px-4 py-3">Lượng máu</th>
              <th class="px-4 py-3">Khám / kết quả</th>
              <th class="px-4 py-3 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="appointment in paginatedAppointments" :key="appointment.id" class="border-b border-slate-100 last:border-b-0">
              <td class="px-4 py-3 align-middle">
                <p class="truncate font-black text-slate-950">{{ appointment.user?.name ?? 'Người hiến' }}</p>
                <p class="mt-1 truncate text-xs font-bold text-slate-500">{{ appointment.user?.blood_type }} · {{ appointment.user?.phone ?? 'Chưa có SĐT' }}</p>
              </td>
              <td class="px-4 py-3 align-middle">
                <span class="inline-flex rounded-full px-2 py-1 text-xs font-black" :class="appointmentClass(appointment.status)">{{ appointmentStatusLabels[appointment.status] }}</span>
              </td>
              <td class="px-4 py-3 align-middle text-xs font-bold text-slate-500">
                <p>Đặt: {{ formatDateTime(appointment.booked_at) }}</p>
                <p v-if="appointment.checked_in_at">Check-in: {{ formatDateTime(appointment.checked_in_at) }}</p>
                <p v-if="appointment.completed_at">Xong: {{ formatDateTime(appointment.completed_at) }}</p>
              </td>
              <td class="px-4 py-3 align-middle">
                <select v-model.number="appointmentVolumeSelections[appointment.id]" class="h-9 w-full rounded-md border border-slate-200 bg-white px-2 text-sm font-black text-slate-700 disabled:bg-slate-50 disabled:text-slate-400" :disabled="isTerminalAppointment(appointment)">
                  <option v-for="volume in volumeOptions" :key="volume" :value="volume">{{ volume }} ml</option>
                </select>
              </td>
              <td class="px-4 py-3 align-middle text-xs font-semibold text-slate-600">
                <p>{{ appointment.volume_ml ? `${appointment.volume_ml}ml` : 'Chưa ghi nhận lượng máu' }}</p>
                <p class="truncate">{{ appointment.screening_notes || appointment.result_summary || 'Chưa có ghi chú khám/xét nghiệm' }}</p>
                <p v-if="appointment.result_published_at" class="font-black text-emerald-600">Đã công bố kết quả</p>
                <a
                  v-if="appointment.certificate?.certificate_verify_url"
                  :href="appointment.certificate.certificate_verify_url"
                  target="_blank"
                  rel="noreferrer"
                  class="mt-1 inline-flex items-center rounded-full bg-red-50 px-2 py-1 text-[11px] font-black text-[#E31837] transition hover:bg-[#E31837] hover:text-white"
                >
                  {{ appointment.certificate.certificate_id }}
                </a>
              </td>
              <td class="px-4 py-3 align-middle">
                <div class="relative flex justify-end">
                  <button
                    type="button"
                    class="grid h-9 w-9 place-items-center rounded-md border border-slate-200 bg-white text-slate-600 transition hover:-translate-y-0.5 hover:border-[#E31837]/30 hover:bg-red-50 hover:text-[#E31837] hover:shadow-sm focus:outline-none focus:ring-2 focus:ring-red-100 disabled:cursor-not-allowed disabled:opacity-35 disabled:hover:translate-y-0 disabled:hover:border-slate-200 disabled:hover:bg-white disabled:hover:text-slate-600 disabled:hover:shadow-none"
                    :disabled="isTerminalAppointment(appointment)"
                    title="Thao tác"
                    @click.stop="toggleAppointmentActions(appointment)"
                  >
                    <MoreHorizontal class="h-4 w-4" />
                  </button>
                  <div
                    v-if="openAppointmentActionId === appointment.id && !isTerminalAppointment(appointment)"
                    class="absolute right-0 top-10 z-20 w-44 overflow-hidden rounded-md border border-slate-200 bg-white py-1 text-sm font-bold text-slate-700 shadow-xl"
                    @click.stop
                  >
                    <button v-if="appointment.status !== 'checked_in'" class="block w-full px-3 py-2 text-left transition hover:bg-blue-50 hover:text-blue-700" @click="handleAppointmentAction(appointment, 'check-in')">Check-in</button>
                    <button class="block w-full px-3 py-2 text-left transition hover:bg-emerald-50 hover:text-emerald-700" @click="handleAppointmentAction(appointment, 'complete')">Hoàn thành</button>
                    <button v-if="appointment.status !== 'deferred'" class="block w-full px-3 py-2 text-left transition hover:bg-amber-50 hover:text-amber-700" @click="handleAppointmentAction(appointment, 'defer')">Tạm hoãn</button>
                    <button v-if="appointment.status !== 'no_show'" class="block w-full px-3 py-2 text-left transition hover:bg-slate-100 hover:text-slate-700" @click="handleAppointmentAction(appointment, 'no-show')">Không đến</button>
                    <button class="block w-full px-3 py-2 text-left transition hover:bg-red-50 hover:text-[#E31837]" @click="handleAppointmentAction(appointment, 'cancel')">Hủy lịch</button>
                  </div>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
        <p v-if="filteredAppointments.length === 0" class="p-8 text-center text-sm text-slate-500">Không tìm thấy người đăng ký phù hợp.</p>
        <div class="flex items-center justify-between border-t border-slate-200 px-4 py-3">
          <p class="text-xs font-bold text-slate-500">Trang {{ appointmentPage }} / {{ appointmentPageCount }}</p>
          <div class="flex gap-2">
            <button class="grid h-8 w-8 place-items-center rounded-md border border-slate-200 text-slate-500 disabled:opacity-40" :disabled="appointmentPage <= 1" @click="goToAppointmentPage(appointmentPage - 1)">
              <ChevronLeft class="h-4 w-4" />
            </button>
            <button class="grid h-8 w-8 place-items-center rounded-md border border-slate-200 text-slate-500 disabled:opacity-40" :disabled="appointmentPage >= appointmentPageCount" @click="goToAppointmentPage(appointmentPage + 1)">
              <ChevronRight class="h-4 w-4" />
            </button>
          </div>
        </div>
      </div>
    </section>

    <div v-if="showModal" class="fixed inset-0 z-[2000] grid place-items-center bg-slate-950/50 p-4" @click="closeEventModal">
      <form class="w-full max-w-3xl rounded-lg bg-white shadow-2xl" @click.stop @submit.prevent="submitEvent">
        <div class="flex items-center justify-between border-b border-slate-200 p-4">
          <h3 class="text-lg font-black text-slate-950">{{ modalTitle }}</h3>
          <button type="button" class="grid h-9 w-9 place-items-center rounded-md border border-slate-200" @click="closeEventModal"><X class="h-4 w-4" /></button>
        </div>
        <div class="grid max-h-[72vh] gap-4 overflow-y-auto p-4 md:grid-cols-2">
          <label class="space-y-1 md:col-span-2"><span class="text-xs font-black uppercase text-slate-500">Tiêu đề</span><input v-model="form.title" required class="h-10 w-full rounded-md border border-slate-200 px-3 outline-none focus:border-[#E31837]" /></label>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Bệnh viện</span><select v-model="form.hospitalId" :disabled="hasBookings" class="h-10 w-full rounded-md border border-slate-200 px-3 disabled:bg-slate-50"><option v-for="hospital in hospitals" :key="hospital.id" :value="hospital.id">{{ hospital.name }}</option></select></label>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Đơn vị tổ chức</span><input v-model="form.organizer" required class="h-10 w-full rounded-md border border-slate-200 px-3 outline-none focus:border-[#E31837]" /></label>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Ngày</span><input v-model="form.date" :disabled="hasBookings" type="date" required class="h-10 w-full rounded-md border border-slate-200 px-3 disabled:bg-slate-50" /></label>
          <div class="grid grid-cols-2 gap-3"><label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Bắt đầu</span><input v-model="form.startTime" :disabled="hasBookings" type="time" required class="h-10 w-full rounded-md border border-slate-200 px-3 disabled:bg-slate-50" /></label><label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Kết thúc</span><input v-model="form.endTime" :disabled="hasBookings" type="time" required class="h-10 w-full rounded-md border border-slate-200 px-3 disabled:bg-slate-50" /></label></div>
          <label class="space-y-1 md:col-span-2"><span class="text-xs font-black uppercase text-slate-500">Địa điểm</span><input v-model="form.locationName" :disabled="hasBookings" required class="h-10 w-full rounded-md border border-slate-200 px-3 disabled:bg-slate-50" /></label>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Tỉnh/thành</span><select v-model="form.provinceCode" :disabled="hasBookings" class="h-10 w-full rounded-md border border-slate-200 px-3 disabled:bg-slate-50"><option v-for="province in provinces" :key="province.code" :value="province.code">{{ province.full_name }}</option></select></label>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Xã/phường</span><select v-model="form.wardCode" :disabled="hasBookings" class="h-10 w-full rounded-md border border-slate-200 px-3 disabled:bg-slate-50"><option v-for="ward in wards" :key="ward.code" :value="ward.code">{{ ward.full_name }}</option></select></label>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Vĩ độ</span><input v-model.number="form.latitude" :disabled="hasBookings" type="number" step="0.000001" class="h-10 w-full rounded-md border border-slate-200 px-3 disabled:bg-slate-50" /></label>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Kinh độ</span><input v-model.number="form.longitude" :disabled="hasBookings" type="number" step="0.000001" class="h-10 w-full rounded-md border border-slate-200 px-3 disabled:bg-slate-50" /></label>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Chỉ tiêu</span><input v-model.number="form.capacity" min="1" type="number" class="h-10 w-full rounded-md border border-slate-200 px-3" /></label>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Ưu tiên</span><select v-model="form.urgency" class="h-10 w-full rounded-md border border-slate-200 px-3"><option value="normal">Bình thường</option><option value="high">Cao</option></select></label>
          <label class="space-y-1 md:col-span-2"><span class="text-xs font-black uppercase text-slate-500">Ảnh</span><input v-model="form.imageUrl" class="h-10 w-full rounded-md border border-slate-200 px-3" /></label>
          <label class="space-y-1 md:col-span-2"><span class="text-xs font-black uppercase text-slate-500">Mô tả</span><textarea v-model="form.description" rows="3" class="w-full rounded-md border border-slate-200 px-3 py-2"></textarea></label>
          <label class="flex items-center gap-2 text-sm font-bold text-slate-600"><input v-model="form.isPublished" type="checkbox" /> Xuất bản cho mobile</label>
          <p v-if="errorMessage" class="md:col-span-2 rounded-md bg-red-50 p-3 text-sm font-bold text-[#E31837]">{{ errorMessage }}</p>
        </div>
        <div class="flex justify-end gap-2 border-t border-slate-200 p-4">
          <button type="button" class="h-10 rounded-md border border-slate-200 px-4 text-sm font-black" @click="closeEventModal">Đóng</button>
          <button class="inline-flex h-10 items-center gap-2 rounded-md bg-[#E31837] px-4 text-sm font-black text-white" :disabled="isSaving">
            <Loader2 v-if="isSaving" class="h-4 w-4 animate-spin" />
            Lưu lịch
          </button>
        </div>
      </form>
    </div>

    <div v-if="showCompleteModal && completingAppointment" class="fixed inset-0 z-[2100] grid place-items-center bg-slate-950/50 p-4" @click="closeCompleteModal">
      <form class="w-full max-w-xl rounded-lg bg-white shadow-2xl" @click.stop @submit.prevent="submitCompletion">
        <div class="flex items-center justify-between border-b border-slate-200 p-4">
          <h3 class="text-lg font-black text-slate-950">Hoàn thành hiến máu</h3>
          <button type="button" class="grid h-9 w-9 place-items-center rounded-md border border-slate-200" @click="closeCompleteModal"><X class="h-4 w-4" /></button>
        </div>
        <div class="space-y-4 p-4">
          <p class="rounded-md bg-slate-50 p-3 text-sm font-bold text-slate-600">{{ completingAppointment.user?.name }} · {{ completingAppointment.user?.blood_type }}</p>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Lượng máu</span><select v-model.number="completeForm.volumeMl" class="h-10 w-full rounded-md border border-slate-200 px-3"><option v-for="volume in volumeOptions" :key="volume" :value="volume">{{ volume }} ml</option></select></label>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Kết quả khám sàng lọc</span><select v-model="completeForm.screeningStatus" class="h-10 w-full rounded-md border border-slate-200 px-3"><option value="eligible">Đủ điều kiện</option><option value="pending">Chờ bổ sung</option><option value="ineligible">Không đủ điều kiện</option></select></label>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Ghi chú khám/xét nghiệm</span><textarea v-model="completeForm.screeningNotes" rows="3" class="w-full rounded-md border border-slate-200 px-3 py-2"></textarea></label>
          <label class="space-y-1"><span class="text-xs font-black uppercase text-slate-500">Tóm tắt kết quả cho mobile</span><textarea v-model="completeForm.resultSummary" rows="3" class="w-full rounded-md border border-slate-200 px-3 py-2"></textarea></label>
          <label class="flex items-center gap-2 text-sm font-bold text-slate-600"><input v-model="completeForm.publishResult" type="checkbox" /> Công bố kết quả cho người hiến</label>
        </div>
        <div class="flex justify-end gap-2 border-t border-slate-200 p-4">
          <button type="button" class="h-10 rounded-md border border-slate-200 px-4 text-sm font-black" @click="closeCompleteModal">Đóng</button>
          <button class="inline-flex h-10 items-center gap-2 rounded-md bg-slate-950 px-4 text-sm font-black text-white">
            <ClipboardCheck class="h-4 w-4" />
            Ghi nhận
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
