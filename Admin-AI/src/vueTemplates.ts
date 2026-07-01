export const vueTemplates = {
  shell: `<template>
  <div class="min-h-screen bg-[#F8FAFC] font-sans flex text-gray-900">
    <!-- SIDEBAR -->
    <aside class="w-64 bg-[#1A1A1A] text-white flex flex-col shrink-0 border-r border-gray-800">
      <!-- Brand Header -->
      <div class="h-16 flex items-center px-6 border-b border-gray-800 space-x-3">
        <div class="relative flex items-center justify-center">
          <div class="absolute w-5 h-5 bg-[#E31837] rounded-full animate-ping opacity-75"></div>
          <span class="relative text-[#E31837] text-2xl font-bold">🩸</span>
        </div>
        <span class="text-xl font-bold tracking-tight">Pulse <span class="text-[#E31837]">Link</span></span>
      </div>

      <!-- Navigation Links -->
      <nav class="flex-1 px-4 py-6 space-y-1.5 overflow-y-auto">
        <button
          v-for="item in navItems"
          :key="item.id"
          @click="currentTab = item.id"
          :class="[
            'w-full flex items-center px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200 text-left',
            currentTab === item.id
              ? 'bg-[#E31837] text-white shadow-lg shadow-[#E31837]/20'
              : 'text-gray-400 hover:bg-gray-800 hover:text-white'
          ]"
        >
          <component :is="item.icon" class="w-5 h-5 mr-3 shrink-0" />
          <span>{{ item.label }}</span>
          <span v-if="item.badge" class="ml-auto bg-[#E31837] text-white text-xs px-2 py-0.5 rounded-full animate-pulse">
            {{ item.badge }}
          </span>
        </button>
      </nav>

      <!-- User Profile / Footer -->
      <div class="p-4 border-t border-gray-800 bg-black/20">
        <div class="flex items-center space-x-3">
          <div class="w-10 h-10 rounded-full bg-gradient-to-tr from-[#E31837] to-red-500 flex items-center justify-center text-white font-bold shadow-md">
            AD
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-white truncate">Dr. Nguyễn Minh</p>
            <p class="text-xs text-gray-500 truncate">Super Admin / Director</p>
          </div>
        </div>
      </div>
    </aside>

    <!-- MAIN APP WRAPPER -->
    <div class="flex-1 flex flex-col min-w-0 overflow-hidden">
      <!-- HEADER -->
      <header class="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-8 shrink-0 z-10">
        <div class="flex items-center space-x-4">
          <span class="text-gray-400">🏢</span>
          <h1 class="text-lg font-bold text-gray-800 tracking-tight">Bệnh viện Đa khoa Trung ương</h1>
        </div>

        <div class="flex items-center space-x-6">
          <!-- Time Indicator -->
          <div class="hidden md:flex items-center space-x-2 text-xs font-mono text-gray-500 bg-gray-100 px-3 py-1.5 rounded-md border border-gray-200">
            <span class="w-2 h-2 rounded-full bg-green-500 animate-pulse"></span>
            <span>{{ formattedTime }}</span>
          </div>

          <!-- Trigger SOS Action -->
          <button
            @click="triggerSOS"
            class="bg-[#E31837] hover:bg-red-700 active:scale-95 text-white font-bold text-xs px-4 py-2.5 rounded-lg shadow-md shadow-red-500/20 flex items-center space-x-2 transition-all cursor-pointer"
          >
            <span>🚨</span>
            <span>+ PHÁT LỆNH SOS</span>
          </button>
        </div>
      </header>

      <!-- MAIN WORKSPACE -->
      <main class="flex-1 overflow-y-auto p-8 relative">
        <!-- Live Alert Banner -->
        <div v-if="sosActive" class="mb-6 bg-red-50 border-l-4 border-[#E31837] p-4 rounded-r-xl shadow-sm flex items-center justify-between animate-bounce">
          <div class="flex items-center space-x-3">
            <span class="text-[#E31837] text-xl animate-pulse">🚨</span>
            <div>
              <h3 class="text-sm font-bold text-red-900">BÁO ĐỘNG ĐỎ TRONG TIẾN TRÌNH</h3>
              <p class="text-xs text-red-700">Yêu cầu khẩn cấp nhóm máu hiếm O- tại phòng phẫu thuật cấp cứu số 3.</p>
            </div>
          </div>
          <button @click="sosActive = false" class="text-red-400 hover:text-red-900 text-xs font-semibold px-2 py-1 rounded">
            Tắt báo động
          </button>
        </div>

        <!-- Render Current Module Component -->
        <keep-alive>
          <component :is="currentTabComponent" :sos-active="sosActive" @update-sos="sosActive = $event" />
        </keep-alive>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue';
import { LayoutDashboard, AlertTriangle, CalendarRange, FileText, ShieldAlert } from 'lucide-vue-next';

// Tab Configuration
const currentTab = ref('dashboard');
const sosActive = ref(true);

const navItems = [
  { id: 'dashboard', label: 'Tổng quan', icon: LayoutDashboard },
  { id: 'sos', label: 'Ca cấp cứu SOS', icon: AlertTriangle, badge: '2' },
  { id: 'events', label: 'Lịch hiến máu', icon: CalendarRange },
  { id: 'community', label: 'Bài viết cộng đồng', icon: FileText },
  { id: 'rbac', label: 'Phân quyền & Nhân sự', icon: ShieldAlert },
];

// Time display logic
const currentTime = ref(new Date());
let timer = null;

onMounted(() => {
  timer = setInterval(() => {
    currentTime.value = new Date();
  }, 1000);
});

onUnmounted(() => {
  if (timer) clearInterval(timer);
});

const formattedTime = computed(() => {
  const options = {
    year: 'numeric', month: '2-digit', day: '2-digit',
    hour: '2-digit', minute: '2-digit', second: '2-digit',
    hour12: false
  };
  return currentTime.value.toLocaleDateString('vi-VN', options);
});

// Mock command execution
const triggerSOS = () => {
  sosActive.value = true;
};
</script>`,

  dashboard: `<template>
  <div class="space-y-8">
    <!-- Top KPI Cards -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6">
      <!-- Metric: Active SOS -->
      <div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm relative overflow-hidden transition-all hover:shadow-md">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">Ca cấp cứu SOS Active</p>
            <h3 class="text-3xl font-extrabold text-gray-900 mt-2">02</h3>
          </div>
          <div class="w-12 h-12 bg-red-50 rounded-xl flex items-center justify-center text-[#E31837]">
            <span class="animate-pulse text-xl">🚨</span>
          </div>
        </div>
        <div class="mt-4 flex items-center space-x-1.5">
          <span class="w-2.5 h-2.5 rounded-full bg-[#E31837] animate-ping"></span>
          <span class="text-xs text-[#E31837] font-semibold">Cảnh báo nháy đỏ đỏ thực tế</span>
        </div>
      </div>

      <!-- Metric: Committed Donors -->
      <div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm relative overflow-hidden transition-all hover:shadow-md">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">Người cam kết hiến hôm nay</p>
            <h3 class="text-3xl font-extrabold text-gray-900 mt-2">24</h3>
          </div>
          <div class="w-12 h-12 bg-green-50 rounded-xl flex items-center justify-center text-green-600">
            <span class="text-xl">🤝</span>
          </div>
        </div>
        <div class="mt-4">
          <span class="text-xs font-semibold text-green-600 bg-green-50 px-2 py-0.5 rounded-full">+18% so với hôm qua</span>
        </div>
      </div>

      <!-- Metric: Appointments -->
      <div class="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm relative overflow-hidden transition-all hover:shadow-md">
        <div class="flex items-center justify-between">
          <div>
            <p class="text-sm font-medium text-gray-500">Tổng lịch hẹn đặt trước</p>
            <h3 class="text-3xl font-extrabold text-gray-900 mt-2">145</h3>
          </div>
          <div class="w-12 h-12 bg-blue-50 rounded-xl flex items-center justify-center text-blue-600">
            <span class="text-xl">📅</span>
          </div>
        </div>
        <div class="mt-4 text-xs text-gray-500">
          Trong 7 ngày tiếp theo
        </div>
      </div>
    </div>

    <!-- BLOOD INVENTORY GRID -->
    <div class="bg-white rounded-2xl border border-gray-200 p-6 shadow-sm">
      <div class="flex flex-col sm:flex-row sm:items-center justify-between mb-6 pb-4 border-b border-gray-100">
        <div>
          <h2 class="text-lg font-extrabold text-gray-900">Theo dõi Trực quan Kho máu</h2>
          <p class="text-xs text-gray-500">Đơn vị: Đơn vị máu chuẩn (ml). Cảnh báo nhấp nháy cho các nhóm máu chạm ngưỡng báo động.</p>
        </div>
        <div class="mt-3 sm:mt-0 flex items-center space-x-4 text-xs font-medium">
          <span class="flex items-center"><span class="w-2.5 h-2.5 rounded-full bg-red-100 border border-[#E31837] mr-1.5"></span> Cực thấp (<25)</span>
          <span class="flex items-center"><span class="w-2.5 h-2.5 rounded-full bg-yellow-400 mr-1.5"></span> Trung bình (25-50)</span>
          <span class="flex items-center"><span class="w-2.5 h-2.5 rounded-full bg-green-500 mr-1.5"></span> Đầy đủ (>50)</span>
        </div>
      </div>

      <div class="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-4">
        <div
          v-for="stock in bloodStocks"
          :key="stock.id"
          :class="[
            'p-4 rounded-xl border flex flex-col items-center justify-between transition-all duration-300 relative',
            stock.units < stock.criticalLimit
              ? 'border-red-200 bg-red-50/50 animate-pulse text-red-950 shadow-sm shadow-red-200'
              : 'border-gray-200 hover:border-gray-300 bg-white'
          ]"
        >
          <div class="absolute top-2 right-2" v-if="stock.units < stock.criticalLimit">
            <span class="inline-flex items-center px-1.5 py-0.5 rounded text-[9px] font-bold bg-[#E31837] text-white animate-bounce">CRITICAL</span>
          </div>

          <div class="text-center">
            <span class="text-2xl font-black tracking-tight" :class="stock.units < stock.criticalLimit ? 'text-[#E31837]' : 'text-gray-900'">
              {{ stock.group }}{{ stock.rh }}
            </span>
          </div>

          <!-- Progress Bar style gauge -->
          <div class="w-full bg-gray-100 rounded-full h-2 mt-4 overflow-hidden">
            <div
              :class="[
                'h-full rounded-full transition-all duration-500',
                stock.units < stock.criticalLimit ? 'bg-[#E31837]' : stock.units < 50 ? 'bg-amber-400' : 'bg-green-500'
              ]"
              :style="{ width: Math.min((stock.units / 120) * 100, 100) + '%' }"
            ></div>
          </div>

          <div class="mt-3 text-center">
            <p class="text-base font-extrabold">{{ stock.units }} <span class="text-[10px] text-gray-500 font-normal">đv</span></p>
            <p class="text-[10px] text-gray-400 mt-0.5">Ngưỡng: {{ stock.criticalLimit }} đv</p>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const bloodStocks = ref([
  { id: 1, group: 'O', rh: '+', units: 84, criticalLimit: 25 },
  { id: 2, group: 'O', rh: '-', units: 12, criticalLimit: 25 }, // CRITICAL
  { id: 3, group: 'A', rh: '+', units: 62, criticalLimit: 25 },
  { id: 4, group: 'A', rh: '-', units: 35, criticalLimit: 25 },
  { id: 5, group: 'B', rh: '+', units: 98, criticalLimit: 25 },
  { id: 6, group: 'B', rh: '-', units: 18, criticalLimit: 25 }, // CRITICAL
  { id: 7, group: 'AB', rh: '+', units: 54, criticalLimit: 25 },
  { id: 8, group: 'AB', rh: '-', units: 28, criticalLimit: 25 }
]);
</script>`,

  sos: `<template>
  <div class="space-y-6">
    <div class="flex flex-col md:flex-row gap-6">
      <!-- LEFT PANEL: MAP PLACEHOLDER (65%) -->
      <div class="md:w-2/3 bg-white rounded-2xl border border-gray-200 p-6 shadow-sm flex flex-col h-[550px]">
        <div class="flex items-center justify-between mb-4">
          <div>
            <h2 class="text-lg font-extrabold text-gray-900 flex items-center">
              <span class="relative flex h-3 w-3 mr-2">
                <span class="animate-ping absolute inline-flex h-full w-full rounded-full bg-[#E31837] opacity-75"></span>
                <span class="relative inline-flex rounded-full h-3 w-3 bg-[#E31837]"></span>
              </span>
              Bản đồ Điều phối Thời gian thực
            </h2>
            <p class="text-xs text-gray-500">Đang theo dõi vị trí các tình nguyện viên di chuyển về phía Bệnh viện.</p>
          </div>
          <span class="text-xs font-mono bg-red-100 text-[#E31837] font-semibold px-2.5 py-1 rounded-full">
            Khu vực: 30km Bán kính
          </span>
        </div>

        <!-- Map Screen Placeholder -->
        <div class="flex-1 bg-gray-950 rounded-xl relative overflow-hidden border border-gray-800">
          <!-- Grid Background Matrix to simulate a high-tech UI map -->
          <div class="absolute inset-0 opacity-10 bg-[radial-gradient(#fff_1px,transparent_1px)] [background-size:16px_16px]"></div>

          <!-- Pulsing Hospital Center -->
          <div class="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-center z-10">
            <div class="relative flex items-center justify-center">
              <div class="absolute w-12 h-12 bg-red-500/25 rounded-full animate-ping"></div>
              <div class="absolute w-20 h-20 bg-red-500/10 rounded-full animate-pulse"></div>
              <div class="w-6 h-6 bg-[#E31837] border-2 border-white rounded-full flex items-center justify-center text-[10px] text-white font-bold shadow-lg">
                🏥
              </div>
            </div>
            <span class="inline-block mt-2 text-[10px] bg-black/80 text-white font-semibold px-2 py-0.5 rounded border border-gray-700 whitespace-nowrap">
              Bệnh viện TW (Tâm chấn)
            </span>
          </div>

          <!-- Connecting Polyline Routes (CSS paths) -->
          <svg class="absolute inset-0 w-full h-full pointer-events-none">
            <path d="M 100 100 L 320 275" stroke="#E31837" stroke-width="2" stroke-dasharray="4 4" class="animate-[dash_2s_linear_infinite]" />
            <path d="M 500 120 L 320 275" stroke="#E31837" stroke-width="2" stroke-dasharray="4 4" />
            <path d="M 150 450 L 320 275" stroke="#E31837" stroke-width="2" stroke-dasharray="4 4" />
            <path d="M 520 400 L 320 275" stroke="#E31837" stroke-width="2" stroke-dasharray="4 4" />
          </svg>

          <!-- Volunteers Moving Indicators -->
          <div class="absolute top-1/4 left-1/4 animate-bounce">
            <div class="flex items-center space-x-1.5 bg-black/80 border border-red-500 rounded-full px-2 py-0.5 text-white">
              <span class="text-xs">🩸 O-</span>
              <span class="w-1.5 h-1.5 bg-red-500 rounded-full animate-ping"></span>
            </div>
          </div>
          <div class="absolute top-1/3 right-1/4">
            <div class="flex items-center space-x-1.5 bg-black/80 border border-green-500 rounded-full px-2 py-0.5 text-white">
              <span class="text-xs">🩸 A-</span>
              <span class="w-1.5 h-1.5 bg-green-500 rounded-full animate-ping"></span>
            </div>
          </div>
          <div class="absolute bottom-1/4 right-1/3">
            <div class="flex items-center space-x-1.5 bg-black/80 border border-red-500 rounded-full px-2 py-0.5 text-white">
              <span class="text-xs">🩸 O-</span>
              <span class="w-1.5 h-1.5 bg-red-500 rounded-full animate-ping"></span>
            </div>
          </div>
        </div>
      </div>

      <!-- RIGHT PANEL: WAVE DISPATCH & LOGS (35%) -->
      <div class="md:w-1/3 bg-white rounded-2xl border border-gray-200 p-6 shadow-sm flex flex-col h-[550px]">
        <h2 class="text-lg font-extrabold text-gray-900 mb-2">Điều phối theo Làn sóng</h2>
        <p class="text-xs text-gray-500 mb-4">Các giai đoạn lan tỏa sóng SOS dựa vào bán kính địa lý:</p>

        <!-- Timeline Log list -->
        <div class="flex-1 space-y-4 overflow-y-auto pr-1">
          <!-- Step 1 -->
          <div class="border-l-2 border-green-500 pl-4 relative pb-2">
            <div class="absolute -left-1.5 top-0 w-3.5 h-3.5 rounded-full bg-green-500 border-2 border-white"></div>
            <div class="flex items-center justify-between">
              <h4 class="text-xs font-bold text-gray-900">Sóng 1: Nội thành (Bán kính 5km)</h4>
              <span class="text-[9px] bg-green-50 text-green-700 font-bold px-1.5 py-0.5 rounded">Hoàn thành</span>
            </div>
            <p class="text-[11px] text-gray-500 mt-1">Đã gửi thông báo đẩy đến 124 người dùng có loại máu O-. Có 8 người phản hồi đồng ý hiến.</p>
          </div>

          <!-- Step 2 -->
          <div class="border-l-2 border-[#E31837] pl-4 relative pb-2">
            <div class="absolute -left-1.5 top-0 w-3.5 h-3.5 rounded-full bg-[#E31837] border-2 border-white animate-pulse"></div>
            <div class="flex items-center justify-between">
              <h4 class="text-xs font-bold text-red-950">Sóng 2: Ngoại thành (5km - 30km)</h4>
              <span class="text-[9px] bg-red-100 text-[#E31837] font-bold px-1.5 py-0.5 rounded animate-pulse">Đang lan tỏa</span>
            </div>
            <p class="text-[11px] text-gray-500 mt-1">Gửi thông báo cấp tập. Đã tìm thấy 12 người đăng ký hiến bổ sung đang di chuyển.</p>
          </div>

          <!-- Step 3 -->
          <div class="border-l-2 border-gray-200 pl-4 relative">
            <div class="absolute -left-1.5 top-0 w-3.5 h-3.5 rounded-full bg-gray-200 border-2 border-white"></div>
            <div class="flex items-center justify-between">
              <h4 class="text-xs font-bold text-gray-400">Sóng 3: Liên tỉnh (>30km)</h4>
              <span class="text-[9px] bg-gray-100 text-gray-500 font-bold px-1.5 py-0.5 rounded">Sẵn sàng</span>
            </div>
            <p class="text-[11px] text-gray-400 mt-1">Sẽ tự động kích hoạt phát sóng qua hệ thống báo đài địa phương nếu Sóng 2 chưa gom đủ 20 đơn vị máu trong 15 phút tới.</p>
          </div>
        </div>

        <!-- Real-time counter widgets -->
        <div class="mt-4 pt-4 border-t border-gray-100 bg-gray-50 p-4 rounded-xl">
          <p class="text-xs font-bold text-gray-700">Tình nguyện viên đã Cam kết</p>
          <div class="flex items-end justify-between mt-2">
            <span class="text-3xl font-black text-gray-950">20 <span class="text-xs font-normal text-gray-500">/ 30 người cần thiết</span></span>
            <span class="text-xs font-semibold text-[#E31837] bg-red-50 px-2 py-0.5 rounded-full animate-pulse">Còn thiếu 10</span>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
// Live communication simulation
</script>`,

  events: `<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between">
      <div>
        <h2 class="text-xl font-black text-gray-900 tracking-tight">Quản lý Lịch hiến máu</h2>
        <p class="text-xs text-gray-500">Quản lý và thiết lập các sự kiện vận động hiến máu cộng đồng.</p>
      </div>
      <button
        @click="showModal = true"
        class="bg-[#E31837] hover:bg-red-700 text-white text-xs font-bold px-4 py-2.5 rounded-lg flex items-center space-x-2 shadow-sm transition-colors cursor-pointer"
      >
        <span>+ TẠO LỊCH HIẾN MÁU MỚI</span>
      </button>
    </div>

    <!-- DATA TABLE -->
    <div class="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="bg-gray-50 text-gray-400 text-[11px] uppercase font-bold border-b border-gray-200">
            <th class="py-3.5 px-6">ID</th>
            <th class="py-3.5 px-6">Sự kiện</th>
            <th class="py-3.5 px-6">Thời gian</th>
            <th class="py-3.5 px-6">Địa điểm</th>
            <th class="py-3.5 px-6 text-center">Chỉ tiêu (đv)</th>
            <th class="py-3.5 px-6 text-center">Đã Đăng ký</th>
            <th class="py-3.5 px-6 text-center">Trạng thái</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100 text-xs">
          <tr v-for="event in events" :key="event.id" class="hover:bg-gray-50/50 transition-colors">
            <td class="py-4 px-6 font-mono text-gray-400">{{ event.id }}</td>
            <td class="py-4 px-6 font-bold text-gray-900">{{ event.name }}</td>
            <td class="py-4 px-6 text-gray-600">{{ event.date }} {{ event.time }}</td>
            <td class="py-4 px-6 text-gray-500">{{ event.location }}</td>
            <td class="py-4 px-6 text-center font-bold text-gray-800">{{ event.targetUnits }}</td>
            <td class="py-4 px-6 text-center">
              <span class="font-bold text-green-600">{{ event.registeredDonors }}</span>
            </td>
            <td class="py-4 px-6 text-center">
              <span :class="[
                'px-2 py-0.5 rounded-full text-[10px] font-bold',
                event.status === 'Đang diễn ra' ? 'bg-green-50 text-green-700' :
                event.status === 'Nháp' ? 'bg-gray-100 text-gray-600' : 'bg-red-50 text-[#E31837]'
              ]">
                {{ event.status }}
              </span>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- MODAL FOR CREATING NEW EVENT -->
    <div v-if="showModal" class="fixed inset-0 bg-black/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
      <div class="bg-white rounded-2xl border border-gray-200 shadow-2xl max-w-lg w-full overflow-hidden animate-in fade-in zoom-in-95 duration-200">
        <div class="px-6 py-4 bg-gray-50 border-b border-gray-200 flex items-center justify-between">
          <h3 class="font-black text-gray-900 text-sm uppercase">Tạo lịch hiến máu mới</h3>
          <button @click="showModal = false" class="text-gray-400 hover:text-gray-600 text-lg">×</button>
        </div>
        <form @submit.prevent="createEvent" class="p-6 space-y-4">
          <div>
            <label class="block text-xs font-bold text-gray-700 mb-1">Tên sự kiện</label>
            <input v-model="form.name" required type="text" class="w-full p-2.5 border border-gray-300 rounded-lg text-xs" placeholder="Ví dụ: Giọt Hồng Nhân Ái Quận 1" />
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-bold text-gray-700 mb-1">Ngày diễn ra</label>
              <input v-model="form.date" required type="date" class="w-full p-2.5 border border-gray-300 rounded-lg text-xs" />
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-700 mb-1">Giờ diễn ra</label>
              <input v-model="form.time" required type="time" class="w-full p-2.5 border border-gray-300 rounded-lg text-xs" />
            </div>
          </div>
          <div>
            <label class="block text-xs font-bold text-gray-700 mb-1">Địa chỉ / Điểm tổ chức</label>
            <input v-model="form.location" required type="text" class="w-full p-2.5 border border-gray-300 rounded-lg text-xs" placeholder="Số 10, đường ABC, Phường X..." />
          </div>
          <div class="grid grid-cols-2 gap-4">
            <div>
              <label class="block text-xs font-bold text-gray-700 mb-1">Chỉ tiêu (Đơn vị máu)</label>
              <input v-model="form.targetUnits" required type="number" class="w-full p-2.5 border border-gray-300 rounded-lg text-xs" />
            </div>
            <div>
              <label class="block text-xs font-bold text-gray-700 mb-1">Chương trình Quà / Khích lệ</label>
              <input v-model="form.incentives" type="text" class="w-full p-2.5 border border-gray-300 rounded-lg text-xs" placeholder="Gói quà tặng dinh dưỡng hạng A..." />
            </div>
          </div>
          <div class="flex items-center justify-between p-3 bg-gray-50 rounded-xl">
            <div>
              <p class="text-xs font-bold text-gray-800">Đăng lên Ứng dụng Di động</p>
              <p class="text-[10px] text-gray-500">Người dùng app sẽ nhận thông báo đẩy tức thì.</p>
            </div>
            <input v-model="form.publishToApp" type="checkbox" class="w-4 h-4 text-[#E31837] border-gray-300 rounded focus:ring-[#E31837]" />
          </div>
          <div class="pt-4 border-t border-gray-100 flex items-center justify-end space-x-3">
            <button @click="showModal = false" type="button" class="px-4 py-2 border border-gray-300 text-gray-600 rounded-lg text-xs font-bold hover:bg-gray-50">Hủy</button>
            <button type="submit" class="px-4 py-2 bg-[#E31837] text-white rounded-lg text-xs font-bold hover:bg-red-700">Tạo sự kiện</button>
          </div>
        </form>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue';

const showModal = ref(false);
const events = ref([
  { id: 'EV01', name: 'Hành trình Đỏ - Kết nối cộng đồng', date: '2026-07-15', time: '08:00', location: 'Sảnh Đa năng Bệnh viện', targetUnits: 150, registeredDonors: 112, status: 'Đang diễn ra' },
  { id: 'EV02', name: 'Giọt máu nghĩa tình - Chi nhánh Quận 3', date: '2026-08-01', time: '07:30', location: 'Ủy ban Nhân dân Quận 3', targetUnits: 100, registeredDonors: 45, status: 'Nháp' }
]);

const form = reactive({
  name: '',
  date: '',
  time: '',
  location: '',
  targetUnits: 100,
  incentives: '',
  publishToApp: true
});

const createEvent = () => {
  events.value.push({
    id: 'EV' + String(events.value.length + 1).padStart(2, '0'),
    name: form.name,
    date: form.date,
    time: form.time,
    location: form.location,
    targetUnits: Number(form.targetUnits),
    registeredDonors: 0,
    status: 'Nháp'
  });
  showModal.value = false;
};
</script>`,

  community: `<template>
  <div class="space-y-6">
    <div class="grid grid-cols-1 lg:grid-cols-3 gap-6">
      <!-- MOCK CMS FORM (LEFT 2 COLS) -->
      <div class="lg:col-span-2 bg-white rounded-2xl border border-gray-200 p-6 shadow-sm space-y-4">
        <h2 class="text-base font-extrabold text-gray-900 uppercase tracking-wider pb-3 border-b border-gray-100">
          Soạn thảo Bài viết Vận động mới
        </h2>

        <div>
          <label class="block text-xs font-bold text-gray-700 mb-1">Tiêu đề bài đăng</label>
          <input type="text" class="w-full p-2.5 border border-gray-300 rounded-lg text-xs" placeholder="Nhập tiêu đề thu hút, kêu gọi hiến máu..." />
        </div>

        <div>
          <label class="block text-xs font-bold text-gray-700 mb-1">Phân vùng Khán giả Nhắm mục tiêu</label>
          <select class="w-full p-2.5 border border-gray-300 rounded-lg text-xs bg-white">
            <option>Gửi đến toàn bộ Người dùng Ứng dụng</option>
            <option>Chỉ nhắm mục tiêu Nhóm máu O- (Khẩn cấp)</option>
            <option>Chỉ nhắm mục tiêu Nhóm máu Hiếm (Rh-)</option>
            <option>Nhóm tình nguyện viên có thành tích xuất sắc</option>
          </select>
        </div>

        <div>
          <label class="block text-xs font-bold text-gray-700 mb-1">Nội dung bài viết (Trình soạn thảo giả lập)</label>
          <div class="border border-gray-300 rounded-lg overflow-hidden text-xs">
            <!-- Mock Editor toolbar -->
            <div class="bg-gray-50 border-b border-gray-300 p-2 flex items-center space-x-4">
              <span class="font-bold hover:text-gray-900 cursor-pointer">B</span>
              <span class="italic hover:text-gray-900 cursor-pointer">I</span>
              <span class="underline hover:text-gray-900 cursor-pointer">U</span>
              <span class="text-gray-300">|</span>
              <span class="hover:text-gray-900 cursor-pointer">🔗 Chèn Link</span>
              <span class="hover:text-gray-900 cursor-pointer">🖼️ Thêm Ảnh</span>
            </div>
            <textarea rows="6" class="w-full p-3 border-none outline-none resize-none text-xs" placeholder="Nhập nội dung thông điệp truyền cảm hứng tại đây..."></textarea>
          </div>
        </div>

        <!-- File Upload Mock -->
        <div>
          <label class="block text-xs font-bold text-gray-700 mb-1">Hình ảnh bìa bài viết</label>
          <div class="border-2 border-dashed border-gray-200 rounded-xl p-6 text-center hover:bg-gray-50 transition-colors cursor-pointer">
            <span class="text-3xl">📤</span>
            <p class="text-xs font-bold text-gray-700 mt-2">Kéo thả ảnh hoặc Click để chọn file</p>
            <p class="text-[10px] text-gray-400 mt-1">Hỗ trợ PNG, JPG dung lượng tối đa 5MB</p>
          </div>
        </div>

        <div class="flex items-center justify-end space-x-3 pt-3 border-t border-gray-100">
          <button class="px-4 py-2 border border-gray-300 text-gray-600 rounded-lg text-xs font-bold hover:bg-gray-50">Lưu nháp</button>
          <button class="px-4 py-2 bg-[#E31837] hover:bg-red-700 text-white rounded-lg text-xs font-bold">XUẤT BẢN NGAY</button>
        </div>
      </div>

      <!-- ENGAGEMENT STATS CARDS (RIGHT 1 COL) -->
      <div class="bg-white rounded-2xl border border-gray-200 p-6 shadow-sm flex flex-col h-[650px] overflow-hidden">
        <h2 class="text-base font-extrabold text-gray-900 uppercase tracking-wider pb-3 border-b border-gray-100 mb-4">
          Bài viết đã đăng gần đây
        </h2>

        <div class="flex-1 overflow-y-auto space-y-4 pr-1">
          <div v-for="post in pastPosts" :key="post.id" class="p-3.5 border border-gray-100 rounded-xl bg-gray-50 hover:border-gray-300 transition-all">
            <h4 class="text-xs font-bold text-gray-900 line-clamp-1">{{ post.title }}</h4>
            <p class="text-[10px] text-gray-400 mt-1">Đăng ngày: {{ post.date }} • Đối tượng: {{ post.target }}</p>

            <div class="grid grid-cols-3 gap-2 mt-3 pt-2.5 border-t border-gray-200 text-center text-[10px]">
              <div>
                <p class="font-extrabold text-gray-800">{{ post.views }}</p>
                <p class="text-gray-400 text-[9px]">Lượt xem</p>
              </div>
              <div>
                <p class="font-extrabold text-gray-800">{{ post.shares }}</p>
                <p class="text-gray-400 text-[9px]">Chia sẻ</p>
              </div>
              <div>
                <p class="font-extrabold text-green-600">👍 {{ post.likes }}</p>
                <p class="text-gray-400 text-[9px]">Biểu dương</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const pastPosts = ref([
  { id: 1, title: 'Báo động đỏ: Cần gấp 10 người hiến máu O- cứu sản phụ nguy kịch', date: '30-06-2026', target: 'Máu O-', views: 1840, shares: 320, likes: 145 },
  { id: 2, title: 'Hành trình hiến máu tiếp sức mùa dịch cùng y bác sĩ Trung ương', date: '28-06-2026', target: 'Tất cả người dùng', views: 950, shares: 120, likes: 80 },
  { id: 3, title: 'Kỷ niệm ngày Quốc tế Hiến máu: Vinh danh 100 tình nguyện viên vàng', date: '14-06-2026', target: 'Toàn quốc', views: 2400, shares: 540, likes: 450 }
]);
</script>`,

  rbac: `<template>
  <div class="space-y-6">
    <div class="flex items-center justify-between pb-4 border-b border-gray-200">
      <div>
        <h2 class="text-xl font-black text-gray-900 tracking-tight">Hệ thống Phân quyền Nhân sự (RBAC)</h2>
        <p class="text-xs text-gray-500">Giám sát tài khoản và điều khiển quyền truy cập nghiêm ngặt của nhân viên y tế.</p>
      </div>
      <span class="text-xs font-mono bg-red-100 text-[#E31837] font-bold px-3 py-1.5 rounded-full">
        Môi trường Bảo mật Cấp cao
      </span>
    </div>

    <!-- USERS DATA TABLE -->
    <div class="bg-white rounded-2xl border border-gray-200 shadow-sm overflow-hidden">
      <table class="w-full text-left border-collapse">
        <thead>
          <tr class="bg-gray-50 text-gray-400 text-[11px] uppercase font-bold border-b border-gray-200">
            <th class="py-3.5 px-6">Họ và Tên</th>
            <th class="py-3.5 px-6">Phòng ban / Đơn vị</th>
            <th class="py-3.5 px-6">Vai trò Hệ thống</th>
            <th class="py-3.5 px-6 text-center">Trạng thái</th>
            <th class="py-3.5 px-6 text-center">Hành động</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-100 text-xs">
          <tr v-for="user in staff" :key="user.id" class="hover:bg-gray-50/50 transition-colors">
            <td class="py-4 px-6 font-bold text-gray-900">{{ user.name }}</td>
            <td class="py-4 px-6 text-gray-600">{{ user.department }}</td>
            <td class="py-4 px-6">
              <span :class="[
                'px-2.5 py-1 rounded-lg text-[10px] font-extrabold border',
                user.role === 'Super Admin / Director' ? 'bg-red-50 text-[#E31837] border-red-200' :
                user.role === 'ER Doctor / Surgeon' ? 'bg-amber-50 text-amber-700 border-amber-200' :
                'bg-blue-50 text-blue-700 border-blue-200'
              ]">
                {{ user.role }}
              </span>
            </td>
            <td class="py-4 px-6 text-center">
              <span :class="[
                'inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold',
                user.status === 'Đang hoạt động' ? 'bg-green-50 text-green-700' : 'bg-red-50 text-red-700'
              ]">
                <span class="w-1.5 h-1.5 rounded-full mr-1.5" :class="user.status === 'Đang hoạt động' ? 'bg-green-500' : 'bg-red-500'"></span>
                {{ user.status }}
              </span>
            </td>
            <td class="py-4 px-6 text-center space-x-2">
              <button @click="openEdit(user)" class="text-blue-600 hover:text-blue-800 font-bold text-xs cursor-pointer">Sửa quyền</button>
              <button @click="toggleStatus(user)" class="text-red-500 hover:text-red-700 font-bold text-xs cursor-pointer">
                {{ user.status === 'Đang hoạt động' ? 'Khóa' : 'Mở' }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- MOCK RULES AUDIT PANEL -->
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-6">
      <div class="bg-gray-900 text-white p-5 rounded-2xl border border-gray-800 shadow-lg">
        <h3 class="text-xs font-bold text-red-500 uppercase tracking-widest">Quyền Hạn: Super Admin</h3>
        <p class="text-xs text-gray-400 mt-2">Quyền tối cao điều phối toàn bộ tài nguyên, phê duyệt nhân sự y tế, có quyền xóa lịch sử nhật ký hệ thống dữ liệu hiến máu.</p>
      </div>
      <div class="bg-gray-900 text-white p-5 rounded-2xl border border-gray-800 shadow-lg">
        <h3 class="text-xs font-bold text-amber-500 uppercase tracking-widest">Quyền Hạn: ER Doctor</h3>
        <p class="text-xs text-gray-400 mt-2">Được phép phát lệnh BÁO ĐỘNG ĐỎ khẩn cấp (SOS), bỏ qua mọi bước kiểm duyệt thông thường để huy động nhóm máu khẩn cấp tại phòng mổ.</p>
      </div>
      <div class="bg-gray-900 text-white p-5 rounded-2xl border border-gray-800 shadow-lg">
        <h3 class="text-xs font-bold text-blue-400 uppercase tracking-widest">Quyền Hạn: Coordinator</h3>
        <p class="text-xs text-gray-400 mt-2">Lên lịch hiến máu, duyệt bài viết cộng đồng, cập nhật chỉ số tồn kho kho máu hàng ngày. Không có quyền phát lệnh SOS.</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue';

const staff = ref([
  { id: 1, name: 'GS. Nguyễn Minh', department: 'Ban Giám đốc', role: 'Super Admin / Director', status: 'Đang hoạt động' },
  { id: 2, name: 'BS. Trần Tiến', department: 'Khoa Cấp cứu & Phẫu thuật', role: 'ER Doctor / Surgeon', status: 'Đang hoạt động' },
  { id: 3, name: 'ĐD. Lê Thị Hồng', department: 'Trung tâm Truyền máu', role: 'Coordinator / Nurse', status: 'Đang hoạt động' },
  { id: 4, name: 'BS. Phạm Vũ Hoàng', department: 'Khoa Hồi sức tích cực', role: 'ER Doctor / Surgeon', status: 'Tạm khóa' }
]);

const toggleStatus = (user) => {
  user.status = user.status === 'Đang hoạt động' ? 'Tạm khóa' : 'Đang hoạt động';
};
const openEdit = (user) => {
  alert('Đang mở panel tùy chỉnh phân quyền chi tiết cho: ' + user.name);
};
</script>`
};
