MIDI_CONTROL_PORT equ 0331h
MIDI_DATA_PORT equ 0330h
MIDI_UART_MODE equ 3Fh ; UART lets us use the soundblaster midi commands the DosBox can send to the Host PC.
NOTE_ON equ 099h ; first nibble is the midi Note ON ; second nibble is the midi Channel

;MIDI_PIANO_INSTRUMENT 93h

; Clock es reference 
Clock equ es:6Ch

proc SetupMidi
	push ax

	mov dx, MIDI_CONTROL_PORT;  MIDI_CONTROL_PORT
	mov al, MIDI_UART_MODE;     play notes as soon as they are received (UART MODE)
	out dx, al

	pop ax
	ret
endp SetupMidi

proc PlayNote
	push bp
	mov bp, sp 
	
	push ax
	push dx
	; Note On Send To Data port
	mov dx, MIDI_DATA_PORT
	mov al, NOTE_ON; 
	out dx, al
	
	mov ax, [bp + 4]
    out dx, al;     
	
    mov al, 7Fh;            note Velocity.
    out dx, al
	
	pop dx
	pop ax
	
	pop bp
; this will remove 2 bytes out of the stack after the ip will pop 
; because we return to where the call was in order to clean the stack.
    ret 2 
endp PlayNote

; clock
proc WaitClock
	push ax
	push cx
	;mov cx, 45 ; 45x0.055sec = ~2.5 [sec]
	mov cl, 1
	
	mov ax, 40h
	mov es, ax
; מעביר את הערך בכתובת
	mov ax, [Clock]
FirstTick:
; בודק אם הערך השתנה
	cmp ax, [Clock]

	je FirstTick
DelayLoop:
	mov ax, [Clock]
Tick:
	cmp ax, [Clock]
	je Tick
	loop DelayLoop
	
	pop cx
	pop ax
	
	ret
endp WaitClock

proc Init
	push ax
	push bx
	push cx
	push si
	
	mov si, 0
	mov cx, 4
InitLoop:
	mov bx, offset Tracks
	mov ax, 0
	mov [bx + si], ax
	
	add si, 2
	loop InitLoop
	
	pop si
	pop cx
	pop bx
	pop ax
	
	; lower layer, upper layer
	call InitScrn
	ret
endp Init
;--------------------------------------------------------------------------
; clears keyboard buffer
;--------------------------------------------------------------------------
proc ClearKeyBoardBuffer
	push ax
	push es
	
	mov	ax, 0
	mov	es, ax
	mov	[word ptr es:041ah], 041Eh
	mov	[word ptr es:041ch], 041Eh	; Clears keyboard buffer
	
	pop	es
	pop	ax
	
	ret
endp ClearKeyBoardBuffer	