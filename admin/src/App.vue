<script setup lang="ts">
import { computed, onBeforeUnmount, onMounted, ref, type Component } from 'vue'
import {
  AlertTriangle,
  Bell,
  Building2,
  CalendarRange,
  ChevronDown,
  Clock3,
  FileText,
  LayoutDashboard,
  Menu,
  ShieldAlert,
  UserRound,
  X,
} from '@lucide/vue'
import SosModal from './components/SosModal.vue'
import { useEmergencyDashboard } from './composables/useEmergencyDashboard'
import CommunityPosts from './views/CommunityPosts.vue'
import Dashboard from './views/Dashboard.vue'
import DonationEvents from './views/DonationEvents.vue'
import HospitalManagement from './views/HospitalManagement.vue'
import RbacManagement from './views/RbacManagement.vue'
import SosAlerts from './views/SosAlerts.vue'
import type { SosPayload } from './types'
import pulseLinkIcon from './assets/pulse_link_icon.png'
import pulseLinkLogo from './assets/pulse_link_logo.png'

type ViewKey = 'dashboard' | 'hospitals' | 'sos' | 'events' | 'community' | 'rbac'

interface NavItem {
  key: ViewKey
  label: string
  shortLabel: string
  icon: Component
}

const apiBaseUrl = import.meta.env.VITE_API_BASE_URL ?? 'http://127.0.0.1:8000'
const {
  hospitals,
  stats,
  alerts,
  activeAlerts,
  activeAlert,
  activeAlertCommitments,
  commitments,
  currentAdmin,
  selectedAlertId,
  selectedHospitalId,
  selectedHospital,
  isLoading,
  loadDashboard,
  loadProvinces,
  activateSos,
  cancelSos,
  completeSos,
  markCommitmentDonated,
  selectAlert,
} = useEmergencyDashboard(apiBaseUrl)

const currentView = ref<ViewKey>('dashboard')
const showSosModal = ref(false)
const mobileMenuOpen = ref(false)
const currentTime = ref(new Date())
const sosSubmitError = ref<string | null>(null)
const isSubmittingSos = ref(false)
let clockTimer: number | undefined

const navigation: NavItem[] = [
  { key: 'dashboard', label: 'Tổng quan', shortLabel: 'Tổng quan', icon: LayoutDashboard },
  { key: 'hospitals', label: 'Bệnh viện', shortLabel: 'BV', icon: Building2 },
  { key: 'sos', label: 'Cấp cứu SOS', shortLabel: 'SOS', icon: AlertTriangle },
  { key: 'events', label: 'Lịch hiến máu', shortLabel: 'Sự kiện', icon: CalendarRange },
  { key: 'community', label: 'Bài viết cộng đồng', shortLabel: 'Bài viết', icon: FileText },
  { key: 'rbac', label: 'Nhân sự & RBAC', shortLabel: 'RBAC', icon: ShieldAlert },
]

const formattedTime = computed(() =>
  currentTime.value.toLocaleString('vi-VN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false,
  }),
)
const activeViewLabel = computed(() => navigation.find((item) => item.key === currentView.value)?.label ?? 'Tổng quan')
const adminInitials = computed(() => {
  const words = (currentAdmin.value?.name ?? 'Pulse Link')
    .trim()
    .split(/\s+/)
    .filter(Boolean)

  return words.slice(-2).map((word) => word[0]).join('').toUpperCase()
})

function switchView(view: ViewKey) {
  currentView.value = view
  mobileMenuOpen.value = false
}

function openSosModal() {
  sosSubmitError.value = null
  showSosModal.value = true
}

async function submitSos(payload: SosPayload) {
  sosSubmitError.value = null
  isSubmittingSos.value = true
  try {
    await activateSos(payload)
    showSosModal.value = false
    switchView('sos')
  } catch (error) {
    sosSubmitError.value = error instanceof Error ? error.message : 'Không thể phát lệnh SOS.'
  } finally {
    isSubmittingSos.value = false
  }
}

onMounted(async () => {
  await Promise.all([loadDashboard(), loadProvinces()])
  clockTimer = window.setInterval(() => {
    currentTime.value = new Date()
  }, 1000)
})

