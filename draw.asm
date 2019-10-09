; All the procs that works with pixels.
proc DrawPix
	push ax
	push bx
	push cx
	push dx
	
	mov bh, 0
	mov cx,[x] 
	mov dx,[y] 
	mov ax,[color] 
	mov ah, 0ch 
	int 10h
	
	pop dx
	pop cx
	pop bx
	pop ax
	
	ret
endp DrawPix

; properties are being delivered throw the memory
proc DrawRect
	push ax
	push cx 
	
	mov cx, [rectHeight]
	add [y], cx
Rect1:
	push cx
	
	mov cx, [rectWidth]
	add [x], cx
	
Rect2:
	dec [x]
	call DrawPix
	
	loop Rect2
	pop cx
	
	dec [y]
	loop Rect1
	
	pop cx
	pop ax
	
	ret
endp DrawRect

proc DrawScrn
	push ax
	push cx
	
	push [y]
	
	mov cx, 4
Scrn1:
	push cx
	push [x]

	mov cx, 16
Scrn2:
	call DrawRect
	
	mov ax, [spacingX]
	add [x], ax
	
	loop Scrn2
	
	pop [x] 
	pop cx
	
	mov ax, [spacingY]
	add [y], ax
	
	loop Scrn1
	pop [y]

	pop cx
	pop ax
	ret
endp DrawScrn

proc InitScrn
	; lower layer
	mov [x], 54
	mov [y], 80
	mov [rectWidth], 10
	mov [rectHeight], 18
	mov [spacingX], 16 
	mov [spacingY], 28 
	mov [color], normal
	call DrawScrn
	
	; upper layer
	mov [x], 55
	mov [y], 82
	mov [rectWidth], 8
	mov [rectHeight], 14
	mov [spacingX], 16 
	mov [spacingY], 28 
	mov [color], off
	call DrawScrn
	; The long vertical rectangle to the right 
	; silver Theme
	mov [color], silver
	
	mov [x], 40
	mov [y], 0
	mov [rectWidth], 6
	mov [rectHeight], 200
	
	call DrawRect
	
	mov [x], 0
	mov [rectWidth], 320
	mov [rectHeight], 6
	
	mov [y], 0   ; from the beginning.
	call DrawRect
	mov [y], 193 ; windowHeight - rectHeight - the first pixel that bugs me.
	call DrawRect
; -----
	mov [x], 50
	mov [y], 80
	mov [rectWidth], 2
	mov [rectHeight], 102 ; spacingY (init) * 3 + rect height (lower layer) = >  28 * 3 + 18
	mov [color], silver
	
	push cx
	mov cx, 4
Setup:
	call DrawRect
	add [x], 64 ; spacingX
	loop Setup
	pop cx

	call DrawCurrBit
	call PlayingBtn
	call DrawSpd
	
	ret
endp InitScrn

proc DrawSpd
; cleans the speed 
	mov [x], 54
	mov [y], 14
	mov [rectHeight], 18 ;  
	mov [rectWidth], 40  ; maxSpeed * width + spacingSpd = 10 * (2 + 2) => 40
	mov [color], background

	call DrawRect
; draws the new speed
	push cx
	push dx
	mov [rectWidth], 2
	mov [color], silver
	xor cx, cx 
	mov cl, 11d ; 10 speed lvls Therefore 11 minus speed so if speed is 10 
	sub cl, [speed]
SpdLoop:
	call DrawRect
	mov dx, [spacingSpd]
	add [x], dx
	
	loop SpdLoop
	
	pop dx
	pop cx
	
	ret
endp DrawSpd

proc PlayingBtn
	mov [x], 8 
	mov [y], 14  ; same height as speed
	mov [rectWidth], 24
	mov [rectHeight], 18
	cmp [isPlaying], 0
	jz RedBtn
GreenBtn:	
	mov [color], green
	call DrawRect
	ret
RedBtn:
	mov [color], red
	call DrawRect
	ret
endp PlayingBtn

proc DrawPointer
; cleans the last pointer
	mov [x], 55	
	mov [y], 186
	mov [rectWidth], 248 ; 16 * (8 + 8) - rectWidth = 256 - 8 = 248
	mov [rectHeight], 4
	mov [color], background
	
	call DrawRect
