# Future Upgrades

A running list of features **not built yet** — kept separate from `README.md` (what exists today) and `agents.md` (rules for agents working in this repo) so it can be picked up independently if/when there's appetite to build any of it. Nothing here is scheduled; this is a menu, not a roadmap.

Each item below was verified against the actual code (not guessed) as of the Site/Project inversion + dashboard redesign work — see the file:line citations for where the gap actually is.

## Tier 1 — Quick wins (the data/hooks already half-exist)

### 1. Assignment notifications
`Assignment.notifiedAt` is a real, indexed column (`backend/src/main/java/com/fieldservice/backend/entity/Assignment.java`), read by `AssignmentRepository`, but **no service ever sets it** — there is no SMS/push/email sent when a worker is assigned to a new project.

**Use case**: an owner assigns Maria to a new HVAC job Monday morning. Today she only finds out if she happens to open the app. This is usually the single most-requested feature for any scheduling tool.

~~### 2. Clock-out photo review in the dashboard~~ — **shipped.** `WorkerDetailPage`'s "Completed tasks" table now shows a clickable photo thumbnail per shift, plus a Confirm action (`shifts.confirmed_at`/`confirmed_by`, `PATCH /api/owner/shifts/{id}/confirm`) so an owner can review and sign off on completed work. See `agents.md`'s Status section for the detail.

### 3. Edit/delete for Sites, Projects, Workers
Confirmed via the controllers: `OwnerSiteController` and `OwnerWorkerController` only have `POST`/`GET`; `OwnerProjectController` adds one `PATCH` (status only). No `PUT`/`DELETE` exists anywhere for these three resources.

**Use case**: an owner mistypes a site's address, or a project gets cancelled before it starts. Today the only fix is direct database surgery.

## Tier 2 — Bigger features clients will actually ask for

### 4. Turn Availability into a real schedule
Confirmed: `AvailabilityService` only supports list/add/delete for a worker's *own* slots. The only owner-facing read (`OwnerWorkerService.getAvailability`) is explicitly read-only — nothing in `AssignmentService` or `ShiftService` ever consumes availability data. It's a dead-end feed today.

**Use case**: an owner wants to look at next week's marked availability and actually build a schedule ("Tom is on-site Tue/Thu, Priya covers Wednesday") rather than assigning a worker to a project indefinitely and hoping they show up on the right days.

### 5. GPS / geofencing at clock-in
Confirmed: no location capture anywhere in the mobile app — no `geolocator` dependency in `employee_app/pubspec.yaml`, no lat/long sent from `clock_service.dart` on clock-in or clock-out. `Site` has static lat/long, but nothing checks a worker's actual position against it.

**Use case**: an owner wants proof a worker was physically at the site when they clocked in — prevents "buddy punching" and disputes over whether work happened on-site. One of the most common asks in field service specifically.

### 6. Payroll support
No wage/rate field exists anywhere on `Profile` or any DTO, and there's no CSV/PDF export endpoint anywhere in the backend. Reports today is an on-screen total only.

**Use case**: an owner needs to hand their bookkeeper a per-worker, per-pay-period hours file to actually run payroll — right now they'd have to hand-copy numbers off the Reports screen.

### 7. Reporting depth
Reports is worker-only, month/quarter/year, on-screen only. No by-site or by-project rollup, no overtime flag, no no-show/late detection.

**Use case**: an owner bills the end customer per site, so they need "how many hours went into the Bridgewater job this month," not just "how many hours did Maria work."

## Tier 3 — Platform maturity (matters once there's more than one owner / a few dozen workers)

### 8. A role between Owner and Worker (e.g. Supervisor/Dispatcher)
Today it's all-or-nothing — every dashboard action requires full `OWNER`-role auth. No intermediate permission tier exists.

### 9. Multi-tenancy
The schema/auth model assumes a single owner's data; there's no company/organization boundary if this platform ever needs to serve more than one business.

### 10. Offline support on the mobile app
Every clock-in/out is a live API call with no retry/queue. Field workers are often in poor-signal areas (basements, rural sites) — a failed clock-in today just fails silently or errors out with no recovery path.

### 11. Search / filter / pagination
Every list page (Sites, Projects, Workers, Assignments) loads everything unfiltered. Fine at today's scale; will need attention once a client has 50+ workers or projects.

### 12. Automated tests + CI
Already flagged in `agents.md`'s Known gaps. Worth repeating here since it's the thing that makes building any of the above safer.

### 13. Move the database closer to where it's actually used
Confirmed via direct measurement: every DB-touching API call pays a ~300-600ms+ network round-trip tax just from the physical distance between wherever this backend runs and the Supabase pooler's region (`ap-south-1`/Mumbai), on top of whatever the query itself costs. The connection-pool sizing fix (see `agents.md`'s Environment notes) removes the *queuing* penalty on pages with several concurrent requests, but it can't remove this base distance tax — no code change can.

**Use case**: once this is used somewhere other than this dev machine (a real deployment, or just a developer/office in a different region), every dashboard page load and every mobile clock-in/out pays this same tax. Fixing it for real means hosting the Postgres database in a region close to wherever the backend/users actually are — a hosting decision, not a code change, and worth deciding deliberately rather than discovering by accident when it starts feeling slow again.

---

*How to use this file*: if you decide to build one of these, pull it out of here into an actual plan (Plan Mode, a proper implementation plan file, whatever fits at the time) — don't just start coding off this list directly, since none of these have been scoped down to concrete file-level changes yet the way the shipped features in `README.md`/`agents.md` have.
