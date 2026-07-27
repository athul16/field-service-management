import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../api/client';
import { ProjectIcon, ReportIcon, SiteIcon, WorkerIcon } from '../components/Icons';

export function HomePage() {
  const navigate = useNavigate();
  const [stats, setStats] = useState(null);
  const [error, setError] = useState(null);

  useEffect(() => {
    Promise.all([api.get('/api/owner/sites'), api.get('/api/owner/projects'), api.get('/api/owner/workers')])
      .then(([sites, projects, workers]) => {
        setStats({
          sites: sites.length,
          projects: projects.length,
          activeProjects: projects.filter((p) => p.status === 'active').length,
          workers: workers.length,
        });
      })
      .catch((err) => setError(err.message));
  }, []);

  const tiles = [
    {
      to: '/sites',
      label: 'Sites',
      sub: stats ? `${stats.sites} site${stats.sites === 1 ? '' : 's'}` : ' ',
      Icon: SiteIcon,
      colorClass: 'tile-blue',
    },
    {
      to: '/projects',
      label: 'Projects',
      sub: stats ? `${stats.activeProjects} active of ${stats.projects}` : ' ',
      Icon: ProjectIcon,
      colorClass: 'tile-purple',
    },
    {
      to: '/workers',
      label: 'Workers',
      sub: stats ? `${stats.workers} worker${stats.workers === 1 ? '' : 's'}` : ' ',
      Icon: WorkerIcon,
      colorClass: 'tile-orange',
    },
    {
      to: '/reports',
      label: 'Reports',
      sub: 'Hours by period',
      Icon: ReportIcon,
      colorClass: 'tile-teal',
    },
  ];

  return (
    <div>
      <h1>Welcome back</h1>
      <p className="muted">Pick a section to get started.</p>
      {error && <p className="error">{error}</p>}
      <div className="tile-grid">
        {tiles.map(({ to, label, sub, Icon, colorClass }) => (
          <button key={to} type="button" className={`tile ${colorClass}`} onClick={() => navigate(to)}>
            <span className="tile-icon">
              <Icon />
            </span>
            <span className="tile-label">{label}</span>
            <span className="tile-sub">{sub}</span>
          </button>
        ))}
      </div>
    </div>
  );
}
