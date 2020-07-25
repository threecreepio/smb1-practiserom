import diff from '../diff-greated.json'
import { reportIssue, copy, setResult, expect } from './utils';
import { applyPatches } from './shared';

export async function applyPatchGreatEd(filename, source, ines) {
    const output = new Uint8Array(source.byteLength + 0x4000);
    copy(source, output, 0x00);
    copy(diff.segments.PRACTISE_PRG0.code, output, diff.segments.PRACTISE_PRG0.offset);
    copy(diff.segments.PRACTISE_WRAMCODE.code, output, diff.segments.PRACTISE_WRAMCODE.offset);
    copy(source.slice(0x1C010), output, 0x1C010 + 0x4000);

    // add our practise banking code
    applyPatches(output, diff.patches, diff.segments.SMBPRG.offset - 0x10);

    // banking code
    {
        const start = 0x10 + 0x23F6D;
        expect(output.slice(start - 5), [0x7f, 0xa8, 0xb9, 0x80, 0x9f, 0x8d]);
        const newLBanking1 = output[start + 1];
        const newLBanking2 = output[start + 2];
        reportIssue(`Level banking RAM appears to be at ${newLBanking2.toString('16').padStart(2, '0')}${newLBanking1.toString('16').padStart(2, '0')}.`, true);
        const levelbankLocation = diff.symbols.PATCHER_LDA_LEVELBANK.val;
        const baseLocation = diff.segments.PRACTISE_WRAMCODE.offset + (levelbankLocation - diff.segments.PRACTISE_WRAMCODE.start);
        output[baseLocation + 1] = newLBanking1;
        output[baseLocation + 2] = newLBanking2;
    }

    output[0x4] += 1; // add 1 PRG
    output[0x6] |= 0b10; // enable battery
    
    // relocate GreatEd NMI
    expect(output.slice(0x10 + 0x23FE3), [0x82, 0x80, 0x78, 0xa9, 0x00, 0x20]);
    output[0x10 + 0x23FE3] = diff.symbols.BANK_GAME_NMI.value[0];
    output[0x10 + 0x23FE4] = diff.symbols.BANK_GAME_NMI.value[1];

    // replace reset handlers banking code to load us in at $8000
    output[0x10 + 0x23FE7] = 0xE;

    reportIssue('Patch applied.');
    setResult(filename, output);
    return true;
}
