; Target assembler: 64tass v1.59.3120 [--ascii --case-sensitive -Wall]
; 6502bench SourceGen v1.10.0
        .cpu    "6502"
JOYBIT_FIRE =   $20
INTERLACE_BIT = $80
KEYCODE_F1 =    $85

counter0 =      $00
INBIT   =       $a7                 ;RS232 temporary for received Bit/Tape
RINONE  =       $a9                 ;RS232 Flag: Start Bit check/Tape temporary
NDX     =       $c6                 ;Number of Characters in Keyboard Buffer queue
RIBUF   =       $f7                 ;RS232 Input Buffer Pointer
ROBUF   =       $f9                 ;RS232 Output Buffer Pointer
FREKZP  =       $fb                 ;Free Zero Page space for User Programs
KEYD    =       $0277               ;Keyboard Buffer Queue (FIFO)
TODSNS  =       $02a2               ;TOD sense during Tape I/O
CINV    =       $0314               ;Vector: Hardware IRQ Interrupt ($ea31)
TBUFFR  =       $033c               ;start of Tape I/O Buffer
VICSCN  =       $0400               ;start of Default Screen Video Matrix
PAOUT   =       $9111               ;port A output register
V1_INTENABLE =  $911e               ;via 1 interrupt enable register
scnkey  =       $ff9f               ;Scan Keyboard ($ea87)
ichrout =       $ffd2               ;Output Vector chrout $f1ca ($0326->$f1ca)
udtim   =       $ffea               ;Increment Real-Time Clock ($f69b)

*       =       $1001
        .byte   $0b
        .byte   $10
        .byte   $01
        .byte   $00
        .text   $9e,"4110"
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00

main
        sei
        lda     #$7f
        sta     V1_INTENABLE        ;poke 0x7F to VIA 1 interrupt enable register (what does this do?)
        jsr     init
        jsr     L1491
        lda     #$ff
        sta     $9005
        lda     PAOUT               ;check if fire held, if so, enable interlace mode
        eor     #$ff
        and     #JOYBIT_FIRE
        beq     _no_interlace
        lda     $9000
        ora     #INTERLACE_BIT
        sta     $9000
_no_interlace
        sec
        php
L1032
        jsr     L16CC
        jsr     L148E
        plp
        bcc     _L103E
        jsr     wait_for_start      ;wait for F1 or fire to start game
_L103E
        jsr     L14A6
        lda     #$56
        ldy     #$13
        sta     CINV
        sty     CINV+1
_loop
        sei
        bit     L1BBB
        bpl     _L106A
        jsr     jmp_snd_reset
        jsr     L1999
        jsr     L14A9
        dec     loop1+2
        bmi     new_game
        jsr     L14A3
        jsr     L14A6
        lda     #$00
        sta     L1BBB
_L106A
        lda     L1BBA
        cmp     #$c5
        bcc     _L1074
        jsr     L16B7
_L1074
        bit     L1BC1
        bpl     _L107C
        jsr     L16BD
_L107C
        cli
        nop
        nop
        nop
        jmp     _loop               ;main game loop

new_game
        jsr     wait_for_start
        ldy     #$03
        sed
        sec
_L108A
        lda     init_vram,y
        sbc     L1B7F+1,y
        dey
        bpl     _L108A
        cld
        bcc     _L10A1
        ldy     #$03
_L1098
        lda     init_vram,y
        sta     L1B7F+1,y
        dey
        bpl     _L1098
_L10A1
        jsr     L1494
        clc
        php
        jmp     L1032

wait_for_start
        jsr     jmp_snd_reset       ;reset all sounds
_loop
        lda     PAOUT               ;check that fire button is pressed
        eor     #$ff                ;flip bits
        and     #JOYBIT_FIRE        ;check bit
        bne     _break              ;return if pressed
        sta     NDX                 ;clear input buffer
        jsr     scnkey              ;read one char from keyboard
        jsr     key_input           ;handle keyboard input
        cmp     #KEYCODE_F1         ;check if F1 was pressed
        bne     _loop               ;if not, continue looping
_break
        rts

key_input
        lda     NDX
        beq     _no_input
        ldy     KEYD
        ldx     #$00
_shift
        lda     KEYD+1,x
        sta     KEYD,x
        inx
        cpx     NDX
        bne     _shift
        tya
_no_input
        rts

L10D8
        lda     L1BA9
        sta     ROBUF
        pha
        lda     L1BAA
        sta     ROBUF+1
        pha
        ldy     L1BB8
        jsr     L120F
        cmp     #$0b
        bcs     _L1105
        pla
        sta     ROBUF+1
        pla
        sta     ROBUF
        pha
        lda     ROBUF+1
        pha
        ldy     L1BAB
        jsr     L120F
        cmp     #$0b
        bcs     _L1105
        pla
        pla
        rts

_L1105
        beq     L113A
        cmp     #$0c
        beq     L1150
        cmp     #$10
        bcs     _L1112
        jmp     L11AC

_L1112
        cmp     #$18
        bcc     L1177
L1116
        lda     L120B,y
        sty     L1BAB
        ldx     #$07
        sec
        jsr     L1488
        lda     ROBUF
        sta     L1BA9
        lda     ROBUF+1
        sta     L1BAA
        pla
        sta     ROBUF+1
        pla
        sta     ROBUF
        lda     #$20
        ldx     #$00
        sec
        jmp     L1488

L113A
        lda     #$10
        ldx     #$00
        jsr     L11D1
        lda     #$ff
        sta     L1BBF
        lda     #$06
        sta     $01
        dec     L1BBA
        jmp     L1116

