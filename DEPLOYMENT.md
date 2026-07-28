# Deploying a free demo/trial environment

For showing this to a prospective client and giving them limited-time access to try it — not a
production deployment. Everything below is free at this scale; the tradeoffs that come with "free"
are called out explicitly rather than glossed over.

## Order of operations (matters — there's a circular dependency)

The backend needs to know the dashboard's URL (for CORS) and the dashboard needs to know the
backend's URL (to call the API). Deploy backend first, get its URL, deploy the dashboard with that
URL, then go back and update the backend's CORS setting with the dashboard's final URL.

Both services live under one Render account/Blueprint (`render.yaml`) — no second hosting provider
needed. Render's free Static Sites have no cold-start/spin-down penalty (that only applies to free
*Web Services*, i.e. the backend), so this is simpler than a two-provider (Render + Vercel) split
without giving up anything this use case needs.

## 1. Backend → Render

This repo already has a GitHub remote connected. On [render.com](https://render.com):

1. Sign up / log in, **New → Blueprint**, connect this GitHub repo.
2. Render reads `render.yaml` at the repo root automatically and proposes two services: the
   `field-service-backend` web service (Docker-based, free plan) and the `field-service-dashboard`
   static site (see step 2 below) — both from the same Blueprint sync.
3. It will prompt for the env vars marked secret in `render.yaml` — fill these in from
   `backend/.env` (**do not commit that file** — copy the values by hand into Render's dashboard):
   `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, `JWT_SECRET`, `BOOTSTRAP_OWNER_PHONE`,
   `BOOTSTRAP_OWNER_PIN`, `CORS_ALLOWED_ORIGINS` (leave this as `http://localhost:5173` for now —
   you'll update it in step 3 below).
4. Deploy. First build takes a few minutes (Docker build from scratch). Note the resulting URL —
   something like `https://field-service-backend.onrender.com`.
5. Confirm it's actually up: `curl https://<your-render-url>/api/ping` → `{"status":"ok"}`.

**The real tradeoff of the free plan**: the backend web service spins down after 15 minutes of no
traffic, and the next request pays a ~30-60 second cold-start cost. For a live demo call, **hit that
`/api/ping` URL yourself 5 minutes before you start** so the client never sees the cold start. This
does not affect the dashboard — free Static Sites stay always-on.

## 2. Owner dashboard → Render (Static Site)

`render.yaml` already defines `field-service-dashboard` as a static site (`runtime: static`, root
`owner_dashboard`, build `npm install && npm run build`, publish path `dist`), with a rewrite route
(`/* → /index.html`) so client-side routing (React Router) doesn't 404 on refresh — same job
`vercel.json` used to do, just expressed in `render.yaml` instead. Note: `staticPublishPath` is
relative to `rootDir` once `rootDir` is set (not the repo root) — this tripped up the first deploy,
which used `owner_dashboard/dist` and got `Publish directory owner_dashboard/dist does not exist!`
right after a successful build. `VITE_API_BASE_URL` is already set in the Blueprint to the backend's
Render URL, so nothing to fill in by hand here. If the Blueprint sync doesn't pick up this service
automatically, trigger it manually from the Blueprint's "Manual sync" button. Note the resulting
URL — something like `https://field-service-dashboard.onrender.com`.

## 3. Close the loop: update CORS on Render

Back in the backend service's Environment tab, edit `CORS_ALLOWED_ORIGINS` to the dashboard's Render
URL from step 2 (comma-separate if you also want `localhost:5173` for your own local testing against
the deployed backend). Redeploy. Without this, the dashboard's API calls will fail with a CORS error
in the browser console — the symptom is requests that look fine in the Network tab status-wise but
the browser blocks the response.

## 4. Android app → Firebase App Distribution (free, "a few users")

This gets a signed build in front of specific people by email, no Play Store review, no $25 Play
Developer fee (that's only needed for Play Store listing, not for App Distribution).

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
   (free — this is a Google account action only you can do).
2. Add an Android app to it with this app's package name (check
   `employee_app/android/app/build.gradle`'s `applicationId`).
3. Build a release APK: `flutter build apk --release` — set `API_BASE_URL` in `employee_app/.env`
   to the **Render backend URL** first (a full rebuild is required for `.env` changes to take
   effect; hot-reload won't pick it up).
4. Install the Firebase CLI (`npm install -g firebase-tools`), `firebase login`, then:
   `firebase appdistribution:distribute build/app/outputs/flutter-apk/app-release.apk --app <firebase-app-id> --groups "testers"`
5. Add testers by email in the Firebase console — they get an email with an install link, no Play
   Store account needed on their end (just "allow installs from unknown sources" once, standard for
   any non-Play-Store Android install).

## 5. Trial access

No expiry mechanism is built — by design, at this scale. Create the prospective client's owner
account yourself (`POST /api/owner/workers` doesn't apply to owners — use the same bootstrap-owner
pattern, or ask them to use a worker-role demo account if that's what you're showing) and remove it
manually when the trial period ends. Revisit a coded `expires_at` field only if this becomes
frequent enough that manual cleanup is a real burden.

## Before every live demo

- Hit the Render `/api/ping` URL 5 minutes early to avoid the cold-start delay live on the call.
- Confirm the Supabase project isn't paused (free-tier Supabase projects can pause after a period of
  inactivity — check its dashboard if it's been a while since the last demo).
- **Stop any local dev backend before redeploying or demoing.** The Supabase connection pooler this
  app uses caps the whole project at 10 session-mode clients; the backend's Hikari pool alone holds
  5 warm connections per running instance. A local `mvn spring-boot:run` left running while Render
  redeploys can push the total over 10, and the deploy fails with
  `FATAL: (EMAXCONNSESSION) max clients reached in session mode` — a real failure this hit once, not
  a hypothetical.
