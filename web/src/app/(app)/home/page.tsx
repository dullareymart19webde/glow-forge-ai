'use client';
import { useEffect, useState } from 'react';
import { account } from '@/lib/appwrite';
import { useRouter } from 'next/navigation';
import Link from 'next/link';
import { motion } from 'framer-motion';
import { MessageSquare, PenTool, FileText, Image as ImageIcon, LogOut } from 'lucide-react';

const tools = [
  { name: 'AI Chat', icon: MessageSquare, route: '/chat', desc: 'Converse with an advanced AI assistant' },
  { name: 'AI Writer', icon: PenTool, route: '/writer', desc: 'Generate blog posts, emails, and code' },
  { name: 'Resume Builder', icon: FileText, route: '/resume', desc: 'Create ATS-friendly resumes instantly' },
  { name: 'Photo Studio', icon: ImageIcon, route: '/photo', desc: 'Remove backgrounds & enhance images' }
];

export default function HomePage() {
  const [userName, setUserName] = useState('');
  const router = useRouter();

  useEffect(() => {
    account.get().then((user) => {
      setUserName(user.name);
    }).catch(() => {
      router.push('/');
    });
  }, [router]);

  const handleLogout = async () => {
    try {
      await account.deleteSession('current');
      router.push('/');
    } catch (e) {
      console.error('Failed to logout', e);
    }
  };

  return (
    <div className="max-w-5xl mx-auto pt-8 md:pt-12 px-2 md:px-0">
      <div className="flex justify-between items-end mb-12">
        <div>
          <h1 className="text-4xl md:text-5xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-white via-purple-100 to-purple-300 mb-3 tracking-tight">
            Welcome, {userName || 'Creator'}
          </h1>
          <p className="text-purple-300/80 text-lg">What will you forge today?</p>
        </div>
        <button 
          onClick={handleLogout}
          className="group flex items-center gap-2 px-5 py-2.5 rounded-full bg-white/5 hover:bg-red-500/10 text-gray-300 hover:text-red-400 transition-all border border-white/10 hover:border-red-500/30"
        >
          <LogOut size={18} className="group-hover:rotate-12 transition-transform" />
          <span className="hidden md:inline font-medium text-sm">Sign Out</span>
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {tools.map((tool, idx) => {
          const Icon = tool.icon;
          return (
            <Link href={tool.route} key={tool.name}>
              <motion.div 
                initial={{ opacity: 0, y: 15 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: idx * 0.1, duration: 0.4, ease: "easeOut" }}
                className="relative overflow-hidden bg-gradient-to-br from-white/[0.07] to-transparent border border-white/10 p-8 rounded-3xl hover:bg-white/[0.12] hover:border-purple-500/50 hover:shadow-[0_0_30px_rgba(168,85,247,0.15)] transition-all cursor-pointer group h-full flex flex-col justify-center min-h-[180px]"
              >
                <div className="absolute top-0 right-0 w-32 h-32 bg-purple-500/10 rounded-full blur-3xl group-hover:bg-purple-500/20 transition-all -translate-y-1/2 translate-x-1/2"></div>
                
                <div className="flex items-center gap-5 mb-3 relative z-10">
                  <div className="p-3.5 rounded-2xl bg-white/5 text-purple-300 group-hover:scale-110 group-hover:bg-purple-500 group-hover:text-white group-hover:shadow-[0_0_20px_rgba(168,85,247,0.4)] transition-all duration-300">
                    <Icon size={28} strokeWidth={2} />
                  </div>
                  <h2 className="text-2xl font-bold text-gray-100 tracking-wide group-hover:text-white transition-colors">{tool.name}</h2>
                </div>
                <p className="text-gray-400 text-sm leading-relaxed relative z-10 pl-[4.5rem]">
                  {tool.desc}
                </p>
              </motion.div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
