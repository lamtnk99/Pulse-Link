<script setup lang="ts">
import { ref } from 'vue'
import { AlertTriangle, KeyRound, Mail } from '@lucide/vue'
import pulseLinkIcon from '../assets/pulse_link_icon.png'

const emit = defineEmits<{
  (e: 'login-success', token: string, user: any): void
}>()

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000'

// Pre-fill system admin by default for convenience
const email = ref('system@pulselink.test')
const password = ref('password')
const isLoading = ref(false)
const errorMessage = ref<string | null>(null)

function fillCredentials(mail: string) {
  email.value = mail
  password.value = 'password'
}

async function handleLogin() {
  errorMessage.value = null
  isLoading.value = true

  try {
    const response = await fetch(`${apiBaseUrl}/api/auth/login`, {
      method: 'POST',
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email: email.value,
        password: password.value,
      }),
    })

    const payload = await response.json()

    if (!response.ok) {
      throw new Error(payload.message || payload.errors?.email?.[0] || 'Thông tin đăng nhập không chính xác.')
    }

    const { token, user } = payload.data
    localStorage.setItem('admin_token', token)
    localStorage.setItem('admin_user', JSON.stringify(user))

    emit('login-success', token, user)
  } catch (error) {
    errorMessage.value = error instanceof Error ? error.message : 'Đã xảy ra lỗi kết nối.'
  } finally {
    isLoading.value = false
  }
}
</script>

<template>
  <div class="w-full max-w-md rounded-2xl border border-slate-800 bg-[#1A1A1A] p-8 shadow-2xl text-white">
    <div class="flex flex-col items-center">
      <div class="relative grid h-16 w-16 place-items-center rounded-xl bg-white p-2.5 shadow-lg">
        <img :src="pulseLinkIcon" alt="Pulse Link" class="max-h-full max-w-full object-contain" />
        <span class="absolute right-1 top-1 h-3 w-3 rounded-full bg-[#E31837]" />
      </div>
      <h2 class="mt-6 text-2xl font-black uppercase tracking-wider">
        PULSE <span class="text-[#E31837]">LINK</span>
      </h2>
      <p class="mt-1.5 text-xs font-bold uppercase tracking-[0.25em] text-neutral-500">Mạch Sống - Điều phối khẩn cấp</p>
    </div>

    <form @submit.prevent="handleLogin" class="mt-8 space-y-5">
      <div v-if="errorMessage" class="flex items-start gap-2.5 rounded-lg border border-red-500/20 bg-red-500/10 p-3.5 text-xs font-semibold text-red-400">
        <AlertTriangle class="h-4 w-4 shrink-0 mt-0.5" />
        <span>{{ errorMessage }}</span>
      </div>

      <div>
        <label for="email" class="block text-[11px] font-black uppercase tracking-[0.14em] text-slate-400">Email quản trị</label>
        <div class="relative mt-1.5">
          <Mail class="absolute left-3 top-1/2 h-4.5 w-4.5 -translate-y-1/2 text-slate-500" />
          <input
            id="email"
            v-model="email"
            type="email"
            required
            placeholder="admin@pulselink.test"
            class="h-11 w-full rounded-md border border-slate-800 bg-slate-900/50 pl-10 pr-3 text-sm font-bold text-white placeholder-slate-600 outline-none transition focus:border-[#E31837] focus:bg-slate-900"
          />
        </div>
      </div>

      <div>
        <label for="password" class="block text-[11px] font-black uppercase tracking-[0.14em] text-slate-400">Mật khẩu</label>
        <div class="relative mt-1.5">
          <KeyRound class="absolute left-3 top-1/2 h-4.5 w-4.5 -translate-y-1/2 text-slate-500" />
          <input
            id="password"
            v-model="password"
            type="password"
            required
            placeholder="••••••••"
            class="h-11 w-full rounded-md border border-slate-800 bg-slate-900/50 pl-10 pr-3 text-sm font-bold text-white placeholder-slate-600 outline-none transition focus:border-[#E31837] focus:bg-slate-900"
          />
        </div>
      </div>

      <button
        type="submit"
        :disabled="isLoading"
        class="flex h-11 w-full items-center justify-center gap-2 rounded-md bg-[#E31837] text-sm font-black uppercase tracking-wide text-white shadow-lg shadow-red-500/10 transition hover:bg-red-700 active:scale-[0.98] disabled:cursor-not-allowed disabled:opacity-60"
      >
        <span v-if="isLoading">Đang đăng nhập...</span>
        <span v-else>Đăng nhập</span>
      </button>

      <div class="mt-6 border-t border-slate-800/80 pt-5">
        <p class="text-[10px] font-black uppercase tracking-[0.14em] text-slate-500 mb-2.5 text-center">Tài khoản thử nghiệm (Click để điền)</p>
        <div class="grid grid-cols-2 gap-2 text-[11px] font-bold">
          <button
            type="button"
            class="flex flex-col items-center justify-center p-2 rounded bg-slate-900 border border-slate-800/60 transition hover:border-[#E31837] hover:bg-slate-900/80"
            @click="fillCredentials('system@pulselink.test')"
          >
            <span class="text-white">System Admin</span>
            <span class="text-[9px] text-slate-500 font-medium">system@pulselink.test</span>
          </button>
          <button
            type="button"
            class="flex flex-col items-center justify-center p-2 rounded bg-slate-900 border border-slate-800/60 transition hover:border-[#E31837] hover:bg-slate-900/80"
            @click="fillCredentials('admin@pulselink.test')"
          >
            <span class="text-white">Hospital Admin</span>
            <span class="text-[9px] text-slate-500 font-medium">admin@pulselink.test</span>
          </button>
        </div>
      </div>
    </form>
  </div>
</template>