L1150
        lda     #$50
        ldx     #$00
        jsr     L11D1
        lda     #$01
        sta     L1BBD
        lda     #$c0
        sta     L1BBC
        lda     #$ff
        sta     L1BBE
        lda     #$01
        sta     L1B90
        sta     L1BA5
        sta     L1B97
        sta     L1B9E
        jmp     L1116

L1177
        sec
        sbc     #$12
        tax
        lda     L11F5,x
        tax
        lda     #$00
        jsr     L11D1
        tya
        pha
        lda     ROBUF
        pha
        lda     ROBUF+1
        pha
        lda     #$e7
        ldy     #$1f
        sta     ROBUF
        sty     ROBUF+1
        ldy     #$05
_L1196
        lda     #$20
        ldx     #$00
        sec
        jsr     L148B
        dey
        bpl     _L1196
        pla
        sta     ROBUF+1
        pla
        sta     ROBUF
        pla
        tay
L11A9
        jmp     L1116

L11AC
        bit     L1BBE
        bpl     _L11C9
        lda     #$ff
        sta     L1BC1
        inc     L1BC2
        ldx     L1BC2
        dex
        lda     L11FB,x
        tax
        lda     #$00
        jsr     L11D1
        jmp     L1116

_L11C9
        lda     #$ff
        sta     L1BBB
        pla
        pla
        rts

L11D1
        sta     L1B8C
        stx     L1B8B
        tya
        pha
        lda     ROBUF
        pha
        lda     ROBUF+1
        pha
        jsr     L148E
        lda     #$00
        ldy     #$03
_L11E6
        sta     L1B89,y
        dey
        bpl     _L11E6
        pla
        sta     ROBUF+1
        pla
        sta     ROBUF
        pla
        tay
        rts

L11F5
        .byte   $20
        .byte   $05
        .byte   $20
        .byte   $10
        .byte   $02
        .byte   $01
L11FB
        .byte   $01
        .byte   $02
        .byte   $04
        .byte   $08
        .byte   $16
        .text   "$2@hv"
        .byte   $64
        .byte   $72
L1207
        .byte   $01
        .byte   $96
        .byte   $16
        .byte   $81
L120B
        .byte   $0d
        .byte   $19
        .byte   $10
        .byte   $18

L120F
        tya
        pha
        lda     L1207,y
        bmi     _L1221
        clc
        adc     ROBUF
        sta     ROBUF
        bcc     _L1232
        inc     ROBUF+1
        bne     _L1232
_L1221
        and     #$7f
        sta     $8f
        sec
        lda     ROBUF
        sbc     $8f
        sta     ROBUF
        lda     ROBUF+1
        sbc     #$00
        sta     ROBUF+1
_L1232
        clc
        jsr     L1488
        tax
        pla
        tay
        txa
        rts

_L123B
        lda     #$8d
        ldy     #$1b
        jsr     _L1257
        lda     #$94
        ldy     #$1b
        jsr     _L1257
        lda     #$9b
        ldy     #$1b
        jsr     _L1257
        lda     #$a2
        ldy     #$1b
        jmp     _L1257

_L1257
        sta     $8b
        sty     $8c
        lda     #$b0
        ldy     #$1b
        sta     $8d
        sty     $8e
        ldy     #$06
_L1265
        lda     ($8b),y
        sta     ($8d),y
        dey
        bpl     _L1265
        lda     $9114
        and     #$03
        clc
        adc     L1BB4
        sta     $8f
        dec     $8f
_L1279
        inc     $8f
        ldy     $8f
        lda     _L1329,y
        sta     L1BB4
        lsr     a
        lsr     a
        lsr     a
        tay
        lda     _L1351,y
        bne     _L128F
        jmp     _L131F

_L128F
        bmi     _L12A0
        clc
        adc     L1BB0
        sta     ROBUF
        lda     #$00
        adc     L1BB1
        sta     ROBUF+1
        bne     _L12B3
_L12A0
        and     #$7f
        sta     INBIT
        sec
        lda     L1BB0
        sbc     INBIT
        sta     ROBUF
        lda     L1BB1
        sbc     #$00
        sta     ROBUF+1
_L12B3
        clc
        jsr     L1488
        cmp     #$1a
        bcs     _L12E5
        cmp     #$00
        bne     _L12C4
        ldy     L1BB4
        beq     _L12E5
_L12C4
        cmp     #$0b
        bcc     _L1279
        cmp     #$0d
        beq     _L12DE
        bcc     _L12E5
        cmp     #$10
        beq     _L12DE
        bcc     _L1279
        cmp     #$11
        beq     _L12DE
        cmp     #$18
        beq     _L12DE
        bcc     _L12E5
_L12DE
        lda     #$ff
        sta     L1BBB
        bne     _L1328

_L12E5
        pha
        txa
        pha
        lda     ROBUF
        pha
        lda     ROBUF+1
        pha
        lda     L1BB0
        sta     ROBUF
        lda     L1BB1
        sta     ROBUF+1
        lda     L1BB5
        ldx     L1BB6
        sec
        jsr     L1488
        pla
        sta     L1BB1
        sta     ROBUF+1
        pla
        sta     L1BB0
        sta     ROBUF
        pla
        sta     L1BB6
        pla
        sta     L1BB5
        lda     #$0e
        ldx     L1BB3
        sec
        jsr     L1488
_L131F
        ldy     #$06
_L1321
        lda     ($8d),y
        sta     ($8b),y
        dey
        bpl     _L1321
_L1328
        rts

