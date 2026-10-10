/* BOM storage (Supabase table public.boms, protected by Row Level Security).
   Depends on app.js (sb, escHtml). Run supabase-add-bom.sql first. */
const BOM_DEFAULT_ROWS = ['PRIMARY CONTAINER','','','SECONDARY PACKAGING','','','INNER SHIPPER','OUTER SHIPPER','SHRINK','Identification Label on Inner Shipper','Identification Label on Outer Shipper',''];

function bomRowToRecord(r){
  return {
    id: r.id, userId: r.user_id, createdBy: r.created_by, piId: r.pi_id, piNumber: r.pi_number || '',
    created: r.bom_date || '', recv: r.recv_date || '', company: r.company_name || '', brand: r.brand_name || '',
    product: r.product_name || '', sku: r.sku_size || '', mrp: r.mrp || '', usp: r.usp || '',
    rows: Array.isArray(r.rows) && r.rows.length ? r.rows : BOM_DEFAULT_ROWS.map(n=>({item:n,desc:'',qty:'',art:''})),
    special: r.special || '', prepared: r.prepared_by || '', checked: r.checked_by || '', approved: r.approved_by || ''
  };
}
function bomRecordToRow(b){
  const row = {
    pi_id: b.piId || null, pi_number: b.piNumber || null,
    bom_date: b.created || null, recv_date: b.recv || null,
    company_name: b.company, brand_name: b.brand, product_name: b.product,
    sku_size: b.sku, mrp: b.mrp, usp: b.usp, rows: b.rows, special: b.special,
    prepared_by: b.prepared, checked_by: b.checked, approved_by: b.approved
  };
  if(b.id) row.id = b.id;
  if(b.createdBy) row.created_by = b.createdBy;
  if(b.userId) row.user_id = b.userId;
  return row;
}
async function getBomLog(){
  const { data, error } = await sb.rpc('get_bom_log');
  if(error){ console.error(error); return { error }; }
  return { rows: data.map(r => ({
    id: r.id, userId: r.user_id, createdBy: r.created_by, piId: r.pi_id, piNumber: r.pi_number || '',
    date: r.bom_date, company: r.company_name || '', brand: r.brand_name || '', product: r.product_name || ''
  })) };
}
async function getBom(id){
  const { data, error } = await sb.from('boms').select('*').eq('id', id).maybeSingle();
  if(error || !data) return null;
  return bomRowToRecord(data);
}
/* Boms already made from a given PI (only the ones you're allowed to see). */
async function getBomsForPi(piId){
  const { data, error } = await sb.from('boms').select('id,product_name').eq('pi_id', piId);
  if(error || !data) return [];
  return data;
}
async function upsertBom(b){
  const { data, error } = await sb.from('boms').upsert(bomRecordToRow(b)).select().maybeSingle();
  if(error){
    if(/boms/.test(error.message||'') && /(does not exist|schema cache)/.test(error.message||'')){
      alert('Save failed: the database has no BOM table yet. Run supabase-add-bom.sql in Supabase first.');
    } else {
      alert('Save failed: ' + (error.message || 'unknown error'));
    }
    return null;
  }
  return data ? bomRowToRecord(data) : null;
}
async function deleteBom(id){
  const { error } = await sb.from('boms').delete().eq('id', id);
  if(error){ alert('Delete failed: ' + error.message); return false; }
  return true;
}
