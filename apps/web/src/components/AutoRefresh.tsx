'use client';

import { useEffect } from 'react';
import { useRouter } from 'next/navigation';

export function AutoRefresh({ intervalSeconds = 10 }: { intervalSeconds?: number }) {
  const router = useRouter();

  useEffect(() => {
    const interval = setInterval(() => {
      console.log('[Auto Refresh] Refreshing page...');
      router.refresh(); 
    }, intervalSeconds * 1000);

    return () => clearInterval(interval);
  }, [intervalSeconds, router]);

  return null;
}
