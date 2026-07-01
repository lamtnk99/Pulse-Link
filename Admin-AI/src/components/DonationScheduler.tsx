import React, { useState } from 'react';
import { CalendarRange, Plus, X, MapPin, Award, CheckSquare, Sparkles, Filter, Check } from 'lucide-react';
import { DonationEvent } from '../types';

interface DonationSchedulerProps {
  events: DonationEvent[];
  onAddEvent: (newEvent: DonationEvent) => void;
}

export default function DonationScheduler({ events, onAddEvent }: DonationSchedulerProps) {
  const [showModal, setShowModal] = useState(false);
  const [filterStatus, setFilterStatus] = useState<string>('Tất cả');

  // Modal Form States
  const [eventName, setEventName] = useState('');
  const [eventDate, setEventDate] = useState('2026-07-20');
  const [eventTime, setEventTime] = useState('08:00');
  const [location, setLocation] = useState('');
  const [targetUnits, setTargetUnits] = useState(100);
  const [incentives, setIncentives] = useState('Quà tặng thực phẩm phục hồi sức khỏe + Tiền mặt hỗ trợ đi lại + Cấp giấy chứng nhận hiến máu.');
  const [publishToApp, setPublishToApp] = useState(true);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!eventName || !location) return;

    const newEvent: DonationEvent = {
      id: `EV-${String(events.length + 1).padStart(2, '0')}`,
      name: eventName,
      date: eventDate,
      time: eventTime,
      location,
      targetUnits,
      registeredDonors: 0,
      incentives,
      publishToApp,
      status: 'Nháp'
    };

    onAddEvent(newEvent);

    // Reset Form
    setEventName('');
    setLocation('');
    setTargetUnits(100);
    setIncentives('Quà tặng thực phẩm phục hồi sức khỏe + Tiền mặt hỗ trợ đi lại + Cấp giấy chứng nhận hiến máu.');
    setPublishToApp(true);
    setShowModal(false);
  };

  const filteredEvents = events.filter(event => {
    if (filterStatus === 'Tất cả') return true;
    return event.status === filterStatus;
  });

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header and Controls */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-black text-gray-900 tracking-tight flex items-center">
            <CalendarRange className="w-5.5 h-5.5 text-[#E31837] mr-2" />
            Quản lý Lịch hiến máu (Donation Events)
          </h2>
          <p className="text-xs text-gray-500 mt-1">
            Thiết lập lịch trình đón tiếp hiến máu định kỳ và cộng đồng toàn tỉnh.
          </p>
        </div>
        <button
          onClick={() => setShowModal(true)}
          className="bg-[#E31837] hover:bg-red-700 active:scale-95 text-white text-xs font-bold px-4 py-2.5 rounded-lg flex items-center justify-center space-x-2 shadow-sm transition-all cursor-pointer w-full sm:w-auto"
        >
          <Plus className="w-4 h-4" />
          <span>+ TẠO LỊCH HIẾN MÁU MỚI</span>
        </button>
      </div>

      {/* FILTER BUTTONS & SUMMARY */}
      <div className="bg-white p-4 rounded-xl border border-slate-100 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
        <div className="flex items-center space-x-2 w-full sm:w-auto">
          <Filter className="w-4 h-4 text-gray-400" />
          <span className="text-xs text-gray-500 font-semibold mr-2">Bộ lọc:</span>
          <div className="flex bg-slate-50 p-0.5 rounded-lg text-xs">
            {['Tất cả', 'Nháp', 'Đang diễn ra', 'Đã kết thúc'].map((status) => (
              <button
                key={status}
                onClick={() => setFilterStatus(status)}
                className={`px-3 py-1.5 rounded-md transition-all font-semibold cursor-pointer ${
                  filterStatus === status
                    ? 'bg-white text-gray-900 shadow-sm'
                    : 'text-gray-500 hover:text-gray-900'
                }`}
              >
                {status}
              </button>
            ))}
          </div>
        </div>
        <div className="text-xs font-mono text-gray-500 bg-[#F8FAFC] px-3 py-1.5 rounded-md border border-slate-200 w-full sm:w-auto text-center sm:text-right">
          Hiển thị: <strong className="text-gray-800">{filteredEvents.length}</strong> / {events.length} sự kiện
        </div>
      </div>

      {/* ENTERPRISE DATA TABLE */}
      <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[800px]">
            <thead>
              <tr className="bg-slate-50 text-slate-500 text-[10px] uppercase font-bold tracking-widest border-b border-slate-100">
                <th className="py-4 px-6 text-center w-20">Mã ID</th>
                <th className="py-4 px-6">Tên Sự kiện</th>
                <th className="py-4 px-6">Thời gian</th>
                <th className="py-4 px-6">Địa điểm tổ chức</th>
                <th className="py-4 px-6 text-center">Chỉ tiêu (đv)</th>
                <th className="py-4 px-6 text-center">Người đăng ký</th>
                <th className="py-4 px-6 text-center">Trạng thái</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 text-xs">
              {filteredEvents.map((event) => (
                <tr key={event.id} className="hover:bg-gray-50/40 transition-colors">
                  <td className="py-4 px-6 text-center font-mono text-gray-400 font-semibold">{event.id}</td>
                  <td className="py-4 px-6">
                    <div>
                      <p className="font-bold text-gray-900">{event.name}</p>
                      {event.publishToApp && (
                        <span className="inline-flex items-center px-1.5 py-0.5 rounded text-[9px] font-semibold bg-blue-50 text-blue-600 mt-1 border border-blue-100">
                          <Sparkles className="w-2.5 h-2.5 mr-0.5" /> Đã đăng lên App Mobile
                        </span>
                      )}
                    </div>
                  </td>
                  <td className="py-4 px-6 text-gray-600">
                    <p className="font-semibold">{event.date}</p>
                    <p className="text-[10px] text-gray-400 mt-0.5">{event.time}</p>
                  </td>
                  <td className="py-4 px-6 text-gray-500 font-medium">
                    <p className="line-clamp-1">{event.location}</p>
                  </td>
                  <td className="py-4 px-6 text-center font-bold text-gray-800">{event.targetUnits}</td>
                  <td className="py-4 px-6 text-center">
                    <span className="font-extrabold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full">
                      {event.registeredDonors}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-center">
                    <span
                      className={`inline-flex items-center px-2.5 py-1 rounded-full text-[10px] font-bold border ${
                        event.status === 'Đang diễn ra'
                          ? 'bg-green-50 text-green-700 border-green-200'
                          : event.status === 'Nháp'
                          ? 'bg-gray-100 text-gray-600 border-gray-200'
                          : 'bg-red-50 text-[#E31837] border-red-200'
                      }`}
                    >
                      <span className={`w-1.5 h-1.5 rounded-full mr-1.5 ${
                        event.status === 'Đang diễn ra' ? 'bg-green-500 animate-pulse' : event.status === 'Nháp' ? 'bg-gray-400' : 'bg-red-500'
                      }`}></span>
                      {event.status}
                    </span>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* FORM MODAL (TẠO LỊCH HIẾN MÁU MỚI) */}
      {showModal && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl border border-gray-200 shadow-2xl max-w-lg w-full overflow-hidden animate-in fade-in zoom-in-95 duration-200 flex flex-col">
            {/* Modal Header */}
            <div className="px-6 py-4 bg-gray-50 border-b border-gray-200 flex items-center justify-between">
              <div className="flex items-center space-x-2">
                <span className="text-[#E31837]">🩸</span>
                <h3 className="font-black text-gray-900 text-sm uppercase tracking-wider">
                  Tạo lịch hiến máu mới
                </h3>
              </div>
              <button
                onClick={() => setShowModal(false)}
                className="text-gray-400 hover:text-gray-600 text-xl cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Modal Form */}
            <form onSubmit={handleSubmit} className="p-6 space-y-4 overflow-y-auto max-h-[75vh]">
              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">
                  Tên chiến dịch sự kiện *
                </label>
                <input
                  type="text"
                  required
                  value={eventName}
                  onChange={(e) => setEventName(e.target.value)}
                  className="w-full p-2.5 border border-gray-300 rounded-lg text-xs focus:ring-1 focus:ring-[#E31837] outline-none"
                  placeholder="Ví dụ: Giọt Hồng Nhân Ái Quận 1 - Chi nhánh Bệnh viện"
                />
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">
                    Ngày tổ chức *
                  </label>
                  <input
                    type="date"
                    required
                    value={eventDate}
                    onChange={(e) => setEventDate(e.target.value)}
                    className="w-full p-2.5 border border-gray-300 rounded-lg text-xs outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">
                    Giờ tổ chức *
                  </label>
                  <input
                    type="time"
                    required
                    value={eventTime}
                    onChange={(e) => setEventTime(e.target.value)}
                    className="w-full p-2.5 border border-gray-300 rounded-lg text-xs outline-none"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">
                  Địa điểm tổ chức & Định vị Address *
                </label>
                <div className="relative">
                  <MapPin className="w-4 h-4 text-gray-400 absolute left-3 top-3" />
                  <input
                    type="text"
                    required
                    value={location}
                    onChange={(e) => setLocation(e.target.value)}
                    className="w-full p-2.5 pl-9 border border-gray-300 rounded-lg text-xs focus:ring-1 focus:ring-[#E31837] outline-none"
                    placeholder="Số 120 Hồng Bàng, Phường 12, Quận 5"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-4">
                <div>
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">
                    Chỉ tiêu đặt ra (đv) *
                  </label>
                  <input
                    type="number"
                    required
                    min={10}
                    value={targetUnits}
                    onChange={(e) => setTargetUnits(Number(e.target.value))}
                    className="w-full p-2.5 border border-gray-300 rounded-lg text-xs outline-none"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">
                    Phần thưởng Khích lệ
                  </label>
                  <div className="relative">
                    <Award className="w-4 h-4 text-gray-400 absolute left-3 top-3" />
                    <input
                      type="text"
                      value={incentives}
                      onChange={(e) => setIncentives(e.target.value)}
                      className="w-full p-2.5 pl-9 border border-gray-300 rounded-lg text-xs outline-none"
                      placeholder="Gói quà dinh dưỡng hạng A + chi phí đi lại"
                    />
                  </div>
                </div>
              </div>

              {/* Publish Toggle Box */}
              <div className="flex items-center justify-between p-3.5 bg-gray-50 border border-gray-100 rounded-xl">
                <div>
                  <p className="text-xs font-bold text-gray-800 flex items-center">
                    <CheckSquare className="w-4 h-4 text-[#E31837] mr-1.5" />
                    Đăng lên ứng dụng Pulse Link Mobile
                  </p>
                  <p className="text-[10px] text-gray-400 mt-0.5">
                    Hàng ngàn tình nguyện viên sẽ nhận được thông báo đẩy tức thì trên điện thoại.
                  </p>
                </div>
                <label className="relative inline-flex items-center cursor-pointer">
                  <input
                    type="checkbox"
                    checked={publishToApp}
                    onChange={(e) => setPublishToApp(e.target.checked)}
                    className="sr-only peer"
                  />
                  <div className="w-9 h-5 bg-gray-200 peer-focus:outline-hidden rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-4 after:w-4 after:transition-all peer-checked:bg-[#E31837]"></div>
                </label>
              </div>

              {/* Action Buttons */}
              <div className="pt-4 border-t border-gray-100 flex items-center justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => setShowModal(false)}
                  className="px-4 py-2 border border-gray-300 text-gray-600 rounded-lg text-xs font-bold hover:bg-gray-50 transition-colors cursor-pointer"
                >
                  Hủy bỏ
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-[#E31837] hover:bg-red-700 text-white rounded-lg text-xs font-bold transition-colors cursor-pointer"
                >
                  Xác nhận Tạo
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
