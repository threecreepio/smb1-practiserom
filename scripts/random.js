const FRAMES_PER_FRAMERULE = 21;

const init = () => [0xA5, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00]
const advance = (seed) => {
	let carry = !!((seed[0] & 0b00000010) ^ (seed[1] & 0b00000010));
	let result = Array.from(seed);
	for (let i=0; i<seed.length; ++i) {
		let ncarry = !!(seed[i] & 0b00000001);
		result[i] = (result[i] >> 1) | (carry ? 0b10000000 : 0);
		carry = ncarry;
	}
	return result;
}


function printResumeData() {
	let seed = init();
	const seeds = [];
	
	// advance rng to the start of the level
	for (let i=0; i<18; ++i) seed = advance(seed);

	for (let i=0; i<99; ++i) {
		seeds.push(seed);
		for (j=0; j<(100 * FRAMES_PER_FRAMERULE); ++j)
			seed = advance(seed);
	}

	for (let i=0; i<seed.length; ++i) {
		const bytes = seeds.map(s => `$${s[i].toString('16').padStart(2, '0')}`).join(', ');
		console.log(`resume_${i}: .byte ${bytes}`);
	}
}

function printSeedFrames(seedtxt) {
	const seedhex = Buffer.from(seedtxt, 'hex').toString('hex');
	const needle = Array.from(Buffer.from(seedtxt, 'hex'));
	let seed = init();
	for (let i=0; i<=0x2FFFF; i+=1) {
		if (-1 === seed.findIndex((v, i) => needle[i] !== v)) {
			let framerule = (i / 21) | 0;
			let offset = (i % 21) | 0;
			console.log(`seed ${seedhex} found on frame ${i.toString().padStart(6)}, framerule ${framerule.toString().padStart(4)}, offset ${offset.toString().padStart(2)}.`);
		}
		seed = advance(seed);
	}
}


printResumeData();
//printSeedFrames('0B0F1907353B51');
