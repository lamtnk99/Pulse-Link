import React, { useState, useEffect, useRef } from 'react';
import { 
  Home, 
  MapPin, 
  History, 
  User, 
  Bell, 
  QrCode, 
  Award, 
  Calendar, 
  Clock, 
  Check, 
  Plus, 
  X, 
  Search, 
  Activity, 
  ChevronRight, 
  Droplet, 
  Sparkles,
  Info,
  AlertTriangle,
  Fingerprint,
  Compass
} from 'lucide-react';
import { motion, AnimatePresence } from 'motion/react';
import { DonorProfile, DonationEvent, PastDonation } from '../types';

interface PhoneShellProps {
  profile: DonorProfile;
  setProfile: React.Dispatch<React.SetStateAction<DonorProfile>>;
  events: DonationEvent[];
  toggleBookEvent: (eventId: string) => void;
  pastDonations: PastDonation[];
  addPastDonation: (donation: Omit<PastDonation, 'id' | 'status' | 'certificateId'>) => void;
  onSelectComponent: (componentName: string) => void;
  activeSelectedWidget: string;
  appMode: 'daily' | 'sos';
  setAppMode: React.Dispatch<React.SetStateAction<'daily' | 'sos'>>;
}

export default function PhoneShell({
  profile,
  setProfile,
  events,
  toggleBookEvent,
  pastDonations,
  addPastDonation,
  onSelectComponent,
  activeSelectedWidget,
  appMode,
  setAppMode
}: PhoneShellProps) {
  const [activeTab, setActiveTab] = useState<'home' | 'events' | 'history' | 'profile'>('home');
  const [currentTime, setCurrentTime] = useState<string>('09:41');
  const [showQRModal, setShowQRModal] = useState(false);
  const [showNotificationModal, setShowNotificationModal] = useState(false);
  const [showAddHistoryModal, setShowAddHistoryModal] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  
  // History form inputs
  const [historyLocation, setHistoryLocation] = useState('');
  const [historyVolume, setHistoryVolume] = useState(350);
  const [historyDate, setHistoryDate] = useState('');
  const [historyNotes, setHistoryNotes] = useState('');

  // Notifications state
  const [notifications, setNotifications] = useState([
    { id: 1, text: '🎉 Chúc mừng! Bạn đã đạt Cấp độ Bạc với 5 lần hiến máu.', time: 'Vừa xong', unread: true },
    { id: 2, text: '🔴 Khẩn cấp: Bệnh viện Chợ Rẫy đang cần gấp nhóm máu O+.', time: '2 giờ trước', unread: true },
    { id: 3, text: '📅 Đừng quên lịch hẹn hiến máu tại FPT Polytechnic sắp tới.', time: '1 ngày trước', unread: false },
  ]);

  // Hold to commit state
  const [holdProgress, setHoldProgress] = useState(0);
  const [isHolding, setIsHolding] = useState(false);
  const [isCommitted, setIsCommitted] = useState(false);

  // Holding progress loop (takes 3 seconds)
  useEffect(() => {
    let interval: NodeJS.Timeout;
    if (isHolding && !isCommitted) {
      interval = setInterval(() => {
        setHoldProgress((prev) => {
          if (prev >= 100) {
            setIsHolding(false);
            setIsCommitted(true);
            return 100;
          }
          return prev + 1;
        });
      }, 30);
    } else if (!isHolding && !isCommitted) {
      interval = setInterval(() => {
        setHoldProgress((prev) => {
          if (prev <= 0) {
            return 0;
          }
          return Math.max(0, prev - 4); // fast decay
        });
      }, 30);
    }
    return () => clearInterval(interval);
  }, [isHolding, isCommitted]);

  // Clock tick
  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      let hours = now.getHours().toString().padStart(2, '0');
      let minutes = now.getMinutes().toString().padStart(2, '0');
      setCurrentTime(`${hours}:${minutes}`);
    };
    updateTime();
    const timer = setInterval(updateTime, 60000);
    return () => clearInterval(timer);
  }, []);

  const totalVolume = pastDonations.reduce((sum, item) => sum + item.volumeml, 0);

  const handleAddHistory = (e: React.FormEvent) => {
    e.preventDefault();
    if (!historyLocation || !historyDate) return;
    
    addPastDonation({
      date: new Date(historyDate).toLocaleDateString('vi-VN'),
      location: historyLocation,
      volumeml: Number(historyVolume),
      bloodType: profile.bloodType,
      notes: historyNotes || 'Sức khỏe sau hiến tốt.'
    });

    // Reset Form
    setHistoryLocation('');
    setHistoryDate('');
    setHistoryNotes('');
    setShowAddHistoryModal(false);

    // Increase total donations in profile
    setProfile(prev => ({
      ...prev,
      totalDonations: prev.totalDonations + 1,
      points: prev.points + 250,
      eligibleDays: 84 // Reset countdown since they just donated
    }));
  };

  const markAllNotificationsRead = () => {
    setNotifications(prev => prev.map(n => ({ ...prev, ...n, unread: false })));
  };

  // Border highlight helper
  const isSelected = (name: string) => {
    return activeSelectedWidget === name ? 'ring-2 ring-red-500 ring-offset-2 ring-offset-neutral-950' : '';
  };

  return (
    <div className={`relative mx-auto w-full max-w-[390px] h-[780px] rounded-none border border-neutral-850 shadow-none overflow-hidden flex flex-col select-none transition-all duration-700 ${
      appMode === 'sos' ? 'bg-gradient-to-b from-[#2B0408] to-[#121212]' : 'bg-neutral-950'
    }`}>
      
      {/* System Status Bar */}
      <div className={`text-white px-6 pt-5 pb-2 flex justify-between items-center text-xs font-semibold tracking-tight z-40 transition-colors duration-700 ${
        appMode === 'sos' ? 'bg-transparent' : 'bg-neutral-950'
      }`}>
        <span>{currentTime}</span>
        <div className="flex items-center gap-1.5">
          {/* Signal */}
          <div className="flex items-end gap-0.5 h-2.5">
            <div className="w-0.5 h-1 bg-white rounded-full"></div>
            <div className="w-0.5 h-1.5 bg-white rounded-full"></div>
            <div className="w-0.5 h-2 bg-white rounded-full"></div>
            <div className="w-0.5 h-2.5 bg-white rounded-full"></div>
          </div>
          {/* Wifi */}
          <svg className="w-3.5 h-3.5 fill-current" viewBox="0 0 24 24">
            <path d="M12 21l-12-14.333c0 0 4.5-4.667 12-4.667s12 4.667 12 4.667l-12 14.333z" />
          </svg>
          {/* Battery */}
          <div className="w-5.5 h-3 border border-white/50 rounded px-0.5 py-px flex items-center justify-start">
            <div className="w-3.5 h-full bg-red-600 rounded-2xs"></div>
            <div className="w-0.5 h-1 bg-white/50 rounded-r-2xs ml-px"></div>
          </div>
        </div>
      </div>

      {appMode === 'daily' ? (
        <>
          {/* Screen Content Wrapper */}
          <div className="flex-1 overflow-y-auto px-4 pt-2 pb-24 scrollbar-thin scrollbar-thumb-neutral-800 scrollbar-track-transparent">
        
        {/* HEADER SECTION (Interactive Selectable) */}
        {activeTab === 'home' && (
          <div 
            id="mobile-header"
            onClick={() => onSelectComponent('Header')}
            className={`cursor-pointer transition-all p-2 rounded-xl ${isSelected('Header')} hover:bg-white/5`}
          >
            <div className="flex justify-between items-center mb-6">
              <div className="flex items-center gap-3">
                <div className="relative">
                  <img 
                    src="https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=150" 
                    alt="Avatar" 
                    className="w-11 h-11 rounded-full object-cover border border-red-500/30"
                  />
                  <span className="absolute bottom-0 right-0 w-3 h-3 bg-green-500 rounded-full border-2 border-neutral-950"></span>
                </div>
                <div>
                  <p className="text-[11px] text-neutral-400 font-medium">Chào Hiệp sĩ,</p>
                  <h4 className="text-[15px] font-bold text-neutral-100 flex items-center gap-1">
                    {profile.name} <Sparkles className="w-3.5 h-3.5 text-amber-500 fill-amber-500/20" />
                  </h4>
                </div>
              </div>
              
              {/* Notification icon with unread indicator */}
              <button 
                onClick={(e) => {
                  e.stopPropagation();
                  setShowNotificationModal(true);
                }}
                className="relative w-10 h-10 rounded-full bg-neutral-900 border border-neutral-800 flex items-center justify-center text-neutral-300 hover:text-white hover:bg-neutral-800 transition-colors"
              >
                <Bell className="w-5 h-5" />
                {notifications.some(n => n.unread) && (
                  <span className="absolute top-2 right-2 w-2 h-2 bg-red-500 rounded-full animate-pulse"></span>
                )}
              </button>
            </div>
          </div>
        )}

        {/* Dynamic Views based on bottom tabs */}
        <AnimatePresence mode="wait">
          {activeTab === 'home' && (
            <motion.div
              key="home-tab"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.15 }}
              className="space-y-5"
            >
              
              {/* HERO PASS CARD (Core Feature) */}
              <div 
                id="hero-pass-card"
                onClick={() => onSelectComponent('Hero Pass Card')}
                className={`cursor-pointer transition-all rounded-2xl ${isSelected('Hero Pass Card')}`}
              >
                <div className="relative w-full h-[180px] bg-gradient-to-br from-red-600 via-red-800 to-[#1e0306] p-5 rounded-2xl overflow-hidden shadow-lg shadow-red-950/20 group">
                  {/* Decorative background circle */}
                  <div className="absolute -top-12 -right-12 w-32 h-32 bg-white/5 rounded-full blur-xl group-hover:scale-110 transition-transform duration-500"></div>
                  <div className="absolute bottom-2 left-1/3 w-24 h-24 bg-red-500/10 rounded-full blur-2xl"></div>

                  <div className="flex justify-between items-start h-full flex-col">
                    <div className="w-full flex justify-between items-center">
                      <span className="text-[10px] font-bold tracking-widest text-red-200/80">PULSE LINK • HERO PASS</span>
                      <div className="flex items-center gap-1 bg-white/10 px-2 py-0.5 rounded-full backdrop-blur-md">
                        <Award className="w-3 h-3 text-amber-400" />
                        <span className="text-[9px] font-bold text-white uppercase">{profile.badgeTitle}</span>
                      </div>
                    </div>

                    <div className="w-full flex justify-between items-end">
                      <div>
                        <span className="text-[10px] text-red-200/60 block">Nhóm máu</span>
                        <h1 className="text-4xl font-extrabold text-white tracking-tight -mt-1">{profile.bloodType}</h1>
                      </div>
                      
                      <div className="text-right">
                        <p className="text-[11px] text-red-200/80 font-medium">Đã đóng góp</p>
                        <p className="text-lg font-bold text-white">{profile.totalDonations} lần hiến</p>
                      </div>
                    </div>

                    <div className="w-full pt-2 border-t border-white/10 flex justify-between items-center text-[10px] text-red-100/70">
                      <div>
                        <span className="text-[8px] text-red-300/60 uppercase block">Mã số định danh</span>
                        <span className="font-mono font-bold tracking-wider text-white">PL-8890-MINHTRI</span>
                      </div>

                      <button
                        onClick={(e) => {
                          e.stopPropagation();
                          setShowQRModal(true);
                        }}
                        className="flex items-center gap-1.5 bg-white/15 px-3 py-1.5 rounded-lg font-bold text-white hover:bg-white/25 active:scale-95 transition-all backdrop-blur-sm"
                      >
                        <QrCode className="w-3.5 h-3.5" />
                        <span>Chứng nhận QR</span>
                      </button>
                    </div>
                  </div>
                </div>
              </div>

              {/* HEALTH TRACKER WIDGET */}
              <div
                id="health-tracker"
                onClick={() => onSelectComponent('Health Tracker Widget')}
                className={`cursor-pointer transition-all rounded-2xl ${isSelected('Health Tracker Widget')}`}
              >
                <div className="bg-neutral-900 border border-neutral-800 rounded-2xl p-4 flex gap-4 items-center relative overflow-hidden">
                  <div className="absolute right-0 top-0 w-24 h-24 bg-red-500/5 rounded-full blur-xl"></div>
                  
                  {/* Circular progress circle */}
                  <div className="relative w-16 h-16 flex items-center justify-center shrink-0">
                    <svg className="w-16 h-16 transform -rotate-90">
                      <circle 
                        cx="32" 
                        cy="32" 
                        r="26" 
                        className="stroke-neutral-800" 
                        strokeWidth="5" 
                        fill="transparent" 
                      />
                      <circle 
                        cx="32" 
                        cy="32" 
                        r="26" 
                        className="stroke-red-600 transition-all duration-1000" 
                        strokeWidth="5" 
                        fill="transparent" 
                        strokeDasharray={2 * Math.PI * 26}
                        strokeDashoffset={2 * Math.PI * 26 * (1 - (84 - profile.eligibleDays) / 84)}
                        strokeLinecap="round"
                      />
                    </svg>
                    <div className="absolute flex flex-col items-center justify-center">
                      <span className="text-base font-extrabold text-white">{profile.eligibleDays}</span>
                      <span className="text-[7px] text-neutral-400 font-bold uppercase -mt-1">ngày</span>
                    </div>
                  </div>

                  <div className="flex-1 space-y-1">
                    <h5 className="text-xs font-bold text-white flex items-center gap-1.5">
                      <Activity className="w-3.5 h-3.5 text-red-500" />
                      Trạng thái phục hồi
                    </h5>
                    <p className="text-[10px] text-neutral-400 leading-relaxed">
                      {profile.eligibleDays === 0 
                        ? 'Cơ thể bạn đã phục hồi hoàn toàn! Sẵn sàng cho lần hiến máu tiếp theo.' 
                        : `Cần thêm ${profile.eligibleDays} ngày nữa để các chỉ số máu phục hồi lý tưởng nhất.`
                      }
                    </p>
                    <div className="flex items-center gap-1 text-[9px] text-green-400 font-semibold pt-0.5">
                      <Check className="w-3 h-3" />
                      <span>Thể tích hồng cầu đạt {92 + (84 - profile.eligibleDays) * 0.1}%</span>
                    </div>
                  </div>
                </div>
              </div>

              {/* UPCOMING EVENTS SECTION */}
              <div
                id="upcoming-events"
                onClick={() => onSelectComponent('Upcoming Events Section')}
                className={`cursor-pointer transition-all rounded-xl ${isSelected('Upcoming Events Section')}`}
              >
                <div className="space-y-3">
                  <div className="flex justify-between items-center px-1">
                    <h4 className="text-[13px] font-bold text-neutral-200 tracking-wide uppercase">Sự kiện hiến máu gần bạn</h4>
                    <button 
                      onClick={(e) => {
                        e.stopPropagation();
                        setActiveTab('events');
                      }}
                      className="text-xs text-red-500 font-semibold hover:text-red-400 flex items-center"
                    >
                      Xem tất cả <ChevronRight className="w-3.5 h-3.5" />
                    </button>
                  </div>

                  {/* Horizontal Scroll Area */}
                  <div className="flex gap-3.5 overflow-x-auto pb-2 scrollbar-none snap-x snap-mandatory">
                    {events.map((event) => (
                      <div 
                        key={event.id}
                        className="w-[245px] bg-neutral-900 border border-neutral-800 rounded-xl overflow-hidden shrink-0 snap-start flex flex-col relative group"
                      >
                        {/* Urgency Badge */}
                        {event.urgency === 'high' && (
                          <span className="absolute top-2 left-2 z-10 bg-red-600/90 text-white text-[8px] font-bold px-2 py-0.5 rounded-full backdrop-blur-sm flex items-center gap-0.5 shadow-sm">
                            <span className="w-1 h-1 bg-white rounded-full animate-ping"></span>
                            Khẩn cấp
                          </span>
                        )}

                        <div className="h-24 w-full relative overflow-hidden bg-neutral-850">
                          <img 
                            src={event.image} 
                            alt={event.title} 
                            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
                          />
                          <div className="absolute inset-0 bg-gradient-to-t from-neutral-900 via-transparent to-transparent"></div>
                          
                          {/* Distance badge */}
                          <span className="absolute bottom-2 right-2 bg-black/65 text-white text-[9px] font-bold px-2 py-0.5 rounded-md backdrop-blur-sm flex items-center gap-1">
                            <MapPin className="w-2.5 h-2.5 text-red-500" />
                            {event.distance}
                          </span>
                        </div>

                        <div className="p-3 flex-1 flex flex-col justify-between space-y-2">
                          <div>
                            <h5 className="text-[12px] font-bold text-neutral-100 line-clamp-1 group-hover:text-red-400 transition-colors">{event.title}</h5>
                            <div className="flex items-center gap-1 text-[10px] text-neutral-400 mt-1">
                              <Calendar className="w-3 h-3 text-red-500/80 shrink-0" />
                              <span className="truncate">{event.date}</span>
                            </div>
                          </div>

                          <div className="flex items-center justify-between pt-1 border-t border-neutral-800/60">
                            <span className="text-[9px] text-emerald-400 font-medium">Còn {event.slotsLeft} lượt đăng ký</span>
                            <button
                              onClick={(e) => {
                                e.stopPropagation();
                                toggleBookEvent(event.id);
                              }}
                              className={`text-[10px] font-bold px-3 py-1.5 rounded-md transition-all active:scale-95 ${
                                event.booked 
                                  ? 'bg-neutral-800 text-neutral-500 cursor-default' 
                                  : 'bg-red-600 text-white hover:bg-red-500'
                              }`}
                            >
                              {event.booked ? 'Đã đặt' : 'Đặt lịch'}
                            </button>
                          </div>
                        </div>
                      </div>
                    ))}
                  </div>
                </div>
              </div>
            </motion.div>
          )}

          {activeTab === 'events' && (
            <motion.div
              key="events-tab"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.15 }}
              className="space-y-4"
            >
              <div className="flex justify-between items-center">
                <h2 className="text-lg font-bold text-white">Sự kiện & Địa điểm</h2>
                <span className="text-[10px] bg-red-600/20 text-red-500 px-2 py-0.5 rounded-full font-bold uppercase">Sát cánh cứu người</span>
              </div>

              {/* Search Bar */}
              <div className="relative">
                <Search className="absolute left-3.5 top-1/2 -translate-y-1/2 w-4.5 h-4.5 text-neutral-500" />
                <input 
                  type="text" 
                  placeholder="Tìm điểm hiến máu, tên sự kiện..."
                  value={searchQuery}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full bg-neutral-900 border border-neutral-800 rounded-xl pl-10 pr-4 py-2.5 text-xs text-white placeholder-neutral-500 focus:outline-none focus:border-red-500 transition-colors"
                />
                {searchQuery && (
                  <button onClick={() => setSearchQuery('')} className="absolute right-3 top-1/2 -translate-y-1/2 text-neutral-400 hover:text-white">
                    <X className="w-3.5 h-3.5" />
                  </button>
                )}
              </div>

              {/* Mini Map Mockup */}
              <div className="h-[130px] rounded-xl bg-neutral-900 border border-neutral-800 overflow-hidden relative">
                {/* Simulated Grid Map */}
                <div className="absolute inset-0 bg-[radial-gradient(#ffffff0a_1px,transparent_1px)] [background-size:16px_16px] opacity-40"></div>
                
                {/* Routes */}
                <svg className="absolute inset-0 w-full h-full text-neutral-800/40" xmlns="http://www.w3.org/2000/svg">
                  <path d="M 0 50 Q 150 100 390 40" fill="none" stroke="currentColor" strokeWidth="4" />
                  <path d="M 120 0 Q 140 120 200 130" fill="none" stroke="currentColor" strokeWidth="3" />
                  <path d="M 280 0 Q 230 70 300 130" fill="none" stroke="currentColor" strokeWidth="2.5" />
                </svg>

                {/* Hotspots */}
                <div className="absolute top-[35%] left-[20%] group">
                  <span className="absolute inline-flex h-4 w-4 rounded-full bg-red-500 opacity-75 animate-ping"></span>
                  <div className="relative w-3.5 h-3.5 bg-red-600 rounded-full border-2 border-neutral-950 flex items-center justify-center cursor-pointer">
                    <div className="w-1 h-1 bg-white rounded-full"></div>
                  </div>
                  <div className="absolute bottom-5 -left-12 bg-neutral-950/90 border border-neutral-800 text-[8px] font-bold text-white px-1.5 py-0.5 rounded shadow-lg whitespace-nowrap pointer-events-none">
                    FPT Polytechnic (Gần nhất)
                  </div>
                </div>

                <div className="absolute top-[60%] right-[30%]">
                  <div className="w-3.5 h-3.5 bg-red-700/60 rounded-full border-2 border-neutral-950 flex items-center justify-center">
                    <div className="w-1 h-1 bg-white/60 rounded-full"></div>
                  </div>
                </div>

                <div className="absolute top-[15%] right-[15%]">
                  <div className="w-3.5 h-3.5 bg-neutral-600 rounded-full border-2 border-neutral-950 flex items-center justify-center"></div>
                </div>

                {/* Map Floating Control */}
                <div className="absolute bottom-2 left-2 bg-neutral-950/85 border border-neutral-800 text-[9px] text-neutral-300 font-semibold px-2 py-1 rounded-md backdrop-blur-sm flex items-center gap-1">
                  <MapPin className="w-3 h-3 text-red-500" />
                  <span>Bản đồ trực tuyến</span>
                </div>
              </div>

              {/* Event Cards List */}
              <div className="space-y-3">
                <p className="text-[10px] font-bold text-neutral-400 tracking-wide uppercase px-0.5">Danh sách địa điểm</p>
                <div className="space-y-2.5">
                  {events
                    .filter(ev => ev.title.toLowerCase().includes(searchQuery.toLowerCase()) || ev.location.toLowerCase().includes(searchQuery.toLowerCase()))
                    .map((event) => (
                      <div key={event.id} className="bg-neutral-900 border border-neutral-850 p-3 rounded-xl flex gap-3 hover:border-red-500/20 transition-all group">
                        <img src={event.image} alt={event.title} className="w-16 h-16 rounded-lg object-cover shrink-0" />
                        <div className="flex-1 min-w-0 flex flex-col justify-between">
                          <div>
                            <div className="flex justify-between items-start">
                              <h4 className="text-xs font-bold text-white truncate pr-2 group-hover:text-red-400 transition-colors">{event.title}</h4>
                              {event.urgency === 'high' && (
                                <span className="bg-red-600/20 text-red-500 text-[7px] font-extrabold px-1.5 py-0.2 rounded-full uppercase shrink-0">Cần Gấp</span>
                              )}
                            </div>
                            <p className="text-[9px] text-neutral-400 truncate mt-0.5">{event.location}</p>
                          </div>
                          <div className="flex justify-between items-center mt-1 pt-1 border-t border-neutral-850">
                            <span className="text-[9px] text-neutral-400 font-medium">{event.date}</span>
                            <button
                              onClick={() => toggleBookEvent(event.id)}
                              className={`text-[9px] font-bold px-2.5 py-1 rounded-md transition-all ${
                                event.booked 
                                  ? 'bg-neutral-800 text-neutral-500' 
                                  : 'bg-red-600 text-white hover:bg-red-500'
                              }`}
                            >
                              {event.booked ? 'Đã đặt' : 'Đăng ký'}
                            </button>
                          </div>
                        </div>
                      </div>
                    ))}
                </div>
              </div>
            </motion.div>
          )}

          {activeTab === 'history' && (
            <motion.div
              key="history-tab"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.15 }}
              className="space-y-4"
            >
              <div className="flex justify-between items-center">
                <div>
                  <h2 className="text-lg font-bold text-white">Nhật ký Hiến máu</h2>
                  <p className="text-[10px] text-neutral-400">Ghi nhận sự sẻ chia vô giá của bạn</p>
                </div>
                <button
                  onClick={() => setShowAddHistoryModal(true)}
                  className="bg-red-600 text-white text-xs font-bold px-3 py-1.5 rounded-lg flex items-center gap-1 hover:bg-red-500 active:scale-95 transition-all"
                >
                  <Plus className="w-4 h-4" />
                  <span>Thêm mới</span>
                </button>
              </div>

              {/* Summary Stats Grid */}
              <div className="grid grid-cols-2 gap-3">
                <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-3 text-center">
                  <span className="text-[9px] font-bold text-neutral-500 uppercase">Tổng thể tích hiến</span>
                  <p className="text-xl font-black text-white mt-0.5">{totalVolume} ml</p>
                  <p className="text-[8px] text-red-500 font-semibold mt-0.5 flex items-center justify-center gap-0.5">
                    <Droplet className="w-2.5 h-2.5 fill-current" /> Đã đóng góp
                  </p>
                </div>
                <div className="bg-neutral-900 border border-neutral-800 rounded-xl p-3 text-center">
                  <span className="text-[9px] font-bold text-neutral-500 uppercase">Danh hiệu hiện tại</span>
                  <p className="text-sm font-bold text-amber-500 mt-1 uppercase flex items-center justify-center gap-1">
                    <Award className="w-3.5 h-3.5 fill-current" /> Bạc (Level 5)
                  </p>
                  <p className="text-[8px] text-neutral-400 mt-0.5">Tiếp theo: Hiệp Sĩ Vàng</p>
                </div>
              </div>

              {/* History Timeline */}
              <div className="space-y-4 pt-1 relative">
                {/* Vertical Timeline Line */}
                <div className="absolute top-2 bottom-2 left-3 w-0.5 bg-neutral-800"></div>

                {pastDonations.map((item, index) => (
                  <div key={item.id} className="relative pl-7 group">
                    {/* Timeline Node dot */}
                    <div className="absolute left-1.5 top-1.5 w-3.5 h-3.5 rounded-full bg-neutral-950 border-3 border-red-600 group-hover:scale-110 transition-transform"></div>

                    <div className="bg-neutral-900 border border-neutral-850 p-3 rounded-xl hover:border-red-500/10 transition-colors">
                      <div className="flex justify-between items-start">
                        <div>
                          <span className="text-[10px] text-neutral-400 font-bold block">{item.date}</span>
                          <h4 className="text-xs font-bold text-white mt-0.5">{item.location}</h4>
                        </div>
                        <span className="bg-red-600/10 text-red-500 text-[10px] font-black px-2 py-0.5 rounded-md">
                          +{item.volumeml}ml
                        </span>
                      </div>
                      
                      <p className="text-[9.5px] text-neutral-400 mt-2 italic border-l-2 border-neutral-800 pl-2 leading-relaxed">
                        {item.notes}
                      </p>

                      <div className="flex justify-between items-center mt-2.5 pt-2 border-t border-neutral-850/60 text-[9px] text-neutral-500">
                        <span>Chứng chỉ: <strong className="text-neutral-400 font-mono">{item.certificateId}</strong></span>
                        <span className="flex items-center gap-1 text-emerald-400 font-bold bg-emerald-400/5 px-2 py-0.5 rounded-md">
                          <Check className="w-3 h-3" /> Đã chứng nhận
                        </span>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
            </motion.div>
          )}

          {activeTab === 'profile' && (
            <motion.div
              key="profile-tab"
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: -10 }}
              transition={{ duration: 0.15 }}
              className="space-y-5"
            >
              {/* Profile Card Header */}
              <div className="bg-neutral-900 border border-neutral-800 rounded-2xl p-5 text-center relative overflow-hidden">
                <div className="absolute top-0 right-0 w-20 h-20 bg-red-600/5 rounded-full blur-xl"></div>
                <div className="relative inline-block mb-3">
                  <img 
                    src="https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?auto=format&fit=crop&q=80&w=200" 
                    alt="Profile Avatar" 
                    className="w-18 h-18 rounded-full mx-auto object-cover border-2 border-red-600"
                  />
                  <span className="absolute bottom-0 right-1.5 bg-red-600 text-white p-1 rounded-full border-2 border-neutral-900">
                    <Award className="w-3.5 h-3.5 fill-current" />
                  </span>
                </div>
                
                {/* Dynamic input for name customization */}
                <div className="space-y-1">
                  <input 
                    type="text" 
                    value={profile.name}
                    onChange={(e) => setProfile(prev => ({ ...prev, name: e.target.value }))}
                    className="bg-transparent border-b border-transparent hover:border-neutral-700 focus:border-red-500 text-center text-base font-extrabold text-white px-2 py-0.5 rounded focus:outline-none w-48 transition-all"
                    title="Bấm để đổi tên Hiệp sĩ"
                    placeholder="Nhập tên..."
                  />
                  <p className="text-[10px] text-red-500 font-bold uppercase tracking-widest">{profile.badgeTitle}</p>
                </div>

                {/* Micro metrics */}
                <div className="grid grid-cols-3 gap-2 mt-4 pt-4 border-t border-neutral-800/60">
                  <div>
                    <span className="text-[8px] text-neutral-500 font-semibold uppercase">Nhóm máu</span>
                    <div className="mt-0.5">
                      <select 
                        value={profile.bloodType}
                        onChange={(e) => setProfile(prev => ({ ...prev, bloodType: e.target.value }))}
                        className="bg-neutral-950 border border-neutral-800 text-red-500 font-bold text-xs rounded px-1.5 py-0.5 focus:outline-none"
                      >
                        <option value="O+">O+</option>
                        <option value="O-">O-</option>
                        <option value="A+">A+</option>
                        <option value="A-">A-</option>
                        <option value="B+">B+</option>
                        <option value="B-">B-</option>
                        <option value="AB+">AB+</option>
                        <option value="AB-">AB-</option>
                      </select>
                    </div>
                  </div>
                  <div>
                    <span className="text-[8px] text-neutral-500 font-semibold uppercase">Đã hiến</span>
                    <p className="text-xs font-black text-white mt-1">{profile.totalDonations} lần</p>
                  </div>
                  <div>
                    <span className="text-[8px] text-neutral-500 font-semibold uppercase">Điểm Hero</span>
                    <p className="text-xs font-black text-amber-500 mt-1">{profile.points} pts</p>
                  </div>
                </div>
              </div>

              {/* Achievements Collection */}
              <div className="space-y-3">
                <p className="text-[10px] font-bold text-neutral-400 tracking-wide uppercase px-0.5">Bảng huy chương</p>
                
                <div className="grid grid-cols-3 gap-2.5">
                  <div className="bg-neutral-900 border border-neutral-850 p-2.5 rounded-xl text-center flex flex-col items-center justify-center space-y-1">
                    <Award className="w-8 h-8 text-neutral-600 fill-neutral-600/10" />
                    <p className="text-[9px] font-bold text-neutral-400">Vàng cao quý</p>
                    <span className="text-[7px] text-neutral-500">Cần 10 lần hiến</span>
                  </div>
                  <div className="bg-neutral-900 border border-red-500/20 p-2.5 rounded-xl text-center flex flex-col items-center justify-center space-y-1 relative ring-1 ring-red-500/10">
                    <Award className="w-8 h-8 text-amber-500 fill-amber-500/10" />
                    <p className="text-[9px] font-extrabold text-white">Hiệp Sĩ Bạc</p>
                    <span className="text-[7px] text-emerald-400 font-semibold">ĐÃ ĐẠT</span>
                  </div>
                  <div className="bg-neutral-900 border border-neutral-850 p-2.5 rounded-xl text-center flex flex-col items-center justify-center space-y-1">
                    <Award className="w-8 h-8 text-amber-700 fill-amber-700/10" />
                    <p className="text-[9px] font-bold text-neutral-400">Đồng vững bền</p>
                    <span className="text-[7px] text-emerald-400 font-semibold">ĐÃ ĐẠT</span>
                  </div>
                </div>
              </div>

              {/* Quick Settings links */}
              <div className="bg-neutral-900 border border-neutral-800 rounded-xl overflow-hidden divide-y divide-neutral-850 text-xs">
                <div className="p-3 flex justify-between items-center text-neutral-200 hover:bg-neutral-850/50 cursor-pointer transition-colors">
                  <span className="font-medium">Chính sách bảo mật hiến ghép tạng</span>
                  <ChevronRight className="w-4 h-4 text-neutral-500" />
                </div>
                <div className="p-3 flex justify-between items-center text-neutral-200 hover:bg-neutral-850/50 cursor-pointer transition-colors">
                  <span className="font-medium">Lịch hẹn nhắc nhở định kỳ</span>
                  <span className="text-[10px] text-red-500 font-bold bg-red-500/10 px-2 py-0.5 rounded">BẬT</span>
                </div>
                <div className="p-3 flex justify-between items-center text-neutral-200 hover:bg-neutral-850/50 cursor-pointer transition-colors">
                  <span className="font-medium">Liên hệ hỗ trợ khẩn cấp</span>
                  <span className="text-[10px] text-neutral-400 font-mono">1900 6080</span>
                </div>
              </div>
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* BOTTOM NAVIGATION BAR */}
      <div 
        id="bottom-nav-bar"
        onClick={() => onSelectComponent('Bottom Navigation Bar')}
        className={`absolute bottom-0 inset-x-0 bg-neutral-900/95 border-t border-neutral-800/80 px-4 py-2.5 flex justify-between items-center backdrop-blur-md rounded-t-2xl z-40 transition-all ${isSelected('Bottom Navigation Bar')}`}
      >
        <button 
          onClick={(e) => { e.stopPropagation(); setActiveTab('home'); }}
          className={`flex flex-col items-center gap-1 shrink-0 ${activeTab === 'home' ? 'text-red-500 font-bold' : 'text-neutral-500'}`}
        >
          <Home className="w-5.5 h-5.5" />
          <span className="text-[9px]">Trang chủ</span>
        </button>

        <button 
          onClick={(e) => { e.stopPropagation(); setActiveTab('events'); }}
          className={`flex flex-col items-center gap-1 shrink-0 ${activeTab === 'events' ? 'text-red-500 font-bold' : 'text-neutral-500'}`}
        >
          <MapPin className="w-5.5 h-5.5" />
          <span className="text-[9px]">Sự kiện</span>
        </button>

        <button 
          onClick={(e) => { e.stopPropagation(); setActiveTab('history'); }}
          className={`flex flex-col items-center gap-1 shrink-0 ${activeTab === 'history' ? 'text-red-500 font-bold' : 'text-neutral-500'}`}
        >
          <History className="w-5.5 h-5.5" />
          <span className="text-[9px]">Nhật ký</span>
        </button>

        <button 
          onClick={(e) => { e.stopPropagation(); setActiveTab('profile'); }}
          className={`flex flex-col items-center gap-1 shrink-0 ${activeTab === 'profile' ? 'text-red-500 font-bold' : 'text-neutral-500'}`}
        >
          <User className="w-5.5 h-5.5" />
          <span className="text-[9px]">Cá nhân</span>
        </button>
      </div>
    </>
  ) : (
    /* EMERGENCY SOS MODE (Screen 2: The Pulse Experience) */
    <div className="flex-1 flex flex-col justify-between px-6 pt-5 pb-8 text-center relative overflow-hidden h-full">
      {/* Urgency Siren Glow rings at the top */}
      <div className="absolute top-0 inset-x-0 h-40 bg-red-600/10 blur-3xl pointer-events-none"></div>

      {/* 1. Urgent Alert Header */}
      <div 
        id="sos-header"
        onClick={() => onSelectComponent('Màn hình Khẩn cấp (SOS Mode)')}
        className={`cursor-pointer p-4 rounded-2xl border transition-all ${
          isSelected('Màn hình Khẩn cấp (SOS Mode)') || activeSelectedWidget === 'Màn hình Khẩn cấp (SOS Mode)'
            ? 'bg-red-500/10 border-red-500/50 ring-1 ring-red-500/30' 
            : 'bg-red-950/25 border-red-900/30 hover:bg-red-950/45'
        }`}
      >
        {/* Pulsing Red Siren Icon */}
        <div className="relative w-14 h-14 bg-red-500/20 rounded-full mx-auto flex items-center justify-center border border-red-500/30 mb-3 animate-pulse">
          <motion.div 
            className="absolute inset-0 rounded-full bg-red-500/10"
            animate={{ scale: [1, 1.4, 1] }}
            transition={{ duration: 1.5, repeat: Infinity }}
          />
          <AlertTriangle className="w-7 h-7 text-red-500 animate-bounce" />
        </div>

        <h2 className="text-sm font-black text-red-500 tracking-wider uppercase mb-1">CỨU TRỢ KHẨN CẤP (SOS)</h2>
        <p className="text-[11.5px] text-neutral-200 leading-relaxed font-medium">
          Bệnh viện <span className="font-bold text-red-400">Đa khoa X</span> đang báo động đỏ thiếu nhóm máu <span className="text-red-500 font-extrabold px-1 py-0.5 rounded bg-red-500/10">{profile.bloodType}</span> của bạn trong bán kính <span className="font-bold text-red-400">5km</span>.
        </p>
      </div>

      {/* 2. Visual Experience - The Living Pulse (ECG) */}
      <div 
        id="living-pulse"
        onClick={() => onSelectComponent('Sóng nhịp tim (Living Pulse Wave)')}
        className={`cursor-pointer py-3 px-1 rounded-2xl border transition-all my-4 relative flex flex-col justify-center items-center h-28 ${
          isSelected('Sóng nhịp tim (Living Pulse Wave)') || activeSelectedWidget === 'Sóng nhịp tim (Living Pulse Wave)'
            ? 'bg-red-500/10 border-red-500/50 ring-1 ring-red-500/30'
            : 'bg-neutral-900/40 border-neutral-800/50 hover:bg-neutral-900/60'
        }`}
      >
        <div className="absolute top-1.5 left-3 flex items-center gap-1.5">
          <span className="w-1.5 h-1.5 bg-red-500 rounded-full animate-ping"></span>
          <span className="text-[8px] font-mono text-red-500 font-bold uppercase tracking-wider">Mạch sống (Living Pulse)</span>
        </div>

        {/* Custom SVG Heartbeat Path */}
        <div className="w-full h-20 flex items-center justify-center overflow-hidden rounded-lg">
          <svg className="w-full h-full text-red-500" viewBox="0 0 300 100" fill="none" preserveAspectRatio="none">
            <defs>
              <pattern id="pulse-grid" width="10" height="10" patternUnits="userSpaceOnUse">
                <path d="M 10 0 L 0 0 0 10" fill="none" stroke="rgba(239, 68, 68, 0.04)" strokeWidth="0.5" />
              </pattern>
            </defs>
            <rect width="100%" height="100%" fill="url(#pulse-grid)" />
            
            {/* Gray wave background trail */}
            <path
              d="M 0 50 L 70 50 L 80 40 L 85 60 L 90 15 L 98 85 L 105 45 L 112 55 L 120 50 L 190 50 L 198 42 L 206 50 L 300 50"
              stroke="rgba(239, 68, 68, 0.12)"
              strokeWidth="2.5"
              strokeLinecap="round"
              strokeLinejoin="round"
            />

            {/* Glowing animated path */}
            <motion.path
              d="M 0 50 L 70 50 L 80 40 L 85 60 L 90 15 L 98 85 L 105 45 L 112 55 L 120 50 L 190 50 L 198 42 L 206 50 L 300 50"
              stroke="#ff334b"
              strokeWidth="3.2"
              strokeLinecap="round"
              strokeLinejoin="round"
              initial={{ pathLength: 0 }}
              animate={{ pathLength: 1 }}
              transition={{
                duration: 2.2,
                repeat: Infinity,
                ease: "linear"
              }}
            />

            {/* Sliding pulse core glow dot */}
            <motion.circle
              r="4.5"
              fill="#ff334b"
              animate={{ 
                cx: [0, 70, 80, 85, 90, 98, 105, 112, 120, 190, 198, 206, 300],
                cy: [50, 50, 40, 60, 15, 85, 45, 55, 50, 50, 42, 50, 50]
              }}
              transition={{
                duration: 2.2,
                repeat: Infinity,
                ease: "linear"
              }}
              className="shadow-[0_0_10px_#ff334b]"
            />
          </svg>
        </div>
      </div>

      {/* 3. The Hero Action - "Hold to Confirm" Button */}
      {!isCommitted ? (
        <div 
          id="hold-commit"
          onClick={() => onSelectComponent('Nút Cam kết 3s (Hold to Commit Button)')}
          className={`cursor-pointer p-2 rounded-2xl border transition-all flex flex-col items-center justify-center ${
            isSelected('Nút Cam kết 3s (Hold to Commit Button)') || activeSelectedWidget === 'Nút Cam kết 3s (Hold to Commit Button)'
              ? 'bg-red-500/10 border-red-500/50 ring-1 ring-red-500/30'
              : 'bg-transparent border-transparent'
          }`}
        >
          <div 
            className="relative w-36 h-36 flex items-center justify-center group touch-none"
            onMouseDown={() => setIsHolding(true)}
            onMouseUp={() => setIsHolding(false)}
            onMouseLeave={() => setIsHolding(false)}
            onTouchStart={(e) => { e.preventDefault(); setIsHolding(true); }}
            onTouchEnd={() => setIsHolding(false)}
          >
            {/* SVG Circle loader path that fills up when held */}
            <svg className="absolute inset-0 w-full h-full transform -rotate-90">
              <circle 
                cx="72" 
                cy="72" 
                r="56" 
                className="stroke-neutral-800/50" 
                strokeWidth="6" 
                fill="transparent" 
              />
              <circle 
                cx="72" 
                cy="72" 
                r="56" 
                className="stroke-red-500 transition-all" 
                strokeWidth="6" 
                fill="transparent" 
                strokeDasharray={2 * Math.PI * 56}
                strokeDashoffset={2 * Math.PI * 56 * (1 - holdProgress / 100)}
                strokeLinecap="round"
              />
            </svg>

            {/* Pulsing neon red button core */}
            <div className={`w-24 h-24 rounded-full flex flex-col items-center justify-center text-center transition-all duration-300 ${
              isHolding 
                ? 'bg-red-600 border-4 border-red-400 scale-95 shadow-[0_0_35px_rgba(239,68,68,0.8)]' 
                : 'bg-[#2B0408] border-3 border-red-500 shadow-[0_0_20px_rgba(239,68,68,0.3)] hover:shadow-[0_0_30px_rgba(239,68,68,0.5)]'
            }`}>
              <Fingerprint className={`w-9 h-9 text-white transition-transform ${isHolding ? 'scale-110 animate-pulse' : ''}`} />
              <span className="text-[9px] font-black tracking-tight text-white mt-1.5 leading-none">NHẤN GIỮ 3S</span>
              <span className="text-[8px] font-bold text-red-200 uppercase mt-0.5 leading-none">ĐỂ CAM KẾT</span>
            </div>
          </div>
          
          {/* Visual Indicator of Progress Percentage */}
          <div className="h-4 mt-1 flex items-center justify-center">
            {holdProgress > 0 ? (
              <span className="text-[10px] font-mono text-red-400 font-bold animate-pulse">
                Đang xác thực: {Math.round(holdProgress)}%
              </span>
            ) : (
              <span className="text-[9.5px] text-neutral-400 font-medium italic">
                Chạm giữ ngón tay để cam kết di chuyển
              </span>
            )}
          </div>
        </div>
      ) : (
        /* SUCCESS WORKFLOW: Connecting Life-lines GPS route */
        <div className="bg-neutral-900/95 border border-emerald-500/40 rounded-2xl p-3 text-left space-y-2.5 shadow-lg relative overflow-hidden">
          <div className="absolute right-0 top-0 w-20 h-20 bg-emerald-500/10 rounded-full blur-xl"></div>
          
          <div className="flex items-center gap-2">
            <span className="w-5 h-5 bg-emerald-500/20 border border-emerald-500/40 rounded-full flex items-center justify-center text-emerald-400 shrink-0">
              <Check className="w-3.5 h-3.5" />
            </span>
            <div>
              <h4 className="text-[11px] font-black text-white uppercase">Mạch sống đã kết nối!</h4>
              <span className="text-[8px] text-emerald-400 font-bold uppercase tracking-wider block">Cam kết thành công • Đang định tuyến</span>
            </div>
          </div>

          {/* Mini-route GPS Canvas overlay inside phone */}
          <div className="h-28 rounded-xl bg-neutral-950 border border-neutral-850 relative overflow-hidden">
            <div className="absolute inset-0 bg-[radial-gradient(#ffffff03_1px,transparent_1px)] [background-size:10px_10px] opacity-50"></div>
            
            {/* Animated Map Route SVG */}
            <svg className="absolute inset-0 w-full h-full text-neutral-800" xmlns="http://www.w3.org/2000/svg">
              {/* Main Route */}
              <path d="M 40 90 L 100 70 L 160 80 L 180 30 L 250 20" fill="none" stroke="rgba(16, 185, 129, 0.2)" strokeWidth="5" strokeLinecap="round" />
              <motion.path 
                d="M 40 90 L 100 70 L 160 80 L 180 30 L 250 20" 
                fill="none" 
                stroke="#10b981" 
                strokeWidth="3.5" 
                strokeLinecap="round" 
                initial={{ pathLength: 0 }}
                animate={{ pathLength: 1 }}
                transition={{ duration: 3, repeat: Infinity, ease: "linear" }}
              />
            </svg>

            {/* Start Point (User) */}
            <div className="absolute bottom-2 left-6 flex items-center gap-1">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
              <span className="text-[7.5px] font-bold text-neutral-400 font-mono">Bạn</span>
            </div>

            {/* End Point (Hospital) */}
            <div className="absolute top-2 right-4 flex items-center gap-1">
              <span className="relative flex h-3 w-3">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-red-400 opacity-75"></span>
                <MapPin className="relative w-3 h-3 text-red-500 fill-red-500/10" />
              </span>
              <span className="text-[7.5px] font-extrabold text-red-400">BV Đa khoa X (5km)</span>
            </div>

            {/* Floating guidance hud */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 bg-neutral-900/95 border border-neutral-800 text-[8px] font-bold text-neutral-200 px-2 py-1 rounded-lg shadow-md flex items-center gap-1 backdrop-blur-xs whitespace-nowrap">
              <Compass className="w-2.5 h-2.5 text-emerald-400 animate-spin" />
              <span>Đường ưu tiên: 8 phút di chuyển</span>
            </div>
          </div>

          <div className="flex gap-1.5 pt-0.5">
            <button 
              onClick={() => {
                setIsCommitted(false);
                setHoldProgress(0);
              }}
              className="flex-1 text-[9px] font-bold text-neutral-400 hover:text-white bg-neutral-800 hover:bg-neutral-750 py-1.5 rounded-lg transition-colors text-center uppercase"
            >
              Hủy cam kết
            </button>
            <button 
              onClick={() => {
                setAppMode('daily');
                setIsCommitted(false);
                setHoldProgress(0);
              }}
              className="flex-1 text-[9px] font-bold text-white bg-emerald-600 hover:bg-emerald-500 py-1.5 rounded-lg transition-colors text-center uppercase shadow-md shadow-emerald-950/25"
            >
              Trở về chính
            </button>
          </div>
        </div>
      )}

      {/* 4. Quick Info Footer */}
      <div className="mt-1 text-center">
        <p className="text-[9px] text-neutral-400 leading-relaxed max-w-[280px] mx-auto">
          Sau khi cam kết, mạch sống của bạn sẽ kết nối với bệnh viện và lộ trình di chuyển nhanh nhất sẽ được kích hoạt.
        </p>
      </div>
    </div>
  )}

      {/* MODAL - HERO PASS DIGITAL CERTIFICATE (Flip Card details) */}
      <AnimatePresence>
        {showQRModal && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setShowQRModal(false)}
            className="absolute inset-0 bg-black/85 z-50 flex items-center justify-center p-4 backdrop-blur-md"
          >
            <motion.div 
              initial={{ scale: 0.9, y: 20 }}
              animate={{ scale: 1, y: 0 }}
              exit={{ scale: 0.9, y: 20 }}
              onClick={(e) => e.stopPropagation()}
              className="bg-neutral-900 border border-neutral-800 rounded-3xl p-6 w-full max-w-[320px] text-center space-y-5 relative"
            >
              <button 
                onClick={() => setShowQRModal(false)}
                className="absolute top-4 right-4 text-neutral-400 hover:text-white bg-neutral-800 p-1.5 rounded-full"
              >
                <X className="w-4 h-4" />
              </button>

              <div className="space-y-1 pt-2">
                <span className="text-[10px] font-bold text-red-500 uppercase tracking-widest">Chứng nhận quốc gia</span>
                <h3 className="text-sm font-extrabold text-white uppercase">MÃ ĐỊNH DANH HIẾP SĨ</h3>
                <p className="text-[10px] text-neutral-400">Hiển thị mã này tại quầy tiếp đón bệnh viện</p>
              </div>

              {/* High-Contrast Beautiful QR Frame */}
              <div className="relative bg-white p-4 rounded-2xl inline-block shadow-inner mx-auto group">
                <div className="absolute inset-0 border-2 border-red-500 rounded-2xl scale-102 animate-pulse pointer-events-none"></div>
                {/* Simulated QR Code matrix using nice visual SVG */}
                <svg className="w-[160px] h-[160px] text-neutral-950" viewBox="0 0 100 100" fill="currentColor">
                  {/* Outer position indicators */}
                  <path d="M 0 0 L 25 0 L 25 5 L 5 5 L 5 25 L 0 25 Z" />
                  <path d="M 5 5 L 20 5 L 20 20 L 5 20 Z M 10 10 L 15 10 L 15 15 L 10 15 Z" fillRule="evenodd" />
                  
                  <path d="M 75 0 L 100 0 L 100 25 L 95 25 L 95 5 L 75 5 Z" />
                  <path d="M 80 5 L 95 5 L 95 20 L 80 20 Z M 85 10 L 90 10 L 90 15 L 85 15 Z" fillRule="evenodd" />
                  
                  <path d="M 0 75 L 0 100 L 25 100 L 25 95 L 5 95 L 5 75 Z" />
                  <path d="M 5 80 L 20 80 L 20 95 L 5 95 Z M 10 85 L 15 85 L 15 90 L 10 90 Z" fillRule="evenodd" />

                  {/* Alignment marker */}
                  <path d="M 75 75 L 85 75 L 85 85 L 75 85 Z M 78 78 L 82 78 L 82 82 L 78 82 Z" fillRule="evenodd" />

                  {/* Random QR pixels for premium tech look */}
                  <rect x="35" y="5" width="5" height="15" />
                  <rect x="45" y="10" width="10" height="5" />
                  <rect x="60" y="0" width="5" height="10" />
                  <rect x="65" y="15" width="5" height="15" />
                  
                  <rect x="5" y="35" width="15" height="5" />
                  <rect x="10" y="45" width="5" height="10" />
                  <rect x="0" y="60" width="10" height="5" />
                  
                  <rect x="35" y="40" width="10" height="10" />
                  <rect x="55" y="35" width="15" height="5" />
                  <rect x="50" y="50" width="15" height="15" />
                  <rect x="35" y="65" width="20" height="5" />
                  
                  <rect x="45" y="80" width="15" height="15" />
                  <rect x="65" y="80" width="5" height="5" />
                  <rect x="65" y="90" width="5" height="10" />
                  
                  <rect x="90" y="35" width="10" height="10" />
                  <rect x="80" y="55" width="15" height="5" />
                </svg>

                {/* Scan Bar Effect */}
                <div className="absolute left-2 right-2 h-0.5 bg-red-600 top-2 animate-bounce"></div>
              </div>

              {/* Blood info inside ticket */}
              <div className="bg-neutral-950 rounded-xl p-3 grid grid-cols-2 text-left gap-1 border border-neutral-850">
                <div>
                  <span className="text-[8px] text-neutral-500 uppercase">Mã số</span>
                  <p className="text-[11px] font-bold text-white font-mono">PL-9088-TRÍ</p>
                </div>
                <div className="text-right">
                  <span className="text-[8px] text-neutral-500 uppercase">Nhóm máu</span>
                  <p className="text-[11px] font-bold text-red-500">{profile.bloodType}</p>
                </div>
              </div>

              <div className="text-[10px] text-neutral-400 pt-1 leading-relaxed">
                Chứng chỉ định danh Hiệp sĩ hiến máu điện tử, được bảo mật và liên thông với Cơ sở dữ liệu y tế quốc gia.
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* MODAL - NOTIFICATION DRAWER */}
      <AnimatePresence>
        {showNotificationModal && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setShowNotificationModal(false)}
            className="absolute inset-0 bg-black/85 z-50 flex items-end justify-center"
          >
            <motion.div 
              initial={{ y: 200 }}
              animate={{ y: 0 }}
              exit={{ y: 200 }}
              onClick={(e) => e.stopPropagation()}
              className="bg-neutral-900 border-t border-neutral-800 rounded-t-[32px] p-6 w-full max-h-[480px] overflow-y-auto space-y-4"
            >
              <div className="flex justify-between items-center pb-2 border-b border-neutral-850">
                <h3 className="text-sm font-bold text-white flex items-center gap-1.5">
                  <Bell className="w-4 h-4 text-red-500" /> Thông báo hệ thống
                </h3>
                <div className="flex items-center gap-3">
                  <button 
                    onClick={markAllNotificationsRead}
                    className="text-[10px] text-red-500 font-semibold hover:text-red-400"
                  >
                    Đọc tất cả
                  </button>
                  <button 
                    onClick={() => setShowNotificationModal(false)}
                    className="text-neutral-400 hover:text-white bg-neutral-800 p-1 rounded-full"
                  >
                    <X className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              <div className="space-y-2.5">
                {notifications.map(notif => (
                  <div 
                    key={notif.id} 
                    className={`p-3 rounded-xl border transition-all text-xs flex gap-3 ${
                      notif.unread 
                        ? 'bg-red-500/5 border-red-500/20 text-neutral-200' 
                        : 'bg-neutral-950 border-neutral-850 text-neutral-400'
                    }`}
                  >
                    <div className="pt-0.5 shrink-0">
                      <div className={`w-2 h-2 rounded-full ${notif.unread ? 'bg-red-500' : 'bg-neutral-700'}`}></div>
                    </div>
                    <div className="space-y-1">
                      <p className="leading-relaxed">{notif.text}</p>
                      <span className="text-[9px] text-neutral-500 block">{notif.time}</span>
                    </div>
                  </div>
                ))}
              </div>

              <div className="pt-2 text-center">
                <p className="text-[10px] text-neutral-500">Pulse Link bảo mật các thông báo theo thời gian thực.</p>
              </div>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* MODAL - ADD PAST DONATION (HISTORY WORKFLOW) */}
      <AnimatePresence>
        {showAddHistoryModal && (
          <motion.div 
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setShowAddHistoryModal(false)}
            className="absolute inset-0 bg-black/85 z-50 flex items-center justify-center p-4 backdrop-blur-md"
          >
            <motion.div 
              initial={{ scale: 0.95, y: 20 }}
              animate={{ scale: 1, y: 0 }}
              exit={{ scale: 0.95, y: 20 }}
              onClick={(e) => e.stopPropagation()}
              className="bg-neutral-900 border border-neutral-800 rounded-2xl p-5 w-full max-w-[320px] space-y-4 text-left"
            >
              <div className="flex justify-between items-center pb-2 border-b border-neutral-850">
                <h3 className="text-xs font-bold text-white uppercase tracking-wider">Thêm lịch sử hiến máu</h3>
                <button onClick={() => setShowAddHistoryModal(false)} className="text-neutral-400 hover:text-white bg-neutral-800 p-1 rounded-full">
                  <X className="w-3.5 h-3.5" />
                </button>
              </div>

              <form onSubmit={handleAddHistory} className="space-y-3.5 text-xs text-neutral-300">
                <div className="space-y-1">
                  <label className="block text-[10px] font-bold text-neutral-400 uppercase">Điểm hiến máu</label>
                  <input 
                    type="text" 
                    required
                    placeholder="Ví dụ: Bệnh viện Chợ Rẫy"
                    value={historyLocation}
                    onChange={(e) => setHistoryLocation(e.target.value)}
                    className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-red-500 transition-colors"
                  />
                </div>

                <div className="grid grid-cols-2 gap-3">
                  <div className="space-y-1">
                    <label className="block text-[10px] font-bold text-neutral-400 uppercase">Thể tích (ml)</label>
                    <select
                      value={historyVolume}
                      onChange={(e) => setHistoryVolume(Number(e.target.value))}
                      className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-red-500 transition-colors"
                    >
                      <option value="250">250 ml</option>
                      <option value="350">350 ml</option>
                      <option value="450">450 ml</option>
                    </select>
                  </div>

                  <div className="space-y-1">
                    <label className="block text-[10px] font-bold text-neutral-400 uppercase">Ngày hiến</label>
                    <input 
                      type="date" 
                      required
                      value={historyDate}
                      onChange={(e) => setHistoryDate(e.target.value)}
                      className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-red-500 transition-colors"
                    />
                  </div>
                </div>

                <div className="space-y-1">
                  <label className="block text-[10px] font-bold text-neutral-400 uppercase">Ghi chú sức khỏe</label>
                  <input 
                    type="text" 
                    placeholder="Ví dụ: Sức khỏe tốt, huyết áp ổn định"
                    value={historyNotes}
                    onChange={(e) => setHistoryNotes(e.target.value)}
                    className="w-full bg-neutral-950 border border-neutral-800 rounded-lg px-3 py-2 text-white focus:outline-none focus:border-red-500 transition-colors"
                  />
                </div>

                <button 
                  type="submit"
                  className="w-full bg-red-600 text-white font-bold py-2 rounded-lg hover:bg-red-500 transition-all flex items-center justify-center gap-1 mt-4"
                >
                  <Check className="w-4 h-4" />
                  <span>Xác nhận đóng góp</span>
                </button>
              </form>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

    </div>
  );
}
