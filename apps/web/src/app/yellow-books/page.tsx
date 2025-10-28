import { Suspense } from 'react';
import Link from 'next/link';
import { YellowBookEntry } from '@yellowbook/contract';

// 60 секунд бүр автомат шинэчлэгдэнэ
export const revalidate = 60;

async function getYellowBooks(): Promise<YellowBookEntry[]> {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333';
  
  try {
    const res = await fetch(`${apiUrl}/yellow-books`, {
      next: { revalidate: 60 },
    });
    
    if (!res.ok) {
      throw new Error('Failed to fetch yellow books');
    }
    
    const data = await res.json();
    return data.data || [];
  } catch (error) {
    console.error('Error fetching yellow books:', error);
    return [];
  }
}

// Loading skeleton component
function YellowBooksSkeleton() {
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
      {[1, 2, 3, 4].map((i) => (
        <div
          key={i}
          className="bg-white/95 backdrop-blur-sm rounded-3xl shadow-xl p-8 animate-pulse"
        >
          <div className="flex items-center gap-6">
            <div className="w-20 h-20 bg-gray-300 rounded-2xl" />
            <div className="flex-1 space-y-3">
              <div className="h-6 bg-gray-300 rounded w-3/4" />
              <div className="h-4 bg-gray-200 rounded w-1/2" />
              <div className="h-4 bg-gray-200 rounded w-2/3" />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

// Async component for yellow books list
async function YellowBooksList() {
  const books = await getYellowBooks();
  
  return (
    <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
      {books.map((book) => (
        <Link
          key={book.id}
          href={`/yellow-books/${book.id}`}
          className="bg-white/95 backdrop-blur-sm rounded-3xl shadow-xl p-8 hover:scale-105 hover:shadow-2xl transition-all duration-300 border border-white/20 block"
        >
          <div className="flex items-center gap-6">
            <div className="w-20 h-20 bg-gradient-to-br from-emerald-400 to-cyan-400 flex items-center justify-center rounded-2xl shadow-lg">
              <span className="text-white text-3xl font-bold">
                {book.businessName[0]}
              </span>
            </div>
            
            <div className="flex-1 space-y-2">
              <h3 className="font-bold text-xl text-emerald-600">
                {book.businessName}
              </h3>
              <div className="flex items-center gap-2 text-slate-700">
                <div className="w-2 h-2 bg-emerald-400 rounded-full" />
                <span className="font-semibold">{book.phoneNumber}</span>
              </div>
              <div className="flex items-center gap-2 text-slate-700">
                <div className="w-2 h-2 bg-purple-400 rounded-full" />
                <span className="font-semibold">{book.address}</span>
              </div>
              <div className="flex items-center gap-2 text-slate-700">
                <div className="w-2 h-2 bg-amber-400 rounded-full" />
                <span className="font-semibold">{book.category}</span>
              </div>
            </div>
          </div>
        </Link>
      ))}
    </div>
  );
}

export default function YellowBooksPage() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 p-8">
      <div className="max-w-6xl mx-auto">
        <div className="mb-12">
          <Link
            href="/"
            className="inline-flex items-center gap-2 px-6 py-3 bg-white/10 backdrop-blur rounded-2xl text-white hover:bg-white/20 transition-colors"
          >
            ← Буцах
          </Link>
        </div>
        
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold text-white mb-4">
            Байгууллагын жагсаалт
          </h1>
          <p className="text-white/80 text-lg">
            ISR with 60s revalidation - Automatically updates every minute
          </p>
        </div>
        
        {/* Suspense boundary for streaming */}
        <Suspense fallback={<YellowBooksSkeleton />}>
          <YellowBooksList />
        </Suspense>
      </div>
    </div>
  );
}
