import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { api } from '../api/client';
import { BarChart } from '../components/BarChart';
import { useAuth } from '../auth/AuthContext';
import { aggregateHours, formatHours, hoursOf } from '../lib/hours';

function startOfThisMonth() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), 1);
}

function startOfNextMonth() {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth() + 1, 1);
}

/** "2m ago" / "1h ago" / "3d ago" — coarse enough for a feed, exact time is on Reports. */
function timeAgo(iso) {
  const ms = Date.now() - new Date(iso).getTime();
  const min = Math.floor(ms / 60000);
  if (min < 1) return 'just now';
  if (min < 60) return `${min}m ago`;
  const hr = Math.floor(min / 60);
  if (hr < 24) return `${hr}h ago`;
  const day = Math.floor(hr / 24);
  return `${day}d ago`;
}

/** One shift becomes one activity row — a still-open shift is "clocked in" (live),
 * a finished one is "completed a shift". No separate "confirmed" row: that would
 * double up on the same shift without a second real timestamp to sort it by. */
function activityForShift(shift) {
  if (shift.status !== 'COMPLETED' || !shift.clockOutAt) {
    return {
      key: shift.id,
      live: true,
      line1: `${shift.workerName} clocked in`,
      line2: shift.siteName,
      at: shift.clockInAt,
    };
  }
  return {
    key: shift.id,
    live: false,
    line1: `${shift.workerName} completed a shift — ${formatHours(hoursOf(shift))} hrs`,
    line2: shift.siteName,
    at: shift.clockOutAt,
  };
}

export function HomePage() {
  const navigate = useNavigate();
  const { profile } = useAuth();
  const [sites, setSites] = useState([]);
  const [projects, setProjects] = useState([]);
  const [workers, setWorkers] = useState([]);
  const [shifts, setShifts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);

  useEffect(() => {
    Promise.all([
      api.get('/api/owner/sites'),
      api.get('/api/owner/projects'),
      api.get('/api/owner/workers'),
      api.get('/api/owner/shifts', { from: startOfThisMonth().toISOString(), to: startOfNextMonth().toISOString() }),
    ])
      .then(([s, p, w, sh]) => {
        setSites(s);
        setProjects(p);
        setWorkers(w);
        setShifts(sh);
      })
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, []);

  const activeProjects = projects.filter((p) => p.status === 'active').length;
  const completedShifts = shifts.filter((s) => s.status === 'COMPLETED' && s.clockOutAt);
  const hoursThisMonth = completedShifts.reduce((sum, s) => sum + hoursOf(s), 0);

  const activity = shifts
    .map(activityForShift)
    .sort((a, b) => new Date(b.at) - new Date(a.at))
    .slice(0, 6);

  const bySite = aggregateHours(completedShifts, (s) => s.siteName);

  const projectCountBySite = new Map();
  for (const p of projects) {
    if (p.status !== 'active') continue;
    projectCountBySite.set(p.siteId, (projectCountBySite.get(p.siteId) ?? 0) + 1);
  }

  return (
    <div>
      <div className="page-header">
        <div>
          <h1>Welcome back, {profile?.fullName}</h1>
          <p className="muted">Here's what's happening across your sites this month.</p>
        </div>
        <button className="btn btn-primary" onClick={() => navigate('/workers', { state: { openForm: true } })}>
          + New worker
        </button>
      </div>

      {error && <p className="error">{error}</p>}

      {loading ? (
        <p className="muted">Loading…</p>
      ) : (
        <>
          <div className="stat-row">
            <button className="card stat-tile stat-tile-link" onClick={() => navigate('/sites')}>
              <div className="stat-label">Sites</div>
              <div className="stat-value">{sites.length}</div>
            </button>
            <button className="card stat-tile stat-tile-link" onClick={() => navigate('/projects')}>
              <div className="stat-label">Active projects</div>
              <div className="stat-value">
                {activeProjects} <small>of {projects.length}</small>
              </div>
            </button>
            <button className="card stat-tile stat-tile-link" onClick={() => navigate('/workers')}>
              <div className="stat-label">Workers</div>
              <div className="stat-value">{workers.length}</div>
            </button>
            <button className="card stat-tile stat-tile-link" onClick={() => navigate('/reports')}>
              <div className="stat-label">Hours logged</div>
              <div className="stat-value">
                {formatHours(hoursThisMonth)} <small>this month</small>
              </div>
            </button>
          </div>

          <div className="panel-grid">
            <div className="card panel">
              <h3>Recent activity</h3>
              {activity.length === 0 ? (
                <p className="muted">No shifts recorded yet this month.</p>
              ) : (
                activity.map((a) => (
                  <div className="activity-row" key={a.key}>
                    <span className={a.live ? 'dot dot-live' : 'dot'} />
                    <div className="body">
                      <div className="line1">{a.line1}</div>
                      <div className="line2">{a.line2}</div>
                    </div>
                    <div className="when">{timeAgo(a.at)}</div>
                  </div>
                ))
              )}
            </div>

            <div className="card panel">
              <BarChart title="Hours by site — this month" data={bySite} valueLabel={formatHours} />

              <h3 style={{ marginTop: '1.2rem' }}>Sites</h3>
              {sites.length === 0 ? (
                <p className="muted">No sites yet.</p>
              ) : (
                <div className="sitelist">
                  {sites.map((site) => {
                    const count = projectCountBySite.get(site.id) ?? 0;
                    return (
                      <div className="site-row" key={site.id}>
                        <div>
                          <div className="sname">{site.name}</div>
                          <div className="scompany">{site.companyName}</div>
                        </div>
                        <div className="scount">
                          {count} active project{count === 1 ? '' : 's'}
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
