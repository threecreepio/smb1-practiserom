import diff from '../diff.json'
import { reportIssue, base64Decode, parseINES } from './utils';

export async function applyPatchMMC1(filename, source, ines) {
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
            replace: [0x4C, ...(diff.symbols.find(v => v.name === 'BANK_STORE_RTS').value), 0x60]
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
}
