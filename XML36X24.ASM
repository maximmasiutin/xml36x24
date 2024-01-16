; VGA X-Mode 360x240(480)x256-Color Library
; Copyright (C) 1995 by FRIENDS Software
; Author: Maxim Masiutin
; To contact the author, mail to 2:469/84@fidonet.org

		.186
		.Model	tPascal

ScrX		equ   360
ScrX1		equ	0
ScrX2		equ   359
ScrY1		equ	0

ScrX4 = ScrX shr 2

		.Data


extrn		SegA000 		: word
extrn		ImageOffset		: word

extrn		CurColor		: byte
extrn		Test8086		: byte
extrn		BackgroundColor 	: byte
extrn		CurX			: word
extrn		CurY			: word

extrn		ScrY2			: word
extrn		ScrY			: word
extrn		PageSize		: word

extrn		LineMode		: byte
extrn		LinePoints		: dword
extrn		LinePointsPos		: word


		.Code

		jumps
		Locals	@@

public		SetVideoMode
public		SetDoubleRetrace,SetSingleRetrace

public		PutBitMap,PutTranspBitMap
public		GetBitMap
public		Line,HorizLine,FullHorLine,GridHorLine,VertLine
public		Clipping
public		PutPixel,PutTPoint, GetPixel
public		Bar,Bar4
public		InternalEllipse
public		ColorPoly
public		Cls,ClearPage,PageCopy,GPCopy
public		SetActivePage,SetVisualPage,SetVisualOffset
public		WaitRetrace,SetAllPalette



ClrQu		macro
		dd	0EB00EBh	     ; PentiumoPhobia
		endm

OPdxax		macro
		adc	dx,0
		shr	dx,1
		rcr	ax,1
		shr	dx,1
		rcr	ax,1
		endm

ModyW		equ	0C0DEh
ModyB		equ	0BAh

cmMovBl 	equ	0B3h
cmMovCl 	equ	0B1h
cmMovAl 	equ	0B0h

CalcScrOfs	macro	IR
		push	dx
		mov	ax,cx
		mov	IR,ScrX
		mul	IR
		add	ax,bx
		OPdxax
		mov	IR,ax
		pop	dx
		endm

CalcMask	macro
		mov	cl,bl
		mov	al,10001b
		and	cl,11b
		rol	al,cl
		mov	byte ptr cs:@@FirstMask,al
		mov	ch,0
		mov	cl,dh
		mov	ah,dl
		mov	bl,al
		mov	dx,3C4h
		mov	al,2
		out	dx,al
		inc	dx
		push	bp
		mov	bp,di
		endm

DrawSprite	proc near
		uses	ds
		; bx=X, cx=Y, dl=h, dh=V, si=ImageOfs, di=ImageSeg

@@cmAddSi	equ	0C683h
@@cmSubSi	equ	0EE83h

		cld
		pushf
		cli
		mov	es,SegA000
		mov	@@hv,dx
		mov	@@SourceSEG,di
		mov	byte ptr cs:@@SkipFAdd,0
		mov	byte ptr cs:@@ColAdd,0
		jmp	@@Strt
@@Invis:	jmp	@@End
@@Strt: 	mov	ax,bx
		add	al,dl
		adc	ah,0
		js	@@Invis
		or	bx,bx
		js	@@LeftRide
		cmp	bx,ScrX
		jnb	@@Invis
		cmp	ax,ScrX
		jb	@@HorNor
		sub	ax,ScrX ; X - Right Ride
		sub	dl,al
		mov	byte ptr cs:@@ColAdd,al
		mov	byte ptr cs:@@SkipFAdd,al
		jmp	@@CalcVert
@@LeftRide:	sub	dl,al
		mov	byte ptr cs:@@ColAdd,dl
		mov	dl,al
		xor	bx,bx
@@HorNor:
@@CalcVert:	cmp	dl,0
		jz	@@Invis
		mov	ax,cx
		add	al,dh
		adc	ah,0
		js	@@Invis
		or	cx,cx
		js	@@UpRide
		cmp	cx,ScrY
		jnb	@@Invis
		cmp	ax,ScrY
		jb	@@VertNor
		sub	ax,ScrY
		sub	dh,al
		mov	cx,ScrY
		sub	cl,dh
		sbb	ch,0
		jmp	@@DrawIt
@@UpRide:	mov	dh,al
		push	@@hv
		sub	byte ptr @@hv[0],al
		mov	al,byte ptr @@hv[1]
		mul	byte ptr @@hv[0]
		pop	@@hv
		add	si,ax
		xor	cx,cx
@@VertNor:
@@DrawIt:	cmp	dh,0
		jz	@@Invis
		cmp	dl,0
		jz	@@Invis

		CalcScrOfs di
		CalcMask
		ClrQu

		mov	bl,ah

		mov	ds,@@SourceSEG
		dw	@@cmSubSi
@@SkipFAdd	db	?

		ClrQu
@@VertLoop:	push	cx
		mov	al,0
		org	$-1
@@FirstMask	db	?
		mov	cl,bl
		add	si,0
		org	$-1
@@ColAdd	db	?

@@HorLoop:	mov	ah,byte ptr ds:[si]
		inc	si
		or	ah,ah
		jz	@@NextPoint
		out	dx,al
		mov	byte ptr es:[di],ah
@@NextPoint:	rol	al,1
		adc	di,0
		loop	@@HorLoop
@@AfterHor:	pop	cx
		add	bp,ScrX/4
		mov	di,bp
		loop	@@VertLoop
		pop	bp
@@End:		popf
		ret

@@hv		dw	?
@@SourceSEG	dw	?
DrawSprite	endp

GetBitMap	proc	far
		arg	X:word,Y:word,H:word,V:word,Adr:dword
		uses	ds

 @@Get		macro	Panel
		mov	al,Panel
		out	dx,al
		mov	cx,H
		mov	si,bx
		rep	movsw
		endm

		cld
		mov	ds,SegA000
		les	di,Adr
		imul	bx,Y,ScrX4
		mov	ax,X
		shr	ax,2
		add	bx,ax
		mov	dx,3CEh
		mov	al,4
		out	dx,al
		inc	dx
		shr	H,3
 @@VLoop:	@@Get	0
		@@Get	1
		@@Get	2
		@@Get	3
		add	bx,ScrX4
		dec	V
		jnz	@@VLoop
		ret
GetBitMap	endp


PutBitMapDef	macro
		arg	X:word,Y:word,H:word,V:word,Adr:dword
		uses	ds
		cld
		mov	es,SegA000
		lds	si,Adr
		imul	bx,Y,ScrX4
		mov	ax,X
		shr	ax,2
		add	bx,ax
		mov	dx,3C4h
		mov	al,2
		out	dx,al
		inc	dx
		endm

PutBitMap	proc far
 @@Draw 	macro	Panel
		mov	al,Panel
		out	dx,al
		mov	cx,H
		mov	di,bx
		rep	movsw
		endm

		PutBitMapDef
		shr	H,3
 @@VLoop:	@@Draw 1
		@@Draw 2
		@@Draw 4
		@@Draw 8
		add	bx,ScrX4
		dec	V
		jnz	@@VLoop
		ret
