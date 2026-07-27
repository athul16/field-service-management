# supabase/ — historical only

This directory is **no longer the source of truth** for the database schema. It documents how the schema reached its state before the project migrated off Supabase's client SDK (Auth, Storage, PostgREST, RLS) onto a self-owned Java Spring Boot backend (`backend/`).

- **`migrations/`** — the schema's history up through that migration. Left as-is (per the project convention of never editing an already-applied migration) rather than deleted.
- **`seed.sql`** — describes how this environment's original test data was created, back when accounts were made through the Supabase dashboard.

**The current source of truth is [`backend/src/main/resources/db/migration/`](../backend/src/main/resources/db/migration)**, starting with `V1__migrate_from_supabase.sql`, which transforms the schema described here into the one the backend now owns (drops the `auth.users` foreign key, RLS policies, and Supabase-specific functions; adds a few constraints/indexes). See `agents.md` for the full rationale.

The Postgres database itself is still physically hosted on Supabase — only its client-facing features have been dropped. New test data should go through the backend's own `/api/owner/**` endpoints or its bootstrap-owner `CommandLineRunner`, not manual SQL against these historical files.
