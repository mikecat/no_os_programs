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

# ���[�g��������A�h���X�B0x200�o�C�g�g�p����B
.set ROOT_CACHE_ADDR,0x7E00
# FAT��������A�h���X�B0x400�o�C�g�g�p����B
.set FAT_CACHE_ADDR,0x7800

.org 0x7C00

.global _start
_start:
	jmp _main
	nop

	.ascii "mkdosfs\0"
BytesPerSector:
	.word 0x0200
SectorPerCluster:
	.byte 0x01
ReservedSectors:
	.word 0x0001
TotalFATs:
	.byte 0x02
MaxRootExtries:
	.word 0x00E0
TotalSectors:
	.word 0x0B40
MediaDescriptor:
	.byte 0xF0
SectorsPerFAT:
	.word 0x0009
SectorsPerTrack:
	.word 0x0012
NumHeads:
	.word 0x0002
HiddenSector:
	.long 0x00000000
TotalSectorsBig:
	.long 0x00000000

DriveNumber:
	.byte 0x00
Reserved:
	.byte 0x00
BootSignature:
	.byte 0x29
VolumeSerialnumber:
	.long 0xEFBEADDE
VolumeLabel:
	.ascii "LOADER     "
FileSystemType:
	.ascii "FAT12   "

.set HiddenSectorHigh,HiddenSector+2

_main:
	# ������
	cli
	mov $0xFFF0,%sp
	push %ax
	xor %ax,%ax
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%ss
	# �t�@�C���̌���
	mov $boot_file_name,%di

# searchfile
# breaks %si,%bp
# input  %di     �T���t�@�C����(11�����ł̕\��)�ւ̃|�C���^
# input  %dl     �h���C�u�ԍ�
# output %bx:%ax �t�@�C���T�C�Y  (������Ȃ��ꍇ����`)
# output %cx     �擪�N���X�^�ԍ�(������Ȃ��ꍇ����`)
	# ���[�J���ϐ�
	# %ax ���[�g���̎c�萔
	# %bh �t�@�C������r�p�o�b�t�@
	# %bl ��������̃��[�g���̎c�萔
	# %cx �����Ă��郋�[�g���̃f�B�X�N��̈ʒu(LBA)
	# %si �����Ă�����̃�������̈ʒu
	# %bp �t�@�C�����̔�r�ʒu
	call getrootdirpos
	movw MaxRootExtries,%ax
	mov $1,%bl
searchfile_loop:
	dec %bl
	jnz searchfile_no_load
	# ���[�g����1�Z�N�^�ǂݍ���
	push %bx
	xor %bx,%bx
	mov $ROOT_CACHE_ADDR,%si
	call readdisk
	pop %bx
	inc %cx
	mov $0x10,%bl
searchfile_no_load:
	# �t�@�C�������r����
	xor %bp,%bp
searchfile_cmp_loop:
	movb (%bp,%si),%bh
	cmpb (%bp,%di),%bh
	jnz searchfile_cmp_loop_end
	inc %bp
	cmp $11,%bp
	jb searchfile_cmp_loop
	# ��������
	movw 0x1A(%si),%cx
	movw 0x1C(%si),%ax
	movw 0x1E(%si),%bx
	jmp _main_search_found	# ���ڎ��̏�����
searchfile_cmp_loop_end:
	add $0x20,%si
	dec %ax
	jnz searchfile_loop
	# ������Ȃ�����

	mov $not_found,%si
	call puts
	jmp error_exit
_main_search_found:
	# �T�C�Y�`�F�b�N(�傫�����邩�A0�o�C�g��������e��)
	test %bx,%bx
	jnz _main_size_ng	# ���16�r�b�g��0�łȂ�������A�E�g
	test %ax,%ax
	jz _main_size_ng	# ����16�r�b�g��0��������A�E�g
	cmp $0x7000,%ax
	jbe _main_size_ok	# ����16�r�b�g��0x7000�ȉ��Ȃ�Z�[�t
_main_size_ng:
	mov $invalid_size,%si
	call puts
	jmp error_exit
_main_size_ok:
	# �t�@�C���̓ǂݍ���
	mov %ax,%bp
	mov %cx,%ax
	movb SectorPerCluster,%dh
	mov $0x0500,%si
	# %bp �c��t�@�C���T�C�Y
	# %ax ���̃N���X�^
	# %dh ���̃N���X�^�̎c��Z�N�^��
	# %si �o�͐�A�h���X
	call cluster2sector
_main_load_loop:
	# ���[�h����
	call readdisk
	# �Z�N�^��i�߂�
	add $0x200,%si
	inc %cx
	jnz _main_sector_no_carry
	inc %bx
_main_sector_no_carry:
	dec %dh
	jnz _main_no_new_cluster
	# ���̃N���X�^�ɍs��

# readfat12
# breaks %cx,%dh
# input  %ax  �N���X�^�ԍ�
# input  %dl  �h���C�u�ԍ�
# output %ax  FAT�̃N���X�^���
	push %bx
	push %si
	mov %al,%dh		# %dh�͉��Ԗڂ̏�񂩂̉���8�r�b�g��\��
	shr $1,%ax		# %ax�͉��Ԗڂ́u3�o�C�g�̉�v����\��
	mov %ax,%bx
	shl $1,%bx
	add %ax,%bx
	mov %bx,%ax		# %ax�́u3�o�C�g�̉�v��FAT�̐擪���牽�o�C�g�ڂ���n�܂邩��\��
	and $0x1,%bh	# %bx��%ax��0x200�Ŋ��������܂�(��������̃I�t�Z�b�g)
	shr $9,%ax		# %ax�́uFAT��ŉ��Ԗڂ̃Z�N�^���v��\��
	cmp fat_cache_number,%ax
	je readfat12_no_read_disk
	# �f�B�X�N����FAT�̃f�[�^�����[�h����
	movw %ax,fat_cache_number
	movw ReservedSectors,%cx	# %cx��FAT�̊J�n�ʒu�̃Z�N�^������
	add %ax,%cx		# %cx�Ɂu�f�B�X�N��ŉ��Ԗڂ̃Z�N�^���v������
	push %bx		# �X�^�b�N�Ƀ�������̃I�t�Z�b�g������
	xor %bx,%bx
	mov $FAT_CACHE_ADDR,%si
	call readdisk
	inc %cx
	add $0x200,%si
	call readdisk
	pop %bx			# %bx�Ƀ�������̃I�t�Z�b�g������
