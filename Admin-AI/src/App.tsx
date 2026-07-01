import React, { useState, useEffect } from 'react';
import {
  LayoutDashboard,
  AlertTriangle,
  CalendarRange,
  FileText,
  ShieldAlert,
  Building,
  Bell,
  Clock,
  Code,
  User,
  ChevronDown
} from 'lucide-react';

import { BloodStock, DonationEvent, CommunityPost, StaffAccount } from './types';
import DashboardOverview from './components/DashboardOverview';
import EmergencyResponse from './components/EmergencyResponse';
import DonationScheduler from './components/DonationScheduler';
import CommunityCMS from './components/CommunityCMS';
import RBACPanel from './components/RBACPanel';
import VueCodeViewer from './components/VueCodeViewer';

export default function App() {
  const [currentTab, setCurrentTab] = useState<'dashboard' | 'sos' | 'events' | 'community' | 'rbac'>('dashboard');
  const [sosActive, setSosActive] = useState(true);
  const [isVueCodeOpen, setIsVueCodeOpen] = useState(false);

  // Dynamic system timestamp state
  const [currentTime, setCurrentTime] = useState(new Date());

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const formattedTime = currentTime.toLocaleString('vi-VN', {
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
    hour12: false
  });

  // Share states so adjustments in one tab affect others
  const [bloodStocks, setBloodStocks] = useState<BloodStock[]>([
    { group: 'O', rh: '+', units: 84, criticalLimit: 25 },
    { group: 'O', rh: '-', units: 12, criticalLimit: 25 }, // CRITICAL
    { group: 'A', rh: '+', units: 62, criticalLimit: 25 },
    { group: 'A', rh: '-', units: 35, criticalLimit: 25 },
    { group: 'B', rh: '+', units: 98, criticalLimit: 25 },
    { group: 'B', rh: '-', units: 18, criticalLimit: 25 }, // CRITICAL
    { group: 'AB', rh: '+', units: 54, criticalLimit: 25 },
    { group: 'AB', rh: '-', units: 28, criticalLimit: 25 }
  ]);

  const [events, setEvents] = useState<DonationEvent[]>([
    {
      id: 'EV-01',
      name: 'Hành trình Đỏ - Kết nối cộng đồng hiến máu',
      date: '2026-07-15',
      time: '08:00',
      location: 'Sảnh Đa năng Bệnh viện Trung ương',
      targetUnits: 150,
      registeredDonors: 112,
      incentives: 'Gói quà tặng dinh dưỡng hạng A + Tiền mặt hỗ trợ đi lại + Cấp giấy chứng nhận hiến máu lưu giữ trọn đời.',
      publishToApp: true,
      status: 'Đang diễn ra'
    },
    {
      id: 'EV-02',
      name: 'Giọt máu nghĩa tình - Chi nhánh Quận 3',
      date: '2026-08-01',
      time: '07:30',
      location: 'Ủy ban Nhân dân Quận 3',
      targetUnits: 100,
      registeredDonors: 45,
      incentives: 'Gói hỗ trợ dinh dưỡng cơ bản + Hỗ trợ xét nghiệm nhóm máu miễn phí.',
      publishToApp: true,
      status: 'Nháp'
    }
  ]);

  const [posts, setPosts] = useState<CommunityPost[]>([
    {
      id: 'POST-01',
      title: 'Báo động đỏ: Cần gấp 10 người hiến máu O- cứu sản phụ nguy kịch',
      content: 'Bệnh viện đang tiếp nhận một ca sinh khó mất máu cấp, sản phụ mang nhóm máu hiếm O- cần truyền gấp 10 đơn vị máu dự trữ để giữ tính mạng. Kính mong các tình nguyện viên khu vực lân cận liên hệ ngay phòng cấp cứu.',
      targetAudience: 'Chỉ nhắm mục tiêu Nhóm máu O- (Khẩn cấp)',
      views: 1840,
      shares: 320,
      commendations: 145,
      status: 'Đã xuất bản',
      date: '30-06-2026'
    },
    {
      id: 'POST-02',
      title: 'Hành trình hiến máu tiếp sức mùa dịch cùng y bác sĩ Trung ương',
      content: 'Chương trình tri ân các y bác sĩ và chiến dịch tình nguyện hiến máu thường niên. Kính mời toàn thể nhân viên y tế và thân nhân tham gia tiếp sức.',
      targetAudience: 'Gửi đến toàn bộ Người dùng Ứng dụng',
      views: 950,
      shares: 120,
      commendations: 80,
      status: 'Đã xuất bản',
      date: '28-06-2026'
    },
    {
      id: 'POST-03',
      title: 'Kỷ niệm ngày Quốc tế Hiến máu: Vinh danh 100 tình nguyện viên vàng',
      content: 'Sự kiện vinh danh các cá nhân xuất sắc có thành tích trên 15 lần hiến máu tình nguyện cứu người.',
      targetAudience: 'Toàn bộ Người dùng Ứng dụng',
      views: 2400,
      shares: 540,
      commendations: 450,
      status: 'Đã xuất bản',
      date: '14-06-2026'
    }
  ]);

  const [staff, setStaff] = useState<StaffAccount[]>([
    { id: '1', name: 'GS. Nguyễn Minh', department: 'Ban Giám đốc', role: 'Super Admin / Director', status: 'Đang hoạt động' },
    { id: '2', name: 'BS. Trần Tiến', department: 'Khoa Cấp cứu & Phẫu thuật', role: 'ER Doctor / Surgeon', status: 'Đang hoạt động' },
    { id: '3', name: 'ĐD. Lê Thị Hồng', department: 'Trung tâm Truyền máu', role: 'Coordinator / Nurse', status: 'Đang hoạt động' },
    { id: '4', name: 'BS. Phạm Vũ Hoàng', department: 'Khoa Hồi sức tích cực', role: 'ER Doctor / Surgeon', status: 'Tạm khóa' }
  ]);

  const handleAddEvent = (newEvent: DonationEvent) => {
    setEvents(prev => [newEvent, ...prev]);
  };

  const handleAddPost = (newPost: CommunityPost) => {
    setPosts(prev => [newPost, ...prev]);
  };

  const handleTriggerSOS = () => {
    setSosActive(true);
    // Automatically switch to SOS view to let users witness live dispatch
    setCurrentTab('sos');
  };

  return (
    <div className="min-h-screen bg-[#F8FAFC] font-sans flex text-gray-900 overflow-hidden select-none">
      {/* 1. GLOBAL SYSTEM SHELL - LEFT SIDEBAR */}
      <aside className="w-68 bg-[#1A1A1A] text-white flex flex-col shrink-0 border-r border-neutral-800 hidden md:flex">
        {/* Brand identity & blood drop icon */}
        <div className="h-16 flex items-center px-6 border-b border-neutral-800 space-x-3 bg-black/10">
          <div className="relative flex items-center justify-center">
            <div className="absolute w-5.5 h-5.5 bg-[#E31837] rounded-full animate-ping opacity-60"></div>
            <span className="relative text-[#E31837] text-2xl animate-pulse select-none">🩸</span>
          </div>
          <div>
            <span className="text-lg font-black tracking-wider uppercase text-white">
              PULSE <span className="text-[#E31837]">LINK</span>
            </span>
            <p className="text-[8px] text-gray-500 font-bold tracking-widest uppercase mt-0.5">Admin Portal</p>
          </div>
        </div>

        {/* Sidebar Nav items */}
        <nav className="flex-1 px-4 py-6 space-y-1.5 overflow-y-auto">
          {/* Dashboard Tab */}
          <button
            onClick={() => setCurrentTab('dashboard')}
            className={`w-full flex items-center px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200 text-left cursor-pointer ${
              currentTab === 'dashboard'
                ? 'bg-white/10 text-white border-l-4 border-[#E31837] pl-3 font-semibold'
                : 'text-slate-400 hover:bg-white/5 hover:text-white'
            }`}
          >
            <LayoutDashboard className="w-5 h-5 mr-3 shrink-0 opacity-70" />
            <span>Tổng quan</span>
          </button>

          {/* SOS Tab with pulse badge */}
          <button
            onClick={() => setCurrentTab('sos')}
            className={`w-full flex items-center px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200 text-left cursor-pointer ${
              currentTab === 'sos'
                ? 'bg-white/10 text-white border-l-4 border-[#E31837] pl-3 font-semibold'
                : 'text-slate-400 hover:bg-white/5 hover:text-white'
            }`}
          >
            <AlertTriangle className="w-5 h-5 mr-3 shrink-0 text-amber-500" />
            <span>Cấp cứu SOS</span>
            {sosActive && (
              <span className="ml-auto bg-[#E31837] text-white text-[10px] font-bold px-1.5 py-0.5 rounded-full animate-pulse">
                2
              </span>
            )}
          </button>

          {/* Events Tab */}
          <button
            onClick={() => setCurrentTab('events')}
            className={`w-full flex items-center px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200 text-left cursor-pointer ${
              currentTab === 'events'
                ? 'bg-white/10 text-white border-l-4 border-[#E31837] pl-3 font-semibold'
                : 'text-slate-400 hover:bg-white/5 hover:text-white'
            }`}
          >
            <CalendarRange className="w-5 h-5 mr-3 shrink-0 opacity-70" />
            <span>Lịch hiến máu</span>
          </button>

          {/* Community Tab */}
          <button
            onClick={() => setCurrentTab('community')}
            className={`w-full flex items-center px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200 text-left cursor-pointer ${
              currentTab === 'community'
                ? 'bg-white/10 text-white border-l-4 border-[#E31837] pl-3 font-semibold'
                : 'text-slate-400 hover:bg-white/5 hover:text-white'
            }`}
          >
            <FileText className="w-5 h-5 mr-3 shrink-0 opacity-70" />
            <span>Bài viết cộng đồng</span>
          </button>

          {/* RBAC Tab */}
          <button
            onClick={() => setCurrentTab('rbac')}
            className={`w-full flex items-center px-4 py-3 rounded-lg text-sm font-medium transition-all duration-200 text-left cursor-pointer ${
              currentTab === 'rbac'
                ? 'bg-white/10 text-white border-l-4 border-[#E31837] pl-3 font-semibold'
                : 'text-slate-400 hover:bg-white/5 hover:text-white'
            }`}
          >
            <ShieldAlert className="w-5 h-5 mr-3 shrink-0 opacity-70" />
            <span>Nhân sự & RBAC</span>
          </button>
        </nav>

        {/* Operational 24/7 indicator widget from Geometric Balance */}
        <div className="px-4 py-1">
          <div className="bg-gradient-to-br from-neutral-800 to-neutral-900 rounded-xl p-3.5 border border-white/5 text-center">
            <p className="text-slate-400 text-[11px] mb-2 font-medium">Hệ thống vận hành 24/7</p>
            <div className="flex justify-center gap-1.5">
              <div className="w-1.5 h-1.5 rounded-full bg-emerald-500"></div>
              <div className="w-1.5 h-1.5 rounded-full bg-emerald-500"></div>
              <div className="w-1.5 h-1.5 rounded-full bg-emerald-500 animate-pulse"></div>
            </div>
          </div>
        </div>

        {/* Vue 3 Code Viewer Callout inside sidebar */}
        <div className="p-4 border-t border-neutral-800 bg-black/10">
          <button
            onClick={() => setIsVueCodeOpen(true)}
            className="w-full bg-emerald-500/10 hover:bg-emerald-500/20 text-emerald-400 border border-emerald-500/20 py-2 px-3 rounded-xl text-[10px] font-mono font-bold transition-all flex items-center justify-center space-x-1.5 cursor-pointer"
          >
            <Code className="w-3.5 h-3.5 animate-pulse" />
            <span>LẤY MÃ NGUỒN VUE 3</span>
          </button>
        </div>

        {/* Sidebar Profile Card */}
        <div className="p-4 border-t border-neutral-800 bg-black/20 flex items-center space-x-3.5">
          <div className="w-9 h-9 rounded-full bg-red-600 flex items-center justify-center text-white font-extrabold shadow-sm text-xs">
            NM
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-xs font-bold text-white truncate">GS. Nguyễn Minh</p>
            <p className="text-[10px] text-gray-500 truncate font-semibold">Super Admin / Director</p>
          </div>
        </div>
      </aside>

      {/* MAIN APP SHELL CONTENT AREA */}
      <div className="flex-1 flex flex-col min-w-0 overflow-hidden">
        {/* 2. TOP HEADER */}
        <header className="h-16 bg-white border-b border-gray-200 flex items-center justify-between px-6 sm:px-8 shrink-0 z-10 shadow-3xs">
          {/* Hospital Brand Node */}
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 rounded-lg bg-red-50 flex items-center justify-center text-[#E31837]">
              <Building className="w-4.5 h-4.5" />
            </div>
            <div>
              <h1 className="text-xs sm:text-sm font-black text-gray-800 uppercase tracking-wide">
                Bệnh viện Đa khoa Trung ương
              </h1>
              <p className="text-[8px] text-gray-400 font-bold uppercase tracking-widest mt-0.5">Sở Y tế Thành phố</p>
            </div>
          </div>

          <div className="flex items-center space-x-4">
            {/* Live dynamic clock */}
            <div className="hidden lg:flex items-center space-x-2 text-[10px] font-mono text-gray-500 bg-gray-50 border border-gray-100 px-3 py-1.5 rounded-lg">
              <Clock className="w-3.5 h-3.5 text-gray-400" />
              <span>{formattedTime}</span>
            </div>

            {/* Notification system alert count */}
            <button className="p-1.5 rounded-lg text-gray-400 hover:text-gray-900 hover:bg-gray-100 transition-colors relative cursor-pointer" title="Cập nhật hệ thống">
              <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[#E31837] animate-ping"></span>
              <span className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[#E31837]"></span>
              <Bell className="w-5 h-5" />
            </button>

            {/* Floating primary action button - Trigger SOS */}
            <button
              onClick={handleTriggerSOS}
              className="bg-[#E31837] hover:bg-red-700 active:scale-95 text-white font-extrabold text-[10px] tracking-wider uppercase px-3.5 py-2 rounded-lg shadow-md shadow-red-500/20 flex items-center space-x-2 transition-all cursor-pointer"
              title="Phát báo động SOS toàn tỉnh"
            >
              <AlertTriangle className="w-3.5 h-3.5 animate-bounce" />
              <span>+ PHÁT LỆNH SOS</span>
            </button>

            {/* Micro developer tools toggle inside UI */}
            <button
              onClick={() => setIsVueCodeOpen(true)}
              className="bg-emerald-500/10 hover:bg-emerald-500/20 border border-emerald-500/20 text-emerald-600 font-bold text-[10px] px-3 py-2 rounded-lg flex items-center space-x-1 cursor-pointer"
              title="Xem code Vue 3 Composition API"
            >
              <Code className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">CODE VUE 3</span>
            </button>

            {/* User Dropdown Profile mock */}
            <div className="flex items-center space-x-1.5 pl-2 border-l border-gray-200">
              <div className="w-8 h-8 rounded-full bg-neutral-900 flex items-center justify-center text-white text-xs font-bold">
                A
              </div>
              <ChevronDown className="w-3.5 h-3.5 text-gray-400 hidden sm:block" />
            </div>
          </div>
        </header>

        {/* MOBILE NAVIGATION BAR (Shown only on small screens) */}
        <div className="bg-[#1A1A1A] text-white p-2.5 flex items-center justify-around md:hidden overflow-x-auto shrink-0 border-b border-neutral-800 text-[10px] font-bold">
          <button
            onClick={() => setCurrentTab('dashboard')}
            className={`flex flex-col items-center p-1.5 rounded-lg ${currentTab === 'dashboard' ? 'text-[#E31837]' : 'text-neutral-400'}`}
          >
            <LayoutDashboard className="w-4 h-4 mb-0.5" />
            <span>Tổng quan</span>
          </button>
          <button
            onClick={() => setCurrentTab('sos')}
            className={`flex flex-col items-center p-1.5 rounded-lg relative ${currentTab === 'sos' ? 'text-[#E31837]' : 'text-neutral-400'}`}
          >
            {sosActive && <span className="absolute top-0 right-1 w-2 h-2 rounded-full bg-[#E31837] animate-ping"></span>}
            <AlertTriangle className="w-4 h-4 mb-0.5" />
            <span>SOS</span>
          </button>
          <button
            onClick={() => setCurrentTab('events')}
            className={`flex flex-col items-center p-1.5 rounded-lg ${currentTab === 'events' ? 'text-[#E31837]' : 'text-neutral-400'}`}
          >
            <CalendarRange className="w-4 h-4 mb-0.5" />
            <span>Sự kiện</span>
          </button>
          <button
            onClick={() => setCurrentTab('community')}
            className={`flex flex-col items-center p-1.5 rounded-lg ${currentTab === 'community' ? 'text-[#E31837]' : 'text-neutral-400'}`}
          >
            <FileText className="w-4 h-4 mb-0.5" />
            <span>Bài viết</span>
          </button>
          <button
            onClick={() => setCurrentTab('rbac')}
            className={`flex flex-col items-center p-1.5 rounded-lg ${currentTab === 'rbac' ? 'text-[#E31837]' : 'text-neutral-400'}`}
          >
            <ShieldAlert className="w-4 h-4 mb-0.5" />
            <span>Nhân sự</span>
          </button>
        </div>

        {/* WORKSPACE AREA */}
        <main className="flex-1 overflow-y-auto p-4 sm:p-8 relative">
          {/* TAB ROUTING COMPONENT SWITCH */}
          {currentTab === 'dashboard' && (
            <DashboardOverview
              sosActive={sosActive}
              bloodStocks={bloodStocks}
              setBloodStocks={setBloodStocks}
            />
          )}

          {currentTab === 'sos' && (
            <EmergencyResponse
              sosActive={sosActive}
              onToggleSOS={() => setSosActive(!sosActive)}
            />
          )}

          {currentTab === 'events' && (
            <DonationScheduler
              events={events}
              onAddEvent={handleAddEvent}
            />
          )}

          {currentTab === 'community' && (
            <CommunityCMS
              posts={posts}
              onAddPost={handleAddPost}
            />
          )}

          {currentTab === 'rbac' && (
            <RBACPanel
              staff={staff}
              setStaff={setStaff}
            />
          )}
        </main>
      </div>

      {/* 3. VUE 3 SOURCE CODE DRAWER COMPONENT */}
      <VueCodeViewer
        isOpen={isVueCodeOpen}
        onClose={() => setIsVueCodeOpen(false)}
        defaultModule={
          currentTab === 'dashboard' ? 'dashboard' :
          currentTab === 'sos' ? 'sos' :
          currentTab === 'events' ? 'events' :
          currentTab === 'community' ? 'community' : 'rbac'
        }
      />
    </div>
  );
}
