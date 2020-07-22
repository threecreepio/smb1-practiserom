import { applyPatchNROM } from './patch-nrom';

export async function applyPatch(filename, source) {
    return await applyPatchNROM(filename, source);
}