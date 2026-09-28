'use client';
import { useState, useRef } from 'react';
import { Loader2, Image as ImageIcon, Download, Upload } from 'lucide-react';

const tools = [
  { id: 'remove-bg', label: 'Remove BG', icon: '🧹' },
  { id: 'enhance', label: 'Enhance', icon: '✨' },
  { id: 'sharpen', label: 'Sharpen', icon: '🔍' },
  { id: 'sketch', label: 'Sketch', icon: '✏️' },
  { id: 'black-white', label: 'B&W', icon: '🔲' },
];

export default function PhotoPage() {
  const [selectedImage, setSelectedImage] = useState<File | null>(null);
  const [previewUrl, setPreviewUrl] = useState<string | null>(null);
  const [processedUrl, setProcessedUrl] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (file) {
      setSelectedImage(file);
      setPreviewUrl(URL.createObjectURL(file));
      setProcessedUrl(null);
      setError(null);
    }
  };

  const processImage = async (type: string) => {
    if (!selectedImage) return;
    setIsLoading(true);
    setError(null);

    const formData = new FormData();
    formData.append('file', selectedImage);
    formData.append('type', type);

    try {
      const response = await fetch('https://glow-forge-ai.onrender.com/api/image/process', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) throw new Error('Failed to process image');

      const blob = await response.blob();
      setProcessedUrl(URL.createObjectURL(blob));
    } catch (error) {
      setError('The Forge failed to process this image. The file might be too large, or our servers are busy. Please try another photo.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-full max-w-5xl mx-auto space-y-6">
      <h1 className="text-2xl font-bold text-white tracking-widest shrink-0">AI PHOTO STUDIO</h1>

      {error && (
        <div className="bg-red-500/10 border border-red-500/30 text-red-400 px-6 py-4 rounded-2xl flex items-center gap-3 animate-in fade-in slide-in-from-top-4 duration-300">
          <div className="bg-red-500/20 p-2 rounded-full">
            <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clipRule="evenodd" />
            </svg>
          </div>
          <span className="font-medium text-sm">{error}</span>
          <button onClick={() => setError(null)} className="ml-auto text-red-400 hover:text-red-300 transition-colors">
            <svg xmlns="http://www.w3.org/2000/svg" className="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path fillRule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clipRule="evenodd" />
            </svg>
          </button>
        </div>
      )}

      {selectedImage && (
        <div className="flex flex-wrap justify-center gap-3">
          {tools.map(tool => (
            <button
              key={tool.id}
              onClick={() => processImage(tool.id)}
              disabled={isLoading}
              className="bg-white/10 hover:bg-white/20 text-white px-4 py-2 rounded-full text-sm font-medium transition-colors border border-white/5 flex items-center gap-2 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              <span>{tool.icon}</span>
              {tool.label}
            </button>
          ))}
        </div>
      )}

      {isLoading && (
        <div className="flex-1 flex flex-col items-center justify-center text-center">
          <div className="w-16 h-16 rounded-full glow-effect bg-amber-900/50 flex items-center justify-center mb-6 shadow-[0_0_30px_rgba(251,191,36,0.3)]">
            <Loader2 size={32} className="text-amber-400 animate-spin" />
          </div>
          <h2 className="text-xl font-bold text-white mb-2 tracking-widest">Forging Image...</h2>
          <p className="text-amber-200/70">Applying AI magic</p>
        </div>
      )}

      {!isLoading && (
        <div className="flex-1 flex flex-col md:flex-row gap-6 h-[400px]">
          <div className="flex-1 bg-[#1E1E1E] rounded-3xl border border-[#333333] overflow-hidden flex flex-col relative">
            {previewUrl ? (
              <img src={previewUrl} alt="Original" className="w-full h-full object-contain p-4" />
            ) : (
              <div className="flex-1 flex flex-col items-center justify-center text-white/30">
                <ImageIcon size={48} className="mb-4" />
                <p>No Image Selected</p>
              </div>
            )}
            <div className="absolute top-4 left-4 bg-black/60 px-3 py-1 rounded-full text-xs text-white/70">ORIGINAL</div>
          </div>

          <div className="flex-1 bg-[#1E1E1E] rounded-3xl border-2 border-purple-500 shadow-[0_0_20px_rgba(168,85,247,0.2)] overflow-hidden flex flex-col relative">
            {processedUrl ? (
              <img src={processedUrl} alt="Processed" className="w-full h-full object-contain p-4" />
            ) : (
              <div className="flex-1 flex items-center justify-center text-white/50">
                Processed Output
              </div>
            )}
            <div className="absolute top-4 left-4 bg-purple-600 px-3 py-1 rounded-full text-xs text-white font-bold tracking-wide">FORGED</div>
          </div>
        </div>
      )}

      <div className="flex flex-col sm:flex-row gap-4 shrink-0">
        <input 
          type="file" 
          accept="image/*" 
          className="hidden" 
          ref={fileInputRef}
          onChange={handleFileChange}
        />
        <button
          onClick={() => fileInputRef.current?.click()}
          disabled={isLoading}
          className="flex-1 bg-[#1E1E1E] hover:bg-[#2A2A2A] text-white border border-[#333333] font-bold py-4 rounded-xl transition-all flex items-center justify-center gap-2 disabled:opacity-50"
        >
          <Upload size={20} />
          Select Photo
        </button>

        {selectedImage && (
          <a
            href={processedUrl || previewUrl!}
            download={`glowforge_${Date.now()}.png`}
            className={`flex-1 font-bold py-4 rounded-xl transition-all flex items-center justify-center gap-2 ${
              isLoading || !processedUrl
                ? 'bg-amber-700/50 text-white/50 cursor-not-allowed border border-amber-900/50'
                : 'bg-amber-600 hover:bg-amber-500 text-white glow-effect shadow-[0_0_15px_rgba(217,119,6,0.4)]'
            }`}
            onClick={(e) => {
              if (isLoading || !processedUrl) e.preventDefault();
            }}
          >
            <Download size={20} />
            Save Photo
          </a>
        )}
      </div>
    </div>
  );
}
