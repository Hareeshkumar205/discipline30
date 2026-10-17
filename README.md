# Discipline 30 — installable PWA

A mobile-first Progressive Web App for a 30-day shared habit challenge: gym/recovery, daily Bhagavad Gita reading, reflections, and partner accountability.

## Included

- Responsive interface for Android and iPhone
- Add-to-home-screen PWA manifest, app icon, and service worker cache
- 30-day progress dashboard and daily habit check-in
- Beginner-friendly weekly workout/recovery structure
- Daily Gita reading references with concise meaning summaries
- Local progress storage and JSON export
- Optional shared challenge using Supabase anonymous authentication and database functions
- Best-effort in-app browser reminder scheduling

## Important limits

- This is the app source, not a deployed public website. A PWA must be served over HTTPS (localhost is fine for local development). You need to deploy it to a static host before installing on your phones.
- Shared cloud sync is optional until you configure a Supabase project and run `supabase_schema.sql`.
- The reminder scheduler uses browser notifications and timers. Mobile browsers can suspend timers when the app is closed; this is **not a guaranteed background notification service**. For dependable scheduled push notifications, add a push service/serverless scheduled job. For now, set a phone alarm as a reliable backup.
- Gita entries show verse references and concise meaning summaries, not the full Sanskrit text or a word-for-word translation. Use a trusted edition for exact shloka text.
- Local check-ins are stored in the browser on each device. Export them regularly. Clearing browser data may delete local progress.

## Easiest free deployment (GitHub Pages)

1. Create/sign in to a GitHub account.
2. Create a new repository, e.g. `discipline30`.
3. Upload all files from this folder to the repository root.
4. Open **Settings → Pages**. Choose deploy from branch, select `main` and `/ (root)`, then Save.
5. Wait for the published HTTPS URL. Open it on both phones.

Alternative static hosts with free tiers include Cloudflare Pages and Netlify. Free-tier terms can change.

## Install on Android

1. Open the HTTPS app URL in Chrome.
2. Choose **Install app** or browser menu → **Add to Home screen**.
3. Confirm installation. Launch it from the new home-screen icon.

## Install on iPhone

1. Open the HTTPS URL in **Safari** (not an in-app browser).
2. Tap **Share** → **Add to Home Screen**.
3. Enable **Open as Web App** if shown, then tap **Add**.
4. Launch from the home-screen icon.

iOS notification support varies by version and installation mode. Allow notifications if prompted; keep a regular iPhone alarm as backup.

## Set up free shared cloud sync with Supabase

1. Create a Supabase project on the free plan.
2. In Supabase, open **SQL Editor**, paste the full contents of `supabase_schema.sql`, and run it.
3. Open **Authentication → Providers / Sign In** and enable **Anonymous Sign-Ins**.
4. In project settings, find the Project URL and anon/publishable key.
5. Edit `config.js`:
   ```js
   window.DISCIPLINE30_CONFIG = {
     supabaseUrl: "https://YOUR-PROJECT.supabase.co",
     supabaseAnonKey: "YOUR-ANON-OR-PUBLISHABLE-KEY"
   };
   ```
   Never use a `service_role` key in browser code.
6. Commit the updated `config.js` and wait for your host to redeploy.
7. On your phone, open the app → **Together** → enter your display name → **Create room**.
8. Share the generated room code privately with your friend.
9. Your friend opens the same app URL → **Together** → enters their display name and room code → **Join room**.
10. Both users save their daily check-in. Partner progress is fetched from the shared cloud database.

### Cloud privacy notes

- Challenge progress is visible to members of that room. Do not put sensitive personal details in reflections.
- The room code is a join credential; share it only with your friend.
- The SQL functions enforce room membership for logs. Anonymous authentication means users are not verified by email and may lose identity if they clear app data or browser storage. For a production-grade app, use email sign-in and stronger account recovery.
- Review your Supabase project's current free-plan limits and privacy settings before storing data.

## Run locally for development

From this folder, run a static server, for example:

```bash
python3 -m http.server 8080
```

Then open `http://localhost:8080` on your computer. PWA install features work best on HTTPS or localhost. For mobile testing, deploy to an HTTPS host.

## Suggested next upgrades

- Exact Sanskrit shlokas from a chosen public-domain/trusted edition
- Real background push notifications
- Email-based accounts and account recovery
- Streak history, weekly charts, and a challenge-end report
- Optional reminders for each user in their local timezone
