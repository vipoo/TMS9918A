; Nyan Cat for RC2014 with TMS9918 and YM2149
; Hand-written assembly by J.B. Langston
; Images and music from Nyan Cat for MSX: https://www.msx.org/news/en/nyan-cat-msx

                org $0100

usenmi:         equ 0                   ; whether to use NMI or IRQ

im1vect:        equ $38                 ; location of IM1 vector
nmivect:        equ $66                 ; location of NMI vector
frameticks:     equ 3                   ; number of interrupts per animation frame
framecount:     equ 12                  ; number of frames in animation
bdos:           equ 5

start:
	LD	HL, (6)			; TOP OF TPA
	LD	SP, HL			; MAKE THAT THE STACK

        ld      de, music               ; initialize player
        call    PLY_Init
        ld      a, frameticks           ; initialize interrupt counter to frame length
        ld      (tickcounter), a
        ld      hl, inthandler          ; install the interrupt handler
if      usenmi
        call    nmisetup
else
        call    im1setup
endif
        call    tmsmulticolor           ; initialize tms for multicolor mode
        ld      a, tmsdarkblue          ; set background color
        call    tmsbackground
        call    tmsintenable            ; enable interrupts on TMS
mainloop:
        ld      a, 1
        ld      (syncready),a
waitloop:
        halt
        ld      a, (syncready)
        or      a
        jr      nz, waitloop
        call    drawframe

        ld      c,$6                            ; check for char at console
        ld      e,0FFh
        call    bdos
        cp      65

        jr      nz, mainloop                ; busy wait and let interrupts do their thing
        rst     0


; set up interrupt mode 1 vector
;       HL = interrupt handler
im1setup:
        di
	ld      a, $C3                  ; prefix with jump instruction
	ld      (im1vect), a
        ld      (im1vect+1), hl         ; load interrupt vector
	im      1                       ; enable interrupt mode 1
        ei
        ret

; set up NMI vector
;       HL = interrupt handler
nmisetup:
	ld      a, $C3                  ; prefix with jump instruction
	ld      (nmivect), a
        ld      (nmivect+1), hl         ; load interrupt vector
        ret

; interrupt handler: rotate animation frames
inthandler:
        push    af
	di
        ld      a, 0
        ld      (syncready), a
        in      a, (tmsreg)             ; clear interrupt flag
	pop	af
        ei

if      usenmi
        retn
else

        reti
endif

tickcounter:
        defb    0                       ; interrupt down counter
currframe:
        defb    0                       ; current frame of animation

syncready:
        defb    0

; draw a single animation frame
;       HL = animation data base address
;       A = current animation frame number
drawframe:
        ld      a, (tickcounter)        ; check if we've been called frameticks times
        or      a
        jr      nz, framewait           ; if not, wait to draw next animation frame
        ld      hl, animation           ; draw the current frame
        ld      a, (currframe)          ; calculate offset for current frame
        ld      d, a                    ; x 1
        add     a, d                    ; x 2
        add     a, d                    ; x 3
        add     a, a                    ; x 6
        ld      d, a                    ; offset = frame x 600h
        ld      e, 0
        add     hl, de                  ; add offset to base address
        ld      de, $0000               ; pattern table address in vram
        ld      bc, $0600               ; length of one frame
        call    tmswrite                ; copy frame to pattern table
        ld      a, (currframe)          ; next animation frame
        inc     a
        cp      framecount              ; have we displayed all frames yet?
        jr      nz, skipreset           ; if not, display the next frame
        ld      a, 0                    ; if so, start over at the first frame
skipreset:
        ld      (currframe), a          ; save next frame in memory
        ld      a, frameticks           ; reset interrupt down counter
        ld      (tickcounter), a
        ret
framewait:
        ld      hl, tickcounter          ; not time to switch animation frames yet
        dec     (hl)                    ; decrement down counter
        ret

	include "arkos.asm"     ; Arkos player
	include "tms.asm"       ; TMS graphics routines


; Change included binary for different cat
animation:
                ; change incbin to binary for z88dk
                BINARY  "nyan/nyan.bin"      ; The Classic
                ;incbin "nyan/nyands.bin"    ; Skrillex?
                ;incbin "nyan/nyanfi.bin"    ; Finland
                ;incbin "nyan/nyangb.bin"    ; Gameboy
                ;incbin "nyan/nyanlb.bin"    ; France
                ;incbin "nyan/nyann1.bin"    ; France
                ;incbin "nyan/nyann2.bin"    ; Hmm... France, and cheese, ...and bananas?
                ;incbin "nyan/nyanus.bin"    ; USA
                ;incbin "nyan/nyanxx.bin"    ; Party Hat


music:
                ; change incbin to binary for z88dk
                BINARY  "nyan/music.bin"     ; music data
