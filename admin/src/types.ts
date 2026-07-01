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
}

export interface DashboardStats {
  active_alerts: number
  notified_donors: number
  committed_donors: number
  arrived_donors: number
}

export interface Donor {
  id: number
  name: string
  blood_type: string
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
  status: 'committed' | 'en_route' | 'arrived' | 'cancelled'
  latitude: number | null
  longitude: number | null
  eta_minutes: number | null
  committed_at: string | null
  last_location_at: string | null
  donor: Donor
}

export interface EmergencyAlert {
  id: string
  database_id: number
  required_blood_type: string
  level: 'level1' | 'level2' | 'level3'
  units_needed: number
  status: string
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
  level: 'level1' | 'level2' | 'level3'
  units_needed: number
  message: string
  expires_at: string
}

export interface DonationEvent {
  id: string
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
