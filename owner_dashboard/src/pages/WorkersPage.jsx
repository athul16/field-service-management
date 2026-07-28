import { useEffect, useState } from 'react';
import { Link, useLocation } from 'react-router-dom';
import { api } from '../api/client';
import { PinRevealModal } from '../components/PinRevealModal';
import { buildE164, PhoneInput, usePhoneCountries } from '../components/PhoneInput';

export function WorkersPage() {
  // The Home dashboard's "+ New worker" quick action links here with this flag
  // set, so the form is already open instead of making the owner click twice.
  const location = useLocation();
  const [workers, setWorkers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState(null);
  const [showForm, setShowForm] = useState(Boolean(location.state?.openForm));
  const [pinReveal, setPinReveal] = useState(null); // { workerName, pin }

  useEffect(() => {
    loadWorkers();
  }, []);

  async function loadWorkers() {
    setLoading(true);
    try {
      setWorkers(await api.get('/api/owner/workers'));
    } catch (err) {
      setError(err.message);
    } finally {
      setLoading(false);
    }
  }

  return (
    <div>
      <div className="page-header">
        <h1>Workers</h1>
        <button className="btn btn-primary" onClick={() => setShowForm((v) => !v)}>
          {showForm ? 'Cancel' : 'New Worker'}
        </button>
      </div>

      {showForm && (
        <CreateWorkerForm
          onCreated={(result) => {
            setShowForm(false);
            setPinReveal({ workerName: result.profile.fullName, pin: result.pin });
            loadWorkers();
          }}
        />
      )}

      {error && <p className="error">{error}</p>}
      {loading ? (
        <p className="muted">Loading…</p>
      ) : workers.length === 0 ? (
        <p className="muted">No workers yet. Create one to get started.</p>
      ) : (
        <table className="table">
          <thead>
            <tr>
              <th>Name</th>
              <th>Phone</th>
            </tr>
          </thead>
          <tbody>
            {workers.map((worker) => (
              <tr key={worker.id}>
                <td>
                  <Link to={`/workers/${worker.id}`}>{worker.fullName}</Link>
                </td>
                <td>{worker.phone}</td>
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

function CreateWorkerForm({ onCreated }) {
  const { countries, defaultCountry } = usePhoneCountries();
  const [fullName, setFullName] = useState('');
  const [iso2, setIso2] = useState('');
  const [number, setNumber] = useState('');
  const [error, setError] = useState(null);
  const [submitting, setSubmitting] = useState(false);

  useEffect(() => {
    if (defaultCountry && !iso2) setIso2(defaultCountry);
  }, [defaultCountry]);

  async function handleSubmit(e) {
    e.preventDefault();
    setError(null);
    setSubmitting(true);
    try {
      // No pin field — the backend generates one and returns it once.
      const phone = buildE164(countries, iso2, number);
      const result = await api.post('/api/owner/workers', { fullName, phone });
      onCreated(result);
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <form className="card form-card" onSubmit={handleSubmit}>
      <label>
        Full name
        <input value={fullName} onChange={(e) => setFullName(e.target.value)} required />
      </label>
      <label>
        Phone number
        <PhoneInput countries={countries} iso2={iso2} onIso2Change={setIso2} number={number} onNumberChange={setNumber} />
      </label>
      <p className="muted">A 6-digit login PIN will be generated automatically and shown once.</p>
      {error && <p className="error">{error}</p>}
      <button type="submit" className="btn btn-primary" disabled={submitting}>
        {submitting ? 'Creating…' : 'Create Worker'}
      </button>
    </form>
  );
}