; draws the new pointer
	push cx
	push dx
	
	mov [x], 55
	mov [y], 186
	mov [rectWidth], 8 
	mov [rectHeight], 4
	mov [spacingX], 16 
	mov [color], silver
	
	mov dx, [spacingX]
	mov cx, [pointer]
PointLoop:
	add [x], dx
	loop PointLoop
	
	call DrawRect
	
	pop dx
	pop cx
	
	ret
endp DrawPointer
; -----
; Tracks



; -----
proc LowerBit ; lower layer
	mov [x], 54
	mov [y], 80
	mov [rectWidth], 10
	mov [rectHeight], 18
	mov [spacingX], 16 
	mov [spacingY], 28 
	
	ret
endp LowerBit

proc UpperBit ; upper layer
	mov [x], 55
	mov [y], 82
	mov [rectWidth], 8
	mov [rectHeight], 14
	mov [spacingX], 16 
	mov [spacingY], 28
	
	ret
endp UpperBit

proc DrawCurrBit  
	; lower layer settings
	call LowerBit 
	
	push [currIndex]
	mov [color], curr ; means that we are currently on the track bit.
	call DrawLayer

	push ax
	push bx
	push cx
	push dx
	push si
	
	mov cx, [currIndex]
	mov cl, ch
	mov ch, 0 
	mov si, cx ; now we have in cx the rows. 
	add si, cx ; because we are using words.
	mov cx, [currIndex] ; now we have in cx the columns.
	mov dx, 1
; we rol 1 cl times  in order to mask the bit of the tracks cl is the curr position.
	rol dx, cl 
	mov bx, offset Tracks
	mov ax, [bx + si]

	and ax, dx
	
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	
	; upper layer settings
	call UpperBit
	jz BitOff1
BitOn1:
; upper layer Color.
	mov [color], on
	push [currIndex]
	call DrawLayer
	
	ret
BitOff1:
; upper layer Color.
	mov [color], off
	push [currIndex]
	call DrawLayer
	
	ret
endp DrawCurrBit  
  
proc ClnHistBit
	; lower layer
	call LowerBit
	
	push [histIndex]
	mov [color], normal ; means that we are currently on the track bit.
	call DrawLayer

	push ax
	push bx
	push cx
	push dx
	push si
	
	mov cx, [histIndex]
	mov cl, ch
	mov ch, 0 
	mov si, cx ; now we have in cx the rows. 
	add si, cx ; because we are using words. 
	mov cx, [histIndex] ; now we have in cx the columns.
	mov dx, 1
; we rol 1 cl times  in order to mask the bit of the tracks cl is the curr position.
	rol dx, cl 
	mov bx, offset Tracks
	mov ax, [bx + si]

	and ax, dx
	
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	
	; upper layer settings
	call UpperBit
	
	jz BitOff2
BitOn2:
; upper layer Color.
	mov [color], on
	push [histIndex]
	call DrawLayer
	
	ret
BitOff2:
; upper layer Color.
	mov [color], off
	push [histIndex]
	call DrawLayer
	
	ret
endp ClnHistBit 

proc DrawLayer
	push bp
	mov bp, sp
	
	push cx
	push dx
		
	mov dx, [spacingX]
	mov cx, [bp + 4]
	mov ch, 0 ; get the Rows
DrawLayer1:
	add [x], dx
	loop DrawLayer1
	
	mov dx, [spacingY]
	mov cx, [bp + 4]
	mov cl, ch
	mov ch, 0 ; get the Columns
DrawLayer2:
	add [y], dx
	loop DrawLayer2
	
	call DrawRect
	
	pop dx
	pop cx
	
	pop bp
	
    ret 2
endp DrawLayer

proc MarkBit
	push ax
	push bx
	push cx
	push dx
	push si
	
	mov cx, [currIndex]
	mov cl, ch
	mov ch, 0
	mov si, cx ; now we have in cx the rows.
	add si, cx ; because we are using words.
	mov cx, [currIndex] ; now we have in cx the columns.
	mov dx, 1
; we rol 1 cl times  in order to mask the bit of the tracks cl is the curr position.
	rol dx, cl
	mov bx, offset Tracks
	mov ax, [bx + si]
	
	xor ax, dx
	
	mov [bx + si], ax
	
	pop si
	pop dx
	pop cx
	pop bx
	pop ax
	
	call DrawCurrBit
	
	ret
endp MarkBit
