const fs = require('fs');
const path = require('path');

for (const file of fs.readdirSync('./graphics')) {
    if (path.extname(file) !== '.json') continue;
    const data = require(`./graphics/${file}`);
    if (data.type !== 'map') continue;
    
    const newname = `${path.basename(file, '.json')}.bin`;
    // tiled uses byte 0 for unused tiles and offsets all the tiles by 1.
    // so we offset them back to where they should be.. and any unused tiles we set to space characters.
    const bin = Buffer.from(data.layers[0].data.map(v => (v || 0x25) - 1));
    console.log(`saving ${newname}`)
    fs.writeFileSync(`./graphics/${newname}`, bin);
}