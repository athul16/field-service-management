# Employee App

Flutter mobile app (Android + iOS) for field workers: self-registration, clock in/out with a required progress photo, availability calendar, and a weekly timesheet.

## Prerequisites

- Flutter SDK 3.3+ (`flutter --version`)
- A Supabase project (see `../supabase/migrations` for the schema to apply)
- An SMS provider configured in Supabase (Authentication → Providers → Phone) for OTP login — e.g. Twilio

## Setup

```bash
cd employee_app
flutter pub get
cp .env.example .env
# then edit .env with your Supabase project URL + anon key
```

## Supabase storage bucket

Clock-out photos are uploaded to a bucket named `shift-photos`. Create it in the Supabase dashboard (Storage → New bucket) and make it public-read, or adjust `ClockService` to use signed URLs if you'd rather keep it private.

## Run

```bash
flutter run
```

## Structure

```
lib/
├── main.dart              # entry point
├── app.dart                # MaterialApp + auth gate (login vs. home)
├── core/                   # theme, Supabase init
├── models/                 # Worker, Site, Shift, AvailabilitySlot
├── services/                # Supabase-backed data layer (screens never call Supabase directly)
└── features/
    ├── auth/                # register_screen.dart, login_screen.dart
    ├── home/                 # bottom-nav shell
    ├── clock/                 # clock in/out + photo capture
    ├── availability/          # drag-select calendar
    └── timesheet/              # weekly hours
```

## Notes / next steps

- Registration/login use Supabase phone OTP. If you'd rather not set up an SMS provider yet, swap `AuthService` to email+password for local testing.
- Worker "license verification" was explicitly deferred per the project spec — not implemented yet.
- Push notifications for new assignments aren't wired up yet; the owner dashboard side will need to trigger those (email/SMS/push).
