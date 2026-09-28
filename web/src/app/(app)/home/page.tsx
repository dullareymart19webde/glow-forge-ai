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
    <div className="max-w-6xl mx-auto">
      <div className="flex justify-between items-center mb-12 mt-4">
        <div>
          <h1 className="text-3xl font-bold text-white mb-2">Welcome, {userName}</h1>
          <p className="text-purple-300">What would you like to create today?</p>
        </div>
        <button 
          onClick={handleLogout}
          className="flex items-center gap-2 px-4 py-2 rounded-xl bg-red-500/10 text-red-400 hover:bg-red-500/20 transition-colors border border-red-500/20"
        >
          <LogOut size={18} />
          <span className="hidden md:inline font-semibold">Sign Out</span>
        </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {tools.map((tool, idx) => {
          const Icon = tool.icon;
          return (
            <Link href={tool.route} key={tool.name}>
              <motion.div 
                initial={{ opacity: 0, y: 20 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: idx * 0.1 }}
                className="glass-panel p-6 rounded-3xl hover:bg-white/5 transition-all cursor-pointer group h-full flex flex-col justify-center min-h-[160px]"
              >
                <div className="flex items-center gap-4 mb-4">
                  <div className="p-4 rounded-2xl bg-purple-900/40 text-purple-400 group-hover:scale-110 group-hover:bg-purple-600 group-hover:text-white transition-all glow-effect">
                    <Icon size={32} />
                  </div>
                  <h2 className="text-xl font-bold text-white">{tool.name}</h2>
                </div>
                <p className="text-purple-200/70">{tool.desc}</p>
              </motion.div>
            </Link>
          );
        })}
      </div>
    </div>
  );
}
