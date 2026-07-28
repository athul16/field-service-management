const MAX_ROWS = 8;

/**
 * Horizontal bar list for a single magnitude-by-category comparison (hours by
 * worker/project/site). One series, one hue — no legend needed, the title
 * names what's plotted. Every bar is direct-labeled with its value, so the
 * hover highlight (pure CSS) is a nice-to-have, never the only way to read a
 * number. Categories beyond MAX_ROWS fold into a single "Other" bar rather
 * than growing the list unreadably long.
 */
export function BarChart({ title, subtitle, data, valueLabel = (v) => v.toFixed(1) }) {
  const sorted = [...data].sort((a, b) => b.value - a.value);

  let rows = sorted;
  if (sorted.length > MAX_ROWS) {
    const shown = sorted.slice(0, MAX_ROWS - 1);
    const rest = sorted.slice(MAX_ROWS - 1);
    const otherTotal = rest.reduce((sum, d) => sum + d.value, 0);
    rows = [...shown, { label: `Other (${rest.length})`, value: otherTotal }];
  }

  const max = rows.length ? Math.max(...rows.map((d) => d.value)) : 0;

  return (
    <div className="card chart-card">
      <h3 className="chart-title">{title}</h3>
      {subtitle && <p className="muted chart-subtitle">{subtitle}</p>}
      {rows.length === 0 ? (
        <p className="muted">No data for this period.</p>
      ) : (
        <div className="bar-chart">
          {rows.map((row) => {
            const pct = max > 0 ? (row.value / max) * 100 : 0;
            return (
              <div className="bar-row" key={row.label}>
                <div className="bar-row-label" title={row.label}>
                  {row.label}
                </div>
                <div className="bar-track">
                  <div className="bar-fill" style={{ width: `${pct}%` }} />
                </div>
                <div className="bar-value">{valueLabel(row.value)}</div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
