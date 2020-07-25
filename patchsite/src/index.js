import { applyPatch } from './patch';

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

