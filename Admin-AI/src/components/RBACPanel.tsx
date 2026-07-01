import React, { useState } from 'react';
import { ShieldAlert, UserCheck, ShieldClose, Shield, UserX, Check, Edit3, X, Info } from 'lucide-react';
import { StaffAccount } from '../types';

interface RBACPanelProps {
  staff: StaffAccount[];
  setStaff: React.Dispatch<React.SetStateAction<StaffAccount[]>>;
}

export default function RBACPanel({ staff, setStaff }: RBACPanelProps) {
  const [selectedStaff, setSelectedStaff] = useState<StaffAccount | null>(null);
  const [newRole, setNewRole] = useState<StaffAccount['role']>('Coordinator / Nurse');

  const handleToggleStatus = (id: string) => {
    setStaff(prev => prev.map(account => {
      if (account.id === id) {
        const nextStatus = account.status === 'Đang hoạt động' ? 'Tạm khóa' : 'Đang hoạt động';
        return { ...account, status: nextStatus };
      }
      return account;
    }));
  };

  const handleModifyRole = (e: React.FormEvent) => {
    e.preventDefault();
    if (!selectedStaff) return;

    setStaff(prev => prev.map(account => {
      if (account.id === selectedStaff.id) {
        return { ...account, role: newRole };
      }
      return account;
    }));

    setSelectedStaff(null);
  };

  const handleOpenEdit = (account: StaffAccount) => {
    setSelectedStaff(account);
    setNewRole(account.role);
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* Header and secure note */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-4 border-b border-slate-200">
        <div>
          <h2 className="text-xl font-black text-gray-900 tracking-tight flex items-center">
            <ShieldAlert className="w-5.5 h-5.5 text-[#E31837] mr-2" />
            Hệ thống Phân quyền & Quản lý Nhân sự (RBAC)
          </h2>
          <p className="text-xs text-gray-500 mt-1">
            Thiết lập quyền truy cập nghiêm ngặt và quản lý tài khoản của y bác sĩ hoạt động trên hệ thống Pulse Link.
          </p>
        </div>
        <span className="text-xs font-mono bg-red-100 text-[#E31837] font-bold px-3 py-1.5 rounded-full border border-red-200 w-fit">
          MÔI TRƯỜNG BẢO MẬT CẤP CAO
        </span>
      </div>

      {/* REVOLVING AUDIT RULES EXPLANATION (Row of 3 cards) */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
        <div className="bg-slate-900 text-white p-5 rounded-2xl border border-slate-800 shadow-md">
          <h3 className="text-xs font-black text-red-500 uppercase tracking-widest flex items-center">
            <span className="mr-1.5">🛡️</span>
            Quyền Hạn: Director (Super Admin)
          </h3>
          <p className="text-xs text-gray-400 mt-2 leading-relaxed">
            Quyền hành chính tối cao. Toàn quyền giám sát cơ sở dữ liệu, quản lý và cấp phát tài khoản y khoa, xóa dấu vết nhật ký sự kiện hoặc can thiệp kho máu.
          </p>
        </div>
        <div className="bg-slate-900 text-white p-5 rounded-2xl border border-slate-800 shadow-md">
          <h3 className="text-xs font-black text-amber-500 uppercase tracking-widest flex items-center">
            <span className="mr-1.5">🥼</span>
            Quyền Hạn: ER Doctor / Surgeon
          </h3>
          <p className="text-xs text-gray-400 mt-2 leading-relaxed">
            Cấp phép tối khẩn. Đặc quyền kích hoạt hoặc hủy lệnh <strong className="text-red-400 font-bold">BÁO ĐỘNG ĐỎ (SOS Alert)</strong>, điều phối dòng máu khẩn cấp tại phòng phẫu thuật trung tâm.
          </p>
        </div>
        <div className="bg-slate-900 text-white p-5 rounded-2xl border border-slate-800 shadow-md">
          <h3 className="text-xs font-black text-blue-400 uppercase tracking-widest flex items-center">
            <span className="mr-1.5">👩‍⚕️</span>
            Quyền Hạn: Coordinator / Nurse
          </h3>
          <p className="text-xs text-gray-400 mt-2 leading-relaxed">
            Điều hành nội dung định kỳ. Tạo lịch hiến máu mới, duyệt bài đăng CMS cộng đồng, kiểm tra thông số tồn kho chuẩn bị cho người hiến. Bị giới hạn kích hoạt SOS.
          </p>
        </div>
      </div>

      {/* USER ACCESS DATA TABLE */}
      <div className="bg-white rounded-2xl border border-slate-100 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse min-w-[700px]">
            <thead>
              <tr className="bg-slate-50 text-slate-500 text-[10px] uppercase font-bold tracking-widest border-b border-slate-100">
                <th className="py-3.5 px-6">Họ và Tên Nhân viên</th>
                <th className="py-3.5 px-6">Khoa / Phòng ban</th>
                <th className="py-3.5 px-6">Vai trò Hệ thống</th>
                <th className="py-3.5 px-6 text-center">Trạng thái Truy cập</th>
                <th className="py-3.5 px-6 text-center">Hành động thực thi</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 text-xs">
              {staff.map((member) => (
                <tr key={member.id} className="hover:bg-gray-50/50 transition-colors">
                  <td className="py-4 px-6">
                    <div className="flex items-center space-x-3">
                      <div className={`w-8 h-8 rounded-full flex items-center justify-center text-white font-extrabold ${
                        member.role === 'Super Admin / Director' ? 'bg-red-500' :
                        member.role === 'ER Doctor / Surgeon' ? 'bg-amber-500' : 'bg-blue-500'
                      }`}>
                        {member.name.split(' ').pop()?.substring(0, 2).toUpperCase()}
                      </div>
                      <div>
                        <p className="font-bold text-gray-900">{member.name}</p>
                        <p className="text-[10px] text-gray-400 mt-0.5">ID: staff_0{member.id}</p>
                      </div>
                    </div>
                  </td>
                  <td className="py-4 px-6 text-gray-600 font-medium">{member.department}</td>
                  <td className="py-4 px-6">
                    <span className={`inline-flex items-center px-2.5 py-1 rounded-lg text-[10px] font-extrabold border ${
                      member.role === 'Super Admin / Director'
                        ? 'bg-red-50 text-[#E31837] border-red-200'
                        : member.role === 'ER Doctor / Surgeon'
                        ? 'bg-amber-50 text-amber-700 border-amber-200'
                        : 'bg-blue-50 text-blue-700 border-blue-200'
                    }`}>
                      {member.role}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-center">
                    <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[10px] font-bold border ${
                      member.status === 'Đang hoạt động'
                        ? 'bg-green-50 text-green-700 border-green-200'
                        : 'bg-red-50 text-red-700 border-red-200'
                    }`}>
                      <span className={`w-1.5 h-1.5 rounded-full mr-1.5 ${
                        member.status === 'Đang hoạt động' ? 'bg-green-500' : 'bg-red-500'
                      }`}></span>
                      {member.status}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-center">
                    <div className="flex items-center justify-center space-x-3.5">
                      <button
                        onClick={() => handleOpenEdit(member)}
                        className="text-blue-600 hover:text-blue-800 font-bold text-xs flex items-center space-x-1 cursor-pointer"
                      >
                        <Edit3 className="w-3.5 h-3.5" />
                        <span>Sửa quyền</span>
                      </button>
                      <button
                        onClick={() => handleToggleStatus(member.id)}
                        className={`font-bold text-xs flex items-center space-x-1 cursor-pointer ${
                          member.status === 'Đang hoạt động'
                            ? 'text-red-500 hover:text-red-700'
                            : 'text-green-600 hover:text-green-800'
                        }`}
                      >
                        {member.status === 'Đang hoạt động' ? (
                          <>
                            <UserX className="w-3.5 h-3.5" />
                            <span>Khóa</span>
                          </>
                        ) : (
                          <>
                            <UserCheck className="w-3.5 h-3.5" />
                            <span>Mở khóa</span>
                          </>
                        )}
                      </button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* ROLE MODIFICATION MODAL */}
      {selectedStaff && (
        <div className="fixed inset-0 bg-black/60 backdrop-blur-xs z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl border border-gray-200 shadow-2xl max-w-md w-full overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="px-6 py-4 bg-gray-50 border-b border-gray-200 flex items-center justify-between">
              <h3 className="font-black text-gray-900 text-sm uppercase flex items-center">
                <Shield className="w-4 h-4 text-[#E31837] mr-1.5" />
                Sửa đổi Vai trò Phân quyền
              </h3>
              <button
                onClick={() => setSelectedStaff(null)}
                className="text-gray-400 hover:text-gray-600 text-lg cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <form onSubmit={handleModifyRole} className="p-6 space-y-4">
              <div className="p-3.5 bg-gray-50 rounded-xl border border-gray-100 flex items-center space-x-3 mb-2">
                <div className="w-9 h-9 rounded-full bg-gray-800 text-white flex items-center justify-center font-bold">
                  {selectedStaff.name.split(' ').pop()?.substring(0, 2).toUpperCase()}
                </div>
                <div>
                  <p className="font-bold text-gray-900 text-xs">{selectedStaff.name}</p>
                  <p className="text-[10px] text-gray-500">{selectedStaff.department}</p>
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide mb-1.5">
                  Chọn Vai trò Hệ thống Mới:
                </label>
                <div className="space-y-2">
                  {[
                    { value: 'Super Admin / Director', label: 'Super Admin / Director (Quản trị tối cao)' },
                    { value: 'ER Doctor / Surgeon', label: 'ER Doctor / Surgeon (Kích hoạt lệnh SOS khẩn)' },
                    { value: 'Coordinator / Nurse', label: 'Coordinator / Nurse (Quản lý thường quy & CMS)' }
                  ].map((option) => (
                    <label
                      key={option.value}
                      className={`flex items-center p-3 border rounded-xl cursor-pointer text-xs transition-all ${
                        newRole === option.value
                          ? 'border-[#E31837] bg-red-50/40 text-red-950 font-bold'
                          : 'border-gray-200 hover:bg-gray-50 text-gray-600'
                      }`}
                    >
                      <input
                        type="radio"
                        name="newRole"
                        value={option.value}
                        checked={newRole === option.value}
                        onChange={() => setNewRole(option.value as StaffAccount['role'])}
                        className="mr-3 text-[#E31837] focus:ring-[#E31837]"
                      />
                      <span>{option.label}</span>
                    </label>
                  ))}
                </div>
              </div>

              <div className="p-3 bg-amber-50 rounded-lg border border-amber-100 flex items-start space-x-2 text-[10px] text-amber-700 leading-normal">
                <Info className="w-3.5 h-3.5 shrink-0 mt-0.5" />
                <p>
                  Hệ thống phân quyền (RBAC) được kiểm toán liên tục. Việc thay đổi vai trò sẽ lập tức thay đổi danh mục quyền lợi thao tác nghiệp vụ và ghi nhận nhật ký hệ thống bảo mật.
                </p>
              </div>

              {/* Actions */}
              <div className="pt-4 border-t border-gray-100 flex items-center justify-end space-x-3">
                <button
                  type="button"
                  onClick={() => setSelectedStaff(null)}
                  className="px-4 py-2 border border-gray-300 text-gray-600 rounded-lg text-xs font-bold hover:bg-gray-50 transition-colors cursor-pointer"
                >
                  Hủy bỏ
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 bg-[#E31837] hover:bg-red-700 text-white rounded-lg text-xs font-bold transition-all flex items-center space-x-1 cursor-pointer"
                >
                  <Check className="w-3.5 h-3.5" />
                  <span>Cập nhật Ngay</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
}
