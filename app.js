/* ===================== Sunshine PI Desk — shared logic ===================== */

const COMPANIES = {
  cosmetic: {
    key: 'cosmetic',
    label: 'Sunshine Cosmetic Pvt. Ltd.',
    short: 'Cosmetic',
    prefix: 'SC',
    address: 'Plot No. 21, Sector-53, Phase V, HSIIDC Industrial Area, Kundli, Sonepat - 131028.',
    phone: '+91-9810062307',
    email: 'sunshinecosmeticspvtltd@gmail.com'
  },
  industries: {
    key: 'industries',
    label: 'Sunshine Industries',
    short: 'Industries',
    prefix: 'SI',
    address: 'Plot No. 3 & 4, HPSIDC Extension, Industrial Area Baddi, District Solan, Himachal Pradesh - 173205.',
    phone: '+91-9212284070 / 011-27375114',
    email: 'marketing@sunshineind.in',
    website: 'www.sunshineind.in',
    tagline: 'Leading Private Label Cosmetics Manufacturers, Committed To Quality, Committed To You'
  }
};

/* ---------------- Terms & Conditions presets ---------------- */
const TC_VERSIONS = {
  v1: `1. The Prices are for the items as per the sampled quality.

2. Approval charges: Rs. 6000/- per product per variant.

3. Payment: 50% advance at the time of order confirmation. 50% pre-dispatch.

4. Taxes & duties: Extra as applicable.

5. Freight: Extra as per actual transit costs.

6. Dispatch: Within 45 days of receiving the Purchase Order with advance along with the signed agreement, copies of GSTIN no., PAN Card, Trademark & artwork/s (or receipt of Containers, Labels & Cartons, whichever is later).

7. Storage Policy: In case any packaging is required to be made or developed in excess of the aforesaid quantities, the same shall be stored at the vendor's warehouse but payment of the same shall be done upon delivery verification.

8. Artworks: All artwork and plate-related development charges are extra.

9. PPS (Pre Production Sample): Upon receiving the signed PPS from the client, we will promptly initiate the filling process. This step is crucial to ensuring the highest quality standards. Your timely approval enables efficient manufacturing execution.

10. Monocarton: We will transmit a digital dummy file layout for confirmation. Once approved, final print execution begins. Your feedback is vital to achieving standard color accuracy.

11. Jurisdiction: All disputes are subject to Solan (Himachal Pradesh) jurisdiction only.`,
  v2: `1. The Prices are for the items as per the sampled quality.

2. Approval charges: Rs. 6000/- per product per variant.

3. Payment: As per mutually agreed terms.

4. Taxes & duties: Extra as applicable.

5. Freight: Extra as per actual transit costs.

6. Dispatch: Within 45 days of receiving the Purchase Order with advance along with the signed agreement, copies of GSTIN no., PAN Card, Trademark & artwork/s (or receipt of Containers, Labels & Cartons, whichever is later).

7. Storage Policy: In case any packaging is required to be made or developed in excess of the aforesaid quantities, the same shall be stored at the vendor's warehouse but payment of the same shall be borne by the customer/buyer.

8. Artworks: All artwork and plate-related development charges are extra.

9. PPS (Pre Production Sample): Upon receiving the signed PPS from the client, we will promptly initiate the filling process. This step is crucial to ensuring the highest quality standards. Your timely approval enables efficient manufacturing execution.

10. Monocarton (Secondary Packaging): We will transmit a digital dummy file layout for confirmation. Once approved, final print execution begins.

11. Jurisdiction: All disputes are subject to Solan (Himachal Pradesh) jurisdiction only.`
};

/* ---------------- Formatting helpers (no storage, safe to use anywhere) ---------------- */
function computeTotals(items, taxPct){
  const rate = Number(taxPct)||0;
  const subtotal = items.reduce((s,i)=> s + (Number(i.qty)||0) * (Number(i.price)||0), 0);
  const tax = subtotal * rate / 100;
  const grandTotal = subtotal + tax;
  let advanceWithoutGST = 0, advanceWithGST = 0;
  items.forEach(i=>{
    const amt = (Number(i.qty)||0) * (Number(i.price)||0);
    const base = amt * (Number(i.advancePct)||0) / 100;
    if(i.advanceGST === 'with'){ advanceWithGST += base * (1 + rate/100); }
    else { advanceWithoutGST += base; }
  });
  const advanceTotal = advanceWithoutGST + advanceWithGST;
  const balanceDue = grandTotal - advanceTotal;
  return { subtotal, tax, grandTotal, advanceWithoutGST, advanceWithGST, advanceTotal, balanceDue };
}
function fmtMoney(n){
  return (Number(n)||0).toLocaleString('en-IN', {minimumFractionDigits:2, maximumFractionDigits:2});
}
function fmtDate(iso){
  if(!iso) return '—';
  const d = new Date(iso+'T00:00:00');
  if(isNaN(d)) return '—';
  return d.toLocaleDateString('en-GB', {day:'2-digit', month:'2-digit', year:'numeric'});
}
function fmtDateTime(iso){
  if(!iso) return '—';
  const d = new Date(iso);
  if(isNaN(d)) return '—';
  return d.toLocaleDateString('en-GB', {day:'2-digit', month:'short', year:'numeric'}) + ', ' +
         d.toLocaleTimeString('en-GB', {hour:'2-digit', minute:'2-digit'});
}
function escHtml(s){ return String(s==null?'':s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;').replace(/'/g,'&#39;'); }
function qs(name){ return new URLSearchParams(location.search).get(name); }

