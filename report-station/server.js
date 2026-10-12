#!/usr/bin/env node
/* Raw Data Station backend — zero dependencies.
 *
 *   GET  /              the wizard UI
 *   GET  /api/fields    verified export columns + supported date filters
 *   POST /api/export    body = wizard spec (buildDefinitionObject output)
 *
 * The real chart export lives in ACS.Modules.Charts (ExportChartsQuery, right 32).
 * It always returns the same 34 columns, so this server: maps the spec to that
 * query, calls it, keeps only the requested columns in order, masks PHI, and
 * returns CSV. No calculations are ever applied.
 *
 *   ACS_API_URL    base URL of the Pulse API; unset = dry-run (returns the mapped request)
 *   ACS_EXPORT_PATH  export route (default /api/charts/export) — confirm against the real API
 *   PORT           default 3000
 */
const http = require('http'), fs = require('fs'), path = require('path');
const MAX_ROWS = 3001;
const DATE_PARAMS = { 'Date of Service (DOS)':'Dos','Sent Date':'Sent','Received Date':'Received','Discharge Date':'Discharge','Approved Date':'Approved','Completed Date':'Completed' };

// Wizard field id -> header returned by ExportChartsQueryHandler (+ whether it's PHI)
const FIELDS = {
  901:['Facility'],902:['Chart ID'],903:['Facility Chart ID'],904:['Medical Record #',1],905:['Date of Birth',1],
  906:['Patient Name',1],907:['Long Patient ID',1],908:['Physician'],909:['Patient Class'],910:['Status'],
  911:['Pending Reason'],912:['Patient Disposition'],913:['Received Date'],914:['Date of Service'],915:['Discharge Date'],
  916:['Sent Date'],917:['Last Changed'],918:['Last Image Receipt'],919:['EMR'],920:['Census'],921:['Location Code'],
  922:['Mid Level'],923:['OB Arrival Source'],924:['OB Department'],925:['Facility Admin Chart ID'],926:['Service Model'],
  927:['Assigned To (First)'],928:['Assigned To (Last)'],929:['Client Comment'],930:['Coder Notes'],
};

