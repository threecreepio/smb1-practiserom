AS = ca65
CC = cc65
LD = ld65

.PHONY: clean
build: patchsite/diff-mmc1.json patchsite/diff-greated.json

%.o: %.asm
	$(AS) --create-dep "$@.dep" --listing "$@.lst" -g --debug-info $< -o $@

patchsite/diff-mmc1.json: main-mmc1.nes
	node ./scripts/create-patchinfo.js main-mmc1.nes > "$@"

patchsite/diff-greated.json: main-greated.nes
	node ./scripts/create-patchinfo.js main-greated.nes > "$@"

main-mmc1.nes: layout-mmc1 title/boot-mmc1.o smb.o
	$(LD)  --dbgfile "$@.dbg" -C $^ -o $@

main-greated.nes: layout-greated title/boot-greated.o smb.o
	$(LD)  --dbgfile "$@.dbg" -C $^ -o $@

clean:
	rm -f ./main*.nes ./*.nes.dbg ./*.o.lst ./*.o ./*.dep ./*/*.o ./*/*.dep

include $(wildcard ./*.dep ./*/*.dep)