onBeforeUnmount(() => {
  if (clockTimer) window.clearInterval(clockTimer)
})
</script>

<template>
  <div class="flex min-h-screen bg-[#F8FAFC] text-slate-950">
    <aside class="hidden w-72 shrink-0 border-r border-neutral-800 bg-[#1A1A1A] text-white md:flex md:flex-col">
      <div class="flex h-16 items-center gap-3 border-b border-neutral-800 px-5">
        <div class="relative grid h-10 w-10 place-items-center rounded-md bg-white p-1.5">
          <img :src="pulseLinkIcon" alt="Pulse Link" class="max-h-full max-w-full object-contain" />
          <span class="absolute right-1 top-1 h-2 w-2 rounded-full bg-[#E31837]" />
        </div>
        <div>
          <p class="text-lg font-black uppercase tracking-wider">
            Pulse <span class="text-[#E31837]">Link</span>
          </p>
          <p class="text-[10px] font-bold uppercase tracking-[0.2em] text-neutral-500">Cổng quản trị bệnh viện</p>
        </div>
      </div>

      <nav class="flex-1 space-y-1.5 overflow-y-auto px-4 py-6">
        <button
          v-for="item in navigation"
          :key="item.key"
          class="flex w-full items-center gap-3 rounded-md px-4 py-3 text-left text-sm font-bold transition"
          :class="currentView === item.key ? 'border-l-4 border-[#E31837] bg-white/10 pl-3 text-white' : 'text-neutral-400 hover:bg-white/5 hover:text-white'"
          @click="switchView(item.key)"
        >
          <component :is="item.icon" class="h-5 w-5" :class="item.key === 'sos' ? 'text-amber-400' : ''" />
          <span>{{ item.label }}</span>
          <span
            v-if="item.key === 'sos' && activeAlerts.length"
            class="ml-auto rounded-full bg-[#E31837] px-2 py-0.5 text-[10px] font-black text-white"
          >
            {{ activeAlerts.length }}
          </span>
        </button>
      </nav>

      <div class="px-4 pb-4">
        <div class="rounded-lg border border-white/5 bg-neutral-900 p-3">
          <p class="text-[11px] font-bold uppercase tracking-[0.16em] text-neutral-500">Hệ thống vận hành</p>
          <div class="mt-3 flex items-center gap-2 text-xs font-bold text-emerald-400">
            <span class="h-2 w-2 rounded-full bg-emerald-400" />
            Kết nối API và Reverb
          </div>
        </div>
      </div>

      <div class="flex items-center gap-3 border-t border-neutral-800 bg-black/20 p-4">
        <div class="grid h-9 w-9 place-items-center rounded-full bg-[#E31837] text-xs font-black">{{ adminInitials }}</div>
        <div class="min-w-0">
          <p class="truncate text-xs font-black text-white">{{ currentAdmin?.name ?? 'Quản trị Pulse Link' }}</p>
          <p class="truncate text-[10px] font-semibold text-neutral-500">{{ currentAdmin?.scope_label ?? 'Đang đồng bộ phân quyền' }}</p>
        </div>
      </div>
    </aside>

    <div class="flex min-w-0 flex-1 flex-col">
      <header class="z-20 flex min-h-16 items-center justify-between gap-4 border-b border-slate-200 bg-white px-4 shadow-sm md:px-6">
        <div class="flex min-w-0 items-center gap-3">
          <button class="grid h-9 w-9 place-items-center rounded-md border border-slate-200 text-slate-600 md:hidden" @click="mobileMenuOpen = !mobileMenuOpen">
            <component :is="mobileMenuOpen ? X : Menu" class="h-5 w-5" />
          </button>
          <div class="grid h-10 w-10 shrink-0 place-items-center rounded-md bg-white p-1 shadow-sm ring-1 ring-slate-200">
            <img :src="pulseLinkIcon" alt="Pulse Link" class="max-h-full max-w-full object-contain" />
          </div>
          <div class="min-w-0">
            <p class="truncate text-sm font-black uppercase tracking-wide text-slate-900">
              {{ selectedHospital?.name ?? 'Bệnh viện điều phối Pulse Link' }}
            </p>
            <p class="truncate text-[11px] font-semibold text-slate-500">
              {{ activeViewLabel }} · {{ selectedHospital?.province?.full_name ?? 'Đang tải dữ liệu' }}
            </p>
          </div>
        </div>

        <div class="flex items-center gap-3">
          <select
            v-model="selectedHospitalId"
            class="hidden h-10 max-w-72 rounded-md border border-slate-200 bg-white px-3 text-sm font-semibold text-slate-700 outline-none focus:border-[#E31837] lg:block"
            @change="loadDashboard"
          >
            <option v-for="hospital in hospitals" :key="hospital.id" :value="hospital.id">
              {{ hospital.name }} - {{ hospital.province?.full_name ?? hospital.province_code }}
            </option>
          </select>

          <div class="hidden items-center gap-2 rounded-md border border-slate-200 bg-slate-50 px-3 py-2 text-[11px] font-mono text-slate-500 xl:flex">
            <Clock3 class="h-4 w-4 text-slate-400" />
            {{ formattedTime }}
          </div>

          <button class="relative grid h-10 w-10 place-items-center rounded-md border border-slate-200 text-slate-500 hover:bg-slate-50" aria-label="Thông báo hệ thống">
            <span class="absolute right-2 top-2 h-2 w-2 rounded-full bg-[#E31837]" />
            <Bell class="h-5 w-5" />
          </button>

          <button
            class="inline-flex h-10 items-center gap-2 rounded-md bg-[#E31837] px-3 text-xs font-black uppercase tracking-wide text-white shadow-sm shadow-red-500/20 transition hover:bg-red-700 active:scale-[0.98]"
            @click="openSosModal"
          >
            <AlertTriangle class="h-4 w-4" />
            <span class="hidden sm:inline">Phát lệnh SOS</span>
          </button>

          <button class="hidden h-10 items-center gap-2 rounded-md border border-slate-200 px-2 text-slate-600 sm:flex" aria-label="Tài khoản quản trị">
            <UserRound class="h-5 w-5" />
            <ChevronDown class="h-4 w-4 text-slate-400" />
          </button>
        </div>
      </header>

      <div v-if="mobileMenuOpen" class="border-b border-neutral-800 bg-[#1A1A1A] p-2 md:hidden">
        <div class="mb-2 rounded-md bg-white p-2">
          <img :src="pulseLinkLogo" alt="Pulse Link" class="h-10 w-auto object-contain" />
        </div>
        <div class="grid grid-cols-3 gap-1 sm:grid-cols-6">
          <button
            v-for="item in navigation"
            :key="item.key"
            class="flex flex-col items-center gap-1 rounded-md p-2 text-[10px] font-bold"
            :class="currentView === item.key ? 'bg-white/10 text-white' : 'text-neutral-400'"
            @click="switchView(item.key)"
          >
            <component :is="item.icon" class="h-4 w-4" />
            {{ item.shortLabel }}
          </button>
        </div>
      </div>

      <main class="flex-1 overflow-y-auto p-4 md:p-6">
        <Dashboard
          v-if="currentView === 'dashboard'"
          :stats="stats"
          :active-alerts="activeAlerts"
          :commitments="commitments"
          :is-loading="isLoading"
          @open-sos="openSosModal"
        />
        <SosAlerts
          v-else-if="currentView === 'sos'"
          :alerts="alerts"
          :active-alerts="activeAlerts"
          :active-alert="activeAlert"
          :selected-alert-id="selectedAlertId"
          :commitments="activeAlertCommitments"
          :stats="stats"
          :is-loading="isLoading"
          @open-sos="openSosModal"
          @select-alert="selectAlert"
          @cancel-alert="cancelSos"
          @complete-alert="completeSos"
          @mark-commitment-donated="markCommitmentDonated"
        />
        <HospitalManagement v-else-if="currentView === 'hospitals'" />
        <DonationEvents v-else-if="currentView === 'events'" />
        <CommunityPosts v-else-if="currentView === 'community'" />
        <RbacManagement v-else />
      </main>
    </div>

    <SosModal
      v-if="showSosModal"
      :hospitals="hospitals"
      :default-hospital-id="selectedHospitalId"
      :error-message="sosSubmitError"
      :submitting="isSubmittingSos"
      @close="showSosModal = false"
      @submit="submitSos"
    />
  </div>
</template>
