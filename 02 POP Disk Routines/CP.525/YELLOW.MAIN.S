* yellow.main
 lst off

* The job of this routine is to
* set the high-bit of $7C in aux zpage.
* (It does it by rotating in a carry set)

                                               ; This is a copy protection check routine which is contained into RYELLOW1.S in
                                               ; scrambled form.  (RYELLOW1.S is in turn included, via `put', by GAMEBG.S or
                                               ; whatever its 5.25" equivalent is.)
                                               ;
                                               ; Googling for the magic bit pattern #$EE #$E7 #$FC #$EE #$E7 #$FC #$EE #$EE #$FC
                                               ; used in the code leads us to
                                               ;
                                               ;   http://textfiles.com/apple/CRACKING/asstcracks1.txt
                                               ;
                                               ; This describes the bit pattern's use in a "bit slip" (a.k.a. "bit insertion")
                                               ; copy protection technique:
                                               ;
                                               ;       / E7   \**/  E7  \/  E7  \*/  E7  \**/  E7  \/  E7  \*/  E7  \*/  E7  \
                                               ;   11101110011100111001111110011101110011100111001111110011101110011101110011111100 
                                               ;   \ EE   / \  E7  /  \  FC  /\   EE / \  E7  /  \  FC  /\  EE  / \  EE  / \  FC  /
                                               ;
                                               ; This suggests strongly that the 5.25" Prince of Persia used this "bit slip" copy
                                               ; protection.  However, the only way to be sure (and to figure out the actual
                                               ; contents of the magic sector) is to get the actual 5.25" disk as well as hardware
                                               ; that can read it.

slot = $fd
lastrack = $ff

*-------------------------------------------------
*
* HLS APPLE COPY PROTECTION
* COPYRIGHT (C) 1987 HLS DUPLICATION
*
* Modified by Roland Gustafsson 8/25/89
* for Prince of Persia copy protection.
*
*-------------------------------------------------

OBJSCT = $07 ;PHYSICAL SECTOR #                ; track 0, sector 7 is where we expect to find the magic bit pattern

* ZERO PAGE

HDRC = $30
HDRS = HDRC+1
HDRT = HDRC+2
HDRV = HDRC+3 HEADER SECTOR
LSRETRY = HDRC+4 ;NIB READ RETRIES
PRETRY = HDRC+5 ;OBJSCT RETRIES
NPTR = HDRC+6
NPTRH = HDRC+7
MEM1 = HDRC+8
MEM2 = HDRC+9

zpage = HDRC
zpagelen = 33 ;arbitrarily long (only needs 10)

*-------------------------------------------------

* Jordan says: use $A400-ABFF                  ; these comments may not be accurate -- the unscrambled check routine spans all the
* Roland says: OK                              ; way from $AAAA to $AC32, and the unscrambling routine (YELLsub in RYELLOW1.S)
                                               ; writes stuff up to address $ACA9, 512 bytes from $AAAA

orgCHECK = $AAAA ;must be highbyte=lowbyte

 org $2000

 da lenCHECK

 dum $A4A4
zpagebuf ds zpagelen
was27 ds 3 ;should be 1 !!!
was2A ds 5 ; ditto
was26 ds 7 ; ditto again
 dend

 org orgCHECK

*-------------------------------------------------

start sta $C008 ;switch to main zpage

 ldx slot
 lda $C089,x ;drive on

 jsr swapzpage                                 ; preserve contents of our scratch buffer in main zero page

* First seek track zero

 lda #0
 jsr SEEK

* Now check signature

 lda #10                                       ; initialize variables
 sta LSRETRY
 ldx slot                                      ; ..
 lda $C08E,X                                   ; .: set drive to input mode (Q7L, Read or Sense Write Protect)
 lda #>:NIBS
 sta NPTRH
 lda #:NIBS
 sta NPTR

:AGAIN lda #$80                                ; scan for an Address Field with sector number = #7
 sta PRETRY
:M1 dec PRETRY
 beq :LSFAIL
 jsr RADR16
 bcs :LSFAIL
 lda HDRS
 cmp #OBJSCT
 bne :M1

 ldy #0                                        ; scan for the #$D5 byte that begins the corresponding Data Field; expect it to be
:M2 lda $C08C,X                                ; within 256 bytes of the 4-and-4 encoded sector number
 bpl :M2
 dey
 beq :LSFAIL
 cmp #$D5
 bne :M2
 ldy #0

:M3 lda $C08C,X                                ; scan for an #$E7 byte in the 6-and-2 encoded data in the Data Field; expect it
 bpl :M3                                       ; to be within 256 bytes of the Data Field's #$D5 byte
 dey
 beq :LSFAIL
 cmp #$E7
 bne :M3

:M4 lda $C08C,X                                ; the #$E7 should be followed by two more #$E7's
 bpl :M4
 cmp #$E7
 bne :LSFAIL

:M5 lda $C08C,X
 bpl :M5
 cmp #$E7
 bne :LSFAIL

                                               ; ? desynchronize the read mechanism -- make it overshoot past the first few 1 bits
                                               ; in the next encoded byte: ?
 lda $C08D,X                                   ; - momentarily switch from Read mode (Q7L + Q6L) to Sense Write Protect (Q7L + Q6H)
 ldy #$10                                      ; - set y <- #$10, which adds a few clock cycles of delay
 bit $6 ;3 US. ( FOR //C)                      ; - throw in yet more clock cycles for good measure
:M6 lda $C08C,X                                ; resume scanning for bytes, in a desynchronized state; expect an #$EE within the
 bpl :M6                                       ; next 15 bytes
 dey
 beq :LSFAIL
 cmp #$EE
 bne :M6

* NOW AT 1/2 NIBBLES

 ldy #7                                        ; after the #$EE byte, expect the next 8 bytes from the desynchronized read to be
:M7 lda $C08C,X * READ DISK DATA               ; #$E7 #$FC #$EE #$E7 #$FC #$EE #$EE #$FC; note that the NIBS array, read indirectly
 bpl :M7                                       ; via (NPTR), is accessed in _reverse_ order
 cmp (NPTR),Y * COMPARE AGAINST TABLE
 bne :LSFAIL
 dey
 bpl :M7
 bmi :GOOD
:LSFAIL jmp :LSFAIL1

* A O K

:GOOD jsr swapzpage                            ; protection check passed
                                               ; restore contents of our scratch buffer in main zero page
 sta $C009-zpagelen,x                          ; switch to auxiliary zero page, and set high bit of $007C; these do the same things
 ror $7C-zpagelen,x                            ; as            sta $C009
                                               ;               sec
                                               ;               ror $7C
                                               ; but in a slightly obfuscated manner --
                                               ;     9D E8 BF  sta $BFE8,x
                                               ;     76 5B     ror $5B,x
                                               ; -- by exploiting the facts that carry flag = 1 and x = #zpagelen after a call to
                                               ; swapzpage
 clc
 rts

* FAILED

:LSFAIL1 dec LSRETRY
 beq :ERROR
 jmp :AGAIN

:NIBS db $FC,$EE,$EE,$FC
 db $E7,$EE,$FC,$E7

:ERROR jsr swapzpage                           ; protection check failed
                                               ; restore contents of our scratch buffer in main zero page
 sta $C009-zpagelen,x                          ; switch to auxiliary zero page, but do not set high bit of $007C; as above, x =
                                               ; #zpagelen
 rts

*-------------------------------------------------
*
* Read address mark
*

RADR16 ldy #$FD
 sty MEM1
:RA1 iny
 bne :RA2
 inc MEM1
 beq :RAEXIT
:RA2 lda $C08C,X
 bpl :RA2
:RA3 cmp #$D5
 bne :RA1
 nop
:RA4 lda $C08C,X
 bpl :RA4
 cmp #$AA
 bne :RA3
 ldy #3
:RA5 lda $C08C,X
 bpl :RA5
 cmp #$96
 bne :RA3
 lda #0
:RA6 sta MEM2
:RA7 lda $C08C,X
 bpl :RA7
 rol
 sta MEM1
:RA8 lda $C08C,X
 bpl :RA8
 and MEM1
 sta HDRC,Y
 eor MEM2
 dey
 bpl :RA6
 tay
 nop
 clc
 rts

:RAEXIT sec
 rts

*-------------------------------------------------
*
* SEEK, a - track
*

SEEK4 lda #4
SEEK sta was2A
 cmp lastrack
 beq :RTS0
 lda #0
 sta was26
:MOVEHEAD lda lastrack
 sta was27
 sec
 sbc was2A
 beq :ISTHERE
 bcs :T0
 eor #$FF
 inc lastrack
 bcc :T1
:T0 adc #$FE
 dec lastrack
:T1 cmp was26
 bcc :T2
 lda was26
:T2 cmp #$C
 bcs :T3
 tay
:T3 sec
 jsr :CHKPOS
 lda ONTBL,Y
 jsr :MSWAIT
 lda was27
 clc
 jsr :CHKPOS2
 lda OFFTBL,Y
 jsr :MSWAIT
 inc was26
 bne :MOVEHEAD
:ISTHERE jsr :MSWAIT
 clc
:CHKPOS lda lastrack
:CHKPOS2 and #3
 rol
 ora slot
 tax
 lda $C080,X
 ldx slot
:RTS0 rts

:MSWAIT ldx #$12
:T21 dex
 bne :T21
 sec
 sbc #1
 bne :MSWAIT
 rts

*-------------------------------------------------

swapzpage ldx #0                               ; swap the contents of the {zpagelen}-byte buffers at zpage ($0030) and zpagebuf
:0 ldy zpagebuf,x                              ; ($A4A4); used to preserve and restore the relevant portion of the main zero page
 lda zpage,x
 sty zpage,x
 sta zpagebuf,x
 inx
 cpx #zpagelen
 bne :0                                        ; upon return, x = #zpagelen = #33 and the carry flag is set; callers take advantage
 rts                                           ; of this

*-------------------------------------------------

ONTBL db $01,$30,$28,$24,$20,$1E,$1D,$1C,$1C,$1C,$1C,$1C
OFFTBL db $70,$2C,$26,$22,$1F,$1E,$1D,$1C,$1C,$1C,$1C,$1C,$FF,$03

*-------------------------------------------------
lenCHECK = *-orgCHECK

 org

*------------------------------------------------- EOF

 sav yellow.main
