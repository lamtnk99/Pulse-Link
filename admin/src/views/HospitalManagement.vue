<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import {
  Building2,
  ChevronLeft,
  ChevronRight,
  Edit3,
  Loader2,
  MapPin,
  Plus,
  RefreshCw,
  Search,
  X,
} from '@lucide/vue'
import type { Hospital, PaginatedResponse, PaginationMeta, Province, Ward } from '../types'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000'
const hospitals = ref<Hospital[]>([])
const provinces = ref<Province[]>([])
const wards = ref<Ward[]>([])
const isLoading = ref(false)
const isSaving = ref(false)
const showModal = ref(false)
const editingHospital = ref<Hospital | null>(null)
const errorMessage = ref('')
const searchKeyword = ref('')
const statusFilter = ref('')
const page = ref(1)
const meta = ref<PaginationMeta>({ current_page: 1, last_page: 1, per_page: 10, total: 0 })

const statusFilters = [
  { value: '', label: 'Tất cả trạng thái' },
  { value: 'active', label: 'Đang hoạt động' },
  { value: 'inactive', label: 'Ngưng hoạt động' },
]

const form = reactive({
  name: '',
  code: '',
  provinceCode: '79',
  wardCode: '',
  address: '',
  latitude: 10.7565,
  longitude: 106.6594,
  contactPhone: '',
  contactEmail: '',
  isActive: true,
})

const modalTitle = computed(() => (editingHospital.value ? 'Sửa bệnh viện' : 'Thêm bệnh viện'))
const activeCountOnPage = computed(() => hospitals.value.filter((hospital) => hospital.is_active).length)

function resetForm() {
  form.name = ''
  form.code = ''
  form.provinceCode = provinces.value[0]?.code ?? '79'
  form.wardCode = ''
  form.address = ''
  form.latitude = provinces.value[0]?.centroid.latitude ?? 10.7565
  form.longitude = provinces.value[0]?.centroid.longitude ?? 106.6594
  form.contactPhone = ''
  form.contactEmail = ''
  form.isActive = true
  errorMessage.value = ''
}

function statusClass(hospital: Hospital) {
  return hospital.is_active ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'
}