readfat12_no_read_disk:
	add $FAT_CACHE_ADDR,%bx
	# ���������FAT�̃f�[�^��ǂݍ���
	test $1,%dh
	jz readfat12_even
	# ��Ԗ�
	movb 1(%bx),%al
	movb 2(%bx),%ah
	shr $4,%ax
	jmp readfat12_end
readfat12_even:
	# �����Ԗ�
	movb (%bx),%al
	movb 1(%bx),%ah
	and $0x0F,%ah
readfat12_end:
	pop %si
	pop %bx

	movb SectorPerCluster,%dh
	mov %ax,%cx
	call cluster2sector
_main_no_new_cluster:
	# �c��t�@�C���T�C�Y�����Z����
	sub $0x200,%bp
	ja _main_load_loop
	# �W�����v����
	pop %ax
	xor %bx,%bx
	push %bx
	mov $0x05,%bh
	push %bx
	retfw

# breaks %ax
# input  �Ȃ�
# output %cx ���[�g�f�B���N�g�����̈ʒu������LBA
getrootdirpos:
	movw ReservedSectors,%cx
	movb TotalFATs,%al
getrootdirpos_loop:
	addw SectorsPerFAT,%cx
	dec %al
	jnz getrootdirpos_loop
	ret

# input  %cx     �N���X�^�ԍ�
# output %bx:%cx ���̃N���X�^�̃f�B�X�N��̐擪�ʒu������LBA
cluster2sector:
	push %ax
	push %dx
	mov %cx,%bx
	dec %bx
	dec %bx
	call getrootdirpos
	movw MaxRootExtries,%ax
	shl $5,%ax
	add $0x1,%ah
	shr $9,%ax	# ���[�g���̃Z�N�^��
	add %ax,%cx	# �f�[�^�̈�̐擪�Z�N�^
	mov %bx,%ax
	xor %bh,%bh
	movb SectorPerCluster,%bl
	mul %bx
	mov %dx,%bx
	add %ax,%cx
	jnc cluster2sector_no_carry
	inc %bx		# �J��オ��
cluster2sector_no_carry:
	pop %dx
	pop %ax
	ret

# input  %bx:%cx LBA
# input  %dl     �h���C�u�ԍ�
# input  %si     �o�͐�A�h���X
readdisk:
	push %ax
	push %bx
	push %cx
	push %dx
	# LBA��HiddenSector�̒l�𑫂�
	addw HiddenSector,%cx
	adcw HiddenSectorHigh,%bx
	# LBA��int $0x13�̃p�����[�^�ɕϊ�����
	mov %cx,%ax
	xchg %bx,%dx
	divw SectorsPerTrack
	mov %dx,%cx
	inc %cx
	and $0x3F,%cl	# �Z�N�^�ԍ�
	xor %dx,%dx
	divw NumHeads
	mov %dl,%dh		# �w�b�h�ԍ�
	mov %al,%ch		# �V�����_�ԍ�(����)
	shl $6,%ah
	or %ah,%cl		# �V�����_�ԍ�(���)
	mov %bl,%dl		# %dl�̒l�𕜌�
	# �f�B�X�N��ǂݍ���
	mov $0x0201,%ax
	mov %si,%bx
	int $0x13
	jc readdisk_error
	pop %dx
	pop %cx
	pop %bx
	pop %ax
	ret
readdisk_error:
	# �G���[�R�[�h���쐬
	mov %ah,%dh
	shr $4,%dx
	shr $4,%dl
	add $0x4141,%dx
	# �G���[���b�Z�[�W��\��
	mov $read_error,%si
	call puts
	# �G���[�R�[�h��\��
	mov %dh,%al
	int $0x10
	mov %dl,%al
	int $0x10
	jmp error_exit

error_exit:
	# ���s����
	mov $0x0E0D,%ax
	xor %bx,%bx
	int $0x10
	mov $0x0A,%al
	int $0x10
	# �L�[���͑ҋ@
error_exit_waitkey_loop:
	# ���������邩�`�F�b�N
	mov $0x01,%ah
	int $0x16
	# �����ǂݏo��
	xor %ah,%ah
	int $0x16
	# �ŏ��̃`�F�b�N�Łu�������Ȃ��v����ZF=1�ɂȂ�A�ʉ߂���
	jnz error_exit_waitkey_loop
	# �u�[�g���s��ʒm
	int $0x18

# breaks %ax,%bx
# input  %si �o�͂��郁�b�Z�[�W�ւ̃|�C���^
# output     �Ȃ�
# NIL�ŏI��郁�b�Z�[�W���o�͂���B(�����ŉ��s�͂���Ȃ�)
puts:
	mov $0x0E,%ah
	xor %bx,%bx
puts_loop:
	movb (%si),%al
	test %al,%al
	jz puts_end
	int $0x10
	inc %si
	jmp puts_loop
puts_end:
	ret

boot_file_name:
	.ascii "BOOT    BIN"

not_found:
	.string "404"

invalid_size:
	.string "413"

read_error:
	.string "500 "

.align 2
fat_cache_number:
	.short 0xFFFF
