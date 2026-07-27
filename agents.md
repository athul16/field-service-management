# Agent Instructions — Field Service Platform

These rules apply to any AI coding agent (Claude, Claude Code, or otherwise) working in this repository.

## Scope

- **Stay inside this repository.** Do not read, write, or reference files outside this project folder (no home directory dotfiles, no other repos, no system config).
- Do not access, print, log, or commit credentials, API keys, tokens, or `.env` files. Supabase keys belong in local `.env` files that are git-ignored — never hard-code them in source.
- Do not run destructive git operations (force-push, history rewrite, branch deletion) without explicit confirmation from a human in the conversation.
- Do not modify files under `supabase/migrations/` that have already been applied to a shared environment — add a new migration instead of editing history.

## Project context

Field service operations platform for an owner managing remote, part-time, non-technical workers across multiple project sites.

- `employee_app/` — Flutter mobile app (Android + iOS) for workers: registration, clock in/out, availability, timesheet.
- `owner_dashboard/` — web dashboard for the owner (not yet started).
- `supabase/` — shared Postgres schema, auth, storage, and RLS policies used by both.

## Conventions

- **Flutter/Dart**: follow standard `flutter_lints` conventions. Keep screens in `lib/features/<feature>/`, shared data models in `lib/models/`, and all Supabase calls behind a `lib/services/` wrapper — screens should never call the Supabase client directly.
- **SQL migrations**: one numbered file per change (`0002_description.sql`), never edit a previously-committed migration. **RLS policies are not enough on their own** — this project's default privileges revoke `anon`/`authenticated` on new tables *and* new Storage buckets, so every new table needs an explicit `grant select, insert, update, delete on <table> to authenticated;` and every new Storage bucket needs its own `storage.objects` policy, or every query/upload against it will fail with a permission error before RLS is ever evaluated (see `0002` and `0003` for the pattern).
- **Naming**: `snake_case` for SQL and file names, `lowerCamelCase` for Dart variables/methods, `UpperCamelCase` for Dart classes.
- Keep the employee app screens simple and large-tap-target — the target users are non-technical and often on small phones in the field.
- **Timestamps**: always call `.toUtc()` on a `DateTime` before sending it to Supabase, and always call `.toLocal()` before reading `.hour`/`.minute`/`.day` off a `DateTime` that came back from a `timestamptz` column. Postgres reads an offset-less timestamp string as being in its own session timezone (effectively UTC), and Dart's `DateTime.parse()` does not auto-convert to local time — skipping either step silently shifts times by the device's UTC offset (this broke clock-out, the clock-in time display, and the timesheet query/display before being fixed).
- Any `Timer` (e.g. a periodic UI refresh) added to a `State` must be cancelled in `dispose()`.

## Before committing

- Confirm no secrets are staged (`git diff --cached` should contain no keys/tokens).
- Keep commits scoped to one logical change with a clear message.

## Environment notes

- `employee_app/.env` is git-ignored but required by `pubspec.yaml` as a bundled asset — if it's missing, the build fails with `No file or variants found for asset: .env`. Copy `.env.example` and fill in the real `SUPABASE_URL`/`SUPABASE_ANON_KEY` (see Supabase dashboard → Project Settings → API). Some newer Supabase dashboards label this the **"Publishable key"** instead of "anon key" — same value/purpose, just renamed.
- `.env` changes need a full `flutter build apk` (or equivalent) + reinstall to take effect — it's a bundled asset, not something hot-reload/hot-restart reliably refreshes.
- The Flutter platform folders (`android/`, `ios/`, `macos/`, `web/`) were generated via `flutter create .` — don't regenerate them, it risks overwriting configuration (like the camera permission entries already added to `ios/Runner/Info.plist` and `android/app/src/main/AndroidManifest.xml`).
- On the Android emulator, if the CAMERA permission was granted as "Only this time," Android kills the app process the moment the system camera activity hands control back — mid clock-out flow, this looks like the app just vanished. `adb shell pm grant <package> android.permission.CAMERA` grants it persistently for testing.
- The `assignments` table is never populated automatically — there's no owner dashboard yet to do it. New workers will see "no assigned sites" (or clock-in will silently have nothing to pick) until a project/site/assignment row is seeded manually, e.g. via `supabase/seed.sql` or an ad hoc SQL Editor script. When writing that SQL, check **Authentication → Users** in the dashboard for the exact stored `phone` value first — it may be normalized to E.164 (e.g. `+1...`) even if the worker typed digits only.

## Status

Last verified end-to-end on the Android emulator against the live Supabase project (ref `yxmhetcdpenugdoczonc`): registration, login (Supabase Test Phone Numbers/OTP — Twilio has no real credentials configured yet), clock-in, and clock-out (photo capture) all work. The availability calendar hasn't been exercised end-to-end. The timesheet screen's query/display logic has been fixed (see the Timestamps rule above) but not yet visually verified in the running app.

Bug history (what broke and why) lives in the migration files themselves (`0001`–`0003`) rather than here — check their header comments before assuming a fixed issue might have regressed.

## Known gaps / next up

- **Add missing indexes**: no foreign-key columns are indexed (Postgres doesn't auto-index FKs, only PKs) — needed on `assignments.worker_id`, `shifts.worker_id`, `sites.project_id`, `projects.owner_id`, `availability_slots.worker_id`, since every RLS policy and "my X" query filters on these. Add as the next numbered migration.
- Visually verify the weekly timesheet screen in the running app.
- Verify the availability drag-select calendar writes to `availability_slots` correctly — check it against the Timestamps rule above before assuming it's fine.
- Repeat the full verification pass on iOS Simulator once Xcode is fully installed (only Command Line Tools were available as of this writing).
- Decide + scaffold `owner_dashboard/` — tech stack is not yet chosen, ask the user rather than assuming.
- Add the `shifts_clock_out_after_clock_in` check constraint as a proper migration — it's live in the database but was never captured in one, so a fresh environment won't have it.
- Configure real Twilio credentials before any real deployment — Indian phone numbers additionally require TRAI DLT registration, separate from just adding Twilio credentials.
