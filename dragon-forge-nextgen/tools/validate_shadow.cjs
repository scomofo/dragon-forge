const fs=require('node:fs'),path=require('node:path');
const validator=require(process.env.GLTF_VALIDATOR_MODULE || 'gltf-validator');
const folder=path.resolve(__dirname,'../campaign/shadow');
(async()=>{const file='shadow_guardian.glb';const report=await validator.validateBytes(new Uint8Array(fs.readFileSync(path.join(folder,file))),{
 uri:file,maxIssues:1000,externalResourceFunction:async uri=>{if(path.basename(uri)!==uri||!uri.endsWith('.png'))throw Error('Non-local texture path');return new Uint8Array(fs.readFileSync(path.join(folder,uri)));}
});fs.mkdirSync(path.resolve(__dirname,'../artifacts/shadow'),{recursive:true});fs.writeFileSync(path.resolve(__dirname,'../artifacts/shadow/gltf-validation.json'),JSON.stringify(report,null,2));
console.log(`${file}: ${report.issues.numErrors} errors / ${report.issues.numWarnings} warnings`);
if(report.issues.numErrors||report.issues.numWarnings){for(const m of report.issues.messages.slice(0,30))console.log(`GLTF_ISSUE ${m.severity} ${m.code}: ${m.message} @ ${m.pointer||''}`);process.exitCode=1;}
})().catch(e=>{console.error(e);process.exitCode=1;});
