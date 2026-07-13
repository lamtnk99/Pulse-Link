export interface GeoCentroid {
  latitude: number | null
  longitude: number | null
}

export interface Province {
  code: string
  name: string
  name_en: string | null
  full_name: string
  full_name_en: string | null
  code_name: string
  centroid: GeoCentroid
}

export interface Ward {
  code: string
  province_code: string
  name: string
  name_en: string | null
  full_name: string
  full_name_en: string | null
  code_name: string
}

export interface Hospital {
  id: number
  name: string
  code: string
  province_code: string
  province?: Province | null
  ward_code?: string | null
  ward?: Ward | null
  address: string
  latitude: number
  longitude: number
  contact_phone?: string | null
  contact_email?: string | null
  is_active?: boolean
}

export interface DashboardStats {
  active_alerts: number
  notified_donors: number
  committed_donors: number
  donated_donors?: number
  upcoming_events?: number
  scheduled_appointments?: number
  completed_appointments?: number
  verified_volume_ml?: number
}

export type DonationAppointmentStatus =
  | 'booked'
  | 'cancelled'
  | 'checked_in'
  | 'deferred'
  | 'completed'
  | 'no_show'

export interface PaginationMeta {
  current_page: number
  last_page: number
  per_page: number
  total: number
  from?: number | null
  to?: number | null
}

export interface PaginatedResponse<T> {
  data: T[]
  links?: Record<string, string | null>
  meta: PaginationMeta
}

export interface UploadResponse {
  data: {
    path: string
    url: string
  }
}

export type AdminPermission =
  | 'dashboard.view'
  | 'sos.activate'
  | 'events.manage'
  | 'posts.manage'
  | 'staff.manage'

export interface AdminUser {
  id: number
  name: string
  email: string
  phone?: string | null
  role: 'system_admin' | 'hospital_staff' | 'hospital_admin'
  hospital_id?: number | null
  hospital?: Hospital | null
  permissions: AdminPermission[]
  active: boolean
  scope_label: string
}

export interface Donor {
  id: number
  name: string
  phone?: string | null
  blood_type: string
  blood_type_verification_status?: 'unreported' | 'self_reported' | 'verified'
  blood_type_verified_at?: string | null
  hero_level: string
  province_code?: string | null
  province?: Province | null
  ward_code?: string | null
  ward?: Ward | null
  latitude?: number
  longitude?: number
}

export interface EmergencyRecipient {
  id: number
  wave: string
  distance_km: number
  donor: Donor
}

export interface EmergencyCommitment {
  id: number
  alert_id: string
  status: 'committed' | 'en_route' | 'donated' | 'cancelled' | 'not_needed'
  cancel_reason?: string | null
  latitude: number | null
  longitude: number | null
  eta_minutes: number | null
  donation_volume_ml?: number | null
  committed_at: string | null
  last_location_at: string | null
  donated_at?: string | null
  verified_at?: string | null
  verified_by?: number | null
  donation_history_id?: number | null
  blood_journey?: BloodJourney | null
  donor: Donor
}

export interface BloodJourneyStep {
  key: string
  label: string
  message?: string | null
  occurred_at?: string | null
  completed: boolean
}

export interface BloodJourney {
  id: string
  destination_type: 'patient' | 'reserve'
  current_step: string
  location_label?: string | null
  final_message?: string | null
  published_at?: string | null
  completed_at?: string | null
  verify_url?: string | null
  steps: BloodJourneyStep[]
}

export interface EmergencyAlert {
  id: string
  database_id: number
  required_blood_type: string
  compatibility_mode?: 'compatible' | 'exact'
  level: 'level1' | 'level2' | 'level3'
  units_needed: number
  status: string
  accepting_commitments?: boolean
  broadcast_stopped_at?: string | null
  message: string
  expires_at: string
  dispatch_summary: Record<string, number>
  hospital: Hospital
  recipients: EmergencyRecipient[]
  commitments: EmergencyCommitment[]
  created_at: string
}

export interface SosPayload {
  hospital_id: number
  required_blood_type: string
  compatibility_mode: 'compatible' | 'exact'
  level: 'level1' | 'level2' | 'level3'
  units_needed: number
  message: string
  expires_at: string
}

export interface DonationEvent {
  id: string
  drive_type?: 'in_hospital' | 'mobile'
  title: string
  organizer: string
  description: string | null
  starts_at: string
  ends_at: string
  location_name: string
  province_code: string
  province?: Province | null
  ward_code?: string | null
  ward?: Ward | null
  location: {
    latitude: number
    longitude: number
  }
  urgency: 'normal' | 'high'
  image_url: string | null
  slots_left: number
  booked: boolean
  appointment_status?: string | null
  is_published: boolean
  capacity: number
  booked_count: number
  hospital?: Hospital | null
  cancelled_at?: string | null
  cancel_reason?: string | null
  appointment_stats?: {
    booked: number
    checked_in: number
    deferred: number
    no_show: number
    completed: number
    cancelled: number
    total_volume_ml: number
  } | null
  appointments?: DonationAppointment[]
}

export interface DonationAppointment {
  id: string
  status: DonationAppointmentStatus
  booked_at: string | null
  checked_in_at?: string | null
  cancelled_at?: string | null
  cancel_reason?: string | null
  completed_at?: string | null
  no_show_at?: string | null
  volume_ml?: number | null
  screening_status?: 'pending' | 'eligible' | 'ineligible' | null
  screening_notes?: string | null
  result_summary?: string | null
  result_published_at?: string | null
  certificate?: {
    id: string
    certificate_id: string
    certificate_title?: string | null
    certificate_issued_at?: string | null
    certificate_verify_url?: string | null
    donation_type?: string | null
  } | null
  user?: Donor | null
  event?: DonationEvent
}

export interface CommunityPost {
  id: string
  slug: string
  title: string
  excerpt: string | null
  content: string
  image_url: string | null
  status: 'draft' | 'published'
  published_at: string | null
  audience_type: 'all' | 'blood_type' | 'hero_level' | 'province'
  audience_label: string
  target_blood_type?: string | null
  target_hero_level?: string | null
  province_code?: string | null
  province?: Province | null
  ward_code?: string | null
  ward?: Ward | null
  hospital?: Hospital | null
  views_count: number
  shares_count: number
}

export interface BloodStock {
  id: number
  hospital_id: number
  blood_type: string
  volume_ml: number
  received_date: string
  expiry_date: string
  status: 'processing' | 'available' | 'used' | 'expired' | 'allocated' | 'discarded'
  donation_history_id?: number | null
  donation_history?: {
    id: number
    certificate_id: string
    user?: {
      id: number
      name: string
    } | null
  } | null
  notes?: string | null
}

export interface BloodSafetyThreshold {
  id: number
  hospital_id: number
  blood_type: string
  min_units: number
}

export interface BloodDemandForecast {
  blood_type: string
  predicted_volume_ml: number
  confidence_score: number
  explanation: string
}

export interface SmartAlert {
  id: number
  hospital_id: number
  blood_type: string
  current_units: number
  threshold_units: number
  status: 'active' | 'resolved' | 'mobilized'
  triggered_at: string
  resolved_at?: string | null
}
