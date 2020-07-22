import diff from '../diff.json'
import { reportIssue, base64Decode, parseINES } from './utils';

export async function applyPatchNROM(filename, source) {
    const expectedSize = 0xA010;
    
    if (source.byteLength !== expectedSize) {
        reportIssue(`Bad file size, probably wont work. Got ${source.byteLength.toString(16)} instead of ${expectedSize.toString(16)}.`, false);
    }

    const ines = parseINES(source);
    if (ines === false) {
        reportIssue("Yeah so that doesn't look an NES rom to me.. Sorry.", false);
        return false;
    }

    if (ines.mapper) {
        reportIssue(`Found mapper ${ines.mapper} instead of 0, probably won't work.`, false);
    }

    const baseprg = base64Decode(diff.prg);
    const output = new Uint8Array(source.byteLength + 0x8000);

    const endofprg = 0x10 + (0x4000 * ines.prg);
    
    for (let i=0; i < endofprg; ++i) {
        output[i] = source[i];
    }
    output[0x4] += 2; // add 2 PRGs
    if (ines.mapper === 0) {
        output[0x6] |= 0b00010000; // set MMC1
    }

    for (let i=endofprg; i<endofprg + 0x8000; ++i) {
        output[i] = baseprg[i - endofprg];
    }
    for (let i=endofprg; i<source.byteLength; ++i) {
        output[i + 0x8000] = source[i];
    }

    for (let i=0; i<diff.patches.length; ++i) {
        const [ offset, original, replacement ] = diff.patches[i];
        if (original !== output[offset]) {
            reportIssue(`Offset ${offset.toString(16)} is ${output[offset].toString(16)}, expected ${original.toString(16)}.`, false);
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

    
    reportIssue(`Found ${(1 + max_worlds)} worlds.`, max_worlds > 0 && max_worlds < 16);
    output[0x8017] = max_worlds + 1;
    
    reportIssue(`Found ${(levelcount)} levels per world.`, levelcount > 2 && levelcount < 16);
    output[0x8018] = levelcount;

    reportIssue('Finished applying patch.');

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
