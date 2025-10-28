'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';

interface YellowBookEntry {
  id: number;
  businessName: string;
  category: string;
  phoneNumber: string;
  address: string;
  description?: string;
  website?: string;
  createdAt: string;
  updatedAt: string;
}

const TABS = [
  { label: 'Нүүр хуудас' },
  { label: 'Лавлах' },
  { label: 'Мэдээлэл' },
];

const LANGS = [
  { code: 'mn', label: 'Монгол' },
  { code: 'en', label: 'English' }
];

export default function Index() {
  const [activeTab, setActiveTab] = useState(0);
  const [lang, setLang] = useState('mn');
  const [showOrgModal, setShowOrgModal] = useState(false);

  return (
    <div className="min-h-screen bg-gradient-to-br from-slate-900 via-purple-900 to-slate-900 flex flex-col items-center justify-start p-8 relative">
      {/* Байгууллага нэмэх товч */}
      <button
        onClick={() => setShowOrgModal(true)}
        className="fixed top-6 right-8 z-50 px-6 py-3 rounded-2xl bg-gradient-to-r from-emerald-400 to-cyan-400 text-slate-900 font-bold shadow-2xl hover:scale-105 hover:shadow-emerald-400/25 transition-all duration-300 backdrop-blur-sm border border-white/20"
      >
        <span className="inline-block w-5 h-5 mr-2">+</span>
        Байгууллага нэмэх
      </button>

      {/* Навигац */}
      <nav className="flex items-center mb-12 w-full max-w-4xl px-8 py-6 rounded-3xl shadow-2xl bg-white/10 backdrop-blur-xl relative border border-white/20">
        <div className="bg-gradient-to-br from-emerald-400 to-cyan-400 rounded-2xl p-4 mr-8 shadow-lg">
          <svg width="40" height="40" viewBox="0 0 24 24" fill="none">
            <rect x="4" y="3" width="16" height="18" rx="3" fill="#1e293b" stroke="none"/>
            <rect x="7" y="7" width="10" height="2" rx="1" fill="white"/>
            <rect x="7" y="11" width="7" height="2" rx="1" fill="white"/>
            <rect x="7" y="15" width="5" height="2" rx="1" fill="white"/>
          </svg>
        </div>
        
        <div className="flex flex-1 justify-center gap-2">
          {TABS.map((tab, idx) => (
            <button
              key={tab.label}
              className={`px-8 py-3 rounded-2xl font-semibold text-lg transition-all duration-300 ${
                activeTab === idx
                  ? 'bg-white text-slate-900 shadow-lg scale-105'
                  : 'text-white/80 hover:text-white hover:bg-white/10 hover:scale-105'
              }`}
              onClick={() => setActiveTab(idx)}
            >
              {tab.label}
            </button>
          ))}
        </div>
        
        <div className="flex items-center gap-4 ml-auto">
          <select
            value={lang}
            onChange={e => setLang(e.target.value)}
            className="px-4 py-2 rounded-xl bg-white/10 backdrop-blur text-white border border-white/20 font-semibold focus:outline-none focus:ring-2 focus:ring-emerald-400 transition"
          >
            {LANGS.map(l => (
              <option key={l.code} value={l.code} className="bg-slate-800 text-white">{l.label}</option>
            ))}
          </select>
        </div>
      </nav>

      <div className="w-full max-w-4xl flex justify-center">
        {activeTab === 0 && (
          <div className="bg-white/95 backdrop-blur-sm rounded-3xl shadow-2xl flex flex-col p-12 items-center w-full border border-white/20">
            <div className="flex items-center w-full mb-8">
              <div className="flex-1">
                <h2 className="text-5xl font-bold mb-8 bg-gradient-to-r from-emerald-600 to-cyan-600 bg-clip-text text-transparent">Бидний тухай</h2>
                <p className="text-slate-700 text-xl leading-relaxed mb-6">
                  Yellow Book нь Монгол дахь бизнесийн мэдээллийг нэг дороос хайж олох боломжийг олгодог систем юм. Байгууллагын нэр, утас, имэйл, байршил, ангиллаар мэдээллийг хүргэнэ.
                </p>
              </div>
              <div className="flex-1 flex justify-center">
                <div className="relative">
                  <div className="absolute inset-0 bg-gradient-to-r from-emerald-400 to-cyan-400 rounded-full blur-2xl opacity-30"></div>
                  <img src="https://cdn-icons-png.flaticon.com/512/616/616494.png" alt="Business" className="relative w-60 h-60 object-contain drop-shadow-2xl" />
                </div>
              </div>
            </div>
            
            {/* Performance-optimized pages links */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6 w-full">
              <Link href="/yellow-books" className="group block p-6 bg-gradient-to-br from-emerald-50 to-cyan-50 rounded-2xl hover:shadow-xl transition-all duration-300 hover:scale-105">
                <div className="text-4xl mb-3">📚</div>
                <h3 className="text-xl font-bold text-emerald-700 mb-2">ISR жагсаалт</h3>
                <p className="text-slate-600 text-sm mb-3">60s revalidation with Suspense streaming</p>
                <span className="text-emerald-600 group-hover:translate-x-1 inline-block transition-transform">Үзэх →</span>
              </Link>
              
              <Link href="/yellow-books/search" className="group block p-6 bg-gradient-to-br from-purple-50 to-amber-50 rounded-2xl hover:shadow-xl transition-all duration-300 hover:scale-105">
                <div className="text-4xl mb-3">🔍</div>
                <h3 className="text-xl font-bold text-purple-700 mb-2">SSR хайлт</h3>
                <p className="text-slate-600 text-sm mb-3">Dynamic search with client map islands</p>
                <span className="text-purple-600 group-hover:translate-x-1 inline-block transition-transform">Хайх →</span>
              </Link>
              
              <Link href="/yellow-books/1" className="group block p-6 bg-gradient-to-br from-amber-50 to-emerald-50 rounded-2xl hover:shadow-xl transition-all duration-300 hover:scale-105">
                <div className="text-4xl mb-3">📄</div>
                <h3 className="text-xl font-bold text-amber-700 mb-2">SSG дэлгэрэнгүй</h3>
                <p className="text-slate-600 text-sm mb-3">Static generation with generateStaticParams</p>
                <span className="text-amber-600 group-hover:translate-x-1 inline-block transition-transform">Жишээ →</span>
              </Link>
            </div>
          </div>
        )}
        {activeTab === 1 && (
          <OrgsList lang={lang} />
        )}
        {activeTab === 2 && (
          <InfoBlocks lang={lang} />
        )}
      </div>

      {/* Modal */}
      {showOrgModal && (
        <OrgModal onClose={() => setShowOrgModal(false)} />
      )}
    </div>
  );
}

function OrgModal({ onClose }: { onClose: () => void }) {
  const [newOrg, setNewOrg] = useState({
    businessName: '',
    phoneNumber: '',
    address: '',
    description: '',
    category: '',
    website: '',
  });

  const handleNewOrgChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setNewOrg({ ...newOrg, [e.target.name]: e.target.value });
  };

  const handleAddOrg = async (e: React.FormEvent) => {
    e.preventDefault();
    try {
      const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333';
      
      const dataToSend = {
        businessName: newOrg.businessName,
        phoneNumber: newOrg.phoneNumber,
        address: newOrg.address,
        category: newOrg.category,
        ...(newOrg.description && { description: newOrg.description }),
        ...(newOrg.website && { website: newOrg.website }),
      };
      
      console.log('Sending data to API:', dataToSend);
      console.log('API URL:', apiUrl);
      
      const response = await fetch(`${apiUrl}/yellow-books`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(dataToSend),
      });
      
      console.log('Response status:', response.status);
      
      const result = await response.json();
      console.log('Response data:', result);
      
      if (!response.ok) {
        throw new Error(result.error || 'Failed to add organization');
      }
      
      console.log('Organization added successfully:', result);
      
      setNewOrg({
        businessName: '',
        phoneNumber: '',
        address: '',
        description: '',
        category: '',
        website: '',
      });
      onClose();
      window.location.reload();
    } catch (error) {
      console.error('Error adding organization:', error);
      alert('Байгууллага нэмэхэд алдаа гарлаа. Дахин оролдоно уу.');
    }
  };

  return (
    <div className="fixed inset-0 flex items-center justify-center bg-black/60 backdrop-blur-sm z-50">
      <div className="bg-white/95 backdrop-blur-xl rounded-3xl shadow-2xl p-10 min-w-[400px] max-w-md flex flex-col relative border border-white/20">
        <button
          className="absolute top-6 right-6 w-8 h-8 rounded-full bg-red-100 hover:bg-red-200 text-red-600 hover:text-red-700 transition-colors flex items-center justify-center"
          onClick={onClose}
        >
          ✕
        </button>
        
        <form className="w-full flex flex-col gap-6" onSubmit={handleAddOrg}>
          <div className="text-center mb-4">
            <h3 className="text-3xl font-bold bg-gradient-to-r from-emerald-600 to-cyan-600 bg-clip-text text-transparent">
              Байгууллага нэмэх
            </h3>
          </div>
          
          <input 
            name="businessName" 
            value={newOrg.businessName} 
            onChange={handleNewOrgChange} 
            placeholder="Байгууллагын нэр" 
            className="px-5 py-4 rounded-2xl border-2 border-gray-200 focus:border-emerald-400 focus:outline-none transition-colors text-lg text-slate-900" 
            required 
          />
          <input 
            name="phoneNumber" 
            value={newOrg.phoneNumber} 
            onChange={handleNewOrgChange} 
            placeholder="Утасны дугаар" 
            className="px-5 py-4 rounded-2xl border-2 border-gray-200 focus:border-emerald-400 focus:outline-none transition-colors text-lg text-slate-900" 
            required 
          />
          <input 
            name="address" 
            value={newOrg.address} 
            onChange={handleNewOrgChange} 
            placeholder="Байршил" 
            className="px-5 py-4 rounded-2xl border-2 border-gray-200 focus:border-emerald-400 focus:outline-none transition-colors text-lg text-slate-900" 
            required 
          />
          <input 
            name="description" 
            value={newOrg.description} 
            onChange={handleNewOrgChange} 
            placeholder="Тайлбар" 
            className="px-5 py-4 rounded-2xl border-2 border-gray-200 focus:border-emerald-400 focus:outline-none transition-colors text-lg text-slate-900" 
          />
          <input 
            name="category" 
            value={newOrg.category} 
            onChange={handleNewOrgChange} 
            placeholder="Ангилал" 
            className="px-5 py-4 rounded-2xl border-2 border-gray-200 focus:border-emerald-400 focus:outline-none transition-colors text-lg text-slate-900" 
            required 
          />
          <input 
            name="website" 
            value={newOrg.website} 
            onChange={handleNewOrgChange} 
            placeholder="Вэбсайт" 
            className="px-5 py-4 rounded-2xl border-2 border-gray-200 focus:border-emerald-400 focus:outline-none transition-colors text-lg text-slate-900" 
          />
          
          <button 
            type="submit" 
            className="px-6 py-4 bg-gradient-to-r from-emerald-500 to-cyan-500 rounded-2xl text-white font-bold text-lg shadow-lg hover:shadow-emerald-500/25 hover:scale-105 transition-all duration-300"
          >
            Хадгалах
          </button>
        </form>
      </div>
    </div>
  );
}