_L1329
        .byte   $00
        .byte   $00
        .byte   $10
        .byte   $18
        .byte   $00
        .byte   $10
        .byte   $08
        .byte   $20
        .byte   $08
        .byte   $08
        .byte   $18
        .byte   $10
        .byte   $08
        .byte   $18
        .byte   $00
        .byte   $20
        .byte   $10
        .byte   $10
        .byte   $00
        .byte   $08
        .byte   $10
        .byte   $00
        .byte   $18
        .byte   $20
        .byte   $18
        .byte   $18
        .byte   $08
        .byte   $00
        .byte   $18
        .byte   $08
        .byte   $10
        .byte   $20
        .byte   $08
        .byte   $00
        .byte   $18
        .byte   $10
        .byte   $08
        .byte   $00
        .byte   $18
        .byte   $20
_L1351
        .byte   $01
        .byte   $81
        .byte   $16
        .byte   $96
        .byte   $00
        .byte   $e6
        .byte   $3f
        .byte   $d0
        .byte   $02
        .byte   $e6
        .byte   $40
        .byte   $2c
        .byte   $be
        .byte   $1b
        .byte   $10
        .byte   $0e
        .byte   $20
        .byte   $ba
        .byte   $16
        .byte   $2c
        .byte   $be
        .byte   $1b
        .byte   $10
        .byte   $06
        .byte   $20
        .byte   $5f
        .byte   $14
        .byte   $4c
        .byte   $72
        .byte   $13

        jsr     _L144B
        jsr     jmp_get_input
        lda     #$00
        sta     NDX
        jsr     scnkey
        jsr     key_input
        cmp     #$45
        beq     _L1392
        cmp     #$56
        beq     _L1395
        cmp     #$4a
        beq     _L1398
        cmp     #$4c
        bne     _L139D
        lda     #$00
        .byte   $2c
_L1392
        lda     #$01
        .byte   $2c
_L1395
        lda     #$02
        .byte   $2c
_L1398
        lda     #$03
        sta     L1BB8
_L139D
        dec     L1BAC
        bpl     _L13AA
        lda     #$06
        sta     L1BAC
        jsr     L16C0
_L13AA
        dec     L1BAD
        bpl     _L13C6
        lda     #$0c
        sta     L1BAD
        jsr     _L123B
        bit     L1BBB
        bpl     _L13C6
        bit     L1BBE
        bpl     _L13E5
        lda     #$00
        sta     L1BBB
_L13C6
        dec     L1BAE
        bpl     _L13D3
        lda     #$04
        sta     L1BAE
        jsr     L149D
_L13D3
        dec     L1BAF
        bpl     _L13E5
        lda     #$08
        sta     L1BAF
        lda     #$00
        sta     L1BBF
        jsr     L10D8
_L13E5
        jsr     L191C
        lda     $40
        cmp     #$05
        bcc     _L1425
        lda     #$00
        sta     $3f
        sta     $40
        lda     L1EA4
        cmp     #$20
        bne     _L1425
        lda     #$a4
        ldy     #$1e
        sta     ROBUF
        sty     ROBUF+1
        lda     $9114
        and     #$07
        pha
        jsr     _L1440
        lda     #$e7
        ldy     #$1f
        sta     ROBUF
        sty     ROBUF+1
        pla
        pha
        jsr     _L1440
        pla
        inc     ROBUF
        inc     ROBUF
        tay
        lda     _L1438,y
        jsr     L16C3
_L1425
        jmp     L16B4

_L1428
        .byte   $12
        .byte   $14
        .byte   $13
        .byte   $15
        .byte   $17
        .byte   $16
        .byte   $17
        .byte   $16
_L1430
        .byte   $06
        .byte   $02
        .byte   $07
        .byte   $03
        .byte   $07
        .byte   $04
        .byte   $07
        .byte   $04
_L1438
        .byte   $20
        .byte   $20
        .byte   $05
        .byte   $10
        .byte   $01
        .byte   $02
        .byte   $01
        .byte   $02

_L1440
        tay
        lda     _L1428,y
        ldx     _L1430,y
        sec
        jmp     L1488

_L144B
        lda     #$f1
        ldy     #$1f
        sta     ROBUF
        sty     ROBUF+1
_L1453
        ldx     #$00
        lda     #$20
        sec
        jsr     L148B
        dey
        bpl     _L1453
        rts

        lda     #$f1
        ldy     #$1f
        sta     ROBUF
        sty     ROBUF+1
        lda     #$0e
        ldx     #$01
        sec
        jsr     L1488
        inc     ROBUF
        inc     ROBUF
        ldy     L1BC2
        lda     _L147C,y
        jmp     L16C3

_L147C
        .byte   $01
        .byte   $02
        .byte   $04
        .byte   $08
        .byte   $16
        .text   "$2@hv"
        .byte   $64
        .byte   $72

L1488
        jmp     L14AF

L148B
        jmp     L14B1

L148E
        jmp     L14D8

L1491
        jmp     L1543

L1494
        jmp     L1546

L1497
        jmp     L1549

jmp_get_input
        jmp     get_input

L149D
        jmp     L15A2

        jmp     L15D5

L14A3
        jmp     L1622

L14A6
        jmp     L162D

L14A9
        jmp     L1647

        jmp     L15CF

L14AF
        ldy     #$00
L14B1
        bcs     _L14C4
        lda     ROBUF+1
        pha
        adc     #$78
        sta     ROBUF+1
        lda     (ROBUF),y
        tax
        pla
        sta     ROBUF+1
        lda     (ROBUF),y
        clc
        rts

_L14C4
        sta     (ROBUF),y
        pha
        lda     ROBUF+1
        pha
        clc
        adc     #$78
        sta     ROBUF+1
        txa
        sta     (ROBUF),y
        pla
        sta     ROBUF+1
        sec
        pla
        rts

