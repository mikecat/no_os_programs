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
	mov $0x0000,%dx
	mov $0xBEEF,%ax
	mov $0x0010,%bx
	call div_test
	mov $0xDEAD,%dx
	mov $0xBEEF,%ax
	mov $0xBEEF,%bx
	call div_test
	mov $0x0000,%dx
	mov $0xFFFF,%ax
	mov $0x0001,%bx
	call div_test
	mov $0x0001,%dx
	mov $0x0000,%ax
	mov $0x0002,%bx
	call div_test
	mov $0x0001,%dx
	mov $0x0000,%ax
	mov $0x0001,%bx
	call div_test
	mov $0x0000,%dx
	mov $0xBEEF,%ax
	mov $0x0000,%bx
	call div_test
	mov $0xDEAD,%dx
	mov $0xBEEF,%ax
	mov $0x00AC,%bx
	call div_test
hltloop:
	hlt
	jmp hltloop

div_test:
	# 内容を表示
	mov %dx,%cx
	call dispreg
	mov $':',%cl
	call putchar
	mov %ax,%cx
	call dispreg
	mov $' ',%cl
	call putchar
	mov $'/',%cl
	call putchar
	mov $' ',%cl
	call putchar
	mov %bx,%cx
	call dispreg
	# キー入力を読み込み、0なら実行しない
	mov %ax,%cx
	xor %ah,%ah
	int $0x16
	cmp $'0',%al
	je div_test_skip
	# 割り算を行い、結果を表示
	mov %cx,%ax
	mov $' ',%cl
	call putchar
	mov $'=',%cl
	call putchar
	mov $' ',%cl
	call putchar
	div %bx
	
	mov %ax,%cx
	call dispreg
	mov $' ',%cl
	call putchar
	mov $'.',%cl
	call putchar
	call putchar
	call putchar
	mov $' ',%cl
	call putchar
	mov %dx,%cx
	call dispreg
div_test_skip:
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

# %cxの値を表示する
dispreg:
	push %ax
	push %bx
	mov $0x0E,%ah
	xor %bx,%bx
	# 値を表示
	mov %ch,%al
	shr $4,%al
	call disphex_one
	mov %ch,%al
	call disphex_one
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
