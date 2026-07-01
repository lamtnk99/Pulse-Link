import React, { useState } from 'react';
import { Clipboard, Check, X, FileCode, Server } from 'lucide-react';
import { vueTemplates } from '../vueTemplates';

interface VueCodeViewerProps {
  isOpen: boolean;
  onClose: () => void;
  defaultModule?: 'shell' | 'dashboard' | 'sos' | 'events' | 'community' | 'rbac';
}

export default function VueCodeViewer({ isOpen, onClose, defaultModule = 'shell' }: VueCodeViewerProps) {
  const [selectedModule, setSelectedModule] = useState<keyof typeof vueTemplates>(defaultModule);
  const [copied, setCopied] = useState(false);

  if (!isOpen) return null;

  const code = vueTemplates[selectedModule];

  const handleCopy = async () => {
    try {
      await navigator.clipboard.writeText(code);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Không thể sao chép mã nguồn:', err);
    }
  };

  const moduleNames: Record<keyof typeof vueTemplates, string> = {
    shell: '1. Global System Shell (Layout)',
    dashboard: '2. Module 1: Dashboard Overview',
    sos: '3. Module 2: Emergency Response',
    events: '4. Module 3: Donation Events',
    community: '5. Module 4: Community CMS',
    rbac: '6. Module 5: RBAC Personnel',
  };

  return (
    <div className="fixed inset-0 z-50 flex justify-end bg-black/50 backdrop-blur-xs transition-opacity animate-fade-in">
      <div className="w-full max-w-3xl bg-[#121212] h-full flex flex-col shadow-2xl border-l border-neutral-800 text-neutral-300 animate-slide-in">
        {/* Header */}
        <div className="p-6 border-b border-neutral-800 flex items-center justify-between bg-[#181818]">
          <div className="flex items-center space-x-3">
            <div className="w-9 h-9 rounded-lg bg-emerald-500/10 flex items-center justify-center text-emerald-400">
              <FileCode className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-white tracking-wider uppercase">MÃ NGUỒN VUE 3 (COMPOSITION API)</h3>
              <p className="text-[10px] text-neutral-400">Xem và sao chép mã nguồn cho dự án Vue 3 của bạn</p>
            </div>
          </div>
          <button
            onClick={onClose}
            className="p-1.5 rounded-lg hover:bg-neutral-800 text-neutral-400 hover:text-white transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Module Selector */}
        <div className="p-4 bg-[#141414] border-b border-neutral-800 flex flex-wrap gap-2 items-center">
          <span className="text-xs text-neutral-400 font-semibold mr-2">Chọn Module:</span>
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-2 w-full mt-2 sm:mt-0 sm:flex-1">
            {(Object.keys(vueTemplates) as Array<keyof typeof vueTemplates>).map((key) => (
              <button
                key={key}
                onClick={() => {
                  setSelectedModule(key);
                  setCopied(false);
                }}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold text-left transition-all ${
                  selectedModule === key
                    ? 'bg-emerald-500 text-black font-extrabold shadow-md shadow-emerald-500/20'
                    : 'bg-neutral-800 hover:bg-neutral-700 text-neutral-300'
                }`}
              >
                {moduleNames[key].split(': ')[1] || moduleNames[key]}
              </button>
            ))}
          </div>
        </div>

        {/* Code Content & Action Bar */}
        <div className="p-4 bg-[#0a0a0a] flex items-center justify-between border-b border-neutral-800">
          <div className="flex items-center space-x-2 text-xs font-mono text-neutral-400">
            <span className="w-2.5 h-2.5 rounded-full bg-emerald-500"></span>
            <span>{selectedModule === 'shell' ? 'PulseLinkShell.vue' : `${selectedModule.toUpperCase() + selectedModule.slice(1)}Module.vue`}</span>
          </div>
          <button
            onClick={handleCopy}
            className={`px-4 py-2 rounded-lg text-xs font-bold flex items-center space-x-2 transition-all ${
              copied
                ? 'bg-emerald-600 text-white'
                : 'bg-neutral-800 hover:bg-neutral-700 text-white'
            }`}
          >
            {copied ? (
              <>
                <Check className="w-4 h-4" />
                <span>ĐÃ SAO CHÉP! ✓</span>
              </>
            ) : (
              <>
                <Clipboard className="w-4 h-4" />
                <span>SAO CHÉP MÃ NGUỒN</span>
              </>
            )}
          </button>
        </div>

        {/* Code Block Container */}
        <div className="flex-1 overflow-auto p-6 bg-[#0c0c0c] font-mono text-xs leading-relaxed select-text">
          <pre className="text-emerald-300 whitespace-pre scrollbar-thin">
            <code>{code}</code>
          </pre>
        </div>

        {/* Footer info */}
        <div className="p-4 bg-[#141414] border-t border-neutral-800 text-[10px] text-neutral-500 flex items-center justify-between font-mono">
          <span>Pulse Link Design System v1.0.0</span>
          <span>Composition API (&lt;script setup&gt;)</span>
        </div>
      </div>
    </div>
  );
}