PutBitMap	endp

PutTranspBitMap proc far
 @@Draw 	macro	Panel
		local	L,S
		mov	al,Panel
		out	dx,al
		mov	cx,H
		mov	di,bx
	L:	lodsb
		cmp	al,0
		jz	S
		mov	byte ptr es:[di],al
	S:	inc	di
		loop	L
		endm

		PutBitMapDef
		shr	H,2
 @@VLoop:	@@Draw 1
		@@Draw 2
		@@Draw 4
		@@Draw 8
		add	bx,ScrX4
		dec	V
		jnz	@@VLoop
		ret
PutTranspBitMap endp

SetVideoMode	proc far
		mov	ax,13h	   ; Call BIOS int10h (ax=13h)
		int	10h
		mov	dx,3c4h
		mov	ax,0604h
		out	dx,ax
		mov	ax,0100h
		out	dx,ax
		mov	dx,3c2h
		mov	al,0e7h
		out	dx,al
		mov	dx,3c4h
		mov	ax,0300h
		out	dx,ax
		mov	dx,3ceh 		; Set ModeX
		mov	ax,4005h
		out	dx,ax
		mov	ax,0506h
		out	dx,ax
		mov	es,SegA000
		xor	di,di			; Clear VRAM
		xor	ax,ax
		mov	cx,8000h
		rep	stosw
		mov	dx,3d4h 		; Set CRTC regs
		lea	si,@@ModeSetup
		mov	cx,18
	  SegCS rep	outsw
		mov	ScrY2,239
		mov	ScrY,240
		mov	PageSize,(ScrX4)*240
		ret
 @@ModeSetup	dw 0C11h,6b00h,5901h,5a02h,8e03h,5e04h,8a05h,0D06h,3e07h
		dw 4109h,0ea10h,08c11h,0df12h,2d13h,14h,0e715h,616h,0e317h
SetVideoMode	endp

SetDoubleRetrace proc	far
		mov	dx,3D4h
		mov	ax,04009h
		out	dx,ax
		mov	ScrY2,479
		mov	ScrY,280
		mov	PageSize,(ScrX4)*480
		ret
SetDoubleRetrace endp

SetSingleRetrace proc	far
		mov	dx,3D4h
		mov	ax,04109h
		out	dx,ax
		mov	ScrY2,239
		mov	ScrY,240
		mov	PageSize,(ScrX4)*240
		ret
SetSingleRetrace endp

TruncateX	proc	near
		mov	ax,ScrX1
		cmp	ax,ss:[bx]
		jle	@@1
		mov	ss:[bx],ax
		inc	cl
      @@1:	mov	ax,ScrX2
		cmp	ax,ss:[bx]
		jge	@@2
		mov	ss:[bx],ax
		inc	cl
      @@2:	ret
TruncateX	endp

TruncateY	proc	near
		mov	ax,ScrY1
		cmp	ax,ss:[bx]
		jle	@@1
		mov	ss:[bx],ax
		inc	cl
      @@1:	mov	ax,ScrY2
		cmp	ax,ss:[bx]
		jge	@@2
		mov	ss:[bx],ax
		inc	cl
      @@2:	ret
TruncateY	endp


IntrHorLine	proc	near

; Draw horisontal line si-bx (es:di points to current Y)

		local	F:byte,L:byte

		cld
		mov	dx,3C4h
		mov	al,2
		out	dx,al
		inc	dx
		mov	cx,bx
		sub	cx,si
		jnz	@@NP
		mov	cx,si
		shr	si,2
		add	di,si
		and	cx,3
		mov	al,1
		shl	al,cl
		out	dx,al
		mov	al,CurColor
		stosb
		jmp	@@5
      @@NP:	inc	cx
		inc	bx
		mov	ax,si
		and	ax,3
		mov	F,al
		jz	@@@1
		mov	ah,4
		sub	ah,al
		shr	ax,8
		sub	cx,ax
		jnc	@@@1
		xor	cx,cx
    @@@1:	mov	ax,bx
		and	ax,3
		mov	L,al
		sub	cx,ax
		jnc	@@@3
		xor	cx,cx
     @@@3:	mov	ax,si
		shr	ax,2
		add	di,ax
		cmp	F,0
		jz	@@2
		cmp	L,0
		jz	@@@2
		cmp	cx,0
		jg	@@@2
		push	cx
		mov	cx,bx
		shr	cx,2
		mov	ax,si
		shr	ax,2
		cmp	ax,cx
		pop	cx
		jnz	@@@2
		mov	al,0Fh
		mov	cl,F
		shl	al,cl
		mov	cl,4
		sub	cl,L
		mov	ah,0Fh
		shr	ah,cl
		and	al,ah
		out	dx,al
		mov	al,CurColor
		stosb
		jmp	@@5
	@@@2:	push	cx
		mov	al,0Fh
		mov	cl,F
		shl	al,cl
		out	dx,al
		mov	al,CurColor
		stosb
		pop	cx
	 @@2:	shr	cx,2
		jz	@@3
		mov	al,0Fh
		out	dx,al
		mov	al,CurColor
		mov	ah,al
		cmp	Test8086,2
		jb	@@186
		.386
		push	ax
		push	ax
		pop	eax
		push	cx
		shr	cx,2
		rep	stosd
		pop	cx
		and	cx,3
		rep	stosb
		jmp	@@3
	 @@186: shr	cx,1
		rep	stosw
		adc	cx,0
		rep	stosb
	 @@3:	cmp	L,0
		jz	@@5
		mov	cl,4
		sub	cl,L
		mov	al,0Fh
		shr	al,cl
		out	dx,al
		mov	al,CurColor
		stosb
      @@5:	ret
IntrHorLine	endp


HorizLine	proc	far
		arg	x1:word,x2:word,y:word
		mov	cl,0
		lea	bx,x1
		call	TruncateX
		lea	bx,x2
		call	TruncateX
		cmp	cl,1
		ja	@@5
		mov	ax,y
		cmp	ax,ScrY1
		jl	@@5
		cmp	ax,ScrY2
		jg	@@5
		mov	di,x1
		cmp	di,x2
		jle	@@1
		xchg	di,x2
		mov	x1,di
	@@1:	cmp	LineMode,0
		jz	@@V
		les	di,LinePoints
		add	di,LinePointsPos
		mov	cx,x2
		cmp	Test8086,2
		jb	@@186
		.386
		mov	ax,x1
		sub	cx,ax
		inc	cx
		mov	bx,cx
		shl	bx,2
		add	LinePointsPos,bx
		shl	eax,16
		mov	ax,y
		mov	ebx,10000h
	@@P3:	stosd
		add	eax,ebx
		loop	@@P3
		.186
		jmp	@@5
	@@186:	mov	si,x1
		sub	cx,si
		inc	cx
		mov	bx,cx
		shl	bx,2
		add	LinePointsPos,bx
		mov	dx,y
	@@P1:	mov	ax,dx
		stosw
		mov	ax,si
		inc	si
		stosw
		loop	@@P1
		jmp	@@5

	@@V:	mov	es,SegA000
		imul	di,y,ScrX4
		add	di,ImageOffset
		mov	si,x1
		mov	bx,x2
		call	IntrHorLine
      @@5:	ret