/* ===================== Supabase client + auth ===================== */
/* SUPABASE_URL / SUPABASE_ANON_KEY come from supabase-config.js, loaded before this file. */
const sb = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

async function getSession(){
  const { data } = await sb.auth.getSession();
  return data.session;
}
/* Call at the top of any protected page. Redirects to login.html if not signed in.
   Returns the session (with .user) if signed in. */
async function requireAuth(){
  const session = await getSession();
  if(!session){
    location.href = 'login.html';
    return null;
  }
  return session;
}
function getDisplayName(session){
  return (session.user.user_metadata && session.user.user_metadata.full_name) || session.user.email;
}
async function logout(){
  await sb.auth.signOut();
  location.href = 'login.html';
}

/* ===================== PI storage (Supabase table: public.pis, protected by Row Level Security) ===================== */

function rowToRecord(row){
  return {
    id: row.id,
    userId: row.user_id,
    company: row.company,
    piNumber: row.pi_number,
    refPO: row.ref_po || '',
    buyerName: row.buyer_name,
    buyerContact: row.buyer_contact || '',
    buyerPhone: row.buyer_phone || '',
    buyerEmail: row.buyer_email || '',
    buyerGST: row.buyer_gst || '',
    buyerAddress: row.buyer_address || '',
    piDate: row.pi_date,
    validUntil: row.valid_until,
    currency: row.currency,
    taxPct: row.tax_pct,
    tcVersion: row.tc_version || '',
    notes: row.notes || '',
    items: row.items || [],
    subtotal: row.subtotal, tax: row.tax, grandTotal: row.grand_total,
    advanceWithoutGST: row.advance_without_gst, advanceWithGST: row.advance_with_gst,
    advanceTotal: row.advance_total, balanceDue: row.balance_due,
    createdBy: row.created_by,
    createdAt: row.created_at,
    updatedAt: row.updated_at
  };
}
function recordToRow(r){
  const row = {
    company: r.company,
    pi_number: r.piNumber,
    ref_po: r.refPO || null,
    buyer_name: r.buyerName,
    buyer_contact: r.buyerContact || null,
    buyer_phone: r.buyerPhone || null,
    buyer_email: r.buyerEmail || null,
    buyer_gst: r.buyerGST || null,
    buyer_address: r.buyerAddress || null,
    pi_date: r.piDate || null,
    valid_until: r.validUntil || null,
    currency: r.currency,
    tax_pct: r.taxPct,
    tc_version: r.tcVersion || null,
    notes: r.notes || null,
    items: r.items,
    subtotal: r.subtotal, tax: r.tax, grand_total: r.grandTotal,
    advance_without_gst: r.advanceWithoutGST, advance_with_gst: r.advanceWithGST,
    advance_total: r.advanceTotal, balance_due: r.balanceDue,
    created_by: r.createdBy
  };
  if(r.id) row.id = r.id;
  return row;
}

/* All of these rely on Supabase Row Level Security to silently scope results
   to the signed-in user's own rows — there is no client-side "which user" filter
   here on purpose, because the database itself enforces it. */

async function getLog(){
  const { data, error } = await sb.from('pis').select('*').order('created_at', {ascending:false});
  if(error){ console.error(error); return []; }
  return data.map(rowToRecord);
}
/* Shared log listing: uses the get_pi_log() Postgres function, which can see
   every PI regardless of who created it, but only returns summary columns —
   no buyer contact info, GST, items, notes, or money amounts. Only the
   creator (or an admin) sees the actual total, via the full record. */
async function getLogSummary(){
  const { data, error } = await sb.rpc('get_pi_log');
  if(error){ console.error(error); return []; }
  return data.map(row => ({
    id: row.id,
    userId: row.user_id,
    piNumber: row.pi_number,
    piDate: row.pi_date,
    company: row.company,
    buyerName: row.buyer_name,
    createdBy: row.created_by
  }));
}
/* Admins can view/edit/delete any PI, not just their own. */
async function getIsAdmin(userId){
  const { data, error } = await sb.from('profiles').select('is_admin').eq('id', userId).maybeSingle();
  if(error || !data) return false;
  return !!data.is_admin;
}
async function getRecord(id){
  const { data, error } = await sb.from('pis').select('*').eq('id', id).maybeSingle();
  if(error || !data) return null;
  return rowToRecord(data);
}
/* Returns the saved record (with server-assigned id/timestamps) or null on failure. */
async function upsertRecord(record){
  const row = recordToRow(record);
  const { data, error } = await sb.from('pis').upsert(row).select().maybeSingle();
  if(error){ alert('Save failed: ' + error.message); return null; }
  return rowToRecord(data);
}
async function deleteRecord(id){
  const { error } = await sb.from('pis').delete().eq('id', id);
  if(error){ alert('Delete failed: ' + error.message); }
}
async function nextPiNumber(companyKey){
  const co = COMPANIES[companyKey];
  const year = new Date().getFullYear();
  const { count } = await sb.from('pis').select('id', {count:'exact', head:true}).eq('company', companyKey);
  const n = (count||0) + 1;
  return `PI-${co.prefix}-${year}-${String(n).padStart(3,'0')}`;
}
