<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { ShieldCheck, AlertCircle, CheckCircle, XCircle, Clock, Eye } from '@lucide/vue'

const props = defineProps<{
  apiBaseUrl: string
}>()

interface IdVerification {
  id: number
  name: string
  email: string
  phone: string | null
  blood_type: string | null
  date_of_birth: string | null
  gender: string | null
  address: string | null
  national_id: string | null
  id_card_front_url: string | null
  id_card_back_url: string | null
  id_verification_status: 'unverified' | 'pending' | 'verified' | 'rejected'
  id_verified_at: string | null
  id_rejection_reason: string | null
  created_at: string | null
}

const items = ref<IdVerification[]>([])
const isLoading = ref(false)
const errorMsg = ref<string | null>(null)
const successMsg = ref<string | null>(null)
const statusFilter = ref<'pending' | 'verified' | 'rejected' | 'all'>('pending')

// Ảnh phóng to
const previewUrl = ref<string | null>(null)

// Modal từ chối
const rejectingUser = ref<IdVerification | null>(null)
const rejectReason = ref('')

const genderLabel = (g: string | null) =>
  g === 'male' ? 'Nam' : g === 'female' ? 'Nữ' : g === 'other' ? 'Khác' : '-'

const statusMeta = computed(() => ({
  pending: { label: 'Chờ duyệt', class: 'bg-amber-50 text-amber-700' },
  verified: { label: 'Đã xác thực', class: 'bg-emerald-50 text-emerald-700' },
  rejected: { label: 'Bị từ chối', class: 'bg-red-50 text-red-700' },
  unverified: { label: 'Chưa nộp', class: 'bg-slate-100 text-slate-600' },
}))

async function fetchItems() {
  isLoading.value = true
  errorMsg.value = null
  try {
    const res = await fetch(`${props.apiBaseUrl}/api/admin/id-verifications?status=${statusFilter.value}`)
    if (!res.ok) throw new Error('Không thể tải danh sách xác thực căn cước.')
    const payload = await res.json()
    items.value = payload.data
  } catch (e: any) {
    errorMsg.value = e.message
  } finally {
    isLoading.value = false
  }
}

async function approve(user: IdVerification) {
  if (!confirm(`Xác nhận đã kiểm tra và duyệt căn cước của "${user.name}"?`)) return
  errorMsg.value = null
  successMsg.value = null
  try {
    const res = await fetch(`${props.apiBaseUrl}/api/admin/id-verifications/${user.id}/approve`, {
      method: 'POST',
      headers: { Accept: 'application/json' },
    })
    if (!res.ok) throw new Error('Không thể duyệt hồ sơ.')
    successMsg.value = `Đã xác thực căn cước cho ${user.name}.`
    await fetchItems()
  } catch (e: any) {
    errorMsg.value = e.message
  }
}

function openReject(user: IdVerification) {
  rejectingUser.value = user
  rejectReason.value = ''
}

async function submitReject() {
  if (!rejectingUser.value) return
  if (!rejectReason.value.trim()) {
    errorMsg.value = 'Vui lòng nhập lý do từ chối.'
    return
  }
  errorMsg.value = null
  successMsg.value = null
  try {
    const res = await fetch(`${props.apiBaseUrl}/api/admin/id-verifications/${rejectingUser.value.id}/reject`, {
      method: 'POST',
      headers: { Accept: 'application/json', 'Content-Type': 'application/json' },
      body: JSON.stringify({ reason: rejectReason.value.trim() }),
    })
    if (!res.ok) throw new Error('Không thể từ chối hồ sơ.')
    successMsg.value = `Đã từ chối hồ sơ của ${rejectingUser.value.name}.`
    rejectingUser.value = null
    await fetchItems()
  } catch (e: any) {
    errorMsg.value = e.message
  }
}

function setFilter(f: typeof statusFilter.value) {
  statusFilter.value = f
  fetchItems()
}

function formatDate(dateStr: string | null) {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleDateString('vi-VN')
}

