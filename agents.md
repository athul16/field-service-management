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
