# Field Service Platform

A lightweight field service operations platform for owners who manage projects and remote, mostly part-time, non-technical workers. The platform gives owners real-time visibility into clock-in/clock-out activity, project progress, and worker availability.

## What this is

Three connected pieces:

1. **Backend API** (`backend/`) — a Java Spring Boot REST API that owns **all** business logic, database access, authentication, and photo storage. Nothing else in this repo talks to the database directly.
2. **Employee mobile app** (`employee_app/`) — a simple Flutter app (Android + iOS) workers use to log in with a phone number + PIN (issued by the owner), clock in/out at a work site, mark availability, and view their timesheet. There is no self-registration. It's a thin UI client of the backend API — it holds no database or auth credentials itself, only a session token.
3. **Owner web dashboard** (`owner_dashboard/`) — a React + Vite website where the owner creates sites (permanent physical locations) and projects (time-bounded engagements at a site, with an active/closed status), onboards workers (auto-generated login PIN, shown once), assigns them to a project, views each worker's assignments/availability/shift history, and reports a worker's total hours by month/quarter/year. Calls the same backend API the employee app already uses.

The backend's Postgres database currently happens to be hosted on Supabase (a holdover from how this project started), but the backend talks to it via a plain JDBC connection — none of Supabase's client-facing features (Auth, Storage, PostgREST, Row Level Security) are used. This was a deliberate choice: the database can be swapped to a different host/engine later without touching the mobile app or the API surface at all.

## Repository structure

```
field-service-platform/
├── agents.md                # Ground rules for AI coding agents working in this repo
├── backend/                  # Java Spring Boot REST API — owns all business logic + DB access
│   └── src/main/
│       ├── java/com/fieldservice/backend/
│       │   ├── config/        # Security config, bootstrap-owner runner, static resource config
│       │   ├── security/      # JWT issuance/validation
│       │   ├── controller/    # REST endpoints
│       │   ├── service/       # Business logic + authorization checks
│       │   ├── repository/    # Plain NamedParameterJdbcTemplate wrappers — no ORM
│       │   ├── entity/        # Plain POJOs (raw UUID foreign keys, no JPA annotations)
│       │   └── dto/           # Request/response shapes (entities are never serialized directly)
│       └── resources/db/migration/  # Flyway — current schema source of truth
├── employee_app/              # Flutter mobile app (workers) — thin UI client of backend/
│   └── lib/
│       ├── core/              # ApiClient (JWT-authenticated HTTP client), theme
│       ├── models/             # Data models (Worker, Project, Site, Shift, Availability)
│       ├── services/           # Thin wrappers over ApiClient, one per feature area
│       └── features/           # Screens, grouped by feature
├── owner_dashboard/            # React + Vite owner website — thin client of backend/'s API
│   └── src/
│       ├── api/                # fetch wrapper (JWT attach, error normalization)
│       ├── auth/                # AuthContext (login/logout, OWNER-role check), ProtectedRoute
│       ├── layout/               # Sidebar + top bar shell
│       ├── components/           # PinRevealModal (shared by create-worker + reset-pin)
│       └── pages/                 # Sites, SiteDetail, Projects, ProjectDetail, Workers, WorkerDetail, Reports, Login
└── supabase/                   # Historical — describes the schema before the backend migration;
    └── migrations/             # backend/.../db/migration/ is the current source of truth now
```

## Features (from project spec)

