<script setup lang="ts">
import { computed, onMounted, reactive, ref } from 'vue'
import {
  CheckCircle2,
  ChevronLeft,
  ChevronRight,
  Edit3,
  KeyRound,
  Loader2,
  Plus,
  RefreshCw,
  ShieldAlert,
  Trash2,
  UserCog,
  X,
} from '@lucide/vue'
import type { AdminPermission, AdminUser, Hospital } from '../types'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000'
const staff = ref<AdminUser[]>([])
const hospitals = ref<Hospital[]>([])
const isLoading = ref(false)
const isSaving = ref(false)
const showModal = ref(false)
const showPermissionMatrix = ref(false)
const editingStaff = ref<AdminUser | null>(null)
const errorMessage = ref('')
const currentPage = ref(1)
const pageSize = 8

const permissionOptions: Array<{ key: AdminPermission; label: string; description: string }> = [
  { key: 'dashboard.view', label: 'Xem dashboard', description: 'Theo dõi số liệu vận hành trong phạm vi được cấp.' },
  { key: 'sos.activate', label: 'Phát lệnh SOS', description: 'Kích hoạt báo động đỏ và điều phối tình nguyện viên.' },
  { key: 'events.manage', label: 'Quản lý sự kiện', description: 'Tạo, sửa và xuất bản lịch hiến máu thường quy.' },
  { key: 'posts.manage', label: 'Quản lý bài viết', description: 'Soạn, chỉnh sửa và xuất bản tin cộng đồng.' },
  { key: 'staff.manage', label: 'Quản lý nhân sự', description: 'Tạo nhân sự bệnh viện và cấp quyền chi tiết.' },
]

const form = reactive({
  name: '',
  email: '',
  phone: '',
  hospitalId: null as number | null,
  password: '',
  permissions: [] as AdminPermission[],
})

const systemAdmins = computed(() => staff.value.filter((member) => member.role === 'system_admin'))
const hospitalStaff = computed(() => staff.value.filter((member) => member.role !== 'system_admin'))
const modalTitle = computed(() => (editingStaff.value ? 'Sửa nhân sự bệnh viện' : 'Thêm nhân sự bệnh viện'))
const totalPages = computed(() => Math.max(1, Math.ceil(staff.value.length / pageSize)))
const pageStart = computed(() => (currentPage.value - 1) * pageSize)
const paginatedStaff = computed(() => staff.value.slice(pageStart.value, pageStart.value + pageSize))
const pageRangeLabel = computed(() => {
  if (!staff.value.length) return '0-0'

  const first = pageStart.value + 1
  const last = Math.min(pageStart.value + pageSize, staff.value.length)

  return `${first}-${last}`
})

function roleLabel(member: AdminUser) {
  if (member.role === 'system_admin') return 'Admin hệ thống'
  return 'Nhân viên bệnh viện'
}

function resetForm() {
  form.name = ''
  form.email = ''
  form.phone = ''
  form.hospitalId = hospitals.value[0]?.id ?? null
  form.password = ''
  form.permissions = ['dashboard.view']
  errorMessage.value = ''
}

async function loadHospitals() {
  const response = await fetch(`${apiBaseUrl}/api/admin/dashboard`)
  const payload = (await response.json()) as { data: { hospitals: Hospital[] } }
  hospitals.value = payload.data.hospitals
}

async function loadStaff() {
  const response = await fetch(`${apiBaseUrl}/api/admin/staff`)
  const payload = (await response.json()) as { data: AdminUser[] }
  staff.value = payload.data
  currentPage.value = Math.min(currentPage.value, totalPages.value)
}

async function loadData() {
  isLoading.value = true
  try {
    await Promise.all([loadHospitals(), loadStaff()])
  } finally {
    isLoading.value = false
  }
}

function openCreateModal() {
  editingStaff.value = null
  resetForm()
  showModal.value = true
}

function openEditModal(member: AdminUser) {
  if (member.role === 'system_admin') return

  editingStaff.value = member
  errorMessage.value = ''
  form.name = member.name
  form.email = member.email
  form.phone = member.phone ?? ''
  form.hospitalId = member.hospital_id ?? hospitals.value[0]?.id ?? null
  form.password = ''
  form.permissions = [...member.permissions]
  showModal.value = true
}

function togglePermission(permission: AdminPermission) {
  form.permissions = form.permissions.includes(permission)
    ? form.permissions.filter((item) => item !== permission)
    : [...form.permissions, permission]
}

