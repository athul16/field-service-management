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
- **SQL migrations**: one numbered file per change (`0002_description.sql`), never edit a previously-committed migration.
- **Naming**: `snake_case` for SQL and file names, `lowerCamelCase` for Dart variables/methods, `UpperCamelCase` for Dart classes.
- Keep the employee app screens simple and large-tap-target — the target users are non-technical and often on small phones in the field.

## Before committing

- Confirm no secrets are staged (`git diff --cached` should contain no keys/tokens).
- Keep commits scoped to one logical change with a clear message.

## Status as of 2026-07-26

Verified end-to-end on the Android emulator against the live Supabase project (ref `yxmhetcdpenugdoczonc`): registration, login (via Supabase's Test Phone Numbers/OTP dashboard feature — Twilio itself has no real credentials configured yet), and clock-in against a seeded site all work. Clock-out (photo capture), the availability calendar, and the timesheet screen have not yet been exercised end-to-end.

Two real bugs were found and fixed this session, both worth knowing about before assuming the app "just works":

- **`0001_init_schema.sql` enabled RLS and added policies but never issued the underlying table GRANTs.** This project's default privileges for new tables are revoked for `anon`/`authenticated`, so every PostgREST query failed with `permission denied for table X` before RLS was even evaluated — this broke every screen, not just one. Fixed in `0002_grant_authenticated_table_privileges.sql`; any new table added later needs an explicit `grant select, insert, update, delete on <table> to authenticated;` (or it will silently break the same way).
- `AppTheme.light` in `employee_app/lib/core/theme.dart` used to call `TextTheme.apply(fontSizeFactor:)`, which crashes on launch if any style in the default Material3 `TextTheme` has a null `fontSize` (true on the Flutter version in use). Already fixed with a null-safe manual scaler — don't reintroduce the `.apply(fontSizeFactor:)` pattern.

### Next steps, in priority order

1. **Add missing indexes.** No foreign-key columns are indexed (Postgres doesn't auto-index FKs, only PKs). Needed on `assignments.worker_id`, `shifts.worker_id`, `sites.project_id`, `projects.owner_id`, `availability_slots.worker_id` — every RLS policy and "my X" query filters on these. Add as `0003_add_fk_indexes.sql`.
2. Verify the clock-out flow (photo capture + upload to the `shift-photos` storage bucket) end-to-end.
3. Verify the availability drag-select calendar writes to `availability_slots` correctly.
4. Verify the weekly timesheet screen reads from `shifts` correctly.
5. Repeat the full verification pass on iOS Simulator once Xcode is fully installed (only Command Line Tools were available as of this writing).
6. Decide + scaffold `owner_dashboard/` — tech stack is not yet chosen, ask the user rather than assuming.
7. Configure real Twilio credentials before any real deployment — Indian phone numbers additionally require TRAI DLT registration, which is separate from just adding Twilio credentials.

### Environment notes

- `employee_app/.env` is git-ignored but required by `pubspec.yaml` as a bundled asset — if it's missing, the build fails with `No file or variants found for asset: .env`. Copy `.env.example` and fill in the real `SUPABASE_URL`/`SUPABASE_ANON_KEY` (see Supabase dashboard → Project Settings → API).
- The Flutter platform folders (`android/`, `ios/`, `macos/`, `web/`) were generated via `flutter create .` — don't regenerate them, it risks overwriting configuration (like the camera permission entries already added to `ios/Runner/Info.plist` and `android/app/src/main/AndroidManifest.xml`).
