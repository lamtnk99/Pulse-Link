<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { Plus, Trash2, Edit, Eye, HeartHandshake, AlertCircle, CheckCircle, XCircle, ImagePlus, Loader2 } from '@lucide/vue'

const props = defineProps<{
  apiBaseUrl: string
}>()

interface Campaign {
  id: number
  public_id: string
  title: string
  description: string
  image_url: string | null
  target_amount: number
  current_amount: number
  status: 'active' | 'completed' | 'cancelled'
  beneficiary_name: string | null
  beneficiary_story: string | null
  impact_unit: string | null
  impact_per_unit_amount: number | null
  impact_per_unit_points: number | null
  urgency_level: 'normal' | 'urgent' | 'critical' | null
  expires_at: string | null
  total_donors: number
  created_at: string
}

interface Transaction {
  id: number
  amount: number
  points: number
  payment_method: string
  payment_status: 'pending' | 'success' | 'failed'
  transaction_id: string
  donor_name: string
  message: string | null
  is_anonymous: boolean
  created_at: string
}

const campaigns = ref<Campaign[]>([])
const isLoading = ref(false)
const isUploading = ref(false)
const showModal = ref(false)
const showTxModal = ref(false)
const errorMsg = ref<string | null>(null)
const successMsg = ref<string | null>(null)

// Form fields
const editingCampaignId = ref<number | null>(null)
const formTitle = ref('')
const formDescription = ref('')
const formImageUrl = ref('')
const formTargetAmount = ref<number>(50000000)
const formExpiresAt = ref('')
const formStatus = ref<'active' | 'completed' | 'cancelled'>('active')
// Empathy fields
const formBeneficiaryName = ref('')
const formBeneficiaryStory = ref('')
const formImpactUnit = ref('')
const formImpactPerUnitAmount = ref<number | null>(null)
const formUrgencyLevel = ref<'' | 'normal' | 'urgent' | 'critical'>('')

// Transactions state
const activeCampaign = ref<Campaign | null>(null)
const transactions = ref<Transaction[]>([])
const isLoadingTx = ref(false)

const totalFinancialRaised = computed(() => {
  return campaigns.value.reduce((acc, c) => acc + c.current_amount, 0)
})

const activeCampaignsCount = computed(() => {
  return campaigns.value.filter((c) => c.status === 'active').length
})

async function fetchCampaigns() {
  isLoading.value = true
  try {
    const res = await fetch(`${props.apiBaseUrl}/api/admin/campaigns`)
    if (!res.ok) throw new Error('Không thể tải danh sách chiến dịch.')
    const payload = await res.json()
    campaigns.value = payload.data
  } catch (e: any) {
    errorMsg.value = e.message
  } finally {
    isLoading.value = false
  }
}

async function viewTransactions(campaign: Campaign) {
  activeCampaign.value = campaign
  showTxModal.value = true
  isLoadingTx.value = true
  try {
    const res = await fetch(`${props.apiBaseUrl}/api/admin/campaigns/${campaign.id}/transactions`)
    if (!res.ok) throw new Error('Không thể tải lịch sử quyên góp.')
    const payload = await res.json()
    transactions.value = payload.data
  } catch (e: any) {
    alert(e.message)
  } finally {
    isLoadingTx.value = false
  }
}

function openCreateModal() {
  editingCampaignId.value = null
  formTitle.value = ''
  formDescription.value = ''
  formImageUrl.value = ''
  formTargetAmount.value = 50000000
  formExpiresAt.value = ''
  formStatus.value = 'active'
  formBeneficiaryName.value = ''
  formBeneficiaryStory.value = ''
  formImpactUnit.value = ''
  formImpactPerUnitAmount.value = null
  formUrgencyLevel.value = ''
  showModal.value = true
}

function openEditModal(campaign: Campaign) {
  editingCampaignId.value = campaign.id
  formTitle.value = campaign.title
  formDescription.value = campaign.description
  formImageUrl.value = campaign.image_url ?? ''
  formTargetAmount.value = campaign.target_amount
  formStatus.value = campaign.status
  formExpiresAt.value = campaign.expires_at ? campaign.expires_at.split('T')[0] : ''
  formBeneficiaryName.value = campaign.beneficiary_name ?? ''
  formBeneficiaryStory.value = campaign.beneficiary_story ?? ''
  formImpactUnit.value = campaign.impact_unit ?? ''
  formImpactPerUnitAmount.value = campaign.impact_per_unit_amount
  formUrgencyLevel.value = campaign.urgency_level ?? ''
  showModal.value = true
}

