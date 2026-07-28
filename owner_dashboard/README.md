# Owner Dashboard

React + Vite web app for the business owner: a live Home dashboard (KPIs, recent activity, hours-by-site, sites overview), create sites (permanent physical locations) and one or more projects under each site over time (with an active/closed status), onboard workers with an auto-generated login PIN, assign workers to projects, view each worker's assignments/availability/shift history, and a Reports page (custom date range plus hours-by-worker/project/site bar charts). Calls the same Java Spring Boot `backend/` API the `employee_app` mobile app uses — this app holds no database credentials of its own, only a JWT for the backend.

Visual identity is "Blueprint" — a deep-cobalt accent, sharp-ish corners, and a fixed dark-navy sidebar, chosen (from three pitched directions) to read as credible enterprise software rather than a demo app. Every color/radius is a CSS custom property in `src/index.css`, not a one-off hex value.

## Prerequisites

- Node.js + npm (`node --version`) — install via `brew install node` if missing
- The `backend/` API running locally (see the root `README.md`'s Backend section) with CORS configured to allow this app's dev origin (already the default — see `CORS_ALLOWED_ORIGINS` in `backend/.env.example`)
- An owner account to log in with (the bootstrap owner from `backend/.env`, or any worker profile with `role: OWNER`)

## Setup

```bash
cd owner_dashboard
npm install
cp .env.example .env
# edit .env if the backend isn't running on the default http://localhost:8080
```

## Run

```bash
npm run dev
```

Open http://localhost:5173 and log in with an owner's phone number + PIN.

## Structure

```
src/
├── api/client.js           # fetch wrapper — attaches the JWT, normalizes error responses
├── auth/                   # AuthContext (login/logout, role check), ProtectedRoute
├── layout/AppLayout.jsx     # fixed left sidebar shell (nav + user/logout) for authenticated pages
├── lib/hours.js             # formatHours/hoursOf/aggregateHours — shared by Home + Reports
├── components/
│   ├── PinRevealModal.jsx  # shows a generated/reset PIN exactly once
│   ├── BarChart.jsx        # hand-rolled horizontal bar list (no charting library)
│   ├── StatusBadge.jsx     # active/closed status pill
│   ├── PhoneInput.jsx      # country-code select + national-number input, builds E.164
│   └── Icons.jsx           # hand-rolled inline SVG icon set
├── pages/
│   ├── LoginPage.jsx
│   ├── HomePage.jsx            # KPI tiles, recent-activity feed, hours-by-site chart, sites overview
│   ├── SitesPage.jsx           # list + create
│   ├── SiteDetailPage.jsx      # site info + its projects (list + create)
│   ├── ProjectsPage.jsx        # all-projects list (read-only; create happens from a site)
│   ├── ProjectDetailPage.jsx   # project info + its one site + close/reopen status toggle
│   ├── WorkersPage.jsx         # list + create (PIN shown once on creation)
│   ├── WorkerDetailPage.jsx    # profile, reset PIN, assign to project, assignments/availability/shifts
│   └── ReportsPage.jsx         # date-range picker (presets + custom) + optional worker filter -> hours-by-worker/project/site bar charts
└── App.jsx                  # routes
```

## Notes

- No state library, no UI framework, no TypeScript — plain `useState`/`useEffect` per page and hand-written CSS (`src/index.css`), matching this repo's low-ceremony style elsewhere.
- Worker PINs are never fetched or displayed after creation/reset — the backend returns the plaintext PIN exactly once in the create/reset response, and this app never persists it beyond the confirmation modal.
- `npm audit` reports a `react-router` advisory (RSC-mode CSRF bypass). This app is a plain client-side SPA with no React Server Components/SSR involved, so that specific vulnerability class doesn't apply — left as-is rather than force a breaking downgrade.
