import { useEffect, useMemo, useState } from 'react';
import { api } from '../api/client';

const PERIOD_TYPES = ['Month', 'Quarter', 'Year'];

function lastNPeriods(n, type) {
  const now = new Date();
  const periods = [];
  if (type === 'Month') {
    for (let i = 0; i < n; i++) {
      const year = now.getFullYear();
      const month = now.getMonth() - i;
      const from = new Date(year, month, 1);
      const to = new Date(year, month + 1, 1);
      periods.push({
        key: `${from.getFullYear()}-${String(from.getMonth() + 1).padStart(2, '0')}`,
        label: from.toLocaleDateString(undefined, { month: 'long', year: 'numeric' }),
        from,
        to,
      });
    }
  } else if (type === 'Quarter') {
    const currentQuarter = Math.floor(now.getMonth() / 3);
    for (let i = 0; i < n; i++) {
      const totalQuarters = now.getFullYear() * 4 + currentQuarter - i;
      const year = Math.floor(totalQuarters / 4);
      const quarter = totalQuarters % 4;
      const from = new Date(year, quarter * 3, 1);
      const to = new Date(year, quarter * 3 + 3, 1);
      periods.push({ key: `${year}-Q${quarter + 1}`, label: `Q${quarter + 1} ${year}`, from, to });
    }
  } else {
    for (let i = 0; i < n; i++) {
      const year = now.getFullYear() - i;
      const from = new Date(year, 0, 1);
      const to = new Date(year + 1, 0, 1);
      periods.push({ key: `${year}`, label: `${year}`, from, to });
    }
  }
  return periods;
}

function formatHours(totalMs) {
  const hours = totalMs / (1000 * 60 * 60);
  return hours.toFixed(1);
}

export function ReportsPage() {
  const [workers, setWorkers] = useState([]);
  const [workerId, setWorkerId] = useState('');
  const [periodType, setPeriodType] = useState('Month');
  const [periodKey, setPeriodKey] = useState('');
  const [shifts, setShifts] = useState([]);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const periods = useMemo(() => lastNPeriods(12, periodType), [periodType]);
  const selectedPeriod = periods.find((p) => p.key === periodKey) ?? periods[0];

  useEffect(() => {
    api.get('/api/owner/workers').then(setWorkers).catch((err) => setError(err.message));
  }, []);

  useEffect(() => {
    setPeriodKey('');
  }, [periodType]);

  useEffect(() => {
    if (!workerId || !selectedPeriod) {
      setShifts([]);
      return;
    }
    setLoading(true);
    setError(null);
    api
      .get('/api/owner/shifts', {
        workerId,
        from: selectedPeriod.from.toISOString(),
        to: selectedPeriod.to.toISOString(),
      })
      .then(setShifts)
      .catch((err) => setError(err.message))
      .finally(() => setLoading(false));
  }, [workerId, selectedPeriod?.key]);

  const completedShifts = shifts.filter((s) => s.status === 'COMPLETED' && s.clockOutAt);
  const totalMs = completedShifts.reduce(
    (sum, s) => sum + (new Date(s.clockOutAt).getTime() - new Date(s.clockInAt).getTime()),
    0,
  );

  return (
    <div>
      <div className="page-header">
        <h1>Reports</h1>
      </div>

      <div className="card form-card">
        <label>
          Worker
          <select value={workerId} onChange={(e) => setWorkerId(e.target.value)}>
            <option value="">Select a worker</option>
            {workers.map((w) => (
              <option key={w.id} value={w.id}>
                {w.fullName}
              </option>
            ))}
          </select>
        </label>
        <label>
          Period
          <select value={periodType} onChange={(e) => setPeriodType(e.target.value)}>
            {PERIOD_TYPES.map((t) => (
              <option key={t} value={t}>
                {t}
              </option>
            ))}
          </select>
        </label>
        <label>
          {periodType}
          <select value={selectedPeriod?.key ?? ''} onChange={(e) => setPeriodKey(e.target.value)}>
            {periods.map((p) => (
              <option key={p.key} value={p.key}>
                {p.label}
              </option>
            ))}
          </select>
        </label>
      </div>

      {error && <p className="error">{error}</p>}

      {!workerId ? (
        <p className="muted">Select a worker to see their total hours.</p>
      ) : loading ? (
        <p className="muted">Loading…</p>
      ) : (
        <>
          <div className="card">
            <h2 style={{ margin: 0 }}>{formatHours(totalMs)} hours</h2>
            <p className="muted">
              {selectedPeriod?.label} &middot; {completedShifts.length} completed shift
              {completedShifts.length === 1 ? '' : 's'}
            </p>
          </div>

          {completedShifts.length > 0 && (
            <table className="table">
              <thead>
                <tr>
                  <th>Site</th>
                  <th>Clock in</th>
                  <th>Clock out</th>
                  <th>Hours</th>
                </tr>
              </thead>
              <tbody>
                {completedShifts.map((s) => (
                  <tr key={s.id}>
                    <td>{s.siteName}</td>
                    <td>{new Date(s.clockInAt).toLocaleString()}</td>
                    <td>{new Date(s.clockOutAt).toLocaleString()}</td>
                    <td>{formatHours(new Date(s.clockOutAt).getTime() - new Date(s.clockInAt).getTime())}</td>
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
