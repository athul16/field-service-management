import { useState } from 'react';

/** Shown exactly once after a worker is created or their PIN is reset — the
 * plaintext PIN is never persisted client-side beyond this modal's state. */
export function PinRevealModal({ workerName, pin, onClose }) {
  const [copied, setCopied] = useState(false);

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(pin);
      setCopied(true);
    } catch {
      // Clipboard access can fail (permissions, insecure context) — the PIN
      // is still visible on screen, so this isn't a blocking failure.
    }
  }

  return (
    <div className="modal-overlay">
      <div className="card modal">
        <h2>Share this PIN with {workerName}</h2>
        <p className="muted">
          This is shown only once. Write it down or share it with the worker now — it can't be
          retrieved again later, only reset.
        </p>
        <div className="pin-display">{pin}</div>
        <div className="modal-actions">
          <button className="btn btn-secondary" onClick={handleCopy}>
            {copied ? 'Copied!' : 'Copy PIN'}
          </button>
          <button className="btn btn-primary" onClick={onClose}>
            Done
          </button>
        </div>
      </div>
    </div>
  );
}
