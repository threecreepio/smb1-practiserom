import { applyPatchNROM } from './patch-nrom';
import { applyPatchMMC1 } from './patch-mmc1';
import { applyPatchGreatEd } from './patch-greated';
import { parseINES, reportIssue } from './utils';

export async function applyPatch(filename, source) {
    const ines = parseINES(source);
    if (!ines) {
        reportIssue("Yeah so that doesn't even look an NES rom to me, patching failed.", false);
        return false;
    }

    if (ines.mapper === 0) {
        reportIssue("Found NROM, assuming most of SMB1 is intact.", true);
        return await applyPatchNROM(filename, source, ines);
    }

    if (ines.mapper === 1) {
        reportIssue("Found MMC1, this is bad.. Let's try anyway.", false);
        return await applyPatchMMC1(filename, source, ines);
    }
    
    if (ines.mapper === 4) {
        reportIssue("Found MMC3, assuming a GreatEd hack and let's hope it works out.", false);
        return await applyPatchGreatEd(filename, source, ines);
    }
    
    reportIssue(`Could not recognize mapper ${ines.mapper}, we'll hope it's MMC1-ish but this won't work.`, false);
    return await applyPatchMMC1(filename, source, ines);
}
