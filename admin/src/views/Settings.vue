<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { Cpu, Save, RefreshCw, AlertCircle, CheckCircle2, Sliders } from '@lucide/vue'

const props = defineProps<{
  apiBaseUrl?: string
}>()

const apiBase = props.apiBaseUrl ?? ''

interface SettingsData {
  ai_primary_provider: 'gemini' | 'groq'
  gemini_api_key: string | null
  gemini_model_name: string
  groq_api_key: string | null
  groq_model_name: string
  chat_daily_limit: number
}

const settings = ref<SettingsData>({
  ai_primary_provider: 'gemini',
  gemini_api_key: '',
  gemini_model_name: 'gemini-2.5-flash',
  groq_api_key: '',
  groq_model_name: 'llama-3.3-70b-versatile',
  chat_daily_limit: 0,
})

const isLoading = ref(true)
const isSaving = ref(false)
const saveError = ref<string | null>(null)
const saveSuccess = ref(false)

// Testing states
const testingGemini = ref(false)
const geminiTestResult = ref<{ success: boolean; message: string } | null>(null)

const testingGroq = ref(false)
const groqTestResult = ref<{ success: boolean; message: string } | null>(null)

async function fetchSettings() {
  isLoading.value = true
  saveError.value = null
  try {
    const res = await fetch(`${apiBase}/api/admin/settings`)
    if (!res.ok) throw new Error('Không thể tải cấu hình AI.')
    const json = await res.json()
    settings.value = {
      ...json.data,
      gemini_api_key: json.data.gemini_api_key ?? '',
      groq_api_key: json.data.groq_api_key ?? '',
    }
  } catch (e) {
    saveError.value = e instanceof Error ? e.message : 'Lỗi kết nối API.'
  } finally {
    isLoading.value = false
  }
}

async function handleSave() {
  isSaving.value = true
  saveError.value = null
  saveSuccess.value = false
  try {
    const res = await fetch(`${apiBase}/api/admin/settings`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify(settings.value),
    })

    if (!res.ok) {
      const errData = await res.json()
      throw new Error(errData.message || 'Lỗi cập nhật cấu hình.')
    }

    saveSuccess.value = true
    setTimeout(() => {
      saveSuccess.value = false
    }, 3000)
    
    // Refresh settings to get masked keys back
    await fetchSettings()
  } catch (e) {
    saveError.value = e instanceof Error ? e.message : 'Không thể lưu cấu hình.'
  } finally {
    isSaving.value = false
  }
}

async function testConnection(provider: 'gemini' | 'groq') {
  const isGemini = provider === 'gemini'
  const keyToTest = isGemini ? settings.value.gemini_api_key : settings.value.groq_api_key

  if (!keyToTest) {
    const msg = 'Vui lòng nhập API Key trước khi thử kết nối.'
    if (isGemini) geminiTestResult.value = { success: false, message: msg }
    else groqTestResult.value = { success: false, message: msg }
    return
  }

  if (isGemini) {
    testingGemini.value = true
    geminiTestResult.value = null
  } else {
    testingGroq.value = true
    groqTestResult.value = null
  }

  try {
    const res = await fetch(`${apiBase}/api/admin/settings/test-ai`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: JSON.stringify({
        provider,
        api_key: keyToTest,
      }),
    })

    const data = await res.json()
    const result = {
      success: res.ok,
      message: res.ok ? `Kết nối thành công! Phản hồi từ AI: "${data.message}"` : (data.message || 'Kết nối thất bại.'),
    }

    if (isGemini) geminiTestResult.value = result
    else groqTestResult.value = result
  } catch (e) {
    const result = {
      success: false,
      message: 'Không thể kết nối đến máy chủ API hoặc quá trình kiểm tra bị gián đoạn.',
    }
    if (isGemini) geminiTestResult.value = result
    else groqTestResult.value = result
  } finally {
    if (isGemini) testingGemini.value = false
    else testingGroq.value = false
  }
}

onMounted(() => {
  fetchSettings()
})
</script>

