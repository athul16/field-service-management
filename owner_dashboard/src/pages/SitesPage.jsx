import { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { api } from '../api/client';

export function SitesPage() {
  const [sites, setSites] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(false);

  useEffect(() => {
    loadSites();
  }, []);

  async function loadSites() {
    setLoading(true);
    try {
      setSites(await api.get('/api/owner/sites'));
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <div className="page-header">
        <h1>Sites</h1>
        <button className="btn btn-primary" onClick={() => setShowForm((v) => !v)}>
          {showForm ? 'Cancel' : 'New Site'}
        </button>
      </div>

      {showForm && (
        <CreateSiteForm
          onCreated={() => {
            setShowForm(false);
            loadSites();
          }}
        />
      )}

      {error && <p className="error">{error}</p>}
      {loading ? (
        <p className="muted">Loading…</p>
      ) : sites.length === 0 ? (
        <p className="muted">No sites yet. Create one to get started.</p>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Company</th>
              <th>Site</th>
              <th>Address</th>
            </tr>
          </thead>
          <tbody>
            {sites.map((site) => (
              <tr key={site.id}>
                <td>{site.companyName}</td>
                <td>
                  <Link to={`/sites/${site.id}`}>{site.name}</Link>
                </td>
                <td>{site.address}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

function CreateSiteForm({ onCreated }) {
  const [name, setName] = useState('');
  const [companyName, setCompanyName] = useState('');
  const [address, setAddress] = useState('');
  const [latitude, setLatitude] = useState('');
  const [longitude, setLongitude] = useState('');
  const [error, setError] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await api.post('/api/owner/sites', {
        name,
        companyName,
        address,
        latitude: latitude ? Number(latitude) : null,
        longitude: longitude ? Number(longitude) : null,
      });
      onCreated();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form className="card form-card" onSubmit={handleSubmit}>
      <label>
        Company name
        <input value={companyName} onChange={(e) => setCompanyName(e.target.value)} required />
      </label>
      <label>
        Site name
        <input value={name} onChange={(e) => setName(e.target.value)} required />
      </label>
      <label>
        Address
        <input value={address} onChange={(e) => setAddress(e.target.value)} required />
      </label>
      <label>
        Latitude (optional)
        <input value={latitude} onChange={(e) => setLatitude(e.target.value)} inputMode="decimal" />
      </label>
      <label>
        Longitude (optional)
        <input value={longitude} onChange={(e) => setLongitude(e.target.value)} inputMode="decimal" />
      </label>
      {error && <p className="error">{error}</p>}
      <button type="submit" className="btn btn-primary" disabled={submitting}>
        {submitting ? 'Creating…' : 'Create Site'}
      </button>
    </form>
  );
}
