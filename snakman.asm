; Target assembler: 64tass v1.59.3120 [--ascii --case-sensitive -Wall]
; 6502bench SourceGen v1.10.0
        .cpu    "6502"
COLOR_BLACK =   0
FREQ_OFF =      0                   ;setting oscillator freq to this value turns the oscillator off
COLOR_WHITE =   1
COLOR_RED =     2
COLOR_CYAN =    3
MAX_LIVES =     3
COLOR_PURPLE =  4
COLOR_GREEN =   5
LOW_VOL =       $05
COLOR_BLUE =    6
COLOR_YELLOW =  7
HALF_VOL =      $08
CHARCODE_SMALL_PELLET = $0b
CHARCODE_POWER_PELLET = $0c
CHARCODE_SNAK_RIGHT = $0d
CHARCODE_GHOST1 = $0e
MAX_VOL =       $0f
CHARCODE_SNAK_DOWN = $10
POINTS_SMALL_PELLET = $10           ;10 in BCD
CHARCODE_SNAK_CLOSED = $11
CHARCODE_TREE = $12
CHARCODE_FLAG = $13
CHARCODE_CHERRY = $14
CHARCODE_STAR = $15
CHARCODE_MUSICNOTE = $17
CHARCODE_SNAK_LEFT = $18
CHARCODE_SNAK_UP = $19
CHARCODE_SNAK_DEATH1 = $1a
CHARCODE_SNAK_DEATH2 = $1b
CHARCODE_SNAK_DEATH3 = $1c
CHARCODE_EMPTY = $20
JOYBIT_FIRE =   $20
CHARCODE_NUM0 = $30
KEYCODE_E =     $45
KEYCODE_J =     $4a
KEYCODE_L =     $4c
POINTS_POWER_PELLET = $50           ;50 in BCD
KEYCODE_V =     $56
INTERLACE_BIT = $80
JOYBIT_RIGHT =  $80
KEYCODE_F1 =    $85

counter0 =      $00                 ;maybe a timer for sound effects?
counter1 =      $01
CHARCODE_MILKJUG = $16
BONUS_SPOTHI =  $1e
HUD_BONUS_SPOTHI = $1f
HUD_GHOST_SPOTHI = $1f
bonus_timerlo = $3f
bonus_timerhi = $40
TIME    =       $a2                 ;counts time by 1/60s
BONUS_SPOTLO =  $a4
NDX     =       $c6                 ;Number of Characters in Keyboard Buffer queue
HUD_BONUS_SPOTLO = $e7
HUD_GHOST_SPOTLO = $f1
SCREENPTR2LO =  $f7                 ;2nd pointer into screen memory used when copying and comparing between 2 screen locations
SCREENPTR2HI =  $f8
SCREENPTRLO =   $f9                 ;pointer into screen memory
SCREENPTRHI =   $fa
UNKNOWNPTRLO =  $fb
UNKNOWNPTRHI =  $fc
KEYD    =       $0277               ;Keyboard Buffer Queue (FIFO)
CINV    =       $0314               ;Vector: Hardware IRQ Interrupt ($ea31)
lives   =       $1b88
SCORE_ADD =     $1b89               ;value to be added when updating the score
SCORE_ADD_DIGITS23 = $1b8b
SCORE_ADD_DIGITS01 = $1b8c
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
        sec                         ;set flag to wait for input before starting
        php
setup_game
        jsr     jmp_setup_screen
        jsr     L148E
        plp                         ;read flag, if clear, skip waiting for input, if set, wait
        bcc     _skip_wait
        jsr     wait_for_start      ;wait for F1 or fire to start game
_skip_wait
        jsr     L14A6
        lda     #$56
        ldy     #$13
        sta     CINV                ;set irq handler to irq_handler
        sty     CINV+1
_loop
        sei
        bit     ghost_touch_flag    ;check if player-ghost collision happened
        bpl     _no_death           ;branch if player didnt die
        jsr     jmp_snd_reset
        jsr     animate_death
        jsr     jmp_reset_positions
        dec     lives
        bmi     new_game
        jsr     L14A3
        jsr     L14A6
        lda     #$00
        sta     ghost_touch_flag    ;clear flag
_no_death
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
        clc                         ;clear flag and push to stack
        php                         ;this will skip the wait_for_start call in main
        jmp     setup_game

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

