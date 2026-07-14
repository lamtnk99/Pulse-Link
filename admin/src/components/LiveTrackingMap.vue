<script setup lang="ts">
import L from 'leaflet'
import { onBeforeUnmount, onMounted, ref, watch } from 'vue'
import type { EmergencyAlert, EmergencyCommitment } from '../types'

const props = defineProps<{
  alert: EmergencyAlert | null
  commitments: EmergencyCommitment[]
  loading: boolean
  selectedCommitmentId?: number | null
}>()

const emit = defineEmits<{
  selectCommitment: [commitment: EmergencyCommitment]
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

function escapeHtml(value: string) {
  return value.replace(/[&<>'"]/g, (character) => ({
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    "'": '&#39;',
    '"': '&quot;',
  })[character] ?? character)
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

watch(() => [props.alert, props.commitments, props.selectedCommitmentId], renderMarkers, { deep: true })

function renderMarkers() {
  if (!map || !layerGroup) return
  layerGroup.clearLayers()

  const hospital = props.alert?.hospital
  if (hospital) {
    const hospitalPoint: L.LatLngExpression = [hospital.latitude, hospital.longitude]
    const hospitalIcon = L.divIcon({
      className: 'sos-hospital-marker',
      html: '<span class="sos-hospital-marker__pin"><span class="sos-hospital-marker__cross"></span></span>',
      iconSize: [38, 38],
      iconAnchor: [19, 19],
      popupAnchor: [0, -22],
    })
    const safeHospitalName = escapeHtml(hospital.name)
    const safeHospitalAddress = escapeHtml(hospital.address)

    L.circle(hospitalPoint, {
      radius: 5000,
      color: '#dc2626',
      fillColor: '#ef4444',
      fillOpacity: 0.08,
      weight: 2,
    }).addTo(layerGroup)
    L.marker(hospitalPoint, { icon: hospitalIcon, title: hospital.name })
      .bindPopup(`<strong>${safeHospitalName}</strong><br>${safeHospitalAddress}`)
      .addTo(layerGroup)
    map.setView(hospitalPoint, 12)
  }

  const mappedCommitments = props.commitments.filter(
    (commitment) => commitment.latitude !== null && commitment.longitude !== null,
  )
  const showEveryLabel = mappedCommitments.length <= 8

  mappedCommitments.forEach((commitment) => {
    const point: L.LatLngExpression = [Number(commitment.latitude), Number(commitment.longitude)]
    const isSelected = commitment.id === props.selectedCommitmentId
    const isEnRoute = commitment.status === 'en_route'
    const marker = L.circleMarker(point, {
      radius: isSelected ? 11 : (isEnRoute ? 9 : 7),
      color: commitment.status === 'cancelled' ? '#94a3b8' : (isSelected ? '#e31837' : '#059669'),
      fillColor: commitment.status === 'cancelled' ? '#cbd5e1' : (isSelected ? '#fb7185' : '#10b981'),
      fillOpacity: 0.9,
      weight: 2,
    })

    const donorLabel = `${commitment.donor?.name ?? 'Tình nguyện viên'} (${commitment.donor?.blood_type ?? '--'})`
    const safeDonorLabel = escapeHtml(donorLabel)
    if (showEveryLabel || isSelected || isEnRoute) {
      marker.bindTooltip(donorLabel, {
        permanent: true,
        direction: 'top',
        offset: [0, -10],
        className: isSelected ? 'sos-donor-label sos-donor-label--selected' : 'sos-donor-label',
      })
    } else {
      marker.bindTooltip(donorLabel, { direction: 'top', className: 'sos-donor-label' })
    }

    marker
      .bindPopup(`<strong>${safeDonorLabel}</strong><br>${statusLabels[commitment.status]}${commitment.eta_minutes ? `<br>ETA ${commitment.eta_minutes} phút` : ''}`)
      .on('click', () => emit('selectCommitment', commitment))
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
    <div ref="mapEl" class="relative z-0 h-[500px]"></div>
  </section>
</template>

<style>
.sos-donor-label {
  border: 0;
  border-radius: 0.45rem;
  background: #0f172a;
  box-shadow: 0 4px 12px rgb(15 23 42 / 22%);
  color: white;
  font-size: 11px;
  font-weight: 800;
  padding: 0.35rem 0.55rem;
  white-space: nowrap;
}

.sos-donor-label::before {
  display: none;
}

.sos-donor-label--selected {
  background: #e31837;
}

.sos-hospital-marker {
  border: 0;
  background: transparent;
}

.sos-hospital-marker__pin {
  position: relative;
  display: grid;
  width: 38px;
  height: 38px;
  place-items: center;
  border: 3px solid white;
  border-radius: 999px;
  background: #e31837;
  box-shadow: 0 5px 15px rgb(127 29 29 / 35%);
}

.sos-hospital-marker__pin::before {
  position: absolute;
  inset: -7px;
  border: 2px solid rgb(227 24 55 / 35%);
  border-radius: inherit;
  content: '';
}

.sos-hospital-marker__cross,
.sos-hospital-marker__cross::before {
  display: block;
  width: 17px;
  height: 5px;
  border-radius: 2px;
  background: white;
  content: '';
}

.sos-hospital-marker__cross::before {
  transform: rotate(90deg);
}
</style>
