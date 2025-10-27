'use client';

import { useEffect, useState } from 'react';
import styles from './page.module.css';

interface YellowBookEntry {
  id: string;
  businessName: string;
  category: string;
  phoneNumber: string;
  address: string;
  description?: string;
  website?: string;
  createdAt: string;
  updatedAt: string;
}

export default function Index() {
  const [listings, setListings] = useState<YellowBookEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3333';
    fetch(`${apiUrl}/yellow-books`)
      .then((res) => res.json())
      .then((data) => {
        if (data.success) {
          setListings(data.data);
        } else {
          setError('Failed to load listings');
        }
        setLoading(false);
      })
      .catch((err) => {
        setError(err.message);
        setLoading(false);
      });
  }, []);

  return (
    <div className={styles.page}>
      <div style={{ padding: '2rem', maxWidth: '1200px', margin: '0 auto' }}>
        <header style={{ marginBottom: '3rem', textAlign: 'center' }}>
          <h1 style={{ fontSize: '3rem', marginBottom: '0.5rem' }}>
            📒 Yellow Book
          </h1>
          <p style={{ fontSize: '1.25rem', color: '#666' }}>
            Mongolian Business Directory
          </p>
        </header>

        {loading && (
          <div style={{ textAlign: 'center', padding: '2rem' }}>
            <p>Loading listings...</p>
          </div>
        )}

        {error && (
          <div
            style={{
              textAlign: 'center',
              padding: '2rem',
              backgroundColor: '#fee',
              borderRadius: '8px',
            }}
          >
            <p style={{ color: '#c00' }}>Error: {error}</p>
            <p style={{ marginTop: '1rem' }}>
              Make sure the API is running at http://localhost:3333
            </p>
          </div>
        )}

        {!loading && !error && listings.length === 0 && (
          <div style={{ textAlign: 'center', padding: '2rem' }}>
            <p>No listings found.</p>
          </div>
        )}

        {!loading && !error && listings.length > 0 && (
          <div
            style={{
              display: 'grid',
              gridTemplateColumns: 'repeat(auto-fill, minmax(350px, 1fr))',
              gap: '1.5rem',
            }}
          >
            {listings.map((listing) => (
              <article
                key={listing.id}
                style={{
                  border: '1px solid #ddd',
                  borderRadius: '12px',
                  padding: '1.5rem',
                  backgroundColor: '#fff',
                  boxShadow: '0 2px 8px rgba(0,0,0,0.1)',
                }}
              >
                <div style={{ marginBottom: '1rem' }}>
                  <h2
                    style={{
                      fontSize: '1.5rem',
                      marginBottom: '0.5rem',
                      color: '#333',
                    }}
                  >
                    {listing.businessName}
                  </h2>
                  <span
                    style={{
                      display: 'inline-block',
                      padding: '0.25rem 0.75rem',
                      backgroundColor: '#e3f2fd',
                      color: '#1976d2',
                      borderRadius: '16px',
                      fontSize: '0.875rem',
                      fontWeight: '500',
                    }}
                  >
                    {listing.category}
                  </span>
                </div>

                <div style={{ marginBottom: '1rem' }}>
                  <p
                    style={{
                      color: '#666',
                      fontSize: '0.95rem',
                      lineHeight: '1.6',
                    }}
                  >
                    {listing.description || 'No description available'}
                  </p>
                </div>

                <div
                  style={{
                    borderTop: '1px solid #eee',
                    paddingTop: '1rem',
                    fontSize: '0.9rem',
                  }}
                >
                  <p style={{ marginBottom: '0.5rem' }}>
                    <strong>📞 Phone:</strong> {listing.phoneNumber}
                  </p>
                  <p style={{ marginBottom: '0.5rem' }}>
                    <strong>📍 Address:</strong> {listing.address}
                  </p>
                  {listing.website && (
                    <p style={{ marginBottom: '0.5rem' }}>
                      <strong>🌐 Website:</strong>{' '}
                      <a
                        href={listing.website}
                        target="_blank"
                        rel="noopener noreferrer"
                        style={{ color: '#1976d2', textDecoration: 'none' }}
                      >
                        {listing.website}
                      </a>
                    </p>
                  )}
                </div>
              </article>
            ))}
          </div>
        )}

        <footer style={{ marginTop: '4rem', textAlign: 'center', color: '#999' }}>
          <p>Total Listings: {listings.length}</p>
          <p style={{ marginTop: '0.5rem' }}>
            Built with ❤️ using Nx, Next.js, and Express
          </p>
        </footer>
      </div>
    </div>
  );
}