update_player
        lda     PLAYER_POSLO
        sta     SCREENPTRLO
        pha
        lda     PLAYER_POSHI
        sta     SCREENPTRHI
        pha
        ldy     input_direction
        jsr     handle_input
        cmp     #CHARCODE_SMALL_PELLET
        bcs     _non_wall_tile
        pla
        sta     SCREENPTRHI
        pla
        sta     SCREENPTRLO
        pha
        lda     SCREENPTRHI
        pha
        ldy     player_direction
        jsr     handle_input
        cmp     #CHARCODE_SMALL_PELLET
        bcs     _non_wall_tile
        pla                         ;it was a wall so just pop stuff from stack and do nothing
        pla
        rts

_non_wall_tile
        beq     _eat_small_pellet
        cmp     #CHARCODE_POWER_PELLET
        beq     _eat_power_pellet
        cmp     #CHARCODE_TREE-2
        bcs     _non_ghost
        jmp     _hit_ghost

_non_ghost
        cmp     #CHARCODE_MUSICNOTE+1
        bcc     _eat_bonus          ;branch if charcode is >= snak down and <= musicnote, it will never equal snak down or snak closed though because only 1 snakman
_draw_new_player_pos
        lda     PLAYER_SPRITE_ARR,y
        sty     player_direction
        ldx     #COLOR_YELLOW
        sec                         ;access_char(mode=write)
        jsr     jmp_access_char
        lda     SCREENPTRLO
        sta     PLAYER_POSLO
        lda     SCREENPTRHI
        sta     PLAYER_POSHI
        pla
        sta     SCREENPTRHI
        pla
        sta     SCREENPTRLO
        lda     #CHARCODE_EMPTY
        ldx     #COLOR_BLACK
        sec                         ;access_char(mode=write)
        jmp     jmp_access_char

_eat_small_pellet
        lda     #POINTS_SMALL_PELLET
        ldx     #$00
        jsr     _update_score
        lda     #$ff
        sta     L1BBF
        lda     #$06
        sta     counter1
        dec     L1BBA
        jmp     _draw_new_player_pos

_eat_power_pellet
        lda     #POINTS_POWER_PELLET
        ldx     #$00
        jsr     _update_score
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
        jmp     _draw_new_player_pos

_eat_bonus
        sec
        sbc     #$12                ;convert character code to index into points array
        tax
        lda     BONUS_POINTS_ARR2,x
        tax
        lda     #$00
        jsr     _update_score
        tya
        pha
        lda     SCREENPTRLO
        pha
        lda     SCREENPTRHI
        pha
        lda     #HUD_BONUS_SPOTLO
        ldy     #HUD_BONUS_SPOTHI
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        ldy     #$05
_loop
        lda     #CHARCODE_EMPTY
        ldx     #COLOR_BLACK
        sec                         ;access_char_with_offset(mode=write)
        jsr     jmp_access_char_with_offset
        dey
        bpl     _loop
        pla
        sta     SCREENPTRHI
        pla
        sta     SCREENPTRLO
        pla
        tay
        jmp     _draw_new_player_pos

_hit_ghost
        bit     L1BBE
        bpl     _hit_ghost_unpowered
        lda     #$ff
        sta     L1BC1
        inc     ghost_eat_streak
        ldx     ghost_eat_streak
        dex
        lda     GHOST_POINTS_ARR2,x
        tax                         ;load points for just eaten ghost into X
        lda     #$00
        jsr     _update_score
        jmp     _draw_new_player_pos

_hit_ghost_unpowered
        lda     #$ff
        sta     ghost_touch_flag    ;set a flag to indicate its time to lose a life i guess? return without updating player pos
        pla
        pla
        rts

_update_score
        sta     SCORE_ADD_DIGITS01  ;store A and X args for later use
        stx     SCORE_ADD_DIGITS23  ;A is right 2 digits, X is left 2 digits
        tya                         ;save Y and screenptr
        pha
        lda     SCREENPTRLO
        pha
        lda     SCREENPTRHI
        pha
        jsr     L148E
        lda     #$00                ;clear score increment
        ldy     #$03
_loop1
        sta     SCORE_ADD,y
        dey
        bpl     _loop1
        pla
        sta     SCREENPTRHI         ;restore screenptr and Y
        pla
        sta     SCREENPTRLO
        pla
        tay
        rts

