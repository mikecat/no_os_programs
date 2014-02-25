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

.org 0x7C00

.global _start
_start:
	jmp _main
	nop

	.ascii "mkdosfs\0"
	.word 0x0200			# BytesPerSector
	.byte 0x01				# SectorPerCluster
	.word 0x0001			# ReservedSectors
	.byte 0x02				# TotalFATs
	.word 0x00E0			# MaxRootExtries
	.word 0x0B40			# TotalSectors
	.byte 0xF0				# MediaDescriptor
	.word 0x0009			# SectorsPerFAT
	.word 0x0012			# SectorsPerTrack
	.word 0x0002			# NumHeads
	.long 0x00000000		# HiddenSector
	.long 0x00000000		# TotalSectors

	.byte 0x00				# DriveNumber
	.byte 0x00				# Reserved
	.byte 0x29				# BootSignature
	.long 0xEFBEADDE		# VolumeSerialnumber
	.ascii "LOADER     "	# VolumeLabel
	.ascii "FAT12   "		# FileSystemType

_main:
	cli
	# とりあえずレジスタのデータをメモリに入れる
	mov %ax,axbuf
	mov %bx,bxbuf
	mov %cx,cxbuf
	mov %dx,dxbuf
	mov %si,sibuf
	mov %di,dibuf
	mov %bp,bpbuf
	mov %sp,spbuf
	mov %cs,csbuf
	mov %ss,ssbuf
	mov %ds,dsbuf
	mov %es,esbuf
	# スタックを初期化
	xor %ax,%ax
	mov %ax,%ss
	mov $0xFFF0,%sp
	# 順に表示していく
	mov $0x7861,%cx
	mov axbuf,%dx
	call dispreg
	mov $0x7862,%cx
	mov bxbuf,%dx
	call dispreg
	mov $0x7863,%cx
	mov cxbuf,%dx
	call dispreg
	mov $0x7864,%cx
	mov dxbuf,%dx
	call dispreg
	mov $0x6973,%cx
	mov sibuf,%dx
	call dispreg
	mov $0x6964,%cx
	mov dibuf,%dx
	call dispreg
	mov $0x7062,%cx
	mov bpbuf,%dx
	call dispreg
	mov $0x7073,%cx
	mov spbuf,%dx
	call dispreg
	mov $0x7363,%cx
	mov csbuf,%dx
	call dispreg
	mov $0x7373,%cx
	mov ssbuf,%dx
	call dispreg
	mov $0x7364,%cx
	mov dsbuf,%dx
	call dispreg
	mov $0x7365,%cx
	mov esbuf,%dx
	call dispreg
hltloop:
	hlt
	jmp hltloop

# "%ax : 0000"のような形式で表示する
# %cxにレジスタ名を、%dxにレジスタの値を置く
dispreg:
	# レジスタ名を表示
	mov $0x0E25,%ax
	xor %bx,%bx
	int $0x10
	mov %cl,%al
	int $0x10
	mov %ch,%al
	int $0x10
	mov $0x20,%al
	int $0x10
	mov $0x3A,%al
	int $0x10
	mov $0x20,%al
	int $0x10
	# 値を表示
	mov %dh,%al
	shr $4,%al
	call disphex
	mov %dh,%al
	call disphex
	mov %dl,%al
	shr $4,%al
	call disphex
	mov %dl,%al
	call disphex
	# 改行を表示
	mov $0x0D,%al
	int $0x10
	mov $0x0A,%al
	int $0x10
	ret

# 16進数を1桁表示する(dispregの補助)
disphex:
	and $0x0F,%al
	cmp $10,%al
	jb disphex_below_ten
	add $7,%al
disphex_below_ten:
	add $0x30,%al
disphex_disp:
	int $0x10
	ret

.align 2
axbuf:
	.word 0xADDE
bxbuf:
	.word 0xADDE
cxbuf:
	.word 0xADDE
dxbuf:
	.word 0xADDE
sibuf:
	.word 0xADDE
dibuf:
	.word 0xADDE
bpbuf:
	.word 0xADDE
spbuf:
	.word 0xADDE
csbuf:
	.word 0xADDE
ssbuf:
	.word 0xADDE
dsbuf:
	.word 0xADDE
esbuf:
	.word 0xADDE