HorizLine	endp

FullHorLine	proc	far
		arg	y:word
		cld
		mov	es,SegA000
		imul	di,y,ScrX4
		add	di,ImageOffset
		cmp	Test8086,2
		mov	dx,3C4h
		mov	ax,0F02h
		out	dx,ax
		jb	@@186
		.386
		mov	cl,CurColor
		mov	ch,cl
		mov	ax,cx
		shl	eax,16
		mov	ax,cx
		mov	cx,22	; ScrX4/4
		rep	stosd
		stosw
		.186
		jmp	@@End
	@@186:	mov	al,CurColor
		mov	ah,al
		mov	cx,ScrX4/2
		rep	stosw
	@@End:	ret
FullHorLine	endp

GridHorLine	proc	far
		arg	y:word,C1:byte,C2:byte,C3:byte,C4:byte
		cld
		mov	es,SegA000
		imul	di,y,ScrX4
		add	di,ImageOffset
		cmp	Test8086,2
		mov	dx,3C4h
		mov	al,2
		out	dx,al
		inc	dx
		mov	al,1
		out	dx,al
		mov	al,C1
		mov	es:[di],al
		mov	al,2
		out	dx,al
		mov	al,C2
		mov	es:[di],al
		mov	al,4
		out	dx,al
		mov	al,C3
		mov	es:[di],al
		mov	al,8
		out	dx,al
		mov	al,C4
		mov	es:[di],al
		mov	al,0Fh
		out	dx,al
		mov	dx,3CEh
		mov	ax,4105h
		out	dx,ax
		mov	al,es:[di]
		cmp	Test8086,2
		jb	@@186
		.386
		mov	cx,22	; ScrX4/4
		rep	stosd
		stosw
		.186
		jmp	@@1
	@@186:	mov	cx,ScrX4/2
		rep	stosw
	@@1:	mov	ax,4005h
		out	dx,ax
		ret
GridHorLine	endp


VertLine	proc	far
		arg	x:word,y1:word,y2:word
		cld
		mov	cl,0
		lea	bx,y1
		call	TruncateY
		lea	bx,y2
		call	TruncateY
		cmp	cl,1
		ja	@@LE
		mov	ax,y1
		cmp	ax,y2
		jbe	@@0
		xchg	ax,y2
		mov	y1,ax
	@@0:	cmp	LineMode,0
		jz	@@V
		les	di,LinePoints
		add	di,LinePointsPos
		mov	cx,y2
		cmp	Test8086,2
		jb	@@186
		.386
		mov	ax,y1
		sub	cx,ax
		shl	eax,16
		mov	ax,x
		inc	cx
		mov	bx,cx
		shl	bx,2
		add	LinePointsPos,bx
		ror	eax,16
	@@P3:	stosd
		inc	ax
		loop	@@P3
		.186
		jmp	@@LE
	@@186:	mov	si,y1
		sub	cx,si
		inc	cx
		mov	bx,cx
		shl	bx,2
		add	LinePointsPos,bx
		mov	dx,x
	@@P1:	mov	ax,si
		stosw
		inc	si
		mov	ax,dx
		stosw
		loop	@@P1
		jmp	@@LE

	@@V:	imul	ax,ScrX4
		add	ax,ImageOffset
		mov	di,x
		cmp	di,ScrX1
		jl	@@LE
		cmp	di,ScrX2
		jg	@@LE
		shr	di,2
		add	di,ax
		mov	dx,3C4h
		mov	cl,byte ptr x
		and	cl,3
		mov	bx,0102h
		shl	bh,cl
		mov	cx,y2
		sub	cx,y1
		inc	cx
		mov	es,SegA000
		mov	ax,bx
		out	dx,ax
		mov	al,CurColor
      @@2:	mov	es:[di],al
		add	di,ScrX4
		loop	@@2
      @@LE:	ret
VertLine	endp

Clipping	proc	far x1,y1,x2,y2 : word
		mov	si,X1
		mov	di,Y1
		mov	bx,X2
		mov	dx,Y2
		call	SetOutCodes
		mov	cl,al
		mov	bx,si
		mov	dx,di
		call	SetOutCodes
		mov	ch,al
@@REPEAT:	mov	ah,al
		or	al,cl		;Inside if zero
		je	@@ExitTrue
		and	ah,cl		;Outside if not zero
		jne	@@ExitFalse
		cmp	ch,0
		jne	@@ELSE1
		xchg	si,X2
		xchg	di,Y2
		xchg	ch,cl
@@ELSE1:	test	ch,00000001b
		je	@@ELSE2
		mov	ax,Y2
		sub	ax,di
		mov	bx,ScrX1
		sub	bx,si
		imul	bx
		mov	bx,X2
		sub	bx,si
		idiv	bx
		jo	@@ExitFalse
		add	di,ax
		mov	si,ScrX1
		jmp	@@ELSE5
@@ELSE2:	test	ch,00000010b
		je	@@ELSE3
		mov	ax,X2
		sub	ax,si
		mov	bx,ScrY1
		sub	bx,di
		imul	bx
		mov	bx,Y2
		sub	bx,di
		idiv	bx
		jo	@@ExitFalse
		add	si,ax
		mov	di,ScrY1
		jmp	@@ELSE5
@@ELSE3:	test	ch,00000100b
		je	@@ELSE4
		mov	ax,Y2
		sub	ax,di
		mov	bx,ScrX2
		sub	bx,si
		imul	bx
		mov	bx,X2
		sub	bx,si
		idiv	bx
		jo	@@ExitFalse
		add	di,ax
		mov	si,ScrX2
		jmp	@@ELSE5
@@ELSE4:	test	ch,00001000b
		je	@@ELSE5
		mov	ax,X2
		sub	ax,si
		mov	bx,ScrY2
		sub	bx,di
		imul	bx
		mov	bx,Y2
		sub	bx,di
		idiv	bx
		jo	@@ExitFalse
		add	si,ax
		mov	di,ScrY2
@@ELSE5:	mov	bx,si
		mov	dx,di
		call	SetOutCodes
		mov	ch,al
		jmp	@@REPEAT
@@ExitFalse:	stc
@@ExitTrue:	mov	cx,X2
		mov	dx,Y2
		ret

