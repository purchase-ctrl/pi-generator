/* Client profiles (Supabase table public.client_profiles, protected by Row Level Security).
   Depends on app.js (sb). Run supabase-add-client-profiles.sql first. */
const cpNorm = s => String(s||'').trim().toLowerCase().replace(/\s+/g,' ');
const cpKey = (name, brand) => cpNorm(name) + '|' + cpNorm(brand);

function cpFromRow(r){
  return { id:r.id, userId:r.user_id, createdBy:r.created_by||'', name:r.name||'', brand:r.brand_name||'',
    contact:r.contact||'', phone:r.phone||'', email:r.email||'', gst:r.gst||'', address:r.address||'', other:r.other||'' };
}
function cpToRow(p){
  const row = { name:p.name, brand_name:p.brand||'', contact:p.contact||null, phone:p.phone||null, email:p.email||null,
    gst:p.gst||null, address:p.address||null, other:p.other||null };
  if(p.id) row.id = p.id;
  if(p.createdBy) row.created_by = p.createdBy;
  if(p.userId) row.user_id = p.userId;
  return row;
}
/* Returns {rows} or {error}. */
async function getClientProfiles(){
  const { data, error } = await sb.from('client_profiles').select('*').order('name', {ascending:true});
  if(error){ console.error(error); return { error }; }
  return { rows: data.map(cpFromRow).sort((a,b)=>a.name.localeCompare(b.name)||a.brand.localeCompare(b.brand)) };
}
function cpMissingTable(error){
  return /client_profiles/.test((error&&error.message)||'') && /(does not exist|schema cache)/.test((error&&error.message)||'');
}
/* Returns {profile} or {error}. */
async function saveClientProfile(p){
  const { data, error } = await sb.from('client_profiles').upsert(cpToRow(p)).select().maybeSingle();
  if(error) return { error };
  return { profile: data ? cpFromRow(data) : null };
}
async function deleteClientProfile(id){
  const { error } = await sb.from('client_profiles').delete().eq('id', id);
  return { error };
}
/* Called after a PI is saved: add the buyer to the profiles if that client + brand isn't there yet.
   Never overwrites an existing profile. Silent on failure so it can't block saving a PI. */
async function ensureProfileFromPI(rec, createdBy){
  try{
    if(!rec.buyerName) return false;
    const have = await getClientProfiles();
    if(have.error) return false;
    const k = cpKey(rec.buyerName, rec.brandName);
    if(have.rows.some(p => cpKey(p.name, p.brand) === k)) return false;
    const r = await saveClientProfile({ createdBy, name:rec.buyerName, brand:rec.brandName||'', contact:rec.buyerContact, phone:rec.buyerPhone,
      email:rec.buyerEmail, gst:rec.buyerGST, address:rec.buyerAddress, other:rec.buyerOther });
    return !r.error;
  }catch(e){ return false; }
}
