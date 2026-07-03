<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import {
  ChevronLeft,
  ChevronRight,
  Edit3,
  FileText,
  ImagePlus,
  Loader2,
  Plus,
  RefreshCw,
  Save,
  Search,
  Send,
  X,
} from '@lucide/vue'
import type { CommunityPost, Hospital, PaginatedResponse, PaginationMeta, Province, UploadResponse, Ward } from '../types'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000'
const posts = ref<CommunityPost[]>([])
const hospitals = ref<Hospital[]>([])
const provinces = ref<Province[]>([])
const wards = ref<Ward[]>([])
const isLoading = ref(false)
const isSaving = ref(false)
const isUploading = ref(false)
const showModal = ref(false)
const editingPost = ref<CommunityPost | null>(null)
const errorMessage = ref('')
const searchKeyword = ref('')
const statusFilter = ref('')
const page = ref(1)
const meta = ref<PaginationMeta>({ current_page: 1, last_page: 1, per_page: 10, total: 0 })

const form = reactive({
  hospitalId: null as number | null,
  title: '',
  excerpt: '',
  content: '',
  imageUrl: '',
  status: 'draft' as CommunityPost['status'],
  audienceType: 'all' as CommunityPost['audience_type'],
  targetBloodType: 'O+',
  targetHeroLevel: 'Gold Badge',
  provinceCode: '79',
  wardCode: '',
})

const modalTitle = computed(() => (editingPost.value ? 'Sửa bài viết cộng đồng' : 'Tạo bài viết cộng đồng'))
const publishedPostsOnPage = computed(() => posts.value.filter((post) => post.status === 'published').length)
const totalViewsOnPage = computed(() => posts.value.reduce((total, post) => total + post.views_count, 0))

function resetForm() {
  form.hospitalId = hospitals.value[0]?.id ?? null
  form.title = ''
  form.excerpt = ''
  form.content = ''
  form.imageUrl = 'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?auto=format&fit=crop&q=80&w=900'
  form.status = 'draft'
  form.audienceType = 'all'
  form.targetBloodType = 'O+'
  form.targetHeroLevel = 'Gold Badge'
  form.provinceCode = '79'
  form.wardCode = ''
  errorMessage.value = ''
}

