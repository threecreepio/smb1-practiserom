import diff from '../diff-mmc1.json'
import { copy, reportIssue, setResult } from './utils';
import { applyPatches } from './shared';

export async function applyPatchMMC1(filename, source, ines) {
    if (ines.prg >= 0x10)  {
        reportIssue("This file is already too large, can't add practise code. Sorry. :(", false);
        return false;
    }

    const searchreplace = [
        {
            // replace "STA $E000; LSR A" with "JMP BANK_STORE_RTS; RTS"
            warning: 'found bank switching code, attempting to correct',
            search: [0x8D, 0x00, 0xE0, 0x4A],
            replace: [0x4C, ...(diff.symbols.BANK_STORE_RTS.value), 0x60]
        }
    ];
    for (let i=0; i<source.byteLength; ++i) {
        outer: for (const n of searchreplace) {
            for (let j=0; j<n.search.length; ++j) {
                if (n.search[j] !== source[i + j]) continue outer;
            }
            if (n.warning) reportIssue(`${(i).toString(16)}: ${n.warning}`, false);
            for (let j=0; j<n.search.length; ++j) {
                source[i + j] = n.replace[j] || 0xFF;
            }
        }
    }

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
    output[0x6] |= 0b00010010; // set MMC1 and enable battery wram

    reportIssue('Patch applied.');
    setResult(filename, output);
    return true;
    /*

    const practiseprg = base64Decode(diff.prg);
    const output = new Uint8Array(0x10 + (0x10 * 0x4000) + (ines.chr * 0x2000));
    const outputchr = 0x10 + (0x10 * 0x4000);
    const endofprg = 0x10 + (0x4000 * ines.prg);
    
    const prg1Head = "78d8a9108d0020a2ff9aad022010fbad";
    const prg2Head = "6900959fc5023010bd3304c9809009a5";
    const foundPRGs = [[], []];
    for (var i=0; i<ines.prg; i += 1) {
        var start = 0x10 + (i * 0x4000);
        const head = Buffer.from(source.slice(start, start + 0x10)).toString('hex')
        if (head === prg1Head) {
            foundPRGs[0].push(i);
        } else if (head === prg2Head) {
            foundPRGs[1].push(i);
        } else {
            reportIssue("Found unknown code bank", false);
        }
    }

    if (foundPRGs[0].length === 0) {
        reportIssue("Could not find SMB1 PRG1, sorry", false);
        return
    }
    
    if (foundPRGs[1].length === 0) {
        reportIssue("Could not find SMB1 PRG2, sorry", false);
        return
    }

    for (let i=0; i<diff.patches.length; ++i) {
        const [ offset, original, replacement ] = diff.patches[i];
        const bank = ((offset - 0x10) / 0x4000) | 0;
        const bankofs = ((offset - 0x10) % 0x4000);
        const banks = foundPRGs[bank] || [];
        
        for (const bankidx of banks) {
            const fileofs = 0x10 + (bankidx * 0x4000) + bankofs;
            if (original !== source[fileofs]) {
                reportIssue(`${fileofs.toString(16)}: found ${source[fileofs].toString(16)}, expected ${original.toString(16)}.`, false);
            }
            source[fileofs] = replacement;
        }
    }

    const searchreplace = [
        {
            // replace "STA $E000; LSR A" with "JMP BANK_STORE_RTS; RTS"
            warning: 'bank switching code, attempting to correct',
            search: [0x8D, 0x00, 0xE0, 0x4A],
            replace: [0x4C, ...(diff.symbols.BANK_STORE_RTS), 0x60]
        }
    ];
    for (let i=0; i<source.byteLength; ++i) {
        outer: for (const n of searchreplace) {
            for (let j=0; j<n.search.length; ++j) {
                if (n.search[j] !== source[i + j]) continue outer;
            }
            if (n.warning) reportIssue(`${(i).toString(16)}: ${n.warning}`, false);
            for (let j=0; j<n.search.length; ++j) {
                source[i + j] = n.replace[j] || 0xFF;
            }
        }
    }

    // copy source prg + chr into place
    for (let i=0; i < endofprg; ++i) {
        output[i] = source[i];
    }
    for (let i=0; i<source.byteLength-endofprg; ++i) {
        output[i + outputchr] = source[i + endofprg];
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
    */
}
