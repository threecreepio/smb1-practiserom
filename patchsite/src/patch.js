import { applyPatchNROM } from './patch-nrom';
import { parseINES, reportIssue } from './utils';

export async function applyPatch(filename, source) {
    const ines = parseINES(source);
    if (!ines) {
        reportIssue("Yeah so that doesn't even look an NES rom to me, patching failed.", false);
        return false;
    }
    if (ines.mapper === 0) {
        return await applyPatchNROM(filename, source, ines);
    } else {
        reportIssue("Could not recognize mapper, patching failed.", false);
        return false;
    }
}