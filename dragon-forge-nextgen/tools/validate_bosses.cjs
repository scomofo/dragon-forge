// Optional independent format validation; no Node dependency for playing.
const fs=require('node:fs'), path=require('node:path');
const validator=require(process.env.GLTF_VALIDATOR_MODULE || 'gltf-validator');
const folder=path.resolve(__dirname,'../campaign/bosses/assets');
(async()=>{ let errors=0,warnings=0; const reports={};
  for(const file of ['buffer_overflow.glb','memory_leak.glb','stack_overflow.glb','mirror_admin.glb','singularity.glb']) {
    const report=await validator.validateBytes(new Uint8Array(fs.readFileSync(path.join(folder,file))),{
      uri:file,maxIssues:1000,externalResourceFunction:async uri=>{
        if(path.basename(uri)!==uri || !uri.endsWith('.png')) throw Error('Non-local texture path');
        return new Uint8Array(fs.readFileSync(path.join(folder,uri)));
      }
    }); reports[file]=report; errors+=report.issues.numErrors;warnings+=report.issues.numWarnings;
    console.log(`${file}: ${report.issues.numErrors} errors / ${report.issues.numWarnings} warnings`);
  }
  fs.mkdirSync(path.resolve(__dirname,'../artifacts/bosses'),{recursive:true});
  fs.writeFileSync(path.resolve(__dirname,'../artifacts/bosses/gltf-validation.json'),JSON.stringify(reports,null,2));
  console.log(`BOSS_GLTF: 5 assets, ${errors} errors, ${warnings} warnings`);
  if(errors || warnings) process.exitCode=1;
})().catch(e=>{console.error(e);process.exitCode=1;});
