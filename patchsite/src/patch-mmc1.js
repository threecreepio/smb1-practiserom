import diff from '../diff-mmc1.json'
import { copy, reportIssue, setResult } from './utils';
import { applyPatches, searchReplace } from './shared';

export async function applyPatchMMC1(filename, source, ines) {
    if (ines.prg >= 0x10)  {
        reportIssue("This file is already too large, can't add practise code. Sorry. :(", false);
        return false;
    }

    searchReplace(source, [
        {
            // replace "STA $E000; LSR A" with "JMP BANK_STORE_RTS; RTS"
            warning: 'found bank switching code, attempting to correct',
            search: [0x8D, 0x00, 0xE0, 0x4A],
            replace: [0x4C, ...(diff.symbols.BANK_STORE_RTS.value), 0x60]
        }
    ]);

    for (let prg = 0; prg < ines.prg; ++prg) {
        const ofs = 0x10 +  (0x4000 * prg);
        const smbprg = diff.segments.SMBPRG;
        const prefix = Buffer.from(source.slice(ofs, ofs + (smbprg.PRG0.length / 2))).toString('hex');
        if (prefix === smbprg.PRG0) {
            reportIssue(`Patching PRG ${prg}`);
            applyPatches(source, diff.patches, ofs - 0x10);
        }
    }

    const output = new Uint8Array(0x10 + (0x10 * 0x4000) + (ines.chr * 0x2000));
    copy(source, output, 0x00);
    copy(diff.segments.PRACTISE_PRG0.code, output, diff.segments.PRACTISE_PRG0.offset);
    copy(diff.segments.PRACTISE_PRG1.code, output, diff.segments.PRACTISE_PRG1.offset);
    copy(diff.segments.PRACTISE_WRAMCODE.code, output, diff.segments.PRACTISE_WRAMCODE.offset);
    copy(diff.segments.PRACTISE_VEC.code, output, diff.segments.PRACTISE_VEC.offset);
    copy(source.slice(0x10 + (ines.prg * 0x4000)), output, diff.segments.SMBCHR.offset);


    output[0x4] = 0x10; // set 16 prg pages
    output[0x6] = (output[0x6] & 0b00001111) | 0b00010010; // set MMC1 and enable battery wram

    reportIssue('Patch applied.');
    setResult(filename, output);
    return true;
}
