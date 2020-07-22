const fs = require('fs');

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
    .filter(v => v.linetype === 'sym');

const original = fs.readFileSync('../original.nes');
const output = fs.readFileSync('../main.nes');

// find all marked settings to copy from the rom
let settings = [];
const scopeofs = [0x0, 0x10, -0x8000]
for (let i=0; i<dbg.length; ++i) {
    const match = dbg[i].name.match(/^PCOPY_(.*?)_SRC/);
    if (!match) continue;
    const src = dbg[i];
    const srcat = Number(src.val) + scopeofs[Number(src.scope)];
    const dst = dbg.find(l => l.name === `PCOPY_${match[1]}_DST`);
    const dstat = Number(dst.val) + scopeofs[Number(dst.scope)];
    console.log(`${src.name} at ${src.val.toString(16)} is ${output[srcat]}.`);
    settings.push({ name: match[1], src: srcat, dst: dstat, original: output[srcat] });
}


// find every diffed byte in the smb1 prg rom
const diff = [];
for (let i=0x10; i<0x8010; ++i) {
    if (output[i] !== original[i]) {
        diff.push([i, original[i], output[i] ]);
    }
}

for (let i=0x10; i<0x8010; ++i) output[i] = 0xFF;
for (let i=0x10 + 0x8000 + 0x8000; i<output.byteLength; ++i) output[i] = 0xFF;

fs.writeFileSync('./diff.json', JSON.stringify({
    base: output.toString('base64'),
    patches: diff,
    settings,
    copy: [
        { origin: 0x10, len: 0x8000, dest: 0x10 },
        { origin: 0x8010, len: 0x2000, dest: 0x10 + 0x8000 + 0x8000 }
    ]
}));
