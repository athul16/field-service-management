import { useEffect, useState } from 'react';
import { api } from '../api/client';

/** Fetches the backend's supported-countries config once — shared by any page with a phone field. */
export function usePhoneCountries() {
  const [countries, setCountries] = useState([]);
  const [defaultCountry, setDefaultCountry] = useState(null);

  useEffect(() => {
    api
      .get('/api/config')
      .then((config) => {
        setCountries(config.phoneCountries);
        setDefaultCountry(config.defaultCountry);
      })
      .catch(() => {
        // Non-fatal — the country <select> just renders empty until this succeeds.
      });
  }, []);

  return { countries, defaultCountry };
}

/** A country-code <select> + national-number <input>, kept in sync as two pieces so the caller
 *  can combine them into a full E.164 string right before submit via buildE164(). */
export function PhoneInput({ countries, iso2, onIso2Change, number, onNumberChange, autoFocus }) {
  const selected = countries.find((c) => c.iso2 === iso2);

  return (
    <div className="phone-input-row">
      <select value={iso2 ?? ''} onChange={(e) => onIso2Change(e.target.value)} aria-label="Country code">
        {countries.map((c) => (
          <option key={c.iso2} value={c.iso2}>
            {c.dialCode} {c.iso2}
          </option>
        ))}
      </select>
      <input
        type="tel"
        inputMode="numeric"
        value={number}
        onChange={(e) => onNumberChange(e.target.value.replace(/\D/g, ''))}
        placeholder={selected ? '0'.repeat(selected.nationalLength) : 'Phone number'}
        maxLength={selected?.nationalLength}
        autoFocus={autoFocus}
        required
      />
    </div>
  );
}

/** Combines a selected country + national digits into the canonical E.164 string the backend expects. */
export function buildE164(countries, iso2, number) {
  const country = countries.find((c) => c.iso2 === iso2);
  return country ? `${country.dialCode}${number}` : number;
}
