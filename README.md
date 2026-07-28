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
│       │   ├── config/        # Security config, CORS, bootstrap-owner runner, phone-country list
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
│       ├── models/             # Data models (Assignment, Shift, AvailabilitySlot, PhoneCountry)
│       ├── services/           # Thin wrappers over ApiClient, one per feature area
│       └── features/           # Screens, grouped by feature
├── owner_dashboard/            # React + Vite owner website — thin client of backend/'s API
│   └── src/
│       ├── api/                # fetch wrapper (JWT attach, error normalization)
│       ├── auth/                # AuthContext (login/logout, OWNER-role check), ProtectedRoute
│       ├── layout/               # Fixed left sidebar shell (nav + user/logout)
│       ├── components/           # PinRevealModal, BarChart (hand-rolled, no charting library), StatusBadge, Icons
│       ├── lib/                   # hours.js — shared by Home + Reports so the two can't drift on the math
│       └── pages/                 # Home, Sites, SiteDetail, Projects, ProjectDetail, Workers, WorkerDetail, Reports, Login
└── supabase/                   # Historical — describes the schema before the backend migration;
    └── migrations/             # backend/.../db/migration/ is the current source of truth now
```

## Features (from project spec)

### Employee side (mobile app)
- Log in with a country code + phone number + PIN — no self-registration; the owner creates the account and issues the PIN. The country list comes from the backend (`GET /api/config`), so adding a new deployment market is a config change, not a code change
- **Shift screen** (formerly "Attendance", formerly "Clock In/Out"): every assigned project gets its own card with an inline Start/End toggle pill, since a worker can be assigned to more than one project at once. Ending a shift attaches 1-3 photos (camera or gallery, worker's choice) instead of one mandatory live capture. The backend verifies the worker is actually assigned to a site before allowing a shift to start, and that a shift belongs to the requesting worker before allowing it to end. Starting a shift on one card dims and disables every other card (only one shift can be open per worker at a time); a worker can start a new shift at a different assigned site immediately after ending one elsewhere (sequential multi-site work — just not concurrent). The screen itself is designed for non-technical, low-literacy workers: assignments are picked from large tappable cards (a colored icon per site, not a text dropdown — the same site always gets the same color) showing the site's name, project, and address, and the Start/End pill is a big green/red button (🟢 Start / 🔴 End) rather than small text. A worker assigned to more than one project at the same site sees one card per project, not a single site card that would have to pick one
- A worker only ever sees the project(s)/site(s) they've been assigned to
- **Availability**: tap any day on the calendar to mark it fully available (turns green) or tap again to un-mark it — no time-of-day, no separate save step, changes sync immediately. A "Clear All" button (with a confirmation prompt) wipes every marked day at once
- **Timesheet**: toggle between Week and Month views of completed hours, each with a total for the period and its own quick-jump picker (tap the "27 Jul – 2 Aug" or "July 2026" label to pick any of the last 12 weeks/months directly, instead of only stepping one at a time via the arrows). Dates are always spelled out with the month name (never a bare numeric `month/day`), so they read unambiguously regardless of whether the reader's local convention is day-first or month-first

### Owner side (web dashboard)
- **Home is a live operational dashboard**, not a nav menu: four clickable KPI tiles (sites, active projects, workers, hours logged this month), a recent-activity feed built from the current month's shifts (a still-open shift shows a live pulse; a finished one shows its hours), an hours-by-site chart, and a sites overview with each site's active-project count — plus a "+ New worker" shortcut that jumps straight to the Workers page with the create-form already open
- **Create sites** (permanent physical locations — company name, address, coordinates) independently, then **create one or more projects under a site over time** (time-bounded engagements, e.g. a maintenance contract), each with an **active/closed status** the owner can toggle
- Assign workers to a project (the project's site is implied — a worker doesn't need to pick a site separately)
- **Employee onboarding**: create a worker's account (name, country code + phone) with a **server-generated 6-digit PIN**, shown once so the owner can share it with the worker directly (in person, by message, etc.). Every phone number is stored as a complete, standardized international number (e.g. `+14155552671`) regardless of how it's typed
- Reset a worker's PIN at any time if they forget it (also auto-generated, shown once)
- View existing sites, projects, and worker details
- Drill into any worker to see their current project assignments, marked availability, and completed tasks — including up to 3 clock-out photos per shift, each viewable full-size, with a **Confirm** action to sign off on completed work
- **Reports**: a date-range picker (This month/Last month/This quarter/This year/Last 12 months, or a custom from/to range) plus an optional worker filter, with bar charts showing total hours by worker, by project, and by site, plus a detail table of every completed shift in range

**All of the above are built and working end-to-end** against the backend's REST API (`/api/owner/workers`, `/api/owner/sites`, `/api/owner/sites/{id}/projects`, `/api/owner/projects`, `/api/owner/projects/{id}/status`, `/api/owner/assignments`, `/api/owner/shifts`, `/api/owner/shifts/{id}/confirm`, plus two owner-facing reads: `/api/owner/workers/{id}/availability` and `/api/owner/workers/{id}/assignments`), plus a public `GET /api/config` both frontends use for the phone country-code selector. Push/email/SMS notifications for new assignments aren't wired up yet.

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

### Deploying a demo/trial environment
See [`DEPLOYMENT.md`](DEPLOYMENT.md) for a free-tier cloud deploy (backend + dashboard both on Render, Android via Firebase App Distribution) — useful for showing this to a prospective client or giving a small group limited-time trial access. Live at the time of writing: `https://field-service-backend-76kh.onrender.com` and `https://field-service-dashboard.onrender.com`.

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
- **Redesigned the owner dashboard's look and feel**: a colorful tile-based home screen (live counts per section) plus a top tab bar, hand-rolled inline SVG icons (no new dependency), and status pill badges for project active/closed state. (Superseded by the "Blueprint" reskin below.)
- **Added shift confirmation**: `shifts` gained `confirmed_at`/`confirmed_by` columns (`V3__add_shift_confirmation.sql`) and a `PATCH /api/owner/shifts/{id}/confirm` endpoint (completed shifts only). The dashboard's Worker Detail page — renamed "Completed tasks" — now shows each shift's clock-out photo as a clickable thumbnail (opens full-size in a new tab, served from `/photos/**`) plus a Confirm button that turns into a green "Confirmed" tag once used.
- **Standardized phone numbers to E.164** ahead of expanding beyond a single test market. Every phone number (login, worker creation, the bootstrap owner) now passes through a single backend `PhoneNumberService` that strips incidental spaces/dashes and validates against a new, backend-owned list of supported countries (`GET /api/config` — currently US + India, add a country there without touching either frontend). Both the mobile app's login screen and the dashboard's login/create-worker forms gained a country-code selector built from that same config. Existing test accounts (in a mix of inconsistent formats) were wiped and reseeded rather than backfilled, same reasoning as the Site/Project inversion's reset.
- **The Shift screen now shows the project name alongside each site**, restoring project visibility that the Site/Project inversion had removed (a site can host more than one project now, so it's no longer implied by the site alone). Backed by a new worker-facing `GET /api/assignments` (replacing the old, project-blind `GET /api/sites/assigned`) — a worker assigned to more than one project at the same site now sees one card per project instead of a single deduped site card. A worker-name greeting was added alongside this, then removed again after three rounds of direct user feedback that it was unnecessary/distracting on a screen the worker already knows is their own.
- **Timesheet week/date labels now spell out the month** (`27 Jul` / `27 Jul – 2 Aug`) instead of numeric `month/day`, which reads as day-first outside the US and was flagged as confusing by an Indian user.
- **Start/End Shift became a per-project toggle, and clock-out photos went from one mandatory live capture to 1-3 camera-or-gallery attachments.** Since a worker can be assigned to more than one project, each assignment card now has its own Start/End pill instead of a single shared button below a picker; starting one shift dims and disables every other card. `shifts.clock_out_photo_url` was replaced by a `shift_photos` table (`V4__add_shift_photos.sql`, up to 3 photos per shift, existing photos backfilled), and `POST /api/shifts/{id}/clock-out` now takes 1-3 `photos` parts instead of exactly one `photo`. Every photo is resized/recompressed at selection time (not after) so multiple attachments stay light on storage. The dashboard's Worker Detail photo column now shows a row of thumbnails per shift instead of one.
- **`employee_app` ran and was login-verified on the iOS Simulator for the first time**, previously blocked by two silent-failure gaps: iOS's App Transport Security rejecting plain-HTTP `localhost` calls with no visible error (fixed with an `NSExceptionDomains` entry in `ios/Runner/Info.plist`), and a missing `NSPhotoLibraryUsageDescription` (needed once clock-out could pick photos from the gallery, not just the camera). `API_BASE_URL` in `.env` is platform-specific and not auto-switched — `http://10.0.2.2:8080` for the Android emulator, `http://localhost:8080` for iOS Simulator — see `agents.md` for the full detail.
- **Reports was upgraded from a single-worker month/quarter/year picker into a full hours dashboard**: a custom date-range option alongside the existing presets, an optional (rather than required) worker filter, and three bar charts — hours by worker, by project, and by site — hand-rolled in HTML/CSS rather than a new charting dependency. A shift only ever carries a site, not a project, so project attribution is a best-effort join through assignments; when a worker has more than one project at the same site, those hours are honestly bucketed as "(multiple projects)" rather than guessed. Backend gained `GET /api/owner/assignments` (every assignment across every worker) to support this. See `agents.md` for the full detail.
- **The owner dashboard was reskinned to "Blueprint"** — a deep-cobalt, sharp-cornered, dense visual identity meant to read as credible against Zoho/Microsoft Dynamics rather than a demo app. Three directions were pitched as a single interactive mockup (a live theme switcher over the app's real nav and data) before picking one, rather than committing code to a direction first. The nav moved from a top tab bar to a fixed left sidebar; every color in `index.css` became a token (no more one-off hex values); the Home screen's four gradient tiles became flat single-accent cards. See `agents.md` for the full detail.
- **Home became a real dashboard**, rebuilt against live data from the layout the owner liked in the Blueprint mockup: clickable KPI tiles, a recent-activity feed (derived from this month's shifts — a live pulse for anyone currently clocked in), an hours-by-site chart (reusing Reports' bar chart component), and a sites overview. The mockup's search box and fabricated "1 on leave" status were deliberately left out — neither has a real feature behind it yet. `formatHours`/`hoursOf`/`aggregateHours` moved into a shared `src/lib/hours.js` so Home and Reports can't drift on the math. See `agents.md` for the full detail.
- **Clock-out photos moved from local disk into the database, with a daily retention job.** Prompted by a question about long-term storage cost — the actual numbers turned out modest (~1GB/3yr projected at 20 workers), but there was no backup and no cleanup mechanism at all, which was the bigger real risk. Photos are now `bytea` rows in `shift_photos`, served back out through a small `PhotoController`, and automatically deleted once their shift is more than `PHOTO_RETENTION_DAYS` (default 30) past clock-out. Neither frontend needed a code change — both already treated the photo field as an opaque URL string. See `agents.md` for the full detail.
- **The backend and dashboard are now actually deployed**, both on Render (see [`DEPLOYMENT.md`](DEPLOYMENT.md)): the backend as a Docker web service, the dashboard as a static site sharing the same `render.yaml` Blueprint — no second hosting provider needed, since Render's free static sites don't have the cold-start penalty free web services do. This repo also moved to its own owner's GitHub account partway through (the original was owned by a different account, and GitHub App installs like Render's can only be authorized by the resource owner). `employee_app`'s `.env` now points at the live Render backend and was verified end-to-end on a fresh Android emulator boot. See `agents.md` for the full blow-by-blow, including three real deploy bugs hit and fixed (a blank `JWT_SECRET` field, a static-site publish-path resolved relative to the wrong directory, and a Supabase connection-pooler exhaustion caused by local dev competing with the live deploy for the same limited pool).

See [`FUTURE_UPGRADES.md`](FUTURE_UPGRADES.md) for a running list of features not built yet (notifications, GPS clock-in verification, payroll export, scheduling from availability, and more) — kept separate from this file since none of it is scheduled or scoped.
