# Employee App

Flutter mobile app (Android + iOS) for field workers: phone + PIN login (no self-registration — an
owner provisions the account), a Shift screen with a per-project Start/End toggle and a 1-3 photo
attachment on clock-out, an availability calendar, and a Week/Month timesheet. A thin UI client of
the Java Spring Boot `backend/` API — this app holds no database or auth credentials of its own,
only a JWT.

## Prerequisites

- Flutter SDK 3.3+ (`flutter --version`)
- The `backend/` API running locally (see the root `README.md`'s Backend section)
- A worker account to log in with — created by an owner via the `owner_dashboard`, or the bootstrap
  owner account itself (`backend/.env`'s `BOOTSTRAP_OWNER_*`)

## Setup

```bash
cd employee_app
flutter pub get
cp .env.example .env
# set API_BASE_URL to the backend's address — see the note below, it's platform-specific
```

**`API_BASE_URL` is platform-specific and not auto-switched**: `http://10.0.2.2:8080` for the
Android emulator (its alias for the host machine), `http://localhost:8080` for iOS Simulator.
Changing `.env` needs a full rebuild — hot-reload won't pick it up.

**iOS only**: local HTTP calls need an App Transport Security exception, already added to
`ios/Runner/Info.plist` (`NSExceptionDomains` → `localhost`). If you point this app at a different
local hostname, add that too.

## Run

```bash
flutter run
```

## Structure

```
lib/
├── main.dart              # entry point
├── app.dart                # MaterialApp + auth gate (login vs. home), theme
├── core/
│   ├── api_client.dart      # JWT-authenticated HTTP client — screens never call http directly
│   └── theme.dart
├── models/                 # Assignment, Shift, AvailabilitySlot, PhoneCountry
├── services/                # One thin wrapper per feature area over ApiClient
└── features/
    ├── auth/                 # login_screen.dart — phone + PIN, country-code selector from GET /api/config
    ├── home/                  # home_shell.dart — bottom-nav shell (Shift / Availability / Timesheet)
    ├── clock/                  # clock_screen.dart — per-project Start/End toggle, 1-3 photo attach on End
    ├── availability/           # full-day toggle calendar (tap to mark/un-mark, no time-of-day)
    └── timesheet/               # Week/Month views, quick-jump picker for either
```

## Notes / next steps

- Worker accounts are owner-provisioned only — there is no in-app registration screen. An owner
  creates a worker (name + phone) from `owner_dashboard`, which returns a generated PIN shown once.
- Worker "license verification" was explicitly deferred per the project spec — not implemented yet.
- Push notifications for new assignments aren't wired up yet.
