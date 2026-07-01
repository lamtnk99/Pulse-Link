export interface DonorProfile {
  name: string;
  bloodType: string;
  heroLevel: string;
  badgeTitle: string;
  totalDonations: number;
  lastDonationDate: string; // ISO string
  points: number;
  eligibleDays: number;
}

export interface DonationEvent {
  id: string;
  title: string;
  organizer: string;
  date: string;
  time: string;
  location: string;
  distance: string;
  urgency: 'high' | 'normal';
  image: string;
  slotsLeft: number;
  booked?: boolean;
}

export interface PastDonation {
  id: string;
  date: string;
  location: string;
  volumeml: number;
  bloodType: string;
  certificateId: string;
  status: 'verified' | 'pending';
  notes?: string;
}

export interface FlutterWidgetInfo {
  name: string;
  type: string;
  description: string;
  children?: FlutterWidgetInfo[];
  code: string;
}
