'use client';
import { useState } from 'react';
import { Loader2, FileText, Briefcase, GraduationCap, Code, User as UserIcon } from 'lucide-react';

interface ResumeData {
  personal_info: { title?: string; name?: string; email?: string; phone?: string };
  summary?: string;
  experience: string[];
  education: string[];
  skills: string[];
}

export default function ResumePage() {
  const [jobTitle, setJobTitle] = useState('');
  const [experience, setExperience] = useState('');
  const [skills, setSkills] = useState('');
  const [education, setEducation] = useState('');
  const [output, setOutput] = useState<ResumeData | null>(null);
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [isLoading, setIsLoading] = useState(false);

  const generateResume = async () => {
    if (!jobTitle.trim() || !experience.trim() || !skills.trim()) return;
    setIsLoading(true);
    setErrorMsg(null);
    
    try {
      const response = await fetch('https://glow-forge-ai.onrender.com/api/resume/generate/', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          personal_info: { title: jobTitle },
          experience: [experience],
          skills: [skills],
          education: [education],
        }),
      });

      if (!response.ok) throw new Error('API Error');
      
      const data = await response.json();
      setOutput(data as ResumeData);
    } catch (error) {
      setErrorMsg('Failed to reach the forge. Please try again later.');
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col md:flex-row h-full gap-6">
      <div className="w-full md:w-1/2 flex flex-col space-y-6">
        <h1 className="text-2xl font-bold text-white tracking-widest shrink-0">RESUME BUILDER</h1>

        <div className="bg-[#1a0f2e]/60 border border-white/5 shadow-2xl rounded-3xl p-6 flex-1 overflow-y-auto space-y-4">
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
            className="w-full bg-gradient-to-r from-purple-600 to-indigo-600 hover:opacity-90 text-white font-bold py-4 rounded-xl transition-all disabled:opacity-50 flex items-center justify-center gap-2 tracking-wider mt-4 shadow-lg shadow-purple-500/20"
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

      <div className="w-full md:w-1/2 bg-[#1a0f2e]/60 border border-white/5 shadow-2xl rounded-3xl p-6 md:mt-[3.75rem] flex-1 h-[600px] md:h-auto overflow-y-auto relative">
        {isLoading ? (
          <div className="h-full flex flex-col items-center justify-center text-center">
            <div className="w-16 h-16 rounded-3xl bg-gradient-to-br from-teal-500/20 to-emerald-500/20 border border-white/10 flex items-center justify-center mb-6 shadow-2xl relative">
              <div className="absolute inset-0 bg-teal-500 blur-2xl opacity-20 rounded-full"></div>
              <Loader2 size={32} className="text-teal-400 animate-spin relative z-10" />
            </div>
            <h2 className="text-xl font-bold text-white mb-2 tracking-widest">Forging Resume...</h2>
            <p className="text-teal-200/70">Parsing AI experience</p>
          </div>
        ) : errorMsg ? (
          <div className="h-full flex flex-col items-center justify-center text-center text-red-400 px-4">
            <p>{errorMsg}</p>
          </div>
        ) : output ? (
          <div className="bg-white text-gray-900 p-8 rounded-2xl shadow-xl font-sans min-h-full">
            <div className="border-b-2 border-gray-800 pb-6 mb-6 text-center">
              <h2 className="text-3xl font-black uppercase tracking-tight text-gray-900 mb-2">
                {output.personal_info?.name || "Professional Identity"}
              </h2>
              <p className="text-xl text-teal-700 font-semibold mb-3">{output.personal_info?.title || jobTitle}</p>
              <div className="flex justify-center gap-4 text-sm text-gray-600 font-medium">
                {output.personal_info?.email && <span>{output.personal_info.email}</span>}
                {output.personal_info?.phone && <span>• {output.personal_info.phone}</span>}
              </div>
            </div>

            {output.summary && (
              <div className="mb-6">
                <div className="flex items-center gap-2 mb-3 text-teal-700 border-b border-gray-200 pb-1">
                  <UserIcon size={18} />
                  <h3 className="text-lg font-bold uppercase tracking-wider">Professional Summary</h3>
                </div>
                <p className="text-gray-700 leading-relaxed text-sm">{output.summary}</p>
              </div>
            )}

            {output.experience && output.experience.length > 0 && (
              <div className="mb-6">
                <div className="flex items-center gap-2 mb-3 text-teal-700 border-b border-gray-200 pb-1">
                  <Briefcase size={18} />
                  <h3 className="text-lg font-bold uppercase tracking-wider">Experience</h3>
                </div>
                <ul className="list-disc pl-5 space-y-2 text-sm text-gray-700">
                  {output.experience.map((exp, idx) => (
                    <li key={idx} className="leading-relaxed">{exp}</li>
                  ))}
                </ul>
              </div>
            )}

            {output.skills && output.skills.length > 0 && (
              <div className="mb-6">
                <div className="flex items-center gap-2 mb-3 text-teal-700 border-b border-gray-200 pb-1">
                  <Code size={18} />
                  <h3 className="text-lg font-bold uppercase tracking-wider">Skills</h3>
                </div>
                <div className="flex flex-wrap gap-2">
                  {output.skills.map((skill, idx) => (
                    <span key={idx} className="bg-gray-100 text-gray-800 px-3 py-1 rounded-md text-xs font-bold border border-gray-200">
                      {skill}
                    </span>
                  ))}
                </div>
              </div>
            )}

            {output.education && output.education.length > 0 && (
              <div>
                <div className="flex items-center gap-2 mb-3 text-teal-700 border-b border-gray-200 pb-1">
                  <GraduationCap size={18} />
                  <h3 className="text-lg font-bold uppercase tracking-wider">Education</h3>
                </div>
                <ul className="list-disc pl-5 space-y-2 text-sm text-gray-700">
                  {output.education.map((edu, idx) => (
                    <li key={idx} className="leading-relaxed">{edu}</li>
                  ))}
                </ul>
              </div>
            )}
          </div>
        ) : (
          <div className="h-full flex flex-col items-center justify-center text-center px-4">
            <div className="relative mb-6">
              <div className="absolute inset-0 bg-teal-500 blur-3xl opacity-20 rounded-full"></div>
              <div className="w-24 h-24 rounded-3xl bg-gradient-to-br from-teal-500/10 to-emerald-500/10 border border-white/10 flex items-center justify-center relative z-10 shadow-2xl">
                <FileText size={42} className="text-teal-400" strokeWidth={1.5} />
              </div>
            </div>
            <h2 className="text-2xl font-bold text-white mb-3">Ready to forge your career?</h2>
            <p className="text-gray-400 max-w-sm text-sm leading-relaxed">
              Fill out the form on the left and our AI will instantly generate an ATS-optimized professional resume.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}
