<script setup lang="ts">
import { computed, nextTick, onMounted, ref, watch } from 'vue'
import {
  Activity,
  AlertTriangle,
  Bell,
  CheckCircle2,
  Database,
  Droplet,
  FileText,
  History,
  ImagePlus,
  Loader2,
  Plus,
  RefreshCw,
  Save,
  Search,
  Sliders,
  Sparkles,
  Calendar
} from '@lucide/vue'
import type { BloodStock, BloodSafetyThreshold, BloodDemandForecast, SmartAlert } from '../types'

type InventoryTab = 'inventory' | 'forecast' | 'alerts' | 'reports'

const props = defineProps<{
  apiBaseUrl?: string
  selectedHospitalId?: number | null
}>()

const emit = defineEmits<{
  openSosView: []
}>()

const apiBase = props.apiBaseUrl ?? ''
const currentTab = ref<InventoryTab>('inventory')
const tabNavigationRef = ref<HTMLElement | null>(null)

// State variables
const inventoryData = ref<BloodStock[]>([])
const stats = ref<Record<string, number>>({})
const breakdown = ref<any[]>([])
const thresholds = ref<BloodSafetyThreshold[]>([])
const forecasts = ref<BloodDemandForecast[]>([])
const smartAlerts = ref<SmartAlert[]>([])
const reportsData = ref<any>(null)

// UI States
const isLoading = ref(true)
const isSaving = ref(false)
const isUploadingImage = ref(false)
const forecastLoading = ref(false)
const alertLoading = ref(false)

// Search & Filter
const searchQuery = ref('')
const selectedBloodType = ref('')
const selectedStatus = ref('')
const currentPage = ref(1)
const totalPages = ref(1)

// Simulation Parameters
const dengueOutbreak = ref(false)
const holidaySeason = ref(false)
const weatherExtreme = ref(false)
const aiReasoning = ref('')
const aiRecommendations = ref<string[]>([])
const forecastDate = ref('')
const suggestedEvents = ref<any[]>([])
const showAiEventModal = ref(false)
const provinces = ref<any[]>([])
const wards = ref<any[]>([])
const hospitals = ref<any[]>([])

const bloodTypeOrder = ['A-', 'A+', 'AB-', 'AB+', 'B-', 'B+', 'O-', 'O+']

const orderedThresholds = computed(() => [...thresholds.value].sort((left, right) => {
  return bloodTypeOrder.indexOf(left.blood_type) - bloodTypeOrder.indexOf(right.blood_type)
}))

const activeSmartAlerts = computed(() => smartAlerts.value.filter((alert) => alert.status === 'active'))
const resolvedSmartAlerts = computed(() => smartAlerts.value.filter((alert) => alert.status !== 'active'))

const aiEventForm = ref({
  hospitalId: null as number | null,
  driveType: 'in_hospital' as 'in_hospital' | 'mobile',
  title: '',
  organizer: '',
  description: '',
  date: '',
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

// Modals
const showAddBagModal = ref(false)
const showMobilizeModal = ref(false)

// Add Bag Form State
const newBag = ref({
  blood_type: 'O+',
  volume_ml: 350,
  received_date: nowFormatted(),
  expiry_date: expiryFormatted(35),
  notes: ''
})

// Mobilization Form State
const mobilizationData = ref({
  alert_id: 0,
  target_blood_type: '',
  draft_post: {
    title: '',
    content: '',
    target_audience: '',
    province_code: ''
  }
})

// Notification State
const toast = ref<{ show: boolean; message: string; type: 'success' | 'error' }>({
  show: false,
  message: '',
  type: 'success'
})

function showToast(message: string, type: 'success' | 'error' = 'success') {
  toast.value = { show: true, message, type }
  setTimeout(() => {
    toast.value.show = false
  }, 4000)
}

function nowFormatted() {
  return new Date().toISOString().split('T')[0]
}

function expiryFormatted(days: number) {
  const d = new Date()
  d.setDate(d.getDate() + days)
  return d.toISOString().split('T')[0]
}

// Watchers
watch(() => props.selectedHospitalId, () => {
  loadAllData()
})

watch([searchQuery, selectedBloodType, selectedStatus], () => {
  currentPage.value = 1
  fetchInventory()
})

async function loadProvinces() {
  try {
    const res = await fetch(`${apiBase}/api/locations/provinces`)
    if (!res.ok) throw new Error()
    const json = await res.json()
    provinces.value = json.data
  } catch (e) {
    console.error('Failed to load provinces', e)
  }
}

async function loadWards(provinceCode: string) {
  if (!provinceCode) {
    wards.value = []
    return
  }
  try {
    const res = await fetch(`${apiBase}/api/locations/provinces/${provinceCode}/wards`)
    if (!res.ok) throw new Error()
    const json = await res.json()
    wards.value = json.data
  } catch (e) {
    console.error('Failed to load wards', e)
  }
}

async function loadHospitals() {
  try {
    const res = await fetch(`${apiBase}/api/admin/hospitals`)
    if (!res.ok) throw new Error()
    const json = await res.json()
    hospitals.value = json.data
  } catch (e) {
    console.error('Failed to load hospitals', e)
  }
}

function openAiEventModal(suggestion: any) {
  aiEventForm.value.hospitalId = props.selectedHospitalId || hospitals.value[0]?.id || null
  aiEventForm.value.driveType = suggestion.drive_type || 'in_hospital'
  aiEventForm.value.title = suggestion.title || ''
  aiEventForm.value.organizer = suggestion.organizer || ''
  aiEventForm.value.description = suggestion.description || ''
  aiEventForm.value.date = suggestion.suggested_date || ''
  aiEventForm.value.startTime = suggestion.starts_at || '08:00'
  aiEventForm.value.endTime = suggestion.ends_at || '12:00'
  aiEventForm.value.locationName = suggestion.location_name || ''
  aiEventForm.value.provinceCode = suggestion.province_code || '79'
  aiEventForm.value.wardCode = suggestion.ward_code || ''
  aiEventForm.value.latitude = suggestion.latitude || 10.7565
  aiEventForm.value.longitude = suggestion.longitude || 106.6594
  aiEventForm.value.capacity = suggestion.capacity || 120
  aiEventForm.value.urgency = suggestion.urgency || 'normal'
  aiEventForm.value.imageUrl = 'https://images.unsplash.com/photo-1615461066841-6116e61058f4?auto=format&fit=crop&q=80&w=900'
  aiEventForm.value.isPublished = true
  
  showAiEventModal.value = true
  void loadWards(aiEventForm.value.provinceCode)
}

async function uploadAiEventImage(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return

  isUploadingImage.value = true
  try {
    const fd = new FormData()
    fd.append('file', file)

    const res = await fetch(`${apiBase}/api/admin/uploads`, {
      method: 'POST',
      headers: { Accept: 'application/json' },
      body: fd,
    })
    const payload = await res.json()
    if (!res.ok) throw new Error(payload.message || 'upload failed')
    aiEventForm.value.imageUrl = payload.data.url
    showToast('Đã tải ảnh lên thành công!', 'success')
  } catch (e) {
    showToast('Không thể tải ảnh lên. Vui lòng thử lại.', 'error')
  } finally {
    isUploadingImage.value = false
    input.value = ''
  }
}

async function submitAiEvent() {
  isSaving.value = true
  try {
    const payload = {
      hospital_id: aiEventForm.value.hospitalId,
      drive_type: aiEventForm.value.driveType,
      title: aiEventForm.value.title,
      organizer: aiEventForm.value.organizer,
      description: aiEventForm.value.description,
      starts_at: `${aiEventForm.value.date}T${aiEventForm.value.startTime}:00`,
      ends_at: `${aiEventForm.value.date}T${aiEventForm.value.endTime}:00`,
      location_name: aiEventForm.value.locationName,
      province_code: aiEventForm.value.provinceCode,
      ward_code: aiEventForm.value.wardCode,
      latitude: aiEventForm.value.latitude,
      longitude: aiEventForm.value.longitude,
      urgency: aiEventForm.value.urgency,
      image_url: aiEventForm.value.imageUrl,
      capacity: aiEventForm.value.capacity,
      is_published: aiEventForm.value.isPublished,
    }

    const res = await fetch(`${apiBase}/api/admin/donation-events`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-Admin-User-Id': String(props.selectedHospitalId ? 2 : 1)
      },
      body: JSON.stringify(payload)
    })

    if (!res.ok) throw new Error()
    showToast('Đã tạo thành công đợt hiến máu mới từ đề xuất AI!', 'success')
    showAiEventModal.value = false
  } catch (e) {
    showToast('Không thể tạo đợt hiến máu. Vui lòng kiểm tra lại thông tin.', 'error')
  } finally {
    isSaving.value = false
  }
}

watch(
  () => aiEventForm.value.provinceCode,
  (provinceCode) => {
    void loadWards(provinceCode)
  }
)

watch(
  [() => aiEventForm.value.driveType, () => aiEventForm.value.hospitalId],
  ([driveType, hospitalId]) => {
    if (driveType === 'in_hospital' && hospitalId) {
      const hospital = hospitals.value.find((h) => h.id === hospitalId)
      if (hospital) {
        aiEventForm.value.organizer = hospital.name
        aiEventForm.value.locationName = hospital.address
        aiEventForm.value.provinceCode = hospital.province_code
        aiEventForm.value.wardCode = hospital.ward_code || ''
        aiEventForm.value.latitude = hospital.latitude
        aiEventForm.value.longitude = hospital.longitude
      }
    }
  }
)

// Load All Data
async function loadAllData() {
  isLoading.value = true
  try {
    await Promise.all([
      fetchInventory(),
      fetchThresholds(),
      fetchForecast(false),
      fetchAlerts(),
      fetchReports()
    ])
  } catch (error) {
    showToast('Lỗi khi đồng bộ dữ liệu từ bệnh viện.', 'error')
  } finally {
    isLoading.value = false
  }
}

