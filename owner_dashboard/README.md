# Owner Dashboard

React + Vite web app for the business owner: create sites (permanent physical locations) and one or more projects under each site over time (with an active/closed status), onboard workers with an auto-generated login PIN, assign workers to projects, view each worker's assignments/availability/shift history, and report a worker's total hours by month/quarter/year. Calls the same Java Spring Boot `backend/` API the `employee_app` mobile app uses — this app holds no database credentials of its own, only a JWT for the backend.

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
├── layout/AppLayout.jsx     # sidebar + top bar shell for authenticated pages
├── components/PinRevealModal.jsx  # shows a generated/reset PIN exactly once
├── pages/
│   ├── LoginPage.jsx
│   ├── SitesPage.jsx           # list + create
│   ├── SiteDetailPage.jsx      # site info + its projects (list + create)
│   ├── ProjectsPage.jsx        # all-projects list (read-only; create happens from a site)
│   ├── ProjectDetailPage.jsx   # project info + its one site + close/reopen status toggle
│   ├── WorkersPage.jsx         # list + create (PIN shown once on creation)
│   ├── WorkerDetailPage.jsx    # profile, reset PIN, assign to project, assignments/availability/shifts
│   └── ReportsPage.jsx         # worker + month/quarter/year picker -> total completed hours
└── App.jsx                  # routes
```

## Notes

- No state library, no UI framework, no TypeScript — plain `useState`/`useEffect` per page and hand-written CSS (`src/index.css`), matching this repo's low-ceremony style elsewhere.
- Worker PINs are never fetched or displayed after creation/reset — the backend returns the plaintext PIN exactly once in the create/reset response, and this app never persists it beyond the confirmation modal.
- `npm audit` reports a `react-router` advisory (RSC-mode CSRF bypass). This app is a plain client-side SPA with no React Server Components/SSR involved, so that specific vulnerability class doesn't apply — left as-is rather than force a breaking downgrade.
