<script setup lang="ts"></script>

<template>
  <div class="min-h-screen bg-slate-50">
    <header class="border-b border-slate-200 bg-white">
      <div class="mx-auto flex max-w-7xl flex-col gap-4 px-5 py-5 md:flex-row md:items-center md:justify-between">
        <div>
          <p class="text-xs font-black uppercase tracking-[0.24em] text-red-600">Trung tâm Pulse Link</p>
          <h1 class="mt-1 text-2xl font-black tracking-tight text-slate-950">Bảng điều hành cấp cứu bệnh viện</h1>
          <p class="mt-1 text-sm text-slate-500">Điều phối SOS, cam kết hiến máu và tuyến di chuyển theo thời gian thực.</p>
        </div>
        <div class="flex flex-wrap items-center gap-3">
          <slot name="toolbar"></slot>
        </div>
      </div>
    </header>

    <main class="mx-auto flex max-w-7xl flex-col gap-5 px-5 py-6">
      <slot></slot>
    </main>
  </div>
</template>
