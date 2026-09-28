'use client';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Home, MessageSquare, PenTool, FileText, Image as ImageIcon } from 'lucide-react';

const navItems = [
  { name: 'Home', path: '/home', icon: Home },
  { name: 'Chat', path: '/chat', icon: MessageSquare },
  { name: 'Writer', path: '/writer', icon: PenTool },
  { name: 'Resume', path: '/resume', icon: FileText },
  { name: 'Photo', path: '/photo', icon: ImageIcon },
];

export function Navigation() {
  const pathname = usePathname();

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-50 glass-panel md:relative md:w-64 md:h-screen md:flex-col p-4 flex justify-around md:justify-start gap-4">
      <div className="hidden md:flex items-center gap-4 p-4 mb-8">
        <div className="w-10 h-10 rounded-full glow-effect bg-purple-900/50 flex items-center justify-center">
          <span className="text-xl font-black text-white">G</span>
        </div>
        <span className="text-white font-bold tracking-widest">GLOWFORGE</span>
      </div>

      {navItems.map((item) => {
        const isActive = pathname === item.path;
        const Icon = item.icon;
        
        return (
          <Link
            key={item.path}
            href={item.path}
            className={`flex items-center gap-3 p-3 rounded-xl transition-all ${
              isActive 
                ? 'bg-purple-600/30 text-purple-300 shadow-[0_0_15px_rgba(168,85,247,0.2)]' 
                : 'text-white/60 hover:bg-white/5 hover:text-white'
            }`}
          >
            <Icon size={24} className={isActive ? 'text-purple-400' : ''} />
            <span className="hidden md:block font-medium">{item.name}</span>
          </Link>
        );
      })}
    </nav>
  );
}