SetOutCodes	proc	near
		cmp	Test8086,2
		jb	@@186
		.386
		cmp	bx,ScrX1
		setl	al
		cmp	bx,ScrX2
		setg	ah
		shl	ah,2
		or	al,ah
		cmp	dx,ScrY1
		setl	ah
		shl	ah,1
		or	al,ah
		cmp	dx,ScrY2
		setg	ah
		shl	ah,3
		or	al,ah
		.186
		jmp	@@End
	@@186:
		cmp	bx,ScrX1
		mov	al,1
		jl	@@1
		mov	al,0
	@@1:	cmp	bx,ScrX2
		mov	ah,1
		jg	@@2
		mov	ah,0
	@@2:	shl	ah,2
		or	al,ah
		cmp	dx,ScrY1
		mov	ah,1
		jl	@@3
		mov	ah,0
	@@3:	shl	ah,1
		or	al,ah
		cmp	dx,ScrY2
		mov	ah,1
		jg	@@4
		mov	ah,0
	@@4:	shl	ah,3
		or	al,ah
	@@End:
		ret
SetOutCodes	endp
Clipping	endp

PutTPoint	proc	far  ; PutTPoint has the same code as PutPixel !
PutTPoint	endp

PutPixel	proc	far
		arg	x:word, y:word
		mov	ax,x
		cmp	ax,ScrX1
		jl	@@Done
		cmp	ax,ScrX2
		jg	@@Done
		mov	ax,y
		cmp	ax,ScrY1
		jl	@@Done
		cmp	ax,ScrY2
		jg	@@Done
		mov	dx,3C4h
		mov	ax,0102h
		mov	cl,byte ptr x
		and	cl,3
		shl	ah,cl
		out	dx,ax
		mov	ax,y
		imul	ax,ScrX4
		add	ax,ImageOffset
		mov	bx,x
		shr	bx,2
		add	bx,ax
		mov	es,SegA000
		mov	al,CurColor
		mov	es:[bx],al
      @@Done:	ret
PutPixel	endp

GetPixel	proc	far
		arg	x:word, y:word
		mov	ax,x
		cmp	ax,ScrX1
		jl	@@Invis
		cmp	ax,ScrX2
		jg	@@Invis
		mov	ax,y
		cmp	ax,ScrY1
		jl	@@Invis
		cmp	ax,ScrY2
		jng	@@Vis
      @@Invis:	mov	al,0
		jmp	@@End
      @@Vis:	mov	es,SegA000
		mov	ax,y
		imul	ax,ScrX4
		add	ax,ImageOffset
		mov	bx,x
		shr	bx,2
		add	bx,ax
		mov	al,4
		mov	ah,byte ptr x
		and	ah,3
		mov	dx,3CEh
		out	dx,ax
		mov	al,es:[bx]
      @@End:	ret
GetPixel	endp


Line		proc	far
		arg	x1:word,y1:word,x2:word,y2:word
		local	DeltaX:word,DeltaY:word
		push	x1 y1 x2 y2
		call	Clipping
		jc	@@LExit
		cmp	si,cx
		jle	@@LTR
		xchg	si,cx
		xchg	di,dx
      @@LTR:	mov	x1,si
		mov	y1,di
		mov	x2,cx
		mov	y2,dx
		mov	ax,cx
		sub	ax,si
		je	@@VLine
		mov	bx,dx
		sub	bx,di
		je	@@HLine
		jns	@@SY
		neg	bx
		mov	DeltaY,bx
		neg	bx
		jmp	@@SX
	@@SY:	mov	DeltaY,bx
	@@SX:	mov	DeltaX,ax
		cwd
		idiv	bx
		or	ax,ax
		je	@@DXmin
		push	bx
		mov	dx,bx
		mov	bx,DeltaX
		xor	ax,ax
		neg	dx
		cmp	dx,bx
		je	@@Angle45
		neg	dx
		cmp	dx,bx
		je	@@Angle45

		cmp	LineMode,0
		jz	@@MaxV
		les	di,LinePoints
		add	di,LinePointsPos
		mov	cx,DeltaX
		inc	cx
		mov	bx,cx
		shl	bx,2
		add	LinePointsPos,bx
		mov	dx,1
		mov	ax,y1
		cmp	ax,y2
		jb	@@@Inv0
		neg	dx
	@@@Inv0:mov	bx,x1
		mov	si,DeltaX
		shr	si,1
	@@@1:	stosw
		xchg	ax,bx
		stosw
		xchg	ax,bx
		sub	si,DeltaY
		ja	@@@1N
		add	si,DeltaX
		add	ax,dx
	@@@1N:	inc	bx
		loop	@@@1
		jmp	@@LExit
	@@maxV: sar	dx,1
		rcr	ax,1
		idiv	bx
		or	ax,ax
		jns	@@P
		neg	ax
      @@P:	shl	ax,1
		mov	si,ax
		mov	ax,ScrX4
		mul	y1
		add	ax,ImageOffset
		mov	di,x1
		shr	di,2
		add	di,ax
		mov	es,SegA000
		mov	ax,1102h
		mov	cl,byte ptr x1
		and	cl,3
		rol	ah,cl
		mov	cx,ScrX4
		pop	dx
		or	dx,dx
		jge	@@2
		neg	cx
      @@2:	mov	dx,3C4h
		out	dx,ax
		mov	al,ah
		inc	dx
		mov	ah,CurColor
		push	bp
		mov	bp,8000h
      @@5:	out	dx,al
		mov	es:[di],ah
		rol	al,1
		adc	di,0
		add	bp,si
		jnc	@@4
		add	di,cx
      @@4:	dec	bx
		jge	@@5
		pop	bp
		jmp	@@LExit

      @@DXmin:	cmp	LineMode,0
		jz	@@minV
		les	di,LinePoints
		add	di,LinePointsPos
		mov	cx,DeltaY
		inc	cx
		mov	bx,cx
		shl	bx,2
		add	LinePointsPos,bx
		mov	dx,1
		mov	ax,y1
		cmp	ax,y2
		jb	@@@Inv1
		neg	dx
	@@@Inv1:mov	bx,x1
		mov	si,DeltaY
		shr	si,1
	@@@2:	stosw
		xchg	ax,bx
		stosw
		xchg	ax,bx
		sub	si,DeltaX
		ja	@@@2N
		add	si,DeltaY
		inc	bx
	@@@2N:	add	ax,dx
		loop	@@@2
		jmp	@@LExit


	@@minV: push	bx
		mov	dx,DeltaX
		xor	ax,ax
		sar	dx,1
		rcr	ax,1
		idiv	bx
		or	ax,ax
		jns	@@Q
		neg	ax
      @@Q:	shl	ax,1
		mov	si,ax
		or	bx,bx
		jns	@@R
		neg	bx
      @@R:	mov	ax,ScrX4
		mul	y1
		add	ax,ImageOffset
		mov	di,x1
		shr	di,2
		add	di,ax
		mov	es,SegA000
		mov	ax,1102h
		mov	cl,byte ptr x1
		and	cl,3
		rol	ah,cl
		mov	cx,ScrX4
		pop	dx
		or	dx,dx
		jge	@@8
		neg	cx
      @@8:	mov	dx,3C4h
		out	dx,ax
		mov	al,ah
		inc	dx
		mov	ah,CurColor
		push	bp
		mov	bp,8000h
      @@6:	mov	es:[di],ah
		add	bp,si
		jnc	@@7
		rol	al,1
		adc	di,0
		out	dx,al
	@@7:	add	di,cx
		dec	bx
		jge	@@6
		pop	bp
		jmp	@@LExit

      @@Angle45:cmp	LineMode,0
		jz	@@A45V

		les	di,LinePoints
		add	di,LinePointsPos
		mov	cx,DeltaY
		inc	cx
		mov	bx,cx
		shl	bx,2
		add	LinePointsPos,bx
		mov	dx,1
		mov	ax,y1
		cmp	ax,y2
		jb	@@@Inv4
		neg	dx
	@@@Inv4:mov	bx,x1
	@@@4:	stosw
		add	ax,dx
		xchg	ax,bx
		stosw
		inc	ax
		xchg	ax,bx
		loop	@@@4
		jmp	@@LExit

	@@A45V: mov	ax,ScrX4
		mul	y1
		add	ax,ImageOffset
		mov	di,x1
		shr	di,2
		add	di,ax
		mov	es,SegA000
		mov	ax,1102h
		mov	cl,byte ptr x1
		and	cl,3
		rol	ah,cl
		mov	cx,ScrX4
		pop	dx
		or	dx,dx
		jge	@@9
		neg	cx
      @@9:	mov	dx,3C4h
		out	dx,ax
		mov	al,ah
		inc	dx
		mov	ah,CurColor
      @@A:	out	dx,al
		mov	es:[di],ah
		rol	al,1
		adc	di,0
		add	di,cx
		dec	bx
		jge	@@A
		jmp	@@LExit

      @@VLine:	push	x1 y1 y2
		call	VertLine
		jmp	@@LExit

      @@HLine:	push	x1 x2 y1
		call	HorizLine
      @@LExit:	ret
