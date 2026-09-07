const fs=require('node:fs'),path=require('node:path');
const validator=require(process.env.GLTF_VALIDATOR_MODULE || 'gltf-validator');
const folder=path.resolve(__dirname,'../campaign/venom');
(async()=>{const file='venom_guardian.glb';const report=await validator.validateBytes(new Uint8Array(fs.readFileSync(path.join(folder,file))),{
 uri:file,maxIssues:1000,externalResourceFunction:async uri=>{if(path.basename(uri)!==uri||!uri.endsWith('.png'))throw Error('Non-local texture path');return new Uint8Array(fs.readFileSync(path.join(folder,uri)));}
});fs.mkdirSync(path.resolve(__dirname,'../artifacts/venom'),{recursive:true});fs.writeFileSync(path.resolve(__dirname,'../artifacts/venom/gltf-validation.json'),JSON.stringify(report,null,2));
console.log(`${file}: ${report.issues.numErrors} errors / ${report.issues.numWarnings} warnings`);if(report.issues.numErrors||report.issues.numWarnings)process.exitCode=1;
})().catch(e=>{console.error(e);process.exitCode=1;});
