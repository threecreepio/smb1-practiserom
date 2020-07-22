import diff from './diff.json'

document.getElementById('version').innerHTML = diff.version ? ` - v${diff.version}` : '';

let download = null;
const downloadButton = document.getElementById('downloadbutton');
downloadButton.addEventListener('click', () => { download(); })

const fileInput = document.getElementById('file');
fileInput.addEventListener('change', applyPatch);

async function applyPatch() {
    downloadButton.setAttribute('disabled', true);
    document.getElementById('warnings').innerText = '';
    
    const expectedSize = 0xA010;
    const selectedFile = fileInput.files[0];
    const source = new Uint8Array(await selectedFile.arrayBuffer());
    const output = base64Decode(diff.base);
    
    if (source.byteLength !== expectedSize) {
        reportIssue(`Expected file to be ${expectedSize} bytes, but it was ${source.byteLength}, this patch will NOT work.`);
    }

    for (let i=0; i<diff.copy.length; ++i) {
        const c = diff.copy[i];
        for (let b=0; b<c.len; ++b) {
            output[c.dest + b] = source[c.origin + b];
        }
    }
    
    for (let i=0; i<diff.patches.length; ++i) {
        const [ offset, original, replacement ] = diff.patches[i];
        if (original !== output[offset]) {
            reportIssue(`Found ${output[offset].toString(16)} at offset ${offset.toString(16)}, expected ${original.toString(16)}.`);
        }
        output[offset] = replacement;
    }

    const max_worlds = output[0x6a27];
    let prev = 0, levelcount = 0xFF;
    for (let i=1; i<max_worlds; ++i) {
        let count = (output[0x1CC4 + i]) - prev;
        levelcount = Math.min(count, levelcount);
        prev += count;
    }

    reportIssue(`Found ${(1 + max_worlds)} worlds.`);
    output[0x8017] = max_worlds + 1;
    
    reportIssue(`Found ${(levelcount)} levels per world.`);
    output[0x8018] = levelcount;

    /*
    for (let i=0; i<diff.settings.length; ++i) {
        const set = diff.settings[i];
        if (output[set.dst] !== output[set.src]) {
            reportIssue(`Setting ${set.name} to ${output[set.src]} (from ${output[set.dst]}).`);
            output[set.dst] = output[set.src];
        }
    }
    */

    reportIssue('Finished applying patch.');
    downloadButton.removeAttribute('disabled');

    download = () => {
        var file = new Blob([output], { type: 'octet/stream' })
        var url = URL.createObjectURL(file);

        var link = document.createElement('a');
        link.download = selectedFile.name.replace('.nes', ' Practise.nes');
        link.href = url;
        link.click();

        URL.revokeObjectURL(url);
    }
}


function reportIssue(text) {
    const el = document.getElementById('warnings');
    el.innerText += text + '\n';
}


function base64Decode(base64) {
  var decoded = window.atob(base64);
  const bin = new Uint8Array(decoded.length);
  for (let i=0; i<decoded.length; ++i) {
    bin[i] = decoded.charCodeAt(i);
  }
  return bin;
}