Line		endp

Bar		proc	far
		arg	x1:word,y1:word,x2:word,y2:word
		local	DY:word,SV:byte
		cld
		mov	cl,0
		lea	bx,x1
		call	TruncateX
		lea	bx,x2
		call	TruncateX
		cmp	cl,1
		ja	@@LocEx
		mov	cl,0
		lea	bx,y1
		call	TruncateY
		lea	bx,y2
		call	TruncateY
		cmp	cl,1
		ja	@@LocEx
      @@7:	mov	ax,x1
		cmp	ax,x2
		jle	@@5
		xchg	ax,x2
		mov	x1,ax
      @@5:	mov	ax,y1
		cmp	ax,y2
		jle	@@6
		xchg	ax,y2
		mov	y1,ax
      @@6:	imul	ax,ScrX4
		add	ax,ImageOffset
		mov	di,x1
		shr	di,2
		add	di,ax
		mov	cl,byte ptr x1
		and	cl,3
		mov	bh,01h
		shl	bh,cl
		mov	SV,bh
		mov	cx,y2
		sub	cx,y1
		inc	cx
		mov	DY,cx
		mov	si,x2
		sub	si,x1
		inc	si
		mov	dx,3C4h
		mov	es,SegA000
      @@0:	push	si di
		mov	bl,4
		mov	bh,SV
      @@1:	push	di
		mov	ah,bh
		mov	al,2
		out	dx,ax
		mov	al,CurColor
		cmp	Test8086,2
		jb	@@186
		.386
		mov	cl,al
		mov	ch,al
		mov	ax,cx
		shl	eax,16
		mov	ax,cx
		mov	cx,si
		add	cx,3
		shr	cx,2
		push	cx
		shr	cx,2
		rep	stosd
		pop	cx
		and	cx,3
		rep	stosb
		.186
		jmp	@@STO
    @@186:	mov	ah,al
		mov	cx,si
		add	cx,3
		shr	cx,3
		rep	stosw
		adc	cl,0
		rep	stosb
      @@STO:	pop	di
		shl	bh,1
		cmp	bh,8
		jbe	@@3
		mov	bh,1
		inc	di
      @@3:	dec	si
		jle	@@4
		dec	bl
		jne	@@1
      @@4:	pop	di
		pop	si
		add	di,ScrX4
		dec	DY
		jne	@@0
      @@LocEx:
		ret
Bar		endp

Bar4		proc	far
		arg	x:word,y:word,w:word,h:word
		cld
		mov	ax,y
		imul	ax,ScrX4
		add	ax,ImageOffset
		mov	di,x
		shr	di,2
		add	di,ax
		mov	dx,3C4h
		mov	ax,0F02h
		out	dx,ax
		mov	es,SegA000
		add	w,3
		shr	w,2
		mov	al,CurColor
		mov	ah,al
		mov	si,ScrX4
		sub	si,w
		mov	bx,h
		cmp	Test8086,2
		jb	@@186
		.386
		mov	cx,ax
		shl	eax,16
		mov	ax,cx
      @@386:	mov	cx,w
		push	cx
		shr	cx,2
		rep	stosd
		pop	cx
		and	cx,3
		rep	stosb
		add	di,si
		dec	bx
		jne	@@386
		.186
		jmp	@@LocEx
      @@186:	mov	cx,w
		shr	cx,1
		rep	stosw
		adc	cl,0
		rep	stosb
		add	di,si
		dec	bx
		jne	@@186
      @@LocEx:
		ret
Bar4		endp

InternalEllipse proc	near
		arg	x:word,y:word,RadX:word,RadY:word,What:Byte
		local	LoVARd:word,HiVARd:word,LoVARdx:word,HiVARdx:word
		local	PutProc:word,LoVARd:word,HiVARd:word,LoVARdx:word
		local	HiVARdx:word,PutProc:word,LoVARdy:word,HiVARdy:word
		local	LoAsquared:word,HiAsquared:word,LoBsquared:word
		local	HiBsquared:word,LoTwoAsquared:word,DtX:word
		local	HiTwoAsquared:word,LoTwoBsquared:word
		local	HiTwoBsquared:word,ULAddr:word,URAddr:word
		local	LRAddr:word,LLAddr:Word,LongMultiply:word
		local	LMask:byte,RMask:byte;

		lea	ax,LongMul386
		cmp	Test8086,2
		jb	@@SetMulPrc
		lea	ax,LongMul186
  @@SetMulPrc:	mov	LongMultiply,ax
		mov	PutProc,offset Set4Pixels
		cmp	What,1
		jne	@@NoOne
		mov	PutProc,offset DrawLines