BONUS_POINTS_ARR2
        .byte   $20                 ;tree points, 2000 | seems like slightly different duplicate of BONUS_POINTS_ARR
        .byte   $05                 ;flag points, 500
        .byte   $20                 ;cherry points, 2000
        .byte   $10                 ;star points, 1000
        .byte   $02                 ;milk jug points, 200
        .byte   $01                 ;music note points, 100
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
        .logical $120b
PLAYER_SPRITE_ARR
        .byte   CHARCODE_SNAK_RIGHT
        .byte   CHARCODE_SNAK_UP
        .byte   CHARCODE_SNAK_DOWN
        .byte   CHARCODE_SNAK_LEFT
        .here

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
        clc                         ;access_char(mode=read)
        jsr     jmp_access_char
        tax                         ;temporarily transfer accumulator to X so that stack operations can be done
        pla                         ;pop direction from stack and move it to Y
        tay
        txa                         ;transfer tile at new location to A
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
        clc                         ;picking random amount to add to 1bb4 and use as offset into prng tablet
        adc     L1BB4
        sta     $8f
        dec     $8f
_L1279
        inc     $8f
        ldy     $8f
        lda     PRNG_TABLE,y
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
        clc                         ;access_char(mode=read)
        jsr     jmp_access_char
        cmp     #$1a
        bcs     _L12E5
        cmp     #$00
        bne     _L12C4
        ldy     L1BB4
        beq     _L12E5
_L12C4
        cmp     #CHARCODE_SMALL_PELLET
        bcc     _L1279
        cmp     #CHARCODE_SNAK_RIGHT
        beq     _L12DE
        bcc     _L12E5
        cmp     #CHARCODE_SNAK_DOWN
        beq     _L12DE
        bcc     _L1279
        cmp     #CHARCODE_SNAK_CLOSED
        beq     _L12DE
        cmp     #CHARCODE_SNAK_LEFT
        beq     _L12DE
        bcc     _L12E5
_L12DE
        lda     #$ff
        sta     ghost_touch_flag    ;set a flag to indicate its time to lose a life
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
        sec                         ;access_char(mode=read)
        jsr     jmp_access_char
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
        sec                         ;access_char(mode=write)
        jsr     jmp_access_char
_move_blocked
        ldy     #$06
_L1321
        lda     ($8d),y
        sta     ($8b),y
        dey
        bpl     _L1321
_L1328
        rts

        .logical $1329
PRNG_TABLE
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
        .here
        .logical $1351
SCREEN_STRIDES2
        .byte   1                   ;right
        .byte   $81                 ;left, -1 with sign-magnitude
        .byte   22
        .byte   $96                 ;-22 with sign-magnitude
        .byte   $00                 ;0 for not moving?
        .here

irq_handler
        inc     bonus_timerlo
        bne     _L135C
        inc     bonus_timerhi
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
        bpl     _no_death
        lda     #$0c
        sta     L1BAD
        jsr     move_ghosts
        bit     ghost_touch_flag    ;check if ghost touched player
        bpl     _no_death
        bit     L1BBE
        bpl     _L13E5
        lda     #$00                ;clear collision flag
        sta     ghost_touch_flag
_no_death
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
        jsr     update_player
_L13E5
        jsr     L191C
        lda     bonus_timerhi
        cmp     #$05
        bcc     _space_occupied
        lda     #$00
        sta     bonus_timerlo       ;reset timer for bonus item
        sta     bonus_timerhi
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
        jmp     jmp_update_time

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
        sec                         ;access_char(mode=write)
        jmp     jmp_access_char

L144B
        lda     #$f1
        ldy     #$1f
        sta     SCREENPTRLO
        sty     SCREENPTRHI
_L1453
        ldx     #COLOR_BLACK
        lda     #CHARCODE_EMPTY
        sec                         ;access_char_with_offset(mode=write)
        jsr     jmp_access_char_with_offset
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
        sec                         ;access_char(mode=write)
        jsr     jmp_access_char
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

jmp_access_char
        jmp     access_char

jmp_access_char_with_offset
        jmp     access_char_with_offset

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

jmp_reset_positions
        jmp     reset_positions

        jmp     draw_yellow_char2

access_char
        ldy     #$00
