# Sunshine PI Desk

A simple proforma invoice generator. Fill in seller/buyer details and line items on the left, see a print-ready invoice preview on the right, and click **Print / Save PDF** to export. Works on desktop and phone. No backend, no build step — just one HTML file.

## Deploy it (GitHub + Vercel)

### 1. Push to GitHub
```bash
cd sunshine-pi-desk
git init
git add .
git commit -m "Sunshine PI Desk"
git branch -M main
git remote add origin https://github.com/<your-username>/sunshine-pi-desk.git
git push -u origin main
```
(Create the empty repo on github.com first — no README/license, since you already have files locally.)

### 2. Import into Vercel
1. Go to vercel.com → **Add New… → Project**.
2. Select the `sunshine-pi-desk` GitHub repo.
3. Framework preset: **Other** (it's a static site — no build command needed, leave Build Command / Output Directory blank).
4. Click **Deploy**.

Vercel gives you a live URL like `sunshine-pi-desk.vercel.app` — open it on your phone or computer, it's fully responsive. Every future `git push` to `main` auto-redeploys.

## Using it
- Data auto-saves to your browser (localStorage) as you type, so refreshing won't lose your work.
- **Reset** clears everything and starts a fresh invoice.
- On phone, use the **Edit / Preview** toggle at the top to switch views.
- **Print / Save PDF** opens your browser's print dialog — choose "Save as PDF" as the destination to download it.
