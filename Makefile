AS = ca65
CC = cc65
LD = ld65
IPS = flips.exe

.PHONY: clean

%.o: %.asm
	$(AS) --create-dep "$@.dep" --listing "$@.lst" -g --debug-info $< -o $@

main.nes: layout main.o title/title.o smb.o
	$(LD)  --dbgfile "$@.dbg" -C $^ -o $@

clean:
	rm -f ./main*.nes ./*.nes.dbg ./*.o ./*.dep ./*/*.o ./*/*.dep

include $(wildcard ./*.dep ./*/*.dep)