L14D8
        sei
        sed
        ldy     #$03
        clc
_L14DD
        lda     L1B89,y
        adc     init_vram,y
        sta     init_vram,y
        dey
        bpl     _L14DD
        cld
        lda     #$0b
        sta     ROBUF
        lda     #$1e
        sta     ROBUF+1
        lda     #$80
        sta     FREKZP
        lda     #$1b
        sta     $fc
        jsr     _L150D
        lda     #$21
        sta     ROBUF
        lda     #$1e
        sta     ROBUF+1
        lda     #$84
        sta     FREKZP
        lda     #$1b
        sta     $fc
_L150D
        lda     #$00
        sta     $fd
        sta     $fe
_L1513
        ldy     $fe
        cpy     #$04
        beq     _L152D
        lda     (FREKZP),y
        pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        jsr     _L152E
        pla
        and     #$0f
        jsr     _L152E
        inc     $fe
        bne     _L1513
_L152D
        rts

_L152E
        beq     _L1532
        dec     $fd
_L1532
        bit     $fd
        bmi     _L1539
        ldx     #$00
        .byte   $2c
_L1539
        ldx     #$07
        ora     #$30
        jsr     L15D1
        inc     ROBUF
        rts

L1543
        ldy     #$00
        .byte   $2c
L1546
        ldy     #$04
        .byte   $2c
L1549
        ldy     #$09
        lda     #$80
        sta     FREKZP
        lda     #$1b
        sta     $fc
        lda     #$25
        sta     $fd
        lda     #$1b
        sta     $fe
_L155B
        lda     ($fd),y
        sta     (FREKZP),y
        iny
        cpy     #$50
        bne     _L155B
        rts

get_input
        lda     #$00
        sta     $9122
        lda     $9120
        eor     #$ff
        and     #$80
        rol     a
        php
        lda     #$ff
        sta     $9122
        lda     PAOUT
        eor     #$ff
        and     #$1c
        lsr     a
        lsr     a
        plp
        rol     a
        cmp     #$01
        beq     _L1596
        cmp     #$02
        beq     _L1599
        cmp     #$04
        beq     _L159C
        cmp     #$08
        bne     _end_input
        lda     #$03
        .byte   $2c
_L1596
        lda     #$00
        .byte   $2c
_L1599
        lda     #$01
        .byte   $2c
_L159C
        lda     #$02
        sta     L1BB8
_end_input
        rts

L15A2
        lda     L1BA9
        ldy     L1BAA
        sta     ROBUF
        sty     ROBUF+1
        clc
        jsr     L1488
        cmp     #$11
        bne     _L15C4
        lda     L1BAB
        beq     _L15C7
        cmp     #$01
        beq     _L15CA
        cmp     #$02
        beq     _L15CD
        lda     #$18
        .byte   $2c
_L15C4
        lda     #$11
        .byte   $2c
_L15C7
        lda     #$0d
        .byte   $2c
_L15CA
        lda     #$19
        .byte   $2c
_L15CD
        lda     #$10
L15CF
        ldx     #$07
L15D1
        sec
        jmp     L1488

L15D5
        lda     L1BA9
        ldy     L1BAA
L15DB
        sta     ROBUF
        sty     ROBUF+1
        lda     #$b4
        ldy     #$16
        sta     CINV
        sty     CINV+1
        lda     #$00
        sta     $a2
        lda     #$1a
        jsr     L15CF
        cli
_L15F3
        lda     $a2
        cmp     #$05
        bcc     _L15F3
        lda     #$1b
        jsr     L15CF
_L15FE
        lda     $a2
        cmp     #$09
        bcc     _L15FE
        lda     #$1c
        jsr     L15CF
_L1609
        lda     $a2
        cmp     #$0d
        bcc     _L1609
        lda     #$20
        ldx     #$00
        jsr     L15D1
        sei
        lda     #$56
        sta     CINV
        lda     #$13
        sta     CINV+1
        rts

L1622
        clc
        lda     #$d8
        adc     loop1+2
        ldy     #$1e
        jsr     L15DB
L162D
        lda     #$c2
        ldy     #$1f
        sta     ROBUF
        sty     ROBUF+1
        sta     L1BA9
        sty     L1BAA
        lda     #$01
        sta     L1BAB
        sta     L1BB8
        lda     #$10
        bne     L15CF

L1647
        lda     #$03
        sta     $8f
        lda     #$86
        sta     $8d
        lda     #$1b
        sta     $8e
_L1653
        clc
        lda     #$07
        adc     $8d
        sta     $8d
        ldy     #$00
        lda     ($8d),y
        sta     ROBUF
        iny
        lda     ($8d),y
        sta     ROBUF+1
        ldy     #$06
        lda     ($8d),y
        tax
        dey
        lda     ($8d),y
        jsr     L15D1
        ldx     $8f
        lda     _L16B0,x
        ldy     #$00
        sta     ($8d),y
        iny
        lda     #$1e
        sta     ($8d),y
        iny
        ldx     $8f
        lda     L1B21,x
        sta     ($8d),y
        iny
        sta     ($8d),y
        iny
        lda     #$00
        sta     ($8d),y
        iny
        iny
        sta     ($8d),y
        dey
        lda     #$20
        sta     ($8d),y
        ldy     #$00
        lda     ($8d),y
        sta     ROBUF
        iny
        lda     ($8d),y
        sta     ROBUF+1
        iny
        lda     ($8d),y
        tax
        lda     #$0e
        jsr     L15D1
        dec     $8f
        bpl     _L1653
        rts

