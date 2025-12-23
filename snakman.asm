; Target assembler: 64tass v1.59.3120 [--ascii --case-sensitive -Wall]
; 6502bench SourceGen v1.10.0
        .cpu    "6502"
COLOR_BLACK =   0
FREQ_OFF =      0                   ;setting oscillator freq to this value turns the oscillator off
COLOR_WHITE =   1
COLOR_RED =     2
COLOR_CYAN =    3
COLOR_PURPLE =  4
LOW_VOL =       $05
COLOR_BLUE =    6
COLOR_YELLOW =  7
HALF_VOL =      $08
CHARCODE_SNAK_RIGHT = $0d
CHARCODE_GHOST1 = $0e
MAX_VOL =       $0f
CHARCODE_SNAK_DOWN = $10
CHARCODE_SNAK_CLOSED = $11
CHARCODE_TREE = $12
CHARCODE_FLAG = $13
CHARCODE_CHERRY = $14
CHARCODE_STAR = $15
CHARCODE_MUSICNOTE = $17
CHARCODE_SNAK_LEFT = $18
CHARCODE_SNAK_UP = $19
CHARCODE_EMPTY = $20
JOYBIT_FIRE =   $20
CHARCODE_NUM0 = $30
KEYCODE_E =     $45
KEYCODE_J =     $4a
KEYCODE_L =     $4c
KEYCODE_V =     $56
INTERLACE_BIT = $80
JOYBIT_RIGHT =  $80
KEYCODE_F1 =    $85

