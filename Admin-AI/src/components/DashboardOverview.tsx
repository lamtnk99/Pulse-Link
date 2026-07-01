import React, { useState } from 'react';
import { AlertTriangle, TrendingUp, Calendar, Droplet, Plus, Minus, Info } from 'lucide-react';
import { BloodStock } from '../types';

interface DashboardOverviewProps {
  sosActive: boolean;
  bloodStocks: BloodStock[];
  setBloodStocks: React.Dispatch<React.SetStateAction<BloodStock[]>>;
}

export default function DashboardOverview({ sosActive, bloodStocks, setBloodStocks }: DashboardOverviewProps) {
  const [editingStockId, setEditingStockId] = useState<string | null>(null);

  const totalSOSCount = sosActive ? 2 : 1;

  const handleAdjustStock = (group: string, rh: string, change: number) => {
    setBloodStocks(prev => prev.map(stock => {
      if (stock.group === group && stock.rh === rh) {
        const nextUnits = Math.max(0, stock.units + change);
        return { ...stock, units: nextUnits };
      }
      return stock;
    }));
  };

  return (
    <div className="space-y-8 animate-fade-in">
      {/* ROW 1: REAL-TIME METRIC CARDS */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        {/* Metric 1: Active SOS Alerts */}
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 flex items-center gap-4 transition-all hover:shadow-md">
          <div className="w-12 h-12 bg-red-100 rounded-xl flex items-center justify-center text-[#E31837] shrink-0 animate-pulse">
            <AlertTriangle className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <p className="text-slate-400 text-[11px] font-bold uppercase tracking-wider">Cấp cứu SOS</p>
            <div className="flex items-end gap-2 mt-1">
              <h3 className="text-2xl font-black text-slate-800">
                {String(totalSOSCount).padStart(2, '0')}
              </h3>
              <span className="text-red-500 text-xs font-bold mb-0.5 animate-pulse">+1 hôm nay</span>
            </div>
          </div>
        </div>

        {/* Metric 2: Committed Donors Today */}
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 flex items-center gap-4 transition-all hover:shadow-md">
          <div className="w-12 h-12 bg-emerald-100 rounded-xl flex items-center justify-center text-emerald-600 shrink-0">
            <TrendingUp className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <p className="text-slate-400 text-[11px] font-bold uppercase tracking-wider">Người hiến cam kết</p>
            <div className="flex items-end gap-2 mt-1">
              <h3 className="text-2xl font-bold text-slate-800">24</h3>
              <span className="text-emerald-500 text-xs font-bold mb-0.5">+12%</span>
            </div>
          </div>
        </div>

        {/* Metric 3: Total Scheduled Appointments */}
        <div className="bg-white p-5 rounded-2xl shadow-sm border border-slate-100 flex items-center gap-4 transition-all hover:shadow-md">
          <div className="w-12 h-12 bg-blue-100 rounded-xl flex items-center justify-center text-blue-600 shrink-0">
            <Calendar className="w-6 h-6" />
          </div>
          <div className="flex-1">
            <p className="text-slate-400 text-[11px] font-bold uppercase tracking-wider">Lịch hẹn hiến máu</p>
            <div className="flex items-end gap-2 mt-1">
              <h3 className="text-2xl font-bold text-slate-800">145</h3>
              <span className="text-blue-500 text-xs font-bold mb-0.5">Tuần này</span>
            </div>
          </div>
        </div>
      </div>

      {/* ROW 2: BLOOD INVENTORY TRACKER */}
      <div className="bg-white rounded-2xl border border-slate-100 p-6 shadow-sm">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between mb-6 pb-4 border-b border-slate-100">
          <div>
            <h2 className="text-lg font-black text-gray-900 tracking-tight flex items-center">
              <Droplet className="w-5 h-5 text-[#E31837] mr-2 animate-pulse" />
              Theo dõi Trực quan Kho máu (Real-time Blood Inventory)
            </h2>
            <p className="text-xs text-gray-500 mt-1">
              Đơn vị: Đơn vị máu chuẩn (ml). Cảnh báo nhấp nháy cho các nhóm máu chạm ngưỡng báo động dưới 25 đv.
            </p>
          </div>
          <div className="mt-3 sm:mt-0 flex flex-wrap items-center gap-4 text-xs font-semibold text-gray-500">
            <span className="flex items-center">
              <span className="w-2.5 h-2.5 rounded-full bg-red-500 mr-1.5 animate-pulse"></span>
              Cực thấp (Critical &lt; 25)
            </span>
            <span className="flex items-center">
              <span className="w-2.5 h-2.5 rounded-full bg-amber-400 mr-1.5"></span>
              Trung bình (25 - 50)
            </span>
            <span className="flex items-center">
              <span className="w-2.5 h-2.5 rounded-full bg-emerald-500 mr-1.5"></span>
              Đầy đủ (&gt; 50)
            </span>
          </div>
        </div>

        {/* Stock Grid */}
        <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-4">
          {bloodStocks.map((stock, idx) => {
            const isCritical = stock.units < stock.criticalLimit;
            const progressPercentage = Math.min((stock.units / 120) * 100, 100);

            return (
              <div
                key={`${stock.group}-${stock.rh}`}
                className={`p-4 rounded-xl border flex flex-col items-center justify-between transition-all duration-300 relative group ${
                  isCritical
                    ? 'border-red-200 bg-red-50/50 animate-pulse text-red-950 shadow-xs'
                    : 'border-slate-200 hover:border-slate-300 bg-white'
                }`}
              >
                {/* Critical Badge */}
                {isCritical && (
                  <span className="absolute top-2 right-2 inline-flex items-center px-1.5 py-0.5 rounded text-[8px] font-black bg-[#E31837] text-white tracking-widest animate-bounce">
                    NGUY CẤP
                  </span>
                )}

                {/* Blood Group Display */}
                <div className="text-center mt-2">
                  <span
                    className={`text-2xl font-black tracking-tight ${
                      isCritical ? 'text-[#E31837]' : 'text-gray-900'
                    }`}
                  >
                    {stock.group}
                    <sup className="text-sm font-extrabold">{stock.rh === '+' ? '⁺' : '⁻'}</sup>
                  </span>
                </div>

                {/* Progress bar visualizer */}
                <div className="w-full bg-slate-100 rounded-full h-1 mt-4 overflow-hidden">
                  <div
                    className={`h-full rounded-full transition-all duration-500 ${
                      isCritical ? 'bg-[#E31837]' : stock.units < 50 ? 'bg-amber-400' : 'bg-emerald-500'
                    }`}
                    style={{ width: `${progressPercentage}%` }}
                  ></div>
                </div>

                {/* Units Counter & Adjuster */}
                <div className="mt-3 text-center w-full">
                  <p className="text-base font-black text-gray-900">
                    {stock.units} <span className="text-[10px] text-gray-400 font-normal">đv</span>
                  </p>
                  <p className="text-[10px] text-gray-400 mt-0.5">Ngưỡng: {stock.criticalLimit}đv</p>

                  {/* Interactive Quick adjustment buttons for layout playground */}
                  <div className="flex items-center justify-center space-x-1.5 mt-2.5 opacity-0 group-hover:opacity-100 transition-opacity">
                    <button
                      onClick={() => handleAdjustStock(stock.group, stock.rh, -5)}
                      className="p-1 rounded bg-slate-100 hover:bg-slate-200 text-gray-600 transition-colors cursor-pointer"
                      title="Giảm 5 đơn vị"
                    >
                      <Minus className="w-3 h-3" />
                    </button>
                    <button
                      onClick={() => handleAdjustStock(stock.group, stock.rh, 5)}
                      className="p-1 rounded bg-slate-100 hover:bg-slate-200 text-gray-600 transition-colors cursor-pointer"
                      title="Tăng 5 đơn vị"
                    >
                      <Plus className="w-3 h-3" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>

        {/* Pro-Tip Box */}
        <div className="mt-6 p-4 bg-[#F8FAFC] rounded-xl border border-slate-200 flex items-start space-x-2.5 text-xs text-gray-600">
          <Info className="w-4 h-4 text-gray-400 shrink-0 mt-0.5" />
          <p>
            <strong className="font-bold text-gray-800">Mẹo kiến trúc:</strong> Bạn có thể hover chuột vào bất kỳ hộp nhóm máu nào để điều chỉnh mức tồn kho ảo tức thời. Khi kho máu chạm dưới mức 25, hệ thống sẽ tự động bật cảnh báo đỏ nhấp nháy thực tế.
          </p>
        </div>
      </div>
    </div>
  );
}
