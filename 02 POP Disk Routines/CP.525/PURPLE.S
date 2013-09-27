* purple (put this file!!!)

* This code sets $DA in aux mem to 1
* if signature is found on track zero.

                                               ; This file apparently implements a secondary copy protection measure (outside of
                                               ; RW18 formatting), used only in the 5.25" diskette version of POP.  Another
                                               ; secondary protection measure can be found in RYELLOW1.S.

PURPrun = $6321

PURPLE
 ldy #PURPrun                                  ; <y, a> <- <low half, high half> of address of buffer to unscramble into
 lda #>PURPrun

 jsr PURPsub                                   ; unscramble the protection check routine
 jsr PURPjmp                                   ; call the protection check routine
                                               ; ? and then fall through to the `rts' ?

* Note: first byte of next junk must be $60 (rts)
*-------------------------------------------------

PURPcode
 hex 60386018EAA8E7108849450040994825          ; this 249-byte blob is a scrambled version of the code in PURPLE.MAIN.S
 hex FB10C08CBD48852AFB10C08CBD498500
 hex A9E7D096C9FB10C08CBD03A0F2D0AAC9
 hex FB10C08CBDEAF0D0D5C9FB10C08CBD3D
 hex F048E604D0C84884FDA060F1D00DE0E8
 hex 62549D409440B56254BC00A2E7FCEEE7
 hex FCEEEEFC63384C0BF044C66018BFFB9D
 hex CD952ABFFC9D00A963BE2063AF4C0330
 hex F4108805D046D1FB10C08CBD07A0F4D0
 hex EEC914F088FB10C08CBD062410A0C08D
 hex BD23D0E7C9FB10C08CBD2CD0E7C9FB10
 hex C08CBDF4D0E7C939F088FB10C08CBD00
 hex A0F4D0D5C947F088FB10C08CBD00A0F1
 hex D007C941A557B063D0205CF045C64585
 hex 80A9478563A94685B6A9C08EBDC089BD
 hex FDA644850AA963BE20

*-------------------------------------------------

PURPlen = *-PURPcode

* Routine to decode code

 hex 20

PURPsub
 sty 4                                         ; store the destination buffer address in the word at $0004
 sta 5

 ldy #0

 ldx #PURPlen
:0 dex                                         ; unscramble: simply copy the bytes in PURPcode to the destination buffer, except
 lda PURPcode,x                                ; in reverse order (last byte comes first, second last comes second, etc.)
 sta (4),y
 iny
 bne :0

 rts

 hex 2c

PURPjmp jmp (4)

*------------------------------------------------- EOF
