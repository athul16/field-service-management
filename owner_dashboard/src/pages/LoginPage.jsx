import { useEffect, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../auth/AuthContext';
import { buildE164, PhoneInput, usePhoneCountries } from '../components/PhoneInput';

export function LoginPage() {
  const { login } = useAuth();
  const navigate = useNavigate();
  const { countries, defaultCountry } = usePhoneCountries();
  const [iso2, setIso2] = useState('');
  const [number, setNumber] = useState('');
  const [pin, setPin] = useState('');
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
      await login(buildE164(countries, iso2, number), pin);
      navigate('/projects', { replace: true });
    } catch (err) {
      setError(err.message);
    } finally {
      setSubmitting(false);
    }
  }

  return (
    <div className="centered-page">
      <form className="card login-card" onSubmit={handleSubmit}>
        <h1>Owner Dashboard</h1>
        <p className="muted">Log in with your owner phone number and PIN.</p>

        <label>
          Phone number
          <PhoneInput
            countries={countries}
            iso2={iso2}
            onIso2Change={setIso2}
            number={number}
            onNumberChange={setNumber}
            autoFocus
          />
        </label>

        <label>
          PIN
          <input
            type="password"
            inputMode="numeric"
            value={pin}
            onChange={(e) => setPin(e.target.value)}
            required
          />
        </label>

        {error && <p className="error">{error}</p>}

        <button type="submit" className="btn btn-primary" disabled={submitting}>
          {submitting ? 'Logging in…' : 'Log in'}
        </button>
      </form>
    </div>
  );
}
