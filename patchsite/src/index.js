import { applyPatch } from './patch';
import diff from '../diff.json';

document.getElementById('version').innerHTML = diff.version ? ` - v${diff.version}` : '';

const downloadButton = document.getElementById('downloadbutton');
downloadButton.addEventListener('click', () => { window.downloadPatch(); })

const fileInput = document.getElementById('file');
fileInput.addEventListener('change', async function () {
  downloadButton.setAttribute('disabled', true);
  document.getElementById('warnings').innerText = '';
  const selectedFile = fileInput.files[0];
  const name = selectedFile.name;
  const source = new Uint8Array(await selectedFile.arrayBuffer());
  if (await applyPatch(name, source) !== false) {
    downloadButton.removeAttribute('disabled');
  }
});

