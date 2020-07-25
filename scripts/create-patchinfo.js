const fs = require('fs');
const original = fs.readFileSync('original.nes');
const output = fs.readFileSync(process.argv[2]);

 const dbginfo = fs.readFileSync(process.argv[2] + '.dbg')
     .toString()
     .split('\n')
     .map(l => {
         const linetype = l.replace(/\t.*/, '');
         const obj = { linetype };
         for (const pair of l.replace(/.*\t/, '').split(',')) {
             const [key, value] = pair.split('=', 2);
             obj[key] = value && value.replace(/^"(.*?)"$/, '$1');
         }
         return obj;
     });

// find where in the file all the segments have been placed
const segments = dbginfo
     .filter(v => v.linetype === 'seg' && v.ooffs !== undefined)
     .map(v => ({ name: v.name, start: Number(v.start), offset: Number(v.ooffs), size: Number(v.size) }))
     .reduce((ht, v) => { ht[v.name] = v; return ht; }, {});

// find symbols that we may need to use while patching
const symbols = dbginfo
     .filter(v => v.linetype === 'sym' && (v.type === 'equ' || v.type === 'lab') && v.val)
     .filter(v => /BANK_|PATCHER_/.test(v.name))
     .map(v => ({ name: v.name, val: Number(v.val), value: [ Number(v.val) & 0xFF, Number(v.val) >> 8 ] }))
     .reduce((ht, v) => { ht[v.name] = v; return ht; }, {});

// find every diffed byte in the smb1 prg rom
const patches = [];
for (let i=0; i<segments.SMBPRG.size; ++i) {
    const at = segments.SMBPRG.offset +  i;
    if (output[at] !== original[0x10 + i]) {
        patches.push([i, original[0x10 + i], output[at] ]);
    }
}

for (const name of Object.keys(segments)) {
    const seg = segments[name];
    if (/PRACTISE_/.test(name)) {
        seg.code = Array.from(output.slice(seg.offset, seg.offset + seg.size));
    }
}

segments.SMBPRG.PRG0 = output.slice(segments.SMBPRG.offset + 0x0000, segments.SMBPRG.offset + 0x0010).toString('hex');
segments.SMBPRG.PRG1 = output.slice(segments.SMBPRG.offset + 0x4000, segments.SMBPRG.offset + 0x4010).toString('hex');

console.log(JSON.stringify({
    version: '0.2.0',
    patches: patches,
    symbols: symbols,
    segments,
    size: output.byteLength
}, null, 4));
