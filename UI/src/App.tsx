import React, { useState } from 'react';
import { 
  Heart, 
  Smartphone, 
  Sparkles, 
  RefreshCw, 
  Info, 
  Award, 
  Droplet,
  Settings,
  Share2
} from 'lucide-react';
import PhoneShell from './components/PhoneShell';
import FlutterMappingPanel from './components/FlutterMappingPanel';
import { INITIAL_PROFILE, MOCK_EVENTS, MOCK_HISTORY } from './data/mockData';
import { DonorProfile, DonationEvent, PastDonation } from './types';

export default function App() {
  const [profile, setProfile] = useState<DonorProfile>(INITIAL_PROFILE);
  const [events, setEvents] = useState<DonationEvent[]>(MOCK_EVENTS);
  const [pastDonations, setPastDonations] = useState<PastDonation[]>(MOCK_HISTORY);
  const [activeSelectedWidget, setActiveSelectedWidget] = useState<string>('Hero Pass Card');
  const [appMode, setAppMode] = useState<'daily' | 'sos'>('daily');

  // Triggered when an event is booked or canceled
  const toggleBookEvent = (eventId: string) => {
    setEvents(prevEvents => 
      prevEvents.map(ev => {
        if (ev.id === eventId) {
          const isBooking = !ev.booked;
          return {
            ...ev,
            booked: isBooking,
            slotsLeft: isBooking ? ev.slotsLeft - 1 : ev.slotsLeft + 1
          };
        }
        return ev;
      })
    );
  };

  // Triggered when a new custom donation is logged in the history
  const addPastDonation = (newDonation: Omit<PastDonation, 'id' | 'status' | 'certificateId'>) => {
    const fresh: PastDonation = {
      id: `pd-${Date.now()}`,
      date: newDonation.date,
      location: newDonation.location,
      volumeml: newDonation.volumeml,
      bloodType: newDonation.bloodType,
      certificateId: `PL-${2026}-${Math.floor(1000 + Math.random() * 9000)}`,
      status: 'verified',
      notes: newDonation.notes
    };
    setPastDonations(prev => [fresh, ...prev]);
  };

  // Reset demo application state
  const handleReset = () => {
    setProfile(INITIAL_PROFILE);
    setEvents(MOCK_EVENTS);
    setPastDonations(MOCK_HISTORY);
    setActiveSelectedWidget('Hero Pass Card');
    setAppMode('daily');
  };

  return (
    <div className="min-h-screen bg-[#0d0d0d] text-neutral-100 flex flex-col font-sans selection:bg-red-600 selection:text-white">
      
      {/* Top Navigation Bar of the Workspace */}
      <header className="bg-neutral-950 border-b border-neutral-850 px-6 py-4 flex items-center justify-between sticky top-0 z-50">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-gradient-to-br from-red-600 to-red-800 flex items-center justify-center shadow-lg shadow-red-950/40 relative">
            <Heart className="w-5 h-5 text-white fill-white/10 animate-pulse" />
            <span className="absolute -bottom-0.5 -right-0.5 w-2 h-2 bg-emerald-400 rounded-full"></span>
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h1 className="text-base font-black tracking-tight text-white uppercase">Pulse Link</h1>
              <span className="text-[9px] bg-red-600/10 text-red-500 font-extrabold px-2 py-0.5 rounded-full border border-red-500/10 uppercase">Mobile UI Workspace</span>
            </div>
            <p className="text-[10px] text-neutral-400">Blood Donation & Emergency Dispatch Ecosystem</p>
          </div>
        </div>

        {/* Global Toolbar */}
        <div className="flex items-center gap-3">
          <button 
            onClick={handleReset}
            className="flex items-center gap-1.5 bg-neutral-900 border border-neutral-800 text-xs text-neutral-300 hover:text-white px-3.5 py-2 rounded-lg hover:bg-neutral-850 transition-colors active:scale-95"
            title="Khôi phục trạng thái ban đầu"
          >
            <RefreshCw className="w-3.5 h-3.5" />
            <span className="hidden sm:inline">Khởi động lại mô phỏng</span>
          </button>
          
          <div className="flex items-center gap-1.5 text-neutral-400 bg-neutral-900 border border-neutral-800 rounded-lg px-3 py-2 text-xs">
            <span className="w-2 h-2 bg-emerald-400 rounded-full"></span>
            <span className="font-semibold text-neutral-200">Môi trường xem trước</span>
          </div>
        </div>
      </header>

      {/* Main Container Layout */}
      <main className="flex-1 max-w-7xl w-full mx-auto p-4 md:p-6 grid grid-cols-1 lg:grid-cols-12 gap-6 items-start">
        
        {/* Left Side: Simulation Controls & User Context (3 Cols on Desktop) */}
        <section className="lg:col-span-3 space-y-6">
          
          {/* Quick Guide */}
          <div className="bg-neutral-900 border border-neutral-800 rounded-2xl p-5 space-y-3.5 shadow-sm">
            <h3 className="text-xs font-bold text-neutral-400 uppercase tracking-widest flex items-center gap-1.5">
              <Sparkles className="w-4 h-4 text-amber-500 fill-amber-500/10" />
              Pulse Link Studio
            </h3>
            <p className="text-[11.5px] text-neutral-400 leading-relaxed">
              Chào mừng bạn đến với môi trường thiết kế tương tác của <strong>Pulse Link</strong>. Ứng dụng tập trung vào tính tương trợ nhân đạo, được mô phỏng với đầy đủ logic điều phối.
            </p>
            <div className="space-y-2 pt-1">
              <div className="flex gap-2.5 text-xs">
                <span className="w-5 h-5 rounded-full bg-red-600/10 text-red-500 flex items-center justify-center font-bold shrink-0 text-[10px]">1</span>
                <span className="text-neutral-400 text-[11px] leading-relaxed">Thay đổi trực tiếp thông tin người dùng trong điện thoại (tên và nhóm máu) để cập nhật thẻ <strong>Hero Pass</strong>.</span>
              </div>
              <div className="flex gap-2.5 text-xs">
                <span className="w-5 h-5 rounded-full bg-red-600/10 text-red-500 flex items-center justify-center font-bold shrink-0 text-[10px]">2</span>
                <span className="text-neutral-400 text-[11px] leading-relaxed">Ấn nút <strong>Chứng nhận QR</strong> trên thẻ để mở chứng chỉ định danh điện tử có quét mã.</span>
              </div>
              <div className="flex gap-2.5 text-xs">
                <span className="w-5 h-5 rounded-full bg-red-600/10 text-red-500 flex items-center justify-center font-bold shrink-0 text-[10px]">3</span>
                <span className="text-neutral-400 text-[11px] leading-relaxed">Đăng ký sự kiện hiến máu hoặc thêm lịch sử đóng góp để mô phỏng sự tăng trưởng điểm số.</span>
              </div>
            </div>
          </div>

          {/* Quick Config Adjuster panel */}
          <div className="bg-neutral-900 border border-neutral-800 rounded-2xl p-5 space-y-4 shadow-sm">
            <h3 className="text-xs font-bold text-neutral-400 uppercase tracking-widest flex items-center gap-1.5">
              <Settings className="w-4 h-4 text-red-500" />
              Bảng kiểm thử nhanh
            </h3>
            
            <div className="space-y-3 text-xs">
              <div className="space-y-1">
                <label className="block text-neutral-400 text-[10.5px]">Tên hiệp sĩ hiển thị</label>
                <input 
                  type="text"
                  value={profile.name}
                  onChange={(e) => setProfile(prev => ({ ...prev, name: e.target.value }))}
                  className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-red-500 transition-colors"
                  placeholder="Nhập tên..."
                />
              </div>

              <div className="space-y-1">
                <label className="block text-neutral-400 text-[10.5px]">Nhóm máu</label>
                <div className="grid grid-cols-4 gap-1.5">
                  {['O+', 'O-', 'A+', 'B+', 'AB+'].map(type => (
                    <button
                      key={type}
                      onClick={() => setProfile(prev => ({ ...prev, bloodType: type }))}
                      className={`py-1.5 rounded-md font-bold text-[11px] transition-all border ${
                        profile.bloodType === type 
                          ? 'bg-red-600 text-white border-red-500' 
                          : 'bg-neutral-950 text-neutral-400 border-neutral-850 hover:bg-neutral-850'
                      }`}
                    >
                      {type}
                    </button>
                  ))}
                </div>
              </div>

              <div className="space-y-1.5 pt-2">
                <label className="block text-neutral-400 text-[10.5px]">Độ phục hồi sức khỏe</label>
                <div className="flex items-center gap-3">
                  <input 
                    type="range"
                    min="0"
                    max="84"
                    value={84 - profile.eligibleDays}
                    onChange={(e) => {
                      const daysPassed = Number(e.target.value);
                      setProfile(prev => ({ ...prev, eligibleDays: 84 - daysPassed }));
                    }}
                    className="flex-1 accent-red-600 h-1 bg-neutral-950 rounded-lg appearance-none cursor-pointer"
                  />
                  <span className="font-mono text-neutral-300 w-12 text-right">
                    {Math.round(((84 - profile.eligibleDays) / 84) * 100)}%
                  </span>
                </div>
                <span className="text-[9.5px] text-neutral-500 block leading-tight">Mô phỏng phục hồi huyết học sau {84 - profile.eligibleDays} ngày kể từ lần hiến cuối.</span>
              </div>

              {/* Simulation Mode Toggle inside Quick Config Panel */}
              <div className="space-y-2 pt-3 border-t border-neutral-850">
                <label className="block text-neutral-400 text-[10.5px] font-semibold uppercase tracking-wider">Chế độ hiển thị ứng dụng</label>
                <div className="grid grid-cols-2 gap-2">
                  <button
                    onClick={() => {
                      setAppMode('daily');
                      setActiveSelectedWidget('Hero Pass Card');
                    }}
                    className={`py-2 px-2.5 rounded-lg font-bold text-[11px] transition-all border flex items-center justify-center gap-1.5 ${
                      appMode === 'daily'
                        ? 'bg-neutral-800 text-white border-neutral-700 shadow-md'
                        : 'bg-neutral-950 text-neutral-500 border-neutral-900 hover:bg-neutral-900 hover:text-neutral-300'
                    }`}
                  >
                    <span>☀️ Daily Mode</span>
                  </button>
                  <button
                    onClick={() => {
                      setAppMode('sos');
                      setActiveSelectedWidget('Màn hình Khẩn cấp (SOS Mode)');
                    }}
                    className={`py-2 px-2.5 rounded-lg font-bold text-[11px] transition-all border flex items-center justify-center gap-1.5 ${
                      appMode === 'sos'
                        ? 'bg-red-950/60 text-red-400 border-red-500/50 shadow-md shadow-red-950/30 ring-1 ring-red-500/30'
                        : 'bg-neutral-950 text-neutral-500 border-neutral-900 hover:bg-red-950/20 hover:text-red-400'
                    }`}
                  >
                    <span className="w-1.5 h-1.5 bg-red-500 rounded-full animate-ping shrink-0"></span>
                    <span>🚨 SOS Mode</span>
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Quick Statistics Banner */}
          <div className="bg-gradient-to-br from-[#121212] to-[#1e0306] border border-red-950/40 rounded-2xl p-4 flex items-center justify-between shadow-sm relative overflow-hidden group">
            <div className="absolute right-0 bottom-0 w-16 h-16 bg-red-600/5 rounded-full blur-xl group-hover:scale-110 transition-transform"></div>
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-full bg-red-600/10 border border-red-500/20 flex items-center justify-center shrink-0">
                <Droplet className="w-5 h-5 text-red-500 fill-red-500/10" />
              </div>
              <div>
                <p className="text-[10px] text-neutral-400 font-medium">Bạn đã đóng góp tổng cộng</p>
                <h4 className="text-base font-extrabold text-white">{pastDonations.reduce((sum, item) => sum + item.volumeml, 0)} ml máu</h4>
              </div>
            </div>
          </div>

        </section>

        {/* Center Side: Interactive Mobile Device Frame (4 Cols on Desktop) */}
        <section className="lg:col-span-4 flex flex-col items-center">
          
          <div className="text-center mb-4 flex flex-col items-center gap-2">
            <span className="text-[10.5px] text-neutral-400 font-bold uppercase tracking-widest flex items-center justify-center gap-1.5">
              <Smartphone className="w-3.5 h-3.5 text-neutral-400 animate-pulse" />
              Thiết bị ảo Pulse Link
            </span>
            <div className="flex bg-neutral-900/90 border border-neutral-850 p-1 rounded-full text-xs shadow-inner">
              <button
                onClick={() => {
                  setAppMode('daily');
                  setActiveSelectedWidget('Hero Pass Card');
                }}
                className={`px-4 py-1.5 rounded-full font-bold transition-all text-[11px] flex items-center gap-1.5 cursor-pointer ${
                  appMode === 'daily'
                    ? 'bg-neutral-800 text-neutral-100 shadow-md border border-neutral-700/50'
                    : 'text-neutral-500 hover:text-neutral-300'
                }`}
              >
                <span>☀️ Chế độ Hàng ngày</span>
              </button>
              <button
                onClick={() => {
                  setAppMode('sos');
                  setActiveSelectedWidget('Màn hình Khẩn cấp (SOS Mode)');
                }}
                className={`px-4 py-1.5 rounded-full font-bold transition-all text-[11px] flex items-center gap-1.5 cursor-pointer ${
                  appMode === 'sos'
                    ? 'bg-red-600 text-white shadow-md shadow-red-900/50'
                    : 'text-neutral-500 hover:text-red-400'
                }`}
              >
                <span className="w-1 h-1 bg-white rounded-full animate-ping shrink-0"></span>
                <span>🚨 Báo động Đỏ SOS</span>
              </button>
            </div>
          </div>

          <PhoneShell 
            profile={profile}
            setProfile={setProfile}
            events={events}
            toggleBookEvent={toggleBookEvent}
            pastDonations={pastDonations}
            addPastDonation={addPastDonation}
            onSelectComponent={(name) => setActiveSelectedWidget(name)}
            activeSelectedWidget={activeSelectedWidget}
            appMode={appMode}
            setAppMode={setAppMode}
          />
        </section>

        {/* Right Side: Interactive Flutter Widget Mapping (5 Cols on Desktop) */}
        <section className="lg:col-span-5 h-[780px]">
          <FlutterMappingPanel 
            activeSelectedWidget={activeSelectedWidget}
            onSelectWidget={(name) => setActiveSelectedWidget(name)}
          />
        </section>

      </main>

      {/* Footer copyright */}
      <footer className="mt-auto border-t border-neutral-850 bg-neutral-950/40 py-6 text-center text-xs text-neutral-500">
        <p>© 2026 Pulse Link ecosystem. Built for Vietnamese Blood Donation mobilization campaign.</p>
        <p className="text-[10.5px] text-neutral-600 mt-1">Sát cánh cứu người - Mẹ Trái Đất chở che.</p>
      </footer>

    </div>
  );
}
