import { useEffect, useMemo, useState } from 'react';
import { api } from '../api/client';
import { BarChart } from '../components/BarChart';
import { aggregateHours, formatHours, hoursOf } from '../lib/hours';

const CUSTOM_KEY = 'custom';

function startOfMonth(year, month) {
  return new Date(year, month, 1);
}

function toDateInputValue(date) {
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

/** Preset rows first, custom range last — the order a reader reaches for them in. */
function presetRanges() {
  const now = new Date();
  const thisMonthStart = startOfMonth(now.getFullYear(), now.getMonth());
  const nextMonthStart = startOfMonth(now.getFullYear(), now.getMonth() + 1);
  const lastMonthStart = startOfMonth(now.getFullYear(), now.getMonth() - 1);

  const currentQuarter = Math.floor(now.getMonth() / 3);
  const thisQuarterStart = new Date(now.getFullYear(), currentQuarter * 3, 1);
  const nextQuarterStart = new Date(now.getFullYear(), currentQuarter * 3 + 3, 1);

  const thisYearStart = new Date(now.getFullYear(), 0, 1);
  const nextYearStart = new Date(now.getFullYear() + 1, 0, 1);

  const last12Start = startOfMonth(now.getFullYear(), now.getMonth() - 11);

  return [
    { key: 'this-month', label: 'This month', from: thisMonthStart, to: nextMonthStart },
    { key: 'last-month', label: 'Last month', from: lastMonthStart, to: thisMonthStart },
    { key: 'this-quarter', label: 'This quarter', from: thisQuarterStart, to: nextQuarterStart },
    { key: 'this-year', label: 'This year', from: thisYearStart, to: nextYearStart },
    { key: 'last-12-months', label: 'Last 12 months', from: last12Start, to: nextMonthStart },
  ];
}

export function ReportsPage() {
  const presets = useMemo(() => presetRanges(), []);

  const [workers, setWorkers] = useState([]);
  const [assignments, setAssignments] = useState([]);
  const [workerId, setWorkerId] = useState('');
  const [rangeKey, setRangeKey] = useState(presets[0].key);
  const [customFrom, setCustomFrom] = useState(toDateInputValue(presets[0].from));
  const [customTo, setCustomTo] = useState(toDateInputValue(new Date()));
  const [shifts, setShifts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  useEffect(() => {
    api.get('/api/owner/workers').then(setWorkers).catch((err) => setError(err.message));
    api.get('/api/owner/assignments').then(setAssignments).catch((err) => setError(err.message));
  }, []);

  const range = useMemo(() => {
    if (rangeKey === CUSTOM_KEY) {
      if (!customFrom || !customTo) return null;
      const from = new Date(`${customFrom}T00:00:00`);
      // Custom "to" is inclusive of the whole day the owner picked, so add one day
      // rather than asking them to reason about an exclusive end-of-range timestamp.
      const to = new Date(`${customTo}T00:00:00`);
      to.setDate(to.getDate() + 1);
      return { from, to };
    }
    return presets.find((p) => p.key === rangeKey) ?? presets[0];
  }, [rangeKey, customFrom, customTo, presets]);

  useEffect(() => {
    if (!range) {
      setShifts([]);
      return;
    }
    setLoading(true);
    setError(null);
    api
      .get('/api/owner/shifts', {
        ...(workerId ? { workerId } : {}),
        from: range.from.toISOString(),
        to: range.to.toISOString(),
      })
      .then(setShifts)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [workerId, range?.from?.getTime(), range?.to?.getTime()]);

  // (workerId, siteId) -> that pair's assignment rows. A shift only carries a siteId, never a
  // projectId (see agents.md), so a project can only be attributed when the pair resolves to
  // exactly one assignment. Two-plus assignments at the same site (a worker on multiple projects
  // there) can't be split with real precision, so they're bucketed under a clearly-labeled
  // "multiple projects" group instead of guessing which one the hours belong to.
  const assignmentsByWorkerSite = useMemo(() => {
    const map = new Map();
    for (const a of assignments) {
      const key = `${a.workerId}|${a.siteId}`;
      if (!map.has(key)) map.set(key, []);
      map.get(key).push(a);
    }
    return map;
  }, [assignments]);

  function projectBucketFor(shift) {
    const matches = assignmentsByWorkerSite.get(`${shift.workerId}|${shift.siteId}`) ?? [];
    if (matches.length === 1) return matches[0].projectName;
    if (matches.length === 0) return 'Unassigned';
    return `${shift.siteName} (multiple projects)`;
  }

  const completedShifts = shifts.filter((s) => s.status === 'COMPLETED' && s.clockOutAt);
  const totalHours = completedShifts.reduce((sum, s) => sum + hoursOf(s), 0);
  const workerCount = new Set(completedShifts.map((s) => s.workerId)).size;

  const byWorker = aggregateHours(completedShifts, (s) => s.workerName);
  const byProject = aggregateHours(completedShifts, projectBucketFor);
  const bySite = aggregateHours(completedShifts, (s) => s.siteName);

  return (
    <div>
      <div className="page-header">
        <h1>Reports</h1>
      </div>

      <div className="card filter-row">
        <label>
          Worker
          <select value={workerId} onChange={(e) => setWorkerId(e.target.value)}>
            <option value="">All workers</option>
            {workers.map((w) => (
              <option key={w.id} value={w.id}>
                {w.fullName}
              </option>
            ))}
          </select>
        </label>
        <label>
          Date range
          <select value={rangeKey} onChange={(e) => setRangeKey(e.target.value)}>
            {presets.map((p) => (
              <option key={p.key} value={p.key}>
                {p.label}
              </option>
            ))}
            <option value={CUSTOM_KEY}>Custom range…</option>
          </select>
        </label>
        {rangeKey === CUSTOM_KEY && (
          <>
            <label>
              From
              <input type="date" value={customFrom} onChange={(e) => setCustomFrom(e.target.value)} max={customTo} />
            </label>
            <label>
              To
              <input type="date" value={customTo} onChange={(e) => setCustomTo(e.target.value)} min={customFrom} />
            </label>
          </>
        )}
      </div>

      {error && <p className="error">{error}</p>}

      {loading ? (
        <p className="muted">Loading…</p>
      ) : (
        <>
          <div className="stat-row">
            <div className="card stat-tile">
              <div className="stat-label">Total hours</div>
              <div className="stat-value">{formatHours(totalHours)}</div>
            </div>
            <div className="card stat-tile">
              <div className="stat-label">Completed shifts</div>
              <div className="stat-value">{completedShifts.length}</div>
            </div>
            <div className="card stat-tile">
              <div className="stat-label">Workers</div>
              <div className="stat-value">{workerCount}</div>
            </div>
          </div>

          <div className="chart-grid">
            <BarChart title="Hours by worker" data={byWorker} valueLabel={formatHours} />
            <BarChart title="Hours by project" data={byProject} valueLabel={formatHours} />
            <BarChart title="Hours by site" data={bySite} valueLabel={formatHours} />
          </div>

          <h2>Completed shifts</h2>
          {completedShifts.length === 0 ? (
            <p className="muted">No completed shifts in this range.</p>
          ) : (
            <table className="table">
              <thead>
                <tr>
                  <th>Worker</th>
                  <th>Site</th>
                  <th>Clock in</th>
                  <th>Clock out</th>
                  <th>Hours</th>
                </tr>
              </thead>
              <tbody>
                {completedShifts
                  .slice()
                  .sort((a, b) => new Date(b.clockInAt) - new Date(a.clockInAt))
                  .map((s) => (
                    <tr key={s.id}>
                      <td>{s.workerName}</td>
                      <td>{s.siteName}</td>
                      <td>{new Date(s.clockInAt).toLocaleString()}</td>
                      <td>{new Date(s.clockOutAt).toLocaleString()}</td>
                      <td>{formatHours(hoursOf(s))}</td>
                    </tr>
                  ))}
              </tbody>
            </table>
          )}
        </>
      )}
    </div>
  );
}