// Fetch Functions
async function fetchInventory() {
  const hospitalParam = props.selectedHospitalId ? `&hospital_id=${props.selectedHospitalId}` : ''
  const q = searchQuery.value ? `&q=${encodeURIComponent(searchQuery.value)}` : ''
  const bt = selectedBloodType.value ? `&blood_type=${encodeURIComponent(selectedBloodType.value)}` : ''
  const st = selectedStatus.value ? `&status=${encodeURIComponent(selectedStatus.value)}` : ''
  
  const res = await fetch(`${apiBase}/api/admin/blood-stocks?page=${currentPage.value}${hospitalParam}${q}${bt}${st}`)
  if (!res.ok) throw new Error()
  const json = await res.json()
  
  inventoryData.value = json.data.bags.data
  stats.value = json.data.stats
  breakdown.value = json.data.breakdown
  totalPages.value = json.data.bags.last_page
}

async function fetchThresholds() {
  const hospitalParam = props.selectedHospitalId ? `?hospital_id=${props.selectedHospitalId}` : ''
  const res = await fetch(`${apiBase}/api/admin/blood-stocks/thresholds${hospitalParam}`)
  if (!res.ok) throw new Error()
  const json = await res.json()
  thresholds.value = json.data
}

async function fetchForecast(forceRefresh = false) {
  forecastLoading.value = true
  try {
    const hospitalParam = props.selectedHospitalId ? `hospital_id=${props.selectedHospitalId}` : ''
    const refreshParam = forceRefresh ? `&force_refresh=true` : ''
    const dengueParam = dengueOutbreak.value ? `&dengue_outbreak=true` : ''
    const holidayParam = holidaySeason.value ? `&holiday_season=true` : ''
    const weatherParam = weatherExtreme.value ? `&weather_extreme=true` : ''
    
    const endpoint = forceRefresh ? 'forecast/generate' : 'forecast'
    const url = `${apiBase}/api/admin/blood-stocks/${endpoint}?${hospitalParam}${refreshParam}${dengueParam}${holidayParam}${weatherParam}`
    
    // Nếu forceRefresh, gửi POST, ngược lại gửi GET
    const method = forceRefresh ? 'POST' : 'GET'
    const res = await fetch(url, { method })
    if (!res.ok) throw new Error()
    const json = await res.json()
    
    forecasts.value = json.data.forecast
    aiReasoning.value = json.data.reasoning_summary
    aiRecommendations.value = json.data.recommendations
    forecastDate.value = json.data.forecast_date
    suggestedEvents.value = json.data.suggested_events || []
  } catch (e) {
    showToast('Không thể kết nối dịch vụ AI dự báo.', 'error')
  } finally {
    forecastLoading.value = false
  }
}

async function fetchAlerts() {
  const hospitalParam = props.selectedHospitalId ? `?hospital_id=${props.selectedHospitalId}` : ''
  const res = await fetch(`${apiBase}/api/admin/blood-stocks/alerts${hospitalParam}`)
  if (!res.ok) throw new Error()
  const json = await res.json()
  smartAlerts.value = json.data
}

async function fetchReports() {
  const hospitalParam = props.selectedHospitalId ? `?hospital_id=${props.selectedHospitalId}` : ''
  const res = await fetch(`${apiBase}/api/admin/blood-stocks/reports${hospitalParam}`)
  if (!res.ok) throw new Error()
  const json = await res.json()
  reportsData.value = json.data
}

// Add New Bag
async function handleAddBag() {
  isSaving.value = true
  try {
    const payload = {
      ...newBag.value,
      hospital_id: props.selectedHospitalId
    }
    const res = await fetch(`${apiBase}/api/admin/blood-stocks`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify(payload)
    })
    
    if (!res.ok) {
      const err = await res.json()
      throw new Error(err.message || 'Lỗi nhập dữ liệu.')
    }
    
    showToast('Đã thêm túi máu vào kho thành công.')
    showAddBagModal.value = false
    // Reset form
    newBag.value = {
      blood_type: 'O+',
      volume_ml: 350,
      received_date: nowFormatted(),
      expiry_date: expiryFormatted(35),
      notes: ''
    }
    loadAllData()
  } catch (error: any) {
    showToast(error.message || 'Lỗi nhập dữ liệu.', 'error')
  } finally {
    isSaving.value = false
  }
}

// Update Bag Status (e.g. Mark as Used)
async function handleUpdateStatus(bagId: number, status: 'used' | 'expired' | 'available') {
  try {
    const res = await fetch(`${apiBase}/api/admin/blood-stocks/${bagId}/status`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        status,
        notes: status === 'used' ? 'Đã xuất kho sử dụng cứu chữa.' : 'Đã hủy bỏ.'
      })
    })
    
    if (!res.ok) throw new Error()
    showToast('Cập nhật trạng thái túi máu thành công.')
    loadAllData()
  } catch (e) {
    showToast('Không thể cập nhật trạng thái.', 'error')
  }
}

// Save Safety Thresholds
async function handleSaveThresholds() {
  isSaving.value = true
  try {
    const payload = thresholds.value.map(t => ({
      blood_type: t.blood_type,
      min_units: t.min_units
    }))
    
    const res = await fetch(`${apiBase}/api/admin/blood-stocks/thresholds`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        thresholds: payload,
        hospital_id: props.selectedHospitalId
      })
    })
    
    if (!res.ok) throw new Error()
    showToast('Đã lưu ngưỡng an toàn tồn kho mới.')
    loadAllData()
  } catch (e) {
    showToast('Lỗi lưu cấu hình.', 'error')
  } finally {
    isSaving.value = false
  }
}

// Open Mobilize Campaign Modal
async function openMobilization(alert: SmartAlert) {
  alertLoading.value = true
  try {
    const res = await fetch(`${apiBase}/api/admin/blood-stocks/alerts/${alert.id}/mobilize`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json'
      }
    })
    if (!res.ok) throw new Error()
    const json = await res.json()
    
    mobilizationData.value = {
      alert_id: json.data.alert_id,
      target_blood_type: json.data.target_blood_type,
      draft_post: json.data.draft_post
    }
    showMobilizeModal.value = true
  } catch (e) {
    showToast('Không thể lấy biểu mẫu huy động.', 'error')
  } finally {
    alertLoading.value = false
  }
}

