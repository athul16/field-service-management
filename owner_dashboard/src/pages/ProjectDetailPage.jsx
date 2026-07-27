import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { api } from '../api/client';

export function ProjectDetailPage() {
  const { projectId } = useParams();
  const [project, setProject] = useState(null);
  const [error, setError] = useState(null);
  const [updating, setUpdating] = useState(false);

  useEffect(() => {
    loadProject();
  }, [projectId]);

  async function loadProject() {
    try {
      const projects = await api.get('/api/owner/projects');
      setProject(projects.find((p) => p.id === projectId) ?? null);
    } catch (err) {
      setError(err.message);
    }
  }

  async function toggleStatus() {
    if (!project) return;
    setUpdating(true);
    setError(null);
    try {
      const nextStatus = project.status === 'active' ? 'closed' : 'active';
      setProject(await api.patch(`/api/owner/projects/${projectId}/status`, { status: nextStatus }));
    } catch (err) {
      setError(err.message);
    } finally {
      setUpdating(false);
    }
  }

  return (
    <div>
      <p>
        <Link to="/projects">&larr; All projects</Link>
      </p>

      {error && <p className="error">{error}</p>}

      {project && (
        <div className="card">
          <div className="page-header">
            <h1>{project.name}</h1>
            <button className="btn btn-secondary" onClick={toggleStatus} disabled={updating}>
              {project.status === 'active' ? 'Close project' : 'Reopen project'}
            </button>
          </div>
          <p className="muted">
            <Link to={`/sites/${project.siteId}`}>{project.siteName}</Link>
          </p>
          <p>
            {project.startDate} &ndash; {project.endDate ?? 'ongoing'} &middot; {project.status}
          </p>
        </div>
      )}
    </div>
  );
}