async function submitStaff() {
  if (!form.name || !form.email || !form.hospitalId) return

  isSaving.value = true
  errorMessage.value = ''
  try {
    const body: Record<string, unknown> = {
      name: form.name,
      email: form.email,
      phone: form.phone,
      hospital_id: form.hospitalId,
      permissions: form.permissions,
    }
    if (form.password) body.password = form.password

    const endpoint = editingStaff.value
      ? `${apiBaseUrl}/api/admin/staff/${editingStaff.value.id}`
      : `${apiBaseUrl}/api/admin/staff`
    const response = await fetch(endpoint, {
      method: editingStaff.value ? 'PUT' : 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    })
    if (!response.ok) await throwApiError(response)

    showModal.value = false
    await loadStaff()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'Không thể lưu nhân sự.'
  } finally {
    isSaving.value = false
  }
}

async function deleteStaff(member: AdminUser) {
  if (member.role === 'system_admin') return
  if (!window.confirm(`Xóa nhân sự ${member.name}?`)) return

  const response = await fetch(`${apiBaseUrl}/api/admin/staff/${member.id}`, {
    method: 'DELETE',
    headers: { Accept: 'application/json' },
  })
  if (response.ok) {
    await loadStaff()
    currentPage.value = Math.min(currentPage.value, totalPages.value)
  }
}

function goToPage(page: number) {
  currentPage.value = Math.min(Math.max(page, 1), totalPages.value)
}

async function throwApiError(response: Response): Promise<never> {
  const payload = await response.json().catch(() => null) as { message?: string; errors?: Record<string, string[]> } | null
  const firstError = payload?.errors ? Object.values(payload.errors)[0]?.[0] : null
  throw new Error(firstError ?? payload?.message ?? 'Yêu cầu không hợp lệ.')
}

onMounted(() => {
  void loadData()
})
</script>