function formattedDate(value: string | null) {
  if (!value) return 'Chưa xuất bản'
  return new Intl.DateTimeFormat('vi-VN', {
    day: '2-digit',
    month: '2-digit',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).format(new Date(value))
}

async function loadPosts() {
  isLoading.value = true
  try {
    const params = new URLSearchParams({
      page: String(page.value),
      per_page: String(meta.value.per_page),
    })
    if (statusFilter.value) params.set('status', statusFilter.value)
    if (searchKeyword.value.trim()) params.set('q', searchKeyword.value.trim())

    const response = await fetch(`${apiBaseUrl}/api/admin/community-posts?${params.toString()}`)
    const payload = (await response.json()) as PaginatedResponse<CommunityPost>
    posts.value = payload.data
    meta.value = payload.meta
    page.value = payload.meta.current_page
  } finally {
    isLoading.value = false
  }
}

async function loadHospitals() {
  const response = await fetch(`${apiBaseUrl}/api/admin/dashboard`)
  const payload = (await response.json()) as { data: { hospitals: Hospital[] } }
  hospitals.value = payload.data.hospitals
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
  editingPost.value = null
  resetForm()
  showModal.value = true
  void loadWards(form.provinceCode)
}

function openEditModal(post: CommunityPost) {
  editingPost.value = post
  errorMessage.value = ''
  form.hospitalId = post.hospital?.id ?? null
  form.title = post.title
  form.excerpt = post.excerpt ?? ''
  form.content = post.content
  form.imageUrl = post.image_url ?? ''
  form.status = post.status
  form.audienceType = post.audience_type
  form.targetBloodType = post.target_blood_type ?? 'O+'
  form.targetHeroLevel = post.target_hero_level ?? 'Gold Badge'
  form.provinceCode = post.province_code ?? '79'
  form.wardCode = post.ward_code ?? ''
  showModal.value = true
  void loadWards(form.provinceCode)
}

async function uploadImage(event: Event) {
  const file = (event.target as HTMLInputElement).files?.[0]
  if (!file) return

  isUploading.value = true
  errorMessage.value = ''
  try {
    const body = new FormData()
    body.append('file', file)

    const response = await fetch(`${apiBaseUrl}/api/admin/uploads`, {
      method: 'POST',
      headers: { Accept: 'application/json' },
      body,
    })
    if (!response.ok) await throwApiError(response)

    const payload = (await response.json()) as UploadResponse
    form.imageUrl = payload.data.url
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'Không thể tải ảnh lên.'
  } finally {
    isUploading.value = false
  }
}

function buildPayload(status: CommunityPost['status']) {
  return {
    hospital_id: form.hospitalId,
    title: form.title,
    excerpt: form.excerpt,
    content: form.content,
    image_url: form.imageUrl,
    status,
    audience_type: form.audienceType,
    target_blood_type: form.audienceType === 'blood_type' ? form.targetBloodType : null,
    target_hero_level: form.audienceType === 'hero_level' ? form.targetHeroLevel : null,
    province_code: form.audienceType === 'province' ? form.provinceCode : null,
    ward_code: form.audienceType === 'province' ? form.wardCode : null,
  }
}

async function submitPost(status: CommunityPost['status']) {
  if (!form.title || !form.content) return

  form.status = status
  isSaving.value = true
  errorMessage.value = ''
  try {
    const endpoint = editingPost.value
      ? `${apiBaseUrl}/api/admin/community-posts/${editingPost.value.id}`
      : `${apiBaseUrl}/api/admin/community-posts`
    const response = await fetch(endpoint, {
      method: editingPost.value ? 'PUT' : 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(buildPayload(status)),
    })
    if (!response.ok) await throwApiError(response)

    showModal.value = false
    await loadPosts()
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'Không thể lưu bài viết.'
  } finally {
    isSaving.value = false
  }
}

async function throwApiError(response: Response): Promise<never> {
  const payload = await response.json().catch(() => null) as { message?: string; errors?: Record<string, string[]> } | null
  const firstError = payload?.errors ? Object.values(payload.errors)[0]?.[0] : null
  throw new Error(firstError ?? payload?.message ?? 'Yêu cầu không hợp lệ.')
}

function goToPage(nextPage: number) {
  if (nextPage < 1 || nextPage > meta.value.last_page || nextPage === page.value) return
  page.value = nextPage
  void loadPosts()
}

watch(
  () => form.provinceCode,
  (provinceCode) => {
    void loadWards(provinceCode)
  },
)

watch([searchKeyword, statusFilter], () => {
  page.value = 1
  void loadPosts()
})

onMounted(async () => {
  await Promise.all([loadHospitals(), loadProvinces(), loadPosts()])
  resetForm()
  await loadWards(form.provinceCode)
})
</script>

<template>
  <div class="space-y-5">
    <section class="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
      <div>
        <p class="text-xs font-black uppercase tracking-[0.22em] text-[#E31837]">Truyền thông cộng đồng</p>
        <h2 class="mt-2 text-2xl font-black text-slate-950">Quản lý bài viết và đối tượng nhận tin</h2>
        <p class="mt-1 text-sm text-slate-500">Soạn, lưu nháp, chỉnh sửa và xuất bản tin cộng đồng cho Mobile App.</p>
      </div>
      <div class="flex flex-wrap gap-2">
        <button class="inline-flex h-10 items-center gap-2 rounded-md border border-slate-200 px-4 text-xs font-black uppercase text-slate-600" @click="loadPosts">
          <RefreshCw class="h-4 w-4" />
          Làm mới
        </button>
        <button class="inline-flex h-10 items-center gap-2 rounded-md bg-[#E31837] px-4 text-xs font-black uppercase text-white" @click="openCreateModal">
          <Plus class="h-4 w-4" />
          Tạo bài viết
        </button>
      </div>
    </section>

    <section class="grid gap-4 md:grid-cols-3">
      <article class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Tổng bài viết</p>
        <p class="mt-1 text-2xl font-black text-slate-950">{{ meta.total }}</p>
      </article>
      <article class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Đã xuất bản trang này</p>
        <p class="mt-1 text-2xl font-black text-[#E31837]">{{ publishedPostsOnPage }}</p>
      </article>
      <article class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Lượt xem trang này</p>
        <p class="mt-1 text-2xl font-black text-slate-950">{{ totalViewsOnPage }}</p>
      </article>
    </section>

    <section class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
      <div class="grid gap-3 md:grid-cols-[1fr_220px]">
        <label class="block">
          <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Tìm kiếm</span>
          <div class="mt-1 flex h-10 items-center gap-2 rounded-md border border-slate-200 bg-white px-3 transition focus-within:border-[#E31837] focus-within:ring-2 focus-within:ring-red-50">
            <Search class="h-4 w-4 shrink-0 text-slate-400" />
            <input v-model="searchKeyword" class="h-full min-w-0 flex-1 border-0 bg-transparent text-sm outline-none" placeholder="Tiêu đề, tóm tắt, nội dung" />
          </div>
        </label>
        <label class="block">
          <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Trạng thái</span>
          <select v-model="statusFilter" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm font-semibold outline-none focus:border-[#E31837]">
            <option value="">Tất cả trạng thái</option>
            <option value="published">Đã xuất bản</option>
            <option value="draft">Nháp</option>
          </select>
        </label>
      </div>
    </section>

    <section class="overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm">
      <div v-if="isLoading" class="flex items-center justify-center gap-2 p-8 text-sm font-bold text-slate-500">
        <Loader2 class="h-4 w-4 animate-spin" />
        Đang tải bài viết...
      </div>
      <div v-else-if="posts.length === 0" class="p-10 text-center text-sm text-slate-500">
        Chưa có bài viết phù hợp với bộ lọc hiện tại.
      </div>
      <div v-else class="overflow-x-auto">
        <table class="w-full min-w-[980px] text-left text-sm">
          <thead class="bg-slate-50 text-[11px] font-black uppercase tracking-[0.16em] text-slate-500">
            <tr>
              <th class="px-5 py-4">Bài viết</th>
              <th class="px-5 py-4">Đối tượng nhận tin</th>
              <th class="px-5 py-4">Bệnh viện</th>
              <th class="px-5 py-4 text-center">Lượt xem</th>
              <th class="px-5 py-4 text-center">Trạng thái</th>
              <th class="px-5 py-4 text-right">Thao tác</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr v-for="post in posts" :key="post.id" class="hover:bg-slate-50/60">
              <td class="px-5 py-4">
                <p class="font-black text-slate-950">{{ post.title }}</p>
                <p class="mt-1 line-clamp-2 max-w-xl text-xs text-slate-500">{{ post.excerpt ?? post.slug }}</p>
                <p class="mt-2 text-[11px] font-semibold text-slate-400">{{ formattedDate(post.published_at) }}</p>
              </td>
              <td class="px-5 py-4 text-slate-600">{{ post.audience_label }}</td>
              <td class="px-5 py-4 text-slate-600">{{ post.hospital?.name ?? 'Toàn hệ thống' }}</td>
              <td class="px-5 py-4 text-center font-black text-slate-950">{{ post.views_count }}</td>
              <td class="px-5 py-4 text-center">
                <span class="rounded-full px-2.5 py-1 text-xs font-black" :class="post.status === 'published' ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'">
                  {{ post.status === 'published' ? 'Đã xuất bản' : 'Nháp' }}
                </span>
              </td>
              <td class="px-5 py-4 text-right">
                <button class="inline-flex items-center gap-2 rounded-md border border-slate-200 px-3 py-2 text-xs font-black text-slate-700 hover:bg-slate-50" @click="openEditModal(post)">
                  <Edit3 class="h-3.5 w-3.5" />
                  Sửa
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div class="flex flex-col gap-3 border-t border-slate-100 px-4 py-3 text-sm text-slate-500 md:flex-row md:items-center md:justify-between">
        <span>Trang {{ meta.current_page }} / {{ meta.last_page }} · {{ meta.total }} bài viết</span>
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

    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/60 p-4 backdrop-blur-sm">
      <form class="max-h-[92vh] w-full max-w-4xl overflow-y-auto rounded-lg bg-white p-5 shadow-2xl" @submit.prevent="submitPost(form.status)">
        <div class="flex items-center justify-between border-b border-slate-200 pb-4">
          <h3 class="flex items-center gap-2 text-lg font-black text-slate-950">
            <FileText class="h-5 w-5 text-[#E31837]" />
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
          <div class="grid gap-3 md:grid-cols-[1fr_220px]">
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Tiêu đề bài viết</span>
              <input v-model="form.title" required class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" />
            </label>
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Trạng thái mặc định</span>
              <select v-model="form.status" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
                <option value="draft">Nháp</option>
                <option value="published">Đã xuất bản</option>
              </select>
            </label>
          </div>

          <label class="block">
            <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Tóm tắt hiển thị trên Mobile</span>
            <input v-model="form.excerpt" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" />
          </label>

          <div class="grid gap-3 md:grid-cols-2">
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Bệnh viện/tác giả</span>
              <select v-model.number="form.hospitalId" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
                <option :value="null">Toàn hệ thống</option>
                <option v-for="hospital in hospitals" :key="hospital.id" :value="hospital.id">{{ hospital.name }}</option>
              </select>
            </label>
            <label class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Đối tượng nhận tin</span>
              <select v-model="form.audienceType" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
                <option value="all">Tất cả người dùng</option>
                <option value="blood_type">Theo nhóm máu</option>
                <option value="hero_level">Theo cấp Hero</option>
                <option value="province">Theo tỉnh/thành</option>
              </select>
            </label>
          </div>

          <div class="grid gap-3 md:grid-cols-2">
            <label v-if="form.audienceType === 'blood_type'" class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Nhóm máu mục tiêu</span>
              <select v-model="form.targetBloodType" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
                <option>O+</option>
                <option>O-</option>
                <option>A+</option>
                <option>A-</option>
                <option>B+</option>
                <option>B-</option>
                <option>AB+</option>
                <option>AB-</option>
              </select>
            </label>
            <label v-if="form.audienceType === 'hero_level'" class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Cấp Hero mục tiêu</span>
              <select v-model="form.targetHeroLevel" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
                <option value="Bronze Badge">Huy hiệu Đồng</option>
                <option value="Silver Badge">Huy hiệu Bạc</option>
                <option value="Gold Badge">Huy hiệu Vàng</option>
                <option value="Platinum Badge">Huy hiệu Bạch kim</option>
              </select>
            </label>
            <label v-if="form.audienceType === 'province'" class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Tỉnh/thành mục tiêu</span>
              <select v-model="form.provinceCode" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
                <option v-for="province in provinces" :key="province.code" :value="province.code">{{ province.full_name }}</option>
              </select>
            </label>
            <label v-if="form.audienceType === 'province'" class="block">
              <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Xã/phường mục tiêu</span>
              <select v-model="form.wardCode" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]">
                <option value="">Toàn tỉnh/thành</option>
                <option v-for="ward in wards" :key="ward.code" :value="ward.code">{{ ward.full_name }}</option>
              </select>
            </label>
          </div>

          <div class="grid gap-3 md:grid-cols-[220px_1fr]">
            <div class="overflow-hidden rounded-lg border border-slate-200 bg-slate-50">
              <img v-if="form.imageUrl" :src="form.imageUrl" alt="Ảnh bài viết" class="h-36 w-full object-cover" />
              <div v-else class="grid h-36 place-items-center text-sm font-bold text-slate-400">Chưa có ảnh</div>
            </div>
            <div class="grid gap-3">
              <label class="block">
                <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Tải ảnh từ máy</span>
                <label class="mt-1 flex h-10 cursor-pointer items-center justify-center gap-2 rounded-md border border-dashed border-slate-300 bg-slate-50 text-sm font-black text-slate-600 hover:bg-slate-100">
                  <Loader2 v-if="isUploading" class="h-4 w-4 animate-spin" />
                  <ImagePlus v-else class="h-4 w-4" />
                  {{ isUploading ? 'Đang tải ảnh...' : 'Chọn ảnh jpg, png, webp' }}
                  <input type="file" accept="image/jpeg,image/png,image/webp" class="hidden" @change="uploadImage" />
                </label>
              </label>
              <label class="block">
                <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Hoặc nhập URL ảnh thủ công</span>
                <input v-model="form.imageUrl" class="mt-1 h-10 w-full rounded-md border border-slate-200 px-3 text-sm outline-none focus:border-[#E31837]" placeholder="https://..." />
              </label>
            </div>
          </div>

          <label class="block">
            <span class="text-xs font-black uppercase tracking-[0.14em] text-slate-500">Nội dung bài viết</span>
            <textarea v-model="form.content" required rows="12" class="mt-1 w-full rounded-md border border-slate-200 px-3 py-2 text-sm leading-6 outline-none focus:border-[#E31837]" />
          </label>
        </div>

        <div class="mt-5 flex flex-wrap justify-end gap-3">
          <button type="button" class="rounded-md border border-slate-200 px-4 py-2 text-sm font-bold text-slate-700" @click="showModal = false">Hủy</button>
          <button type="button" class="inline-flex items-center gap-2 rounded-md border border-slate-200 px-4 py-2 text-sm font-black text-slate-700" @click="submitPost('draft')">
            <Loader2 v-if="isSaving && form.status === 'draft'" class="h-4 w-4 animate-spin" />
            <Save v-else class="h-4 w-4" />
            Lưu nháp
          </button>
          <button type="button" class="inline-flex items-center gap-2 rounded-md bg-[#E31837] px-4 py-2 text-sm font-black text-white" @click="submitPost('published')">
            <Loader2 v-if="isSaving && form.status === 'published'" class="h-4 w-4 animate-spin" />
            <Send v-else class="h-4 w-4" />
            Xuất bản
          </button>
        </div>
      </form>
    </div>
  </div>
</template>
