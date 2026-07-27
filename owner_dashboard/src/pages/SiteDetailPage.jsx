import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { api } from '../api/client';

export function SiteDetailPage() {
  const { siteId } = useParams();
  const [site, setSite] = useState(null);
  const [projects, setProjects] = useState([]);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(false);

  useEffect(() => {
    loadSite();
    loadProjects();
  }, [siteId]);

  async function loadSite() {
    try {
      const sites = await api.get('/api/owner/sites');
      setSite(sites.find((s) => s.id === siteId) ?? null);
    } catch (err) {
      setError(err.message);
    }
  }

  async function loadProjects() {
    try {
      setProjects(await api.get('/api/owner/projects', { siteId }));
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div>
      <p>
        <Link to="/sites">&larr; All sites</Link>
      </p>

      {error && <p className="error">{error}</p>}

      {site && (
        <div className="card">
          <h1>{site.companyName} — {site.name}</h1>
          <p className="muted">{site.address}</p>
          {site.latitude != null && site.longitude != null && (
            <p className="muted">{site.latitude}, {site.longitude}</p>
          )}
        </div>
      )}

      <div className="page-header">
        <h2>Projects</h2>
        <button className="btn btn-primary" onClick={() => setShowForm((v) => !v)}>
          {showForm ? 'Cancel' : 'New Project'}
        </button>
      </div>

      {showForm && (
        <CreateProjectForm
          siteId={siteId}
          onCreated={() => {
            setShowForm(false);
            loadProjects();
          }}
        />
      )}

      {projects.length === 0 ? (
        <p className="muted">No projects yet at this site.</p>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Start</th>
              <th>End</th>
              <th>Status</th>
            </tr>
          </thead>
          <tbody>
            {projects.map((project) => (
              <tr key={project.id}>
                <td>
                  <Link to={`/projects/${project.id}`}>{project.name}</Link>
                </td>
                <td>{project.startDate}</td>
                <td>{project.endDate ?? '—'}</td>
                <td>{project.status}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  );
}

function CreateProjectForm({ siteId, onCreated }) {
  const [name, setName] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');
  const [error, setError] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await api.post(`/api/owner/sites/${siteId}/projects`, {
        name,
        startDate,
        endDate: endDate || null,
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
        Name
        <input value={name} onChange={(e) => setName(e.target.value)} required />
      </label>
      <label>
        Start date
        <input type="date" value={startDate} onChange={(e) => setStartDate(e.target.value)} required />
      </label>
      <label>
        End date (optional)
        <input type="date" value={endDate} onChange={(e) => setEndDate(e.target.value)} />
      </label>
      {error && <p className="error">{error}</p>}
      <button type="submit" className="btn btn-primary" disabled={submitting}>
        {submitting ? 'Creating…' : 'Create Project'}
      </button>
    </form>
  );
}
