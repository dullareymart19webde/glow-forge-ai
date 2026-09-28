'use client';
import { useState } from 'react';
import ReactMarkdown from 'react-markdown';
import { Loader2, FileText } from 'lucide-react';

export default function ResumePage() {
  const [jobTitle, setJobTitle] = useState('');
  const [experience, setExperience] = useState('');
  const [skills, setSkills] = useState('');
  const [education, setEducation] = useState('');
  const [output, setOutput] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const generateResume = async () => {
    if (!jobTitle.trim() || !experience.trim() || !skills.trim()) return;
    setIsLoading(true);
    
    try {
      const response = await fetch('https://glow-forge-ai.onrender.com/api/resume/build', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          job_title: jobTitle,
          experience: experience,
          skills: skills,
          education: education,
        }),
      });

      if (!response.ok) throw new Error('API Error');
      
      const data = await response.json();
      setOutput(data.resume);
    } catch (error) {
      setOutput('*Failed to reach the forge. Please try again later.*');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col md:flex-row h-full gap-6">
      <div className="w-full md:w-1/2 flex flex-col space-y-6">
        <h1 className="text-2xl font-bold text-white tracking-widest shrink-0">RESUME BUILDER</h1>

        <div className="glass-panel rounded-3xl p-6 flex-1 overflow-y-auto space-y-4">
          <div>
            <label className="block text-purple-200 text-sm mb-2">Target Job Title</label>
            <input
              value={jobTitle}
              onChange={(e) => setJobTitle(e.target.value)}
              placeholder="e.g. Senior Software Engineer"
              className="w-full bg-black/40 border border-white/10 rounded-xl py-3 px-4 text-white placeholder-purple-300/50 focus:outline-none focus:border-purple-500 transition-colors"
            />
          </div>

          <div>
            <label className="block text-purple-200 text-sm mb-2">Work Experience</label>
            <textarea
              value={experience}
              onChange={(e) => setExperience(e.target.value)}
              placeholder="List your previous roles and achievements..."
              rows={4}
              className="w-full bg-black/40 border border-white/10 rounded-xl py-3 px-4 text-white placeholder-purple-300/50 focus:outline-none focus:border-purple-500 transition-colors resize-none"
            />
          </div>

          <div>
            <label className="block text-purple-200 text-sm mb-2">Key Skills</label>
            <textarea
              value={skills}
              onChange={(e) => setSkills(e.target.value)}
              placeholder="e.g. Python, React, Project Management..."
              rows={3}
              className="w-full bg-black/40 border border-white/10 rounded-xl py-3 px-4 text-white placeholder-purple-300/50 focus:outline-none focus:border-purple-500 transition-colors resize-none"
            />
          </div>

          <div>
            <label className="block text-purple-200 text-sm mb-2">Education (Optional)</label>
            <textarea
              value={education}
              onChange={(e) => setEducation(e.target.value)}
              placeholder="e.g. B.S. Computer Science, University of Mars..."
              rows={2}
              className="w-full bg-black/40 border border-white/10 rounded-xl py-3 px-4 text-white placeholder-purple-300/50 focus:outline-none focus:border-purple-500 transition-colors resize-none"
            />
          </div>

          <button
            onClick={generateResume}
            disabled={!jobTitle.trim() || !experience.trim() || !skills.trim() || isLoading}
            className="w-full bg-purple-600 hover:bg-purple-500 text-white font-bold py-4 rounded-xl transition-all glow-effect disabled:opacity-50 flex items-center justify-center gap-2 tracking-wider mt-4"
          >
            {isLoading ? (
              <>
                <Loader2 size={20} className="animate-spin" />
                FORGING RESUME...
              </>
            ) : (
              <>
                <FileText size={20} />
                GENERATE RESUME
              </>
            )}
          </button>
        </div>
      </div>

      <div className="w-full md:w-1/2 glass-panel rounded-3xl p-6 md:mt-[3.75rem] flex-1 h-[600px] md:h-auto overflow-y-auto">
        {isLoading ? (
          <div className="h-full flex flex-col items-center justify-center text-center">
            <div className="w-16 h-16 rounded-full glow-effect bg-teal-900/50 flex items-center justify-center mb-6">
              <Loader2 size={32} className="text-teal-400 animate-spin" />
            </div>
            <h2 className="text-xl font-bold text-white mb-2 tracking-widest">Forging Resume...</h2>
            <p className="text-teal-200/70">Parsing AI experience</p>
          </div>
        ) : output ? (
          <div className="prose prose-invert max-w-none prose-p:leading-relaxed prose-pre:bg-black/50 prose-pre:border prose-pre:border-white/10 prose-headings:text-teal-300">
            <ReactMarkdown>{output}</ReactMarkdown>
          </div>
        ) : (
          <div className="h-full flex flex-col items-center justify-center text-center px-4">
            <FileText size={48} className="text-white/20 mb-4" />
            <p className="text-white/50 max-w-sm">
              Fill out the form and generate to see your ATS Resume Data.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
