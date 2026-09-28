'use client';
import { useState } from 'react';
import ReactMarkdown from 'react-markdown';
import { Loader2, PenTool, ChevronDown } from 'lucide-react';

const targets = [
  'Blog Post', 'Email', 'Essay', 'Social Media Post', 
  'Code Snippet', 'Poem', 'Business Plan', 'Product Description'
];

export default function WriterPage() {
  const [topic, setTopic] = useState('');
  const [target, setTarget] = useState(targets[0]);
  const [output, setOutput] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const generateContent = async () => {
    if (!topic.trim()) return;
    setIsLoading(true);
    
    try {
      const response = await fetch('https://glow-forge-ai.onrender.com/api/writer/generate/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          topic: topic,
          target_output: target,
          tone: 'professional',
          language: 'English',
          length: 'medium'
        }),
      });

      if (!response.ok) throw new Error('API Error');
      
      const data = await response.json();
      setOutput(data.result);
    } catch (error) {
      setOutput('*Failed to reach the forge. Please try again later.*');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-full max-w-4xl mx-auto space-y-6">
      <h1 className="text-2xl font-bold text-white tracking-widest">AI WRITER</h1>

      <div className="glass-panel rounded-3xl p-6">
        <div className="space-y-4">
          <div>
            <label className="block text-purple-200 text-sm mb-2">Output Type</label>
            <div className="relative">
              <select
                value={target}
                onChange={(e) => setTarget(e.target.value)}
                className="w-full bg-black/40 border border-white/10 rounded-xl py-3 pl-4 pr-10 text-white appearance-none focus:outline-none focus:border-purple-500 transition-colors"
              >
                {targets.map(t => <option key={t} value={t} className="bg-gray-900">{t}</option>)}
              </select>
              <ChevronDown size={18} className="absolute right-4 top-3.5 text-purple-400 pointer-events-none" />
            </div>
          </div>

          <div>
            <label className="block text-purple-200 text-sm mb-2">Topic / Content</label>
            <textarea
              value={topic}
              onChange={(e) => setTopic(e.target.value)}
              placeholder="What do you want me to write about?"
              rows={4}
              className="w-full bg-black/40 border border-white/10 rounded-xl py-3 px-4 text-white placeholder-purple-300/50 focus:outline-none focus:border-purple-500 transition-colors resize-none"
            />
          </div>

          <button
            onClick={generateContent}
            disabled={!topic.trim() || isLoading}
            className="w-full bg-purple-600 hover:bg-purple-500 text-white font-bold py-4 rounded-xl transition-all glow-effect disabled:opacity-50 flex items-center justify-center gap-2 tracking-wider"
          >
            {isLoading ? (
              <>
                <Loader2 size={20} className="animate-spin" />
                FORGING CONTENT...
              </>
            ) : (
              <>
                <PenTool size={20} />
                GENERATE CONTENT
              </>
            )}
          </button>
        </div>
      </div>

      {output && (
        <div className="glass-panel rounded-3xl p-6 flex-1 overflow-y-auto">
          <div className="prose prose-invert max-w-none prose-p:leading-relaxed prose-pre:bg-black/50 prose-pre:border prose-pre:border-white/10 prose-headings:text-purple-300">
            <ReactMarkdown>{output}</ReactMarkdown>
          </div>
        </div>
      )}
    </div>
  );
}