_L16B0
        .byte   $fb
        .byte   $fc
        .byte   $fd
        .byte   $fe

L16B4
        jmp     L17E1

L16B7
        jmp     L16CF

        jmp     L16F0

L16BD
        jmp     L1721

L16C0
        jmp     L17A0

L16C3
        jmp     L17E7

jmp_snd_reset
        jmp     snd_reset

L16C9
        jmp     L1820

L16CC
        jmp     L186B

L16CF
        jsr     L1497
        jsr     L16CC
        lda     #$d7
        sta     ROBUF
        lda     #$1e
        sta     ROBUF+1
        ldy     loop1+2
        lda     #$20
        ldx     #$00
_L16E4
        iny
        cpy     #$04
        beq     _L16EF
        sec
        jsr     L148B
        bcs     _L16E4
_L16EF
        rts

L16F0
        lda     L1BBC
        bne     _L171D
        dec     L1BBD
        bpl     _L171D
        lda     #$00
        sta     L1BBC
        sta     L1BBD
        sta     L1BC2
        sta     L1BBE
        lda     #$03
        sta     L1B90
        lda     #$04
        sta     L1B97
        lda     #$07
        sta     L1B9E
        lda     #$02
        sta     L1BA5
        rts

_L171D
        dec     L1BBC
        rts

L1721
        lda     L1B8C+1
        ldy     loop2
        jsr     _L1792
        bcc     _L1732
        lda     #$8d
        ldy     #$1b
        bne     _L1758

_L1732
        lda     L1BA2
        ldy     L1BA3
        jsr     _L1792
        bcc     _L1743
        lda     #$a2
        ldy     #$1b
        bne     _L1758

_L1743
        lda     inc_counter0
        ldy     inc_counter0+1
        jsr     _L1792
        bcc     _L1754
        lda     #$94
        ldy     #$1b
        bne     _L1758

_L1754
        lda     #$9b
        ldy     #$1b
_L1758
        sta     $8d
        sty     $8e
        ldy     #$00
        lda     #$fb
        sta     ROBUF
        sta     ($8d),y
        iny
        lda     #$1e
        sta     ROBUF+1
        sta     ($8d),y
        iny
        iny
        lda     ($8d),y
        tax
        lda     #$0e
        jsr     L17DD
        ldy     #$04
        lda     #$00
        sta     ($8d),y
        iny
        lda     ($8d),y
        cmp     #$0b
        bne     _L1785
        dec     L1BBA
_L1785
        lda     #$20
        sta     ($8d),y
        iny
        lda     #$00
        sta     ($8d),y
        sta     L1BC1
        rts

_L1792
        cmp     L1BA9
        bne     _L179E
        cpy     L1BAA
        bne     _L179E
        sec
        .byte   $24
_L179E
        clc
        rts

L17A0
        lda     L1B8C+1
        ldy     loop2
        ldx     L1B90
        jsr     _L17CD
        lda     inc_counter0
        ldy     inc_counter0+1
        ldx     L1B97
        jsr     _L17CD
        lda     L1B9B
        ldy     L1B9C
        ldx     L1B9E
        jsr     _L17CD
        lda     L1BA2
        ldy     L1BA3
        ldx     L1BA5
_L17CD
        sta     ROBUF
        sty     ROBUF+1
        txa
        pha
        clc
        jsr     L1488
        eor     #$01
        tay
        pla
        tax
        tya
L17DD
        sec
        jmp     L1488

L17E1
        jsr     udtim
        jmp     $eb15

L17E7
        pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        bne     _L17F9
        lda     #$20
        ldx     #$00
_L17F2
        jsr     L17DD
        inc     ROBUF
        bne     _L17FF
_L17F9
        ora     #$30
        ldx     #$07
        bne     _L17F2

_L17FF
        pla
        and     #$0f
        ora     #$30
        ldx     #$07
        jsr     L17DD
        inc     ROBUF
        lda     #$30
        jsr     L1488
        inc     ROBUF
        jmp     L1488

snd_reset
        lda     #$00
        ldy     #$04
_L1819
        sta     $900a,y
        dey
        bpl     _L1819
        rts

L1820
        clc
        lda     #$9f
        adc     #$57
        sta     ROBUF
        lda     #$1b
        adc     #$01
        sta     ROBUF+1
        lda     #$57
        sta     RIBUF
        lda     #$1d
        sta     RIBUF+1
        ldy     #$00
_L1837
        lda     (ROBUF),y
        sta     (RIBUF),y
        lda     ROBUF
        bne     _L1841
        dec     ROBUF+1
_L1841
        dec     ROBUF
        lda     RIBUF
        bne     _L1849
        dec     RIBUF+1
_L1849
        dec     RIBUF
        lda     RIBUF+1
        cmp     #$1b
        bne     _L1837
        lda     #$00
        ldy     #$1d
        sta     RIBUF
        sta     ROBUF
        sty     RIBUF+1
        lda     #$81
        sta     ROBUF+1
        ldy     #$ff
_L1861
        lda     (ROBUF),y
        sta     (RIBUF),y
        dey
        cpy     #$57
        bne     _L1861
        rts

L186B
        lda     #$b4
        ldy     #$16
        sta     CINV
        sty     CINV+1
        lda     #$08
        sta     $900f
        ldy     #$00
_L187C
        lda     _L18FF,y
        cmp     #$00
        beq     _L1889
        jsr     ichrout
        iny
        bne     _L187C
_L1889
        sei
        lda     #$44
        ldy     #$1a
        sta     RIBUF
        sty     RIBUF+1
        lda     #$2b
        ldy     #$1e
        sta     ROBUF
        sty     ROBUF+1
        ldx     #$00
        txa
        pha
        ldy     #$00
