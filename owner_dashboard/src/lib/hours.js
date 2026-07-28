/** Shared by ReportsPage and HomePage — one place for "how many hours did a shift take"
 * and "sum hours by some key" so the two pages can't drift on the math. */

export function formatHours(totalHours) {
  return totalHours.toFixed(1);
}

/** Only call on a COMPLETED shift (clockOutAt set) — an in-progress shift has no duration yet. */
export function hoursOf(shift) {
  return (new Date(shift.clockOutAt).getTime() - new Date(shift.clockInAt).getTime()) / (1000 * 60 * 60);
}

export function aggregateHours(shifts, keyFn) {
  const totals = new Map();
  for (const shift of shifts) {
    const key = keyFn(shift);
    totals.set(key, (totals.get(key) ?? 0) + hoursOf(shift));
  }
  return Array.from(totals, ([label, value]) => ({ label, value }));
}