async function loadHospitals() {
  isLoading.value = true
  try {
    const params = new URLSearchParams({
      page: String(page.value),
      per_page: String(meta.value.per_page),
    })
    if (searchKeyword.value.trim()) params.set('q', searchKeyword.value.trim())
    if (statusFilter.value) params.set('status', statusFilter.value)

    const response = await fetch(`${apiBaseUrl}/api/admin/hospitals?${params.toString()}`)
    const payload = (await response.json()) as PaginatedResponse<Hospital>
    hospitals.value = payload.data
    meta.value = payload.meta
    page.value = payload.meta.current_page
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
  editingHospital.value = null
  resetForm()
  showModal.value = true
  void loadWards(form.provinceCode)
}

function openEditModal(hospital: Hospital) {
  editingHospital.value = hospital
  errorMessage.value = ''
  form.name = hospital.name
  form.code = hospital.code
  form.provinceCode = hospital.province_code
  form.wardCode = hospital.ward_code ?? ''
  form.address = hospital.address
  form.latitude = hospital.latitude
  form.longitude = hospital.longitude
  form.contactPhone = hospital.contact_phone ?? ''
  form.contactEmail = hospital.contact_email ?? ''
  form.isActive = hospital.is_active ?? true
  showModal.value = true
  void loadWards(form.provinceCode)
}

function buildPayload() {
  return {
    name: form.name,
    code: form.code,
    province_code: form.provinceCode,
    ward_code: form.wardCode || null,
    address: form.address,
    latitude: form.latitude,
    longitude: form.longitude,
    contact_phone: form.contactPhone || null,
    contact_email: form.contactEmail || null,
    is_active: form.isActive,
  }
}

async function submitHospital() {
  if (!form.name || !form.code || !form.address) return

  isSaving.value = true
  errorMessage.value = ''
  try {
    const endpoint = editingHospital.value
      ? `${apiBaseUrl}/api/admin/hospitals/${editingHospital.value.id}`
      : `${apiBaseUrl}/api/admin/hospitals`
    const response = await fetch(endpoint, {
      method: editingHospital.value ? 'PUT' : 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(buildPayload()),
    })
    if (!response.ok) await throwApiError(response)

    showModal.value = false
    await loadHospitals()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'Không thể lưu bệnh viện.'
  } finally {
    isSaving.value = false
  }
}

async function deactivateHospital(hospital: Hospital) {
  if (!window.confirm(`Ngưng hoạt động ${hospital.name}?`)) return

  const response = await fetch(`${apiBaseUrl}/api/admin/hospitals/${hospital.id}`, {
    method: 'DELETE',
    headers: { Accept: 'application/json' },
  })
  if (response.ok) await loadHospitals()
}

async function throwApiError(response: Response): Promise<never> {
  const payload = await response.json().catch(() => null) as { message?: string; errors?: Record<string, string[]> } | null
  const firstError = payload?.errors ? Object.values(payload.errors)[0]?.[0] : null
  throw new Error(firstError ?? payload?.message ?? 'Yêu cầu không hợp lệ.')
}

function goToPage(nextPage: number) {
  if (nextPage < 1 || nextPage > meta.value.last_page || nextPage === page.value) return
  page.value = nextPage
  void loadHospitals()
}

watch(
  () => form.provinceCode,
  (provinceCode) => {
    const province = provinces.value.find((item) => item.code === provinceCode)
    if (!editingHospital.value && province?.centroid.latitude && province?.centroid.longitude) {
      form.latitude = province.centroid.latitude
      form.longitude = province.centroid.longitude
    }
    void loadWards(provinceCode)
  },
)

watch([searchKeyword, statusFilter], () => {
  page.value = 1
  void loadHospitals()
})

onMounted(async () => {
  await Promise.all([loadProvinces(), loadHospitals()])
  resetForm()
  await loadWards(form.provinceCode)
})
</script>

<template>
  <div class="space-y-5">
    <section class="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
      <div>
        <p class="text-xs font-black uppercase tracking-[0.22em] text-[#E31837]">Mạng lưới tiếp nhận</p>
        <h2 class="mt-2 flex items-center gap-2 text-2xl font-black text-slate-950">
          <Building2 class="h-6 w-6 text-[#E31837]" />
          Quản lý bệnh viện
        </h2>
        <p class="mt-1 text-sm text-slate-500">Thêm bệnh viện, địa chỉ và tọa độ làm tâm điều phối SOS, lịch hiến máu và RBAC.</p>
      </div>
      <div class="flex flex-wrap gap-2">
        <button class="inline-flex h-10 items-center gap-2 rounded-md border border-slate-200 px-4 text-xs font-black uppercase text-slate-600" @click="loadHospitals">
          <RefreshCw class="h-4 w-4" />
          Làm mới
        </button>
        <button class="inline-flex h-10 items-center gap-2 rounded-md bg-[#E31837] px-4 text-xs font-black uppercase text-white" @click="openCreateModal">
          <Plus class="h-4 w-4" />
          Thêm bệnh viện
        </button>
      </div>
    </section>

    <section class="grid gap-4 md:grid-cols-3">
      <article class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Tổng bệnh viện</p>
        <p class="mt-1 text-2xl font-black text-slate-950">{{ meta.total }}</p>
      </article>
      <article class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Đang hoạt động trang này</p>
        <p class="mt-1 text-2xl font-black text-emerald-600">{{ activeCountOnPage }}</p>
      </article>
      <article class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Tỉnh/thành có dữ liệu</p>
        <p class="mt-1 text-2xl font-black text-slate-950">{{ provinces.length }}</p>
      </article>
    </section>

    <section class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <div class="grid gap-3 md:grid-cols-[1fr_220px]">
        <label class="block">
          <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Tìm kiếm</span>
          <div class="mt-1 flex h-10 items-center gap-2 rounded-md border border-slate-200 bg-white px-3 transition focus-within:border-[#E31837] focus-within:ring-2 focus-within:ring-red-50">
            <Search class="h-4 w-4 shrink-0 text-slate-400" />
            <input v-model="searchKeyword" class="h-full min-w-0 flex-1 border-0 bg-transparent text-sm outline-none" placeholder="Tên, mã, địa chỉ, số điện thoại, email" />
          </div>
        </label>
        <label class="block">
          <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Trạng thái</span>
          <select v-model="statusFilter" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[#E31837]">
            <option v-for="status in statusFilters" :key="status.value" :value="status.value">{{ status.label }}</option>
          </select>
        </label>
      </div>
    </section>

    <section class="overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm">
      <div v-if="isLoading" class="flex items-center justify-center gap-2 p-8 text-sm font-bold text-slate-500">
        <Loader2 class="h-4 w-4 animate-spin" />
        Đang tải bệnh viện...
      </div>
      <div v-else-if="hospitals.length === 0" class="p-10 text-center text-sm text-slate-500">
        Chưa có bệnh viện phù hợp với bộ lọc hiện tại.
      </div>
      <div v-else class="overflow-x-auto">
        <table class="w-full min-w-[1040px] text-left text-sm">
          <thead class="bg-slate-50 text-[11px] font-black uppercase tracking-[0.16em] text-slate-500">
            <tr>
              <th class="px-5 py-4">Bệnh viện</th>
              <th class="px-5 py-4">Địa chỉ</th>
              <th class="px-5 py-4">Tọa độ</th>
              <th class="px-5 py-4">Liên hệ</th>
              <th class="px-5 py-4 text-center">Trạng thái</th>
              <th class="px-5 py-4 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr v-for="hospital in hospitals" :key="hospital.id" class="hover:bg-slate-50/60">
              <td class="px-5 py-4">
                <p class="font-bold text-slate-950">{{ hospital.name }}</p>
                <p class="mt-1 font-mono text-xs font-bold text-[#E31837]">{{ hospital.code }}</p>
              </td>
              <td class="px-5 py-4 text-slate-600">
                <p>{{ hospital.address }}</p>
                <p class="mt-1 text-xs text-slate-400">{{ hospital.ward?.full_name ?? hospital.ward_code }} · {{ hospital.province?.full_name ?? hospital.province_code }}</p>
              </td>
              <td class="px-5 py-4 font-mono text-xs font-bold text-slate-600">
                {{ hospital.latitude.toFixed(4) }}, {{ hospital.longitude.toFixed(4) }}
              </td>
              <td class="px-5 py-4 text-slate-600">
                <p>{{ hospital.contact_phone ?? 'Chưa có SĐT' }}</p>
                <p class="mt-1 text-xs text-slate-400">{{ hospital.contact_email ?? 'Chưa có email' }}</p>
              </td>
              <td class="px-5 py-4 text-center">
                <span class="rounded-full px-2.5 py-1 text-xs font-black" :class="statusClass(hospital)">
                  {{ hospital.is_active ? 'Đang hoạt động' : 'Ngưng hoạt động' }}
                </span>
              </td>
              <td class="px-5 py-4 text-right">
                <div class="flex justify-end gap-2">
                  <button class="inline-flex items-center gap-2 rounded-md border border-slate-200 px-3 py-2 text-xs font-black text-slate-700 hover:bg-slate-50" @click="openEditModal(hospital)">
                    <Edit3 class="h-3.5 w-3.5" />
                    Sửa
                  </button>
                  <button
                    class="inline-flex items-center gap-2 rounded-md border border-red-100 px-3 py-2 text-xs font-black text-[#E31837] hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-40"
                    :disabled="!hospital.is_active"
                    @click="deactivateHospital(hospital)"
                  >
                    Ngưng
                  </button>
                </div>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="flex flex-col gap-3 border-t border-slate-100 px-4 py-3 text-sm text-slate-500 md:flex-row md:items-center md:justify-between">
        <span>Trang {{ meta.current_page }} / {{ meta.last_page }} · {{ meta.total }} bệnh viện</span>
        <div class="flex gap-2">
          <button class="inline-flex h-9 items-center gap-1 rounded-md border border-slate-200 px-3 font-bold disabled:opacity-40" :disabled="page <= 1" @click="goToPage(page - 1)">
            <ChevronLeft class="h-4 w-4" />
            Trước
          </button>
          <button class="inline-flex h-9 items-center gap-1 rounded-md border border-slate-200 px-3 font-bold disabled:opacity-40" :disabled="page >= meta.last_page" @click="goToPage(page + 1)">
            Sau
            <ChevronRight class="h-4 w-4" />
          </button>
        </div>
      </div>
    </section>

    <div v-if="showModal" class="fixed inset-0 z-[2000] flex items-center justify-center overflow-y-auto bg-slate-950/60 p-4 backdrop-blur-sm">
      <form class="max-h-[92vh] w-full max-w-4xl overflow-y-auto rounded-lg bg-white p-5 shadow-2xl" @submit.prevent="submitHospital">
        <div class="flex items-center justify-between border-b border-slate-200 pb-4">
          <h3 class="flex items-center gap-2 text-lg font-black text-slate-950">
            <Building2 class="h-5 w-5 text-[#E31837]" />
            {{ modalTitle }}
          </h3>
          <button type="button" class="rounded-md p-2 text-slate-500 hover:bg-slate-100" @click="showModal = false">
            <X class="h-4 w-4" />
          </button>
        </div>

        <p v-if="errorMessage" class="mt-4 rounded-md border border-red-100 bg-red-50 p-3 text-sm font-bold text-[#E31837]">
          {{ errorMessage }}
        </p>

        <div class="mt-4 grid gap-4">
          <div class="grid gap-3 md:grid-cols-[1fr_180px]">
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Tên bệnh viện</span>
              <input v-model="form.name" required class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" />
            </label>
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Mã bệnh viện</span>
              <input v-model="form.code" required class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 font-mono text-sm font-bold uppercase outline-none focus:border-[#E31837]" />
            </label>
          </div>

          <label class="block">
            <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Địa chỉ</span>
            <input v-model="form.address" required class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" />
          </label>

          <div class="grid gap-3 md:grid-cols-2">
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Tỉnh/thành</span>
              <select v-model="form.provinceCode" required class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
                <option v-for="province in provinces" :key="province.code" :value="province.code">{{ province.full_name }}</option>
              </select>
            </label>
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Xã/phường</span>
              <select v-model="form.wardCode" required class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
                <option v-for="ward in wards" :key="ward.code" :value="ward.code">{{ ward.full_name }}</option>
              </select>
            </label>
          </div>

          <div class="grid gap-3 md:grid-cols-4">
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Vĩ độ</span>
              <input v-model.number="form.latitude" required type="number" step="0.0000001" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" />
            </label>
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Kinh độ</span>
              <input v-model.number="form.longitude" required type="number" step="0.0000001" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" />
            </label>
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Số điện thoại</span>
              <input v-model="form.contactPhone" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" />
            </label>
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Email</span>
              <input v-model="form.contactEmail" type="email" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" />
            </label>
          </div>

          <div class="flex items-center justify-between gap-3 rounded-lg border border-slate-200 bg-slate-50 p-3">
            <label class="flex items-center gap-2 text-sm font-bold text-slate-700">
              <input v-model="form.isActive" type="checkbox" class="h-4 w-4 rounded border-slate-300 text-[#E31837]" />
              Bệnh viện đang hoạt động
            </label>
            <span class="inline-flex items-center gap-1 text-xs font-bold text-slate-500">
              <MapPin class="h-3.5 w-3.5" />
              Tọa độ dùng làm tâm bán kính SOS
            </span>
          </div>
        </div>

        <div class="mt-5 flex justify-end gap-3">
          <button type="button" class="rounded-md border border-slate-200 px-4 py-2 text-sm font-bold text-slate-700" @click="showModal = false">Hủy</button>
          <button type="submit" class="inline-flex items-center gap-2 rounded-md bg-[#E31837] px-4 py-2 text-sm font-black text-white">
            <Loader2 v-if="isSaving" class="h-4 w-4 animate-spin" />
            {{ editingHospital ? 'Lưu thay đổi' : 'Thêm bệnh viện' }}
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