_L18A0
        inc     RIBUF
        bne     _L18A6
        inc     RIBUF+1
_L18A6
        lda     (RIBUF),y
        pha
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        jsr     _L18E1
        pla
        and     #$0f
        jsr     _L18E1
        pla
        tax
        inx
        txa
        pha
        cpx     #$dc
        bne     _L18A0
        pla
        lda     #$1e
        sta     ROBUF+1
        lda     #$fb
        sta     ROBUF
        ldy     #$03
_L18CA
        ldx     L1B21,y
        lda     #$0e
        sec
        jsr     L148B
        dey
        bpl     _L18CA
        lda     #$56
        ldy     #$13
        sta     CINV
        sty     CINV+1
        rts

_L18E1
        inc     ROBUF
        bne     _L18E7
        inc     ROBUF+1
_L18E7
        cmp     #$0b
        bcc     _L18F4
        beq     _L18FA
        cmp     #$0c
        beq     _L18F7
        ldx     #$07
        .byte   $2c
_L18F4
        ldx     #$06
        .byte   $2c
_L18F7
        ldx     #$02
        .byte   $2c
_L18FA
        ldx     #$05
        jmp     L17DD

_L18FF
        .text   $93,$9e,"()*( #$%&' ",$0d,$9e,"     #$%&' ",$0d
        .byte   $13
        .byte   $00

L191C
        lda     counter0
        cmp     #$0c
        bcc     _L1926
_L1922
        lda     #$0b
        sta     counter0
_L1926
        dec     counter0
        bmi     _L1922
        bit     L1BBE
        bmi     _L1963
        ldy     counter0
        lda     _L194F,y
        sta     $900c
        lda     #$05
        sta     $900e
        lda     $01
        beq     _L194B
        tay
        dec     $01
        lda     #$0f
        sta     $900e
        lda     _L195B,y
_L194B
        sta     $900a
        rts

_L194F
        .byte   $d8
        .byte   $da
        .byte   $dc
        .byte   $de
        .byte   $e0
        .byte   $e2
        .byte   $e1
        .byte   $df
        .byte   $dd
        .byte   $db
        .byte   $d9
        .byte   $d7
_L195B
        .byte   $00
        .byte   $90
        .byte   $92
        .byte   $94
        .byte   $96
        .byte   $94
        .byte   $92
        .byte   $90

_L1963
        lda     L1BBD
        bne     _L196F
        lda     L1BBC
        cmp     #$40
        bcc     _L1982
_L196F
        lda     #$00
        sta     $900a
        lda     #$0f
        sta     $900e
        ldy     counter0
        lda     _L198D,y
        sta     $900c
        rts

_L1982
        lda     #$08
        sta     $900e
        lda     #$d8
        sta     $900c
        rts

_L198D
        .byte   $d8
        .byte   $d9
        .byte   $da
        .byte   $db
        .byte   $dc
        .byte   $dd
        .byte   $de
        .byte   $df
        .byte   $e0
        .byte   $e1
        .byte   $e2
        .byte   $e3

L1999
        jsr     L16C0
        jsr     L1A2F
        jsr     jmp_snd_reset
        lda     #$cd
        sta     $900c
        lda     #$0f
L19A9
        sta     $900e
        cli
_L19AD
        lda     $a2
        cmp     #$03
        bne     _L19AD
        lda     #$00
        sta     $a2
        dec     $900c
        lda     $900c
        cmp     #$a5
        bne     _L19AD
        sei
        jsr     jmp_snd_reset
        lda     #$0f
        sta     $900e
        lda     #$80
        sta     $900d
        sta     $900a
        lda     #$00
        sta     $a2
        lda     L1BA9
        ldy     L1BAA
        sta     ROBUF
        sty     ROBUF+1
        lda     #$1a
        jsr     L1A3F
        cli
_L19E6
        lda     $a2
        cmp     #$04
        bcc     _L19E6
        lda     #$1b
        jsr     L1A3F
        dec     $900e
_L19F4
        lda     $a2
        cmp     #$09
        bcc     _L19F4
        lda     #$1c
        jsr     L1A3F
        dec     $900e
_L1A02
        lda     $a2
        cmp     #$0e
        bcc     _L1A02
        lda     #$20
        ldx     #$00
        jsr     L1A41
_L1A0F
        dec     $900e
        beq     _L1A20
        lda     #$00
        sta     $a2
_L1A18
        lda     $a2
        cmp     #$05
        bcs     _L1A0F
        bcc     _L1A18

_L1A20
        jsr     jmp_snd_reset
        sei
        lda     #$13
        sta     CINV+1
        lda     #$56
        sta     CINV
        rts

L1A2F
        sei
        lda     #$b4
        ldy     #$16
        sta     CINV
        sty     CINV+1
        lda     #$00
        sta     $a2
        rts

L1A3F
        ldx     #$07