<template>
  <div class="space-y-5">
    <section class="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
      <div>
        <p class="text-xs font-black uppercase tracking-[0.22em] text-[#E31837]">Bảo mật vận hành</p>
        <h2 class="mt-2 flex items-center gap-2 text-2xl font-black text-slate-950">
          <ShieldAlert class="h-6 w-6 text-[#E31837]" />
          Nhân sự và phân quyền RBAC
        </h2>
        <p class="mt-1 text-sm text-slate-500">Admin hệ thống xem toàn bộ bệnh viện; nhân viên chỉ thao tác trong bệnh viện được gán.</p>
      </div>
      <div class="flex flex-wrap gap-2">
        <button class="inline-flex h-10 items-center gap-2 rounded-md border border-slate-200 px-4 text-xs font-black uppercase text-slate-600" @click="loadData">
          <RefreshCw class="h-4 w-4" />
          Làm mới
        </button>
        <button class="inline-flex h-10 items-center gap-2 rounded-md bg-[#E31837] px-4 text-xs font-black uppercase text-white" @click="openCreateModal">
          <Plus class="h-4 w-4" />
          Thêm nhân sự
        </button>
      </div>
    </section>

    <section class="grid gap-3 sm:grid-cols-2 xl:grid-cols-4">
      <article class="rounded-lg border border-slate-800 bg-slate-950 p-3 text-white">
        <p class="text-[11px] font-black uppercase tracking-[0.16em] text-slate-400">System admin</p>
        <div class="mt-2 flex items-end justify-between gap-3">
          <p class="text-2xl font-black">{{ systemAdmins.length }}</p>
          <span class="rounded-full bg-white/10 px-2 py-1 text-[10px] font-black uppercase text-white">Toàn hệ thống</span>
        </div>
      </article>
      <article class="rounded-lg border border-slate-200 bg-white p-3 shadow-sm">
        <p class="text-[11px] font-black uppercase tracking-[0.16em] text-slate-500">Hospital staff</p>
        <div class="mt-2 flex items-end justify-between gap-3">
          <p class="text-2xl font-black text-slate-950">{{ hospitalStaff.length }}</p>
          <span class="rounded-full bg-red-50 px-2 py-1 text-[10px] font-black uppercase text-[#E31837]">Theo bệnh viện</span>
        </div>
      </article>
      <article class="rounded-lg border border-slate-200 bg-white p-3 shadow-sm">
        <p class="text-[11px] font-black uppercase tracking-[0.16em] text-slate-500">Bệnh viện</p>
        <div class="mt-2 flex items-end justify-between gap-3">
          <p class="text-2xl font-black text-slate-950">{{ hospitals.length }}</p>
          <span class="rounded-full bg-slate-100 px-2 py-1 text-[10px] font-black uppercase text-slate-600">Đang hoạt động</span>
        </div>
      </article>
      <button
        class="flex min-h-[86px] items-center justify-between gap-3 rounded-lg border border-red-100 bg-red-50 p-3 text-left text-[#E31837] shadow-sm hover:border-[#E31837]"
        @click="showPermissionMatrix = true"
      >
        <span>
          <span class="block text-[11px] font-black uppercase tracking-[0.16em]">Ma trận quyền</span>
          <span class="mt-2 block text-sm font-black text-slate-950">{{ permissionOptions.length }} nhóm thao tác</span>
        </span>
        <KeyRound class="h-5 w-5 shrink-0" />
      </button>
    </section>

    <section>
      <article class="overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm">
        <div class="flex flex-col gap-3 border-b border-slate-200 px-5 py-4 md:flex-row md:items-center md:justify-between">
          <div>
            <h3 class="text-base font-black text-slate-950">Danh sách nhân sự</h3>
            <p class="mt-1 text-xs font-bold text-slate-500">Hiển thị {{ pageRangeLabel }} trong {{ staff.length }} tài khoản quản trị.</p>
          </div>
          <button
            class="inline-flex h-9 items-center gap-2 self-start rounded-md border border-red-100 px-3 text-xs font-black uppercase text-[#E31837] hover:bg-red-50 md:self-auto"
            @click="showPermissionMatrix = true"
          >
            <KeyRound class="h-4 w-4" />
            Ma trận quyền
          </button>
        </div>
        <div v-if="isLoading" class="flex items-center justify-center gap-2 p-8 text-sm font-bold text-slate-500">
          <Loader2 class="h-4 w-4 animate-spin" />
          Đang tải nhân sự...
        </div>
        <div v-else class="overflow-x-auto">
          <table class="w-full min-w-[1040px] text-left text-sm">
            <thead class="bg-slate-50 text-[11px] font-black uppercase tracking-[0.16em] text-slate-500">
              <tr>
                <th class="px-5 py-4">Nhân sự</th>
                <th class="px-5 py-4">Phạm vi</th>
                <th class="px-5 py-4">Vai trò</th>
                <th class="px-5 py-4">Quyền</th>
                <th class="px-5 py-4 text-center">Trạng thái</th>
                <th class="px-5 py-4 text-right">Thao tác</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-slate-100">
              <tr v-for="member in paginatedStaff" :key="member.id" class="hover:bg-slate-50/60">
                <td class="px-5 py-4">
                  <p class="font-bold text-slate-950">{{ member.name }}</p>
                  <p class="mt-1 text-xs text-slate-500">{{ member.email }}</p>
                </td>
                <td class="px-5 py-4 text-slate-600">{{ member.scope_label }}</td>
                <td class="min-w-[150px] px-5 py-4">
                  <span class="whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-black" :class="member.role === 'system_admin' ? 'bg-slate-950 text-white' : 'bg-red-50 text-[#E31837]'">
                    {{ roleLabel(member) }}
                  </span>
                </td>
                <td class="px-5 py-4">
                  <div class="flex max-w-sm flex-wrap gap-1.5">
                    <span
                      v-for="permission in member.permissions"
                      :key="permission"
                      class="rounded bg-slate-100 px-2 py-0.5 text-[10px] font-bold text-slate-600"
                    >
                      {{ permission }}
                    </span>
                    <span v-if="member.role === 'system_admin'" class="rounded bg-slate-100 px-2 py-0.5 text-[10px] font-bold text-slate-600">
                      toàn quyền
                    </span>
                  </div>
                </td>
                <td class="min-w-[150px] px-5 py-4 text-center">
                  <span class="inline-flex items-center gap-1 whitespace-nowrap rounded-full px-2.5 py-1 text-xs font-black" :class="member.active ? 'bg-emerald-50 text-emerald-700' : 'bg-slate-100 text-slate-500'">
                    <CheckCircle2 class="h-3.5 w-3.5" />
                    {{ member.active ? 'Đang hoạt động' : 'Chưa hoạt động' }}
                  </span>
                </td>
                <td class="px-5 py-4 text-right">
                  <div class="flex justify-end gap-2">
                    <button
                      class="inline-flex items-center gap-2 rounded-md border border-slate-200 px-3 py-2 text-xs font-black text-slate-700 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
                      :disabled="member.role === 'system_admin'"
                      @click="openEditModal(member)"
                    >
                      <Edit3 class="h-3.5 w-3.5" />
                      Sửa
                    </button>
                    <button
                      class="inline-flex items-center gap-2 rounded-md border border-red-100 px-3 py-2 text-xs font-black text-[#E31837] hover:bg-red-50 disabled:cursor-not-allowed disabled:opacity-40"
                      :disabled="member.role === 'system_admin'"
                      @click="deleteStaff(member)"
                    >
                      <Trash2 class="h-3.5 w-3.5" />
                      Xóa
                    </button>
                  </div>
                </td>
              </tr>
            </tbody>
          </table>
        </div>

        <div v-if="!isLoading" class="flex flex-col gap-3 border-t border-slate-200 px-5 py-4 sm:flex-row sm:items-center sm:justify-between">
          <p class="text-xs font-bold text-slate-500">Trang {{ currentPage }} / {{ totalPages }}</p>
          <div class="flex items-center gap-2">
            <button
              class="inline-flex h-9 w-9 items-center justify-center rounded-md border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
              :disabled="currentPage === 1"
              @click="goToPage(currentPage - 1)"
              aria-label="Trang trước"
            >
              <ChevronLeft class="h-4 w-4" />
            </button>
            <button
              v-for="page in totalPages"
              :key="page"
              class="h-9 min-w-9 rounded-md border px-3 text-xs font-black"
              :class="page === currentPage ? 'border-[#E31837] bg-[#E31837] text-white' : 'border-slate-200 text-slate-600 hover:bg-slate-50'"
              @click="goToPage(page)"
            >
              {{ page }}
            </button>
            <button
              class="inline-flex h-9 w-9 items-center justify-center rounded-md border border-slate-200 text-slate-600 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40"
              :disabled="currentPage === totalPages"
              @click="goToPage(currentPage + 1)"
              aria-label="Trang sau"
            >
              <ChevronRight class="h-4 w-4" />
            </button>
          </div>
        </div>
      </article>
    </section>

    <div v-if="showPermissionMatrix" class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
      <aside class="w-full max-w-2xl rounded-lg bg-white shadow-2xl">
        <div class="flex items-center justify-between border-b border-slate-200 p-5">
          <h3 class="flex items-center gap-2 text-lg font-black text-slate-950">
            <KeyRound class="h-5 w-5 text-[#E31837]" />
            Ma trận quyền
          </h3>
          <button type="button" class="rounded-md p-2 text-slate-500 hover:bg-slate-100" @click="showPermissionMatrix = false">
            <X class="h-4 w-4" />
          </button>
        </div>
        <div class="grid max-h-[70vh] gap-3 overflow-y-auto p-5 md:grid-cols-2">
          <div v-for="permission in permissionOptions" :key="permission.key" class="rounded-md border border-slate-100 bg-slate-50 p-3">
            <p class="font-black text-slate-950">{{ permission.label }}</p>
            <p class="mt-1 font-mono text-[11px] font-bold text-[#E31837]">{{ permission.key }}</p>
            <p class="mt-2 text-xs leading-5 text-slate-500">{{ permission.description }}</p>
          </div>
        </div>
      </aside>
    </div>

    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
      <form class="w-full max-w-2xl rounded-lg bg-white p-5 shadow-2xl" @submit.prevent="submitStaff">
        <div class="flex items-center justify-between border-b border-slate-200 pb-4">
          <h3 class="flex items-center gap-2 text-lg font-black text-slate-950">
            <UserCog class="h-5 w-5 text-[#E31837]" />
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
          <div class="grid gap-3 md:grid-cols-2">
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Họ tên</span>
              <input v-model="form.name" required class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" />
            </label>
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Email đăng nhập</span>
              <input v-model="form.email" required type="email" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" />
            </label>
          </div>

          <div class="grid gap-3 md:grid-cols-2">
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Số điện thoại</span>
              <input v-model="form.phone" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" />
            </label>
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Bệnh viện phụ trách</span>
              <select v-model.number="form.hospitalId" required class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
                <option v-for="hospital in hospitals" :key="hospital.id" :value="hospital.id">{{ hospital.name }}</option>
              </select>
            </label>
          </div>

          <label class="block">
            <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Mật khẩu {{ editingStaff ? 'mới nếu cần đổi' : 'ban đầu' }}</span>
            <input v-model="form.password" :required="!editingStaff" type="password" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" placeholder="Tối thiểu 6 ký tự" />
          </label>

          <div>
            <p class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Quyền chi tiết</p>
            <div class="mt-2 grid gap-2 md:grid-cols-2">
              <label
                v-for="permission in permissionOptions"
                :key="permission.key"
                class="flex cursor-pointer items-start gap-3 rounded-md border border-slate-200 p-3 hover:bg-slate-50"
              >
                <input
                  type="checkbox"
                  class="mt-1 h-4 w-4 rounded border-slate-300 text-[#E31837]"
                  :checked="form.permissions.includes(permission.key)"
                  @change="togglePermission(permission.key)"
                />
                <span>
                  <span class="block text-sm font-black text-slate-950">{{ permission.label }}</span>
                  <span class="mt-1 block text-xs text-slate-500">{{ permission.description }}</span>
                </span>
              </label>
            </div>
          </div>
        </div>

        <div class="mt-5 flex justify-end gap-3">
          <button type="button" class="rounded-md border border-slate-200 px-4 py-2 text-sm font-bold text-slate-700" @click="showModal = false">Hủy</button>
          <button type="submit" class="inline-flex items-center gap-2 rounded-md bg-[#E31837] px-4 py-2 text-sm font-black text-white">
            <Loader2 v-if="isSaving" class="h-4 w-4 animate-spin" />
            Lưu nhân sự
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
