import { readFileSync, writeFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);
const projectRoot = path.resolve(__dirname, '..');
const manifestPath = path.join(projectRoot, 'dist', 'manifest.json');
const controlAddInPath = path.resolve(projectRoot, '..', 'TBGC_Receiving_ControlAddin.al');

const manifest = JSON.parse(readFileSync(manifestPath, 'utf8'));
const entry = manifest['index.html'];

if (!entry?.file) {
  throw new Error('Unable to find JS entry in dist/manifest.json.');
}

const scriptPath = `react-receiving/dist/${entry.file.replace(/\\/g, '/')}`;
const styleFile = entry.css?.[0];

if (!styleFile) {
  throw new Error('Unable to find CSS entry in dist/manifest.json.');
}

const stylePath = `react-receiving/dist/${styleFile.replace(/\\/g, '/')}`;

const controlAddIn = readFileSync(controlAddInPath, 'utf8');
const updatedControlAddIn = controlAddIn
  .replace(/Scripts\s*=\s*'[^']+';/, `Scripts = '${scriptPath}';`)
  .replace(/StyleSheets\s*=\s*'[^']+';/, `StyleSheets = '${stylePath}';`);

if (updatedControlAddIn === controlAddIn) {
  throw new Error('Failed to update script and stylesheet paths in TBGC_Receiving_ControlAddin.al.');
}

writeFileSync(controlAddInPath, updatedControlAddIn, 'utf8');

console.log(`Updated control add-in asset paths:
  Scripts = '${scriptPath}'
  StyleSheets = '${stylePath}'`);
