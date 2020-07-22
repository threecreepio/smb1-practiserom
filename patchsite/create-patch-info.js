const fs = require('fs');
const original = fs.readFileSync('../original.nes');
const output = fs.readFileSync('../main.nes');
const package = require('./package.json')

// const dbg = fs.readFileSync('../main.nes.dbg')
//     .toString()
//     .split('\n')
//     .map(l => {
//         const linetype = l.replace(/\t.*/, '');
//         const obj = { linetype };
//         for (const pair of l.replace(/.*\t/, '').split(',')) {
//             const [key, value] = pair.split('=', 2);
//             obj[key] = value && value.replace(/^"(.*?)"$/, '$1');
//         }
//         return obj;
//     })
//     .filter(v => v.linetype === 'sym');
// const scopeofs = [0x0, 0x10, -0x8000]
// find all marked settings to copy from the rom
// let settings = [];
// for (let i=0; i<dbg.length; ++i) {
//     const match = dbg[i].name.match(/^PCOPY_(.*?)_SRC/);
//     if (!match) continue;
//     const src = dbg[i];
//     const srcat = Number(src.val) + scopeofs[Number(src.scope)];
//     const dst = dbg.find(l => l.name === `PCOPY_${match[1]}_DST`);
//     const dstat = Number(dst.val) + scopeofs[Number(dst.scope)];
//     console.log(`${src.name} at ${srcat.toString(16)} is ${output[srcat]}.`);
//     settings.push({ name: match[1], src: srcat, dst: dstat, original: output[srcat] });
// }

const settings = [
    { name: 'MAX_WORLDS', src: 0x6A27, dst: 0x8017, original: 7 },
    { name: 'MAX_LEVELS', src: 0x3305, dst: 0x8018, original: 3 },
];
console.log(JSON.stringify(settings, null, 4));



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
    version: package.version.replace('(\d+\.\d+)\..*', '$1'),
    //base: output.toString('base64'),
    prg: output.slice(0x10 + 0x8000, 0x10 + 0x8000 + 0x8000).toString('base64'),
    patches: diff,
    settings,
    copy: [
        { origin: 0x10, len: 0x8000, dest: 0x10 },
        { origin: 0x8010, len: 0x2000, dest: 0x10 + 0x8000 + 0x8000 }
    ]
}));
