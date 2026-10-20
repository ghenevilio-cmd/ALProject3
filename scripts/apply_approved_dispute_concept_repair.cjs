// Release procedure: execute only the reviewed library with the exact user-approved manifest.
const fs=require('node:fs'),path=require('node:path'),assert=require('node:assert/strict'),crypto=require('node:crypto'),{execFileSync}=require('node:child_process');
const root='C:/AL/ALProject3',vms='C:/Users/ghene.winters/Desktop/GHENE/Projects/Vendor Management System',oms='C:/Users/ghene.winters/.codex/worktrees/oms-notification-review/Ordering Management System';
const sha=x=>crypto.createHash('sha256').update(x).digest('hex');const json=p=>JSON.parse(fs.readFileSync(p,'utf8'));
const az=args=>JSON.parse(execFileSync('az.cmd',[...args,'-o','json'],{encoding:'utf8',stdio:['ignore','pipe','pipe'],maxBuffer:4e6,shell:true}));
let db;
(async()=>{
 const frozen=json(root+'/docs/dispute-concept-exact-repair-manifest-2026-10-20.json');const input=frozen.manifest;
 assert(frozen.approved===true&&frozen.manifestHash==='1ce10ee6b834a2e505fcca0258e582d3464cccf96d2996542e47e50fa0500e67');assert.equal(sha(JSON.stringify(input)),frozen.manifestHash);
 for(const [repo,commit] of [[vms,'17a014b9b46a2501587e2e9ba4b2c4fe8332a5fb'],[oms,'fb221b7ead19b568860da0fa0e88d702a331c95d']]){const r=json(repo+'/docs/reviews/dispute-concept-backend-hosted-2026-10-20.json');assert(r.backendVerified===true&&r.commit===commit);}
 const inventory=json(path.join(process.env.TEMP,'oms-concept-undo-inventory.json'));assert(inventory.companies.length===17&&inventory.requests.length===0&&inventory.outbox.length===0&&Math.abs(Date.now()-Date.parse(inventory.checkedAt))<60000,'Fresh empty financial inventory required');
 const bc=json(root+'/docs/receipt-concept-published-verification-2026-10-20.json');assert(bc.readChecksPassed===true&&Math.abs(Date.now()-Date.parse(bc.at))<60000,'Fresh BC proof required');
 process.env.NODE_ENV='test';process.env.DATABASE_URL='sqlserver://127.0.0.1:1;database=Unused';process.env.JWT_SECRET='maintenance-only-'+crypto.randomBytes(24).toString('hex');process.env.RLS_ENFORCED='true';
 const {readReceiptLines}=require(vms+'/backend/dist/modules/po/receiptLines');
 for(const t of input.targets){const raw=bc.rawReceipts.find(x=>x.po===t.receipt.orderNumber);assert(raw&&raw.bcCompanyId==='f1912784-68b5-f011-bbd1-6045bd1ba617');const proof=await readReceiptLines(raw.bcCompanyId,t.receipt.orderNumber,t.receipt.orderLineNumber,{all:async()=>raw.rows,check:()=>{}});const receipt=proof.data.find(x=>x.id===t.receiptLineId);assert.deepEqual(receipt,t.receipt,'Approved BC evidence changed');}
 const source=vms+'/backend/scripts/repair-dispute-concepts.ts';const reviewed=JSON.parse(execFileSync('git',['show','17a014b9b46a2501587e2e9ba4b2c4fe8332a5fb:docs/reviews/dispute-concept-implementation-2026-10-20.json'],{cwd:vms,encoding:'utf8'}));assert.equal(sha(fs.readFileSync(source)),reviewed.files.find(x=>x.repository==='VMS'&&x.path==='backend/scripts/repair-dispute-concepts.ts').sha256);
 const url=az(['keyvault','secret','show','--vault-name','tbg-portal-keyvault','--name','VmsMigrationDatabaseUrl']).value;
 const {PrismaClient}=require(vms+'/node_modules/@prisma/client');db=new PrismaClient({datasources:{db:{url}},log:[]});
 const {runAsSystem,applyTenantContext}=require(vms+'/backend/src/lib/tenant.ts');const {repairDisputeConcepts,disputeSnapshotHash}=require(source);
 process.env.VMS_DISPUTE_CONCEPT_REPAIR_APPROVED=frozen.manifestHash;
 const result=await runAsSystem(()=>db.$transaction(async tx=>{
  await applyTenantContext(tx);
  const before=await tx.poDispute.findMany({where:{id:{in:[1,2]}},orderBy:{id:'asc'}});assert(before.length===2);
  const oldEvents=await tx.poDisputeEvent.findMany({where:{disputeId:{in:[1,2]}},orderBy:{id:'asc'}});
  assert.equal(await repairDisputeConcepts(tx,input.targets,input.actorId),2);
  assert.equal(await repairDisputeConcepts(tx,input.targets,input.actorId),0);
  const after=await tx.poDispute.findMany({where:{id:{in:[1,2]}},orderBy:{id:'asc'}}),events=await tx.poDisputeEvent.findMany({where:{disputeId:{in:[1,2]}},orderBy:{id:'asc'}});
  assert.deepEqual(events.slice(0,oldEvents.length),oldEvents);assert.equal(events.length,oldEvents.length+2);
  const cases=[];
  for(let i=0;i<after.length;i++){const a=after[i],b=before[i];assert(b.status==='IN_PROGRESS'&&b.version===2&&a.version===3&&a.conceptCode==='DENNYS'&&a.locationCode==='1991');const strip=x=>{const {conceptCode,version,updatedAt,...rest}=JSON.parse(JSON.stringify(x));return rest};assert.deepEqual(strip(a),strip(b));
   const additions=events.filter(x=>x.disputeId===a.id&&x.action==='CONCEPT_CORRECTED');assert.equal(additions.length,1);assert(additions[0].companyId===1&&additions[0].actorId===5);
   assert.equal(await tx.auditLog.count({where:{entity:'po_disputes',entityId:a.id,companyId:1,action:'DISPUTE_CONCEPT_CORRECTED',actorId:5,data:additions[0].data}}),1);
   cases.push({id:a.id,companyId:a.companyId,status:a.status,locationCode:a.locationCode,conceptCode:a.conceptCode,version:a.version,beforeHash:disputeSnapshotHash(b),afterHash:disputeSnapshotHash(a),historyPreserved:true,auditEvents:1,correctionEvents:1});}
  return {cases,originalHistoryEvents:oldEvents.length,currentHistoryEvents:events.length,idempotentRepeat:0};
 },{timeout:20000}));
 const report={at:new Date().toISOString(),manifestHash:frozen.manifestHash,approved:true,committed:true,...result,bcWrites:false,financialUndo:false};fs.writeFileSync(root+'/docs/dispute-concept-exact-repair-result-2026-10-20.json',JSON.stringify(report,null,2)+'\n');console.log(JSON.stringify(report,null,2));
})().catch(e=>{console.log(JSON.stringify({failed:true,code:e.code||e.name,message:e.code==='ERR_ASSERTION'?e.message:'Exact repair stopped; private details suppressed'}));process.exitCode=1}).finally(()=>db?.$disconnect());