function parseCsv(text){            // RFC-4180 style, handles quotes and embedded newlines
  const rows=[]; let row=[], cur='', q=false;
  text = text.replace(/^﻿/,'');
  for(let i=0;i<text.length;i++){
    const c=text[i];
    if(q){ if(c==='"'){ if(text[i+1]==='"'){cur+='"';i++;} else q=false; } else cur+=c; }
    else if(c==='"') q=true;
    else if(c===','){ row.push(cur); cur=''; }
    else if(c==='\n'||c==='\r'){ if(c==='\r'&&text[i+1]==='\n') i++; row.push(cur); rows.push(row); row=[]; cur=''; }
    else cur+=c;
  }
  if(cur!==''||row.length){ row.push(cur); rows.push(row); }
  return rows;
}
const csvCell = v => /[",\n\r]/.test(v) ? '"'+v.replace(/"/g,'""')+'"' : v;
const maskValue = (h,v) => !v ? v : h==='Patient Name' ? v.trim()[0]+'.' : '***'+v.slice(-4);

function validate(spec){
  const errs=[], d=spec&&spec.EXPORT_DEFINITION, f=spec&&spec.RUNTIME_FILTERS, cols=(spec&&spec.EXPORT_COLUMN)||[];
  if(!d||!f) return ['body must be a wizard spec (EXPORT_DEFINITION, RUNTIME_FILTERS, EXPORT_COLUMN)'];
  if(d.AGGREGATION && d.AGGREGATION!=='none') errs.push('calculated/aggregated output is not supported');
  if(!cols.length) errs.push('select at least one column');
  cols.forEach(c=>{ if(!FIELDS[c.EXPORT_FIELD_ID]) errs.push('field '+c.EXPORT_FIELD_ID+' is not an exportable raw field'); });
  if(!DATE_PARAMS[f.DATE_BASIS]) errs.push('unsupported date basis: '+f.DATE_BASIS);
  if(!f.FACILITY_IDS||!f.FACILITY_IDS.length) errs.push('FACILITY_IDS required (the real query requires facility IDs)');
  return errs;
}
function toQuery(spec){
  const f=spec.RUNTIME_FILTERS, b=DATE_PARAMS[f.DATE_BASIS], q=new URLSearchParams();
  q.set('Facilities', f.FACILITY_IDS.join(','));
  q.set('Statuses', (f.CHART_STATUS_IDS||[]).join(','));
  q.set('Format','csv');
  if(f.DATE_START) q.set(b+'From', f.DATE_START);
  if(f.DATE_END)   q.set(b+'To',   f.DATE_END);
  return q;
}
function project(csv, spec){
  const rows=parseCsv(csv), head=rows.shift()||[], mask=spec.RUNTIME_FILTERS.MASK_PHI!==false;
  const sel=spec.EXPORT_COLUMN.slice().sort((a,b)=>a.COLUMN_ORDER-b.COLUMN_ORDER).map(c=>{
    const [name,phi]=FIELDS[c.EXPORT_FIELD_ID]; return {name, caption:c.CAPTION||name, phi:!!phi, i:head.indexOf(name)};
  });
  const missing=sel.filter(s=>s.i<0).map(s=>s.name);
  if(missing.length) throw new Error('upstream export is missing columns: '+missing.join(', '));
  const out=[sel.map(s=>csvCell(s.caption)).join(',')];
  rows.slice(0,MAX_ROWS).forEach(r=>out.push(sel.map(s=>csvCell(mask&&s.phi?maskValue(s.name,r[s.i]||''):(r[s.i]||''))).join(',')));
  return {body:'﻿'+out.join('\r\n')+'\r\n', rows:Math.min(rows.length,MAX_ROWS), capped:rows.length>MAX_ROWS};
}

async function handleExport(req,res,body){
  let spec; try{ spec=JSON.parse(body); }catch{ return send(res,400,{errors:['invalid JSON']}); }
  const errs=validate(spec); if(errs.length) return send(res,400,{errors:errs});
  const query=toQuery(spec), base=process.env.ACS_API_URL;
  const route=process.env.ACS_EXPORT_PATH||'/api/charts/export';
  if(!base) return send(res,200,{dryRun:true, note:'ACS_API_URL not set — nothing was fetched.', request:route+'?'+query, maxRows:MAX_ROWS,
    columns:spec.EXPORT_COLUMN.map(c=>FIELDS[c.EXPORT_FIELD_ID][0]), maskPhi:spec.RUNTIME_FILTERS.MASK_PHI!==false});
  const auth=req.headers.authorization; if(!auth) return send(res,401,{errors:['Authorization header required (user needs right 32)']});
  const up=await fetch(base+route+'?'+query,{headers:{authorization:auth}});
  if(!up.ok) return send(res,up.status,{errors:['upstream export failed: '+up.status]});
  try{
    const r=project(await up.text(),spec);
    res.writeHead(200,{'content-type':'text/csv; charset=utf-8','content-disposition':'attachment; filename="export.csv"','x-row-count':r.rows,'x-row-cap-hit':r.capped});
    res.end(r.body);
  }catch(e){ send(res,502,{errors:[e.message]}); }
}
function send(res,code,obj){ res.writeHead(code,{'content-type':'application/json'}); res.end(JSON.stringify(obj,null,2)); }

const server = http.createServer((req,res)=>{
  if(req.method==='GET'&&(req.url==='/'||req.url==='/index.html'))
    return fs.createReadStream(path.join(__dirname,'index.html')).pipe(res.writeHead(200,{'content-type':'text/html'})&&res);
  if(req.method==='GET'&&req.url==='/api/fields')
    return send(res,200,{maxRows:MAX_ROWS,dateBases:Object.keys(DATE_PARAMS),fields:Object.entries(FIELDS).map(([id,[name,phi]])=>({id:+id,name,phi:!!phi}))});
  if(req.method==='POST'&&req.url==='/api/export'){ let b=''; req.on('data',c=>b+=c); return req.on('end',()=>handleExport(req,res,b).catch(e=>send(res,500,{errors:[e.message]}))); }
  send(res,404,{errors:['not found']});
});
if(require.main===module) server.listen(process.env.PORT||3000,()=>console.log('Raw Data Station on :'+(process.env.PORT||3000)));
module.exports={server,validate,toQuery,project,parseCsv};