access_char_with_offset
        bcs     _write_mode
        lda     SCREENPTRHI
        pha
        adc     #$78
        sta     SCREENPTRHI
        lda     (SCREENPTRLO),y
        tax
        pla
        sta     SCREENPTRHI
        lda     (SCREENPTRLO),y     ;return character
        clc
        rts

_write_mode
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
        sta     SCREENPTRHI         ;write new character
        sec
        pla
        rts

L14D8
        sei                         ;disable interrupts
        sed                         ;enable decimal mode
        ldy     #$03
        clc
_loop1
        lda     SCORE_ADD,y
        adc     init_vram,y
        sta     init_vram,y
        dey
        bpl     _loop1
        cld
        lda     #$0b
        sta     SCREENPTRLO
        lda     #$1e                ;1e0b is a character right of HIGH SCORE
        sta     SCREENPTRHI
        lda     #$80
        sta     UNKNOWNPTRLO
        lda     #$1b
        sta     UNKNOWNPTRHI
        jsr     _L150D
        lda     #$21
        sta     SCREENPTRLO
        lda     #$1e                ;1e21 is a character right of SCORE
        sta     SCREENPTRHI
        lda     #$84
        sta     UNKNOWNPTRLO
        lda     #$1b
        sta     UNKNOWNPTRHI
_L150D
        lda     #$00
        sta     $fd
        sta     $fe
_loop2
        ldy     $fe
        cpy     #$04
        beq     _return
        lda     (UNKNOWNPTRLO),y
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
        bne     _loop2
_return
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
        sta     UNKNOWNPTRLO
        lda     #$1b
        sta     UNKNOWNPTRHI
        lda     #$25
        sta     $fd
        lda     #$1b
        sta     $fe
_L155B
        lda     ($fd),y
        sta     (UNKNOWNPTRLO),y
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
        lda     PLAYER_POSLO
        ldy     PLAYER_POSHI
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        clc                         ;access_char(mode=read)
        jsr     jmp_access_char
        cmp     #CHARCODE_SNAK_CLOSED
        bne     _closed
        lda     player_direction
        beq     _right
        cmp     #$01
        beq     _up
        cmp     #$02
        beq     _down
        lda     #CHARCODE_SNAK_LEFT
        .byte   $2c
_closed
        lda     #CHARCODE_SNAK_CLOSED
        .byte   $2c
_right
        lda     #CHARCODE_SNAK_RIGHT
        .byte   $2c
_up
        lda     #CHARCODE_SNAK_UP
        .byte   $2c
_down
        lda     #CHARCODE_SNAK_DOWN
draw_yellow_char2
        ldx     #COLOR_YELLOW
L15D1
        sec                         ;access_char(mode=write)
        jmp     jmp_access_char

L15D5
        lda     PLAYER_POSLO
        ldy     PLAYER_POSHI
L15DB
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        lda     #$b4
        ldy     #$16
        sta     CINV                ;set irq handler to jmp_update_time
        sty     CINV+1
        lda     #$00
        sta     TIME
        lda     #$1a
        jsr     draw_yellow_char2
        cli
_L15F3
        lda     TIME
        cmp     #$05
        bcc     _L15F3
        lda     #$1b
        jsr     draw_yellow_char2
_L15FE
        lda     TIME
        cmp     #$09
        bcc     _L15FE
        lda     #$1c
        jsr     draw_yellow_char2
_L1609
        lda     TIME
        cmp     #$0d
        bcc     _L1609
        lda     #$20
        ldx     #$00
        jsr     L15D1
        sei
        lda     #$56                ;set irq handler to irq_handler
        sta     CINV
        lda     #$13
        sta     CINV+1
        rts

L1622
        clc
        lda     #$d8
        adc     lives
        ldy     #$1e
        jsr     L15DB
L162D
        lda     #$c2
        ldy     #$1f
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        sta     PLAYER_POSLO
        sty     PLAYER_POSHI
        lda     #$01
        sta     player_direction
        sta     input_direction     ;start game facing up
        lda     #$10
        bne     draw_yellow_char2

reset_positions
        lda     #$03                ;not 100% sure that's all this does
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
        .byte   $fb                 ;might be ghost starting positions?
        .byte   $fc
        .byte   $fd
        .byte   $fe

jmp_update_time
        jmp     update_time

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

jmp_load_charset
        jmp     load_charset

jmp_setup_screen
        jmp     setup_screen

