const fs = require('node:fs');
const path = require('node:path');
const validator = require(process.env.GLTF_VALIDATOR_MODULE || 'gltf-validator');
const folder = path.resolve(__dirname, '../campaign/synthesis');
(async () => {
  const file = 'synthesis_guardian.glb';
  const report = await validator.validateBytes(new Uint8Array(fs.readFileSync(path.join(folder, file))), {
    uri: file,
    maxIssues: 1000,
    externalResourceFunction: async uri => {
      if (path.basename(uri) !== uri || !uri.endsWith('.png')) throw Error('Non-local texture path');
      return new Uint8Array(fs.readFileSync(path.join(folder, uri)));
    },
  });
  const output = path.resolve(__dirname, '../artifacts/synthesis');
  fs.mkdirSync(output, { recursive: true });
  fs.writeFileSync(path.join(output, 'gltf-validation.json'), JSON.stringify(report, null, 2));
  console.log(`${file}: ${report.issues.numErrors} errors / ${report.issues.numWarnings} warnings`);
  if (report.issues.numErrors || report.issues.numWarnings) {
    for (const issue of report.issues.messages.slice(0, 30)) {
      console.log(`GLTF_ISSUE ${issue.severity} ${issue.code}: ${issue.message} @ ${issue.pointer || ''}`);
    }
    process.exitCode = 1;
  }
})().catch(error => { console.error(error); process.exitCode = 1; });