L1A41
        sec
        jmp     L1488

        .byte   $31
        .fill   9,$11
        .byte   $14
        .byte   $2b
        .byte   $bb
        .byte   $cb
        .fill   5,$bb
        .byte   $bc
        .byte   $bb
        .byte   $b2
        .byte   $2b
        .byte   $11
        .byte   $11
        .byte   $11
        .byte   $b1
        .byte   $77
        .byte   $1b
        .byte   $11
        .byte   $11
        .byte   $11
        .byte   $b2
        .byte   $2b
        .byte   $bb
        .byte   $bb
        .byte   $bb
        .byte   $bb
        .byte   $22
        .byte   $bb
        .byte   $bb
        .byte   $bb
        .byte   $bb
        .byte   $b2
        .byte   $2b
        .byte   $11
        .byte   $1b
        .byte   $2b
        .byte   $2b
        .byte   $65
        .byte   $b2
        .byte   $b2
        .byte   $b1
        .byte   $11
        .byte   $b2
        .byte   $2b
        .byte   $bb
        .byte   $bb
        .byte   $2b
        .byte   $2b
        .byte   $bb
        .byte   $b2
        .byte   $b2
        .byte   $bb
        .byte   $bb
        .byte   $b2
        .byte   $2b
        .byte   $11
        .byte   $1b
        .byte   $2b
        .byte   $61
        .byte   $11
        .byte   $15
        .byte   $b2
        .byte   $b3
        .byte   $11
        .byte   $19
        .byte   $2b
        .byte   $bb
        .byte   $bb
        .byte   $2b
        .byte   $bb
        .byte   $bb
        .byte   $bb
        .byte   $b2
        .byte   $b2
        .byte   $dd
        .byte   $d2
        .byte   $a1
        .byte   $11
        .byte   $4b
        .byte   $2b
        .byte   $31
        .byte   $11
        .byte   $14
        .byte   $b2
        .byte   $b6
        .byte   $11
        .byte   $15
        .byte   $61
        .byte   $11
        .byte   $5b
        .byte   $2b
        .byte   $2e
        .byte   $ee
        .byte   $e0
        .fill   8,$bb
        .byte   $61
        .byte   $11
        .byte   $15
        .byte   $b2
        .byte   $b3
        .byte   $11
        .byte   $14
        .byte   $31
        .byte   $11
        .byte   $4b
        .byte   $2b
        .byte   $bb
        .byte   $bb
        .byte   $bb
        .byte   $b2
        .byte   $b6
        .byte   $11
        .byte   $19
        .byte   $a1
        .byte   $11
        .text   "[++4"
        .byte   $b2
        .byte   $b2
        .byte   $bb
        .byte   $bb
        .byte   $b2
        .byte   $2b
        .byte   $bb
        .byte   $bb
        .byte   $2b
        .byte   $2b
        .byte   $22
        .byte   $b2
        .byte   $b2
        .byte   $b1
        .byte   $11
        .byte   $b2
        .text   "+++++",$22
        .byte   $b2
        .byte   $b2
        .byte   $bb
        .byte   $bb
        .byte   $b2
        .text   "+++++",$22
        .byte   $b2
        .byte   $b2
        .byte   $b1
        .byte   $11
        .byte   $b2
        .text   "+++++",$22
        .byte   $b2
        .byte   $b2
        .byte   $bb
        .byte   $bb
        .byte   $b2
        .text   "+++++"
        .byte   $65
        .byte   $b2
        .byte   $b2
        .byte   $b1
        .byte   $11
        .byte   $b2
        .byte   $2b
        .byte   $bb
        .byte   $cb
        .fill   5,$bb
        .byte   $bc
        .byte   $bb
        .byte   $b2
        .byte   $61
        .fill   9,$11
        .byte   $15
L1B21
        .byte   $02
        .byte   $07
        .byte   $04
        .byte   $03
        .fill   8,$00
        .byte   $03
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $fe
        .byte   $1e
        .byte   $03
        .byte   $03
        .byte   $00
        .byte   $20
        .byte   $00
        .byte   $fb
        .byte   $1e
        .byte   $04
        .byte   $04
        .byte   $00
        .byte   $20
        .byte   $00
        .byte   $fd
        .byte   $1e
        .byte   $07
        .byte   $07
        .byte   $00
        .byte   $20
        .byte   $00
        .byte   $fc
        .byte   $1e
        .byte   $02
        .byte   $02
        .byte   $00
        .byte   $20
        .byte   $00
        .byte   $c2
        .byte   $1f
        .byte   $01
        .byte   $10
        .byte   $20
        .byte   $0c
        .byte   $18
        .fill   8,$00
        .byte   $01
        .byte   $00
        .byte   $c4
        .fill   8,$00

init
        ldy     #$00
        sty     counter0
_loop
        lda     L1E00,y
        jsr     init_vram
        lda     L1F00,y
        jsr     init_vram
        iny
        bne     _loop
        lda     counter0
L1B7D
        cmp     #$09
L1B7F
        bne     L1B7D
        jmp     L16C9

init_vram
        ldx     #$07
loop1
        cmp     L1B97,x
L1B89
        beq     inc_counter0
L1B8B
        dex
L1B8C
        bpl     loop1
loop2
        cmp     #$20
L1B90
        beq     return
        bne     loop2

inc_counter0
        inc     counter0
return
        rts

L1B97
        .byte   $12
        .byte   $05
        .byte   $01
        .byte   $04
L1B9B
        .byte   $19
L1B9C
        .byte   $2e
        .byte   $15
L1B9E
        .byte   $0e
        .byte   $28
        .byte   $14
        .byte   $28
L1BA2
        .byte   $14
L1BA3
        .byte   $28
        .byte   $14
L1BA5
        .byte   $28
        .byte   $14
        .byte   $00
        .byte   $00
L1BA9
        .byte   $ff
L1BAA
        .byte   $ff
L1BAB
        .byte   $ff
L1BAC
        .byte   $ff
L1BAD
        .byte   $00
L1BAE
        .byte   $00
L1BAF
        .byte   $3c
L1BB0
        .byte   $3c
L1BB1
        .byte   $3c
        .byte   $3c
L1BB3
        .byte   $3c
L1BB4
        .byte   $3c
L1BB5
        .byte   $3c