async function submitForm() {
  errorMsg.value = null
  successMsg.value = null
  const body = {
    title: formTitle.value,
    description: formDescription.value,
    image_url: formImageUrl.value || null,
    target_amount: formTargetAmount.value,
    expires_at: formExpiresAt.value || null,
    status: formStatus.value,
    beneficiary_name: formBeneficiaryName.value || null,
    beneficiary_story: formBeneficiaryStory.value || null,
    impact_unit: formImpactUnit.value || null,
    impact_per_unit_amount: formImpactPerUnitAmount.value,
    urgency_level: formUrgencyLevel.value || null,
  }

  const isEdit = editingCampaignId.value !== null
  const url = isEdit
    ? `${props.apiBaseUrl}/api/admin/campaigns/${editingCampaignId.value}`
    : `${props.apiBaseUrl}/api/admin/campaigns`
  const method = isEdit ? 'PUT' : 'POST'

  try {
    const res = await fetch(url, {
      method,
      headers: {
        Accept: 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(body),
    })
    const payload = await res.json()
    if (!res.ok) throw new Error(payload.message || 'Đã có lỗi xảy ra.')
    
    successMsg.value = isEdit ? 'Cập nhật chiến dịch thành công!' : 'Tạo chiến dịch quyên góp thành công!'
    showModal.value = false
    await fetchCampaigns()
  } catch (e: any) {
    errorMsg.value = e.message
  }
}

async function uploadImage(event: Event) {
  const input = event.target as HTMLInputElement
  const file = input.files?.[0]
  if (!file) return

  isUploading.value = true
  errorMsg.value = null
  try {
    const fd = new FormData()
    fd.append('file', file)

    const res = await fetch(`${props.apiBaseUrl}/api/admin/uploads`, {
      method: 'POST',
      headers: { Accept: 'application/json' },
      body: fd,
    })
    const payload = await res.json()
    if (!res.ok) throw new Error(payload.message || 'Không thể tải ảnh lên.')
    formImageUrl.value = payload.data.url
  } catch (e: any) {
    errorMsg.value = e.message
  } finally {
    isUploading.value = false
    input.value = ''
  }
}

async function deleteCampaign(campaign: Campaign) {
  if (!confirm(`Bạn có chắc chắn muốn xóa chiến dịch "${campaign.title}" không?`)) return
  try {
    const res = await fetch(`${props.apiBaseUrl}/api/admin/campaigns/${campaign.id}`, {
      method: 'DELETE',
    })
    if (!res.ok) throw new Error('Không thể xóa chiến dịch.')
    await fetchCampaigns()
  } catch (e: any) {
    alert(e.message)
  }
}

function formatCurrency(val: number) {
  return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val)
}

function formatDate(dateStr: string | null) {
  if (!dateStr) return '-'
  return new Date(dateStr).toLocaleDateString('vi-VN')
}

onMounted(() => {
  fetchCampaigns()
})
</script>