L16CF
        jsr     L1497
        jsr     jmp_setup_screen
        lda     #$d7
        sta     SCREENPTRLO
        lda     #$1e                ;looks to be the screen address of one character left of the lives counter area
        sta     SCREENPTRHI
        ldy     lives
        lda     #CHARCODE_EMPTY
        ldx     #COLOR_BLACK
_next_cell
        iny
        cpy     #MAX_LIVES+1        ;have we reached the final counter cell
        beq     _return
        sec                         ;access_char_with_offset(mode=write)
        jsr     jmp_access_char_with_offset ;clear each cell that is over the current number of lives
        bcs     _next_cell
_return
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
        jsr     draw_char2
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
        cmp     PLAYER_POSLO
        bne     _L179E
        cpy     PLAYER_POSHI
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
        clc                         ;access_char(mode=read)
        jsr     jmp_access_char
        eor     #$01
        tay
        pla
        tax
        tya
draw_char2
        sec                         ;access_char(mode=write)
        jmp     jmp_access_char

update_time
        jsr     udtim               ;see https://www.mdawson.net/vic20chrome/vic20/docs/kernel_disassembly.txt#:~:text=%3B%20IRQ%20handler
        jmp     $eb15               ;undocumented kernal routine, clear timer interrupt flag and pop Y,X,A from stack (in that order)

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
        jsr     draw_char2
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
        jsr     draw_char2
        inc     SCREENPTRLO
        lda     #CHARCODE_NUM0      ;draw 2 trailing 0s
        jsr     jmp_access_char     ;access_char(mode=???)
        inc     SCREENPTRLO
        jmp     jmp_access_char     ;access_char(mode=???)

snd_reset
        lda     #$00                ;sets all oscillator freqs to 0 and volume to 0
        ldy     #$04
_loop
        sta     OSC1_FREQ,y
        dey
        bpl     _loop
        rts

load_charset
        clc
        lda     #$9f                ;TODO: give screenptr and screenptr2 local names that fit better when moving to manual editing
        adc     #$57
        sta     SCREENPTRLO
        lda     #$1b
        adc     #$01                ;really weird way of setting screenptr to 0x1cf6
        sta     SCREENPTRHI         ;thats the address of the last byte of the new characters
        lda     #$57
        sta     SCREENPTR2LO
        lda     #$1d                ;set screenptr2 to 0x1d57
        sta     SCREENPTR2HI        ;thats the new end of the characters
        ldy     #$00
_loop
        lda     (SCREENPTRLO),y
        sta     (SCREENPTR2LO),y    ;copy byte to new location
        lda     SCREENPTRLO
        bne     _no_carry_src       ;don't increment high byte of source pointer if no carry
        dec     SCREENPTRHI
_no_carry_src
        dec     SCREENPTRLO
        lda     SCREENPTR2LO
        bne     _no_carry_dest      ;don't increment high byte of dest pointer if no carry
        dec     SCREENPTR2HI
_no_carry_dest
        dec     SCREENPTR2LO
        lda     SCREENPTR2HI
        cmp     #$1b                ;while ((screenptr2 & 0xff00) != 0x1b)
        bne     _loop               ;i.e. last byte gets copied to 0x1c00 (start of characterset ram)
        lda     #$00
        ldy     #$1d
        sta     SCREENPTR2LO
        sta     SCREENPTRLO
        sty     SCREENPTR2HI        ;set screenptr2 to 0x1d00
        lda     #$81
        sta     SCREENPTRHI         ;and screenptr to 0x8100
        ldy     #$ff
_loop2
        lda     (SCREENPTRLO),y     ;copy range 0x81ff-0x8158 to 0x1dff-0x1d58
        sta     (SCREENPTR2LO),y
        dey
        cpy     #$57
        bne     _loop2
        rts

setup_screen
        lda     #$b4                ;set irq handler to jmp_update_time
        ldy     #$16
        sta     CINV
        sty     CINV+1
        lda     #$08
        sta     $900f               ;set screen and border color: background: 1000 inverted: 0 border: 000
        ldy     #$00
_loop
        lda     SCORE_HEADER_ARR,y
        cmp     #$00
        beq     _break
        jsr     ichrout
        iny
        bne     _loop