L1BB6
        .byte   $3c
        .byte   $00
L1BB8
        .byte   $00
        .byte   $3f
L1BBA
        .byte   $3f
L1BBB
        .byte   $3f
L1BBC
        .byte   $3f
L1BBD
        .byte   $3c
L1BBE
        .byte   $3c
L1BBF
        .byte   $00
        .byte   $00
L1BC1
        .byte   $fc
L1BC2
        .byte   $fc
        .byte   $fc
        .byte   $fc
        .text   "<<<<"
        .byte   $fc
        .byte   $fc
        .byte   $fc
        .byte   $fc
        .byte   $00
        .byte   $00
        .text   "<<????"
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $ff
        .byte   $ff
        .byte   $ff
        .byte   $ff
        .byte   $3c
        .byte   $3c
        .fill   8,$00
        .byte   $3c
        .byte   $3c
        .byte   $fc
        .byte   $fc
        .byte   $fc
        .byte   $fc
        .text   "<<<<????<<"
        .byte   $00
        .byte   $00
        .byte   $18
        .byte   $3c
        .byte   $3c
        .byte   $18
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $18
        .byte   $3c
        .byte   $7e
        .byte   $7e
        .byte   $3c
        .byte   $18
        .byte   $00
        .byte   $1c
        .byte   $3e
        .byte   $70
        .byte   $60
        .byte   $60
        .byte   $70
        .byte   $3e
        .byte   $1c
        .byte   $3c
        .byte   $7e
        .byte   $6a
        .byte   $6a
        .byte   $6a
        .byte   $7e
        .byte   $2a
        .byte   $2a
        .byte   $3c
        .byte   $7e
        .byte   $6a
        .byte   $6a
        .byte   $6a
        .byte   $7e
        .byte   $54
        .byte   $54
        .byte   $18
        .byte   $3c
        .byte   $7e
        .byte   $e7
        .byte   $c3
        .byte   $c3
        .byte   $42
        .byte   $00
        .byte   $18
        .byte   $3c
        .byte   $7e
        .byte   $7e
        .byte   $7e
        .byte   $3c
        .byte   $18
        .byte   $00
        .byte   $08
        .byte   $18
        .byte   $3c
        .byte   $3c
        .byte   $7e
        .byte   $7e
        .byte   $ff
        .byte   $18
        .byte   $06
        .byte   $8e
        .byte   $7e
        .byte   $3e
        .byte   $1e
        .byte   $02
        .byte   $02
        .byte   $07
        .byte   $e0
        .byte   $58
        .byte   $44
        .byte   $22
        .byte   $77
        .byte   $77
        .byte   $77
        .byte   $22
        .byte   $08
        .byte   $1c
        .byte   $ff
        .byte   $7e
        .byte   $3c
        .byte   $7e
        .byte   $63
        .byte   $41
        .byte   $00
        .byte   $18
        .byte   $3f
        .byte   $7d
        .byte   $7f
        .byte   $7e
        .byte   $7e
        .byte   $7e
        .byte   $0f
        .byte   $08
        .byte   $0f
        .byte   $08
        .byte   $08
        .byte   $78
        .byte   $78
        .byte   $70
        .byte   $38
        .byte   $7c
        .byte   $0e
        .byte   $06
        .byte   $06
        .byte   $0e
        .byte   $7c
        .byte   $38
        .byte   $00
        .byte   $42
        .byte   $c3
        .byte   $c3
        .byte   $e7
        .byte   $7e
        .byte   $3c
        .byte   $00
        .byte   $c3
        .byte   $e7
        .byte   $7e
        .byte   $3c
        .byte   $3c
        .byte   $7e
        .byte   $e7
        .byte   $c3
        .byte   $89
        .byte   $4a
        .byte   $2c
        .byte   $ff
        .byte   $18
        .byte   $34
        .byte   $52
        .byte   $91
        .byte   $00
        .byte   $40
        .byte   $00
        .byte   $02
        .byte   $00
        .byte   $00
        .byte   $02
        .byte   $20
        .byte   $00
        .byte   $00
        .text   $07,$1f,"?8"
        .fill   5,$70
        .text   "8?",$1f,$07
        .fill   6,$00
        .byte   $fc
        .byte   $f8
        .byte   $f0
        .fill   9,$00
        .byte   $f0
        .byte   $f8
        .byte   $fc
        .fill   12,$00
        .text   "<b@<"
        .byte   $02
        .byte   $42
        .byte   $3c
        .byte   $00
        .text   $1c,$22,"@@@",$22,$1c
        .byte   $00
        .byte   $18
        .text   "$bbb$"
        .byte   $18
        .byte   $00
        .byte   $7c
        .byte   $42
        .byte   $42
        .byte   $7c
        .byte   $48
        .byte   $44
        .byte   $42
        .byte   $00
        .byte   $7e
        .byte   $40
        .byte   $40
        .byte   $70
        .byte   $40
        .byte   $40
        .byte   $7e
        .byte   $00
        .byte   $42
        .byte   $42
        .byte   $42
        .byte   $7e
        .byte   $42
        .byte   $42
        .byte   $42
        .byte   $00
        .byte   $1c
        .fill   5,$08
        .byte   $1c
        .byte   $00
        .text   $1c,$22,"@nb",$22,$1c
        .byte   $00
        .text   "         e6fa            d011            297f            858f "
        .text   "           38              a5f9            e58f            85f"
        .text   "9            a5fa            e900            85fa            1"
        .text   "8              20@sdh          aa              68             "
        .text   " a8              "
L1E00
        .fill   164,$20
L1EA4
        .fill   92,$20
L1F00
        .fill   256,$20
