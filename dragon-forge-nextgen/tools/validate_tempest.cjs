// Optional offline format validator; never a runtime dependency.
const fs = require('node:fs'), path = require('node:path');
const validator = require(process.env.GLTF_VALIDATOR_MODULE || 'gltf-validator');
const root = path.resolve(__dirname, '..');
const folder = path.join(root, 'campaign/tempest');
(async () => {
  let errors = 0, warnings = 0;
  const reports = {};
  for (const file of ['tempest_arc.glb']) {
    const report = await validator.validateBytes(new Uint8Array(fs.readFileSync(path.join(folder,file))), {
      uri:file, maxIssues:1000,
      externalResourceFunction: async uri => {
        const target = path.resolve(folder, uri);
        if (!target.startsWith(root + path.sep) || !target.endsWith('.png')) throw Error('Texture outside project');
        return new Uint8Array(fs.readFileSync(target));
      }
    });
    reports[file] = report;
    errors += report.issues.numErrors; warnings += report.issues.numWarnings;
    console.log(`${file}: ${report.issues.numErrors} errors / ${report.issues.numWarnings} warnings`);
  }
  fs.mkdirSync(path.join(root, 'artifacts/tempest'), {recursive:true});
  fs.writeFileSync(path.join(root,'artifacts/tempest/gltf-validation.json'),JSON.stringify(reports,null,2));
  console.log(`TEMPEST_GLTF: 1 assets, ${errors} errors, ${warnings} warnings`);
  if (errors || warnings) process.exitCode=1;
})().catch(error => { console.error(error); process.exitCode=1; });