@@NoOne:	mov	DtX,0
	   ; initial constants
		mov	ax,RadX
		mul	ax
		mov	LoAsquared,ax
		mov	HiAsquared,dx	 ; a^2
		shl	ax,1
		rcl	dx,1
		mov	LoTwoAsquared,ax
		mov	HiTwoAsquared,dx ; 2*a^2
		mov	ax,RadY
		mul	ax
		mov	LoBsquared,ax
		mov	HiBsquared,dx	 ; b^2
		shl	ax,1
		rcl	dx,1
		mov	LoTwoBsquared,ax
		mov	HiTwoBsquared,dx ; 2*b^2
	   ; plot pixels from (0,b) until dy/dx = -1
	   ; initial buffer address and bit mask
		mov	ax,ScrX4
		mul	RadY
		mov	si,ax
		mov	di,ax
		mov	ax,y
		mov	bx,x
		mov	cl,bl
		mov	dx,ScrX4
		mul	dx
		shr	bx,2
		add	bx,ax
		add	bx,ImageOffset
		mov	es,SegA000
		add	si,bx		   ; SI := offset of (0,b)
		mov	ULAddr,si
		mov	URAddr,si
		sub	bx,di		   ; AX := offset of (0,-b)
		mov	LLAddr,bx
		mov	LRAddr,bx
	   ; initial decision variables
		xor	ax,ax
		mov	LoVARdx,ax
		mov	HiVARdx,ax
		mov	ax,LoTwoAsquared
		mov	dx,HiTwoAsquared
		mov	cx,RadY
		call	LongMultiply
		mov	LoVARdy,ax
		mov	HiVARdy,dx
		mov	ax,LoAsquared
		mov	dx,HiAsquared
		sar	dx,1
		rcr	ax,1
		sar	dx,1
		rcr	ax,1		   ; DX:AX = Asquared/4
		add	ax,LoBsquared
		adc	dx,HiBsquared	   ; DX:AX = Bsquared + Asquared/4
		mov	LoVARd,ax
		mov	HiVARd,dx
		mov	ax,LoAsquared
		mov	dx,HiAsquared
		mov	cx,RadY
		call	LongMultiply	  ; DX:AX = Asquared*b
		sub	LoVARd,ax
		sbb	HiVARd,dx	   ; d = Bsquared - Asquared*b + Asquared/4
	   ; loop until dy/dx >= -1
		mov	bx,RadY 	   ; BX := initial y-coordinate
		xor	cx,cx		   ; CH := 0 (initial y-increment)
					; CL := 0 (initial x-increment)
@@L10:		mov	ax,LoVARdx
		mov	dx,HiVARdx
		sub	ax,LoVARdy
		sbb	dx,HiVARdy
		jns  @@L20		 ; jump if dx>=dy
		call	PutProc
		mov	cx,1		   ; CH := 0 (y-increment)
					; CL := 1 (x-increment)
		cmp	HiVARd,0
		js	@@L11		    ; jump if d < 0
		mov	ch,1		   ; increment in y direction
		dec	bx		   ; decrement current y-coordinate
		mov	ax,LoVARdy
		mov	dx,HiVARdy
		sub	ax,LoTwoAsquared   ; DX:AX := dy - TwoAsquared
		sbb	dx,HiTwoAsquared
		mov	LoVARdy,ax
		mov	HiVARdy,dx	   ; dy -= TwoAsquared
		sub	LoVARd,ax
		sbb	HiVARd,dx	   ; d -= dy
@@L11:		mov	ax,LoVARdx
		mov	dx,HiVARdx
		add	ax,LoTwoBsquared   ; DX:AX := dx + TwoBsquared
		adc	dx,HiTwoBsquared
		mov	LoVARdx,ax
		mov	HiVARdx,dx	   ; dx += TwoBsquared
		add	ax,LoBsquared
		adc	dx,HiBsquared	   ; DX:AX := dx + Bsquared
		add	LoVARd,ax
		adc	HiVARd,dx	   ; d += dx + Bsquared
		jmp	@@L10
	   ; plot pixels from current (x,y) until y < 0
	   ; initial buffer address and bit mask
@@L20:		push	bx cx
		mov	ax,LoAsquared
		mov	dx,HiAsquared
		sub	ax,LoBsquared
		sbb	dx,HiBsquared
		mov	bx,ax
		mov	cx,dx
		sar	dx,1
		rcr	ax,1		   ; DX:AX := (Asquared-Bsquared)/2
		add	ax,bx
		adc	dx,cx		   ; DX:AX := 3*(Asquared-Bsquared)/2
		sub	ax,LoVARdx
		sbb	dx,HiVARdx
		sub	ax,LoVARdy
		sbb	dx,HiVARdy	   ; DX:AX := 3*(Asquared-Bsquared)/2 - (dx+dy)
		sar	dx,1
		rcr	ax,1   ; DX:AX := ( 3*(Asquared-Bsquared)/2 - (dx+dy) )/2
		add	LoVARd,ax
		adc	HiVARd,dx
	   ; loop until y < 0
		pop	cx bx		   ; CH,CL := y- and x-increments
@@L21:		call	PutProc 	   ; BX := y
		mov	cx,100h 	   ; CH := 1 (y-increment)
	   ; CL := 0 (x-increment)
		cmp  HiVARd,0
		jns	@@L22		    ; jump if d >= 0
		mov	cl,1		    ; increment in x direction
		mov	ax,LoVARdx
		mov	dx,HiVARdx
		add	ax,LoTwoBsquared   ; DX:AX := dx + TwoBsquared
		adc	dx,HiTwoBsquared
		mov	LoVARdx,ax
		mov	HiVARdx,dx
		add	LoVARd,ax
		adc	HiVARd,dx
@@L22:		mov	ax,LoVARdy
		mov	dx,HiVARdy
		sub	ax,LoTwoAsquared
		sbb	dx,HiTwoAsquared
		mov	LoVARdy,ax
		mov	HiVARdy,dx
		sub	ax,LoAsquared
		sbb	dx,HiAsquared
		sub	LoVARd,ax
		sbb	HiVARd,dx
		dec	bx
		jns	@@L21		    ; loop if y >= 0
@@Lexit:	ret

LongMul186	proc near
		push	ax
		mov	ax,dx
		mul	cx
		xchg	ax,cx
		pop	dx
		mul	dx
		add	dx,cx
		ret
LongMul186	endp

LongMul386	proc near
		.386
		xchg	ax,dx
		shl	eax,16
		mov	ax,dx
		movzx	ecx,cx
		mul	ecx
		shld	edx,eax,16
		.186
		ret
LongMul386	endp

Set4Pixels	proc near
		uses	ax,bx,dx
		push	bx
		xor	ch,ch
		add	DtX,cx
		mov	ax,x
		sub	ax,DtX
		mov	ULAddr,ax
		add	bx,y
		cmp	bx,ScrY2
		jg	@@2
		push	ax
		mov	ax,x
		add	ax,DtX
		mov	URAddr,ax
		push	ax
		mov	ax,ScrX4
		mul	bx
		add	ax,ImageOffset
		pop	di
		push	ax
		mov	dx,3C4h
		mov	cx,di
		cmp	cx,ScrX1
		jl	@@1
		cmp	cx,ScrX2
		jg	@@1
		shr	di,2
		and	cl,3
		add	di,ax
		mov	ax,0102h
		shl	ah,cl
		out	dx,ax
		mov	al,CurColor
		mov	es:[di],al
@@1:		pop	ax
		pop	di
		mov	cx,di
		cmp	cx,ScrX1
		jl	@@2
		cmp	cx,ScrX2
		jg	@@2
		shr	di,2
		and	cl,3
		add	di,ax
		mov	ax,0102h
		shl	ah,cl
		out	dx,ax
		mov	al,CurColor
		mov	es:[di],al

