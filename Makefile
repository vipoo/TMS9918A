
ASSEMBLER=z80asm
ASSFLAGS=-b

%.com: %.asm
	$(ASSEMBLER) -o$@ $(ASSFLAGS) $<

nyan.com: nyan.asm
