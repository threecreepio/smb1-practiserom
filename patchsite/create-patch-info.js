const fs = require('fs');
const original = fs.readFileSync('../original.nes');
const output = fs.readFileSync('../main.nes');
const package = require('./package.json')

 const dbg = fs.readFileSync('../main.nes.dbg')
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
     })
     .filter(v => v.linetype === 'sym' && v.type === 'lab')
     .filter(v => /^BANK_/.test(v.name))
     .map(v => ({ name: v.name, value: [ Number(v.val) & 0xFF, Number(v.val) >> 8 ] }));

// find every diffed byte in the smb1 prg rom
const diff = [];
for (let i=0x10; i<0x8010; ++i) {
    if (output[i] !== original[i]) {
        diff.push([i, original[i], output[i] ]);
    }
}

const prgstart = 0x10 + (0x0E * 0x4000);
const prgend = 0x10 + (0x10 * 0x4000);

fs.writeFileSync('./diff.json', JSON.stringify({
    version: package.version.replace('(\d+\.\d+)\..*', '$1'),
    prg: output.slice(prgstart, prgend).toString('base64'),
    patches: diff,
    symbols: dbg,
    settings
}));