<template>
  <div class="space-y-6">
    <!-- Header -->
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-2xl font-black tracking-wide text-slate-900 flex items-center gap-2">
          <HeartHandshake class="h-7 w-7 text-[#E31837]" />
          QUẢN LÝ QUYÊN GÓP
        </h1>
        <p class="text-sm text-slate-500">Quản lý các quỹ quyên góp. Người dùng có thể góp bằng tiền mặt hoặc điểm Hero (quy đổi 1 điểm = 250đ).</p>
      </div>
      <button
        @click="openCreateModal"
        class="flex items-center gap-1.5 rounded-xl bg-[#E31837] px-4 py-2.5 text-sm font-bold text-white hover:bg-[#E31837]/90 transition shadow-sm"
      >
        <Plus class="h-4 w-4" />
        TẠO CHIẾN DỊCH
      </button>
    </div>

    <!-- Feedback alerts -->
    <div v-if="errorMsg" class="flex items-center gap-2 rounded-xl bg-red-50 border border-red-200 p-4 text-red-600 text-sm">
      <AlertCircle class="h-4 w-4 shrink-0" />
      {{ errorMsg }}
    </div>
    <div v-if="successMsg" class="flex items-center gap-2 rounded-xl bg-green-50 border border-green-200 p-4 text-green-600 text-sm">
      <CheckCircle class="h-4 w-4 shrink-0" />
      {{ successMsg }}
    </div>

    <!-- Stats grid -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="text-xs font-bold text-slate-400 uppercase tracking-wider">Tổng số chiến dịch</div>
        <div class="mt-2 text-3xl font-black text-slate-900">{{ campaigns.length }}</div>
      </div>
      <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="text-xs font-bold text-slate-400 uppercase tracking-wider">Quỹ tài chính thu nhận</div>
        <div class="mt-2 text-3xl font-black text-emerald-600">{{ formatCurrency(totalFinancialRaised) }}</div>
      </div>
      <div class="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <div class="text-xs font-bold text-slate-400 uppercase tracking-wider">Chiến dịch đang diễn ra</div>
        <div class="mt-2 text-3xl font-black text-rose-600">{{ activeCampaignsCount }}</div>
      </div>
    </div>

    <!-- Campaign list table -->
    <div class="overflow-x-auto rounded-2xl border border-slate-200 bg-white shadow-sm">
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="border-b border-slate-200 bg-slate-50 text-[11px] font-black uppercase tracking-wider text-slate-500">
            <th class="p-4">Tên chiến dịch</th>
            <th class="p-4">Quỹ quyên góp (VND)</th>
            <th class="p-4">Thời hạn</th>
            <th class="p-4">Trạng thái</th>
            <th class="p-4 text-right">Hành động</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-slate-100 text-sm text-slate-700 bg-white">
          <tr v-for="c in campaigns" :key="c.id" class="hover:bg-slate-50/50 transition">
            <td class="p-4 font-bold text-slate-900">
              <div>{{ c.title }}</div>
              <div class="text-[11px] text-slate-500 font-normal line-clamp-1 mt-1">{{ c.description }}</div>
            </td>
            <td class="p-4">
              <div class="font-bold text-emerald-600">{{ formatCurrency(c.current_amount) }}</div>
              <div class="text-[11px] text-slate-500 mt-0.5">Mục tiêu: {{ formatCurrency(c.target_amount) }}</div>
            </td>
            <td class="p-4 text-slate-500">{{ formatDate(c.expires_at) }}</td>
            <td class="p-4">
              <span v-if="c.status === 'active'" class="rounded bg-green-50 text-green-600 text-xs px-2.5 py-1 font-bold whitespace-nowrap">ĐANG DIỄN RA</span>
              <span v-else-if="c.status === 'completed'" class="rounded bg-blue-50 text-blue-600 text-xs px-2.5 py-1 font-bold whitespace-nowrap">HOÀN THÀNH</span>
              <span v-else class="rounded bg-slate-100 text-slate-500 text-xs px-2.5 py-1 font-bold whitespace-nowrap">ĐÃ HỦY</span>
            </td>
            <td class="p-4 text-right space-x-2 whitespace-nowrap">
              <button @click="viewTransactions(c)" title="Lịch sử giao dịch" class="p-2 rounded-lg border border-slate-200 bg-white hover:bg-slate-50 transition text-slate-600 hover:text-slate-900 shadow-sm">
                <Eye class="h-4 w-4" />
              </button>
              <button @click="openEditModal(c)" title="Sửa" class="p-2 rounded-lg border border-amber-200 bg-amber-50 hover:bg-amber-100 transition text-amber-600 hover:text-amber-800 shadow-sm">
                <Edit class="h-4 w-4" />
              </button>
              <button @click="deleteCampaign(c)" title="Xóa" class="p-2 rounded-lg border border-red-200 bg-red-50 hover:bg-red-100 transition text-red-600 hover:text-red-800 shadow-sm">
                <Trash2 class="h-4 w-4" />
              </button>
            </td>
          </tr>
          <tr v-if="campaigns.length === 0">
            <td colspan="5" class="p-8 text-center text-slate-400 font-bold">
              Không tìm thấy chiến dịch quyên góp nào.
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Add/Edit Campaign Modal -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <form @submit.prevent="submitForm" class="flex w-full max-w-lg flex-col rounded-2xl border border-slate-200 bg-white shadow-2xl max-h-[90vh]">
        <div class="px-6 pt-6 pb-4 border-b border-slate-100">
          <h3 class="text-lg font-black text-slate-900 uppercase tracking-wide">
            {{ editingCampaignId ? 'CẬP NHẬT CHIẾN DỊCH' : 'TẠO CHIẾN DỊCH MỚI' }}
          </h3>
        </div>
        <div class="flex-1 overflow-y-auto px-6 py-4 space-y-4">
          <div>
            <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Tiêu đề chiến dịch</label>
            <input v-model="formTitle" type="text" required class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-[#E31837] focus:ring-2 focus:ring-red-50" placeholder="Ví dụ: Hỗ trợ viện phí ca SOS em bé A" />
          </div>

          <div>
            <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Mô tả dự án</label>
            <textarea v-model="formDescription" required rows="3" class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-[#E31837] focus:ring-2 focus:ring-red-50" placeholder="Nhập câu chuyện dự án, các mục đích sử dụng quỹ..."></textarea>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Mục tiêu quỹ (VND)</label>
              <input v-model.number="formTargetAmount" type="number" min="0" required class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-[#E31837] focus:ring-2 focus:ring-red-50" />
            </div>
            <div>
              <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Thời hạn đóng</label>
              <input v-model="formExpiresAt" type="date" class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-[#E31837] focus:ring-2 focus:ring-red-50" />
            </div>
          </div>
          <p class="text-[11px] text-slate-500 -mt-1">
            Người dùng có thể góp bằng tiền mặt hoặc điểm Hero — điểm sẽ tự quy đổi ra VND (1 điểm = 250đ) và cộng vào cùng quỹ này.
          </p>

          <div>
            <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Ảnh đại diện</label>
            <div class="grid gap-3 sm:grid-cols-[180px_1fr]">
              <div class="overflow-hidden rounded-xl border border-slate-200 bg-slate-50">
                <img v-if="formImageUrl" :src="formImageUrl" alt="Ảnh chiến dịch" class="h-28 w-full object-cover" />
                <div v-else class="grid h-28 place-items-center text-xs font-bold text-slate-400">Chưa có ảnh</div>
              </div>
              <div class="grid content-start gap-2">
                <label class="flex h-11 cursor-pointer items-center justify-center gap-2 rounded-xl border border-dashed border-slate-300 bg-slate-50 text-sm font-bold text-slate-600 hover:bg-slate-100">
                  <Loader2 v-if="isUploading" class="h-4 w-4 animate-spin" />
                  <ImagePlus v-else class="h-4 w-4" />
                  {{ isUploading ? 'Đang tải ảnh...' : 'Tải ảnh từ máy (jpg, png, webp)' }}
                  <input type="file" accept="image/jpeg,image/png,image/webp" class="hidden" :disabled="isUploading" @change="uploadImage" />
                </label>
                <input v-model="formImageUrl" type="url" class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-[#E31837] focus:ring-2 focus:ring-red-50" placeholder="Hoặc nhập URL ảnh thủ công https://..." />
              </div>
            </div>
          </div>

          <!-- Empathy section -->
          <div class="rounded-xl border border-[#E31837]/20 bg-[#E31837]/[0.02] p-4 space-y-4">
            <div class="flex items-center gap-2 text-[#E31837]">
              <HeartHandshake class="h-4 w-4" />
              <span class="text-xs font-black uppercase tracking-wide">Câu chuyện hoàn cảnh</span>
            </div>
            <p class="text-[11px] text-slate-500 -mt-2">
              Cho người quyên góp biết họ đang giúp ai và mỗi khoản đóng góp dùng vào việc gì. Có thể bỏ trống.
            </p>

            <div>
              <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Người / cộng đồng thụ hưởng</label>
              <input v-model="formBeneficiaryName" type="text" class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-[#E31837] focus:ring-2 focus:ring-red-50" placeholder="Ví dụ: Bé Gia Bảo, 6 tuổi / Điểm trường Lũng Cú" />
            </div>

            <div>
              <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Câu chuyện hoàn cảnh</label>
              <textarea v-model="formBeneficiaryStory" rows="4" class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-[#E31837] focus:ring-2 focus:ring-red-50" placeholder="Kể hoàn cảnh thật của người thụ hưởng: họ là ai, đang gặp khó khăn gì..."></textarea>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Đơn vị tác động</label>
                <input v-model="formImpactUnit" type="text" class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-[#E31837] focus:ring-2 focus:ring-red-50" placeholder="Ví dụ: phần cơm, đơn vị máu, bộ sơ cứu" />
              </div>
              <div>
                <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Mức độ cấp thiết</label>
                <select v-model="formUrgencyLevel" class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-[#E31837] focus:ring-2 focus:ring-red-50">
                  <option value="">Không hiển thị</option>
                  <option value="normal">Đang kêu gọi</option>
                  <option value="urgent">Cần gấp</option>
                  <option value="critical">Rất cấp thiết</option>
                </select>
              </div>
            </div>

            <div>
              <label class="block text-xs font-bold text-slate-500 uppercase mb-1">VND cho 1 đơn vị tác động</label>
              <input v-model.number="formImpactPerUnitAmount" type="number" min="0" class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-[#E31837] focus:ring-2 focus:ring-red-50" placeholder="Ví dụ: 35000" />
              <p class="text-[11px] text-slate-400 mt-1">Số tiền để tạo ra một đơn vị tác động, dùng hiển thị "≈ N {{ formImpactUnit || 'đơn vị' }}" cho người quyên góp.</p>
            </div>
          </div>

          <div v-if="editingCampaignId">
            <label class="block text-xs font-bold text-slate-500 uppercase mb-1">Trạng thái</label>
            <select v-model="formStatus" class="w-full rounded-xl border border-slate-200 bg-white px-4 py-2.5 text-sm text-slate-900 focus:outline-none focus:border-[#E31837] focus:ring-2 focus:ring-red-50">
              <option value="active">Đang diễn ra</option>
              <option value="completed">Hoàn thành</option>
              <option value="cancelled">Hủy bỏ</option>
            </select>
          </div>

        </div>
        <div class="flex justify-end gap-2 px-6 py-4 border-t border-slate-100">
          <button type="button" @click="showModal = false" class="rounded-xl border border-slate-200 px-4 py-2 text-sm text-slate-500 hover:bg-slate-50">Hủy</button>
          <button type="submit" class="rounded-xl bg-[#E31837] px-5 py-2 text-sm font-bold text-white hover:bg-[#E31837]/90 transition">Xác nhận</button>
        </div>
      </form>
    </div>

    <!-- View Transactions Modal -->
    <div v-if="showTxModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm p-4">
      <div class="w-full max-w-3xl rounded-2xl border border-slate-200 bg-white p-6 shadow-2xl flex flex-col max-h-[85vh]">
        <div class="flex items-center justify-between border-b border-slate-100 pb-4">
          <h3 class="text-base font-black text-slate-900 uppercase tracking-wide">
            Lịch sử quyên góp: {{ activeCampaign?.title }}
          </h3>
          <button @click="showTxModal = false" class="text-slate-500 hover:text-slate-800 font-bold">&times; Đóng</button>
        </div>

        <div class="flex-1 overflow-y-auto mt-4 space-y-4">
          <div v-if="isLoadingTx" class="text-center py-8 text-slate-400 font-bold">Đang tải lịch sử giao dịch...</div>
          <div v-else class="overflow-x-auto">
            <table class="w-full text-left text-sm border-collapse">
              <thead>
                <tr class="border-b border-slate-200 text-[10px] font-black uppercase tracking-wider text-slate-500">
                  <th class="pb-2">Người ủng hộ</th>
                  <th class="pb-2">Đóng góp</th>
                  <th class="pb-2">Phương thức</th>
                  <th class="pb-2">Mã giao dịch</th>
                  <th class="pb-2">Trạng thái</th>
                  <th class="pb-2">Thời gian</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-slate-100 text-slate-700 bg-white">
                <tr v-for="t in transactions" :key="t.id" class="hover:bg-slate-50/50">
                  <td class="py-2.5">
                    <div class="font-bold text-slate-900">{{ t.donor_name }}</div>
                    <div class="text-[10px] text-slate-400 italic mt-0.5">{{ t.message || 'Không có lời chúc.' }}</div>
                  </td>
                  <td class="py-2.5 font-bold">
                    <span v-if="t.amount > 0" class="text-emerald-600">+{{ formatCurrency(t.amount) }}</span>
                    <span v-else class="text-rose-600">+{{ t.points }} Pts</span>
                  </td>
                  <td class="py-2.5 uppercase text-xs text-slate-500">{{ t.payment_method }}</td>
                  <td class="py-2.5 font-mono text-xs text-slate-600">{{ t.transaction_id }}</td>
                  <td class="py-2.5">
                    <span v-if="t.payment_status === 'success'" class="text-emerald-600 text-xs font-bold flex items-center gap-1">
                      <CheckCircle class="h-3 w-3" /> THÀNH CÔNG
                    </span>
                    <span v-else-if="t.payment_status === 'failed'" class="text-red-600 text-xs font-bold flex items-center gap-1">
                      <XCircle class="h-3 w-3" /> THẤT BẠI
                    </span>
                    <span v-else class="text-yellow-600 text-xs font-bold">PENDING</span>
                  </td>
                  <td class="py-2.5 text-xs text-slate-500">{{ new Date(t.created_at).toLocaleString('vi-VN') }}</td>
                </tr>
                <tr v-if="transactions.length === 0">
                  <td colspan="6" class="py-6 text-center text-slate-400 font-bold">
                    Chưa có lượt ủng hộ nào cho chiến dịch này.
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>
