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
	.long 0x12345678		# VolumeSerialnumber
	.ascii "LOADER     "	# VolumeLabel
	.ascii "FAT12   "		# FileSystemType

TXT_BOOTBIN:
	.ascii "BOOT    BIN\0"

_main:
	cli
	mov $0xFFF0,%sp
	xor %ax,%ax
	mov %ax,%ds
	mov %ax,%ss

	xor %dl,%dl
	int $0x13
	jc errorexit
	# read FAT to 0x9000:0x0000
	mov $0x9000,%bx
	mov %bx,%es
	mov $0x01,%bx
	call fposcalc
	mov $0x0209,%ax
	xor %bx,%bx
	int $0x13
	jc errorexit_t
	# read root to 0x9000:0x1200
	mov $0x13,%bl
	call fposcalc
	mov $0x020E,%ax
	mov $0x1200,%bx
	int $0x13
	jc errorexit_t
	xor %dx,%dx
	mov %dx,%es
	lea TXT_BOOTBIN,%dx
	call searchfile
	test %ax,%ax
	jz errorexit
	jmp no_errorexit_t
errorexit_t:
	jmp errorexit
no_errorexit_t:
	mov %cx,%dx
	mov %bx,%cx
	mov $0x0500,%bx
	call getfiledata
	xor %ax,%ax
	push %ax
	push %bx
	mov %ax,%si
	mov %ax,%di
	mov %ax,%bp
	mov %ax,%es
	mov $outputnumber,%bx
	mov $searchfile,%cx
	mov $getfiledata,%dx
	retfw

# put error code on %ah then call
errorexit:
	mov %ah,%dl
	mov $0x0E65,%ax
	mov $0x0007,%bx
	int $0x10
	mov $0x72,%al
	int $0x10
	int $0x10
	mov $0x20,%al
	int $0x10
	xor %ch,%ch
	mov %dl,%cl
	call outputnumber
	mov $0x0D,%al
	int $0x10
	mov $0x0A,%al
	int $0x10
hltloop:
	hlt
	jmp hltloop

#put number to output on %cx then call this
outputnumber:
	push %ax
	push %cx
	push %dx
	push %bx
	mov $10,%bx
	push %bx
MAKEOUTPUTLOOP:
	mov %cx,%ax
	xor %dx,%dx
	div %bx
	push %dx
	mov %ax,%cx
	test %cx,%cx
	jnz MAKEOUTPUTLOOP
	mov $0x0E,%ah
	mov $0x0007,%bx
OUTPUTLOOP:
	pop %cx
	cmp $10,%cx
	je OWARIDAYO
	mov %cl,%al
	add $48,%al
	int $0x10
	jmp OUTPUTLOOP
OWARIDAYO:
	pop %bx
	pop %dx
	pop %cx
	pop %ax
	ret

# put sector ID(0-origin) to %bx, then call
# after return, set operation and address, then do int $0x13
fposcalc:
	push %si
	push %di
	push %ax
	mov %bx,%ax
	xor %dx,%dx
	mov $18,%cx
	div %cx
	inc %dx
	and $1,%ax
	shl $8,%ax
	mov %ax,%si
	mov %dx,%di
	mov %bx,%ax
	xor %dx,%dx
	mov $36,%cx
	div %cx
	mov %al,%ch
	mov %ah,%cl
	shl $6,%cl
	mov %di,%dx
	or %dl,%cl
	mov %si,%dx
	pop %ax
	pop %di
	pop %si
	ret

# search specified file from root
# input  %dx : address of file name to search
# return %ax : first sector of the file (0 if not found)
# return %bx : file size (lower 16-bits) (undefined if not found)
# return %cx : file size (higher 16-bits) (undefined if not found)
searchfile:
	push %si
	push %di
	push %es
	mov $0x9000,%cx
	mov %cx,%es
	mov $0xE0,%cx
	mov $0x1200,%bx
SEARCHLOOP:
	testb $0x08,%es:0xB(%bx)
	jnz SEARCHSKIP
	mov %dx,%si
	mov %bx,%di
	call filematch
	jz SEARCHFOUND
SEARCHSKIP:
	add $0x20,%bx
	loop SEARCHLOOP
	xor %ax,%ax
	jmp SEARCHEXIT
SEARCHFOUND:
	mov %es:0x1A(%bx),%ax
	mov %es:0x1E(%bx),%cx
	mov %es:0x1C(%bx),%bx
SEARCHEXIT:
	pop %es
	pop %di
	pop %si
	ret

# compare file name
# input %si : file name to search
# input %di : file name on disk (will accessed with "%es:")
# output    : ZF=1 if same, ZF=0 if differ
# breaks %si,%di
filematch:
	push %cx
	push %ax
	mov $11,%cx
	dec %si
	dec %di
COMPLOOP:
	inc %si
	inc %di
	mov (%si),%al
	cmp %es:(%di),%al
	jnz COMPEXIT
	loop COMPLOOP
COMPEXIT:
	pop %ax
	pop %cx
	ret

# get data from FAT
# input %dx  : the index to get data
# output %ax : cluster ID on the index
getfatdata:
	push %si
	push %di
	push %es
	mov $0x9000,%si
	mov %si,%es
	mov %dx,%si
	shr $1,%si
	mov %si,%di
	add %di,%si
	add %di,%si
	test $1,%dl
	jz GETFATEVEN
	mov %es:1(%si),%ax
	shr $4,%ax
	jmp GOTFATODD
GETFATEVEN:
	mov %es:(%si),%ax
	and $0xF,%ah
GOTFATODD:
	pop %es
	pop %di
	pop %si
	ret

errorexit_tmp:
	jmp errorexit

# get file data from disk
# input %ax : the first sector to read
# input %es:%bx : address to read data (note: if %bx is not a multiple of 0x200, it may be broken)
# input %cx : size to read (note: size written will be rounded up to a multiple of 0x200)
# input %dx : size to read (higher 16 bits)
getfiledata:
	test %cx,%cx
	jnz NO_NODATATOREAD
	test %dx,%dx
	jz NODATATOREAD
NO_NODATATOREAD:
	push %ax
	push %cx
	push %dx
	push %bx
	push %si
	push %es
	mov %dx,%si
	mov %ax,%dx
GETFILELOOP:
	mov %dx,%ax
	add $31,%ax # "2" on fat is sector 0x21 (0-origin)
	push %cx
	push %dx
	push %bx
	mov %ax,%bx
	call fposcalc
	mov $0x0201,%ax
	pop %bx
	int $0x13
	jc errorexit_tmp
	pop %dx
	pop %cx
	call getfatdata
	mov %ax,%dx
	add $0x2,%bh
	jnc ADDR_NOCARRY
	mov %es,%ax
	add $0x10,%ah
	mov %ax,%es
ADDR_NOCARRY:
	sub $0x200,%cx
	ja GETFILELOOP
	test %si,%si
	jz DATAREADEND
	dec %si
	jmp GETFILELOOP
DATAREADEND:
	pop %es
	pop %si
	pop %bx
	pop %dx
	pop %cx
	pop %ax
NODATATOREAD:
	ret