onMounted(fetchItems)
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-black tracking-wide text-slate-900 flex items-center gap-2">
          <ShieldCheck class="h-7 w-7 text-[#E31837]" />
          XÁC THỰC CĂN CƯỚC
        </h1>
        <p class="text-sm text-slate-500">Kiểm tra và duyệt căn cước công dân của người hiến máu để đảm bảo thông tin chính xác.</p>
      </div>
    </div>

    <!-- Alerts -->
    <div v-if="errorMsg" class="flex items-center gap-2 rounded-xl bg-red-50 border border-red-200 p-4 text-red-600 text-sm">
      <AlertCircle class="h-4 w-4 shrink-0" />
      {{ errorMsg }}
    </div>
    <div v-if="successMsg" class="flex items-center gap-2 rounded-xl bg-green-50 border border-green-200 p-4 text-green-600 text-sm">
      <CheckCircle class="h-4 w-4 shrink-0" />
      {{ successMsg }}
    </div>

    <!-- Filter tabs -->
    <div class="flex gap-2">
      <button
        v-for="f in (['pending', 'verified', 'rejected', 'all'] as const)"
        :key="f"
        @click="setFilter(f)"
        class="rounded-xl px-4 py-2 text-sm font-bold transition"
        :class="statusFilter === f ? 'bg-[#E31837] text-white' : 'bg-white border border-slate-200 text-slate-500 hover:bg-slate-50'"
      >
        {{ f === 'pending' ? 'Chờ duyệt' : f === 'verified' ? 'Đã xác thực' : f === 'rejected' ? 'Bị từ chối' : 'Tất cả' }}
      </button>
    </div>

    <!-- List -->
    <div v-if="isLoading" class="py-12 text-center text-slate-400 font-bold">Đang tải...</div>
    <div v-else-if="items.length === 0" class="rounded-2xl border border-slate-200 bg-white p-12 text-center text-slate-400 font-bold">
      Không có hồ sơ nào.
    </div>
    <div v-else class="grid grid-cols-1 gap-4">
      <div v-for="u in items" :key="u.id" class="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex flex-wrap items-start justify-between gap-4">
          <!-- Info -->
          <div class="space-y-1">
            <div class="flex items-center gap-2">
              <span class="font-black text-slate-900">{{ u.name }}</span>
              <span class="rounded px-2 py-0.5 text-[11px] font-bold" :class="statusMeta[u.id_verification_status].class">
                {{ statusMeta[u.id_verification_status].label }}
              </span>
            </div>
            <div class="text-xs text-slate-500">{{ u.email }} · {{ u.phone ?? 'Chưa có SĐT' }}</div>
            <div class="text-xs text-slate-500">
              CCCD: <span class="font-bold text-slate-700">{{ u.national_id ?? '-' }}</span>
              · Nhóm máu: <span class="font-bold text-slate-700">{{ u.blood_type ?? '-' }}</span>
            </div>
            <div class="text-xs text-slate-500">
              Ngày sinh: {{ formatDate(u.date_of_birth) }} · Giới tính: {{ genderLabel(u.gender) }}
            </div>
            <div v-if="u.address" class="text-xs text-slate-500">Địa chỉ: {{ u.address }}</div>
            <div v-if="u.id_verification_status === 'rejected' && u.id_rejection_reason" class="text-xs text-red-600 font-semibold">
              Lý do từ chối: {{ u.id_rejection_reason }}
            </div>
          </div>

          <!-- Actions -->
          <div v-if="u.id_verification_status === 'pending'" class="flex gap-2">
            <button @click="approve(u)" class="flex items-center gap-1.5 rounded-xl bg-emerald-600 px-4 py-2 text-sm font-bold text-white hover:bg-emerald-700 transition">
              <CheckCircle class="h-4 w-4" /> Duyệt
            </button>
            <button @click="openReject(u)" class="flex items-center gap-1.5 rounded-xl border border-red-200 bg-red-50 px-4 py-2 text-sm font-bold text-red-600 hover:bg-red-100 transition">
              <XCircle class="h-4 w-4" /> Từ chối
            </button>
          </div>
          <div v-else-if="u.id_verification_status === 'verified'" class="flex items-center gap-1.5 text-emerald-600 text-sm font-bold">
            <CheckCircle class="h-4 w-4" /> Đã duyệt {{ formatDate(u.id_verified_at) }}
          </div>
          <div v-else-if="u.id_verification_status === 'rejected'" class="flex items-center gap-1.5 text-slate-400 text-sm font-bold">
            <Clock class="h-4 w-4" /> Chờ nộp lại
          </div>
        </div>

        <!-- ID card images -->
        <div class="mt-4 grid grid-cols-2 gap-3 sm:max-w-md">
          <div v-for="(img, idx) in [{ url: u.id_card_front_url, label: 'Mặt trước' }, { url: u.id_card_back_url, label: 'Mặt sau' }]" :key="idx">
            <div class="text-[11px] font-bold text-slate-400 uppercase mb-1">{{ img.label }}</div>
            <div
              v-if="img.url"
              class="group relative aspect-[8/5] cursor-pointer overflow-hidden rounded-xl border border-slate-200"
              @click="previewUrl = img.url"
            >
              <img :src="img.url" :alt="img.label" class="h-full w-full object-cover" />
              <div class="absolute inset-0 hidden items-center justify-center bg-black/40 group-hover:flex">
                <Eye class="h-6 w-6 text-white" />
              </div>
            </div>
            <div v-else class="aspect-[8/5] grid place-items-center rounded-xl border border-dashed border-slate-200 text-xs text-slate-400">
              Chưa có ảnh
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Image preview modal -->
    <div v-if="previewUrl" class="fixed inset-0 z-50 flex items-center justify-center bg-black/70 p-6" @click="previewUrl = null">
      <img :src="previewUrl" alt="CCCD" class="max-h-[85vh] max-w-full rounded-xl" />
    </div>

    <!-- Reject reason modal -->
    <div v-if="rejectingUser" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <div class="w-full max-w-md rounded-2xl border border-slate-200 bg-white p-6 shadow-2xl">
        <h3 class="text-lg font-black text-slate-900 uppercase tracking-wide mb-1">Từ chối hồ sơ</h3>
        <p class="text-sm text-slate-500 mb-4">Nhập lý do để người dùng biết cần chỉnh sửa gì khi nộp lại.</p>
        <textarea
          v-model="rejectReason"
          rows="3"
          class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-[#E31837] focus:ring-2 focus:ring-red-50"
          placeholder="Ví dụ: Ảnh mặt trước bị mờ, không đọc được số CCCD."
        ></textarea>
        <div class="mt-4 flex justify-end gap-2">
          <button @click="rejectingUser = null" class="rounded-xl border border-slate-200 px-4 py-2 text-sm text-slate-500 hover:bg-slate-50">Hủy</button>
          <button @click="submitReject" class="rounded-xl bg-[#E31837] px-5 py-2 text-sm font-bold text-white hover:bg-[#E31837]/90 transition">Xác nhận từ chối</button>
        </div>
      </div>
    </div>
  </div>
</template>
