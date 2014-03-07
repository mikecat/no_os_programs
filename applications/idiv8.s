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
	cli
	mov $0x007F,%ax
	mov $0x01,%bl
	call idiv_test
	mov $0x00FF,%ax
	mov $0x01,%bl
	call idiv_test
	mov $0x00FF,%ax
	mov $0x02,%bl
	call idiv_test
	mov $0xFFFD,%ax
	mov $0x02,%bl
	call idiv_test
	mov $0xFFFD,%ax
	mov $0xFE,%bl
	call idiv_test
	mov $0x7FFF,%ax
	mov $0x7F,%bl
	call idiv_test
	mov $0x0100,%ax
	mov $0x02,%bl
	call idiv_test
	mov $0x0100,%ax
	mov $0x03,%bl
	call idiv_test
hltloop:
	hlt
	jmp hltloop

idiv_test:
	# 内容を表示
	mov %ah,%cl
	call dispreg
	mov %al,%cl
	call dispreg
	mov $' ',%cl
	call putchar
	mov $'/',%cl
	call putchar
	mov $' ',%cl
	call putchar
	mov %bl,%cl
	call dispreg
	# キー入力を読み込み、0なら実行しない
	mov %ax,%cx
	xor %ah,%ah
	int $0x16
	cmp $'0',%al
	je idiv_test_skip
	# 割り算を行い、結果を表示
	mov %cx,%ax
	mov $' ',%cl
	call putchar
	mov $'=',%cl
	call putchar
	mov $' ',%cl
	call putchar
	idiv %bl
	
	mov %al,%cl
	call dispreg
	mov $' ',%cl
	call putchar
	mov $'.',%cl
	call putchar
	call putchar
	call putchar
	mov $' ',%cl
	call putchar
	mov %ah,%cl
	call dispreg
idiv_test_skip:
	mov $0x0D,%cl
	call putchar
	mov $0x0A,%cl
	call putchar
	ret

# %clの文字を表示する
putchar:
	push %ax
	push %bx
	mov $0x0E,%ah
	xor %bx,%bx
	mov %cl,%al
	int $0x10
	pop %bx
	pop %ax
	ret

# %clの値を表示する
dispreg:
	push %ax
	push %bx
	mov $0x0E,%ah
	xor %bx,%bx
	# 値を表示
	mov %cl,%al
	shr $4,%al
	call disphex_one
	mov %cl,%al
	call disphex_one
	pop %bx
	pop %ax
	ret

# 16進数を1桁表示する(dispregの補助)
disphex_one:
	and $0x0F,%al
	cmp $10,%al
	jb disphex_one_below_ten
	add $7,%al
disphex_one_below_ten:
	add $0x30,%al
disphex_one_disp:
	int $0x10
	ret
