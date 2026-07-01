import React, { useState, useEffect } from 'react';
import { ShieldAlert, Compass, Navigation, Radio, Users, Play, RotateCcw, AlertTriangle } from 'lucide-react';

interface EmergencyResponseProps {
  sosActive: boolean;
  onToggleSOS: () => void;
}

export default function EmergencyResponse({ sosActive, onToggleSOS }: EmergencyResponseProps) {
  const [committedCount, setCommittedCount] = useState(20);
  const [dispatchStage, setDispatchStage] = useState<'wave1' | 'wave2' | 'wave3'>('wave2');
  const [pulseKey, setPulseKey] = useState(0);

  // Simulate real-time websocket counter changes
  useEffect(() => {
    if (!sosActive) return;
    const interval = setInterval(() => {
      setCommittedCount(prev => {
        if (prev >= 30) return 20; // reset
        return prev + 1;
      });
    }, 4000);
    return () => clearInterval(interval);
  }, [sosActive]);

  const handleResetSimulation = () => {
    setCommittedCount(20);
    setDispatchStage('wave1');
    setPulseKey(prev => prev + 1);
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Trigger State UI banner inside workspace */}
      {sosActive && (
        <div className="bg-red-50 border-l-4 border-[#E31837] p-4 rounded-r-xl shadow-xs flex items-center justify-between">
          <div className="flex items-center space-x-3">
            <div className="w-8 h-8 rounded-full bg-red-100 flex items-center justify-center text-[#E31837] animate-pulse">
              <ShieldAlert className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm font-black text-red-950 uppercase tracking-wider">BÁO ĐỘNG ĐỎ TRONG TIẾN TRÌNH (RED ALERT ACTIVE)</h3>
              <p className="text-xs text-red-700 mt-0.5">Hệ thống đang phát thông báo ưu tiên sóng phát xa 30km thu gom nhóm máu hiếm O- khẩn cấp.</p>
            </div>
          </div>
          <div className="flex items-center space-x-2">
            <button
              onClick={handleResetSimulation}
              className="px-3 py-1.5 bg-white border border-red-200 text-red-700 hover:bg-red-100 transition-colors rounded-lg text-xs font-bold flex items-center space-x-1.5 cursor-pointer"
            >
              <RotateCcw className="w-3.5 h-3.5" />
              <span>Chạy lại mô phỏng</span>
            </button>
            <button
              onClick={onToggleSOS}
              className="px-3 py-1.5 bg-[#E31837] hover:bg-red-700 text-white transition-colors rounded-lg text-xs font-bold cursor-pointer"
            >
              Tắt báo động
            </button>
          </div>
        </div>
      )}

      {/* Main Two-Column Layout */}
      <div className="flex flex-col lg:flex-row gap-6">
        {/* LEFT PANEL: LIVE-TRACKING MAP (65% width) */}
        <div className="lg:w-[65%] bg-white rounded-2xl border border-slate-100 p-6 shadow-sm flex flex-col h-[580px]">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-4 pb-3 border-b border-gray-100">
            <div>
              <h2 className="text-base font-extrabold text-gray-900 tracking-tight flex items-center">
                <Compass className="w-5 h-5 text-gray-600 mr-2" />
                Bản đồ Điều phối Thời gian thực (Live Tracking Map)
              </h2>
              <p className="text-xs text-gray-500 mt-0.5">Mô phỏng đường đi của Tình nguyện viên về Bệnh viện TW qua định vị GPS liên tục.</p>
            </div>
            <div className="mt-2 sm:mt-0 flex items-center space-x-2">
              <span className="inline-flex items-center px-2 py-0.5 rounded text-[10px] font-bold bg-gray-100 text-gray-600 border border-gray-200">
                <Navigation className="w-3.5 h-3.5 mr-1 text-blue-500" /> GPS Đã kết nối
              </span>
            </div>
          </div>

          {/* High-Fidelity SVG Map Placeholder */}
          <div className="flex-1 bg-neutral-950 rounded-xl relative overflow-hidden border border-neutral-800">
            {/* Grid Map Matrix background */}
            <div className="absolute inset-0 opacity-10 bg-[radial-gradient(#fff_1px,transparent_1px)] [background-size:20px_20px]"></div>

            {/* Simulated River */}
            <svg className="absolute inset-0 w-full h-full pointer-events-none">
              <path
                d="M -50 400 Q 200 300 300 200 T 800 100"
                fill="none"
                stroke="#1e293b"
                strokeWidth="24"
                className="opacity-40"
              />
              <path
                d="M -50 400 Q 200 300 300 200 T 800 100"
                fill="none"
                stroke="#0f172a"
                strokeWidth="20"
                className="opacity-40"
              />
            </svg>

            {/* Hospital Node (Tâm chấn) */}
            <div className="absolute top-1/2 left-1/2 -translate-x-1/2 -translate-y-1/2 text-center z-10">
              <div className="relative flex items-center justify-center">
                <div className="absolute w-16 h-16 bg-red-500/20 rounded-full animate-ping"></div>
                <div className="absolute w-28 h-28 bg-red-500/10 rounded-full animate-pulse"></div>
                <div className="w-10 h-10 bg-[#E31837] border-4 border-neutral-900 rounded-full flex items-center justify-center text-white font-bold shadow-2xl relative">
                  <span className="text-base">🏥</span>
                </div>
              </div>
              <div className="mt-3 bg-neutral-900/95 border border-neutral-800 px-3 py-1 rounded-lg shadow-lg">
                <p className="text-[10px] font-bold text-white tracking-wide">Bệnh viện ĐK Trung ương</p>
                <p className="text-[8px] text-red-400 font-mono mt-0.5">Điểm tiếp nhận máu O-</p>
              </div>
            </div>

            {/* Pulse GPS Track Rings */}
            <svg className="absolute inset-0 w-full h-full pointer-events-none">
              {/* Outer wave rings */}
              <circle cx="50%" cy="50%" r="90" fill="none" stroke="#dc2626" strokeWidth="1" strokeDasharray="2 6" className="opacity-30 animate-[spin_60s_linear_infinite]" />
              <circle cx="50%" cy="50%" r="180" fill="none" stroke="#dc2626" strokeWidth="1" strokeDasharray="4 8" className="opacity-20 animate-[spin_120s_linear_infinite]" />

              {/* Moving Route 1 */}
              <path
                key={`r1-${pulseKey}`}
                d="M 80 120 L 260 210 L 320 250"
                fill="none"
                stroke="#E31837"
                strokeWidth="1.5"
                strokeDasharray="4 4"
                className="opacity-60 animate-[dash_1.5s_linear_infinite]"
              />

              {/* Moving Route 2 */}
              <path
                key={`r2-${pulseKey}`}
                d="M 580 430 L 410 320 L 360 280"
                fill="none"
                stroke="#E31837"
                strokeWidth="1.5"
                strokeDasharray="4 4"
                className="opacity-60 animate-[dash_2s_linear_infinite]"
              />

              {/* Route 3 */}
              <path
                key={`r3-${pulseKey}`}
                d="M 520 80 L 360 200 L 330 240"
                fill="none"
                stroke="#10b981"
                strokeWidth="1"
                strokeDasharray="2 4"
                className="opacity-40"
              />
            </svg>

            {/* Volunteer Marker 1 (O- moving closer) */}
            <div
              key={`v1-${pulseKey}`}
              className="absolute top-[22%] left-[28%] flex items-center space-x-2 bg-neutral-900/90 border border-red-500/50 rounded-full px-2.5 py-1 text-white shadow-lg animate-pulse"
            >
              <div className="w-2 h-2 rounded-full bg-red-500 animate-ping"></div>
              <span className="text-[9px] font-mono font-bold">O- (TNV Minh Tuấn - 1.2km)</span>
            </div>

            {/* Volunteer Marker 2 (O- moving closer) */}
            <div
              key={`v2-${pulseKey}`}
              className="absolute bottom-[24%] right-[22%] flex items-center space-x-2 bg-neutral-900/90 border border-red-500/50 rounded-full px-2.5 py-1 text-white shadow-lg animate-pulse"
            >
              <div className="w-2 h-2 rounded-full bg-red-500 animate-ping"></div>
              <span className="text-[9px] font-mono font-bold">O- (TNV Khánh Nam - 2.8km)</span>
            </div>

            {/* Volunteer Marker 3 (A- moving closer) */}
            <div
              key={`v3-${pulseKey}`}
              className="absolute top-[12%] right-[28%] flex items-center space-x-2 bg-neutral-900/90 border border-emerald-500/50 rounded-full px-2.5 py-1 text-white shadow-lg opacity-80"
            >
              <div className="w-2 h-2 rounded-full bg-emerald-500"></div>
              <span className="text-[9px] font-mono">A- (TNV Bảo Vy - 4.5km)</span>
            </div>

            {/* Map Info Box */}
            <div className="absolute bottom-4 left-4 bg-black/80 border border-neutral-800 rounded-lg p-3 max-w-xs text-white">
              <p className="text-[10px] font-bold text-gray-300">TRẠNG THÁI GPS TIẾP NHẬN</p>
              <div className="grid grid-cols-2 gap-2 mt-1.5 text-[9px] text-gray-400">
                <div>• O- Đang đến: <span className="text-red-400 font-extrabold">2</span></div>
                <div>• Nhóm khác: <span className="text-emerald-400 font-extrabold">3</span></div>
                <div>• Phản hồi SOS: <span className="text-white font-extrabold">20</span></div>
                <div>• Độ trễ API: <span className="text-gray-500 font-mono">14ms</span></div>
              </div>
            </div>
          </div>
        </div>

        {/* RIGHT PANEL: WAVE DISPATCH LIVE FEED (35% width) - High contrast dark style from Geometric Balance */}
        <div className="lg:w-[35%] bg-slate-900 border border-slate-800 shadow-xl rounded-2xl p-6 flex flex-col h-[580px] relative overflow-hidden text-white">
          {/* Radial glow background */}
          <div className="absolute inset-0 opacity-15 pointer-events-none bg-[radial-gradient(circle_at_50%_50%,#E31837,transparent_70%)]"></div>

          <div className="relative z-10 flex flex-col h-full">
            <div className="pb-3 border-b border-slate-800">
              <h2 className="text-base font-bold text-white tracking-tight flex items-center justify-between">
                <span className="flex items-center">
                  <Radio className="w-5 h-5 text-[#E31837] mr-2 animate-pulse shrink-0" />
                  Sóng Phát lệnh Truyền tin (Wave Dispatch)
                </span>
                <span className="text-[10px] bg-[#E31837] text-white px-2 py-0.5 rounded font-black tracking-wider animate-pulse shrink-0">ACTIVE</span>
              </h2>
              <p className="text-xs text-slate-400 mt-1">Phát tín hiệu theo cấp độ bán kính địa lý thu gom máu khẩn cấp.</p>
            </div>

            {/* Timeline dispatch radius progression */}
            <div className="flex-1 overflow-y-auto py-6 space-y-6 pr-1">
              {/* Wave 1: 5km Inner-City */}
              <div className={`pl-6 border-l-2 relative pb-2 transition-all ${
                dispatchStage === 'wave1' || dispatchStage === 'wave2' || dispatchStage === 'wave3'
                  ? 'border-emerald-500' : 'border-slate-800'
              }`}>
                <div className={`absolute -left-[7px] top-0.5 w-3.5 h-3.5 rounded-full border-2 border-slate-900 flex items-center justify-center text-[7px] font-black ${
                  dispatchStage === 'wave1' || dispatchStage === 'wave2' || dispatchStage === 'wave3'
                    ? 'bg-emerald-500 text-white' : 'bg-slate-800 text-slate-500'
                }`}>✓</div>
                <div className="flex items-center justify-between">
                  <h4 className="text-xs font-bold text-slate-100">Sóng 1: Nội thành (Bán kính 5km)</h4>
                  <span className="text-[9px] font-bold bg-emerald-500/10 text-emerald-400 px-1.5 py-0.5 rounded">Hoàn thành</span>
                </div>
                <p className="text-[11px] text-slate-400 mt-1">
                  Gửi thông báo đẩy khẩn cấp đến ứng dụng di động cho toàn bộ tình nguyện viên nhóm máu O- cư trú trong vòng 5km xung quanh bệnh viện.
                </p>
                <div className="mt-2 text-[10px] text-slate-400 bg-white/5 p-2 rounded border border-white/5">
                  Kết quả: <strong className="text-slate-100 font-bold">124 Nhận tin</strong> • <strong className="text-emerald-400 font-bold">8 Cam kết hiến</strong>
                </div>
              </div>

              {/* Wave 2: 30km Provincial */}
              <div className={`pl-6 border-l-2 relative pb-2 transition-all ${
                dispatchStage === 'wave2' || dispatchStage === 'wave3'
                  ? 'border-[#E31837]' : 'border-slate-800'
              }`}>
                <div className={`absolute -left-[7px] top-0.5 w-3.5 h-3.5 rounded-full border-2 border-slate-900 flex items-center justify-center text-[7px] font-black ${
                  dispatchStage === 'wave2' || dispatchStage === 'wave3'
                    ? 'bg-[#E31837] text-white animate-pulse' : 'bg-slate-800 text-slate-500'
                }`}>{dispatchStage === 'wave3' ? '✓' : '●'}</div>
                <div className="flex items-center justify-between">
                  <h4 className="text-xs font-bold text-slate-100">Sóng 2: Ngoại thành (5km - 30km)</h4>
                  <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded ${
                    dispatchStage === 'wave2'
                      ? 'bg-red-500/10 text-[#E31837] animate-pulse'
                      : dispatchStage === 'wave3' ? 'bg-emerald-500/10 text-emerald-400' : 'bg-slate-800 text-slate-500'
                  }`}>
                    {dispatchStage === 'wave2' ? 'Đang lan tỏa' : dispatchStage === 'wave3' ? 'Hoàn thành' : 'Chờ'}
                  </span>
                </div>
                <p className="text-[11px] text-slate-400 mt-1">
                  Kích hoạt truyền tin qua tổng đài SMS khu vực và đẩy thông báo khẩn cấp bán kính 30km ngoại thành. Gọi điện ưu tiên cho top tình nguyện viên kỳ cựu.
                </p>
                <div className="mt-2 text-[10px] text-slate-400 bg-white/5 p-2 rounded border border-white/5">
                  Kết quả: <strong className="text-slate-100 font-bold">342 Nhận tin</strong> • <strong className="text-[#E31837] font-bold">12 Cam kết hiến</strong>
                </div>
              </div>

              {/* Wave 3: >50km Inter-Provincial */}
              <div className={`pl-6 border-l-2 relative pb-2 transition-all ${
                dispatchStage === 'wave3' ? 'border-[#E31837]' : 'border-slate-800'
              }`}>
                <div className={`absolute -left-[7px] top-0.5 w-3.5 h-3.5 rounded-full border-2 border-slate-900 flex items-center justify-center text-[7px] font-black ${
                  dispatchStage === 'wave3'
                    ? 'bg-[#E31837] text-white' : 'bg-slate-800 text-slate-500'
                }`}>●</div>
                <div className="flex items-center justify-between">
                  <h4 className="text-xs font-bold text-slate-400">Sóng 3: Liên tỉnh (&gt;50km)</h4>
                  <span className={`text-[9px] font-bold px-1.5 py-0.5 rounded ${
                    dispatchStage === 'wave3' ? 'bg-red-500/10 text-[#E31837] animate-pulse' : 'bg-slate-800 text-slate-500'
                  }`}>
                    {dispatchStage === 'wave3' ? 'Đang kích hoạt' : 'Sẵn sàng'}
                  </span>
                </div>
                <p className="text-[11px] text-slate-500 mt-1">
                  Liên hệ phát sóng truyền hình địa phương phối hợp cùng Chữ Thập Đỏ liên tỉnh để vận chuyển khẩn cấp đơn vị lưu trữ.
                </p>
              </div>
            </div>

            {/* Interactive stage controls */}
            <div className="mt-3 flex items-center justify-between p-2.5 bg-white/5 border border-white/10 rounded-xl mb-3">
              <span className="text-[10px] text-slate-400 font-bold">Kích hoạt Sóng kế tiếp:</span>
              <div className="flex space-x-1">
                <button
                  onClick={() => setDispatchStage('wave1')}
                  className={`px-2 py-1 rounded text-[9px] font-bold transition-all cursor-pointer ${dispatchStage === 'wave1' ? 'bg-white text-slate-950 shadow' : 'bg-slate-800 text-slate-300 border border-slate-700 hover:bg-slate-700'}`}
                >
                  Sóng 1
                </button>
                <button
                  onClick={() => setDispatchStage('wave2')}
                  className={`px-2 py-1 rounded text-[9px] font-bold transition-all cursor-pointer ${dispatchStage === 'wave2' ? 'bg-white text-slate-950 shadow' : 'bg-slate-800 text-slate-300 border border-slate-700 hover:bg-slate-700'}`}
                >
                  Sóng 2
                </button>
                <button
                  onClick={() => setDispatchStage('wave3')}
                  className={`px-2 py-1 rounded text-[9px] font-bold transition-all cursor-pointer ${dispatchStage === 'wave3' ? 'bg-[#E31837] text-white shadow' : 'bg-slate-800 text-slate-300 border border-slate-700 hover:bg-slate-700'}`}
                >
                  Sóng 3
                </button>
              </div>
            </div>

            {/* Real-time websocket counter widget */}
            <div className="mt-auto bg-white/5 border border-white/10 p-4 rounded-xl flex items-center justify-between">
              <div>
                <p className="text-[10px] font-mono tracking-widest text-slate-400 flex items-center">
                  <Users className="w-3.5 h-3.5 mr-1.5 text-red-500 animate-pulse" />
                  WEBSOCKET LIVE FEED
                </p>
                <h3 className="text-xl font-black mt-1 text-white">
                  {committedCount} <span className="text-[10px] text-slate-400 font-normal">người đăng ký</span>
                </h3>
              </div>
              <div className="text-right">
                <span className="text-[10px] font-extrabold text-white bg-[#E31837] px-2.5 py-1 rounded border border-red-500/20">
                  O- Cần: 30 đv
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}
