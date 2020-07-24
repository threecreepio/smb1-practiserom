import diff from '../diff.json'
import { reportIssue, base64Decode, parseINES } from './utils';

export async function applyPatchNROM(filename, source, ines) {
    const expectedSize = 0xA010;
    if (source.byteLength !== expectedSize) {
        reportIssue(`Expected ${expectedSize} byte file, found ${source.byteLength}.`, false);
    }

    const practiseprg = base64Decode(diff.prg);
    const output = new Uint8Array(0x10 + (0x10 * 0x4000) + (ines.chr * 0x2000));
    const outputchr = 0x10 + (0x10 * 0x4000);

    for (const [ fileofs, original, replacement ] of diff.patches) {
        if (original !== source[fileofs]) {
            reportIssue(`${fileofs.toString(16)}: found ${source[fileofs].toString(16)}, expected ${original.toString(16)}.`, false);
        }
        source[fileofs] = replacement;
    }

    // copy source prg + chr into place
    for (let i=0; i < 0x8010; ++i) {
        output[i] = source[i];
    }
    for (let i=0; i<source.byteLength-0x8010; ++i) {
        output[i + outputchr] = source[i + 0x8010];
    }

    output[0x4] = 0x10; // set 16 prg pages
    output[0x6] |= 0b00010010; // set MMC1 and enable battery wram
    for (let i=0; i<0x8000; ++i) {
        const destination = i + (0x4000 * 0x0E) + 0x10;
        output[destination] = practiseprg[i];
    }
    reportIssue('Patch attempt completed, test it out.');

    window.downloadPatch = () => {
        var file = new Blob([output], { type: 'octet/stream' })
        var url = URL.createObjectURL(file);

        var link = document.createElement('a');
        link.download = filename.replace('.nes', ' Practise.nes');
        link.href = url;
        link.click();

        URL.revokeObjectURL(url);
    }

    return true;
}
