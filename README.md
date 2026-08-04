# Artwork Compliance Checker — Standalone App

A web app that checks packaging artwork PDFs, built as **two separate tabs**:

**Part 1 tab** — spelling, mandatory field checklist (vs.
`ARTWORK_DECORATION_FINAL`), and batch coding box size measurement (min.
18mm x 18mm) with a ruler overlay. Has its own upload, its own "Run check"
button, and a Print Checklist button (pass/fail-only report + score +
verdict + the artwork itself, 2 printed pages).

**Part 2 tab** — a separate, focused ingredient/shelf-life cross-check
against a formulation code from your uploaded spreadsheet. Has its own
upload and its own "Run ingredient cross-check" button — entirely
independent of Part 1, and faster since it isn't also computing
spelling/compliance/size.

(Part 1 still has an optional formulation-code field too, if you want the
ingredient check folded into one combined run instead of using the
separate Part 2 tab.)

Your Anthropic API key lives only on the server (as an environment
variable), never in the browser — safe to share with your team or open in
any browser, on any device.

## How it works

```
Your browser                     Your server (Vercel)              Anthropic
-------------                    --------------------              ---------
1. Upload a PDF, optionally
   enter a formulation code
2. Text extracted + page 1
   rendered as an image (pdf.js)
3. POST /api/check         --->  4. Makes two focused        --->   5. Call A: spelling +
   (no API key sent)                 calls with your API key           compliance + formulation
                                                                     6. Call B: batch box size
                            <---  7. Merges + returns one     <---
                                     combined result
8. Results rendered, incl.
   the size-measurement
   ruler overlay
```

Two separate AI calls are made per check (not one) so that a failure in
the visual size-measurement task never blocks your spelling/compliance
results — see `api/check.js` for details.

## Files in this project

- `index.html` — the app itself (two tabs, upload, run, results UI)
- `api/check.js` — Part 1's backend function (spelling, compliance,
  size, and Part 1's own optional formulation cross-check)
- `api/check-ingredients.js` — Part 2's dedicated backend function
  (ingredient/shelf-life cross-check only)
- `package.json`, `.gitignore`, `.env.example` — project setup files

## Deploy it (Vercel — free, ~5 minutes)

**1. Get an Anthropic API key**
Go to [console.anthropic.com](https://console.anthropic.com) → API Keys →
Create Key. Copy it — you'll need it in step 4.

**2. Get this project onto Vercel**
- Create a free account at [vercel.com](https://vercel.com)
- Put this folder in a GitHub repository (create a new repo, then use
  GitHub's "uploading an existing file" link to add everything — make sure
  `index.html` and the `api` folder end up at the top level of the repo,
  not nested inside another folder)
- In Vercel, click **Add New → Project**, then import that GitHub repo

**3. Deploy**
Vercel detects `index.html` and `api/check.js` automatically — no build
configuration needed. Click **Deploy**.

**4. Add your API key**
Project → **Settings → Environment Variables**
- Name: `ANTHROPIC_API_KEY`
- Value: the key from step 1
- Make sure **Production** is checked (not just Development)
- **Save**, then go to **Deployments → Redeploy**

**5. Open the URL Vercel gives you** — done.

## Testing locally before deploying (optional)

```bash
npm i -g vercel
cp .env.example .env      # then paste your real key into .env
vercel dev
```

## Your ingredient/formulation sheet (Part 2)

This is a **static upload** — no live sync. Upload your spreadsheet once
in the app's "Ingredient & shelf-life reference" panel; it's remembered
on that device (via browser storage) until you remove it or upload a
different file. If you edit your source spreadsheet, you need to
re-upload it in the app for the change to take effect.

Your sheet needs, at minimum, one row per formulation code with:
- **Formulation Code**
- **Base Ingredients** (comma-separated)
- **Shelf Life** (e.g. "36 Months")

Optional columns it also understands: **Description**, **Hero Ingredient**
(added at the end before preservative), **Additional Ingredients/Notes**
(free-text constraints, e.g. "Vegan — no beeswax"). A "Same as [other
product]" value in Base Ingredients is automatically resolved by matching
that text against another row's Description.

## Updating the Part 1 checklist or the 18mm minimum

Both live in **two places** and should be kept in sync:
- `api/check.js` — `REFERENCE_RULES` (grades the artwork) and the
  minimum-size wording in the size task's system prompt
- `index.html` — `REFERENCE_RULES` (display only) and `MIN_MM` inside
  `renderBatchSizeSection`

## Cost note

Each check makes two API calls to Claude (spelling/compliance/formulation,
plus batch box size). Costs are billed to your Anthropic account per the
API's standard pricing.
