.code16gcc

# Copyright 2014 MikeCAT.
#
# This software is provided "as is", without any express or implied warranties,
# including but not limited to the implied warranties of merchantability and
# fitness for a particular purpose.  In no event will the authors or contributors
# be held liable for any direct, indirect, incidental, special, exemplary, or
# consequential damages however caused and on any theory of liability, whether in
# contract, strict liability, or tort (including negligence or otherwise),
# arising in any way out of the use of this software, even if advised of the
# possibility of such damage.
#
# Permission is granted to anyone to use this software for any purpose, including
# commercial applications, and to alter and distribute it freely in any form,
# provided that the following conditions are met:
#
# 1. The origin of this software must not be misrepresented; you must not claim
#    that you wrote the original software. If you use this software in a product,
#    an acknowledgment in the product documentation would be appreciated but is
#    not required.
#
# 2. Altered source versions may not be misrepresented as being the original
#    software, and neither the name of MikeCAT nor the names of
#    authors or contributors may be used to endorse or promote products derived
#    from this software without specific prior written permission.
#
# 3. This notice must be included, unaltered, with any source distribution.

.macro call operand
	callw \operand
.endm

.macro ret
	retw
.endm

.org 0x0500

.global _start
_start:

	#init screen
	mov $0x0003,%ax
	int $0x10
	mov $0x02,%ah
	xor %bh,%bh
	xor %dx,%dx
	int $0x10
	# show title
	mov $TITLETEXT,%bp
	call PUT_STRING

PROGRAMMAIN:
	movb $0x0E,%ah
	movw $0x0007,%bx
	movb $'>',%al
	int $0x10
	movw $0,%cx # inputed number
	movw $1,%di # initial input flag
INPUTLOOP:
	movb $0,%ah
	int $0x16 # put keycode to %al
	cmpb $13,%al
	je JUDGEMAIN_RELAY
	cmpb $8,%al
	je DELETEINPUT
	cmpb $48,%al
	jb INPUTLOOP
	cmpb $58,%al
	jae INPUTLOOP
	# input number
	cmpw $0,%di # avoid double zero
	jne DOINPUT
	cmpw $0,%cx
	jne DOINPUT
	cmpb $48,%al
	je INPUTLOOP
DOINPUT:
	cmp $6554,%cx
	jae INPUTLOOP # avoid overflow
	and $0x00FF,%ax
	movw %ax,%si
	cmp $0,%cx # delete zero
	jne NODELETEZERO
	jmp NO_JUDGEMAIN_RELAY
JUDGEMAIN_RELAY:
	jmp JUDGEMAIN
NO_JUDGEMAIN_RELAY:
	cmp $0,%di
	jne NODELETEZERO
	movb $0x0E,%ah 
	movw $0x0007,%bx
	movb $8,%al
	int $0x10
NODELETEZERO:
	movw $10,%bx
	movw %cx,%ax
	mul %bx
	subw $48,%si
	addw %si,%ax
	jc INPUTLOOP # overflow -> ignore
	movw %ax,%cx
	movw %si,%ax
	movb $0x0E,%ah
	movw $0x0007,%bx
	addb $48,%al
	int $0x10
	movw $0,%di
	jmp INPUTLOOP
DELETEINPUT:
	cmpw $0,%di
	jne INPUTLOOP
	cmp $10,%cx
	jb DELETEATALL
	movw $10,%bx
	movw $0,%dx
	movw %cx,%ax
	div %bx
	movw %ax,%cx
	movb $0x0E,%ah
	movw $0x0007,%bx
	movb $8,%al
	int $0x10
	movb $32,%al
	int $0x10
	movb $8,%al
	int $0x10
	jmp INPUTLOOP
DELETEATALL:
	movb $0x0E,%ah
	movw $0x0007,%bx
	movb $8,%al
	int $0x10
	movb $32,%al
	int $0x10
	movb $8,%al
	int $0x10
	movw $1,%di
	movw $0,%cx
GOTO_INPUTLOOP:
	jmp INPUTLOOP
JUDGEMAIN:
	cmp $0,%di
	jne GOTO_INPUTLOOP
	movb $0x0E,%ah
	movw $0x0007,%bx
	movb $13,%al
	int $0x10
	movb $10,%al
	int $0x10
	cmp $0,%cx # when zero, shutdown
	je _poweroff_relay

	cmp $1,%cx
	je THISISNOTPRIME
	movw $2,%si
