<script setup lang="ts">
import { ref, onMounted, computed } from 'vue'
import { Plus, Trash2, Edit, Eye, HeartHandshake, AlertCircle, CheckCircle, XCircle } from '@lucide/vue'

const props = defineProps<{
  apiBaseUrl: string
}>()

interface Campaign {
  id: number
  public_id: string
  title: string
  description: string
  image_url: string | null
  type: 'financial' | 'points' | 'both'
  target_amount: number
  current_amount: number
  target_points: number
  current_points: number
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
const showModal = ref(false)
const showTxModal = ref(false)
const errorMsg = ref<string | null>(null)
const successMsg = ref<string | null>(null)

// Form fields
const editingCampaignId = ref<number | null>(null)
const formTitle = ref('')
const formDescription = ref('')
const formImageUrl = ref('')
const formType = ref<'financial' | 'points' | 'both'>('both')
const formTargetAmount = ref<number>(50000000)
const formTargetPoints = ref<number>(5000)
const formExpiresAt = ref('')
const formStatus = ref<'active' | 'completed' | 'cancelled'>('active')
// Empathy fields
const formBeneficiaryName = ref('')
const formBeneficiaryStory = ref('')
const formImpactUnit = ref('')
const formImpactPerUnitAmount = ref<number | null>(null)
const formImpactPerUnitPoints = ref<number | null>(null)
const formUrgencyLevel = ref<'' | 'normal' | 'urgent' | 'critical'>('')

// Transactions state
const activeCampaign = ref<Campaign | null>(null)
const transactions = ref<Transaction[]>([])
const isLoadingTx = ref(false)

const totalFinancialRaised = computed(() => {
  return campaigns.value.reduce((acc, c) => acc + c.current_amount, 0)
})

const totalPointsDonated = computed(() => {
  return campaigns.value.reduce((acc, c) => acc + c.current_points, 0)
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
  formType.value = 'both'
  formTargetAmount.value = 50000000
  formTargetPoints.value = 5000
  formExpiresAt.value = ''
  formStatus.value = 'active'
  formBeneficiaryName.value = ''
  formBeneficiaryStory.value = ''
  formImpactUnit.value = ''
  formImpactPerUnitAmount.value = null
  formImpactPerUnitPoints.value = null
  formUrgencyLevel.value = ''
  showModal.value = true
}

function openEditModal(campaign: Campaign) {
  editingCampaignId.value = campaign.id
  formTitle.value = campaign.title
  formDescription.value = campaign.description
  formImageUrl.value = campaign.image_url ?? ''
  formType.value = campaign.type
  formTargetAmount.value = campaign.target_amount
  formTargetPoints.value = campaign.target_points
  formStatus.value = campaign.status
  formExpiresAt.value = campaign.expires_at ? campaign.expires_at.split('T')[0] : ''
  formBeneficiaryName.value = campaign.beneficiary_name ?? ''
  formBeneficiaryStory.value = campaign.beneficiary_story ?? ''
  formImpactUnit.value = campaign.impact_unit ?? ''
  formImpactPerUnitAmount.value = campaign.impact_per_unit_amount
  formImpactPerUnitPoints.value = campaign.impact_per_unit_points
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
    type: formType.value,
    target_amount: formType.value !== 'points' ? formTargetAmount.value : 0,
    target_points: formType.value !== 'financial' ? formTargetPoints.value : 0,
    expires_at: formExpiresAt.value || null,
    status: formStatus.value,
    beneficiary_name: formBeneficiaryName.value || null,
    beneficiary_story: formBeneficiaryStory.value || null,
    impact_unit: formImpactUnit.value || null,
    impact_per_unit_amount:
      formType.value !== 'points' ? formImpactPerUnitAmount.value : null,
    impact_per_unit_points:
      formType.value !== 'financial' ? formImpactPerUnitPoints.value : null,
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
        <h1 class="text-2xl font-black tracking-wide text-neutral-100 flex items-center gap-2">
          <HeartHandshake class="h-7 w-7 text-[#E31837]" />
          QUẢN LÝ QUYÊN GÓP
        </h1>
        <p class="text-sm text-neutral-400">Quản lý quỹ tài chính SOS và tích lũy đổi quà điểm Hero.</p>
      </div>
      <button
        @click="openCreateModal"
        class="flex items-center gap-1.5 rounded-xl bg-[#E31837] px-4 py-2.5 text-sm font-bold text-white hover:bg-[#E31837]/90 transition"
      >
        <Plus class="h-4 w-4" />
        TẠO CHIẾN DỊCH
      </button>
    </div>

    <!-- Feedback alerts -->
    <div v-if="errorMsg" class="flex items-center gap-2 rounded-xl bg-red-950/40 border border-red-500/20 p-4 text-red-400 text-sm">
      <AlertCircle class="h-4 w-4 shrink-0" />
      {{ errorMsg }}
    </div>
    <div v-if="successMsg" class="flex items-center gap-2 rounded-xl bg-green-950/40 border border-green-500/20 p-4 text-green-400 text-sm">
      <CheckCircle class="h-4 w-4 shrink-0" />
      {{ successMsg }}
    </div>

    <!-- Stats grid -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="rounded-2xl border border-neutral-800 bg-neutral-900/50 p-6">
        <div class="text-xs font-bold text-neutral-400 uppercase tracking-wider">Tổng số chiến dịch</div>
        <div class="mt-2 text-3xl font-black text-white">{{ campaigns.length }}</div>
      </div>
      <div class="rounded-2xl border border-neutral-800 bg-neutral-900/50 p-6">
        <div class="text-xs font-bold text-neutral-400 uppercase tracking-wider">Quỹ tài chính thu nhận</div>
        <div class="mt-2 text-3xl font-black text-emerald-400">{{ formatCurrency(totalFinancialRaised) }}</div>
      </div>
      <div class="rounded-2xl border border-neutral-800 bg-neutral-900/50 p-6">
        <div class="text-xs font-bold text-neutral-400 uppercase tracking-wider">Quỹ điểm Hero đóng góp</div>
        <div class="mt-2 text-3xl font-black text-rose-400">{{ totalPointsDonated }} Pts</div>
      </div>
    </div>

    <!-- Campaign list table -->
    <div class="overflow-x-auto rounded-2xl border border-neutral-800 bg-neutral-900/20">
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="border-b border-neutral-800 text-[11px] font-black uppercase tracking-wider text-neutral-400">
            <th class="p-4">Tên chiến dịch</th>
            <th class="p-4">Hình thức</th>
            <th class="p-4">Tài chính (VND)</th>
            <th class="p-4">Điểm Hero</th>
            <th class="p-4">Thời hạn</th>
            <th class="p-4">Trạng thái</th>
            <th class="p-4 text-right">Hành động</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-neutral-800/40 text-sm text-neutral-200">
          <tr v-for="c in campaigns" :key="c.id" class="hover:bg-white/[0.02] transition">
            <td class="p-4 font-bold">
              <div>{{ c.title }}</div>
              <div class="text-[11px] text-neutral-400 font-normal line-clamp-1 mt-1">{{ c.description }}</div>
            </td>
            <td class="p-4">
              <span v-if="c.type === 'financial'" class="rounded bg-emerald-950 text-emerald-400 text-xs px-2 py-0.5 font-bold">TIỀN MẶT</span>
              <span v-else-if="c.type === 'points'" class="rounded bg-rose-950 text-rose-400 text-xs px-2 py-0.5 font-bold">ĐIỂM HERO</span>
              <span v-else class="rounded bg-neutral-800 text-neutral-300 text-xs px-2 py-0.5 font-bold">CẢ HAI</span>
            </td>
            <td class="p-4">
              <div v-if="c.type !== 'points'">
                <div class="font-bold text-emerald-400">{{ formatCurrency(c.current_amount) }}</div>
                <div class="text-[11px] text-neutral-400 mt-0.5">Mục tiêu: {{ formatCurrency(c.target_amount) }}</div>
              </div>
              <span v-else class="text-neutral-500">-</span>
            </td>
            <td class="p-4">
              <div v-if="c.type !== 'financial'">
                <div class="font-bold text-rose-400">{{ c.current_points }} Pts</div>
                <div class="text-[11px] text-neutral-400 mt-0.5">Mục tiêu: {{ c.target_points }} Pts</div>
              </div>
              <span v-else class="text-neutral-500">-</span>
            </td>
            <td class="p-4 text-neutral-400">{{ formatDate(c.expires_at) }}</td>
            <td class="p-4">
              <span v-if="c.status === 'active'" class="rounded bg-green-500/10 text-green-400 text-xs px-2.5 py-1 font-bold">ĐANG DIỄN RA</span>
              <span v-else-if="c.status === 'completed'" class="rounded bg-blue-500/10 text-blue-400 text-xs px-2.5 py-1 font-bold">HOÀN THÀNH</span>
              <span v-else class="rounded bg-neutral-800 text-neutral-400 text-xs px-2.5 py-1 font-bold">ĐÃ HỦY</span>
            </td>
            <td class="p-4 text-right space-x-2">
              <button @click="viewTransactions(c)" title="Lịch sử giao dịch" class="p-2 rounded bg-neutral-800 hover:bg-neutral-700 transition text-neutral-300">
                <Eye class="h-4 w-4" />
              </button>
              <button @click="openEditModal(c)" title="Sửa" class="p-2 rounded bg-neutral-800 hover:bg-neutral-700 transition text-yellow-500">
                <Edit class="h-4 w-4" />
              </button>
              <button @click="deleteCampaign(c)" title="Xóa" class="p-2 rounded bg-neutral-800 hover:bg-neutral-700 transition text-red-500">
                <Trash2 class="h-4 w-4" />
              </button>
            </td>
          </tr>
          <tr v-if="campaigns.length === 0">
            <td colspan="7" class="p-8 text-center text-neutral-400">
              Không tìm thấy chiến dịch quyên góp nào.
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- Add/Edit Campaign Modal -->
    <div v-if="showModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div class="w-full max-w-lg rounded-2xl border border-neutral-800 bg-neutral-950 p-6 shadow-xl">
        <h3 class="text-lg font-black text-white uppercase tracking-wide">
          {{ editingCampaignId ? 'CẬP NHẬT CHIẾN DỊCH' : 'TẠO CHIẾN DỊCH MỚI' }}
        </h3>
        <form @submit.prevent="submitForm" class="mt-4 space-y-4">
          <div>
            <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Tiêu đề chiến dịch</label>
            <input v-model="formTitle" type="text" required class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]" placeholder="Ví dụ: Hỗ trợ viện phí ca SOS em bé A" />
          </div>

          <div>
            <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Mô tả dự án</label>
            <textarea v-model="formDescription" required rows="3" class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]" placeholder="Nhập câu chuyện dự án, các mục đích sử dụng quỹ..."></textarea>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Hình thức</label>
              <select v-model="formType" class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]">
                <option value="both">Cả hai (Tiền & Điểm)</option>
                <option value="financial">Quyên góp tiền mặt</option>
                <option value="points">Quyên góp điểm Hero</option>
              </select>
            </div>
            <div>
              <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Thời hạn đóng</label>
              <input v-model="formExpiresAt" type="date" class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]" />
            </div>
          </div>

          <div class="grid grid-cols-2 gap-4">
            <div v-if="formType !== 'points'">
              <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Mục tiêu tiền (VND)</label>
              <input v-model.number="formTargetAmount" type="number" min="0" required class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]" />
            </div>
            <div v-if="formType !== 'financial'">
              <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Mục tiêu điểm Hero</label>
              <input v-model.number="formTargetPoints" type="number" min="0" required class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]" />
            </div>
          </div>

          <div>
            <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Link ảnh đại diện (URL)</label>
            <input v-model="formImageUrl" type="url" class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]" placeholder="https://images.unsplash.com/..." />
          </div>

          <!-- Empathy section: nội dung giúp người quyên góp thấu cảm với hoàn cảnh -->
          <div class="rounded-xl border border-[#E31837]/20 bg-[#E31837]/[0.03] p-4 space-y-4">
            <div class="flex items-center gap-2 text-[#E31837]">
              <HeartHandshake class="h-4 w-4" />
              <span class="text-xs font-black uppercase tracking-wide">Nội dung thấu cảm</span>
            </div>
            <p class="text-[11px] text-neutral-500 -mt-2">
              Giúp người quyên góp hình dung mình đang giúp ai, và mỗi đóng góp tạo ra tác động gì. Bỏ trống nếu chưa có.
            </p>

            <div>
              <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Người / cộng đồng thụ hưởng</label>
              <input v-model="formBeneficiaryName" type="text" class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]" placeholder="Ví dụ: Bé Gia Bảo, 6 tuổi / Điểm trường Lũng Cú" />
            </div>

            <div>
              <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Câu chuyện hoàn cảnh</label>
              <textarea v-model="formBeneficiaryStory" rows="4" class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]" placeholder="Kể câu chuyện thật, gần gũi về người thụ hưởng để chạm tới cảm xúc người đọc..."></textarea>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div>
                <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Đơn vị tác động</label>
                <input v-model="formImpactUnit" type="text" class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]" placeholder="Ví dụ: phần cơm, đơn vị máu, bộ sơ cứu" />
              </div>
              <div>
                <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Mức độ cấp thiết</label>
                <select v-model="formUrgencyLevel" class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]">
                  <option value="">Không hiển thị</option>
                  <option value="normal">Đang kêu gọi</option>
                  <option value="urgent">Cần gấp</option>
                  <option value="critical">Rất cấp thiết</option>
                </select>
              </div>
            </div>

            <div class="grid grid-cols-2 gap-4">
              <div v-if="formType !== 'points'">
                <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">VND cho 1 đơn vị tác động</label>
                <input v-model.number="formImpactPerUnitAmount" type="number" min="0" class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]" placeholder="Ví dụ: 35000" />
              </div>
              <div v-if="formType !== 'financial'">
                <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Điểm Hero cho 1 đơn vị</label>
                <input v-model.number="formImpactPerUnitPoints" type="number" min="0" class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]" placeholder="Ví dụ: 50" />
              </div>
            </div>
          </div>

          <div v-if="editingCampaignId">
            <label class="block text-xs font-bold text-neutral-400 uppercase mb-1">Trạng thái</label>
            <select v-model="formStatus" class="w-full rounded-xl border border-neutral-800 bg-neutral-900 px-4 py-2.5 text-sm text-white focus:outline-none focus:border-[#E31837]">
              <option value="active">Đang diễn ra</option>
              <option value="completed">Hoàn thành</option>
              <option value="cancelled">Hủy bỏ</option>
            </select>
          </div>

          <div class="flex justify-end gap-2 pt-4 border-t border-neutral-850">
            <button type="button" @click="showModal = false" class="rounded-xl border border-neutral-800 px-4 py-2 text-sm text-neutral-400 hover:bg-neutral-900">Hủy</button>
            <button type="submit" class="rounded-xl bg-[#E31837] px-5 py-2 text-sm font-bold text-white hover:bg-[#E31837]/90 transition">Xác nhận</button>
          </div>
        </form>
      </div>
    </div>

    <!-- View Transactions Modal -->
    <div v-if="showTxModal" class="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-sm p-4">
      <div class="w-full max-w-3xl rounded-2xl border border-neutral-800 bg-neutral-950 p-6 shadow-xl flex flex-col max-h-[85vh]">
        <div class="flex items-center justify-between border-b border-neutral-800 pb-4">
          <h3 class="text-base font-black text-white uppercase tracking-wide">
            Lịch sử quyên góp: {{ activeCampaign?.title }}
          </h3>
          <button @click="showTxModal = false" class="text-neutral-400 hover:text-white">&times; Đóng</button>
        </div>

        <div class="flex-1 overflow-y-auto mt-4 space-y-4">
          <div v-if="isLoadingTx" class="text-center py-8 text-neutral-400">Đang tải lịch sử giao dịch...</div>
          <div v-else class="overflow-x-auto">
            <table class="w-full text-left text-sm border-collapse">
              <thead>
                <tr class="border-b border-neutral-800 text-[10px] font-black uppercase tracking-wider text-neutral-400">
                  <th class="pb-2">Người ủng hộ</th>
                  <th class="pb-2">Đóng góp</th>
                  <th class="pb-2">Phương thức</th>
                  <th class="pb-2">Mã giao dịch</th>
                  <th class="pb-2">Trạng thái</th>
                  <th class="pb-2">Thời gian</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-neutral-850 text-neutral-200">
                <tr v-for="t in transactions" :key="t.id" class="hover:bg-white/[0.01]">
                  <td class="py-2.5">
                    <div class="font-bold">{{ t.donor_name }}</div>
                    <div class="text-[10px] text-neutral-500 italic mt-0.5">{{ t.message || 'Không có lời chúc.' }}</div>
                  </td>
                  <td class="py-2.5 font-bold">
                    <span v-if="t.amount > 0" class="text-emerald-400">+{{ formatCurrency(t.amount) }}</span>
                    <span v-else class="text-rose-400">+{{ t.points }} Pts</span>
                  </td>
                  <td class="py-2.5 uppercase text-xs text-neutral-400">{{ t.payment_method }}</td>
                  <td class="py-2.5 font-mono text-xs">{{ t.transaction_id }}</td>
                  <td class="py-2.5">
                    <span v-if="t.payment_status === 'success'" class="text-emerald-400 text-xs font-bold flex items-center gap-1">
                      <CheckCircle class="h-3 w-3" /> THÀNH CÔNG
                    </span>
                    <span v-else-if="t.payment_status === 'failed'" class="text-red-400 text-xs font-bold flex items-center gap-1">
                      <XCircle class="h-3 w-3" /> THẤT BẠI
                    </span>
                    <span v-else class="text-yellow-500 text-xs font-bold">PENDING</span>
                  </td>
                  <td class="py-2.5 text-xs text-neutral-400">{{ new Date(t.created_at).toLocaleString('vi-VN') }}</td>
                </tr>
                <tr v-if="transactions.length === 0">
                  <td colspan="6" class="py-6 text-center text-neutral-400">
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
