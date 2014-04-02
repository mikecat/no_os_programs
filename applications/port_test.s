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
	# �V���A���|�[�g������
	mov $0x0003,%ax
	xor %dx,%dx
	int $0x14
	call dispinfo
	# �V���A���|�[�g1�������M
	mov $0x0130,%ax
	xor %dx,%dx
	int $0x14
	call dispinfo
	# �V���A���|�[�g1������M
	mov $0x02,%ah
	xor %dx,%dx
	int $0x14
	call dispinfo
	# �V���A���|�[�g�X�e�[�^�X�ǂݍ���
	mov $0x03,%ah
	xor %dx,%dx
	int $0x14
	call dispinfo
	# ���s
	mov $0x0D,%cl
	call putchar
	mov $0x0A,%cl
	call putchar
	# �p�������|�[�g������
	mov $0x01,%ah
	xor %dx,%dx
	int $0x17
	call dispinfo
	# �p�������|�[�g������������
	mov $0x0030,%ax
	xor %dx,%dx
	int $0x17
	call dispinfo
	# �p�������|�[�g�X�e�[�^�X�擾
	mov $0x03,%ah
	xor %dx,%dx
	int $0x17
	call dispinfo
hltloop:
	hlt
	jmp hltloop

# CF��%ax�̏���\������
dispinfo:
	mov $'0',%cl
	jnc dispinfo_nocarry
	inc %cl
dispinfo_nocarry:
	call putchar
	mov $' ',%cl
	call putchar
	mov %ax,%cx
	call dispreg
	mov $0x0D,%cl
	call putchar
	mov $0x0A,%cl
	call putchar
	ret

# %cl�̕�����\������
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

# %cx�̒l��\������
dispreg:
	push %ax
	push %bx
	mov $0x0E,%ah
	xor %bx,%bx
	# �l��\��
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

# 16�i����1���\������(dispreg�̕⏕)
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
