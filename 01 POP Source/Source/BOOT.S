*  boot
org = $800
 lst off
*-------------------------------
* $800 TS (0,0) boot sector

SLOT = $2b
sector = $50

text = $fb2f
home = $fc58
vtab = $FB5B
cout = $FDF0
normal = $fe84
pr0 = $fe93
in0 = $fe89

*-------------------------------
 org org

 hex 01                                        ; FCS Instruct ROM Boot to load 1 sector from the current positon (T=0,S=0 )at $800

entry lda #$60
 sta entry                                     ; patch $801 with instruction RTS (Hex code RTS = $60)
                                               ; this will avoid going through the following
                                               ; code again after a new sector was loaded
                                               ; as the slot rom always jumps to address $801.
                                               ; Now it will hit the RTS instruction there
                                               ; and thus return to the JSR call at .rdsect instead.

 lda #$ff
 sta $4fb
 sta $3f3
 sta $3f4
 sta $c000 ;80store off
 sta $c002 ;RAMRD main
 sta $c004 ;RAMWRT main
 sta $c00c ;80col off
 sta $c00e ;Altcharset off
 sta $c081 ;write RAM, read ROM (2nd 4k bank)
                                               ; http://apple2.org.za/gswv/USA2WUG/FOUNDING.MEMBERS/HOME.PAGES/EDHEL/texts/pokes.html
 jsr text                                      ; Clears Hi-res screen, Lo-res screen, and accumulator 
 jsr home                                      ; Clear screen and set cursor to left corner
 jsr normal                                    ; set ROM cout routine to print normal characters
 jsr pr0                                       ; set cout to print on text screen
 jsr in0                                       ; set cin to read from the keyboard (http://mirrors.apple2.org.za/ground.icaen.uiowa.edu/Collections/1WSW/MEGA.PEEKS.AND.POKES.html)

 ldx SLOT                                      ; x <- $2b
 txa                                           ; a <- x
 lsr                                           ; Logical Shift Right
 lsr                                           ; Logical Shift Right
 lsr                                           ; Logical Shift Right
 lsr                                           ; Logical Shift Right
 ora #$c0                                      ; bitwise OR with Accumulator: if the boot sector was loaded from slot #6 this will yield $c6
 sta :rdsect+2                                 ; patch the address high byte of the JSR instruction
 lda #$0f
 sta sector                                    ; read sectors 15 down to 1

                                               ; read sector loop

:0 ldy sector                                  ; Counter is in page 0 at $05. Count remaining sectors to load
 lda skewtbl,y                                 ; skewing look-up table. Also known as interleave
                                               ; see: "http://en.wikipedia.org/wiki/Interleaving" for more detail on that
 sta $3d                                       ; sector number
                   
 lda sectaddr,y                                ; if 0 then skip this sector
 beq :1
 sta $27                                       ; high byte of load address
:rdsect jsr $005c                              ; this instruction will be patched
                                               ; If the slot is #6 this instruction will become
                                               ; JSR $c65c
                                               ; At this address the slot rom will load another disk sector
:1 dec sector                                  ; sector counter--
 bne :0

 lda SLOT
 jmp $900                                      ; Jump to boot stage2. A ds directive makes sure stage2 is at $900

skewtbl hex 00,0d,0b,09,07,05,03,01            ; This is a standard DOS skewing table
 hex 0e,0c,0a,08,06,04,02,0f

sectaddr hex 00,09,00,00,00,00,00,00           ; These are the addresses (high byte) where the sectors are loaded
 hex 30,31,32,33,34,00,00,00






*===============================
*  boot stage 2

rw18 = $d000

slot = $fd
track = $fe
lastrack = $ff

 dum $00

dest ds 2
source ds 2
endsourc ds 2

 dend
*-------------------------------
 ds $900-*

stage2 stx slot

 jsr check128k ;check for 128K memory

 jsr moverw18 ;& move RW18 to D000

 lda #0
 sta lastrack
 sta $3f3
 sta $3f4 ;zero reset vector

 jsr rw18
 hex 07,a9 ;Bbund ID byte

 jsr rw18
 hex 00,01,00 ;drive 1 on

 jsr rw18 ;seek track 1
 hex 02,00,01

* load & run stage 3 boot
* from drive 1

 jsr rw18
 hex c3,ee

 jmp $ee00

*-------------------------------------------------
* Check for AUX memory routine

CHECKER lda #$EE
 sta $C005
 sta $C003
 sta $0800
 lda $0C00
 cmp #$EE
 bne :0
 asl $0C00
 lda $0800
 cmp $0C00
 beq :1
:0 clc
:1 sta $C004
 sta $C002
 rts

CHECKEND = *-CHECKER

*-------------------------------------------------
*
* Check to make sure //c or //e
* with 128k
*
*-------------------------------
check128k
 sta $c081

 lda $FBB3 ;Apple // family ID byte
 cmp #6
 bne NOT128K ;Must be e/c/GS

 bit $C017
 bmi NOT128K

 ldx #CHECKEND
:0 lda CHECKER,X
 sta $180,X
 dex
 bpl :0

 jsr $180
 bcs NOT128K

 rts

*-------------------------------
* Turn off drive and display message

NOT128K ldx SLOT
 lda $C088,X

 jsr text
 jsr home
 lda #8
 jsr vtab

 ldy #0
:0 lda MEMTEXT,Y
 beq *
 jsr cout
 cmp #$8D
 bne :1
 lda #4
 sta $24
:1 iny
 bne :0

MEMTEXT hex 8D
 asc "REQUIRES A //C OR //E WITH 128K"
 hex 00

*-------------------------------
* Move RW18
* d0 < 30.40
*-------------------------------
moverw18
 bit $c08b
 bit $c08b ;rd/wrt RAM, 1st 4k bank

 lda #$d0
 ldx #$30
 ldy #$40

* a < x.y
* 20 < 40.60 means 2000 < 4000.5fffm
* WARNING: If x >= y, routine will wipe out 64k

movemem sta dest+1
 stx source+1
 sty endsourc+1

 ldy #0
 sty dest
 sty source
 sty endsourc

:loop lda (source),y
 sta (dest),y

 iny
 bne :loop

 inc source+1
 inc dest+1

 lda source+1
 cmp endsourc+1
 bne :loop

 rts

*-------------------------------
 sav boot