<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h1 class="text-3xl font-black tracking-tight text-slate-950">Cấu hình Hệ thống Chatbot AI</h1>
        <p class="text-sm font-semibold text-slate-500">Quản lý API Keys, Nhà cung cấp (Provider) và Hạn mức tin nhắn sức khỏe cho ứng dụng di động.</p>
      </div>
    </div>

    <div v-if="isLoading" class="flex h-64 items-center justify-center rounded-xl border border-slate-200 bg-white shadow-sm">
      <div class="flex flex-col items-center gap-2">
        <RefreshCw class="h-8 w-8 animate-spin text-[#E31837]" />
        <span class="text-sm font-bold text-slate-500">Đang tải cấu hình AI...</span>
      </div>
    </div>

    <form v-else @submit.prevent="handleSave" class="space-y-6">
      <!-- General Settings Card -->
      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 class="flex items-center gap-2 text-lg font-black text-slate-900 border-b border-slate-100 pb-3 mb-4">
          <Sliders class="h-5 w-5 text-[#E31837]" />
          CẤU HÌNH VẬN HÀNH CHUNG
        </h2>

        <div class="grid gap-6 md:grid-cols-2">
          <div>
            <label class="block text-xs font-black uppercase tracking-wider text-slate-500 mb-1.5">
              Provider Ưu tiên (Primary Provider)
            </label>
            <select
              v-model="settings.ai_primary_provider"
              class="w-full h-11 rounded-md border border-slate-200 bg-slate-50 px-3 text-sm font-semibold text-slate-700 outline-none focus:border-[#E31837] focus:bg-white"
            >
              <option value="gemini">Google Gemini Flash (Khuyên dùng)</option>
              <option value="groq">Groq AI (Mô hình Llama 3)</option>
            </select>
            <p class="mt-1 text-[11px] font-semibold text-slate-400">
              Hệ thống sẽ mặc định gọi đến provider này. Nếu lỗi hoặc hết hạn mức, hệ thống tự động fallback sang provider kia.
            </p>
          </div>

          <div>
            <label class="block text-xs font-black uppercase tracking-wider text-slate-500 mb-1.5">
              Hạn mức tin nhắn/user/ngày
            </label>
            <input
              type="number"
              v-model="settings.chat_daily_limit"
              min="0"
              class="w-full h-11 rounded-md border border-slate-200 bg-slate-50 px-3 text-sm font-semibold text-slate-700 outline-none focus:border-[#E31837] focus:bg-white"
              placeholder="0 (Không giới hạn)"
            />
            <p class="mt-1 text-[11px] font-semibold text-slate-400">
              Nhập 0 hoặc bỏ trống nếu không muốn giới hạn. Tránh spam và kiểm soát chi phí API.
            </p>
          </div>
        </div>
      </div>

      <!-- Gemini Config Card -->
      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 class="flex items-center gap-2 text-lg font-black text-slate-900 border-b border-slate-100 pb-3 mb-4">
          <Cpu class="h-5 w-5 text-blue-600" />
          CẤU HÌNH GOOGLE GEMINI
        </h2>

        <div class="space-y-4">
          <div class="grid gap-6 md:grid-cols-2">
            <div>
              <label class="block text-xs font-black uppercase tracking-wider text-slate-500 mb-1.5">
                Gemini API Key
              </label>
              <div class="flex gap-2">
                <input
                  type="password"
                  v-model="settings.gemini_api_key"
                  class="flex-1 h-11 rounded-md border border-slate-200 bg-slate-50 px-3 text-sm font-semibold text-slate-700 outline-none focus:border-blue-500 focus:bg-white"
                  placeholder="Nhập Google AI Studio API Key..."
                />
                <button
                  type="button"
                  :disabled="testingGemini"
                  @click="testConnection('gemini')"
                  class="px-4 h-11 rounded-md border border-slate-200 text-xs font-bold text-slate-600 hover:bg-slate-50 active:scale-[0.98] disabled:opacity-50 inline-flex items-center gap-1.5"
                >
                  <RefreshCw v-if="testingGemini" class="h-3.5 w-3.5 animate-spin" />
                  {{ testingGemini ? 'Đang test...' : 'Kiểm tra' }}
                </button>
              </div>
            </div>

            <div>
              <label class="block text-xs font-black uppercase tracking-wider text-slate-500 mb-1.5">
                Gemini Model Name
              </label>
              <input
                type="text"
                v-model="settings.gemini_model_name"
                class="w-full h-11 rounded-md border border-slate-200 bg-slate-50 px-3 text-sm font-semibold text-slate-700 outline-none focus:border-blue-500 focus:bg-white"
              />
            </div>
          </div>

          <!-- Test Result Banner -->
          <div
            v-if="geminiTestResult"
            :class="[
              'p-3.5 rounded-md text-xs font-semibold flex items-start gap-2',
              geminiTestResult.success ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200'
            ]"
          >
            <CheckCircle2 v-if="geminiTestResult.success" class="h-4 w-4 shrink-0 mt-0.5 text-green-600" />
            <AlertCircle v-else class="h-4 w-4 shrink-0 mt-0.5 text-red-600" />
            <div>{{ geminiTestResult.message }}</div>
          </div>
        </div>
      </div>

      <!-- Groq Config Card -->
      <div class="rounded-xl border border-slate-200 bg-white p-6 shadow-sm">
        <h2 class="flex items-center gap-2 text-lg font-black text-slate-900 border-b border-slate-100 pb-3 mb-4">
          <Cpu class="h-5 w-5 text-orange-600" />
          CẤU HÌNH GROQ CLOUD AI
        </h2>

        <div class="space-y-4">
          <div class="grid gap-6 md:grid-cols-2">
            <div>
              <label class="block text-xs font-black uppercase tracking-wider text-slate-500 mb-1.5">
                Groq API Key
              </label>
              <div class="flex gap-2">
                <input
                  type="password"
                  v-model="settings.groq_api_key"
                  class="flex-1 h-11 rounded-md border border-slate-200 bg-slate-50 px-3 text-sm font-semibold text-slate-700 outline-none focus:border-orange-500 focus:bg-white"
                  placeholder="Nhập Groq API Key..."
                />
                <button
                  type="button"
                  :disabled="testingGroq"
                  @click="testConnection('groq')"
                  class="px-4 h-11 rounded-md border border-slate-200 text-xs font-bold text-slate-600 hover:bg-slate-50 active:scale-[0.98] disabled:opacity-50 inline-flex items-center gap-1.5"
                >
                  <RefreshCw v-if="testingGroq" class="h-3.5 w-3.5 animate-spin" />
                  {{ testingGroq ? 'Đang test...' : 'Kiểm tra' }}
                </button>
              </div>
            </div>

            <div>
              <label class="block text-xs font-black uppercase tracking-wider text-slate-500 mb-1.5">
                Groq Model Name
              </label>
              <input
                type="text"
                v-model="settings.groq_model_name"
                class="w-full h-11 rounded-md border border-slate-200 bg-slate-50 px-3 text-sm font-semibold text-slate-700 outline-none focus:border-orange-500 focus:bg-white"
              />
            </div>
          </div>

          <!-- Test Result Banner -->
          <div
            v-if="groqTestResult"
            :class="[
              'p-3.5 rounded-md text-xs font-semibold flex items-start gap-2',
              groqTestResult.success ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-red-50 text-red-700 border border-red-200'
            ]"
          >
            <CheckCircle2 v-if="groqTestResult.success" class="h-4 w-4 shrink-0 mt-0.5 text-green-600" />
            <AlertCircle v-else class="h-4 w-4 shrink-0 mt-0.5 text-red-600" />
            <div>{{ groqTestResult.message }}</div>
          </div>
        </div>
      </div>

      <!-- Action buttons -->
      <div class="flex items-center justify-end gap-3">
        <div v-if="saveSuccess" class="text-xs font-bold text-green-600 flex items-center gap-1.5">
          <CheckCircle2 class="h-4 w-4" />
          Đã lưu tất cả thay đổi!
        </div>
        <div v-if="saveError" class="text-xs font-bold text-red-600 flex items-center gap-1.5">
          <AlertCircle class="h-4 w-4" />
          {{ saveError }}
        </div>
        <button
          type="submit"
          :disabled="isSaving"
          class="inline-flex h-11 items-center gap-2 rounded-md bg-[#E31837] px-5 text-sm font-black uppercase tracking-wide text-white shadow-sm shadow-red-500/20 transition hover:bg-red-700 active:scale-[0.98] disabled:opacity-50"
        >
          <Save class="h-4 w-4" />
          Lưu cấu hình
        </button>
      </div>
    </form>
  </div>
</template>
