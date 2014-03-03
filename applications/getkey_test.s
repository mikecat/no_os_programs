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
	xor %ah,%ah
	int $0x16
	mov %ax,%dx

	# 値を表示
	mov $0x0E,%ah
	xor %bx,%bx
	mov %dh,%al
	shr $4,%al
	call disphex
	mov %dh,%al
	call disphex
	mov $0x20,%al
	int $0x10
	mov %dl,%al
	shr $4,%al
	call disphex
	mov %dl,%al
	call disphex
	mov $0x20,%al
	int $0x10
	mov %dl,%al
	int $0x10
	# 改行を表示
	mov $0x0D,%al
	int $0x10
	mov $0x0A,%al
	int $0x10

	jmp _start

# 16進数を1桁表示する
disphex:
	and $0x0F,%al
	cmp $10,%al
	jb disphex_below_ten
	add $7,%al
disphex_below_ten:
	add $0x30,%al
	int $0x10
	ret