@@2:		pop	bx
		mov	ax,y
		sub	ax,bx
		cmp	ax,ScrY1
		jl	@@4
		imul	ax,ScrX4
		mov	dx,3C4h
		add	ax,ImageOffset
		mov	di,ULAddr
		push	ax
		mov	cx,di
		cmp	cx,ScrX1
		jl	@@3
		cmp	cx,ScrX2
		jg	@@3
		shr	di,2
		and	cl,3
		add	di,ax
		mov	ax,0102h
		shl	ah,cl
		out	dx,ax
		mov	al,CurColor
		mov	es:[di],al
@@3:		pop	ax

		mov	di,URAddr
		mov	cx,di
		cmp	cx,ScrX1
		jl	@@4
		cmp	cx,ScrX2
		jg	@@4
		shr	di,2
		and	cl,3
		add	di,ax
		mov	ax,0102h
		shl	ah,cl
		out	dx,ax
		mov	al,CurColor
		mov	es:[di],al
@@4:		ret
Set4Pixels	endp

DrawLines	proc near
		uses	ax,bx,dx
		push	bx
		xor	ch,ch
		add	DtX,cx
		mov	ax,x
		sub	ax,DtX
		mov	ULAddr,ax
		push	ax
		mov	ax,x
		add	ax,DtX
		mov	URAddr,ax
		push	ax
		add	bx,y
		push	bx
		call	HorizLine
		pop	bx
		push	ULAddr
		push	URAddr
		mov	ax,y
		sub	ax,bx
		push	ax
		call	HorizLine
		ret
DrawLines	endp
InternalEllipse endp


		.386

ColorPoly	proc	far
		arg	Bounds : DWord, Num : Word
		local	CurrentX1 : dword	; Current X1
		local	CurrentX2 : dword	; Current X2
		local	Vertex1   : word	; First poly vertex
		local	Vertex2   : word	; Second poly vertex
		local	StartX1   : word	; Start X for first line
		local	FinalX1   : word	; Final X for first line
		local	StartX2   : word	; Start X for second line
		local	FinalX2   : word	; Final X for second line
		local	FinalY1   : word	; Final Y for first line
		local	FinalY2   : word	; Final Y for second line
		local	LastPoint : byte	; 1 if processing last point
		cld
		les	si,Bounds

;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-
		push	bp
		mov	cx,Num
		mov	di,es:[si+2]
		mov	bx,32767
		mov	bp,-32768
		mov	dl,1
@@L1:		SegES	lodsw
		cmp	di,es:[si]
		sete	dh
		and	dl,dh
		add	si,2
		cmp	ax,bx
		jg	@@L11
		mov	bx,ax
@@L11:		cmp	ax,bp
		jl	@@L12
		mov	bp,ax
@@L12:		loop	@@L1
		mov	ax,bp
		pop	bp
		cmp	ax,ScrX1
		jl	@@Done
		cmp	bx,ScrX2
		jg	@@Done
		sub	ax,bx
		jo	@@Done
		cmp	dl,1
		je	@@DoLine
		mov	si,word ptr Bounds
;*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-*-

		mov	bx,32767
		mov	di,-32768
		xor	cx,cx
@@L2:		add	si,2
		SegES	lodsw
		cmp	ax,bx
		jg	@@L3
		mov	bx,ax
		mov	dx,cx
@@L3:		cmp	ax,di
		jle	@@L4
		mov	di,ax
@@L4:		inc	cx
		cmp	cx,Num
		jb	@@L2
		cmp	di,ScrY1
		jl	@@Done
		cmp	bx,ScrY2
		jg	@@Done
		sub	di,bx
		jo	@@Done

		mov	si,word ptr Bounds
		mov	Vertex1,dx
		mov	Vertex2,dx
		mov	bx,dx
		shl	bx,2
		add	si,bx
		SegES	lodsw
		mov	FinalX1,ax
		mov	FinalX2,ax
		mov	word ptr CurrentX1+2,ax
		mov	word ptr CurrentX2+2,ax
		SegES	lodsw
		mov	FinalY1,ax
		mov	FinalY2,ax
		mov	si,ax
		imul	ax,ScrX4
		mov	LastPoint,0
		mov	es,SegA000
		mov	di,ImageOffset
		add	di,ax
		mov	dx,si
		mov	fs,word ptr Bounds+2

;**********°±²Û Main loop Û²±°*************
; DI = VRAM addr (X=0)
; DX = current Y
@@REPEAT:	cmp	dx,FinalY1
		jge	@@BOUND1
@@ELSE1:	cmp	dx,FinalY2
		jge	@@BOUND2
@@ELSE2:	cmp	dx,ScrY1
		jl	@@IncY
		mov	si,word ptr CurrentX1+2
		mov	bx,word ptr CurrentX2+2
		call	@@DrawLine

		add	CurrentX1,12345678h
@@DeltaX1	equ	dword ptr $-4
		add	CurrentX2,12345678h
@@DeltaX2	equ	dword ptr $-4
		add	di,ScrX4
		inc	dx
		cmp	dx,ScrY2
		jle	@@REPEAT
		jmp	@@Done

@@IncY: 	mov	ax,ScrY1
		cmp	ax,FinalY1
		jl	@@IY_1
		mov	ax,FinalY1
@@IY_1: 	cmp	ax,FinalY2
		jl	@@IY_2
		mov	ax,FinalY2
@@IY_2: 	mov	si,ax
		sub	ax,dx
		movzx	eax,ax
		mov	ebx,eax

		mul	@@DeltaX1
		add	CurrentX1,eax
		mov	eax,ebx
		mul	@@DeltaX2
		add	CurrentX2,eax
		mov	ax,ScrX4
		mul	bx
		add	di,ax
		mov	dx,si
		cmp	dx,FinalY2
		jge	@@BOUND2
		cmp	dx,FinalY1
		jl	@@ELSE2

@@BOUND1:	cmp	LastPoint,0
		jne	@@Done
		mov	bx,Vertex1
		dec	bx
		jge	@@11
		mov	bx,Num
		dec	bx
@@11:		mov	Vertex1,bx
		cmp	bx,Vertex2
		sete	LastPoint
		mov	si,word ptr Bounds
		shl	bx,2
		add	si,bx
		mov	ax,fs:[si]	; X
		xchg	ax,FinalX1
		mov	StartX1,ax
		mov	word ptr CurrentX1+2,ax
		mov	word ptr CurrentX1,8000h
		mov	ax,fs:[si+2]	; Y
		mov	FinalY1,ax
		sub	ax,dx
		jg	@@12

		cmp	dx,ScrY1
		jl	@@BOUND1
		mov	si,StartX1
		mov	bx,FinalX1
		call	@@DrawLine
		jmp	@@BOUND1

@@12:		mov	si,dx		; push dx
		movzx	ebx,ax
		mov	ax,FinalX1
		sub	ax,StartX1
		shl	eax,10h
		cdq
		idiv	ebx

		mov	@@DeltaX1,eax
		mov	dx,si		; pop dx
		jmp	@@ELSE1

