import { Suspense } from 'react';
import Link from 'next/link';
import { YellowBookEntry } from '@yellowbook/contract';
import ClientMap from '../../../components/ClientMap';

// SSR: Server-Side Rendering - хүсэлт бүрийн динамикаар
export const dynamic = 'force-dynamic';

async function searchYellowBooks(query: string): Promise<YellowBookEntry[]> {
  const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333';
  
  try {
    const res = await fetch(`${apiUrl}/yellow-books`, {
      cache: 'no-store', //  Үргэлж шинэ өгөгдөл
    });
    
    if (!res.ok) {
      return [];
    }
    
    const data = await res.json();
    const books: YellowBookEntry[] = data.data || [];
    
    // Filter on server side
    if (!query) return books;
    
    const lowerQuery = query.toLowerCase();
    return books.filter(
      (book) =>
        book.businessName.toLowerCase().includes(lowerQuery) ||
        book.category.toLowerCase().includes(lowerQuery) ||
        book.address.toLowerCase().includes(lowerQuery) ||
        book.phoneNumber.includes(lowerQuery)
    );
  } catch (error) {
    console.error('Error searching yellow books:', error);
    return [];
  }
}

function SearchResultsSkeleton() {
  return (
    <div className="space-y-6">
      {[1, 2, 3].map((i) => (
        <div
          key={i}
          className="bg-white/95 rounded-3xl shadow-xl p-6 animate-pulse"
        >
          <div className="flex gap-4">
            <div className="w-16 h-16 bg-gray-300 rounded-xl" />
            <div className="flex-1 space-y-3">
              <div className="h-6 bg-gray-300 rounded w-2/3" />
              <div className="h-4 bg-gray-200 rounded w-1/2" />
              <div className="h-32 bg-gray-200 rounded-2xl" />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

async function SearchResults({ query }: { query: string }) {
  const results = await searchYellowBooks(query);
  
  if (results.length === 0) {
    return (
      <div className="text-center py-12">
        <div className="text-6xl mb-4">🔍</div>
        <h3 className="text-2xl font-bold text-white mb-2">
          {query ? 'Илэрц олдсонгүй' : 'Хайлт хийнэ үү'}
        </h3>
        <p className="text-white/60">
          {query
            ? 'Өөр хайлтын түлхүүр үг ашиглан дахин оролдоно уу'
            : 'Байгууллага хайхын тулд дээрх хайлтын талбарт бичнэ үү'}
        </p>
      </div>
    );
  }
  
  return (
    <div className="space-y-6">
      <div className="text-white/80 mb-4">
        <strong>{results.length}</strong> илэрц олдлоо
      </div>
      
      {results.map((book) => (
        <div
          key={book.id}
          className="bg-white/95 backdrop-blur-sm rounded-3xl shadow-xl p-6 border border-white/20"
        >
          <div className="flex gap-6">
            <Link
              href={`/yellow-books/${book.id}`}
              className="flex-shrink-0"
            >
              <div className="w-16 h-16 bg-gradient-to-br from-emerald-400 to-cyan-400 flex items-center justify-center rounded-xl shadow-lg hover:scale-110 transition-transform">
                <span className="text-white text-2xl font-bold">
                  {book.businessName[0]}
                </span>
              </div>
            </Link>
            
            <div className="flex-1">
              <Link href={`/yellow-books/${book.id}`}>
                <h3 className="text-2xl font-bold text-emerald-600 hover:text-emerald-700 mb-2">
                  {book.businessName}
                </h3>
              </Link>
              
              <div className="grid grid-cols-1 md:grid-cols-3 gap-3 mb-4">
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
              
              {book.description && (
                <p className="text-slate-600 mb-4 line-clamp-2">
                  {book.description}
                </p>
              )}
              
              {/* Client-side map island */}
              <ClientMap address={book.address} businessName={book.businessName} />
            </div>
          </div>
        </div>
      ))}
    </div>
  );
}

export default async function SearchPage({
  searchParams,
}: {
  searchParams: Promise<{ q?: string }>;
}) {
  const { q } = await searchParams;
  const query = q || '';
  
  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 p-8">
      <div className="max-w-6xl mx-auto">
        <div className="mb-12 flex justify-between items-center">
          <Link
            href="/yellow-books"
            className="inline-flex items-center gap-2 px-6 py-3 bg-white/10 backdrop-blur rounded-2xl text-white hover:bg-white/20 transition-colors"
          >
            ← Буцах
          </Link>
          
          <span className="text-white/60 text-sm">
            SSR with client map islands
          </span>
        </div>
        
        <div className="text-center mb-12">
          <h1 className="text-5xl font-bold text-white mb-4">
            Байгууллага хайх
          </h1>
          <p className="text-white/80 text-lg mb-8">
            Server-Side Rendering for real-time search
          </p>
          
          <form method="GET" className="max-w-2xl mx-auto">
            <input
              type="text"
              name="q"
              defaultValue={query}
              placeholder="Байгууллагын нэр, утас, хаяг, ангилал..."
              className="w-full px-6 py-4 rounded-2xl border-2 border-white/20 bg-white/10 backdrop-blur text-white placeholder-white/60 focus:outline-none focus:border-emerald-400 text-lg"
              autoFocus
            />
          </form>
        </div>
        
        <Suspense fallback={<SearchResultsSkeleton />}>
          <SearchResults query={query} />
        </Suspense>
      </div>
    </div>
  );
}
