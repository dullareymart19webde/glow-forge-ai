import { Navigation } from '@/components/Navigation';

export default function AppLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="flex flex-col md:flex-row min-h-screen">
      <Navigation />
      <main className="flex-1 p-4 pb-24 md:pb-4 md:p-8 h-screen overflow-y-auto">
        {children}
      </main>
    </div>
  );
}