@@BOUND2:	cmp	LastPoint,0
		jne	@@Done
		mov	bx,Vertex2
		inc	bx
		cmp	bx,Num
		jb	@@21
		xor	bx,bx
@@21:		mov	Vertex2,bx
		cmp	bx,Vertex1
		sete	LastPoint
		mov	si,word ptr Bounds
		shl	bx,2
		add	si,bx
		mov	ax,fs:[si]
		xchg	ax,FinalX2
		mov	StartX2,ax
		mov	word ptr CurrentX2+2,ax
		mov	word ptr CurrentX2,8000h
		mov	ax,fs:[si+2]
		mov	FinalY2,ax
		sub	ax,dx
		jg	@@22

		cmp	dx,ScrY1
		jl	@@BOUND2
		mov	si,StartX2
		mov	bx,FinalX2
		call	@@DrawLine
		jmp	@@BOUND2

@@22:		mov	si,dx		; push dx
		movzx	ebx,ax
		mov	ax,FinalX2
		sub	ax,StartX2
		shl	eax,10h
		cdq
		idiv	ebx
		mov	@@DeltaX2,eax
		mov	dx,si		; pop dx
		jmp	@@ELSE2

@@DoLine:	cmp	di,ScrY1
		jl	@@Done
		cmp	di,ScrY2
		jg	@@Done
		mov	bx,32767
		mov	dx,-32768
		mov	cx,Num
		mov	si,word ptr Bounds
@@DLL0: 	SegES	lodsw
		add	si,2
		cmp	ax,bx
		jg	@@DLL1
		mov	bx,ax
@@DLL1: 	cmp	ax,dx
		jl	@@DLL2
		mov	dx,ax
@@DLL2: 	loop	@@DLL0
		mov	si,dx
		mov	dx,di
		mov	ax,ScrX4
		imul	di
		mov	es,SegA000
		mov	di,ImageOffset
		add	di,ax
		push	offset @@Done

;*** si = StartX1; bx = FinalX1; ***
@@DrawLine:	cmp	si,bx
		jle	@@DL1
		xchg	si,bx
@@DL1:		cmp	si,ScrX2
		jg	@@LEx
		cmp	bx,ScrX1
		jl	@@LEx
		cmp	si,ScrX1
		jge	@@DL2
		mov	si,ScrX1
@@DL2:		cmp	bx,ScrX2
		jle	@@DL3
		mov	bx,ScrX2
@@DL3:		push	di dx
		call	IntrHorLine
		pop	dx di
@@LEx:		retn
@@Done: 	ret
ColorPoly	endp

WaitRetrace	proc	far
		mov   dx,3DAh
	@@1:	in    al,dx
		test  al,8
		je    @@1
	@@2:	in    al,dx
		test  al,8
		jne   @@2
		ret
WaitRetrace	endp

SetAllPalette	proc	far
		arg	Addr:dword
		call	WaitRetrace
		les	si,Addr
		mov	dx,3C8h
		mov	al,0
		out	dx,al
		mov	cx,100h*3
		inc	dx
	SegES	rep	outsb
		ret
		endp

Cls		proc	far
		cld
		xor	di,di
		mov	dx,3C4h
		mov	ax,0F02h
		out	dx,ax
		mov	es,SegA000
		mov	al,BackgroundColor
		mov	ah,al
		cmp	Test8086,2
		jb	@@186
		.386
		mov	cx,PageSize
		shr	cx,2
		push	ax
		push	ax
		pop	eax
		rep	stosd
		.186
		jmp	@@@
	@@186:	mov	cx,PageSize
		shr	cx,1
		rep	stosw
	@@@:	ret
Cls		endp

ClearPage	proc	far
		arg	Pg:byte
		cld
		mov	al,Pg
		mov	ah,0
		mul	PageSize
		mov	di,ax
		mov	dx,3C4h
		mov	ax,0F02h
		out	dx,ax
		mov	es,SegA000
		mov	al,BackgroundColor
		mov	ah,al
		cmp	Test8086,2
		jb	@@186
		.386
		mov	cx,PageSize
		shr	cx,2
		push	ax
		push	ax
		pop	eax
		rep	stosd
		.186
		jmp	@@@
	@@186:	mov	cx,PageSize
		shr	cx,1
		rep	stosw
	@@@:	ret
ClearPage	endp

PageCopy	proc	far
		arg	Page1:byte,Page2:byte
		mov	es,SegA000
		mov	al,Page1
		mov	ah,0
		mul	PageSize
		mov	si,ax
		mov	al,Page2
		mov	ah,0
		mul	PageSize
		mov	di,ax
		mov	cx,PageSize
		mov	dx,3C4h
		mov	ax,0F02h
		out	dx,ax
		mov	dx,3CEh
		mov	ax,0003h
		out	dx,ax
		mov	ax,4105h
		out	dx,ax
		SegES rep movsb
		mov	ax,4005h
		out	dx,ax
		ret
PageCopy	endp

GPCopy		proc	far
		arg	x:word,y:word,h:word,v:word,Page1:byte,d_x:word,d_y:word,Page2:byte
		uses	ds
		mov	al,Page1
		mov	ah,0
		mov	bx,PageSize
		mul	bx
		mov	si,x
		shr	si,2
		add	si,ax
		imul	ax,y,ScrX4
		add	si,ax
		mov	al,Page2
		mov	ah,0
		mul	bx
		mov	di,d_x
		shr	di,2
		add	di,ax
		imul	ax,d_y,ScrX4
		add	di,ax
		mov	ax,0A000h
		mov	ds,ax
		mov	es,ax
		mov	dx,03CEh
		mov	ax,4105h
		out	dx,ax		; Write mode 1
		mov	dl,0C4h
		mov	ax,0F02h
		out	dx,ax
		mov	ax,h
		shr	ax,2
		mov	bx,v
		mov	dx,ScrX4
		sub	dx,ax

@@NextRow:	mov	cx,ax
		rep	movsb
		add	si,dx
		add	di,dx
		dec	bx
		jne	@@NextRow
		mov	dx,03CEh
		mov	ax,4005h
		out	dx,ax		; Write mode 0
		ret
GPCopy		endp

SetActivePage	proc	far
		arg	Pg:byte
		mov	al,Pg
		mov	ah,0
		mov	bx,PageSize
		mul	bx
		mov	ImageOffset,ax
		ret
SetActivePage	endp

SetVisualPage	proc	far
		arg	Pg:byte
		mov	al,Pg
		mov	ah,0
		mov	bx,PageSize
		mul	bx
		mov	bx,ax
		mov	dx,3D4h
		mov	al,0Ch
		mov	ah,bh
		out	dx,ax
		inc	al
		mov	ah,bl
		out	dx,ax
		ret
SetVisualPage	endp


SetVisualOffset proc	far
		arg	Ofs:word
		mov	bx,Ofs
		mov	dx,3D4h
		mov	al,0Ch
		mov	ah,bh
		out	dx,ax
		inc	al
		mov	ah,bl
		out	dx,ax
		ret
SetVisualOffset endp
		end

      ***  THAT'S ALL FOLKS ! ***
