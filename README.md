# Sunshine PI Desk

A Proforma Invoice tool for **Sunshine Cosmetic Pvt. Ltd.** and **Sunshine Industries**, with real per-person login: everyone gets their own account, and **each person can only ever see and open PIs they created themselves** — enforced by the database, not just hidden in the browser.

## The pages

1. **`login.html`** — Sign up (name + email + password) or log in. This is the front door — every other page redirects here if you're not signed in.
2. **`index.html` — New PI.** Pick the selling company, enter the client's details, items, and terms. "Created by" is no longer a dropdown — it's automatically your account's name.
3. **`preview.html` — Result.** The generated Proforma Invoice, with the real header/footer artwork for whichever company was selected. Print/Save-as-PDF button.
4. **`log.html` — Log.** Every PI **you've** created — nobody else's ever appears here, even by direct link.
5. **`account.html`** — See your name/email, and change your password (always asks for your current password first).

## How the security actually works now

Previously, "locking" a PI was a passcode checked in the browser — someone with dev tools could bypass it. This version is different: PIs live in a real database (Supabase/Postgres), protected by a **Row Level Security** policy that says *"you may only ever see rows where `user_id` matches your own logged-in account."* That check happens on the server, every time, for every request — there is no client-side code path that can see around it. If you're not logged in as the person who created a PI, the database simply won't return it — Sunshine PI Desk shows "No PI found," not because it's hidden, but because it genuinely isn't sent to you.

## One-time setup (you only do this once)

### 1. Create a free Supabase project
1. Go to **supabase.com** → sign up → **New project**.
2. Pick a name and a database password (save that password somewhere safe), choose a region close to you, and create the project. It takes a minute or two to provision.

### 2. Create the database table
1. In your new project, open **SQL Editor** (left sidebar) → **New query**.
2. Open `supabase-setup.sql` (included in this folder), copy all of it, paste it into the editor, and click **Run**.
3. This creates the `pis` table and the Row Level Security policy described above.

### 3. (Recommended) Turn off email confirmation, for a smoother first login
By default Supabase emails a confirmation link on signup. For an internal team tool this is usually unnecessary friction:
1. Go to **Authentication → Providers → Email**.
2. Turn off **"Confirm email"**.
3. Save.

(If you'd rather keep email confirmation on, that's fine too — people will just need to click the link in their inbox once after signing up, before they can log in.)

### 4. Connect the site to your project
1. In Supabase, go to **Project Settings → API**.
2. Copy the **Project URL** and the **anon public** key.
3. Open `supabase-config.js` in this folder and paste them in:
   ```js
   const SUPABASE_URL = 'https://xxxxxxxx.supabase.co';
   const SUPABASE_ANON_KEY = 'eyJhbGciOi...(long string)';
   ```
4. Save the file.

These two values are meant to be public (every visitor's browser needs them) — they are **not** secret. The real protection is the Row Level Security policy from step 2, not these keys.

### 5. Deploy (same as before)
```bash
cd sunshine-pi-desk
git init
git add .
git commit -m "Sunshine PI Desk with login"
git branch -M main
git remote add origin https://github.com/<your-username>/sunshine-pi-desk.git
git push -u origin main
```
Then on vercel.com: **Add New… → Project → import the repo → Framework preset: Other** → **Deploy**.

### 6. Create your team's accounts
Open your live site → it'll land on the login page → click **"Need an account? Sign up"** → each person enters their name, email, and a password. That's their permanent login from then on.

## Files
```
login.html            Sign up / log in
index.html             New PI form
preview.html           Result / generated invoice
log.html                Your PI log
account.html           Account info + change password
style.css                Shared styling incl. both company letterhead themes
app.js                    Shared logic: Supabase client, auth, data, formatting
supabase-config.js   Your project's URL + key (fill in once, see setup above)
supabase-setup.sql   Database schema — run this once in Supabase's SQL Editor
images/                  Real header/footer artwork from each company's Word letterhead
```

## A note on going from the old version
If you were using the earlier localStorage-based version, that data lived only in each person's browser and does **not** carry over automatically — this version starts with an empty database. Old PIs that matter can simply be re-created once everyone has an account.
