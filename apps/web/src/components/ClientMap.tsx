'use client';

import { useEffect, useRef } from 'react';

interface MapProps {
  address: string;
  businessName: string;
}

export default function ClientMap({ address, businessName }: MapProps) {
  const mapRef = useRef<HTMLDivElement>(null);
  
  useEffect(() => {
    // Client-side only map rendering
    if (typeof window !== 'undefined' && mapRef.current) {
      // Map initialization logic here
      console.log('Map initialized for:', businessName, address);
    }
  }, [address, businessName]);
  
  return (
    <div ref={mapRef} className="w-full h-64 rounded-2xl overflow-hidden shadow-lg">
      <iframe
        title={`Map for ${businessName}`}
        width="100%"
        height="100%"
        style={{ border: 0 }}
        loading="lazy"
        allowFullScreen
        src={`https://www.google.com/maps?q=${encodeURIComponent(address)}&output=embed`}
      />
    </div>
  );
}