_break
        sei
        lda     #$44                ;$1a45 is the location of the maze layout
        ldy     #$1a                ;not in screenmem, maybe screenptr2 isnt actually pointing to screen mem
        sta     SCREENPTR2LO
        sty     SCREENPTR2HI
        lda     #$2b                ;maze in screen mem starts at $1e2c
        ldy     #$1e                ;both of these pointers get incremented once before doing anything with them
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        ldx     #$00
        txa
        pha
        ldy     #$00
_loop_tiledraw
        inc     SCREENPTR2LO
        bne     _no_carry
        inc     SCREENPTR2HI
_no_carry
        lda     (SCREENPTR2LO),y    ;load byte of 2 packed characters from maze layout
        pha                         ;save loop counter
        lsr     a
        lsr     a
        lsr     a
        lsr     a                   ;extract upper nibble, left tile
        jsr     draw_next_tile
        pla
        and     #$0f                ;extract lower nibble, right tile
        jsr     draw_next_tile
        pla                         ;load loop counter
        tax
        inx
        txa
        pha
        cpx     #220                ;check if 220 tiles have been drawn
        bne     _loop_tiledraw
        pla
        lda     #$1e                ;screen address of leftmost cell of ghost home
        sta     SCREENPTRHI
        lda     #$fb
        sta     SCREENPTRLO
        ldy     #$03
_loop1
        ldx     GHOST_COLORS_ARR,y
        lda     #CHARCODE_GHOST1
        sec                         ;access_char_with_offset(mode=write)
        jsr     jmp_access_char_with_offset
        dey
        bpl     _loop1
        lda     #$56                ;set irq handler to irq_handler
        ldy     #$13
        sta     CINV
        sty     CINV+1
        rts

draw_next_tile
        inc     SCREENPTRLO
        bne     _no_carry
        inc     SCREENPTRHI
_no_carry
        cmp     #CHARCODE_SMALL_PELLET
        bcc     _blue
        beq     _green
        cmp     #CHARCODE_POWER_PELLET
        beq     _red
        ldx     #COLOR_YELLOW
        .byte   $2c
_blue
        ldx     #COLOR_BLUE
        .byte   $2c
_red
        ldx     #COLOR_RED
        .byte   $2c
_green
        ldx     #COLOR_GREEN
        jmp     draw_char2

        .logical $18ff
SCORE_HEADER_ARR
        .byte   $93                 ;clear screen
        .byte   $9e                 ;set color to yellow
        .byte   $28                 ;H
        .byte   $29                 ;I
        .byte   $2a                 ;G
        .byte   $28                 ;H
        .byte   $20
        .byte   $23                 ;S
        .byte   $24                 ;C
        .byte   $25                 ;O
        .byte   $26                 ;R
        .byte   $27                 ;E
        .byte   $20
        .byte   $0d                 ;return
        .byte   $9e
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $20
        .byte   $23                 ;S
        .byte   $24                 ;C
        .byte   $25                 ;O
        .byte   $26                 ;R
        .byte   $27                 ;E
        .byte   $20
        .byte   $0d                 ;return
        .byte   $13                 ;home
        .byte   $00
        .here

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
        lda     counter1            ;if *0x01 != 0, play the pellet sound alongside normal sound
        beq     _no_pellet_sound
        tay
        dec     counter1            ;clear pellet eat flag
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

animate_death
        jsr     L16C0
        jsr     reset_time_irq
        jsr     jmp_snd_reset
        lda     #205
        sta     OSC3_FREQ
        lda     #MAX_VOL
        sta     VOLUME
        cli                         ;enable interrupts
_wait
        lda     TIME
        cmp     #3
        bne     _wait               ;wait until time == 3
        lda     #$00
        sta     TIME                ;reset time to 0
        dec     OSC3_FREQ           ;i think this might be the falling tone that plays when dying?
        lda     OSC3_FREQ
        cmp     #165                ;lower OSC3_FREQ from 205 to 165, waiting a short time at each step
        bne     _wait
        sei                         ;disable interrupts
        jsr     jmp_snd_reset
        lda     #MAX_VOL
        sta     VOLUME
        lda     #128
        sta     NOISE_FREQ
        sta     OSC1_FREQ
        lda     #$00
        sta     TIME                ;reset time
        lda     PLAYER_POSLO
        ldy     PLAYER_POSHI
        sta     SCREENPTRLO
        sty     SCREENPTRHI
        lda     #CHARCODE_SNAK_DEATH1
        jsr     draw_yellow_char
        cli