// Publish Mobilization Post to CMS
async function submitMobilization() {
  isSaving.value = true
  try {
    // Đăng bài viết cộng đồng lên CMS để mobile app nhận tin
    const res = await fetch(`${apiBase}/api/admin/community-posts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Admin-User-Id': localStorage.getItem('admin_user_id') || ''
      },
      body: JSON.stringify({
        title: mobilizationData.value.draft_post.title,
        content: mobilizationData.value.draft_post.content,
        status: 'published',
        audience_type: 'blood_type',
        target_blood_type: mobilizationData.value.target_blood_type,
        province_code: mobilizationData.value.draft_post.province_code,
        excerpt: 'Kêu gọi hiến máu khẩn cấp cho bệnh viện.'
      })
    })
    
    if (!res.ok) {
      const err = await res.json()
      throw new Error(err.message || 'Lỗi đăng tin huy động.')
    }
    
    showToast('Đã xuất bản bài đăng huy động thành công!')
    showMobilizeModal.value = false
    loadAllData()
  } catch (error: any) {
    showToast(error.message || 'Lỗi kích hoạt huy động.', 'error')
  } finally {
    isSaving.value = false
  }
}

function parseDate(value: string, useDateOnly = false) {
  const datePart = value.match(/^\d{4}-\d{2}-\d{2}/)?.[0]
  const normalized = useDateOnly && datePart
    ? `${datePart}T12:00:00`
    : value.includes(' ') ? value.replace(' ', 'T') : value
  const parsed = new Date(normalized)

  return Number.isNaN(parsed.getTime()) ? null : parsed
}

function formatInventoryDate(value: string) {
  const date = parseDate(value, true)
  if (!date) return 'Chưa xác định'

  return new Intl.DateTimeFormat('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
  }).format(date)
}

function formatAlertDateTime(value?: string | null) {
  if (!value) return null
  const date = parseDate(value)
  if (!date) return null

  const time = new Intl.DateTimeFormat('vi-VN', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(date)

  return `${time} ${formatInventoryDate(value)}`
}

function alertStatusLabel(status: SmartAlert['status']) {
  if (status === 'resolved') return 'Đã khắc phục'
  if (status === 'mobilized') return 'Đã huy động'
  return 'Đang xảy ra'
}

function alertStatusClass(status: SmartAlert['status']) {
  if (status === 'resolved') return 'bg-emerald-100 text-emerald-700'
  if (status === 'mobilized') return 'bg-blue-100 text-blue-700'
  return 'bg-red-100 text-red-700'
}

// Helper: Phân tích màu cho ngày hết hạn
function getExpiryColorClass(expiryDate: string, status: string) {
  if (status !== 'available') return 'text-slate-400'
  const exp = parseDate(expiryDate, true)
  if (!exp) return 'text-slate-400'
  const today = new Date()
  const diffTime = exp.getTime() - today.getTime()
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  
  if (diffDays < 0) return 'text-red-600 font-bold bg-red-50 px-2 py-0.5 rounded'
  if (diffDays <= 7) return 'text-amber-600 font-bold bg-amber-50 px-2 py-0.5 rounded'
  return 'text-slate-600'
}

function getExpiryLabel(expiryDate: string, status: string) {
  if (status !== 'available') return status === 'used' ? 'Đã dùng' : 'Đã hủy'
  const exp = parseDate(expiryDate, true)
  if (!exp) return 'Không xác định'
  const today = new Date()
  today.setHours(0, 0, 0, 0)
  exp.setHours(0, 0, 0, 0)
  
  const diffTime = exp.getTime() - today.getTime()
  const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24))
  
  if (diffDays < 0) return `Hết hạn ${Math.abs(diffDays)} ngày`
  if (diffDays === 0) return 'Hết hạn hôm nay'
  return `Còn ${diffDays} ngày`
}

function formatVolume(ml: number) {
  return `${new Intl.NumberFormat('vi-VN').format(ml)} ml`
}

async function openInventoryTab(tab: InventoryTab) {
  currentTab.value = tab
  await nextTick()
  tabNavigationRef.value?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

function openSosView() {
  emit('openSosView')
}

// SVG Charts Helper
const maxForecastVal = computed(() => {
  if (forecasts.value.length === 0) return 3000
  return Math.max(...forecasts.value.map(f => f.predicted_volume_ml), 3000)
})

onMounted(async () => {
  await Promise.all([loadHospitals(), loadProvinces()])
  loadAllData()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header Page Title -->
    <section class="flex flex-col gap-4 lg:flex-row lg:items-end lg:justify-between">
      <div>
        <p class="text-xs font-black uppercase tracking-[0.24em] text-[#E31837]">Vận hành bệnh viện</p>
        <h1 class="mt-2 text-3xl font-black tracking-tight text-slate-950">Kho máu & Dự báo Nhu cầu AI</h1>
        <p class="mt-1 max-w-3xl text-sm text-slate-500">
          Xem tồn kho chi tiết, thiết lập cảnh báo an toàn tồn kho tự động và phân tích xu hướng nhu cầu máu tương lai dựa trên dữ liệu Gemini AI.
        </p>
      </div>

      <div class="flex gap-2">
        <button
          @click="loadAllData"
          class="inline-flex h-10 items-center justify-center gap-2 rounded-md border border-slate-200 bg-white px-4 text-xs font-bold text-slate-700 hover:bg-slate-50 active:scale-[0.98] transition cursor-pointer"
        >
          <RefreshCw class="h-4 w-4" :class="isLoading ? 'animate-spin text-[#E31837]' : ''" />
          Đồng bộ lại
        </button>

        <button
          @click="showAddBagModal = true"
          class="inline-flex h-10 items-center justify-center gap-2 rounded-md bg-[#E31837] px-4 text-xs font-black uppercase tracking-wide text-white shadow-sm shadow-red-500/20 transition hover:bg-red-700 active:scale-[0.98] cursor-pointer"
        >
          <Plus class="h-4 w-4" />
          Nhập túi máu mới
        </button>
      </div>
    </section>

    <!-- Thống kê nhanh / Card indicators -->
    <section class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
      <button
        type="button"
        class="w-full rounded-xl border border-slate-200 bg-white p-5 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-slate-300 hover:shadow-md focus:outline-none focus:ring-2 focus:ring-slate-100"
        @click="openInventoryTab('inventory')"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-400">Tồn kho hiện tại</span>
          <div class="grid h-8 w-8 place-items-center rounded bg-slate-100 text-slate-600">
            <Database class="h-4 w-4" />
          </div>
        </div>
        <div class="mt-4 flex items-baseline gap-2">
          <strong class="text-3xl font-black text-slate-950">{{ stats.total_units ?? 0 }}</strong>
          <span class="text-xs font-bold text-slate-500">túi máu</span>
        </div>
      </button>

      <button
        type="button"
        class="w-full rounded-xl border border-red-100 bg-white p-5 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-amber-200 hover:shadow-md focus:outline-none focus:ring-2 focus:ring-amber-100"
        @click="openInventoryTab('inventory')"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-400">Sắp hết hạn (&lt;7 ngày)</span>
          <div class="grid h-8 w-8 place-items-center rounded bg-amber-50 text-amber-500">
            <AlertTriangle class="h-4 w-4 animate-pulse" />
          </div>
        </div>
        <div class="mt-4 flex items-baseline gap-2">
          <strong class="text-3xl font-black text-amber-600">{{ stats.expiring_units ?? 0 }}</strong>
          <span class="text-xs font-bold text-slate-500">túi cần lưu ý</span>
        </div>
      </button>

      <button
        type="button"
        class="w-full rounded-xl border border-red-100 bg-white p-5 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-red-200 hover:shadow-md focus:outline-none focus:ring-2 focus:ring-red-100"
        @click="openInventoryTab('alerts')"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-400">Cảnh báo thiếu hụt</span>
          <div class="grid h-8 w-8 place-items-center rounded bg-red-50 text-[#E31837]">
            <AlertTriangle class="h-4 w-4 text-[#E31837] animate-ping" />
          </div>
        </div>
        <div class="mt-4 flex items-baseline gap-2">
          <strong class="text-3xl font-black text-[#E31837]">{{ stats.scarcity_alerts_count ?? 0 }}</strong>
          <span class="text-xs font-bold text-slate-500">nhóm máu dưới ngưỡng</span>
        </div>
      </button>

      <button
        type="button"
        class="w-full rounded-xl border border-slate-200 bg-white p-5 text-left shadow-sm transition hover:-translate-y-0.5 hover:border-emerald-200 hover:shadow-md focus:outline-none focus:ring-2 focus:ring-emerald-100"
        @click="openSosView"
      >
        <div class="flex items-center justify-between">
          <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-400">SOS đang điều phối</span>
          <div class="grid h-8 w-8 place-items-center rounded bg-emerald-50 text-emerald-600">
            <Activity class="h-4 w-4 text-emerald-500 animate-pulse" />
          </div>
        </div>
        <div class="mt-4 flex items-baseline gap-2">
          <strong class="text-3xl font-black text-emerald-600">{{ stats.active_sos_requests ?? 0 }}</strong>
          <span class="text-xs font-bold text-slate-500">ca hoạt động</span>
        </div>
      </button>
    </section>

    <!-- Tab navigation -->
    <div ref="tabNavigationRef" class="border-b border-slate-200 bg-white rounded-t-xl px-4 pt-2 shadow-sm flex flex-wrap gap-2">
      <button
        @click="currentTab = 'inventory'"
        class="border-b-2 px-4 py-3 text-sm font-black transition cursor-pointer"
        :class="currentTab === 'inventory' ? 'border-[#E31837] text-[#E31837]' : 'border-transparent text-slate-500 hover:text-slate-900'"
      >
        Dashboard tồn kho máu
      </button>
      <button
        @click="currentTab = 'forecast'"
        class="border-b-2 px-4 py-3 text-sm font-black transition flex items-center gap-1.5 cursor-pointer"
        :class="currentTab === 'forecast' ? 'border-[#E31837] text-[#E31837]' : 'border-transparent text-slate-500 hover:text-slate-900'"
      >
        <Sparkles class="h-4 w-4" />
        AI Dự báo Nhu cầu (30 ngày)
      </button>
      <button
        @click="currentTab = 'alerts'"
        class="border-b-2 px-4 py-3 text-sm font-black transition flex items-center gap-1.5 cursor-pointer"
        :class="currentTab === 'alerts' ? 'border-[#E31837] text-[#E31837]' : 'border-transparent text-slate-500 hover:text-slate-900'"
      >
        <Bell class="h-4 w-4" />
        Cảnh báo khan hiếm & Huy động
      </button>
      <button
        @click="currentTab = 'reports'"
        class="border-b-2 px-4 py-3 text-sm font-black transition flex items-center gap-1.5 cursor-pointer"
        :class="currentTab === 'reports' ? 'border-[#E31837] text-[#E31837]' : 'border-transparent text-slate-500 hover:text-slate-900'"
      >
        <FileText class="h-4 w-4" />
        Báo cáo & Thống kê
      </button>
    </div>

    <!-- MAIN VIEWPORT CONTAINER -->
    <div class="min-h-[400px]">
      <div v-if="isLoading" class="flex h-96 items-center justify-center rounded-xl border border-slate-200 bg-white shadow-sm">
        <div class="flex flex-col items-center gap-2">
          <Loader2 class="h-8 w-8 animate-spin text-[#E31837]" />
          <span class="text-sm font-bold text-slate-500">Đang đồng bộ dữ liệu bệnh viện...</span>
        </div>
      </div>

      <!-- Tab 1: Inventory & Stock breakdown -->
      <div v-else-if="currentTab === 'inventory'" class="space-y-6">
        <!-- Stock progress breakdowns -->
        <div class="grid gap-6 rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <div>
            <h3 class="text-base font-black text-slate-950">Trực quan tồn kho theo nhóm máu</h3>
            <p class="text-xs text-slate-500 mt-1">So sánh lượng tồn trữ thực tế với ngưỡng an toàn tối thiểu được cấu hình của bệnh viện.</p>
          </div>

          <div class="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">
            <div
              v-for="item in breakdown"
              :key="item.blood_type"
              class="rounded-lg border p-4 transition-all"
              :class="item.is_scarce ? 'border-red-100 bg-red-50/50 shadow-sm' : 'border-slate-100 bg-slate-50/50'"
            >
              <div class="flex items-center justify-between">
                <span class="text-lg font-black text-slate-950 flex items-center gap-1">
                  <Droplet class="h-5 w-5 fill-red-600 text-red-600" />
                  {{ item.blood_type }}
                </span>
                <span
                  v-if="item.is_scarce"
                  class="rounded-full bg-red-100 px-2 py-0.5 text-[9px] font-black uppercase text-red-600 animate-pulse"
                >
                  Khan hiếm
                </span>
                <span v-else-if="item.expiring_soon > 0" class="rounded-full bg-amber-100 px-2 py-0.5 text-[9px] font-black uppercase text-amber-700">
                  {{ item.expiring_soon }} sắp hết hạn
                </span>
                <span v-else class="rounded-full bg-green-100 px-2 py-0.5 text-[9px] font-black uppercase text-green-700">
                  An toàn
                </span>
              </div>

              <div class="mt-4 space-y-1.5">
                <div class="flex items-baseline justify-between text-xs font-bold text-slate-500">
                  <span>Tồn kho: <strong class="text-slate-900">{{ item.units }} đv</strong></span>
                  <span>Ngưỡng: {{ item.min_units }} đv</span>
                </div>
                <div class="relative h-2 w-full rounded-full bg-slate-200 overflow-hidden">
                  <div
                    class="h-full rounded-full transition-all duration-500"
                    :class="item.is_scarce ? 'bg-[#E31837]' : item.expiring_soon > 0 ? 'bg-amber-400' : 'bg-emerald-500'"
                    :style="{ width: `${Math.min((item.units / Math.max(item.min_units * 2, 10)) * 100, 100)}%` }"
                  />
                  <!-- Dải vạch thể hiện ngưỡng min_units -->
                  <div
                    class="absolute top-0 bottom-0 w-0.5 bg-slate-400/60"
                    :style="{ left: `${(item.min_units / Math.max(item.min_units * 2, 10)) * 100}%` }"
                  />
                </div>
                <p class="text-[9px] font-semibold text-slate-400">Thể tích: {{ formatVolume(item.volume_ml) }}</p>
              </div>
            </div>
          </div>
        </div>

        <!-- Inventory List Table -->
        <div class="rounded-xl border border-slate-200 bg-white shadow-sm overflow-hidden">
          <!-- Table Toolbar -->
          <div class="flex flex-col gap-3 p-5 md:flex-row md:items-center md:justify-between border-b border-slate-100 bg-slate-50/50">
            <div>
              <h3 class="text-base font-black text-slate-950">Danh sách túi máu chi tiết</h3>
              <p class="text-xs text-slate-500 mt-1">Quản lý nhập xuất và theo dõi hạn dùng của từng đơn vị máu lưu trữ.</p>
            </div>
            
            <div class="flex flex-wrap gap-2">
              <div class="relative flex h-10 w-full sm:w-60 items-center rounded-md border border-slate-200 bg-white px-3">
                <Search class="h-4 w-4 text-slate-400 mr-2 shrink-0" />
                <input
                  v-model="searchQuery"
                  type="text"
                  placeholder="Tìm theo ID, ghi chú..."
                  class="w-full text-xs font-semibold text-slate-700 outline-none placeholder:text-slate-400"
                />
              </div>

              <select
                v-model="selectedBloodType"
                class="h-10 rounded-md border border-slate-200 bg-white px-3 text-xs font-bold text-slate-600 outline-none"
              >
                <option value="">Tất cả nhóm máu</option>
                <option v-for="t in ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-']" :key="t" :value="t">{{ t }}</option>
              </select>

              <select
                v-model="selectedStatus"
                class="h-10 rounded-md border border-slate-200 bg-white px-3 text-xs font-bold text-slate-600 outline-none"
              >
                <option value="">Tất cả trạng thái</option>
                <option value="available">Sẵn sàng (Available)</option>
                <option value="expiring_soon">Sắp hết hạn (&lt;7 ngày)</option>
                <option value="used">Đã sử dụng (Used)</option>
                <option value="expired">Đã hết hạn (Expired)</option>
                <option value="allocated">Đã điều phối SOS (Allocated)</option>
              </select>
            </div>
          </div>

          <!-- Table Content -->
          <div class="overflow-x-auto">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="border-b border-slate-100 bg-slate-50/70 text-[10px] font-black uppercase tracking-wider text-slate-400">
                  <th class="p-4">Mã số túi máu</th>
                  <th class="p-4">Nhóm máu</th>
                  <th class="p-4">Thể tích</th>
                  <th class="p-4">Ngày tiếp nhận</th>
                  <th class="p-4">Ngày hết hạn</th>
                  <th class="p-4">Trạng thái</th>
                  <th class="p-4">Nguồn hiến</th>
                  <th class="p-4 text-right">Thao tác</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 text-xs font-semibold text-slate-700">
                <tr v-for="bag in inventoryData" :key="bag.id" class="hover:bg-slate-50/50">
                  <td class="p-4 font-mono font-bold text-slate-900">#BAG-{{ String(bag.id).padStart(5, '0') }}</td>
                  <td class="p-4">
                    <span class="inline-flex items-center gap-1 rounded bg-red-50 px-2 py-0.5 font-bold text-red-600">
                      🩸 {{ bag.blood_type }}
                    </span>
                  </td>
                  <td class="p-4 font-mono">{{ formatVolume(bag.volume_ml) }}</td>
                  <td class="p-4 text-slate-500 whitespace-nowrap">{{ formatInventoryDate(bag.received_date) }}</td>
                  <td class="p-4">
                    <div class="flex flex-col">
                      <span class="whitespace-nowrap" :class="getExpiryColorClass(bag.expiry_date, bag.status)">
                        {{ formatInventoryDate(bag.expiry_date) }}
                      </span>
                      <span class="text-[10px] text-slate-400 font-normal">
                        ({{ getExpiryLabel(bag.expiry_date, bag.status) }})
                      </span>
                    </div>
                  </td>
                  <td class="p-4">
                    <span
                      class="inline-block rounded-full px-2 py-0.5 text-[10px] font-bold"
                      :class="{
                        'bg-emerald-100 text-emerald-800': bag.status === 'available',
                        'bg-blue-100 text-blue-800': bag.status === 'used',
                        'bg-red-100 text-red-800': bag.status === 'expired',
                        'bg-amber-100 text-amber-800': bag.status === 'allocated'
                      }"
                    >
                      {{ bag.status.toUpperCase() }}
                    </span>
                  </td>
                  <td class="p-4 text-slate-500">
                    <span v-if="bag.donation_history?.user">
                      {{ bag.donation_history.user.name }} (Lịch hiến: {{ bag.donation_history.certificate_id }})
                    </span>
                    <span v-else class="italic text-slate-400">Hiến thường quy tự do / Nhập ngoài</span>
                  </td>
                  <td class="p-4 text-right">
                    <div class="flex justify-end gap-1.5" v-if="bag.status === 'available'">
                      <button
                        @click="handleUpdateStatus(bag.id, 'used')"
                        class="rounded border border-blue-100 bg-blue-50 px-2.5 py-1 text-[10px] font-bold text-blue-600 hover:bg-blue-100 active:scale-95 transition"
                      >
                        Xuất kho dùng
                      </button>
                      <button
                        @click="handleUpdateStatus(bag.id, 'expired')"
                        class="rounded border border-red-100 bg-red-50 px-2.5 py-1 text-[10px] font-bold text-red-600 hover:bg-red-100 active:scale-95 transition"
                      >
                        Báo hủy/Hết hạn
                      </button>
                    </div>
                    <span v-else class="text-slate-400 italic text-[11px] font-normal">Đã xử lý (Không thể sửa)</span>
                  </td>
                </tr>
                <tr v-if="inventoryData.length === 0">
                  <td colspan="8" class="p-8 text-center text-slate-400 italic">
                    Không tìm thấy dữ liệu túi máu phù hợp với bộ lọc hiện tại.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>

          <!-- Table Pagination -->
          <div class="flex items-center justify-between border-t border-slate-100 p-4" v-if="totalPages > 1">
            <button
              :disabled="currentPage === 1"
              @click="currentPage--; fetchInventory()"
              class="rounded border border-slate-200 px-3 py-1.5 text-xs font-bold text-slate-500 hover:bg-slate-50 disabled:opacity-50"
            >
              Trang trước
            </button>
            <span class="text-xs font-bold text-slate-600">Trang {{ currentPage }} / {{ totalPages }}</span>
            <button
              :disabled="currentPage === totalPages"
              @click="currentPage++; fetchInventory()"
              class="rounded border border-slate-200 px-3 py-1.5 text-xs font-bold text-slate-500 hover:bg-slate-50 disabled:opacity-50"
            >
              Trang sau
            </button>
          </div>
        </div>
      </div>

      <!-- Tab 2: AI Forecasting -->
      <div v-else-if="currentTab === 'forecast'" class="space-y-6">
        <!-- AI Forecasting Dashboard -->
        <div class="grid gap-6 lg:grid-cols-[1fr_360px]">
          <!-- SVG Line Chart comparing demand -->
          <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm flex flex-col justify-between">
            <div>
              <div class="flex items-center justify-between">
                <h3 class="text-base font-black text-slate-950 flex items-center gap-2">
                  <Sparkles class="h-5 w-5 text-purple-600" />
                  Dự báo nhu cầu máu trong 30 ngày tới
                </h3>
                <span class="rounded-full bg-purple-50 px-3 py-1 text-xs font-bold text-purple-600 flex items-center gap-1.5">
                  <Sparkles class="h-3.5 w-3.5 text-purple-600" /> Powered by Google Gemini
                </span>
              </div>
              <p class="text-xs text-slate-500 mt-1">Dựa trên mô hình AI học máy, phân tích nhu cầu sử dụng thực tế của 8 nhóm máu chính.</p>
            </div>

            <!-- Custom SVG Chart Container -->
            <div class="mt-6 flex-1 min-h-[250px] relative flex flex-col justify-end">
              <div v-if="forecastLoading" class="absolute inset-0 bg-white/70 z-10 flex items-center justify-center">
                <div class="flex flex-col items-center gap-1">
                  <Loader2 class="h-8 w-8 animate-spin text-purple-600" />
                  <span class="text-xs font-bold text-slate-500">AI đang thiết lập mô hình dự báo...</span>
                </div>
              </div>

              <!-- Biểu đồ cột SVG hoặc biểu đồ đường SVG đẹp mắt -->
              <svg viewBox="0 0 800 300" class="w-full h-64 overflow-visible">
                <!-- Grid Lines -->
                <line x1="50" y1="20" x2="750" y2="20" stroke="#f1f5f9" stroke-width="1" />
                <line x1="50" y1="90" x2="750" y2="90" stroke="#f1f5f9" stroke-width="1" />
                <line x1="50" y1="160" x2="750" y2="160" stroke="#f1f5f9" stroke-width="1" />
                <line x1="50" y1="230" x2="750" y2="230" stroke="#f1f5f9" stroke-width="1" />
                <line x1="50" y1="250" x2="750" y2="250" stroke="#e2e8f0" stroke-width="2" />

                <!-- Y-Axis Labels -->
                <text x="40" y="24" text-anchor="end" class="text-[9px] font-mono fill-slate-400 font-bold">3,000ml</text>
                <text x="40" y="94" text-anchor="end" class="text-[9px] font-mono fill-slate-400 font-bold">2,000ml</text>
                <text x="40" y="164" text-anchor="end" class="text-[9px] font-mono fill-slate-400 font-bold">1,000ml</text>
                <text x="40" y="234" text-anchor="end" class="text-[9px] font-mono fill-slate-400 font-bold">100ml</text>

                <!-- Bars for forecast -->
                <g v-for="(f, index) in forecasts" :key="index">
                  <!-- X-Axis Coordinate calculation -->
                  <!-- 8 groups, width of X domain = 700. Step = 700 / 8 = 87.5. Center = 50 + index*87.5 + 43.75 -->
                  <rect
                    :x="50 + index * 87.5 + 28"
                    :y="250 - (f.predicted_volume_ml / maxForecastVal) * 220"
                    width="30"
                    :height="(f.predicted_volume_ml / maxForecastVal) * 220"
                    fill="url(#forecastGradient)"
                    rx="4"
                    class="transition-all duration-300 hover:opacity-80 cursor-pointer"
                  />
                  <!-- Label nhóm máu -->
                  <text
                    :x="50 + index * 87.5 + 43"
                    y="270"
                    text-anchor="middle"
                    class="text-xs font-black fill-slate-700"
                  >
                    {{ f.blood_type }}
                  </text>
                  <!-- Label giá trị trên đỉnh cột -->
                  <text
                    :x="50 + index * 87.5 + 43"
                    :y="242 - (f.predicted_volume_ml / maxForecastVal) * 220"
                    text-anchor="middle"
                    class="text-[10px] font-mono font-bold fill-[#E31837]"
                  >
                    {{ f.predicted_volume_ml }}ml
                  </text>
                </g>

                <!-- Gradient definitions -->
                <defs>
                  <linearGradient id="forecastGradient" x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stop-color="#E31837" stop-opacity="1" />
                    <stop offset="100%" stop-color="#fd0054" stop-opacity="0.3" />
                  </linearGradient>
                </defs>
              </svg>
            </div>

            <!-- AI Output Analysis Text -->
            <div class="mt-6 border-t border-slate-100 pt-5 space-y-3">
              <h4 class="text-sm font-black text-slate-900 flex items-center gap-1.5">
                <Sparkles class="h-4.5 w-4.5 text-purple-600" />
                Lý giải Phân tích từ AI (Gemini Agent):
              </h4>
              <p class="text-xs text-slate-700 bg-purple-50/50 rounded-lg p-4 border border-purple-100/30 leading-relaxed font-semibold">
                {{ aiReasoning || 'AI đang phân tích các điều kiện vận hành hiện tại...' }}
              </p>
              <div class="text-[10px] text-slate-400 font-bold">Ngày lập dự báo: {{ forecastDate }}</div>
            </div>
          </div>

          <!-- Scenario Simulation parameters panel -->
          <div class="space-y-4">
            <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm">
              <h3 class="text-sm font-black text-slate-950 border-b border-slate-100 pb-3 mb-4 flex items-center gap-2">
                <Sliders class="h-4.5 w-4.5 text-[#E31837]" />
                GIẢ LẬP KỊCH BẢN AI
              </h3>
              
              <div class="space-y-4">
                <div class="flex items-start justify-between">
                  <div class="max-w-[75%]">
                    <label class="text-xs font-black text-slate-900 block">Dịch sốt xuất huyết bùng phát</label>
                    <span class="text-[10px] text-slate-400 font-semibold leading-tight block mt-0.5">Tăng đột biến nhu cầu chế phẩm tiểu cầu và máu O/A tại vùng bùng dịch.</span>
                  </div>
                  <input
                    type="checkbox"
                    v-model="dengueOutbreak"
                    class="w-5 h-5 rounded accent-[#E31837] cursor-pointer"
                  />
                </div>

                <div class="flex items-start justify-between">
                  <div class="max-w-[75%]">
                    <label class="text-xs font-black text-slate-900 block">Kỳ nghỉ lễ lớn (Tết/Quốc khánh)</label>
                    <span class="text-[10px] text-slate-400 font-semibold leading-tight block mt-0.5">Lượng máu hiến giảm mạnh, đồng thời tăng rủi ro các ca cấp cứu giao thông.</span>
                  </div>
                  <input
                    type="checkbox"
                    v-model="holidaySeason"
                    class="w-5 h-5 rounded accent-[#E31837] cursor-pointer"
                  />
                </div>

                <div class="flex items-start justify-between">
                  <div class="max-w-[75%]">
                    <label class="text-xs font-black text-slate-900 block">Thời tiết cực đoan (Lũ lụt/Nắng nóng)</label>
                    <span class="text-[10px] text-slate-400 font-semibold leading-tight block mt-0.5">Giảm nghiêm trọng số lượng người hiến trực tiếp tại các điểm di động.</span>
                  </div>
                  <input
                    type="checkbox"
                    v-model="weatherExtreme"
                    class="w-5 h-5 rounded accent-[#E31837] cursor-pointer"
                  />
                </div>

                <button
                  @click="fetchForecast(true)"
                  :disabled="forecastLoading"
                  class="w-full h-11 bg-slate-900 hover:bg-slate-950 text-white font-bold text-xs rounded-lg active:scale-[0.98] transition-all flex items-center justify-center gap-1.5 shadow-sm cursor-pointer disabled:opacity-50"
                >
                  <RefreshCw class="w-4 h-4" :class="forecastLoading ? 'animate-spin' : ''" />
                  CẬP NHẬT DỰ BÁO AI MỚI
                </button>
              </div>
            </div>

            <!-- Recommendations list -->
            <div class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm space-y-4">
              <h3 class="text-sm font-black text-slate-950 border-b border-slate-100 pb-3">Khuyến nghị Hành động:</h3>
              <ul class="space-y-3">
                <li
                  v-for="(rec, idx) in aiRecommendations"
                  :key="idx"
                  class="flex items-start gap-2.5 text-xs text-slate-700 font-semibold"
                >
                  <span class="text-emerald-500 font-bold mt-0.5 shrink-0">✓</span>
                  <span>{{ rec }}</span>
                </li>
              </ul>
            </div>
          </div>
        </div>

        <!-- AI Suggested Events Section -->
        <div v-if="suggestedEvents.length > 0" class="mt-6 rounded-xl border border-slate-200 bg-white p-6 shadow-sm space-y-4">
          <div class="flex items-center justify-between border-b border-slate-100 pb-4">
            <div>
              <h3 class="text-base font-black text-slate-950 flex items-center gap-2">
                <Calendar class="h-5 w-5 text-purple-600" />
                Đề xuất đợt hiến máu từ AI (Dựa trên dự báo nhu cầu)
              </h3>
              <p class="text-xs text-slate-500 mt-1">AI tự động phân tích và lập kế hoạch tổ chức hiến máu bù đắp lượng máu sắp thiếu hụt.</p>
            </div>
            <span class="rounded-full bg-purple-50 px-3 py-1 text-xs font-bold text-purple-600">
              Có {{ suggestedEvents.length }} đề xuất mới
            </span>
          </div>

          <div class="grid gap-6 md:grid-cols-2">
            <div
              v-for="(event, idx) in suggestedEvents"
              :key="idx"
              class="relative rounded-lg border border-slate-200 p-5 hover:border-purple-300 transition-all flex flex-col justify-between"
            >
              <!-- Urgency & Type Badge -->
              <div class="absolute right-4 top-4 flex items-center gap-1.5">
                <span
                  v-if="event.urgency === 'high'"
                  class="rounded-full bg-red-50 px-2 py-0.5 text-[10px] font-bold text-red-600"
                >
                  Khẩn cấp
                </span>
                <span
                  class="rounded-full px-2 py-0.5 text-[10px] font-bold"
                  :class="event.drive_type === 'in_hospital' ? 'bg-blue-50 text-blue-600' : 'bg-orange-50 text-orange-600'"
                >
                  {{ event.drive_type === 'in_hospital' ? 'Tại bệnh viện' : 'Lưu động' }}
                </span>
              </div>

              <div class="space-y-3">
                <h4 class="text-sm font-black text-slate-950 pr-20">{{ event.title }}</h4>
                <p class="text-xs text-slate-500 line-clamp-3 leading-relaxed">{{ event.description }}</p>

                <div class="grid grid-cols-2 gap-2 text-xs border-t border-slate-100 pt-3">
                  <div>
                    <span class="text-slate-400 font-bold block uppercase text-[9px]">Đơn vị tổ chức:</span>
                    <span class="text-slate-700 font-bold block truncate">{{ event.organizer }}</span>
                  </div>
                  <div>
                    <span class="text-slate-400 font-bold block uppercase text-[9px]">Địa điểm:</span>
                    <span class="text-slate-700 font-bold block truncate">{{ event.location_name }}</span>
                  </div>
                  <div class="mt-2">
                    <span class="text-slate-400 font-bold block uppercase text-[9px]">Thời gian đề xuất:</span>
                    <span class="text-slate-700 font-bold block">{{ event.suggested_date }} ({{ event.starts_at }} - {{ event.ends_at }})</span>
                  </div>
                  <div class="mt-2">
                    <span class="text-slate-400 font-bold block uppercase text-[9px]">Chỉ tiêu dự kiến:</span>
                    <span class="text-slate-700 font-bold block">{{ event.capacity }} lượt đặt lịch</span>
                  </div>
                </div>
              </div>

              <button
                @click="openAiEventModal(event)"
                class="mt-5 w-full h-10 bg-purple-600 hover:bg-purple-700 text-white font-bold text-xs rounded-lg active:scale-[0.98] transition-all flex items-center justify-center gap-1.5 shadow-sm cursor-pointer"
              >
                <Plus class="w-4 h-4" />
                TẠO NHANH ĐỢT HIẾN NÀY
              </button>
            </div>
          </div>
        </div>
      </div>

      <!-- Tab 3: Smart Alerts & Mobilization -->
      <div v-else-if="currentTab === 'alerts'" class="space-y-6">
        <section class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
          <div class="flex flex-col gap-4 border-b border-slate-100 pb-5 md:flex-row md:items-start md:justify-between">
            <div>
              <h3 class="flex items-center gap-2 text-base font-black text-slate-950">
                <Sliders class="h-5 w-5 text-[#E31837]" />
                Ngưỡng an toàn tối thiểu
              </h3>
              <p class="mt-1 text-xs text-slate-500">Thiết lập số đơn vị dự phòng tối thiểu để hệ thống tự động kích hoạt cảnh báo.</p>
            </div>
            <button
              @click="handleSaveThresholds"
              :disabled="isSaving"
              class="inline-flex h-10 shrink-0 items-center justify-center gap-2 rounded-lg bg-[#E31837] px-4 text-xs font-black uppercase tracking-wide text-white transition hover:bg-red-700 active:scale-[0.98] disabled:opacity-50"
            >
              <Save class="h-4 w-4" />
              {{ isSaving ? 'Đang lưu...' : 'Lưu thiết lập ngưỡng' }}
            </button>
          </div>

          <div class="mt-5 grid grid-cols-2 divide-x divide-y divide-slate-100 overflow-hidden rounded-lg border border-slate-100 sm:grid-cols-4 2xl:grid-cols-8">
            <label v-for="threshold in orderedThresholds" :key="threshold.id" class="min-w-0 p-3.5">
              <span class="flex items-center gap-1.5 text-xs font-black text-slate-800">
                <Droplet class="h-4 w-4 fill-[#E31837] text-[#E31837]" />
                {{ threshold.blood_type }}
              </span>
              <span class="mt-2 flex items-center gap-1.5">
                <input
                  v-model.number="threshold.min_units"
                  type="number"
                  min="0"
                  max="150"
                  class="h-9 min-w-0 w-full rounded-md border border-slate-200 px-2 text-center text-sm font-black text-slate-900 outline-none transition focus:border-[#E31837] focus:ring-2 focus:ring-red-100"
                />
                <span class="text-[10px] font-bold text-slate-400">đv</span>
              </span>
            </label>
          </div>
        </section>

        <div class="grid gap-6 2xl:grid-cols-2">
          <section class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
            <div class="flex items-start justify-between gap-4">
              <div>
                <h3 class="flex items-center gap-2 text-base font-black text-slate-950">
                  <AlertTriangle class="h-5 w-5 text-[#E31837]" />
                  Cảnh báo khan hiếm
                </h3>
                <p class="mt-1 text-xs text-slate-500">Các nhóm máu cần huy động người hiến gấp.</p>
              </div>
              <span class="rounded-full bg-red-50 px-2.5 py-1 text-[10px] font-black text-[#E31837]">
                {{ activeSmartAlerts.length }} nhóm máu
              </span>
            </div>

            <div v-if="activeSmartAlerts.length" class="mt-5 space-y-3">
              <article
                v-for="alert in activeSmartAlerts"
                :key="alert.id"
                class="rounded-lg border border-red-100 bg-red-50/60 p-4"
              >
                <div class="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
                  <div class="flex min-w-0 items-start gap-3">
                    <div class="grid h-11 w-11 shrink-0 place-items-center rounded-lg bg-red-100 text-base font-black text-[#E31837]">
                      {{ alert.blood_type }}
                    </div>
                    <div class="min-w-0">
                      <h4 class="text-xs font-black text-slate-900">Tồn kho dưới ngưỡng an toàn tối thiểu</h4>
                      <p class="mt-1 text-[11px] font-semibold text-slate-500">
                        Thực tế: <span class="font-black text-[#E31837]">{{ alert.current_units }} đv</span>
                        / Yêu cầu: {{ alert.threshold_units }} đv.
                      </p>
                      <p class="mt-2 text-[10px] font-bold text-slate-400">Kích hoạt: {{ formatAlertDateTime(alert.triggered_at) }}</p>
                    </div>
                  </div>
                  <div class="flex shrink-0 items-center gap-2">
                    <span class="rounded-full bg-red-100 px-2 py-1 text-[9px] font-black uppercase text-red-700 animate-pulse">Đang xảy ra</span>
                    <button
                      @click="openMobilization(alert)"
                      :disabled="alertLoading"
                      class="inline-flex h-9 items-center justify-center gap-1.5 rounded-md bg-[#E31837] px-3 text-[10px] font-black text-white transition hover:bg-red-700 active:scale-95 disabled:opacity-50"
                    >
                      <Loader2 v-if="alertLoading" class="h-3.5 w-3.5 animate-spin" />
                      Kích hoạt huy động
                    </button>
                  </div>
                </div>
              </article>
            </div>

            <div v-else class="mt-5 rounded-lg border border-dashed border-emerald-200 bg-emerald-50/50 p-8 text-center">
              <CheckCircle2 class="mx-auto h-7 w-7 text-emerald-500" />
              <p class="mt-2 text-xs font-bold text-emerald-700">Tồn kho hiện chưa có cảnh báo cần huy động.</p>
            </div>
          </section>

          <section class="rounded-xl border border-slate-200 bg-white p-5 shadow-sm sm:p-6">
            <div class="flex items-start justify-between gap-4">
              <div>
                <h3 class="flex items-center gap-2 text-base font-black text-slate-950">
                  <History class="h-5 w-5 text-slate-600" />
                  Lịch sử xử lý
                </h3>
                <p class="mt-1 text-xs text-slate-500">Lịch sử phát hiện, huy động và khắc phục cảnh báo.</p>
              </div>
              <span class="rounded-full bg-slate-100 px-2.5 py-1 text-[10px] font-black text-slate-600">
                {{ resolvedSmartAlerts.length }} hoạt động
              </span>
            </div>

            <div v-if="resolvedSmartAlerts.length" class="mt-5 divide-y divide-slate-100 overflow-hidden rounded-lg border border-slate-100">
              <article v-for="alert in resolvedSmartAlerts" :key="alert.id" class="flex gap-3 p-3.5">
                <div class="grid h-10 w-10 shrink-0 place-items-center rounded-lg bg-slate-100 text-sm font-black text-slate-700">
                  {{ alert.blood_type }}
                </div>
                <div class="min-w-0 flex-1">
                  <div class="flex flex-wrap items-start justify-between gap-2">
                    <div>
                      <h4 class="text-xs font-black text-slate-900">Tồn kho dưới ngưỡng an toàn tối thiểu</h4>
                      <p class="mt-0.5 text-[11px] font-semibold text-slate-500">
                        Thực tế: <span class="font-bold text-[#E31837]">{{ alert.current_units }} đv</span> / Yêu cầu: {{ alert.threshold_units }} đv.
                      </p>
                    </div>
                    <span class="rounded-full px-2 py-1 text-[9px] font-black uppercase" :class="alertStatusClass(alert.status)">
                      {{ alertStatusLabel(alert.status) }}
                    </span>
                  </div>
                  <div class="mt-2 flex flex-wrap gap-x-4 gap-y-1 text-[10px] font-bold text-slate-400">
                    <span>Kích hoạt: {{ formatAlertDateTime(alert.triggered_at) }}</span>
                    <span v-if="alert.resolved_at">Khắc phục: {{ formatAlertDateTime(alert.resolved_at) }}</span>
                  </div>
                </div>
              </article>
            </div>

            <p v-else class="mt-5 rounded-lg border border-dashed border-slate-200 p-8 text-center text-xs font-semibold text-slate-400">
              Chưa có lịch sử cảnh báo đã xử lý.
            </p>
          </section>
        </div>
      </div>

      <!-- Tab 4: Reports & Statistics -->
      <div v-else-if="currentTab === 'reports'" class="space-y-6">
        <div class="grid gap-6 md:grid-cols-2">
          <!-- Blood Utilization Chart -->
          <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <h3 class="text-base font-black text-slate-950 border-b border-slate-100 pb-3 mb-6">Tỷ lệ sử dụng & Hao hụt tồn kho</h3>
            
            <div class="flex flex-col items-center justify-center py-6 sm:flex-row sm:gap-12" v-if="reportsData">
              <!-- Custom SVG Donut Chart -->
              <svg width="150" height="150" viewBox="0 0 42 42" class="overflow-visible transform -rotate-90">
                <circle cx="21" cy="21" r="15.915" fill="transparent" stroke="#f1f5f9" stroke-width="4" />
                <!-- Used circle segment -->
                <circle
                  cx="21"
                  cy="21"
                  r="15.915"
                  fill="transparent"
                  stroke="#10b981"
                  stroke-width="4"
                  :stroke-dasharray="`${reportsData.utilization.utilization_rate} ${100 - reportsData.utilization.utilization_rate}`"
                  stroke-dashoffset="0"
                />
                <!-- Expired circle segment -->
                <circle
                  cx="21"
                  cy="21"
                  r="15.915"
                  fill="transparent"
                  stroke="#ef4444"
                  stroke-width="4"
                  :stroke-dasharray="`${reportsData.utilization.waste_rate} ${100 - reportsData.utilization.waste_rate}`"
                  :stroke-dashoffset="100 - reportsData.utilization.utilization_rate"
                />
              </svg>

              <!-- Legend -->
              <div class="space-y-4 mt-6 sm:mt-0">
                <div class="flex items-center gap-2">
                  <span class="w-3 h-3 rounded-full bg-emerald-500"></span>
                  <div>
                    <p class="text-xs font-bold text-slate-900">Sử dụng thành công: {{ reportsData.utilization.utilization_rate }}%</p>
                    <p class="text-[10px] text-slate-400 font-semibold">{{ reportsData.utilization.used_count }} túi máu cứu chữa</p>
                  </div>
                </div>

                <div class="flex items-center gap-2">
                  <span class="w-3 h-3 rounded-full bg-red-500"></span>
                  <div>
                    <p class="text-xs font-bold text-slate-900">Hao hụt (Quá hạn): {{ reportsData.utilization.waste_rate }}%</p>
                    <p class="text-[10px] text-slate-400 font-semibold">{{ reportsData.utilization.expired_count }} túi đã hủy</p>
                  </div>
                </div>

                <div class="flex items-center gap-2">
                  <span class="w-3 h-3 rounded-full bg-slate-300"></span>
                  <div>
                    <p class="text-xs font-bold text-slate-900">Đang lưu kho: {{ reportsData.utilization.available_count }} túi</p>
                  </div>
                </div>
              </div>
            </div>
            <p v-else class="text-center italic text-slate-400">Đang tải dữ liệu báo cáo...</p>
          </div>

          <!-- Campaign Efficiency Report -->
          <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
            <h3 class="text-base font-black text-slate-950 border-b border-slate-100 pb-3 mb-4">Hiệu quả chiến dịch hiến máu thường quy</h3>
            <p class="text-xs text-slate-500 mb-4">Thể tích máu tiếp nhận trung bình trên từng đầu người hẹn hiến tại sự kiện hiến máu.</p>
            
            <div class="space-y-3.5 max-h-[300px] overflow-y-auto pr-1" v-if="reportsData">
              <div v-for="(item, idx) in reportsData.campaigns_efficiency" :key="idx" class="space-y-1">
                <div class="flex items-center justify-between text-xs font-bold text-slate-700">
                  <span class="truncate max-w-[70%]" :title="item.event_title">{{ item.event_title }}</span>
                  <span class="text-[#E31837]">{{ formatVolume(item.volume_collected_ml) }}</span>
                </div>
                <div class="h-2 w-full rounded-full bg-slate-100 overflow-hidden relative">
                  <div
                    class="h-full rounded-full bg-red-500/80"
                    :style="{ width: `${Math.min((item.volume_collected_ml / 40000) * 100, 100)}%` }"
                  />
                </div>
                <p class="text-[9px] text-slate-400 font-bold">Lượt đăng ký tham gia hiến: {{ item.appointments_count }} người</p>
              </div>

              <p v-if="reportsData.campaigns_efficiency.length === 0" class="text-center text-slate-400 italic py-6">
                Chưa có sự kiện nào hoàn thành trong kỳ.
              </p>
            </div>
          </div>
        </div>

        <!-- SOS coordination efficiency table -->
        <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
          <h3 class="text-base font-black text-slate-950 border-b border-slate-100 pb-3 mb-4">Hiệu suất và Tỷ lệ hoàn thành điều phối SOS khẩn cấp</h3>
          
          <div class="overflow-x-auto" v-if="reportsData">
            <table class="w-full text-left border-collapse">
              <thead>
                <tr class="border-b border-slate-100 text-[10px] font-black uppercase text-slate-400">
                  <th class="pb-3">Mã ca khẩn cấp</th>
                  <th class="pb-3">Nhóm máu</th>
                  <th class="pb-3">Nhu cầu chỉ tiêu</th>
                  <th class="pb-3">Số lượng cam kết hiến</th>
                  <th class="pb-3">Thực tế hiến thành công</th>
                  <th class="pb-3">Tỷ lệ turnout</th>
                  <th class="pb-3 text-right">Trạng thái ca</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-50 text-xs font-semibold text-slate-700">
                <tr v-for="item in reportsData.sos_performance" :key="item.alert_id" class="hover:bg-slate-50/50">
                  <td class="py-3 font-mono font-bold text-slate-900">#SOS-{{ item.alert_id.substring(0, 8) }}</td>
                  <td class="py-3">
                    <span class="rounded bg-red-50 px-1.5 py-0.5 text-red-600 font-bold">{{ item.blood_type }}</span>
                  </td>
                  <td class="py-3">{{ item.units_needed }} đơn vị</td>
                  <td class="py-3 text-slate-500">{{ item.commitments_count }} người nhận</td>
                  <td class="py-3 text-emerald-600 font-bold">{{ item.donated_count }} người</td>
                  <td class="py-3 font-mono text-slate-600">{{ item.turnout_rate }}%</td>
                  <td class="py-3 text-right">
                    <span
                      class="rounded-full px-2 py-0.5 text-[9px] font-black uppercase"
                      :class="item.status === 'fulfilled' || item.status === 'completed' ? 'bg-emerald-100 text-emerald-800' : 'bg-amber-100 text-amber-800'"
                    >
                      {{ item.status }}
                    </span>
                  </td>
                </tr>
                <tr v-if="reportsData.sos_performance.length === 0">
                  <td colspan="7" class="p-8 text-center text-slate-400 italic">
                    Chưa có ca SOS khẩn cấp được phát ra.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>

    <!-- MODAL: ADD BAG -->
    <div
      v-if="showAddBagModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4"
    >
      <div class="w-full max-w-md rounded-xl border border-slate-200 bg-white p-6 shadow-xl space-y-6">
        <div class="flex items-center justify-between border-b border-slate-100 pb-3">
          <h3 class="text-base font-black text-slate-900 flex items-center gap-1.5">
            <Droplet class="h-5 w-5 text-[#E31837]" />
            NHẬP ĐƠN VỊ TÚI MÁU MỚI
          </h3>
          <button @click="showAddBagModal = false" class="text-slate-400 hover:text-slate-700 text-lg font-bold">×</button>
        </div>

        <form @submit.prevent="handleAddBag" class="space-y-4 text-xs font-bold text-slate-600">
          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Nhóm máu</label>
            <select
              v-model="newBag.blood_type"
              class="w-full h-10 rounded border border-slate-200 bg-slate-50 px-3 outline-none focus:border-[#E31837]"
            >
              <option v-for="t in ['O+', 'O-', 'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-']" :key="t" :value="t">{{ t }}</option>
            </select>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Thể tích (ml)</label>
              <select
                v-model="newBag.volume_ml"
                class="w-full h-10 rounded border border-slate-200 bg-slate-50 px-3 outline-none focus:border-[#E31837]"
              >
                <option :value="250">250 ml</option>
                <option :value="350">350 ml</option>
                <option :value="450">450 ml</option>
              </select>
            </div>

            <div>
              <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Ngày tiếp nhận</label>
              <input
                type="date"
                v-model="newBag.received_date"
                class="w-full h-10 rounded border border-slate-200 bg-slate-50 px-3 outline-none focus:border-[#E31837]"
              />
            </div>
          </div>

          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Ngày hết hạn (Khuyên dùng: +35 ngày)</label>
            <input
              type="date"
              v-model="newBag.expiry_date"
              class="w-full h-10 rounded border border-slate-200 bg-slate-50 px-3 outline-none focus:border-[#E31837]"
            />
          </div>

          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Ghi chú vận hành</label>
            <input
              type="text"
              v-model="newBag.notes"
              placeholder="Ví dụ: Nhập kho từ chiến dịch lưu động..."
              class="w-full h-10 rounded border border-slate-200 bg-slate-50 px-3 outline-none focus:border-[#E31837] placeholder:text-slate-400 font-semibold"
            />
          </div>

          <div class="flex gap-2 justify-end pt-4 border-t border-slate-100">
            <button
              type="button"
              @click="showAddBagModal = false"
              class="h-10 px-4 rounded border border-slate-200 text-slate-600 hover:bg-slate-50 font-bold active:scale-95"
            >
              Hủy bỏ
            </button>
            <button
              type="submit"
              :disabled="isSaving"
              class="h-10 px-5 rounded bg-[#E31837] hover:bg-red-700 text-white font-black uppercase tracking-wider active:scale-95 disabled:opacity-50"
            >
              {{ isSaving ? 'Đang thêm...' : 'XÁC NHẬN THÊM' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: MOBILIZE CAMPAIGN CONFIRMATION -->
    <div
      v-if="showMobilizeModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4"
    >
      <div class="w-full max-w-lg rounded-xl border border-slate-200 bg-white p-6 shadow-xl space-y-5">
        <div class="flex items-center justify-between border-b border-slate-100 pb-3">
          <h3 class="text-base font-black text-slate-900 flex items-center gap-1.5">
            <Sparkles class="h-5 w-5 text-purple-600" />
            XÁC NHẬN CHIẾN DỊCH HUY ĐỘNG NGƯỜI HIẾN
          </h3>
          <button @click="showMobilizeModal = false" class="text-slate-400 hover:text-slate-700 text-lg font-bold">×</button>
        </div>

        <p class="text-xs text-slate-500 font-semibold leading-relaxed">
          Hệ thống AI đã tự soạn thảo sẵn một bài đăng kêu gọi hiến máu dựa trên dữ liệu thiếu hụt hiện tại để gửi thông báo đến các tình nguyện viên tương thích. Bạn có thể sửa đổi nội dung bài đăng trước khi xuất bản.
        </p>

        <form @submit.prevent="submitMobilization" class="space-y-4 text-xs font-bold text-slate-600">
          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Tiêu đề bài viết</label>
            <input
              type="text"
              v-model="mobilizationData.draft_post.title"
              class="w-full h-10 rounded border border-slate-200 bg-slate-50 px-3 outline-none focus:border-purple-500 font-bold text-slate-900"
            />
          </div>

          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Nội dung chi tiết kêu gọi</label>
            <textarea
              rows="6"
              v-model="mobilizationData.draft_post.content"
              class="w-full rounded border border-slate-200 bg-slate-50 p-3 outline-none focus:border-purple-500 font-semibold text-slate-700 leading-relaxed"
            />
          </div>

          <div class="grid grid-cols-2 gap-4 bg-slate-50 p-3 rounded-lg border border-slate-100">
            <div>
              <p class="text-[10px] text-slate-400 uppercase tracking-wide">Nhóm máu nhắm chọn</p>
              <strong class="text-xs text-slate-800">Nhóm máu {{ mobilizationData.target_blood_type }}</strong>
            </div>
            <div>
              <p class="text-[10px] text-slate-400 uppercase tracking-wide">Đối tượng đích</p>
              <strong class="text-xs text-[#E31837]">Khẩn cấp / Vị trí gần Bệnh viện</strong>
            </div>
          </div>

          <div class="flex gap-2 justify-end pt-4 border-t border-slate-100">
            <button
              type="button"
              @click="showMobilizeModal = false"
              class="h-10 px-4 rounded border border-slate-200 text-slate-600 hover:bg-slate-50 font-bold active:scale-95"
            >
              Hủy bỏ
            </button>
            <button
              type="submit"
              :disabled="isSaving"
              class="h-10 px-5 rounded bg-purple-600 hover:bg-purple-700 text-white font-black uppercase tracking-wider active:scale-95 disabled:opacity-50 flex items-center gap-1.5"
            >
              <Sparkles class="h-4 w-4" />
              {{ isSaving ? 'Đang xuất bản...' : 'ĐĂNG BÀI HUY ĐỘNG NGAY' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- MODAL: CREATE EVENT FROM AI SUGGESTION -->
    <div
      v-if="showAiEventModal"
      class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4"
    >
      <div class="w-full max-w-2xl rounded-xl border border-slate-200 bg-white p-6 shadow-xl space-y-4">
        <div class="flex items-center justify-between border-b border-slate-100 pb-3">
          <h3 class="text-base font-black text-slate-900 flex items-center gap-1.5">
            <Calendar class="h-5 w-5 text-purple-600" />
            TẠO ĐỢT HIẾN MÁU TỪ ĐỀ XUẤT AI
          </h3>
          <button @click="showAiEventModal = false" class="text-slate-400 hover:text-slate-700 text-lg font-bold">×</button>
        </div>

        <form @submit.prevent="submitAiEvent" class="grid grid-cols-2 gap-4 overflow-y-auto max-h-[70vh] p-1 text-xs font-bold text-slate-600">
          <div class="col-span-2">
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Tiêu đề chiến dịch</label>
            <input
              type="text"
              v-model="aiEventForm.title"
              required
              class="w-full h-10 rounded border border-slate-200 px-3 outline-none focus:border-purple-500 font-bold text-slate-900"
            />
          </div>

          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Loại hình tổ chức</label>
            <select
              v-model="aiEventForm.driveType"
              class="w-full h-10 rounded border border-slate-200 px-3 bg-white outline-none focus:border-purple-500 font-bold"
            >
              <option value="in_hospital">Tổ chức tại bệnh viện</option>
              <option value="mobile">Ủy quyền / Hợp tác lưu động</option>
            </select>
          </div>

          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Bệnh viện tiếp nhận</label>
            <select
              v-model="aiEventForm.hospitalId"
              class="w-full h-10 rounded border border-slate-200 px-3 bg-white outline-none focus:border-purple-500 font-bold"
            >
              <option v-for="h in hospitals" :key="h.id" :value="h.id">{{ h.name }}</option>
            </select>
          </div>

          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Đơn vị tổ chức</label>
            <input
              type="text"
              v-model="aiEventForm.organizer"
              :disabled="aiEventForm.driveType === 'in_hospital'"
              required
              class="w-full h-10 rounded border border-slate-200 px-3 outline-none focus:border-purple-500 font-bold text-slate-900 disabled:bg-slate-50"
            />
          </div>

          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Ngày diễn ra</label>
            <input
              type="date"
              v-model="aiEventForm.date"
              required
              class="w-full h-10 rounded border border-slate-200 px-3 outline-none focus:border-purple-500 font-semibold"
            />
          </div>

          <div class="grid grid-cols-2 gap-2">
            <div>
              <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Bắt đầu</label>
              <input
                type="time"
                v-model="aiEventForm.startTime"
                required
                class="w-full h-10 rounded border border-slate-200 px-3 outline-none focus:border-purple-500 font-semibold"
              />
            </div>
            <div>
              <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Kết thúc</label>
              <input
                type="time"
                v-model="aiEventForm.endTime"
                required
                class="w-full h-10 rounded border border-slate-200 px-3 outline-none focus:border-purple-500 font-semibold"
              />
            </div>
          </div>

          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Chỉ tiêu lượt đặt lịch</label>
            <input
              type="number"
              v-model.number="aiEventForm.capacity"
              min="10"
              required
              class="w-full h-10 rounded border border-slate-200 px-3 outline-none focus:border-purple-500 font-bold text-slate-900"
            />
          </div>

          <div class="col-span-2">
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Tên địa điểm diễn ra</label>
            <input
              type="text"
              v-model="aiEventForm.locationName"
              :disabled="aiEventForm.driveType === 'in_hospital'"
              required
              class="w-full h-10 rounded border border-slate-200 px-3 outline-none focus:border-purple-500 font-bold text-slate-900 disabled:bg-slate-50"
            />
          </div>

          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Tỉnh / Thành phố</label>
            <select
              v-model="aiEventForm.provinceCode"
              :disabled="aiEventForm.driveType === 'in_hospital'"
              class="w-full h-10 rounded border border-slate-200 px-3 bg-white outline-none focus:border-purple-500 font-bold disabled:bg-slate-50"
            >
              <option v-for="p in provinces" :key="p.code" :value="p.code">{{ p.full_name }}</option>
            </select>
          </div>

          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Quận / Huyện / Xã / Phường</label>
            <select
              v-model="aiEventForm.wardCode"
              :disabled="aiEventForm.driveType === 'in_hospital'"
              class="w-full h-10 rounded border border-slate-200 px-3 bg-white outline-none focus:border-purple-500 font-bold disabled:bg-slate-50"
            >
              <option v-for="w in wards" :key="w.code" :value="w.code">{{ w.full_name }}</option>
            </select>
          </div>

          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Tọa độ Vĩ độ (Latitude)</label>
            <input
              type="number"
              step="0.000001"
              v-model.number="aiEventForm.latitude"
              :disabled="aiEventForm.driveType === 'in_hospital'"
              required
              class="w-full h-10 rounded border border-slate-200 px-3 outline-none focus:border-purple-500 font-semibold disabled:bg-slate-50"
            />
          </div>

          <div>
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Tọa độ Kinh độ (Longitude)</label>
            <input
              type="number"
              step="0.000001"
              v-model.number="aiEventForm.longitude"
              :disabled="aiEventForm.driveType === 'in_hospital'"
              required
              class="w-full h-10 rounded border border-slate-200 px-3 outline-none focus:border-purple-500 font-semibold disabled:bg-slate-50"
            />
          </div>

          <div class="col-span-2">
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Mức độ ưu tiên</label>
            <select
              v-model="aiEventForm.urgency"
              class="w-full h-10 rounded border border-slate-200 px-3 bg-white outline-none focus:border-purple-500 font-bold"
            >
              <option value="normal">Bình thường</option>
              <option value="high">Cao / Cần thiết gấp</option>
            </select>
          </div>

          <div class="col-span-2">
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Mô tả chiến dịch</label>
            <textarea
              rows="3"
              v-model="aiEventForm.description"
              class="w-full rounded border border-slate-200 p-3 outline-none focus:border-purple-500 font-semibold text-slate-700 leading-relaxed"
            />
          </div>

          <div class="col-span-2">
            <label class="block mb-1.5 uppercase tracking-wide text-slate-400">Ảnh chiến dịch</label>
            <div class="grid gap-3 sm:grid-cols-[180px_1fr]">
              <div class="overflow-hidden rounded border border-slate-200 bg-slate-50">
                <img v-if="aiEventForm.imageUrl" :src="aiEventForm.imageUrl" alt="Ảnh đợt hiến" class="h-28 w-full object-cover" />
                <div v-else class="grid h-28 place-items-center text-xs font-bold text-slate-400">Chưa có ảnh</div>
              </div>
              <div class="grid content-start gap-2">
                <label class="flex h-10 cursor-pointer items-center justify-center gap-2 rounded border border-dashed border-slate-300 bg-slate-50 font-bold text-slate-600 hover:bg-slate-100">
                  <Loader2 v-if="isUploadingImage" class="h-4 w-4 animate-spin" />
                  <ImagePlus v-else class="h-4 w-4" />
                  {{ isUploadingImage ? 'Đang tải ảnh...' : 'Tải ảnh từ máy (jpg, png, webp)' }}
                  <input type="file" accept="image/jpeg,image/png,image/webp" class="hidden" :disabled="isUploadingImage" @change="uploadAiEventImage" />
                </label>
                <input
                  v-model="aiEventForm.imageUrl"
                  class="w-full h-10 rounded border border-slate-200 px-3 outline-none focus:border-purple-500 font-semibold"
                  placeholder="Hoặc nhập URL ảnh thủ công https://..."
                />
              </div>
            </div>
          </div>

          <div class="col-span-2 flex gap-2 justify-end pt-4 border-t border-slate-100">
            <button
              type="button"
              @click="showAiEventModal = false"
              class="h-10 px-4 rounded border border-slate-200 text-slate-600 hover:bg-slate-50 font-bold active:scale-95"
            >
              Hủy bỏ
            </button>
            <button
              type="submit"
              :disabled="isSaving"
              class="h-10 px-5 rounded bg-purple-600 hover:bg-purple-700 text-white font-black uppercase tracking-wider active:scale-95 disabled:opacity-50 flex items-center gap-1.5"
            >
              <Plus class="h-4 w-4" />
              {{ isSaving ? 'Đang tạo...' : 'XÁC NHẬN TẠO NGAY' }}
            </button>
          </div>
        </form>
      </div>
    </div>

    <!-- TOAST NOTIFICATION -->
    <div
      v-if="toast.show"
      class="fixed bottom-5 right-5 z-50 rounded-lg px-4 py-3 shadow-lg text-xs font-bold text-white flex items-center gap-2.5 transition-all"
      :class="toast.type === 'success' ? 'bg-slate-900 border border-slate-800' : 'bg-red-600'"
    >
      <CheckCircle2 v-if="toast.type === 'success'" class="h-5 w-5 text-emerald-400" />
      <AlertTriangle v-else class="h-5 w-5 text-white" />
      <span>{{ toast.message }}</span>
    </div>
  </div>
</template>
