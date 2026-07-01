<script setup lang="ts">
import { ref } from 'vue'
import { ShieldAlert, UserCheck, UserX } from '@lucide/vue'

interface StaffAccount {
  id: string
  name: string
  department: string
  role: 'Giám đốc hệ thống' | 'Bác sĩ cấp cứu' | 'Điều phối viên'
  active: boolean
}

const staff = ref<StaffAccount[]>([
  { id: 'ST-01', name: 'GS. Nguyễn Minh', department: 'Ban giám đốc', role: 'Giám đốc hệ thống', active: true },
  { id: 'ST-02', name: 'BS. Trần Tiến', department: 'Khoa Cấp cứu', role: 'Bác sĩ cấp cứu', active: true },
  { id: 'ST-03', name: 'ĐD. Lê Thị Hồng', department: 'Trung tâm Truyền máu', role: 'Điều phối viên', active: true },
  { id: 'ST-04', name: 'BS. Phạm Vũ Hoàng', department: 'Hồi sức tích cực', role: 'Bác sĩ cấp cứu', active: false },
])

const permissions = [
  ['Phát lệnh SOS', 'Giám đốc hệ thống', 'Bác sĩ cấp cứu'],
  ['Quản lý lịch hiến máu', 'Giám đốc hệ thống', 'Điều phối viên'],
  ['Xuất bản bài cộng đồng', 'Giám đốc hệ thống', 'Điều phối viên'],
  ['Quản lý phân quyền', 'Giám đốc hệ thống'],
]
</script>

<template>
  <div class="space-y-5">
    <section>
      <p class="text-xs font-black uppercase tracking-[0.22em] text-[#E31837]">Bảo mật vận hành</p>
      <h2 class="mt-2 flex items-center gap-2 text-2xl font-black text-slate-950">
        <ShieldAlert class="h-6 w-6 text-[#E31837]" />
        Nhân sự và phân quyền RBAC
      </h2>
    </section>

    <section class="grid gap-4 md:grid-cols-3">
      <article v-for="role in ['Giám đốc hệ thống', 'Bác sĩ cấp cứu', 'Điều phối viên']" :key="role" class="rounded-lg border border-slate-800 bg-slate-950 p-4 text-white">
        <h3 class="text-sm font-black text-[#E31837]">{{ role }}</h3>
        <p class="mt-2 text-xs leading-5 text-slate-400">
          {{ role === 'Giám đốc hệ thống' ? 'Toàn quyền giám sát, cấp quyền và kiểm toán.' : role === 'Bác sĩ cấp cứu' ? 'Kích hoạt hoặc hủy báo động đỏ theo ca trực.' : 'Quản lý lịch hiến máu và truyền thông cộng đồng.' }}
        </p>
      </article>
    </section>

    <section class="grid gap-5 xl:grid-cols-[1.2fr_0.8fr]">
      <article class="overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm">
        <table class="w-full min-w-[720px] text-left text-sm">
          <thead class="bg-slate-50 text-[11px] font-black uppercase tracking-[0.16em] text-slate-500">
            <tr>
              <th class="px-5 py-4">Nhân sự</th>
              <th class="px-5 py-4">Khoa phòng</th>
              <th class="px-5 py-4">Vai trò</th>
              <th class="px-5 py-4 text-center">Trạng thái</th>
            </tr>
          </thead>
          <tbody class="divide-y divide-slate-100">
            <tr v-for="member in staff" :key="member.id">
              <td class="px-5 py-4 font-bold text-slate-950">{{ member.name }}</td>
              <td class="px-5 py-4 text-slate-600">{{ member.department }}</td>
              <td class="px-5 py-4">
                <span class="rounded-full bg-red-50 px-2.5 py-1 text-xs font-black text-[#E31837]">{{ member.role }}</span>
              </td>
              <td class="px-5 py-4 text-center">
                <button
                  class="inline-flex items-center gap-1 rounded-md px-2.5 py-1 text-xs font-black"
                  :class="member.active ? 'bg-emerald-50 text-emerald-700' : 'bg-red-50 text-red-700'"
                  @click="member.active = !member.active"
                >
                  <component :is="member.active ? UserCheck : UserX" class="h-3.5 w-3.5" />
                  {{ member.active ? 'Đang hoạt động' : 'Tạm khóa' }}
                </button>
              </td>
            </tr>
          </tbody>
        </table>
      </article>

      <aside class="rounded-lg border border-slate-200 bg-white p-5 shadow-sm">
        <h3 class="text-base font-black text-slate-950">Ma trận quyền</h3>
        <div class="mt-4 space-y-3">
          <div v-for="permission in permissions" :key="permission[0]" class="rounded-md border border-slate-100 bg-slate-50 p-3">
            <p class="font-black text-slate-950">{{ permission[0] }}</p>
            <p class="mt-1 text-xs text-slate-500">{{ permission.slice(1).join(' · ') }}</p>
          </div>
        </div>
      </aside>
    </section>
  </div>
</template>
