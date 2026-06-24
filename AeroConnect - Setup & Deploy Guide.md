# AeroConnect — Setup & Deploy Guide

This turns the AeroConnect HTML file into a real multi-user app: students log in on their own laptops, pilots and owners see each other, and everything stays in sync through a shared cloud database (Supabase). Total time: ~20–30 minutes, all on free tiers.

You'll do four things: **(1)** create a Supabase project, **(2)** run the database script, **(3)** paste two keys into the HTML, **(4)** deploy to a shared link.

---

## Part 1 — Create the Supabase project (5 min)

1. Go to **supabase.com** and sign up (free).
2. Click **New project**. Give it a name (e.g. `aeroconnect`), set a database password (save it somewhere), pick the nearest region, and create it. Wait ~2 minutes for it to finish provisioning.

## Part 2 — Set up the database (3 min)

1. In your project, open **SQL Editor** (left sidebar) → **New query**.
2. Open the file **`supabase-schema.sql`** (included alongside this guide), copy everything, paste it into the editor, and click **Run**.
3. You should see "Success. No rows returned." That created the three tables (profiles, requests, connections), the security rules, and turned on real-time sync.

## Part 3 — Turn off email confirmation (1 min)

So students can sign up and use the app immediately without checking email:

1. Go to **Authentication** → **Providers** → **Email**.
2. Turn **OFF** "Confirm email" (toggle it off / disable it). Save.

> If you skip this, new sign-ups will be stuck waiting for a confirmation email and the app will tell them so.

## Part 4 — Get your two keys and paste them in (3 min)

1. Go to **Project Settings** (gear icon) → **API**.
2. Copy two values:
   - **Project URL** (looks like `https://abcdxyz.supabase.co`)
   - **anon public** key (a long string under "Project API keys")
3. Open **`AeroConnect.html`** in a text editor. Near the top of the `<script>` section you'll see:

   ```js
   const SUPABASE_URL = "PASTE_YOUR_SUPABASE_URL_HERE";
   const SUPABASE_ANON_KEY = "PASTE_YOUR_SUPABASE_ANON_KEY_HERE";
   ```

4. Replace the two placeholders with your Project URL and anon key. Save the file.

> The anon key is safe to put in front-end code — that's what it's designed for. Your data is protected by the security rules (Row Level Security) the SQL script set up. **Do not** use the `service_role` key here.

---

## Part 5 — Deploy to one shared link (5 min)

Easiest option, no account-juggling: **Netlify Drop**.

1. Go to **app.netlify.com/drop**.
2. Drag your saved **`AeroConnect.html`** file (rename it to `index.html` first so it loads as the homepage) onto the page.
3. Netlify gives you a public URL like `https://random-name.netlify.app`. That's your shared link — send it to every student.

Alternatives if you prefer: **Vercel**, **GitHub Pages**, or **Cloudflare Pages** all host a single HTML file for free. Any of them works because the app talks to Supabase directly from the browser.

> To update the app later, just re-drag the new file (Netlify) or push the change. Everyone gets the update on refresh.

---

## Part 6 — Test it (5 min)

1. Open the link on **two** browsers (or two laptops).
2. On the first: **Create an account** as a **Pilot** — set ratings (e.g. C172, SR22), a range, and an availability window that includes a near-future date.
3. On the second: **Create an account** as an **Aircraft Owner**.
4. As the owner, go to **Browse Pilots** — you should see the pilot you just made appear live. Then **New Request**: pick the same aircraft, an airport near the pilot's home, and a date inside their availability window. Submit.
5. On the **Matches** page, the pilot should show ✓ Qualified. Click **Connect with pilot**.
6. Switch to the pilot's browser — a **Requests** badge appears. Open it, **Accept** the trip.
7. Back on the owner's screen, the match flips to "✓ Pilot accepted — trip confirmed." The trip shows on both dashboards and calendars.

If all that works, you're synced and live across machines.

---

## How the pieces fit (for teaching)

- **profiles** — every user (owner or pilot). Pilots store their ratings, range, and availability. This *is* the live pilot directory owners browse.
- **requests** — a trip an owner needs a pilot for.
- **connections** — the handshake: an owner reaches out to a qualified pilot; the pilot accepts or declines. This is the two-sided engagement.
- **Matching** still happens in the browser (rating + availability + range), but now runs against *real* pilots from the database instead of a hardcoded list.
- **Real-time** means when any laptop writes a row, the others refresh automatically — that's the "in sync" behavior.

## Troubleshooting

- **"Backend not configured" banner** — the two keys aren't pasted in (or the URL doesn't start with `https`).
- **Sign-up says email confirmation is ON** — finish Part 3.
- **Pilot doesn't appear for the owner** — make sure the pilot finished sign-up (got into the app); check the **Table Editor → profiles** in Supabase to confirm the row exists.
- **Pilot qualifies but range fails** — the airport code isn't in the built-in coordinate list. Unlisted airports are treated as "eligible" with a note, so this shouldn't block; if you want exact distances for a specific airport, add its lat/long to the `AIRPORTS` object in the script.
- **Nothing syncs live** — confirm the three `alter publication` lines ran (they're in the SQL script) and that you didn't block the Supabase domain on the school network.
