const fs=require('node:fs'); const {execSync}=require('node:child_process');
const repo='C:/AL/ALProject3';
const az=(s)=>JSON.parse(execSync('az '+s+' -o json',{stdio:['ignore','pipe','pipe'],encoding:'utf8',maxBuffer:4e6}));
const output={at:new Date().toISOString(),readOnly:true};
async function main(){
 const settings=Object.fromEntries(az('webapp config appsettings list -g TBG_EMPLOYEE_PORTAL -n tbg-vms-api').map(x=>[x.name,x.value]));
 function setting(name,fallback){let v=settings[name]??fallback;if(v?.startsWith('@Microsoft.KeyVault(')){const vault=/VaultName=([^;)]+)/.exec(v)?.[1],secret=/SecretName=([^;)]+)/.exec(v)?.[1];if(!vault||!secret||!/^[\w-]+$/.test(vault+secret))throw Error('Reference unsupported');v=az('keyvault secret show --vault-name '+vault+' --name '+secret).value;}return v;}
 const tenant=setting('BC_TENANT_ID'), client=setting('BC_CLIENT_ID'), secret=setting('BC_CLIENT_SECRET');
 const env=setting('BC_ENVIRONMENT','Preprodtest'); if(env.toUpperCase()!=='PREPRODTEST')throw Error('Unexpected BC environment'); output.environment=env;
 const root=setting('BC_BASE_URL','https://api.businesscentral.dynamics.com/v2.0')+'/'+tenant+'/'+env;
 const auth=await fetch('https://login.microsoftonline.com/'+tenant+'/oauth2/v2.0/token',{method:'POST',signal:AbortSignal.timeout(30000),body:new URLSearchParams({grant_type:'client_credentials',client_id:client,client_secret:secret,scope:'https://api.businesscentral.dynamics.com/.default'})});
 if(!auth.ok)throw Error('OAuth failed '+auth.status); const token=(await auth.json()).access_token;
 async function get(url){const r=await fetch(url,{headers:{Authorization:'Bearer '+token,Accept:'application/json'},signal:AbortSignal.timeout(30000)});return {status:r.status,json:r.ok?await r.json():null};}


 const assert=require('node:assert/strict');
 const company='f1912784-68b5-f011-bbd1-6045bd1ba617';
 const base=root+'/api/microsoft/automation/v2.0/companies('+company+')';
 const url=new URL(base+'/extensions');url.searchParams.set('$filter','id eq 5aebd1c1-2f62-4145-b924-32816b4d64d5');
 const ext=await get(url);output.extensions={status:ext.status,records:ext.json?.value?.map(x=>({id:x.id,packageId:x.packageId,name:x.displayName,publisher:x.publisher,isInstalled:x.isInstalled,version:[x.versionMajor,x.versionMinor,x.versionBuild,x.versionRevision].join('.')}))};
 const save=()=>fs.writeFileSync(repo+'/docs/receipt-concept-published-verification-2026-10-20.json',JSON.stringify(output,null,2)+'\n');save();
 assert.equal(ext.status,200);assert(output.extensions.records.some(x=>x.version==='1.1.2.28'&&x.isInstalled),'Expected installed28');
 const meta=await fetch(root+'/api/systemsintegration/omsapi2/v1.0/$metadata',{headers:{Authorization:'Bearer '+token,Accept:'application/xml'},signal:AbortSignal.timeout(30000)});
 const xml=meta.ok?await meta.text():'';const v2=/<Action\s[^>]*Name="undoV2"[^>]*>[\s\S]*?<\/Action>/i.exec(xml)?.[0]??'';
 output.metadata={status:meta.status,contractVersionField:xml.includes('Name="undoContractVersion"'),rawDimensionField:xml.includes('Name="shortcutDimension1Code"'),boundUndoV2:v2.includes('IsBound="true"'),parameters:[...v2.matchAll(/<Parameter[^>]*Name="([^"]+)"/g)].map(x=>x[1])};save();
 assert.equal(meta.status,200);assert(output.metadata.boundUndoV2&&output.metadata.rawDimensionField&&output.metadata.contractVersionField);
 assert(output.metadata.parameters.includes('expectedShortcutDimension1Code'));
 output.receipts=[];
 for(const po of ['POR10000008','POR10000002']){
  const u=new URL(root+'/api/systemsintegration/omsapi2/v1.0/companies('+company+')/postedReceiptLines');u.searchParams.set('$filter',"orderNumber eq '"+po+"' and orderLineNumber eq 10000");u.searchParams.set('$top','500');
  const r=await get(u);const rows=r.json?.value?.map(x=>({id:x.id,receiptId:x.receiptId,receiptNumber:x.receiptNumber,lineNumber:x.lineNumber,orderNumber:x.orderNumber,orderLineNumber:x.orderLineNumber,locationCode:x.locationCode,conceptCode:x.conceptCode,shortcutDimension1Code:x.shortcutDimension1Code,undoContractVersion:x.undoContractVersion,quantity:x.quantity,quantityBase:x.quantityBase,quantityInvoiced:x.quantityInvoiced,quantityInvoicedBase:x.quantityInvoicedBase,correction:x.correction}));
  output.rawReceipts??=[];output.rawReceipts.push({bcCompanyId:company,po,checkedAt:new Date().toISOString(),rows:r.json?.value});output.receipts.push({po,status:r.status,rows});save();assert.equal(r.status,200);assert(rows.length>0&&!r.json['@odata.nextLink']);
  assert(rows.every(x=>x.undoContractVersion===2&&x.locationCode==='1991'&&x.conceptCode==='DENNYS'&&x.shortcutDimension1Code==='1991'));
 }
 output.readChecksPassed=true;save();console.log(JSON.stringify({at:output.at,environment:env,installed:output.extensions.records,metadata:output.metadata,receipts:output.receipts,readOnly:true},null,2));
}
main().catch(e=>{console.log(JSON.stringify({failed:true,code:e.code||e.name,message:'Read-only published verification stopped; private details suppressed'}));process.exitCode=1;});
