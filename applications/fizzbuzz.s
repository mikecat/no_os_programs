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

.global _start
_start:
	cli
	# clear the display
	mov $0x0003,%ax
	int $0x10

	xor %cx,%cx
gotonextline:
	mov %cx,%ax
	mov $25,%bx
	xor %dx,%dx
	div %bx
	mov %dx,%si
	mov $15,%bx
	mul %bx
	mov %al,%dl
	mov %si,%bx
	mov %bl,%dh
	mov $0x02,%ah
	xor %bh,%bh
	int $0x10
fizzbuzzloop:
	inc %cx
	cmp $100,%cx
	ja hltloop
	mov $15,%bx
	mov %cx,%ax
	xor %dx,%dx
	div %bx
	test %dx,%dx
	jnz notfizzbuzz
	mov $0x0E46,%ax
	xor %bx,%bx
	int $0x10
	mov $'i',%al
	int $0x10
	mov $'z',%al
	int $0x10
	int $0x10
printbuzz:
	mov $0x0E42,%ax
	int $0x10
	mov $'u',%al
	int $0x10
	mov $'z',%al
	int $0x10
	int $0x10
	jmp gotonextline
notfizzbuzz:
	mov $3,%bx
	mov %cx,%ax
	xor %dx,%dx
	div %bx
	test %dx,%dx
	jnz notfizz
	mov $0x0E46,%ax
	xor %bx,%bx
	int $0x10
	mov $'i',%al
	int $0x10
	mov $'z',%al
	int $0x10
	int $0x10
	jmp gotonextline
notfizz:
	mov $5,%bx
	mov %cx,%ax
	xor %dx,%dx
	div %bx
	test %dx,%dx
	jz printbuzz
	# print the number
	mov %cx,%ax
	mov $10,%bl
	div %bl
	add $0x3030,%ax
	xor %bx,%bx
	mov %ax,%dx
	mov $0x0E,%ah
	cmp $0x30,%dl
	je onedigit
	mov %dl,%al
	int $0x10
onedigit:
	mov %dh,%al
	int $0x10
	jmp gotonextline

hltloop:
	hlt
	jmp hltloop
