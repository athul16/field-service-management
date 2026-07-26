# Field Service Platform

A lightweight field service operations platform for owners who manage projects and remote, mostly part-time, non-technical workers. The platform gives owners real-time visibility into clock-in/clock-out activity, project progress, and worker availability.

## What this is

Two connected pieces:

1. **Employee mobile app** (this repo's `employee_app/`) — a simple Flutter app (Android + iOS) workers use to self-register, clock in/out at a work site, mark availability, and view their timesheet.
2. **Owner web dashboard** (`owner_dashboard/`, coming next phase) — a website where the owner creates projects, assigns available workers, and monitors progress and clock-in history per worker.

Both are backed by a shared **Supabase** project (Postgres database, auth, and file storage for clock-out photos), so data syncs between the app and dashboard in real time.

## Repository structure

```
field-service-platform/
├── agents.md                # Ground rules for AI coding agents working in this repo
├── employee_app/             # Flutter mobile app (workers)
│   └── lib/
│       ├── core/             # App-wide config, theme, routing
│       ├── models/           # Data models (Worker, Project, Site, Shift, Availability)
│       ├── services/         # Supabase-backed services (auth, clock, availability, timesheet)
│       └── features/         # Screens, grouped by feature
├── owner_dashboard/           # Owner-facing website (to be built)
└── supabase/
    └── migrations/            # SQL schema & row-level security policies
```

## Features (from project spec)

### Employee side (mobile app)
- Self-registration with name + phone (required), email (optional)
- Clock in/out, tied to a selected work site; clock-out requires a progress photo
- Simple drag-to-select availability calendar for upcoming weeks
- Weekly timesheet view of hours completed

### Owner side (web dashboard — next phase)
- Create projects with location and timeline
- Open a project to see all sites, assign available workers, and notify them (push/email/SMS)
- View completed/in-progress status per worker per site
- Drill into any worker to see their full clock-in/out history, including photos

## Tech stack

| Layer | Choice |
|---|---|
| Mobile app | Flutter (single codebase, Android + iOS) |
| Backend | Supabase (Postgres, Auth, Storage, Realtime) |
| Owner dashboard | TBD — planned as a web app reading from the same Supabase project |

## Getting started (employee app)

See [`employee_app/README.md`](employee_app/README.md) for setup, environment variables, and how to run the app locally.

## Backend

See [`supabase/migrations`](supabase/migrations) for the current database schema. Apply migrations with the Supabase CLI:

```bash
supabase link --project-ref <your-project-ref>
supabase db push
```

## Status

🚧 Early build. Employee app scaffold and initial database schema are in progress. Owner dashboard has not been started yet.
