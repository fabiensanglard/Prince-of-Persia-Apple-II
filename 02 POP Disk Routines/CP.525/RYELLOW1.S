* Ryellow1 (put this file!!!)

* This code sets the high bit of $7C in aux mem
* if signature is found on track zero.

* NOTE: make sure the x register has a number
* greater than 4 when calling YELLOW.

                                               ; This file apparently implements a secondary copy protection measure (outside of
                                               ; RW18 formatting), used only in the 5.25" diskette version of POP.  Two other
                                               ; secondary protection checks are in POPBOOT0.S ("red herring") and PURPLE.S.

YELLrun = $AAAA                                ; this constant is not used, though $AAAA happens to be the address of the buffer
                                               ; for the cleartext protection check routine

YELLOW                                         ; we just came in from outside (GAMEBG.S); start by doing some weird things...
:0 sec                                         ; .. shift a 1 bit from the right into the accumulator
 rol                                           ; .:
 clc                                           ; .. shift a 0 bit from the right into the accumulator
 rol                                           ; .:
 dex                                           ; repeat the above shifts x times
 bne :0                                        ; x >= 4 upon entry (see above!), so by now, a = binary 10101010 = #$AA
 sta 4                                         ; byte at $0004 <- #$AA

 jsr YELLsub                                   ; unscramble protection check routine and transfer control to it
 jmp YELLnothing                               ; ? clear away traces of the cleartext routine ?

*-------------------------------------------------

YELLcode
 hex 27A26A0C5717236A8AAD0603AA8A3401          ; this 393-byte blob is a scrambled version of the code in YELLOW.MAIN.S
 hex 03A02F9E0C5717246A03012F9D03E92F          ; (yes, I actually checked  -- tkchia 20130926)
 hex 9C032A2F9F6C9F5AF68AF8011AFD0F9B
 hex 63AD7A5B0AAA17266ABA51225AED637F
 hex 7A5E0AAA17266ABA51225A93634D7A5E
 hex 17266ABA51634D7A8617266ABA51634D
 hex 7A8917276A0ABA8EAC17266ABA51225A
 hex BE63447A5E0AAD17266ABA517B9C7AAF
 hex 22BA5E9AA9E696018AAD06374215DCF1
 hex B2CA6C9E5AA1E66100564444564D4456
 hex 4D8AAD06374215CA0A572E92627AAE4C
 hex 925A9717266ABA51637F7A5A4017266A
 hex BA5163007A580AA917266ABA51633C7A
 hex 4D03AA2F9317266ABA51802F9217266A
 hex BA518F92339AAAEF9322BA4D0240B2CA
 hex 92CA03AE27620E6F555AFC03AA27670E
 hex 0F55276F0E9247620E5A9F1AACE3554C
 hex 553AAEC3546C5567670E3AA907670E63
 hex A61AAB02928A440113B3068A5601076F
 hex 0EB28A5A01138F068A560144670E7A6A
 hex 8A5601B20F5583A980AF5700172A6A0C
 hex 57CA08B8607A579243AB7A5CCA08AA16
 hex 0E0E1F9A3E9A370E0E424A8B7A5BCAAB
 hex 9A828E8AB4B7B6B6B6B6B6DA868C88B5
 hex B4B7B6B6B6B6B655A9

*-------------------------------------------------

YELLlen = *-YELLcode

* Routine to decode code

 hex 20 ;jsr                                   ; ? junk byte to confuse linear sweep disassemblers ?

YELLsub sta 5                                  ; we came from YELLOW, so at this point, byte at $0004 = a = #$AA
                                               ; after `sta 5', word at $0004 reads as #$AAAA
 ldy #0                                        ; let the unscrambling begin!  note that
:0 lda YELLcode,y                              ; - the unscrambling algorithm is simply to xor each byte with #$AA
 eor 4                                         ; - the cleartext routine is written to a 512-byte buffer starting at $AAAA
 sta (4),y                                     ; - the YELLcode blob is only 393 bytes long, but this routine overshoots the end
 inc 5                                         ;   of the blob, and `unscrambles' 512 - 393 = 119 extra bytes
 lda YELLcode+256,y                            ; - each loop iteration unscrambles 2 bytes, one from YELLcode,y and one from
 eor 4                                         ;   YELLcode+256,y
 sta (4),y
 dec 5
 iny
 bne :0
 lda 4                                         ; ..
 eor #$4C!$AA ;jmp instruction                 ;  : unscrambling done; construct the instruction `jmp $AAAA' at $0003
 sta 3                                         ; .:
 jmp 3                                         ; hand over to protection check routine

*-------------------------------------------------

 hex a9 ;lda #imm

YELLnothing ldy #0
 inc 5
:0 tya
:1 sta (4),y
 iny
 bne :1
 rts


*------------------------------------------------- EOF
