import React, { useState } from 'react';
import { 
  Terminal, 
  Copy, 
  Check, 
  Smartphone, 
  ChevronRight, 
  FileCode, 
  Layers, 
  BookOpen, 
  Heart, 
  Code,
  Sliders,
  ExternalLink,
  Info
} from 'lucide-react';
import { FLUTTER_WIDGETS_DOCS, FLUTTER_THEME_CODE, FlutterWidgetDoc } from '../data/flutterWidgets';

interface FlutterMappingPanelProps {
  activeSelectedWidget: string;
  onSelectWidget: (widgetName: string) => void;
}

export default function FlutterMappingPanel({
  activeSelectedWidget,
  onSelectWidget
}: FlutterMappingPanelProps) {
  const [activeTab, setActiveTab] = useState<'inspector' | 'code' | 'theme'>('inspector');
  const [copied, setCopied] = useState(false);

  // Find the selected widget documentation
  const currentDoc = FLUTTER_WIDGETS_DOCS.find(
    doc => doc.name.toLowerCase() === activeSelectedWidget.toLowerCase()
  ) || FLUTTER_WIDGETS_DOCS[0];

  const handleCopy = (text: string) => {
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="bg-neutral-900 border border-neutral-800 rounded-3xl h-full flex flex-col overflow-hidden shadow-xl">
      
      {/* Panel Header */}
      <div className="bg-neutral-950 border-b border-neutral-800 px-6 py-4.5 flex justify-between items-center shrink-0">
        <div className="flex items-center gap-2.5">
          <div className="p-1.5 rounded-lg bg-red-600/10 text-red-500 border border-red-500/20">
            <Terminal className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-sm font-bold text-white flex items-center gap-1.5">
              Flutter Mapping Inspector
            </h3>
            <p className="text-[11px] text-neutral-400">Xem kiến trúc Widgets & mã nguồn Dart tương ứng</p>
          </div>
        </div>
        <div className="flex items-center gap-1.5 text-[10px] bg-neutral-900 px-2.5 py-1.5 rounded-lg border border-neutral-800 font-mono text-red-500 font-bold">
          <span>Target: Flutter SDK</span>
        </div>
      </div>

      {/* Navigation Sub-Tabs */}
      <div className="bg-neutral-900/80 px-4 py-2 border-b border-neutral-800 flex gap-2 shrink-0">
        <button
          onClick={() => setActiveTab('inspector')}
          className={`flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs font-semibold transition-all ${
            activeTab === 'inspector' 
              ? 'bg-neutral-800 text-white shadow-sm border border-neutral-700/50' 
              : 'text-neutral-400 hover:text-white'
          }`}
        >
          <Layers className="w-4 h-4" />
          <span>Sơ đồ Widgets</span>
        </button>

        <button
          onClick={() => setActiveTab('code')}
          className={`flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs font-semibold transition-all ${
            activeTab === 'code' 
              ? 'bg-neutral-800 text-white shadow-sm border border-neutral-700/50' 
              : 'text-neutral-400 hover:text-white'
          }`}
        >
          <FileCode className="w-4 h-4" />
          <span>Mã nguồn Dart ({currentDoc.flutterWidget.split(' ')[0]})</span>
        </button>

        <button
          onClick={() => setActiveTab('theme')}
          className={`flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs font-semibold transition-all ${
            activeTab === 'theme' 
              ? 'bg-neutral-800 text-white shadow-sm border border-neutral-700/50' 
              : 'text-neutral-400 hover:text-white'
          }`}
        >
          <Sliders className="w-4 h-4" />
          <span>Cấu hình Theme</span>
        </button>
      </div>

      {/* Main Content Area */}
      <div className="flex-1 overflow-y-auto p-6 scrollbar-thin scrollbar-thumb-neutral-850 scrollbar-track-transparent">
        
        {activeTab === 'inspector' && (
          <div className="space-y-6">
            
            {/* Context Notice */}
            <div className="bg-red-500/5 border border-red-500/15 rounded-xl p-4 flex gap-3 text-xs leading-relaxed text-neutral-300">
              <Info className="w-5 h-5 text-red-500 shrink-0 mt-0.5" />
              <p>
                <strong>Tương tác thông minh:</strong> Nhấp vào các phần tử của điện thoại mô phỏng bên trái, hoặc nhấp chọn các Widget trong danh sách dưới đây để lập tức ánh xạ cấu trúc tương quan trong Flutter!
              </p>
            </div>

            {/* Visual Hierarchy Mapper */}
            <div className="space-y-3">
              <h4 className="text-xs font-bold text-neutral-400 uppercase tracking-widest px-0.5">Cấu trúc phân rã UI (Widget Tree)</h4>
              
              <div className="space-y-2">
                {FLUTTER_WIDGETS_DOCS.map((doc) => {
                  const isCurrent = doc.name === currentDoc.name;
                  return (
                    <div 
                      key={doc.name}
                      onClick={() => onSelectWidget(doc.name)}
                      className={`p-4 rounded-xl border text-left cursor-pointer transition-all ${
                        isCurrent 
                          ? 'bg-red-950/20 border-red-500/50 ring-1 ring-red-500/20 shadow-md shadow-red-950/10' 
                          : 'bg-neutral-950 border-neutral-850 hover:bg-neutral-850 hover:border-neutral-700'
                      }`}
                    >
                      <div className="flex justify-between items-center">
                        <div className="space-y-0.5">
                          <span className="text-[10px] text-red-500 font-extrabold uppercase tracking-wider">{doc.category}</span>
                          <h5 className="text-xs font-bold text-white flex items-center gap-1.5">
                            {doc.name}
                            {isCurrent && <span className="w-2 h-2 bg-red-500 rounded-full animate-ping"></span>}
                          </h5>
                        </div>
                        <span className="text-[10px] font-mono bg-neutral-900 border border-neutral-800 text-neutral-400 px-2.5 py-1 rounded-md">
                          {doc.flutterWidget}
                        </span>
                      </div>

                      <p className="text-[11px] text-neutral-400 mt-2 leading-relaxed">
                        {doc.description}
                      </p>

                      {/* Display key properties list */}
                      <div className="mt-3.5 pt-3 border-t border-neutral-850/60 space-y-1.5">
                        <span className="text-[9px] font-bold text-neutral-500 uppercase tracking-wider block">Các thuộc tính Flutter chủ chốt:</span>
                        <div className="flex flex-wrap gap-1.5">
                          {doc.keyProperties.map((prop, pi) => (
                            <code key={pi} className="text-[9.5px] font-mono bg-neutral-900 text-red-400 px-2 py-0.5 rounded border border-neutral-800">
                              {prop}
                            </code>
                          ))}
                        </div>
                      </div>

                      {/* Code CTA */}
                      {isCurrent && (
                        <div className="mt-4 flex justify-end">
                          <button 
                            onClick={(e) => {
                              e.stopPropagation();
                              setActiveTab('code');
                            }}
                            className="bg-red-600 hover:bg-red-500 text-white text-[10px] font-bold px-3 py-1.5 rounded-lg flex items-center gap-1"
                          >
                            <Code className="w-3.5 h-3.5" />
                            <span>Xem mã nguồn Dart tương ứng</span>
                          </button>
                        </div>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Architecture guidelines card */}
            <div className="bg-neutral-950 border border-neutral-850 rounded-xl p-4 space-y-3">
              <h5 className="text-xs font-bold text-white flex items-center gap-1.5">
                <BookOpen className="w-4 h-4 text-red-500" />
                Nguyên lý Thiết kế Tech-Humanism
              </h5>
              <p className="text-[11px] text-neutral-400 leading-relaxed">
                Ứng dụng <strong>Pulse Link</strong> kết hợp giữa màu đỏ đậm nhiệt huyết (#E31837) và màu tối sâu thẳm (#121212) để tạo hiệu ứng tương phản mạnh mẽ, khơi dậy tinh thần nhân ái cứu người (Hiệp sĩ). Khi triển khai Flutter, hãy dùng các thành phần bo tròn 16-24dp, đổ bóng mờ nhạt và tận dụng <code>LinearGradient</code> tinh tế để giữ được tính nguyên bản.
              </p>
            </div>

          </div>
        )}

        {activeTab === 'code' && (
          <div className="space-y-4">
            
            {/* Code Header Metadata */}
            <div className="flex justify-between items-center bg-neutral-950 border border-neutral-850 rounded-xl p-3">
              <div>
                <span className="text-[9px] text-neutral-500 uppercase font-bold">Thành phần đang chọn</span>
                <h4 className="text-xs font-bold text-white">{currentDoc.name}</h4>
              </div>
              <button 
                onClick={() => handleCopy(currentDoc.dartCode)}
                className="bg-neutral-900 hover:bg-neutral-850 text-neutral-300 hover:text-white border border-neutral-800 text-xs font-semibold px-3 py-1.5 rounded-lg flex items-center gap-1.5 active:scale-95 transition-all"
              >
                {copied ? <Check className="w-3.5 h-3.5 text-emerald-500" /> : <Copy className="w-3.5 h-3.5" />}
                <span>{copied ? 'Đã sao chép!' : 'Sao chép Dart'}</span>
              </button>
            </div>

            {/* Dart Syntax Highlight Display */}
            <div className="relative rounded-xl border border-neutral-850 overflow-hidden bg-neutral-950 font-mono text-[11px] leading-relaxed shadow-inner">
              <div className="bg-neutral-900 px-4 py-2 border-b border-neutral-850 text-[10px] text-neutral-500 flex justify-between items-center">
                <span>DART RECIPE</span>
                <span className="text-red-500/80 font-bold">100% Flutter Native</span>
              </div>
              
              <pre className="p-4 overflow-x-auto text-neutral-300 max-h-[480px] scrollbar-thin scrollbar-thumb-neutral-800">
                {currentDoc.dartCode}
              </pre>
            </div>

          </div>
        )}

        {activeTab === 'theme' && (
          <div className="space-y-5">
            
            <div className="bg-neutral-950 border border-neutral-850 rounded-xl p-4 space-y-3">
              <h4 className="text-xs font-bold text-white flex items-center gap-1.5">
                <Sliders className="w-4 h-4 text-red-500" />
                Cấu hình Theme hệ thống (PulseLinkTheme)
              </h4>
              <p className="text-[11px] text-neutral-400 leading-relaxed">
                Trong Flutter, cấu hình màu sắc thương hiệu toàn cục trong file <code>main.dart</code> sẽ đồng bộ giao diện cho toàn bộ màn hình vệ tinh. Dưới đây là lớp cấu hình mã màu chuẩn Crimson Red và Deep Blood Red.
              </p>
            </div>

            {/* Copy theme code block */}
            <div className="relative rounded-xl border border-neutral-850 overflow-hidden bg-neutral-950 font-mono text-[11px] leading-relaxed">
              <div className="bg-neutral-900 px-4 py-2 border-b border-neutral-850 text-[10px] text-neutral-500 flex justify-between items-center">
                <span>pulse_link_theme.dart</span>
                <button 
                  onClick={() => handleCopy(FLUTTER_THEME_CODE)}
                  className="text-neutral-400 hover:text-white flex items-center gap-1"
                >
                  {copied ? <Check className="w-3 h-3 text-emerald-400" /> : <Copy className="w-3 h-3" />}
                  <span>Sao chép</span>
                </button>
              </div>
              
              <pre className="p-4 overflow-x-auto text-neutral-300 max-h-[380px] scrollbar-thin scrollbar-thumb-neutral-800">
                {FLUTTER_THEME_CODE}
              </pre>
            </div>

            {/* Quick integration recipe */}
            <div className="bg-neutral-950 border border-neutral-850 rounded-xl p-4 text-xs space-y-2">
              <h5 className="font-bold text-white">Cách tích hợp vào Flutter App:</h5>
              <ol className="list-decimal pl-4 space-y-1.5 text-neutral-400 text-[11px]">
                <li>Khởi tạo một file mới <code>pulse_link_theme.dart</code> và dán đoạn mã trên.</li>
                <li>Trong file <code>main.dart</code>, import file cấu hình theme.</li>
                <li>Gán <code>theme: PulseLinkTheme.darkTheme</code> vào phương thức khởi tạo <code>MaterialApp</code>.</li>
              </ol>
            </div>

          </div>
        )}

      </div>

      {/* Footer Branding Info */}
      <div className="bg-neutral-950 border-t border-neutral-800 px-6 py-4 flex justify-between items-center text-[10px] text-neutral-500 shrink-0">
        <span className="flex items-center gap-1">
          Thiết kế bởi <Heart className="w-3 h-3 text-red-500 fill-red-500" /> Pulse Link Team
        </span>
        <span className="font-mono">v1.2.0-Alpha</span>
      </div>

    </div>
  );
}
