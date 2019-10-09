; -----
; Amir kedem
; 4.7.2018
; 
; Drum Machine
;
; Keyboard Inputs:
; arrows, space, enter, backspace, ( - / + ) / ( - / = ).
; -----

IDEAL
MODEL small
STACK 100h
DATASEG

; picture file handling
;-------------
filename 	db 'ui.bmp',0
filehandle 	dw ?
Header 		db 54 dup (0)
Palette 	db 256*4 dup (0)
ScrLine 	db 320 dup (0)
ErrorMsg 	db 'Error', 13, 10,'$'
;-------------

; pixels & drawing handling
;-------------
x dw ?
y dw ?
rectWidth dw ?
rectHeight dw ?
spacingX dw ? 
spacingY dw ? 
color dw ?

spacingSpd dw 4
;-------------
; A Boolean for pause or play.
isPlaying db 0

speed db 3
clockConuter db 0

; kick  equ 36 
; snare equ 38 
; clap  equ 39
; hihat equ 42
Sounds dw 36, 38, 39, 42
; the direction in which we read these numbers 
; depends on the rol action that we do on dx 
Tracks dw 4 dup(0)

; high order stands for rows 
; low order stands for columns 
; 0 means 0 column , 0 rows => the first bit in the tracks 
currIndex dw 0 
histIndex dw 0 ; history - The last bit that we hovered on. 

pointer dw 0

CODESEG

; colors 
silver     equ 1d ; The Theme of the drum machine

on         equ 2d  ; upper layer on
off        equ 3d  ; upper layer off
curr       equ 4d  ; lower layer while cursored
normal     equ 5d  ; lower layer while not cursored

red        equ 249d ; stop / not playing
green      equ 250d ; play / playing

background equ 255d

; Includes all the Procs.
include ‏‏"midi.asm"
include ‏‏"draw.asm"
include "picture.asm"
; The beginning
Start:
	mov ax, @data
	mov ds, ax
	
;Graphic mode
	mov ax, 13h       ; mode 13h = 320x200 pixels, 256 colors.
	int 10h
               
	call RenderPic    ; Process BMP file
	call SetupMidi    ; Setup the UART Mode
	; lower layer, upper layer
	call InitScrn
; -----
; End Of SetUp
; sets up the bit mask that filters the tracks and checks the bits.
	mov dx, 1b 
; PlayLoop
PlayLoop:	
; ----- 
;key check start
	push ax
	push dx 
; gets input from keyboard and puts it in al.
; int 21/ ah 06h doesn't clear the keyboard buffer.
	mov ah, 06h
	mov dl, 255
    int 21h
; if esc key then exit.
	cmp al, 27d 
	jne Try_Up1 
	jmp cs:Exit 
; The Arrows Check
; -----



; -----
Try_Up1:
	cmp al, 72d ; Up Arrow
	jne Try_Down1
; updates history
	; minus the direction that we came from.
	mov dx, [currIndex]
	mov [histIndex], dx
; updates current
	mov dx, [currIndex]
	cmp dh, 0
	jne Try_Up2
	mov dh, 3
	mov [currIndex], dx
	
	call clnHistBit
	call drawCurrBit
	jmp OutKey
Try_Up2:
	dec dh
	mov [currIndex], dx
	
	call ClnHistBit
	call DrawCurrBit
	jmp OutKey
; -----
Try_Down1:
	cmp al, 80d ; Down Arrow
	jne Try_Right1
; updates history
	mov dx, [currIndex]
	mov [histIndex], dx
; updates current	
	mov dx, [currIndex]
	cmp dh, 3
	jne Try_Down2
	mov dh, 0
	mov [currIndex], dx
	call clnHistBit
	call drawCurrBit
	jmp OutKey
Try_Down2:
	inc dh
	mov [currIndex], dx
	call ClnHistBit
	call DrawCurrBit
	jmp OutKey
; -----
Try_Right1:
	cmp al, 77d ; Right Arrow
	jne Try_Left1
; updates history
	mov dx, [currIndex]
	mov [histIndex], dx
; updates current	
	mov dx, [currIndex]
	cmp dl, 0fh
	jne Try_Right2
	mov dl, 0
	mov [currIndex], dx
	
	call ClnHistBit
	call DrawCurrBit
	jmp OutKey
Try_Right2:
	inc dl
	mov [currIndex], dx
	
	call ClnHistBit
	call DrawCurrBit
	jmp OutKey
; -----
Try_Left1:
	cmp al, 75d ; Left Arrow
	jne Try_Enter
; updates history
	mov dx, [currIndex]
	mov [histIndex], dx
; updates current
	mov dx, [currIndex]
	cmp dl, 0
	jne Try_Left2
	mov dl, 0fh 
	mov [currIndex], dx
	
	call ClnHistBit
	call DrawCurrBit
	jmp OutKey
Try_Left2:
	dec dl
	mov [currIndex], dx
	
	call ClnHistBit 
	call DrawCurrBit
	jmp OutKey
; -----



; -----
; The Function Check
; press Enter To Play and Pause.
Try_Enter: 
	cmp al, 13d
	jne Try_Minus
	xor [isPlaying], 1 
	call PlayingBtn
	mov [clockConuter], 0
	jmp Outkey
Try_Minus:  
	cmp al, '-' ; the dash key or minus 
	jne Try_Plus
	cmp [speed], 10
	je OutKey
	inc [speed]	 ; inc speed so the music will go slower
	call DrawSpd
	mov [clockConuter], 0
	jmp OutKey
Try_Plus: 
	cmp al, '=' ; the equal key or plus
	jne Try_Space
	cmp [speed], 1
	je OutKey
	dec [speed]  ; dec speed so the music will go faster
	call DrawSpd
	mov [clockConuter], 0
	jmp OutKey
Try_Space:
	cmp al, 32d
	jne Try_BackSpace
	call MarkBit
	jmp Outkey
Try_BackSpace:
	cmp al, 8d ; the equal key or plus
	jne OutKey ; or the next Compression
	call Init
	
OutKey:
; since int 21/ ah 06h doesn't clear the keyboard buffer.
; we clear the buffer directly.
	call ClearKeyBoardBuffer 
	pop dx
	pop ax
; ----- key check over
; -----
; ----- Tracks Check 
	cmp [isPlaying], 1
	je Continue
; resets the start position in which we read over the tracks.
	mov dx, 1 
	mov [pointer], 0
	call DrawPointer
	
	jmp NotPlaying
Continue:
	mov cl, [clockConuter]
	cmp [speed], cl
	jne NotPlaying
	mov [clockConuter], 0
; the loop that goes over the tracks and sounds.
	mov si, 0
	mov cx, 4
TrackLoop:
	mov bx, offset Tracks
	mov ax, [bx + si]
	and ax, dx
; if the bit that we are asking is off so jmp
; else play a sound
	jz NextTrack
	mov bx, offset Sounds
	mov ax, [bx + si]
; play note expects for a parameter.
	push ax
	call PlayNote 
NextTrack:	
	add si, 2
	loop TrackLoop
; shift left the bit mask.
	rol dx, 1
; if the pointer gets to 0fh that means it has reached
; the end so we have to set it back to zero
	cmp [pointer], 0fh
	jbe Pointer1
	mov [pointer], 0
Pointer1:
	call DrawPointer
	inc [pointer]
	
NotPlaying:
	inc [clockConuter]
	call WaitClock
	jmp PlayLoop
	
Exit:
; Back to text mode
	mov ah, 0
	mov al, 2
	int 10h
	
	mov ax, 4c00h
	int 21h
	
END start