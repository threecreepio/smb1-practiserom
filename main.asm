.segment "INES"
	.byte "NES",$1A
	.byte 4 ; prg
	.byte 1 ; chr
	.byte $11

.segment "SMBCHR"
.incbin "smb.chr"