### Employee side (mobile app)
- Log in with phone number + PIN — no self-registration; the owner creates the account and issues the PIN
- **Shift screen** (formerly "Attendance", formerly "Clock In/Out"): Start Shift / End Shift, tied to a selected work site; ending a shift requires a progress photo. The backend verifies the worker is actually assigned to a site before allowing a shift to start, and that a shift belongs to the requesting worker before allowing it to end. A worker can tap a selected site again to deselect it, and can start a new shift at a different assigned site immediately after ending one elsewhere (sequential multi-site work — a worker just can't be clocked in at two sites *at once*). The active-shift card shows which site it's for, not just the elapsed time. The screen itself is designed for non-technical, low-literacy workers: work sites are picked from large tappable cards (a colored icon per site, not a text dropdown — the same site always gets the same color), showing the site's name and address instead of a list, and Start Shift / End Shift are big full-width green/red buttons (🟢 Start Shift / 🔴 End Shift) rather than small text buttons
- A worker only ever sees the project(s)/site(s) they've been assigned to
- **Availability**: tap any day on the calendar to mark it fully available (turns green) or tap again to un-mark it — no time-of-day, no separate save step, changes sync immediately. A "Clear All" button (with a confirmation prompt) wipes every marked day at once
- **Timesheet**: toggle between Week and Month views of completed hours, each with a total for the period and its own quick-jump picker (tap the "Week of M/D" or "Month Year" label to pick any of the last 12 weeks/months directly, instead of only stepping one at a time via the arrows)

### Owner side (web dashboard)
- **Create sites** (permanent physical locations — company name, address, coordinates) independently, then **create one or more projects under a site over time** (time-bounded engagements, e.g. a maintenance contract), each with an **active/closed status** the owner can toggle
- Assign workers to a project (the project's site is implied — a worker doesn't need to pick a site separately)
- **Employee onboarding**: create a worker's account (name, phone) with a **server-generated 6-digit PIN**, shown once so the owner can share it with the worker directly (in person, by message, etc.)
- Reset a worker's PIN at any time if they forget it (also auto-generated, shown once)
- View existing sites, projects, and worker details
- Drill into any worker to see their current project assignments, marked availability, and shift history
- **Reports**: pick a worker and a month/quarter/year to see their total completed hours for that period

**All of the above are built and working end-to-end** against the backend's REST API (`/api/owner/workers`, `/api/owner/sites`, `/api/owner/sites/{id}/projects`, `/api/owner/projects`, `/api/owner/projects/{id}/status`, `/api/owner/assignments`, `/api/owner/shifts`, plus two owner-facing reads: `/api/owner/workers/{id}/availability` and `/api/owner/workers/{id}/assignments`). Push/email/SMS notifications for new assignments aren't wired up yet.

## Tech stack

| Layer | Choice |
|---|---|
| Mobile app | Flutter (single codebase, Android + iOS) |
| Backend | Java 21, Spring Boot (Web, JDBC, Security), plain `NamedParameterJdbcTemplate` (no ORM), Flyway, JWT (jjwt) |
| Database | Postgres (currently Supabase-hosted, accessed via plain JDBC — no Supabase client features in use) |
| Owner dashboard | React + Vite (plain JavaScript, no UI framework), calls the backend's REST API directly with `fetch` |

## Getting started

### Backend
1. Copy `backend/.env.example` to `backend/.env` and fill in the database connection details (from your Postgres host's connection-pooling info, not a direct/IPv6-only connection if applicable) and a JWT secret.
2. Run: `set -a && source backend/.env && set +a && mvn -f backend spring-boot:run`
3. Confirm it's up: `curl http://localhost:8080/api/ping` → `{"status":"ok"}`

See [`agents.md`](agents.md)'s Environment notes for connection-pooler gotchas if the database is Supabase-hosted.

### Employee app
See [`employee_app/README.md`](employee_app/README.md) for setup and how to run the app locally. Set `API_BASE_URL` in `employee_app/.env` to the backend's address (`http://10.0.2.2:8080` from the Android emulator, `http://localhost:8080` from iOS Simulator).

### Owner dashboard
1. Copy `owner_dashboard/.env.example` to `owner_dashboard/.env` and set `VITE_API_BASE_URL` to the backend's address (`http://localhost:8080`).
2. `cd owner_dashboard && npm install && npm run dev`
3. Open http://localhost:5173 and log in with an OWNER-role phone + PIN (e.g. the bootstrap owner from `backend/.env`).

See [`owner_dashboard/README.md`](owner_dashboard/README.md) for the full page/component breakdown.

## Status

🚧 Early build, but the hard architectural work is done. The full migration away from Supabase's client SDK (Auth, Storage, PostgREST, RLS) to a self-owned Java backend is complete and verified end-to-end on the Android emulator: login, clock-in (with site-assignment verification), clock-out (with photo upload), availability, and the weekly timesheet all work against the real backend. The owner dashboard now has a working UI against every one of these endpoints (see Recent history below).

Recent history:
- Replaced self-registration and phone/OTP login with owner-provisioned phone + PIN login, removing the Twilio/SMS dependency entirely.
- **Migrated the entire backend from Supabase's client SDK to a Java Spring Boot API** that owns all business logic, database access, JWT-based auth, and clock-out photo storage. Authorization (who can see/touch what) now lives in the backend's service layer instead of Postgres RLS. See `agents.md` for the detailed rationale and the gotchas hit along the way (Supabase's IPv6-only direct connection, connection-pooler tenant routing, a Hibernate lazy-loading trap, a Postgres/JDBC null-parameter-type quirk, and a Flutter Android Gradle dependency conflict).
- **Replaced Spring Data JPA/Hibernate with plain `NamedParameterJdbcTemplate`.** Hibernate had already caused the lazy-loading and null-parameter bugs mentioned above; entities are now plain POJOs with raw `UUID` foreign keys (no lazy loading possible) and repositories are hand-written, explicit SQL — full regression suite re-verified end-to-end. See `agents.md`'s Java/Spring Boot conventions and Status section for the design and the two regressions specifically guarded against (SQL-side dedup, no redundant re-reads on writes that already have their data in scope).
- Fixed several UTC/local-time display and query bugs across the clock, timesheet, and availability screens — see `agents.md`'s Timestamps convention for the rule that keeps these from recurring.
- Added a Postman collection (`backend/postman/field-service-platform.postman_collection.json`) covering every endpoint, for manual testing and data-seeding ahead of `owner_dashboard` having a real UI.
- **Redesigned the Clock In/Out screen as "Attendance"** for non-technical, low-literacy workers: work sites are now large tappable cards with a consistent color-coded icon per site instead of a dropdown list, and Start Shift / End Shift are big full-width green/red buttons. Scoped deliberately to just this one screen (a prior full-app graphical redesign was built and then explicitly reverted earlier in the project) — verified end-to-end on the Android emulator, including the photo upload on End Shift.
- **Renamed "Attendance" to "Shift"** (tab + title), added the ability to deselect a chosen work site, confirmed sequential multi-site shifts already worked with no backend changes needed, and added the site/project name to the active-shift card. All remaining "clock in"/"clock out" wording in the app was renamed to "start shift"/"end shift" phrasing.
- **Redesigned Availability as a full-day toggle**: removed the time-of-day pickers, drag-range day selection, and Save button entirely — tapping a day now marks it available (green) or un-marks it immediately, with a "Clear All" action (confirmation-gated) to wipe every marked day at once. Fixed a real bug along the way: the first version did a full list refetch after every tap, which was slow and could let one tap's background refresh clobber another day's more recent optimistic update — fixed by using the add endpoint's own response instead of a second round trip.
- **Added Week/Month views to the Timesheet screen**, plus a quick-jump picker for each (tap the period label to pick any of the last 12 weeks/months directly). No backend changes were needed — the existing `/api/timesheet/week` endpoint already takes an arbitrary date range, so the Month view just requests a month-long range through the same endpoint.
- Added the site's address to both site displays on the Shift screen (the site-selection cards and the active-shift card) — the data was already being fetched, just not shown.
- **Built the Owner Dashboard** (`owner_dashboard/`, React + Vite): projects, sites, workers (with auto-generated PIN), assignments, and per-worker availability/shift views, all working end-to-end against the live backend. Required three small backend additions — worker PIN generation (`POST /api/owner/workers`/`.../pin` now auto-generate a 6-digit PIN when none is supplied, returned once in the response), two new owner-facing reads (`GET /api/owner/workers/{id}/availability`, `.../assignments`), and a CORS policy (none existed before, since the mobile app isn't subject to browser CORS). Also caught and fixed a real pre-existing bug found during verification: any `@Valid` validation failure was returning a misleading 401 "Unauthorized" instead of 400, because Spring's error-dispatch to `/error` wasn't in the security config's permit-all list — see `agents.md` for the mechanism.
- **Inverted the Site/Project relationship**: a Site is now the independent, permanent entity (created first, with a company name/address), and a Project belongs to exactly one Site — one site can now host many projects over time, the reverse of the original model. Projects gained an explicit active/closed status, `location` was dropped from Project (the site's address covers it), and the dashboard gained a Sites section and a Reports page (per-worker total hours by month/quarter/year). See `agents.md`'s Status section for the full detail, including a CORS `PATCH`-method gap and an assignment-derivation invariant this change introduced.
- **Redesigned the owner dashboard's look and feel**: a colorful tile-based home screen (live counts per section) plus a top tab bar replacing the old sidebar, hand-rolled inline SVG icons (no new dependency), and status pill badges for project active/closed state.

See [`FUTURE_UPGRADES.md`](FUTURE_UPGRADES.md) for a running list of features not built yet (notifications, GPS clock-in verification, payroll export, scheduling from availability, and more) — kept separate from this file since none of it is scheduled or scoped.
