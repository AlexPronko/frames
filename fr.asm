; BSD LICENSE:
; THIS SOFTWARE IS PROVIDED BY ALEKSANDRAS PRONKO AS IS AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING,
; BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
; DISCLAIMED. IN NO EVENT SHALL ALEKSANDRAS PRONKO BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
; EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
; LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING
; IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

	org 100h
start:
	jmp	InstallTSR

OLD_Int16:
	dd 0
TableNum:
	db 0
IntFunction:
	dw 0

	mov	[IntFunction], ax	;save call parameters
	cmp	ah, 0
	jnz	OldInt

	push	ax
	mov	ah, 2
	pushf
	call	dword [cs:OLD_Int16]	;call old int to get scroll lock state
	and	al, 10h
	pop	ax			;doesn't change the flags!
	jz	OldInt			;jump if scroll lock is not active
;	 pop	 ax

OldIntCall:
	pushf				;push flags because of iret from old int
	call	dword [cs:OLD_Int16]	;call old int
	cmp	al, 0
	jz	NoNumeric
	cmp	ah, 53h 		;is Del key pressed?
	jnz	NoScrollLock
	mov	al, [cs:TableNum]	;if yes - next table
	inc	al
	and	al, 3
	mov	[cs:TableNum], al
	mov	ax, [cs:IntFunction]
	jmp	OldIntCall

NoScrollLock:
	cmp	ah, 47h 		;is scancode within range of numerical keyboard codes?
	js	NoNumeric
	cmp	ah, 52h
	jns	NoNumeric

	push	bx			;yes
	push	ax
;	 xor	 bh, bh

	xor	ah, ah
	mov	bl, [cs:TableNum]	;which table used
	mov	al, 0Bh
	mul	bl
	mov	bx,ax
;	 xor	 ah, ah
;	 mov	 bx, ax
	pop	ax
;	 push	 ax
;	 sub	 ah, 47h
	add	bl, ah
	sub	bl, 47h
;	 xor	 bh, bh
;	 pop	 ax
	mov	al, [cs:FrameTable+bx]	;get frame from table value
	pop	bx

NoNumeric:
	iret

;OldIntSavedAX:
;	 pop	 ax

OldInt:
	jmp	dword [cs:OLD_Int16]

FrameTable:
	db 0DAh,0C2h,0BFh,0C4h,0C3h,0C5h,0B4h,0B3h,0C0h,0C1h,0D9h	;single
	db 0C9h,0CBh,0BBh,0CDh,0CCh,0CEh,0B9h,0BAh,0C8h,0CAh,0BCh	;double
	db 0D5h,0D1h,0B8h,0CDh,0C6h,0D8h,0B5h,0B3h,0D4h,0CFh,0BEh	;single vertical, double horizontal
	db 0D6h,0D2h,0B7h,0C4h,0C7h,0D7h,0B6h,0BAh,0D3h,0D0h,0BDh	;double vertical, single horizontal

InstallTSR:
	mov	dx, Message
	mov	ah, 9
	int	21h			;print message

	mov	ax, 3516h
	int	21h			;get int vector

	mov	[OLD_Int16], bx
	mov	[OLD_Int16+2], es

	mov	ax, 2516h
	mov	dx, 10Ah
	int	21h			;set int vector

;	 mov	 dx, 10 		 ;10 paragraphs for the TSR?
	mov	dx, InstallTSR
	mov	cl, 4
	shr	dx, cl
	inc	dx
	mov	ax, 3100h
	int	21h			;TSR

Message:
	db 'Numpad frames TSR driver (C) 1995(?) by Daemon_Magic',0Dh,0Ah
	db 'Use ScrollLock to turn on/off, numbers to graph frames and Del to toggle frame graphs.',0Dh,0Ah,'$'