function OrgsList({ lang }: { lang: string }) {
  const [orgs, setOrgs] = useState<YellowBookEntry[]>([]);
  const [search, setSearch] = useState('');
  const [selectedOrg, setSelectedOrg] = useState<YellowBookEntry | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333';
    fetch(`${apiUrl}/yellow-books`)
      .then(res => res.json())
      .then(data => {
        if (data.success) {
          setOrgs(data.data);
        }
        setLoading(false);
      });
  }, []);

  const filteredOrgs = orgs.filter(org =>
    org.businessName.toLowerCase().includes(search.toLowerCase()) ||
    org.phoneNumber.includes(search) ||
    org.address.toLowerCase().includes(search.toLowerCase())
  );

  if (loading) {
    return (
      <div className="w-full flex justify-center items-center p-12">
        <div className="text-white text-2xl">Loading...</div>
      </div>
    );
  }

  return (
    <div className="w-full flex flex-col gap-8">
      {/* Хайлт */}
      <div className="flex gap-4 mb-8">
        <input
          type="text"
          placeholder={lang === 'en' ? "Search..." : "Хайх..."}
          value={search}
          onChange={e => setSearch(e.target.value)}
          className="px-6 py-4 rounded-2xl border-2 border-white/20 bg-white/10 backdrop-blur text-white placeholder-white/60 focus:outline-none focus:border-emerald-400 flex-1 text-lg"
        />
      </div>

      {/* Жагсаалт */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {filteredOrgs.map((org) => (
          <div key={org.id} className="bg-white/95 backdrop-blur-sm rounded-3xl shadow-xl flex flex-col lg:flex-row items-center p-8 gap-6 hover:scale-105 hover:shadow-2xl transition-all duration-300 border border-white/20">
            <div className="flex flex-col items-center justify-center">
              <div className="w-20 h-20 bg-gradient-to-br from-emerald-400 to-cyan-400 flex items-center justify-center rounded-2xl mb-4 shadow-lg">
                <span className="text-white text-3xl font-bold">{org.businessName[0]}</span>
              </div>
              <h3
                className="font-bold text-xl text-center text-emerald-600 cursor-pointer hover:text-emerald-700 transition-colors"
                onClick={() => setSelectedOrg(org)}
              >
                {org.businessName}
              </h3>
            </div>
            
            <div className="flex-1 flex flex-col gap-3">
              <div className="flex items-center gap-3 text-slate-700">
                <div className="w-2 h-2 bg-emerald-400 rounded-full"></div>
                <span className="font-semibold">{org.phoneNumber}</span>
              </div>
              <div className="flex items-center gap-3 text-slate-700">
                <div className="w-2 h-2 bg-purple-400 rounded-full"></div>
                <span className="font-semibold">{org.address}</span>
              </div>
              <div className="flex items-center gap-3 text-slate-700">
                <div className="w-2 h-2 bg-amber-400 rounded-full"></div>
                <span className="font-semibold">{org.category}</span>
              </div>
            </div>
            
            <div>
              <button
                className="px-6 py-3 bg-gradient-to-r from-emerald-500 to-cyan-500 rounded-2xl text-white font-semibold shadow-lg hover:shadow-emerald-500/25 hover:scale-105 transition-all duration-300"
                onClick={() => setSelectedOrg(org)}
              >
                {lang === 'en' ? "Details" : "Дэлгэрэнгүй"}
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Modal */}
      {selectedOrg && (
        <div className="fixed inset-0 flex items-center justify-center bg-black/60 backdrop-blur-sm z-50">
          <div className="bg-white/95 backdrop-blur-xl rounded-3xl shadow-2xl p-10 min-w-[400px] max-w-2xl relative border border-white/20">
            <button 
              className="absolute top-6 right-6 w-8 h-8 rounded-full bg-red-100 hover:bg-red-200 text-red-600 transition-colors flex items-center justify-center" 
              onClick={() => setSelectedOrg(null)}
            >
              ✕
            </button>
            
            <div className="text-center">
              <h2 className="text-3xl font-bold mb-6 bg-gradient-to-r from-emerald-600 to-cyan-600 bg-clip-text text-transparent">
                {selectedOrg.businessName}
              </h2>
              
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mb-8 text-left">
                <div className="bg-gradient-to-r from-emerald-50 to-cyan-50 p-4 rounded-2xl">
                  <p className="text-emerald-700 font-semibold">{lang === 'en' ? "Phone" : "Утас"}</p>
                  <p className="text-slate-700">{selectedOrg.phoneNumber}</p>
                </div>
                <div className="bg-gradient-to-r from-purple-50 to-amber-50 p-4 rounded-2xl">
                  <p className="text-purple-700 font-semibold">{lang === 'en' ? "Address" : "Хаяг"}</p>
                  <p className="text-slate-700">{selectedOrg.address}</p>
                </div>
                <div className="bg-gradient-to-r from-amber-50 to-emerald-50 p-4 rounded-2xl">
                  <p className="text-amber-700 font-semibold">{lang === 'en' ? "Category" : "Ангилал"}</p>
                  <p className="text-slate-700">{selectedOrg.category}</p>
                </div>
                {selectedOrg.website && (
                  <div className="bg-gradient-to-r from-cyan-50 to-purple-50 p-4 rounded-2xl">
                    <p className="text-cyan-700 font-semibold">{lang === 'en' ? "Website" : "Вэбсайт"}</p>
                    <a href={selectedOrg.website} target="_blank" rel="noopener noreferrer" className="text-slate-700 hover:text-cyan-600">{selectedOrg.website}</a>
                  </div>
                )}
              </div>

              {selectedOrg.description && (
                <div className="bg-gradient-to-r from-slate-50 to-gray-50 p-4 rounded-2xl mb-6">
                  <p className="text-slate-700">{selectedOrg.description}</p>
                </div>
              )}

              {selectedOrg.address && (
                <div className="rounded-3xl overflow-hidden shadow-xl border-4 border-white">
                  <iframe
                    title="map"
                    width="100%"
                    height="300"
                    style={{ border: 0 }}
                    loading="lazy"
                    allowFullScreen
                    src={`https://www.google.com/maps?q=${encodeURIComponent(selectedOrg.address)}&output=embed`}
                  />
                </div>
              )}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

function InfoBlocks({ lang }: { lang: string }) {
  const infoData = [
    {
      id: 1,
      title: lang === 'en' ? 'About Us' : 'Бидний тухай',
      content: lang === 'en' 
        ? 'Yellow Book is a comprehensive business directory for Mongolia, helping users find businesses easily.'
        : 'Yellow Book нь Монгол улсын бизнесийн иж бүрэн лавлах бөгөөд хэрэглэгчдэд бизнес хайхад тусалдаг.'
    },
    {
      id: 2,
      title: lang === 'en' ? 'How to Use' : 'Хэрхэн ашиглах',
      content: lang === 'en'
        ? 'Search for businesses by name, phone, or location. Click on any listing for more details and map view.'
        : 'Бизнесийг нэр, утас, эсвэл байршлаар хайна. Дэлгэрэнгүй мэдээлэл болон газрын зургийг үзэхийн тулд аль нэг бизнес дээр дарна уу.'
    },
    {
      id: 3,
      title: lang === 'en' ? 'Add Business' : 'Бизнес нэмэх',
      content: lang === 'en'
        ? 'Click the "Add Organization" button to submit your business information to our directory.'
        : '"Байгууллага нэмэх" товч дарж өөрийн бизнесийн мэдээллийг манай лавлахад нэмнэ үү.'
    },
    {
      id: 4,
      title: lang === 'en' ? 'Contact' : 'Холбоо барих',
      content: lang === 'en'
        ? 'For questions or support, please reach out to our team.'
        : 'Асуулт эсвэл дэмжлэгийн тулд манай багтай холбогдоно уу.'
    }
  ];

  const [openIdx, setOpenIdx] = useState<number | null>(null);

  return (
    <div className="w-full flex flex-col items-center">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-8 w-full">
        {infoData.map((item, idx) => (
          <div
            key={item.id}
            className="bg-gradient-to-br from-white/20 to-white/10 backdrop-blur-sm rounded-3xl shadow-xl h-40 flex items-center justify-center cursor-pointer transition-all duration-300 hover:scale-105 hover:from-white/30 hover:to-white/20 border border-white/20"
            onClick={() => setOpenIdx(idx)}
          >
            <span className="text-2xl font-bold text-white text-center px-6">{item.title}</span>
          </div>
        ))}
      </div>
      
      {openIdx !== null && infoData[openIdx] && (
        <div className="fixed inset-0 flex items-center justify-center bg-black/60 backdrop-blur-sm z-50">
          <div className="bg-white/95 backdrop-blur-xl rounded-3xl shadow-2xl p-10 min-w-[400px] max-w-2xl relative border border-white/20">
            <button
              className="absolute top-6 right-6 w-8 h-8 rounded-full bg-red-100 hover:bg-red-200 text-red-600 transition-colors flex items-center justify-center"
              onClick={() => setOpenIdx(null)}
            >
              ✕
            </button>
            
            <div className="text-center">
              <h3 className="text-3xl font-bold mb-6 bg-gradient-to-r from-emerald-600 to-cyan-600 bg-clip-text text-transparent">
                {infoData[openIdx].title}
              </h3>
              <p className="text-slate-700 text-lg leading-relaxed">{infoData[openIdx].content}</p>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}