import sys
import binascii
import re
FRAMERULE_FRAMES=21 # NTSC

# snagged from pellsson :)

def _ror(val, carry):
	next_carry	= bool(val & 1)
	val			= (val >> 1)
	if carry:
		val |= 0x80
	return val, next_carry

def random_init():
	return [ 0xA5 ] + ([ 0 ] * 6)

def random_advance(seed):
	carry = bool((seed[0] & 0x02) ^ (seed[1] & 0x02))
	for i in range(0, len(seed)):
		seed[i], carry = _ror(seed[i], carry)
	return seed

def locate_seed_frame(needle):
	print("---")
	needle_ary = list(map(int, bytearray.fromhex(re.sub("[^0-9a-fA-F]", "", needle))))
	seed = random_init()
	for i in range(0, 200000):
		rule = int(i / FRAMERULE_FRAMES)
		off = int(i % FRAMERULE_FRAMES)
		#print('seed ' + ''.join('{:02X}'.format(x) for x in seed) +  (' found on frame: %d, framerule: %d, framerule offset: %d' % (i, rule, off)))
		if seed == needle_ary:
			print('found on frame: %d, framerule: %d, framerule offset: %d' % (i, rule, off))
		seed = random_advance(seed)

def print_resume_data():
    seed = random_init()
    sets = [[],[],[],[],[],[],[]]
    for i in range(0, 18):
        seed = random_advance(seed)
    #;for _ in range(0, (100 * FRAMERULE_FRAMES)): # - 147):
    #    seed = random_advance(seed)
    for base_i in range(0, 99):
        for i in range(0, len(seed)):
            sets[i].append(seed[i])
        for _ in range(0, (100 * FRAMERULE_FRAMES)):
            seed = random_advance(seed)
    for i in range(0, len(sets)):
        print('resume_' + str(i) + ': .byte ' + ', '.join('${:02x}'.format(x) for x in sets[i]))


print_resume_data()
locate_seed_frame("0B0F1907353B51") # min starting seed, original rom, frame before level visible
locate_seed_frame("0B0F1907353B51")