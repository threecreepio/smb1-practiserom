import diff from '../diff-mmc1.json'
import { copy, reportIssue, setResult } from './utils';
import { applyPatches } from './shared';

export async function applyPatchNROM(filename, source, ines) {
    const expectedSize = 0xA010;
    if (source.byteLength !== expectedSize) {
        reportIssue(`Expected ${expectedSize} byte file, found ${source.byteLength}.`, false);
    }

    const output = new Uint8Array(0x10 + (0x10 * 0x4000) + (ines.chr * 0x2000));
    copy(source, output, 0x00);
    copy(diff.segments.PRACTISE_PRG0.code, output, diff.segments.PRACTISE_PRG0.offset);
    copy(diff.segments.PRACTISE_PRG1.code, output, diff.segments.PRACTISE_PRG1.offset);
    copy(diff.segments.PRACTISE_WRAMCODE.code, output, diff.segments.PRACTISE_WRAMCODE.offset);
    copy(diff.segments.PRACTISE_VEC.code, output, diff.segments.PRACTISE_VEC.offset);
    copy(source.slice(0x10 + (ines.prg * 0x4000)), output, diff.segments.SMBCHR.offset);

    // add our practise banking code
    applyPatches(output, diff.patches, diff.segments.SMBPRG.offset - 0x10);
    output[0x4] = 0x10; // set 16 prg pages
    output[0x6] = (output[0x6] & 0b00001111) | 0b00010010; // set MMC1 and enable battery wram
    
    reportIssue('Patch applied.');
    setResult(filename, output);
    return true;
}
