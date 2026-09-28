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
    <nav className="fixed bottom-0 left-0 right-0 z-50 bg-[#16092b]/90 backdrop-blur-xl border-t border-white/5 md:relative md:w-64 md:h-screen md:flex-col md:border-t-0 md:border-r flex justify-around md:justify-start px-2 py-3 md:p-6 gap-2 md:gap-4 shadow-2xl">
      <div className="hidden md:flex items-center gap-3 mb-10 pl-2">
        <div className="w-10 h-10 rounded-2xl flex items-center justify-center overflow-hidden shadow-lg shadow-purple-500/30">
          <img src="/assets/logo.png" alt="Logo" className="w-full h-full object-cover" />
        </div>
        <span className="text-white font-extrabold tracking-[0.15em] text-lg">GLOWFORGE</span>
      </div>

      {navItems.map((item) => {
        const isActive = pathname === item.path;
        const Icon = item.icon;
        
        return (
          <Link
            key={item.path}
            href={item.path}
            className={`flex flex-col md:flex-row items-center gap-1 md:gap-4 p-2 md:px-4 md:py-3 rounded-2xl transition-all duration-300 ${
              isActive 
                ? 'bg-purple-500/10 text-purple-300 md:border-l-2 md:border-purple-400 md:rounded-l-none' 
                : 'text-gray-400 hover:bg-white/5 hover:text-gray-200'
            }`}
          >
            <Icon size={22} strokeWidth={isActive ? 2.5 : 2} className={isActive ? 'text-purple-400 drop-shadow-[0_0_8px_rgba(168,85,247,0.5)]' : ''} />
            <span className={`text-[10px] md:text-sm md:block ${isActive ? 'font-bold' : 'font-medium'}`}>
              {item.name}
            </span>
          </Link>
        );
      })}
    </nav>
  );
}
