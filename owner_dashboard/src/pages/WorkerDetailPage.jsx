import { useEffect, useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { api, BASE_URL } from '../api/client';
import { CheckCircleIcon } from '../components/Icons';
import { PinRevealModal } from '../components/PinRevealModal';
import { StatusBadge } from '../components/StatusBadge';

export function WorkerDetailPage() {
  const { workerId } = useParams();

  const [worker, setWorker] = useState(null);
  const [assignments, setAssignments] = useState([]);
  const [availability, setAvailability] = useState([]);
  const [shifts, setShifts] = useState([]);
  const [projects, setProjects] = useState([]);
  const [error, setError] = useState(null);
  const [pinReveal, setPinReveal] = useState(null);

  // Independent fetches — one page failing (e.g. shifts) shouldn't block
  // the others from rendering.
  useEffect(() => {
    api
      .get(`/api/owner/workers/${workerId}`)
      .then(setWorker)
      .catch((err) => setError(err.message));
  }, [workerId]);

  useEffect(() => {
    loadAssignments();
  }, [workerId]);

  useEffect(() => {
    api
      .get(`/api/owner/workers/${workerId}/availability`)
      .then(setAvailability)
      .catch((err) => setError(err.message));
  }, [workerId]);

  useEffect(() => {
    api
      .get('/api/owner/shifts', { workerId })
      .then(setShifts)
      .catch((err) => setError(err.message));
  }, [workerId]);

  useEffect(() => {
    api.get('/api/owner/projects').then(setProjects).catch(() => {});
  }, []);

  async function loadAssignments() {
    try {
      setAssignments(await api.get(`/api/owner/workers/${workerId}/assignments`));
    } catch (err) {
      setError(err.message);
    }
  }

  async function handleResetPin() {
    try {
      const result = await api.post(`/api/owner/workers/${workerId}/pin`, {});
      setPinReveal({ workerName: worker?.fullName ?? 'this worker', pin: result.pin });
    } catch (err) {
      setError(err.message);
    }
  }

  async function handleConfirmShift(shiftId) {
    try {
      const updated = await api.patch(`/api/owner/shifts/${shiftId}/confirm`, {});
      setShifts((prev) => prev.map((s) => (s.id === shiftId ? updated : s)));
    } catch (err) {
      setError(err.message);
    }
  }

  return (
    <div>
      <p>
        <Link to="/workers">&larr; All workers</Link>
      </p>

      {error && <p className="error">{error}</p>}

      {worker && (
        <div className="card">
          <div className="page-header">
            <h1>{worker.fullName}</h1>
            <button className="btn btn-secondary" onClick={handleResetPin}>
              Reset PIN
            </button>
          </div>
          <p className="muted">{worker.phone}</p>
        </div>
      )}

      <h2>Assign to a project</h2>
      <AssignProjectForm workerId={workerId} projects={projects} onAssigned={loadAssignments} />

      <h2>Current assignments</h2>
      {assignments.length === 0 ? (
        <p className="muted">Not assigned to any site yet.</p>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Site</th>
              <th>Project</th>
              <th>Assigned</th>
            </tr>
          </thead>
          <tbody>
            {assignments.map((a) => (
              <tr key={a.id}>
                <td>{a.siteName}</td>
                <td>{a.projectName}</td>
                <td>{new Date(a.assignedAt).toLocaleString()}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      <h2>Availability</h2>
      {availability.length === 0 ? (
        <p className="muted">No availability marked yet.</p>
      ) : (
        <ul className="plain-list">
          {availability.map((slot) => (
            <li key={slot.id}>
              {new Date(slot.startAt).toLocaleDateString()}
            </li>
          ))}
        </ul>
      )}

      <h2>Completed tasks</h2>
      <p className="muted">Every shift this worker has recorded — review the clock-out photo and confirm completed work.</p>
      {shifts.length === 0 ? (
        <p className="muted">No shifts recorded yet.</p>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Site</th>
              <th>Clock in</th>
              <th>Clock out</th>
              <th>Status</th>
              <th>Photo</th>
              <th>Confirmation</th>
            </tr>
          </thead>
          <tbody>
            {shifts.map((shift) => (
              <tr key={shift.id}>
                <td>{shift.siteName}</td>
                <td>{new Date(shift.clockInAt).toLocaleString()}</td>
                <td>{shift.clockOutAt ? new Date(shift.clockOutAt).toLocaleString() : '—'}</td>
                <td>
                  <StatusBadge status={shift.status === 'COMPLETED' ? 'active' : 'closed'} label={shift.status} />
                </td>
                <td>
                  {shift.clockOutPhotoUrl ? (
                    <a href={`${BASE_URL}${shift.clockOutPhotoUrl}`} target="_blank" rel="noreferrer">
                      <img className="shift-photo-thumb" src={`${BASE_URL}${shift.clockOutPhotoUrl}`} alt="Clock-out proof" />
                    </a>
                  ) : (
                    '—'
                  )}
                </td>
                <td>
                  {shift.status !== 'COMPLETED' ? (
                    '—'
                  ) : shift.confirmedAt ? (
                    <span className="confirmed-tag">
                      <CheckCircleIcon width={16} height={16} />
                      Confirmed
                    </span>
                  ) : (
                    <button className="btn btn-secondary" onClick={() => handleConfirmShift(shift.id)}>
                      Confirm
                    </button>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      )}

      {pinReveal && (
        <PinRevealModal
          workerName={pinReveal.workerName}
          pin={pinReveal.pin}
          onClose={() => setPinReveal(null)}
        />
      )}
    </div>
  );
}

function AssignProjectForm({ workerId, projects, onAssigned }) {
  const [projectId, setProjectId] = useState('');
  const [error, setError] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  async function handleSubmit(e) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      await api.post('/api/owner/assignments', { projectId, workerId });
      setProjectId('');
      onAssigned();
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form className="card form-card" onSubmit={handleSubmit}>
      <label>
        Project
        <select value={projectId} onChange={(e) => setProjectId(e.target.value)} required>
          <option value="" disabled>
            Select a project
          </option>
          {projects.map((p) => (
            <option key={p.id} value={p.id}>
              {p.name} — {p.siteName}
            </option>
          ))}
        </select>
      </label>
      {error && <p className="error">{error}</p>}
      <button type="submit" className="btn btn-primary" disabled={submitting || !projectId}>
        {submitting ? 'Assigning…' : 'Assign'}
      </button>
    </form>
  );
}
