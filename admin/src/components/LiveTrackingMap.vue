<script setup lang="ts">
import L from 'leaflet'
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import type { EmergencyAlert, EmergencyCommitment } from '../types'

const props = defineProps<{
  alert: EmergencyAlert | null
  commitments: EmergencyCommitment[]
  loading: boolean
}>()

const mapEl = ref<HTMLElement | null>(null)
let map: L.Map | null = null
let layerGroup: L.LayerGroup | null = null

const statusLabels: Record<EmergencyCommitment['status'], string> = {
  committed: 'Đã cam kết',
  en_route: 'Đang di chuyển',
  donated: 'Đã hiến',
  cancelled: 'Đã hủy',
  not_needed: 'Ca đã đủ',
}

onMounted(() => {
  if (!mapEl.value) return
  map = L.map(mapEl.value, { zoomControl: false }).setView([10.7565, 106.6594], 12)
  L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
    attribution: '&copy; OpenStreetMap contributors',
  }).addTo(map)
  layerGroup = L.layerGroup().addTo(map)
  renderMarkers()
})

onBeforeUnmount(() => {
  map?.remove()
})

watch(() => [props.alert, props.commitments], renderMarkers, { deep: true })

function renderMarkers() {
  if (!map || !layerGroup) return
  layerGroup.clearLayers()

  const hospital = props.alert?.hospital
  if (hospital) {
    const hospitalPoint: L.LatLngExpression = [hospital.latitude, hospital.longitude]
    L.circle(hospitalPoint, {
      radius: 5000,
      color: '#dc2626',
      fillColor: '#ef4444',
      fillOpacity: 0.08,
      weight: 2,
    }).addTo(layerGroup)
    L.marker(hospitalPoint).bindPopup(`<strong>${hospital.name}</strong><br>${hospital.address}`).addTo(layerGroup)
    map.setView(hospitalPoint, 12)
  }

  props.commitments.forEach((commitment) => {
    if (!commitment.latitude || !commitment.longitude) return
    const point: L.LatLngExpression = [commitment.latitude, commitment.longitude]
    L.circleMarker(point, {
      radius: 8,
      color: commitment.status === 'cancelled' ? '#94a3b8' : '#059669',
      fillColor: commitment.status === 'cancelled' ? '#cbd5e1' : '#10b981',
      fillOpacity: 0.9,
      weight: 2,
    })
      .bindPopup(`<strong>${commitment.donor?.name}</strong><br>${statusLabels[commitment.status]}${commitment.cancel_reason ? `<br>${commitment.cancel_reason}` : ''}`)
      .addTo(layerGroup!)

    if (hospital) {
      L.polyline([[hospital.latitude, hospital.longitude], point], {
        color: '#10b981',
        weight: 3,
        opacity: 0.72,
      }).addTo(layerGroup!)
    }
  })
}
</script>

<template>
  <section class="relative z-0 overflow-hidden rounded-lg border border-slate-200 bg-white shadow-sm">
    <div class="flex items-center justify-between border-b border-slate-200 px-4 py-3">
      <div>
        <h2 class="text-base font-black text-slate-950">Bản đồ theo dõi tình nguyện viên</h2>
        <p class="text-sm text-slate-500">Người đã xác nhận, thời gian dự kiến và tuyến di chuyển.</p>
      </div>
      <span class="rounded-full bg-emerald-50 px-3 py-1 text-xs font-black uppercase text-emerald-700">
        {{ loading ? 'Đang đồng bộ' : 'Trực tuyến' }}
      </span>
    </div>
    <div ref="mapEl" class="relative z-0 h-[520px]"></div>
  </section>
</template>
