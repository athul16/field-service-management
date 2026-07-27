# Field Service Platform

A lightweight field service operations platform for owners who manage projects and remote, mostly part-time, non-technical workers. The platform gives owners real-time visibility into clock-in/clock-out activity, project progress, and worker availability.

## What this is

Three connected pieces:

1. **Backend API** (`backend/`) — a Java Spring Boot REST API that owns **all** business logic, database access, authentication, and photo storage. Nothing else in this repo talks to the database directly.
2. **Employee mobile app** (`employee_app/`) — a simple Flutter app (Android + iOS) workers use to log in with a phone number + PIN (issued by the owner), clock in/out at a work site, mark availability, and view their timesheet. There is no self-registration. It's a thin UI client of the backend API — it holds no database or auth credentials itself, only a session token.
3. **Owner web dashboard** (`owner_dashboard/`, coming next phase) — a website where the owner creates projects and sites, onboards workers (creating their account and PIN, and assigning them to a site), and monitors progress and clock-in history per worker. It will call the same backend API the employee app already uses.

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
├── owner_dashboard/            # Owner-facing website (to be built, against backend/'s API)
└── supabase/                   # Historical — describes the schema before the backend migration;
    └── migrations/             # backend/.../db/migration/ is the current source of truth now
```

## Features (from project spec)

### Employee side (mobile app)
- Log in with phone number + PIN — no self-registration; the owner creates the account and issues the PIN
- **Shift screen** (formerly "Attendance", formerly "Clock In/Out"): Start Shift / End Shift, tied to a selected work site; ending a shift requires a progress photo. The backend verifies the worker is actually assigned to a site before allowing a shift to start, and that a shift belongs to the requesting worker before allowing it to end. A worker can tap a selected site again to deselect it, and can start a new shift at a different assigned site immediately after ending one elsewhere (sequential multi-site work — a worker just can't be clocked in at two sites *at once*). The active-shift card shows which site/project it's for, not just the elapsed time. The screen itself is designed for non-technical, low-literacy workers: work sites are picked from large tappable cards (a colored icon per site, not a text dropdown — the same site always gets the same color) instead of a list, and Start Shift / End Shift are big full-width green/red buttons (🟢 Start Shift / 🔴 End Shift) rather than small text buttons
- A worker only ever sees the project(s)/site(s) they've been assigned to
- **Availability**: tap any day on the calendar to mark it fully available (turns green) or tap again to un-mark it — no time-of-day, no separate save step, changes sync immediately. A "Clear All" button (with a confirmation prompt) wipes every marked day at once
- **Timesheet**: toggle between Week and Month views of completed hours, each with a total for the period and its own quick-jump picker (tap the "Week of M/D" or "Month Year" label to pick any of the last 12 weeks/months directly, instead of only stepping one at a time via the arrows)

### Owner side (web dashboard — next phase)
- Create projects with location and timeline
- Open a project to see all sites, assign available workers, and notify them (push/email/SMS)
- **Employee onboarding**: create a worker's account (name, phone), assign them to a project/site, and issue their initial login PIN — shown once so the owner can share it with the worker directly (in person, by message, etc.)
- Reset a worker's PIN at any time if they forget it
- View completed/in-progress status per worker per site
- Drill into any worker to see their full clock-in/out history, including photos

**All of the above already exist as backend REST endpoints** (`/api/owner/workers`, `/api/owner/projects`, `/api/owner/projects/{id}/sites`, `/api/owner/assignments`, `/api/owner/shifts`) — building the dashboard is now purely a frontend exercise against an already-working, already-tested API.

## Tech stack

| Layer | Choice |
|---|---|
| Mobile app | Flutter (single codebase, Android + iOS) |
| Backend | Java 21, Spring Boot (Web, JDBC, Security), plain `NamedParameterJdbcTemplate` (no ORM), Flyway, JWT (jjwt) |
| Database | Postgres (currently Supabase-hosted, accessed via plain JDBC — no Supabase client features in use) |
| Owner dashboard | TBD — will call the backend's REST API, same as the mobile app |

## Getting started

### Backend
1. Copy `backend/.env.example` to `backend/.env` and fill in the database connection details (from your Postgres host's connection-pooling info, not a direct/IPv6-only connection if applicable) and a JWT secret.
2. Run: `set -a && source backend/.env && set +a && mvn -f backend spring-boot:run`
3. Confirm it's up: `curl http://localhost:8080/api/ping` → `{"status":"ok"}`

See [`agents.md`](agents.md)'s Environment notes for connection-pooler gotchas if the database is Supabase-hosted.

### Employee app
See [`employee_app/README.md`](employee_app/README.md) for setup and how to run the app locally. Set `API_BASE_URL` in `employee_app/.env` to the backend's address (`http://10.0.2.2:8080` from the Android emulator, `http://localhost:8080` from iOS Simulator).

## Status

🚧 Early build, but the hard architectural work is done. The full migration away from Supabase's client SDK (Auth, Storage, PostgREST, RLS) to a self-owned Java backend is complete and verified end-to-end on the Android emulator: login, clock-in (with site-assignment verification), clock-out (with photo upload), availability, and the weekly timesheet all work against the real backend. The owner-side REST endpoints exist and are tested but have no UI yet — `owner_dashboard/` is still just a README describing what to build.

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
