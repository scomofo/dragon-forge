// Independent Khronos validation; npm is only needed by this optional build check.
const fs = require('node:fs');
const path = require('node:path');
const validator = require(process.env.GLTF_VALIDATOR_MODULE || 'gltf-validator');
const project = path.resolve(__dirname, '..');
const art = path.join(project, 'art', 'generated');
(async () => {
  const reports = {};
  let errors = 0, warnings = 0;
  const files = fs.readdirSync(art).filter(f => f.endsWith('.glb')).sort();
  for (const file of files) {
    const report = await validator.validateBytes(new Uint8Array(fs.readFileSync(path.join(art, file))), {
      uri: file,
      maxIssues: 1000,
      externalResourceFunction: async uri => {
        if (path.basename(uri) !== uri || !uri.endsWith('.png')) throw new Error('Non-local texture URI');
        return new Uint8Array(fs.readFileSync(path.join(art, uri)));
      }
    });
    reports[file] = report;
    errors += report.issues.numErrors;
    warnings += report.issues.numWarnings;
    console.log(`${file}: ${report.issues.numErrors} errors, ${report.issues.numWarnings} warnings`);
  }
  fs.mkdirSync(path.join(project, 'artifacts'), { recursive: true });
  fs.writeFileSync(path.join(project, 'artifacts', 'gltf-report.json'), JSON.stringify(reports, null, 2));
  console.log(`KHRONOS_GLTF: ${files.length} assets, ${errors} errors, ${warnings} warnings`);
  if (errors || warnings || files.length !== 15) process.exitCode = 1;
})().catch(error => { console.error(error); process.exitCode = 1; });
