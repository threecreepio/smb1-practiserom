import { reportIssue } from './utils';

export function applyPatches(file, patches, fileOffset) {
    for (let i=0; i<patches.length; ++i) {
        const [ offset, original, replacement ] = patches[i];
        const ofs = 0x10 + offset + fileOffset;
        if (original !== file[ofs]) {
            reportIssue(`mismatch at ${ofs.toString(16).padStart(4, '0')}: found ${file[ofs].toString(16).padStart(2, '0')}, expected ${original.toString(16).padStart(2, '0')}.`, false);
        }
        file[ofs] = replacement;
    }
}