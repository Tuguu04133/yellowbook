import { Suspense } from 'react';
import Link from 'next/link';
import { YellowBookEntry } from '@yellowbook/contract';
import { notFound } from 'next/navigation';

// SSG: Static Site Generation with generateStaticParams
export const dynamicParams = true; // Allow dynamic params for new entries

const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333';

// Pre-generate static pages for all yellow books at build time
export async function generateStaticParams() {
  try {
    const res = await fetch(`${apiUrl}/yellow-books`, {
      next: { revalidate: 60 },
    });
    
    if (!res.ok) {
      return [];
    }
    
    const data = await res.json();
    const books: YellowBookEntry[] = data.data || [];
    
    return books.map((book) => ({
      id: book.id.toString(),
    }));
  } catch (error) {
    console.error('Error generating static params:', error);
    return [];
  }
}

async function getYellowBook(id: string): Promise<YellowBookEntry | null> {
  try {
    const res = await fetch(`${apiUrl}/yellow-books/${id}`, {
      next: { revalidate: 60 },
    });
    
    if (!res.ok) {
      return null;
    }
    
    const data = await res.json();
    return data.data;
  } catch (error) {
    console.error('Error fetching yellow book:', error);
    return null;
  }
}

// Loading skeleton
function YellowBookDetailSkeleton() {
  return (
    <div className="bg-white/95 backdrop-blur-xl rounded-3xl shadow-2xl p-10 animate-pulse">
      <div className="flex items-center justify-center mb-8">
        <div className="w-32 h-32 bg-gray-300 rounded-full" />
      </div>
      
      <div className="space-y-4 mb-8">
        <div className="h-10 bg-gray-300 rounded w-3/4 mx-auto" />
        <div className="h-6 bg-gray-200 rounded w-1/2 mx-auto" />
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="h-24 bg-gradient-to-r from-gray-100 to-gray-200 rounded-2xl" />
        ))}
      </div>
      
      <div className="h-64 bg-gray-200 rounded-3xl" />
    </div>
  );
}

// Async component for yellow book details
async function YellowBookDetail({ id }: { id: string }) {
  const book = await getYellowBook(id);
  
  if (!book) {
    notFound();
  }
  
  return (
    <div className="bg-white/95 backdrop-blur-xl rounded-3xl shadow-2xl p-10 relative border border-white/20">
      <div className="text-center mb-8">
        <div className="inline-flex w-32 h-32 bg-gradient-to-br from-emerald-400 to-cyan-400 items-center justify-center rounded-full shadow-2xl mb-6">
          <span className="text-white text-6xl font-bold">
            {book.businessName[0]}
          </span>
        </div>
        
        <h1 className="text-4xl font-bold mb-4 bg-gradient-to-r from-emerald-600 to-cyan-600 bg-clip-text text-transparent">
          {book.businessName}
        </h1>
        <div className="inline-block px-6 py-2 bg-gradient-to-r from-amber-100 to-emerald-100 rounded-full">
          <span className="text-amber-700 font-semibold">{book.category}</span>
        </div>
      </div>
      
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8">
        <div className="bg-gradient-to-r from-emerald-50 to-cyan-50 p-6 rounded-2xl">
          <p className="text-emerald-700 font-semibold mb-2">Утас</p>
          <p className="text-slate-700 text-lg">{book.phoneNumber}</p>
        </div>
        
        <div className="bg-gradient-to-r from-purple-50 to-amber-50 p-6 rounded-2xl">
          <p className="text-purple-700 font-semibold mb-2">Хаяг</p>
          <p className="text-slate-700 text-lg">{book.address}</p>
        </div>
        
        {book.website && (
          <div className="bg-gradient-to-r from-cyan-50 to-purple-50 p-6 rounded-2xl md:col-span-2">
            <p className="text-cyan-700 font-semibold mb-2">Вэбсайт</p>
            <a
              href={book.website}
              target="_blank"
              rel="noopener noreferrer"
              className="text-cyan-600 hover:text-cyan-700 underline text-lg"
            >
              {book.website}
            </a>
          </div>
        )}
      </div>
      
      {book.description && (
        <div className="bg-gradient-to-r from-slate-50 to-gray-50 p-6 rounded-2xl mb-8">
          <p className="text-slate-700 text-lg leading-relaxed">{book.description}</p>
        </div>
      )}
      
      {book.address && (
        <div className="rounded-3xl overflow-hidden shadow-xl border-4 border-white">
          <iframe
            title="map"
            width="100%"
            height="400"
            style={{ border: 0 }}
            loading="lazy"
            allowFullScreen
            src={`https://www.google.com/maps?q=${encodeURIComponent(book.address)}&output=embed`}
          />
        </div>
      )}
    </div>
  );
}

export default async function YellowBookPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 p-8">
      <div className="max-w-4xl mx-auto">
        <div className="mb-12 flex justify-between items-center">
          <Link
            href="/yellow-books"
            className="inline-flex items-center gap-2 px-6 py-3 bg-white/10 backdrop-blur rounded-2xl text-white hover:bg-white/20 transition-colors"
          >
            ← Буцах
          </Link>
          
          <span className="text-white/60 text-sm">
            SSG with generateStaticParams
          </span>
        </div>
        
        <Suspense fallback={<YellowBookDetailSkeleton />}>
          <YellowBookDetail id={id} />
        </Suspense>
      </div>
    </div>
  );
}
