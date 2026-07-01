<script setup lang="ts">
const props = defineProps<{
  label: string
  value: number
  tone: 'red' | 'green' | 'blue' | 'slate'
}>()

const toneClasses = {
  red: 'border-red-100 bg-red-50 text-red-700',
  green: 'border-emerald-100 bg-emerald-50 text-emerald-700',
  blue: 'border-sky-100 bg-sky-50 text-sky-700',
  slate: 'border-slate-200 bg-white text-slate-700',
}
</script>

<template>
  <div class="rounded-lg border p-4 shadow-sm" :class="toneClasses[props.tone]">
    <p class="text-xs font-black uppercase tracking-wide opacity-70">{{ label }}</p>
    <p class="mt-2 text-3xl font-black tabular-nums">{{ value }}</p>
  </div>
</template>
