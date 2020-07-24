MMC1 = %00010000
BATTERY = %00000010
VERTICAL_MIRROR = %00000001

.segment "INES"
	.byte "NES",$1A
	.byte 16 ; prg
	.byte 1  ; chr
	.byte MMC1 | BATTERY | VERTICAL_MIRROR

.segment "SMBCHR"
.incbin "smb.chr"