JUDGELOOP:
	cmp %cx,%si
	jae THISISPRIME
	movw $0,%dx
	movw %cx,%ax
	div %si
	cmp $0,%dx
	je THISISNOTPRIME
	incw %si
	jmp JUDGELOOP
THISISNOTPRIME:
	movb $0x0E,%ah
	movw $0x0007,%bx
	movb $'n',%al
	int $0x10
	movb $'o',%al
	int $0x10
	movb $'t',%al
	int $0x10
	movb $' ',%al
	int $0x10
THISISPRIME:
	movb $0x0E,%ah
	movw $0x0007,%bx
	movb $'p',%al
	int $0x10
	movb $'r',%al
	int $0x10
	movb $'i',%al
	int $0x10
	movb $'m',%al
	int $0x10
	movb $'e',%al
	int $0x10
	movb $13,%al
	int $0x10
	movb $10,%al
	int $0x10
	jmp PROGRAMMAIN

_poweroff_relay:
	jmp _poweroff

PROGRAMMAIN_RELAY:
	mov $EXITCANCELED,%bp
	call PUT_STRING
	jmp PROGRAMMAIN

#put number to output on %cx then call this
# this will break %ax,%bx,%cx,%dx
outputnumber:
	pushw $10
MAKEOUTPUTLOOP:
	movw %cx,%ax
	movw $0,%dx
	movw $10,%bx
	divw %bx
	pushw %dx
	movw %ax,%cx
	cmpw $0,%cx
	ja MAKEOUTPUTLOOP
	movb $0x0E,%ah
	movw $0x0007,%bx
OUTPUTLOOP:
	popw %cx
	cmp $10,%cx
	je OWARIDAYO
	movb %cl,%al
	addb $48,%al
	int $0x10
	jmp OUTPUTLOOP
OWARIDAYO:
	movb $32,%al
	int $0x10
	ret

# shutdown the computer
_poweroff:
	mov $EXITCHECK,%bp
	call PUT_STRING

	xor %ah,%ah
	int $0x16
	cmp $'y',%al
	jne PROGRAMMAIN_RELAY

	movw $0x5300,%ax
	xorw %bx,%bx
	int $0x15
	jc OFF_ERROR
	cmp $0x0101,%ax
	jb OFF_UNSURPORTED
	push %ax
	movw $0x5301,%ax
	xorw %bx,%bx
	int $0x15
	pop %cx
	jnc OFF_NO_ERROR
	cmp $2,%ah
	jne OFF_ERROR
OFF_NO_ERROR:
	movw $0x530E,%ax
	xorw %bx,%bx
	int $0x15
	jc OFF_ERROR
	movw $0x530D,%ax
	movw $0x0001,%bx
	movw $0x0001,%cx
	int $0x15
#	jc OFF_ERROR
	movw $0x530F,%ax
	movw $0x0001,%bx
	movw $0x0001,%cx
	int $0x15
#	jc OFF_ERROR
	movw $0x5307,%ax
	movw $0x0001,%bx
	movw $0x0003,%cx
	int $0x15
OFF_ERROR:
	mov $EXITERROR,%bp
	call PUT_STRING
	jmp PROGRAMMAIN
OFF_UNSURPORTED:
	mov $EXITUNSURPORTED,%bp
	call PUT_STRING
	jmp PROGRAMMAIN

# print NIL-terminated string which begins from %bp
PUT_STRING:
	push %ax
	push %bx
	push %si
	mov $0x0E,%ah
	xor %bx,%bx
	xor %si,%si
PUT_STRING_LOOP:
	mov (%bp,%si),%al
	test %al,%al
	jnz PUT_STRING_NORET
	pop %si
	pop %bx
	pop %ax
	ret
PUT_STRING_NORET:
	int $0x10
	inc %si
	jmp PUT_STRING_LOOP

# title text
TITLETEXT:
	.ascii "Welcome to Prime Judge!\r\n"
	.ascii "Input positive integer (<=65535) to test primality.\r\n"
	.ascii "Input 0 to exit.\r\n\0"

# confirm exit
EXITCHECK:
	.ascii "Are you sure you want to exit?(y/n)\r\n\0"

# exit cancelled
EXITCANCELED:
	.ascii "Have fun!\r\n\0"

# exit error
EXITERROR:
	.ascii "Shutdown failed! Sorry!\r\n\0"

# exit unsurported
EXITUNSURPORTED:
	.ascii "Shutdown unsurported version! Sorry!\r\n\0"
