import React, { useState } from 'react';
import { FileText, Send, Image as ImageIcon, Eye, Share2, ThumbsUp, Sparkles, Filter, Check } from 'lucide-react';
import { CommunityPost } from '../types';

interface CommunityCMSProps {
  posts: CommunityPost[];
  onAddPost: (newPost: CommunityPost) => void;
}

export default function CommunityCMS({ posts, onAddPost }: CommunityCMSProps) {
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [audience, setAudience] = useState('Gửi đến toàn bộ Người dùng Ứng dụng');
  const [mockUploadedFile, setMockUploadedFile] = useState<string | null>(null);
  const [isDragOver, setIsDragOver] = useState(false);
  const [publishSuccess, setPublishSuccess] = useState(false);

  const handlePublish = (e: React.FormEvent) => {
    e.preventDefault();
    if (!title || !content) return;

    const newPost: CommunityPost = {
      id: `POST-${String(posts.length + 1).padStart(2, '0')}`,
      title,
      content,
      targetAudience: audience,
      views: 0,
      shares: 0,
      commendations: 0,
      status: 'Đã xuất bản',
      date: 'Hôm nay'
    };

    onAddPost(newPost);
    setTitle('');
    setContent('');
    setMockUploadedFile(null);
    setPublishSuccess(true);
    setTimeout(() => setPublishSuccess(false), 3000);
  };

  const triggerMockUpload = () => {
    setMockUploadedFile('banner_hiem_o_minus_hoan_hao.png');
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(true);
  };

  const handleDragLeave = () => {
    setIsDragOver(false);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setIsDragOver(false);
    setMockUploadedFile('banner_drop_image_upload.png');
  };

  return (
    <div className="space-y-6 animate-fade-in">
      {/* CMS Header */}
      <div>
        <h2 className="text-xl font-black text-gray-900 tracking-tight flex items-center">
          <FileText className="w-5.5 h-5.5 text-[#E31837] mr-2" />
          Ban Truyền thông & Bài viết Cộng đồng (Community CMS)
        </h2>
        <p className="text-xs text-gray-500 mt-1">
          Soạn thảo các thông điệp nhân văn thúc đẩy tinh thần hiến máu, tiếp sức cộng đồng trực tiếp đến thiết bị người dùng.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* COMPOSER FORM (2/3 width) */}
        <form onSubmit={handlePublish} className="lg:col-span-2 bg-white rounded-2xl border border-slate-100 p-6 shadow-sm space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <h3 className="text-xs font-bold text-gray-700 uppercase tracking-widest">Soạn Thảo Bài viết Vận Động Mới</h3>
            {publishSuccess && (
              <span className="text-xs font-bold text-emerald-600 bg-emerald-50 px-2.5 py-1 rounded-full animate-pulse flex items-center">
                <Check className="w-3.5 h-3.5 mr-1" /> Đã xuất bản lên App di động!
              </span>
            )}
          </div>

          <div>
            <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">Tiêu đề bài viết *</label>
            <input
              type="text"
              required
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              className="w-full p-2.5 border border-slate-200 rounded-lg text-xs outline-none focus:ring-1 focus:ring-[#E31837]"
              placeholder="Ví dụ: Báo động đỏ: Cần gấp 10 người hiến máu O- cứu sản phụ nguy kịch tại Hà Nội"
            />
          </div>

          <div>
            <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">Bộ lọc Khán giả Nhắm mục tiêu (Target Audience Filter)</label>
            <div className="relative">
              <Filter className="w-4 h-4 text-gray-400 absolute left-3 top-3" />
              <select
                value={audience}
                onChange={(e) => setAudience(e.target.value)}
                className="w-full p-2.5 pl-9 border border-slate-200 rounded-lg text-xs bg-white outline-none focus:ring-1 focus:ring-[#E31837] text-gray-700 font-semibold cursor-pointer"
              >
                <option>Gửi đến toàn bộ Người dùng Ứng dụng</option>
                <option>Chỉ nhắm mục tiêu Nhóm máu O- (Khẩn cấp)</option>
                <option>Chỉ nhắm mục tiêu Nhóm máu Hiếm (Rh-)</option>
                <option>Nhóm tình nguyện viên có thành tích hiến trên 5 lần</option>
              </select>
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">Nội dung bài viết</label>
            <div className="border border-slate-200 rounded-lg overflow-hidden text-xs">
              {/* Fake Toolbar */}
              <div className="bg-slate-50 border-b border-slate-200 px-3 py-2 flex items-center space-x-4 text-gray-500 font-medium">
                <button type="button" className="hover:text-gray-900 font-bold">B</button>
                <button type="button" className="hover:text-gray-900 italic font-serif">I</button>
                <button type="button" className="hover:text-gray-900 underline">U</button>
                <span className="text-gray-300">|</span>
                <button type="button" className="hover:text-gray-900 text-[10px]">🔗 Chèn link</button>
                <button type="button" onClick={triggerMockUpload} className="hover:text-gray-900 text-[10px] flex items-center">
                  <ImageIcon className="w-3.5 h-3.5 mr-1" /> Chèn ảnh
                </button>
              </div>
              <textarea
                required
                rows={5}
                value={content}
                onChange={(e) => setContent(e.target.value)}
                className="w-full p-3 border-none outline-none resize-none text-xs leading-relaxed"
                placeholder="Nhập nội dung thông điệp truyền cảm hứng, hướng dẫn cụ thể và địa điểm chuẩn bị hiến máu tại đây..."
              ></textarea>
            </div>
          </div>

          {/* DRAG & DROP ZONE */}
          <div>
            <label className="block text-xs font-bold text-gray-700 uppercase tracking-wide mb-1">Hình ảnh đính kèm (Ảnh bìa)</label>
            <div
              onDragOver={handleDragOver}
              onDragLeave={handleDragLeave}
              onDrop={handleDrop}
              onClick={triggerMockUpload}
              className={`border-2 border-dashed rounded-xl p-6 text-center transition-all cursor-pointer ${
                isDragOver ? 'border-[#E31837] bg-red-50/20' : 'border-slate-200 hover:bg-slate-50'
              }`}
            >
              <div className="flex flex-col items-center justify-center">
                <span className="text-3xl">📤</span>
                <p className="text-xs font-bold text-gray-700 mt-2">
                  {mockUploadedFile ? `✓ Đã nhận diện: ${mockUploadedFile}` : 'Kéo thả ảnh hoặc Click để chọn file'}
                </p>
                <p className="text-[10px] text-gray-400 mt-1">Hỗ trợ định dạng PNG, JPG, JPEG kích thước tối ưu 1200x630 (Tối đa 5MB)</p>
              </div>
            </div>
          </div>

          <div className="flex items-center justify-end space-x-3 pt-3 border-t border-slate-100">
            <button
              type="button"
              className="px-4 py-2 border border-slate-200 text-gray-600 rounded-lg text-xs font-bold hover:bg-slate-50 transition-colors cursor-pointer"
            >
              Lưu nháp
            </button>
            <button
              type="submit"
              className="px-4 py-2 bg-[#E31837] hover:bg-red-700 text-white rounded-lg text-xs font-bold transition-all flex items-center space-x-1.5 shadow-xs cursor-pointer"
            >
              <Send className="w-3.5 h-3.5" />
              <span>XUẤT BẢN NGAY</span>
            </button>
          </div>
        </form>

        {/* RECENT PAST ARTICLES WITH STATISTICS (1/3 width) */}
        <div className="bg-white rounded-2xl border border-slate-100 p-6 shadow-sm flex flex-col h-[650px] overflow-hidden">
          <div className="pb-3 border-b border-slate-100 mb-4">
            <h3 className="text-xs font-bold text-gray-700 uppercase tracking-widest">Bài viết đã đăng gần đây</h3>
          </div>

          <div className="flex-1 overflow-y-auto space-y-4 pr-1">
            {posts.map((post) => (
              <div
                key={post.id}
                className="p-4 border border-slate-100 rounded-xl bg-slate-50 hover:border-slate-200 hover:bg-white transition-all duration-200"
              >
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-[9px] font-mono text-gray-400 font-bold">{post.id}</span>
                  <span className="text-[9px] font-bold bg-green-50 text-green-700 px-1.5 py-0.5 rounded">
                    {post.status}
                  </span>
                </div>
                <h4 className="text-xs font-extrabold text-gray-900 line-clamp-2 leading-snug">{post.title}</h4>
                <p className="text-[9px] text-gray-400 mt-1">
                  Đăng: <strong className="text-gray-500 font-semibold">{post.date}</strong> • Đối tượng: <strong className="text-gray-500 font-semibold">{post.targetAudience}</strong>
                </p>

                {/* Engagement Statistics Row */}
                <div className="grid grid-cols-3 gap-2 mt-4 pt-3 border-t border-gray-200/60 text-center">
                  <div className="flex flex-col items-center">
                    <div className="flex items-center space-x-1 text-gray-600">
                      <Eye className="w-3.5 h-3.5" />
                      <span className="text-xs font-black">{post.views}</span>
                    </div>
                    <span className="text-[9px] text-gray-400 mt-0.5">Lượt xem</span>
                  </div>
                  <div className="flex flex-col items-center">
                    <div className="flex items-center space-x-1 text-gray-600">
                      <Share2 className="w-3.5 h-3.5" />
                      <span className="text-xs font-black">{post.shares}</span>
                    </div>
                    <span className="text-[9px] text-gray-400 mt-0.5">Lượt chia sẻ</span>
                  </div>
                  <div className="flex flex-col items-center">
                    <div className="flex items-center space-x-1 text-emerald-600 bg-emerald-50 px-1.5 py-0.5 rounded-full">
                      <ThumbsUp className="w-3 h-3" />
                      <span className="text-xs font-black">{post.commendations}</span>
                    </div>
                    <span className="text-[9px] text-gray-400 mt-0.5">Biểu dương</span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>
    </div>
  );
}