_wait_death1
        lda     TIME
        cmp     #4
        bcc     _wait_death1
        lda     #CHARCODE_SNAK_DEATH2
        jsr     draw_yellow_char
        dec     VOLUME
_wait_death2
        lda     TIME
        cmp     #9
        bcc     _wait_death2
        lda     #CHARCODE_SNAK_DEATH3
        jsr     draw_yellow_char
        dec     VOLUME
wait_death3
        lda     TIME
        cmp     #14
        bcc     wait_death3
        lda     #CHARCODE_EMPTY
        ldx     #COLOR_BLACK
        jsr     draw_char
_L1A0F
        dec     VOLUME
        beq     _L1A20
        lda     #$00
        sta     TIME
_L1A18
        lda     TIME
        cmp     #$05
        bcs     _L1A0F
        bcc     _L1A18

_L1A20
        jsr     jmp_snd_reset
        sei
        lda     #$13                ;set irq handler to irq_handler
        sta     CINV+1
        lda     #$56
        sta     CINV
        rts

reset_time_irq
        sei
        lda     #$b4                ;set irq handler to jmp_update_time and reset TIME
        ldy     #$16
        sta     CINV
        sty     CINV+1
        lda     #$00
        sta     TIME
        rts

draw_yellow_char
        ldx     #COLOR_YELLOW
draw_char
        sec                         ;access_char(mode=write)
        jmp     jmp_access_char

        .logical $1a45
MAZE_LAYOUT
        .byte   $31,$11,$11,$11,$11,$11,$11,$11,$11,$11,$14 ;maze layout, 2 characters per byte, each line here is a row
        .byte   $2b,$bb,$cb,$bb,$bb,$bb,$bb,$bb,$bc,$bb,$b2
        .byte   $2b,$11,$11,$11,$b1,$77,$1b,$11,$11,$11,$b2
        .byte   $2b,$bb,$bb,$bb,$bb,$22,$bb,$bb,$bb,$bb,$b2
        .byte   $2b,$11,$1b,$2b,$2b,$65,$b2,$b2,$b1,$11,$b2
        .byte   $2b,$bb,$bb,$2b,$2b,$bb,$b2,$b2,$bb,$bb,$b2
        .byte   $2b,$11,$1b,$2b,$61,$11,$15,$b2,$b3,$11,$19
        .byte   $2b,$bb,$bb,$2b,$bb,$bb,$bb,$b2,$b2,$dd,$d2
        .byte   $a1,$11,$4b,$2b,$31,$11,$14,$b2,$b6,$11,$15
        .byte   $61,$11,$5b,$2b,$2e,$ee,$e0,$bb,$bb,$bb,$bb
        .byte   $bb,$bb,$bb,$bb,$61,$11,$15,$b2,$b3,$11,$14
        .byte   $31,$11,$4b,$2b,$bb,$bb,$bb,$b2,$b6,$11,$19
        .byte   $a1,$11,$5b,$2b,$2b,$34,$b2,$b2,$bb,$bb,$b2
        .byte   $2b,$bb,$bb,$2b,$2b,$22,$b2,$b2,$b1,$11,$b2
        .byte   $2b,$2b,$2b,$2b,$2b,$22,$b2,$b2,$bb,$bb,$b2
        .byte   $2b,$2b,$2b,$2b,$2b,$22,$b2,$b2,$b1,$11,$b2
        .byte   $2b,$2b,$2b,$2b,$2b,$22,$b2,$b2,$bb,$bb,$b2
        .byte   $2b,$2b,$2b,$2b,$2b,$65,$b2,$b2,$b1,$11,$b2
        .byte   $2b,$bb,$cb,$bb,$bb,$bb,$bb,$bb,$bc,$bb,$b2
        .byte   $61,$11,$11,$11,$11,$11,$11,$11,$11,$11,$15
        .here
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
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $01
        .byte   $00
        .byte   $c4
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00
        .byte   $00

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
        jmp     jmp_load_charset

init_vram
        ldx     #$07                ;i think this is actually something about drawing the score
loop1
        cmp     L1B97,x
        beq     inc_counter0
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
PLAYER_POSLO
        .byte   %11111111
PLAYER_POSHI
        .byte   %11111111
player_direction
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
ghost_touch_flag
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