counter0 =      $00                 ;maybe a timer for sound effects?
CHARCODE_MILKJUG = $16
BONUS_SPOTHI =  $1e
HUD_BONUS_SPOTHI = $1f
HUD_GHOST_SPOTHI = $1f
BONUS_SPOTLO =  $a4
NDX     =       $c6                 ;Number of Characters in Keyboard Buffer queue
HUD_BONUS_SPOTLO = $e7
HUD_GHOST_SPOTLO = $f1
SCREENPTR2LO =  $f7                 ;2nd pointer into screen memory used when copying and comparing between 2 screen locations
SCREENPTR2HI =  $f8
SCREENPTRLO =   $f9                 ;pointer into screen memory
SCREENPTRHI =   $fa
FREKZP  =       $fb                 ;Free Zero Page space for User Programs
KEYD    =       $0277               ;Keyboard Buffer Queue (FIFO)
TODSNS  =       $02a2               ;TOD sense during Tape I/O
CINV    =       $0314               ;Vector: Hardware IRQ Interrupt ($ea31)
VICSCN  =       $0400               ;start of Default Screen Video Matrix
BONUS_SPOT =    $1ea4               ;location on screen when bonus items spawn
OSC1_FREQ =     $900a               ;oscillator 1 frequency register (on:128-255)
OSC3_FREQ =     $900c               ;oscillator 3 frequency register (on:128-255)
NOISE_FREQ =    $900d               ;noise source frequency
VOLUME  =       $900e               ;volume register (bits 4-7 also control some color stuff that isn't used in this)
VIA1_PORTAOUT = $9111               ;port A output register
TIMER1LO =      $9114
VIA1_INTENABLE = $911e              ;via 1 interrupt enable register
VIA2_PORTBOUT = $9120
VIA2_DATADIRECTION = $9122
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
        sta     VIA1_INTENABLE      ;poke 0x7F to VIA 1 interrupt enable register (what does this do?)
        jsr     init
        jsr     L1491
        lda     #$ff
        sta     $9005               ;set start of character memory to 0x1C00 and dont modify screen memory location
        lda     VIA1_PORTAOUT       ;check if fire held, if so, enable interlace mode
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
        sta     CINV                ;set irq handler to $1356
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
        lda     VIA1_PORTAOUT       ;check that fire button is pressed
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
        beq     _no_input           ;jump to return if there was no input
        ldy     KEYD                ;load first character of input buffer into Y
        ldx     #$00
_shift
        lda     KEYD+1,x            ;shift the rest of the buffer forward
        sta     KEYD,x
        inx
        cpx     NDX
        bne     _shift
        tya                         ;transfer character read into A for return
_no_input
        rts

L10D8
        lda     L1BA9
        sta     SCREENPTRLO
        pha
        lda     L1BAA
        sta     SCREENPTRHI
        pha
        ldy     input_direction
        jsr     handle_input
        cmp     #$0b
        bcs     _L1105
        pla
        sta     SCREENPTRHI
        pla
        sta     SCREENPTRLO
        pha
        lda     SCREENPTRHI
        pha
        ldy     L1BAB
        jsr     handle_input
        cmp     #$0b
        bcs     _L1105
        pla
        pla
        rts

_L1105
        beq     _L113A
        cmp     #$0c
        beq     _L1150
        cmp     #$10
        bcs     _L1112
        jmp     _L11AC

_L1112
        cmp     #$18
        bcc     _L1177
_L1116
        lda     L120B,y
        sty     L1BAB
        ldx     #COLOR_YELLOW
        sec
        jsr     jmp_draw_char1
        lda     SCREENPTRLO
        sta     L1BA9
        lda     SCREENPTRHI
        sta     L1BAA
        pla
        sta     SCREENPTRHI
        pla
        sta     SCREENPTRLO
        lda     #CHARCODE_EMPTY
        ldx     #COLOR_BLACK
        sec
        jmp     jmp_draw_char1

_L113A
        lda     #$10
        ldx     #$00
        jsr     _L11D1
        lda     #$ff
        sta     L1BBF
        lda     #$06
        sta     $01
        dec     L1BBA
        jmp     _L1116

_L1150
        lda     #$50
        ldx     #$00
        jsr     _L11D1
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
        jmp     _L1116

_L1177
        sec
        sbc     #$12
        tax
        lda     _L11F5,x
        tax
        lda     #$00
        jsr     _L11D1
        tya
        pha
        lda     SCREENPTRLO
        pha
        lda     SCREENPTRHI
        pha
        lda     #$e7
        ldy     #$1f
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        ldy     #$05
_L1196
        lda     #CHARCODE_EMPTY
        ldx     #COLOR_BLACK
        sec
        jsr     jmp_draw_char2
        dey
        bpl     _L1196
        pla
        sta     SCREENPTRHI
        pla
        sta     SCREENPTRLO
        pla
        tay
        jmp     _L1116

_L11AC
        bit     L1BBE
        bpl     _L11C9
        lda     #$ff
        sta     L1BC1
        inc     ghost_eat_streak
        ldx     ghost_eat_streak
        dex
        lda     GHOST_POINTS_ARR2,x
        tax                         ;load points for just eaten ghost into X
        lda     #$00
        jsr     _L11D1
        jmp     _L1116

_L11C9
        lda     #$ff
        sta     L1BBB
        pla
        pla
        rts

_L11D1
        sta     L1B8C
        stx     L1B8B
        tya
        pha
        lda     SCREENPTRLO
        pha
        lda     SCREENPTRHI
        pha
        jsr     L148E
        lda     #$00
        ldy     #$03
_L11E6
        sta     L1B89,y
        dey
        bpl     _L11E6
        pla
        sta     SCREENPTRHI
        pla
        sta     SCREENPTRLO
        pla
        tay
        rts

_L11F5
        .byte   $20
        .byte   $05
        .byte   $20
        .byte   $10
        .byte   $02
        .byte   $01
        .logical $11fb
GHOST_POINTS_ARR2
        .byte   $01                 ;seems like an identical table to GHOST_POINTS_ARR
        .byte   $02
        .byte   $04
        .byte   $08
        .byte   $16
        .byte   $24
        .byte   $32
        .byte   $40
        .byte   $48
        .byte   $56
        .byte   $64
        .byte   $72
        .here
        .logical $1207
SCREEN_STRIDES
        .byte   1                   ;right
        .byte   $96                 ;-22 with sign-magnitude
        .byte   22
        .byte   $81                 ;left, -1 with sign-magnitude
        .here
L120B
        .byte   $0d
        .byte   $19
        .byte   $10
        .byte   $18

handle_input
        tya
        pha                         ;push direction to stack for later use
        lda     SCREEN_STRIDES,y
        bmi     _negative_dir       ;branch if moving in negative direction along either axis
        clc
        adc     SCREENPTRLO         ;increment screenptr to next cell
        sta     SCREENPTRLO
        bcc     _join
        inc     SCREENPTRHI         ;16-bit add, need to increment the high byte too if there was a carry
        bne     _join
_negative_dir
        and     #$7f                ;clear sign bit to extract magnitude
        sta     $8f
        sec
        lda     SCREENPTRLO         ;decrement screenptr to next cell
        sbc     $8f
        sta     SCREENPTRLO
        lda     SCREENPTRHI
        sbc     #$00                ;subtract carry bit
        sta     SCREENPTRHI
_join
        clc
        jsr     jmp_draw_char1
        tax                         ;temporarily transfer accumulator to X so that stack operations can be done
        pla                         ;pop direction from stack and move it to Y
        tay
        txa
        rts

move_ghosts
        lda     #$8d                ;call move_ghost for each of the 4 ghosts
        ldy     #$1b
        jsr     move_ghost
        lda     #$94
        ldy     #$1b
        jsr     move_ghost
        lda     #$9b
        ldy     #$1b
        jsr     move_ghost
        lda     #$a2
        ldy     #$1b
        jmp     move_ghost

move_ghost
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
        lda     TIMER1LO
        and     #$03                ;get random 0-3 value from timer1
        clc                         ;picking random direction for ghost to move in
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
        lda     SCREEN_STRIDES2,y
        bne     _can_move           ;not so sure this is actually about a move being blocked or not, but somehow its about a valid move delta vs 0 being read from the array
        jmp     _move_blocked

_can_move
        bmi     _L12A0
        clc
        adc     L1BB0
        sta     SCREENPTRLO
        lda     #$00
        adc     L1BB1
        sta     SCREENPTRHI
        bne     _L12B3
_L12A0
        and     #$7f
        sta     $a7
        sec
        lda     L1BB0
        sbc     $a7
        sta     SCREENPTRLO
        lda     L1BB1
        sbc     #$00
        sta     SCREENPTRHI
_L12B3
        clc
        jsr     jmp_draw_char1
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
        lda     SCREENPTRLO
        pha
        lda     SCREENPTRHI
        pha
        lda     L1BB0
        sta     SCREENPTRLO
        lda     L1BB1
        sta     SCREENPTRHI
        lda     L1BB5
        ldx     L1BB6
        sec
        jsr     jmp_draw_char1
        pla
        sta     L1BB1
        sta     SCREENPTRHI
        pla
        sta     L1BB0
        sta     SCREENPTRLO
        pla
        sta     L1BB6
        pla
        sta     L1BB5
        lda     #CHARCODE_GHOST1
        ldx     L1BB3
        sec
        jsr     jmp_draw_char1
_move_blocked
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
        .logical $1351
SCREEN_STRIDES2
        .byte   1                   ;right
        .byte   $81                 ;left, -1 with sign-magnitude
        .byte   22
        .byte   $96                 ;-22 with sign-magnitude
        .byte   $00                 ;0 for not moving?
        .here

        inc     $3f
        bne     _L135C
        inc     $40
_L135C
        bit     L1BBE
        bpl     _L136F
        jsr     L16BA
        bit     L1BBE
        bpl     _L136F
        jsr     draw_ghost_points
        jmp     _L1372

_L136F
        jsr     L144B
_L1372
        jsr     jmp_get_input       ;get joystick input
        lda     #$00                ;then keyboard input
        sta     NDX                 ;clear input buffer
        jsr     scnkey              ;read one keypress
        jsr     key_input
        cmp     #KEYCODE_E
        beq     _up
        cmp     #KEYCODE_V
        beq     _down
        cmp     #KEYCODE_J
        beq     _left
        cmp     #KEYCODE_L
        bne     _no_input
        lda     #$00
        .byte   $2c
_up
        lda     #$01
        .byte   $2c
_down
        lda     #$02
        .byte   $2c
_left
        lda     #$03
        sta     input_direction     ;store direction as value 0-3 (0: right, 1: up, 2: down, 3: left)
_no_input
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
        jsr     move_ghosts
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
        bcc     _space_occupied
        lda     #$00
        sta     $3f
        sta     $40
        lda     BONUS_SPOT
        cmp     #CHARCODE_EMPTY
        bne     _space_occupied     ;if empty, spawn a bonus item maybe?
        lda     #BONUS_SPOTLO
        ldy     #BONUS_SPOTHI
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        lda     TIMER1LO
        and     #$07                ;get "random" value 0-7 from timer1
        pha
        jsr     draw_bonus          ;draw bonus item in maze
        lda     #HUD_BONUS_SPOTLO
        ldy     #HUD_BONUS_SPOTHI
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        pla
        pha
        jsr     draw_bonus          ;draw bonus item on hud
        pla
        inc     SCREENPTRLO         ;move screen points a few characters to the right
        inc     SCREENPTRLO
        tay
        lda     BONUS_POINTS_ARR,y
        jsr     jmp_draw_points
_space_occupied
        jmp     L16B4

        .logical $1428
BONUS_SPRITES_ARR
        .byte   CHARCODE_TREE
        .byte   CHARCODE_CHERRY
        .byte   CHARCODE_FLAG
        .byte   CHARCODE_STAR
        .byte   CHARCODE_MUSICNOTE
        .byte   CHARCODE_MILKJUG
        .byte   CHARCODE_MUSICNOTE
        .byte   CHARCODE_MILKJUG
        .here
        .logical $1430
BONUS_COLORS_ARR
        .byte   COLOR_BLUE
        .byte   COLOR_RED
        .byte   COLOR_YELLOW
        .byte   COLOR_CYAN
        .byte   COLOR_YELLOW
        .byte   COLOR_PURPLE
        .byte   COLOR_YELLOW
        .byte   COLOR_PURPLE
        .here
        .logical $1438
BONUS_POINTS_ARR
        .byte   $20                 ;tree points, 2000
        .byte   $20                 ;cherry points, 2000
        .byte   $05                 ;flag points, 500
        .byte   $10                 ;star points, 1000
        .byte   $01                 ;music note points, 100
        .byte   $02                 ;milk jug points, 200
        .byte   $01                 ;music note points, 100
        .byte   $02                 ;milk jug points, 200
        .here

draw_bonus
        tay
        lda     BONUS_SPRITES_ARR,y
        ldx     BONUS_COLORS_ARR,y
        sec
        jmp     jmp_draw_char1

L144B
        lda     #$f1
        ldy     #$1f
        sta     SCREENPTRLO
        sty     SCREENPTRHI
_L1453
        ldx     #COLOR_BLACK
        lda     #CHARCODE_EMPTY
        sec
        jsr     jmp_draw_char2
        dey
        bpl     _L1453
        rts

draw_ghost_points
        lda     #HUD_GHOST_SPOTLO   ;draws ghost icon + points on hud
        ldy     #HUD_GHOST_SPOTHI
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        lda     #CHARCODE_GHOST1
        ldx     #COLOR_WHITE
        sec
        jsr     jmp_draw_char1
        inc     SCREENPTRLO         ;move screen pointer a couple characters to the right for the number
        inc     SCREENPTRLO
        ldy     ghost_eat_streak
        lda     GHOST_POINTS_ARR,y  ;load points for next ghost for drawing to screen
        jmp     jmp_draw_points

        .logical $147c
GHOST_POINTS_ARR
        .byte   $01                 ;consecutive ghost point values in BCD
        .byte   $02
        .byte   $04
        .byte   $08
        .byte   $16
        .byte   $24
        .byte   $32
        .byte   $40
        .byte   $48
        .byte   $56
        .byte   $64
        .byte   $72
        .here

jmp_draw_char1
        jmp     draw_char1

jmp_draw_char2
        jmp     draw_char2

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

draw_char1
        ldy     #$00
draw_char2
        bcs     _L14C4
        lda     SCREENPTRHI
        pha
        adc     #$78
        sta     SCREENPTRHI
        lda     (SCREENPTRLO),y
        tax
        pla
        sta     SCREENPTRHI
        lda     (SCREENPTRLO),y
        clc
        rts

_L14C4
        sta     (SCREENPTRLO),y
        pha
        lda     SCREENPTRHI
        pha
        clc
        adc     #$78
        sta     SCREENPTRHI
        txa
        sta     (SCREENPTRLO),y
        pla
        sta     SCREENPTRHI
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
        sta     SCREENPTRLO
        lda     #$1e
        sta     SCREENPTRHI
        lda     #$80
        sta     FREKZP
        lda     #$1b
        sta     $fc
        jsr     _L150D
        lda     #$21
        sta     SCREENPTRLO
        lda     #$1e
        sta     SCREENPTRHI
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
        inc     SCREENPTRLO
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
        sta     VIA2_DATADIRECTION  ;set VIA2 port B data direction to input
        lda     VIA2_PORTBOUT       ;check if joystick right pressed
        eor     #$ff                ;(*0x9122 ^ 0xFF) & 0x80 -- flip bits with XOR cause active low
        and     #JOYBIT_RIGHT
        rol     a                   ;move joy right bit to carry flag
        php
        lda     #$ff
        sta     VIA2_DATADIRECTION  ;set VIA2 port B data direction to input
        lda     VIA1_PORTAOUT       ;check other joystick directions
        eor     #$ff                ;convert joystick input bits from bits 2-4 of VIA_PORTAOUT to bits 0-2 of A
        and     #$1c                ;((*0x9111 ^ 0xFF) & 0b00011100) >> 2
        lsr     a
        lsr     a
        plp                         ;restore flags
        rol     a                   ;and shift the input bits left by 1, putting the carry flag (joystick right) into bit 0
        cmp     #$01
        beq     _right
        cmp     #$02
        beq     _up
        cmp     #$04
        beq     _down
        cmp     #$08
        bne     _end_input          ;no direction was input
        lda     #$03
        .byte   $2c
_right
        lda     #$00
        .byte   $2c
_up
        lda     #$01
        .byte   $2c
_down
        lda     #$02
        sta     input_direction     ;store direction as value 0-3 (0: right, 1: up, 2: down, 3: left)
_end_input
        rts

L15A2
        lda     L1BA9
        ldy     L1BAA
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        clc
        jsr     jmp_draw_char1
        cmp     #$11
        bne     _L15C4
        lda     L1BAB
        beq     _L15C7
        cmp     #$01
        beq     _L15CA
        cmp     #$02
        beq     _L15CD
        lda     #CHARCODE_SNAK_LEFT
        .byte   $2c
_L15C4
        lda     #CHARCODE_SNAK_CLOSED
        .byte   $2c
_L15C7
        lda     #CHARCODE_SNAK_RIGHT
        .byte   $2c
_L15CA
        lda     #CHARCODE_SNAK_UP
        .byte   $2c
_L15CD
        lda     #CHARCODE_SNAK_DOWN
L15CF
        ldx     #COLOR_YELLOW
L15D1
        sec
        jmp     jmp_draw_char1

L15D5
        lda     L1BA9
        ldy     L1BAA
L15DB
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        lda     #$b4
        ldy     #$16
        sta     CINV                ;set irq handler to $16b4
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
        lda     #$56                ;set irq handler to $1356
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
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        sta     L1BA9
        sty     L1BAA
        lda     #$01
        sta     L1BAB
        sta     input_direction     ;start game facing up
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
        sta     SCREENPTRLO
        iny
        lda     ($8d),y
        sta     SCREENPTRHI
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
        lda     GHOST_COLORS_ARR,x
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
        sta     SCREENPTRLO
        iny
        lda     ($8d),y
        sta     SCREENPTRHI
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

L16BA
        jmp     L16F0

L16BD
        jmp     L1721

L16C0
        jmp     L17A0

jmp_draw_points
        jmp     draw_points

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
        sta     SCREENPTRLO
        lda     #$1e                ;looks to be the screen address of one character left of the lives counter area
        sta     SCREENPTRHI
        ldy     loop1+2
        lda     #CHARCODE_EMPTY
        ldx     #COLOR_BLACK
_L16E4
        iny
        cpy     #$04
        beq     _L16EF
        sec
        jsr     jmp_draw_char2
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
        sta     ghost_eat_streak    ;reset ghost eating streak to 0
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
        sta     SCREENPTRLO
        sta     ($8d),y
        iny
        lda     #$1e
        sta     SCREENPTRHI
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
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        txa
        pha
        clc
        jsr     jmp_draw_char1
        eor     #$01
        tay
        pla
        tax
        tya
L17DD
        sec
        jmp     jmp_draw_char1

L17E1
        jsr     udtim
        jmp     $eb15

draw_points
        pha                         ;draw ghost and bonus item points
        lsr     a
        lsr     a
        lsr     a
        lsr     a
        bne     _L17F9
        lda     #CHARCODE_EMPTY
        ldx     #COLOR_BLACK
_L17F2
        jsr     L17DD
        inc     SCREENPTRLO
        bne     _L17FF
_L17F9
        ora     #CHARCODE_NUM0      ;add offset from charcode for '0'
        ldx     #COLOR_YELLOW
        bne     _L17F2

_L17FF
        pla
        and     #$0f
        ora     #CHARCODE_NUM0      ;add offset from charcode for '0'
        ldx     #COLOR_YELLOW
        jsr     L17DD
        inc     SCREENPTRLO
        lda     #CHARCODE_NUM0      ;draw 2 trailing 0s
        jsr     jmp_draw_char1
        inc     SCREENPTRLO
        jmp     jmp_draw_char1

snd_reset
        lda     #$00                ;sets all oscillator freqs to 0 and volume to 0
        ldy     #$04
_loop
        sta     OSC1_FREQ,y
        dey
        bpl     _loop
        rts

L1820
        clc
        lda     #$9f
        adc     #$57
        sta     SCREENPTRLO
        lda     #$1b
        adc     #$01
        sta     SCREENPTRHI
        lda     #$57
        sta     SCREENPTR2LO
        lda     #$1d
        sta     SCREENPTR2HI
        ldy     #$00
_L1837
        lda     (SCREENPTRLO),y
        sta     (SCREENPTR2LO),y
        lda     SCREENPTRLO
        bne     _L1841
        dec     SCREENPTRHI
_L1841
        dec     SCREENPTRLO
        lda     SCREENPTR2LO
        bne     _L1849
        dec     SCREENPTR2HI
_L1849
        dec     SCREENPTR2LO
        lda     SCREENPTR2HI
        cmp     #$1b
        bne     _L1837
        lda     #$00
        ldy     #$1d
        sta     SCREENPTR2LO
        sta     SCREENPTRLO
        sty     SCREENPTR2HI
        lda     #$81
        sta     SCREENPTRHI
        ldy     #$ff
_L1861
        lda     (SCREENPTRLO),y
        sta     (SCREENPTR2LO),y
        dey
        cpy     #$57
        bne     _L1861
        rts

L186B
        lda     #$b4                ;set irq handler to 16b4
        ldy     #$16
        sta     CINV
        sty     CINV+1
        lda     #$08
        sta     $900f               ;set screen and border color: background: 1000 inverted: 0 border: 000
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
        ldy     #$1a                ;not in screenmem, maybe screenptr2 isnt actually pointing to screen mem
        sta     SCREENPTR2LO
        sty     SCREENPTR2HI
        lda     #$2b
        ldy     #$1e                ;not sure what this is, its just above the top right corner of maze, maybe last spot the score extends into
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        ldx     #$00
        txa
        pha
        ldy     #$00
_L18A0
        inc     SCREENPTR2LO
        bne     _L18A6
        inc     SCREENPTR2HI
_L18A6
        lda     (SCREENPTR2LO),y
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
        lda     #$1e                ;screen address of leftmost cell of ghost home
        sta     SCREENPTRHI
        lda     #$fb
        sta     SCREENPTRLO
        ldy     #$03
_loop
        ldx     GHOST_COLORS_ARR,y
        lda     #CHARCODE_GHOST1
        sec
        jsr     jmp_draw_char2
        dey
        bpl     _loop
        lda     #$56                ;set irq handler to 1356
        ldy     #$13
        sta     CINV
        sty     CINV+1
        rts

_L18E1
        inc     SCREENPTRLO
        bne     _L18E7
        inc     SCREENPTRHI
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
        .byte   $93
        .byte   $9e
        .byte   $28
        .byte   $29
        .byte   $2a
        .byte   $28
        .byte   $20
        .byte   $23
        .byte   $24
        .byte   $25
        .byte   $26
        .byte   $27
        .byte   $20
        .byte   $0d
        .byte   $9e
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $23
        .byte   $24
        .byte   $25
        .byte   $26
        .byte   $27
        .byte   $20
        .byte   $0d
        .byte   $13
        .byte   $00

L191C
        lda     counter0
        cmp     #$0c
        bcc     _skip_clamp
_wrap_counter
        lda     #$0b
        sta     counter0
_skip_clamp
        dec     counter0
        bmi     _wrap_counter
        bit     L1BBE
        bmi     play_powerup_sound  ;play powerup sound if high bit of 1BBE is set
        ldy     counter0
        lda     SFX1,y
        sta     OSC3_FREQ
        lda     #LOW_VOL
        sta     VOLUME
        lda     $01                 ;if *0x01 != 0, play the pellet sound alongside normal sound
        beq     _no_pellet_sound
        tay
        dec     $01                 ;clear pellet eat flag
        lda     #MAX_VOL
        sta     VOLUME
        lda     SFX2,y
_no_pellet_sound
        sta     OSC1_FREQ
        rts

        .logical $194f
SFX1
        .byte   216                 ;sound effect played by OSC3 (high)
        .byte   218                 ;maybe the normal background sound played all the time
        .byte   220
        .byte   222
        .byte   224
        .byte   226
        .byte   225
        .byte   223
        .byte   221
        .byte   219
        .byte   217
        .byte   215
        .here
        .logical $195b
SFX2
        .byte   FREQ_OFF            ;sound effect played by OSC1 (low)
        .byte   144                 ;maybe the sound played when eating pellets
        .byte   146
        .byte   148
        .byte   150
        .byte   148
        .byte   146
        .byte   144
        .here

play_powerup_sound
        lda     L1BBD
        bne     _L196F
        lda     L1BBC
        cmp     #$40
        bcc     _power_end_tone
_L196F
        lda     #FREQ_OFF
        sta     OSC1_FREQ
        lda     #MAX_VOL
        sta     VOLUME
        ldy     counter0
        lda     SFX_POWERUP,y       ;play repeated falling sound when powerup is active
        sta     OSC3_FREQ
        rts

_power_end_tone
        lda     #HALF_VOL           ;play single tone at end of powerup time
        sta     VOLUME
        lda     #216
        sta     OSC3_FREQ
        rts

        .logical $198d
SFX_POWERUP
        .byte   216                 ;sound effect played by OSC3 (high)
        .byte   217
        .byte   218
        .byte   219
        .byte   220
        .byte   221
        .byte   222
        .byte   223
        .byte   224
        .byte   225
        .byte   226
        .byte   227
        .here

L1999
        jsr     L16C0
        jsr     _L1A2F
        jsr     jmp_snd_reset
        lda     #205
        sta     OSC3_FREQ
        lda     #MAX_VOL
        sta     VOLUME
        cli
_L19AD
        lda     $a2
        cmp     #$03
        bne     _L19AD
        lda     #$00
        sta     $a2
        dec     OSC3_FREQ           ;i think this might be the falling tone that plays when dying?
        lda     OSC3_FREQ
        cmp     #$a5
        bne     _L19AD
        sei
        jsr     jmp_snd_reset
        lda     #MAX_VOL
        sta     VOLUME
        lda     #128
        sta     NOISE_FREQ
        sta     OSC1_FREQ
        lda     #$00
        sta     $a2
        lda     L1BA9
        ldy     L1BAA
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        lda     #$1a
        jsr     _L1A3F
        cli
_L19E6
        lda     $a2
        cmp     #$04
        bcc     _L19E6
        lda     #$1b
        jsr     _L1A3F
        dec     VOLUME
_L19F4
        lda     $a2
        cmp     #$09
        bcc     _L19F4
        lda     #$1c
        jsr     _L1A3F
        dec     VOLUME
_L1A02
        lda     $a2
        cmp     #$0e
        bcc     _L1A02
        lda     #$20
        ldx     #$00
        jsr     _L1A41
_L1A0F
        dec     VOLUME
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
        lda     #$13                ;set irq handler to $1356
        sta     CINV+1
        lda     #$56
        sta     CINV
        rts

_L1A2F
        sei
        lda     #$b4                ;set irq handler to $16b4 and reset $a2 (whatever that is)
        ldy     #$16
        sta     CINV
        sty     CINV+1
        lda     #$00
        sta     $a2
        rts

_L1A3F
        ldx     #COLOR_YELLOW
_L1A41
        sec
        jmp     jmp_draw_char1

        .byte   $31
        .byte   $11
        .byte   $11
        .byte   $11
        .byte   $11
        .byte   $11
        .byte   $11
        .byte   $11
        .byte   $11
        .byte   $11
        .byte   $14
        .byte   $2b
        .byte   $bb
        .byte   $cb
        .byte   $bb
        .byte   $bb
        .byte   $bb
        .byte   $bb
        .byte   $bb
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
        .logical $1b21
GHOST_COLORS_ARR
        .byte   COLOR_RED
        .byte   COLOR_YELLOW
        .byte   COLOR_PURPLE
        .byte   COLOR_CYAN
        .here
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
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
        lda     SCREENMEMLO,y
        jsr     init_vram
        lda     SCREENMEMHI,y
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
        cmp     #CHARCODE_EMPTY
L1B90
        beq     return
        bne     loop2

inc_counter0
        inc     counter0
return
        rts

        .logical $1b97
L1B97
        .byte   %00010010           ;unknown tile? or variable space?
        .byte   %00000101
        .byte   %00000001
        .byte   %00000100
L1B9B
        .byte   %00011001
L1B9C
        .byte   %00101110
        .byte   %00010101
L1B9E
        .byte   %00001110
        .here
        .logical $1b9f
        .byte   %00101000           ;ghost home door tile
        .byte   %00010100           ;this seems to be character number 1 in the character set, but its here instead of at 1C00??
        .byte   %00101000           ;so charcode 0
L1BA2
        .byte   %00010100
L1BA3
        .byte   %00101000
        .byte   %00010100
L1BA5
        .byte   %00101000
        .byte   %00010100
        .here
        .logical $1ba7
        .byte   %00000000           ;horizontal wall tile
        .byte   %00000000           ;charcode 0x01
L1BA9
        .byte   %11111111
L1BAA
        .byte   %11111111
L1BAB
        .byte   %11111111
L1BAC
        .byte   %11111111
L1BAD
        .byte   %00000000
L1BAE
        .byte   %00000000
        .here
        .logical $1baf
L1BAF
        .byte   %00111100           ;vertical wall tile
L1BB0
        .byte   %00111100           ;charcode 0x02
L1BB1
        .byte   %00111100
        .byte   %00111100
L1BB3
        .byte   %00111100
L1BB4
        .byte   %00111100
L1BB5
        .byte   %00111100
L1BB6
        .byte   %00111100
        .here
        .logical $1bb7
        .byte   %00000000           ;top left corner tile
input_direction
        .byte   %00000000           ;charcode 0x03
        .byte   %00111111
L1BBA
        .byte   %00111111
L1BBB
        .byte   %00111111
L1BBC
        .byte   %00111111
L1BBD
        .byte   %00111100
L1BBE
        .byte   %00111100
        .here
        .logical $1bbf
L1BBF
        .byte   %00000000           ;top right corner tile
        .byte   %00000000           ;charcode 0x04
L1BC1
        .byte   %11111100
ghost_eat_streak
        .byte   %11111100
        .byte   %11111100
        .byte   %11111100
        .byte   %00111100
        .byte   %00111100
        .here
        .logical $1bc7
        .byte   %00111100           ;bottom right corner tile
        .byte   %00111100           ;charcode 0x05
        .byte   %11111100
        .byte   %11111100
        .byte   %11111100
        .byte   %11111100
        .byte   %00000000
        .byte   %00000000
        .here
        .logical $1bcf
        .byte   %00111100           ;bottom left corner tile
        .byte   %00111100           ;charcode 0x06
        .byte   %00111111
        .byte   %00111111
        .byte   %00111111
        .byte   %00111111
        .byte   %00000000
        .byte   %00000000
        .here
        .logical $1bd7
        .byte   %00000000           ;downward T tile
        .byte   %00000000           ;charcode 0x07
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %11111111
        .byte   %00111100
        .byte   %00111100
        .here
        .logical $1bdf
        .byte   %00000000           ;empty tile
        .byte   %00000000           ;charcode 0x08
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .here
        .logical $1be7
        .byte   %00111100           ;leftward T tile
        .byte   %00111100           ;charcode 0x09
        .byte   %11111100
        .byte   %11111100
        .byte   %11111100
        .byte   %11111100
        .byte   %00111100
        .byte   %00111100
        .here
        .logical $1bef
        .byte   %00111100           ;rightward T tile
        .byte   %00111100           ;charcode 0x0a
        .byte   %00111111
        .byte   %00111111
        .byte   %00111111
        .byte   %00111111
        .byte   %00111100
        .byte   %00111100
        .here
        .logical $1bf7
        .byte   %00000000           ;small pellet sprite
        .byte   %00000000           ;charcode 0x0b
        .byte   %00011000
        .byte   %00111100
        .byte   %00111100
        .byte   %00011000
        .byte   %00000000
        .byte   %00000000
        .here
        .logical $1bff
        .byte   %00000000           ;power pellet sprite
        .byte   %00011000           ;charcode 0x0c
        .byte   %00111100
        .byte   %01111110
        .byte   %01111110
        .byte   %00111100
        .byte   %00011000
        .byte   %00000000
        .here
        .logical $1c07
        .byte   %00011100           ;snakman sprite right-facing
        .byte   %00111110           ;charcode 0x0d
        .byte   %01110000
        .byte   %01100000
        .byte   %01100000
        .byte   %01110000
        .byte   %00111110
        .byte   %00011100
        .here
        .logical $1c0f
        .byte   %00111100           ;ghost sprite 1
        .byte   %01111110           ;charcode 0x0e
        .byte   %01101010
        .byte   %01101010
        .byte   %01101010
        .byte   %01111110
        .byte   %00101010
        .byte   %00101010
        .here
        .logical $1c17
        .byte   %00111100           ;ghost sprite 2
        .byte   %01111110           ;charcode 0x0f
        .byte   %01101010
        .byte   %01101010
        .byte   %01101010
        .byte   %01111110
        .byte   %01010100
        .byte   %01010100
        .here
        .logical $1c1f
        .byte   %00011000           ;snakman sprite downward-facing
        .byte   %00111100           ;charcode 0x10
        .byte   %01111110
        .byte   %11100111
        .byte   %11000011
        .byte   %11000011
        .byte   %01000010
        .byte   %00000000
        .here
        .logical $1c27
        .byte   %00011000           ;snakman sprite mouth closed
        .byte   %00111100           ;charcode 0x11
        .byte   %01111110
        .byte   %01111110
        .byte   %01111110
        .byte   %00111100
        .byte   %00011000
        .byte   %00000000
        .here
        .logical $1c2f
        .byte   %00001000           ;bonus item sprite - christmas tree
        .byte   %00011000           ;charcode 0x12
        .byte   %00111100
        .byte   %00111100
        .byte   %01111110
        .byte   %01111110
        .byte   %11111111
        .byte   %00011000
        .here
        .logical $1c37
        .byte   %00000110           ;bonus item sprite - flag
        .byte   %10001110           ;charcode 0x13
        .byte   %01111110
        .byte   %00111110
        .byte   %00011110
        .byte   %00000010
        .byte   %00000010
        .byte   %00000111
        .here
        .logical $1c3f
        .byte   %11100000           ;bonus item sprite - cherries
        .byte   %01011000           ;charcode 0x14
        .byte   %01000100
        .byte   %00100010
        .byte   %01110111
        .byte   %01110111
        .byte   %01110111
        .byte   %00100010
        .here
        .logical $1c47
        .byte   %00001000           ;bonus item sprite - star
        .byte   %00011100           ;charcode 0x15
        .byte   %11111111
        .byte   %01111110
        .byte   %00111100
        .byte   %01111110
        .byte   %01100011
        .byte   %01000001
        .here
        .logical $1c4f
        .byte   %00000000           ;bonus item sprite - milk can??
        .byte   %00011000           ;charcode 0x16
        .byte   %00111111
        .byte   %01111101
        .byte   %01111111
        .byte   %01111110
        .byte   %01111110
        .byte   %01111110
        .here
        .logical $1c57
        .byte   %00001111           ;bonus item sprite - music note
        .byte   %00001000           ;charcode 0x17
        .byte   %00001111
        .byte   %00001000
        .byte   %00001000
        .byte   %01111000
        .byte   %01111000
        .byte   %01110000
        .here
        .logical $1c5f
        .byte   %00111000           ;snakman sprite left-facing
        .byte   %01111100           ;charcode 0x18
        .byte   %00001110
        .byte   %00000110
        .byte   %00000110
        .byte   %00001110
        .byte   %01111100
        .byte   %00111000
        .here
        .logical $1c67
        .byte   %00000000           ;snakman sprite upward-facing
        .byte   %01000010           ;charcode 0x19
        .byte   %11000011
        .byte   %11000011
        .byte   %11100111
        .byte   %01111110
        .byte   %00111100
        .byte   %00000000
        .here
        .logical $1c6f
        .byte   %11000011           ;snakman death frame 1
        .byte   %11100111           ;charcode 0x1a
        .byte   %01111110
        .byte   %00111100
        .byte   %00111100
        .byte   %01111110
        .byte   %11100111
        .byte   %11000011
        .here
        .logical $1c77
        .byte   %10001001           ;snakman death frame 2
        .byte   %01001010           ;charcode 0x1b
        .byte   %00101100
        .byte   %11111111
        .byte   %00011000
        .byte   %00110100
        .byte   %01010010
        .byte   %10010001
        .here
        .logical $1c7f
        .byte   %00000000           ;snakman death frame 3
        .byte   %01000000           ;charcode 0x1c
        .byte   %00000000
        .byte   %00000010
        .byte   %00000000
        .byte   %00000000
        .byte   %00000010
        .byte   %00100000
        .here
        .logical $1c87
        .byte   %00000000
        .byte   %00000000
        .byte   %00000111
        .byte   %00011111
        .byte   %00111111
        .byte   %00111000
        .byte   %01110000
        .byte   %01110000
        .here
        .logical $1c8f
        .byte   %01110000
        .byte   %01110000
        .byte   %01110000
        .byte   %00111000
        .byte   %00111111
        .byte   %00011111
        .byte   %00000111
        .byte   %00000000
        .here
        .logical $1c97
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %11111100
        .byte   %11111000
        .byte   %11110000
        .here
        .logical $1c9f
        .byte   %00000000           ;character 0x20, empty space
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .here
        .logical $1ca7
        .byte   %00000000
        .byte   %11110000
        .byte   %11111000
        .byte   %11111100
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .here
        .logical $1caf
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .byte   %00000000
        .here
        .logical $1cb7
        .byte   %00111100           ;character S
        .byte   %01000010
        .byte   %01000000
        .byte   %00111100
        .byte   %00000010
        .byte   %01000010
        .byte   %00111100
        .byte   %00000000
        .here
        .logical $1cbf
        .byte   %00011100           ;character C
        .byte   %00100010
        .byte   %01000000
        .byte   %01000000
        .byte   %01000000
        .byte   %00100010
        .byte   %00011100
        .byte   %00000000
        .here
        .logical $1cc7
        .byte   %00011000           ;character O
        .byte   %00100100
        .byte   %01000010
        .byte   %01000010
        .byte   %01000010
        .byte   %00100100
        .byte   %00011000
        .byte   %00000000
        .here
        .logical $1ccf
        .byte   %01111100           ;character R
        .byte   %01000010
        .byte   %01000010
        .byte   %01111100
        .byte   %01001000
        .byte   %01000100
        .byte   %01000010
        .byte   %00000000
        .here
        .logical $1cd7
        .byte   %01111110           ;character E
        .byte   %01000000
        .byte   %01000000
        .byte   %01110000
        .byte   %01000000
        .byte   %01000000
        .byte   %01111110
        .byte   %00000000
        .here
        .logical $1cdf
        .byte   %01000010           ;character H
        .byte   %01000010
        .byte   %01000010
        .byte   %01111110
        .byte   %01000010
        .byte   %01000010
        .byte   %01000010
        .byte   %00000000
        .here
        .logical $1ce7
        .byte   %00011100           ;character I
        .byte   %00001000
        .byte   %00001000
        .byte   %00001000
        .byte   %00001000
        .byte   %00001000
        .byte   %00011100
        .byte   %00000000
        .here
        .logical $1cef
        .byte   %00011100           ;character G
        .byte   %00100010
        .byte   %01000000
        .byte   %01001110
        .byte   %01000010
        .byte   %00100010
        .byte   %00011100
        .byte   %00000000
        .here
        .logical $1cf7
        .byte   %00100000           ;i wonder if the stuff below here is the maze layout
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .here
        .logical $1cff
        .byte   %00100000
        .byte   %01000101
        .byte   %00110110
        .byte   %01000110
        .byte   %01000001
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .here
        .logical $1d07
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .here
        .logical $1d0f
        .byte   %00100000
        .byte   %01000100
        .byte   %00110000
        .byte   %00110001
        .byte   %00110001
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .here
        .logical $1d17
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .here
        .logical $1d1f
        .byte   %00100000
        .byte   %00110010
        .byte   %00111001
        .byte   %00110111
        .byte   %01000110
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .here
        .logical $1d27
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .here
        .logical $1d30
        .byte   %00111000
        .byte   %00110101
        .byte   %00111000
        .byte   %01000110
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .here
        .logical $1d38
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .byte   %00100000
        .here
        .byte   $33
        .byte   $38
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $41
        .byte   $35
        .byte   $46
        .byte   $39
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $45
        .byte   $35
        .byte   $38
        .byte   $46
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $38
        .byte   $35
        .byte   $46
        .byte   $39
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $41
        .byte   $35
        .byte   $46
        .byte   $41
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $45
        .byte   $39
        .byte   $30
        .byte   $30
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $38
        .byte   $35
        .byte   $46
        .byte   $41
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $31
        .byte   $38
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $32
        .byte   $30
        .byte   $40
        .byte   $53
        .byte   $44
        .byte   $48
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $41
        .byte   $41
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $36
        .byte   $38
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $41
        .byte   $38
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
SCREENMEMLO
        .fill   256,$20             ;clear screen on program load
SCREENMEMHI
        .fill   256,$20
