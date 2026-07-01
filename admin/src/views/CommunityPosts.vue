<script setup lang="ts">
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { FileText, Loader2, RefreshCw, Send } from '@lucide/vue'
import type { CommunityPost, Province, Ward } from '../types'

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000'
const posts = ref<CommunityPost[]>([])
const provinces = ref<Province[]>([])
const wards = ref<Ward[]>([])
const isLoading = ref(false)
const isSaving = ref(false)
const published = ref(false)
const form = reactive({
  title: '',
  excerpt: '',
  content: '',
  imageUrl: 'https://images.unsplash.com/photo-1530026405186-ed1f139313f8?auto=format&fit=crop&q=80&w=900',
  audienceType: 'all' as CommunityPost['audience_type'],
  targetBloodType: 'O+',
  targetHeroLevel: 'Gold Badge',
  provinceCode: '79',
  wardCode: '',
})

const totalViews = computed(() => posts.value.reduce((total, post) => total + post.views_count, 0))
const publishedPosts = computed(() => posts.value.filter((post) => post.status === 'published').length)

async function loadPosts() {
  isLoading.value = true
  try {
    const response = await fetch(`${apiBaseUrl}/api/admin/community-posts`)
    const payload = (await response.json()) as { data: CommunityPost[] }
    posts.value = payload.data
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

async function submitPost(status: 'draft' | 'published') {
  if (!form.title || !form.content) return
  isSaving.value = true
  try {
    const response = await fetch(`${apiBaseUrl}/api/admin/community-posts`, {
      method: 'POST',
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
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
      }),
    })
    const payload = (await response.json()) as { data: CommunityPost }
    posts.value = [payload.data, ...posts.value]
    form.title = ''
    form.excerpt = ''
    form.content = ''
    published.value = status === 'published'
    window.setTimeout(() => {
      published.value = false
    }, 2400)
  } finally {
    isSaving.value = false
  }
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

watch(
  () => form.provinceCode,
  (provinceCode) => {
    void loadWards(provinceCode)
  },
)

onMounted(async () => {
  await Promise.all([loadPosts(), loadProvinces()])
  await loadWards(form.provinceCode)
})
</script>

<template>
  <div class="space-y-5">
    <section class="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
      <div>
        <p class="text-xs font-black uppercase tracking-[0.22em] text-[#E31837]">Truyền thông cộng đồng</p>
        <h2 class="mt-2 text-2xl font-black text-slate-950">Quản lý bài viết và đối tượng nhận tin</h2>
        <p class="mt-1 text-sm text-slate-500">Bài đã xuất bản sẽ xuất hiện trong mục Tin cộng đồng trên Mobile.</p>
      </div>
      <button class="inline-flex h-10 items-center gap-2 rounded-md border border-slate-200 px-4 text-xs font-black uppercase text-slate-600" @click="loadPosts">
        <RefreshCw class="h-4 w-4" />
        Làm mới
      </button>
    </section>

    <section class="grid gap-4 md:grid-cols-3">
      <article class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Tổng bài viết</p>
        <p class="mt-1 text-2xl font-black text-slate-950">{{ posts.length }}</p>
      </article>
      <article class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Đã xuất bản</p>
        <p class="mt-1 text-2xl font-black text-[#E31837]">{{ publishedPosts }}</p>
      </article>
      <article class="rounded-lg border border-slate-200 bg-white p-4 shadow-sm">
        <p class="text-xs font-black uppercase tracking-[0.16em] text-slate-400">Lượt xem</p>
        <p class="mt-1 text-2xl font-black text-slate-950">{{ totalViews }}</p>
      </article>
    </section>

    <section class="grid gap-5 xl:grid-cols-[1.2fr_0.8fr]">
      <form class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm" @submit.prevent="submitPost('published')">
        <div class="flex items-center justify-between border-b border-slate-100 pb-4">
          <h3 class="flex items-center gap-2 text-base font-black text-slate-950">
            <FileText class="h-5 w-5 text-[#E31837]" />
            Soạn bài viết mới
          </h3>
          <span v-if="published" class="rounded-full bg-emerald-50 px-3 py-1 text-xs font-black text-emerald-700">Đã xuất bản</span>
        </div>
        <div class="mt-4 grid gap-4">
          <input v-model="form.title" required class="rounded-md border border-slate-200 px-3 py-2 text-sm" placeholder="Tiêu đề bài viết" />
          <input v-model="form.excerpt" class="rounded-md border border-slate-200 px-3 py-2 text-sm" placeholder="Tóm tắt hiển thị trên Mobile" />
          <input v-model="form.imageUrl" class="rounded-md border border-slate-200 px-3 py-2 text-sm" placeholder="Ảnh đại diện" />
          <div class="grid gap-3 md:grid-cols-2">
            <select v-model="form.audienceType" class="rounded-md border border-slate-200 px-3 py-2 text-sm">
              <option value="all">Tất cả người dùng</option>
              <option value="blood_type">Theo nhóm máu</option>
              <option value="hero_level">Theo cấp Hero</option>
              <option value="province">Theo tỉnh/thành</option>
            </select>
            <select v-if="form.audienceType === 'blood_type'" v-model="form.targetBloodType" class="rounded-md border border-slate-200 px-3 py-2 text-sm">
              <option>O+</option>
              <option>O-</option>
              <option>A+</option>
              <option>A-</option>
              <option>B+</option>
              <option>B-</option>
              <option>AB+</option>
              <option>AB-</option>
            </select>
            <select v-else-if="form.audienceType === 'hero_level'" v-model="form.targetHeroLevel" class="rounded-md border border-slate-200 px-3 py-2 text-sm">
              <option value="Bronze Badge">Huy hiệu Đồng</option>
              <option value="Silver Badge">Huy hiệu Bạc</option>
              <option value="Gold Badge">Huy hiệu Vàng</option>
              <option value="Platinum Badge">Huy hiệu Bạch kim</option>
            </select>
            <select v-else-if="form.audienceType === 'province'" v-model="form.provinceCode" class="rounded-md border border-slate-200 px-3 py-2 text-sm">
              <option v-for="province in provinces" :key="province.code" :value="province.code">{{ province.full_name }}</option>
            </select>
            <input v-else disabled class="rounded-md border border-slate-100 bg-slate-50 px-3 py-2 text-sm text-slate-400" value="Không cần lọc thêm" />
          </div>
          <select v-if="form.audienceType === 'province'" v-model="form.wardCode" class="rounded-md border border-slate-200 px-3 py-2 text-sm">
            <option v-for="ward in wards" :key="ward.code" :value="ward.code">{{ ward.full_name }}</option>
          </select>
          <textarea v-model="form.content" required rows="10" class="rounded-md border border-slate-200 px-3 py-2 text-sm" placeholder="Nội dung truyền thông"></textarea>
        </div>
        <div class="mt-4 flex flex-wrap justify-end gap-3">
          <button type="button" class="rounded-md border border-slate-200 px-4 py-2 text-sm font-bold text-slate-700" @click="submitPost('draft')">Lưu nháp</button>
          <button type="submit" class="inline-flex items-center gap-2 rounded-md bg-[#E31837] px-4 py-2 text-sm font-black text-white">
            <Loader2 v-if="isSaving" class="h-4 w-4 animate-spin" />
            <Send v-else class="h-4 w-4" />
            Xuất bản ngay
          </button>
        </div>
      </form>

      <aside class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <div class="flex items-center justify-between border-b border-slate-100 pb-4">
          <h3 class="text-base font-black text-slate-950">Bài đã đăng</h3>
          <span class="text-xs font-black text-slate-400">{{ totalViews }} lượt xem</span>
        </div>
        <div v-if="isLoading" class="mt-4 flex items-center justify-center gap-2 rounded-md border border-dashed border-slate-200 p-6 text-sm font-bold text-slate-500">
          <Loader2 class="h-4 w-4 animate-spin" />
          Đang tải bài viết...
        </div>
        <div v-else class="mt-4 space-y-3">
          <article v-for="post in posts" :key="post.id" class="rounded-md border border-slate-100 bg-slate-50 p-3">
            <div class="flex items-center justify-between gap-3">
              <span class="font-mono text-[11px] font-bold text-slate-400">{{ post.slug }}</span>
              <span class="rounded-full px-2 py-0.5 text-[10px] font-black" :class="post.status === 'published' ? 'bg-emerald-50 text-emerald-700' : 'bg-amber-50 text-amber-700'">
                {{ post.status === 'published' ? 'Đã xuất bản' : 'Nháp' }}
              </span>
            </div>
            <h4 class="mt-2 text-sm font-black text-slate-950">{{ post.title }}</h4>
            <p class="mt-2 text-xs text-slate-500">{{ post.audience_label }} · {{ formattedDate(post.published_at) }}</p>
            <p class="mt-2 text-xs text-slate-400">{{ post.views_count }} lượt xem · {{ post.shares_count }} chia sẻ</p>
          </article>
        </div>
      </aside>
    </section>
  </div>
</template>
