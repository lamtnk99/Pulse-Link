export interface BloodStock {
  group: 'O' | 'A' | 'B' | 'AB';
  rh: '+' | '-';
  units: number;
  criticalLimit: number;
}

export interface DonationEvent {
  id: string;
  name: string;
  date: string;
  time: string;
  location: string;
  targetUnits: number;
  registeredDonors: number;
  incentives: string;
  publishToApp: boolean;
  status: 'Nháp' | 'Đang diễn ra' | 'Đã kết thúc';
}

export interface CommunityPost {
  id: string;
  title: string;
  content: string;
  image?: string;
  targetAudience: string;
  views: number;
  shares: number;
  commendations: number;
  status: 'Đã xuất bản' | 'Bản nháp';
  date: string;
}

export interface StaffAccount {
  id: string;
  name: string;
  department: string;
  role: 'Super Admin / Director' | 'ER Doctor / Surgeon' | 'Coordinator / Nurse';
  status: 'Đang hoạt động' | 'Tạm khóa';
}

export interface SOSState {
  isActive: boolean;
  timestamp: string;
  patientInfo?: string;
  requiredBloodType?: string;
  location?: string;
}
