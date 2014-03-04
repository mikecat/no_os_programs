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

# ルート情報を入れるアドレス。0x200バイト使用する。
.set ROOT_CACHE_ADDR,0x7E00
# FAT情報を入れるアドレス。0x400バイト使用する。
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

TXT_BOOTBIN:
	.ascii "BOOT    BIN\0"

_main:
	# 初期化
	cli
	mov $0xFFF0,%sp
	push %ax
	xor %ax,%ax
	mov %ax,%ds
	mov %ax,%es
	mov %ax,%ss
	# ファイルの検索
	mov $boot_file_name,%di
	call searchfile
	jnz _main_search_found
	# TODO: not found表示
	jmp error_exit
_main_search_found:
	# サイズチェック(大きすぎるか、0バイトだったら弾く)
	test %bx,%bx
	jnz _main_size_ng	# 上位16ビットが0でなかったらアウト
	test %ax,%ax
	jz _main_size_ng	# 下位16ビットが0だったらアウト
	cmp $0x7000,%ax
	jbe _main_size_ok	# 下位16ビットが0x7000以下ならセーフ
_main_size_ng:
	# TODO: invalid size表示
	jmp error_exit
_main_size_ok:
	# ファイルの読み込み
	mov %ax,%bp
	mov %cx,%ax
	movb SectorPerCluster,%dh
	mov $0x0500,%si
	# %bp 残りファイルサイズ
	# %ax 今のクラスタ
	# %dh 今のクラスタの残りセクタ数
	# %si 出力先アドレス
	call cluster2sector
_main_load_loop:
	# ロード処理
	call readdisk
	# セクタを進める
	add $0x200,%si
	inc %cx
	jnz _main_sector_no_carry
	inc %bx
_main_sector_no_carry:
	dec %dh
	jnz _main_no_new_cluster
	# 次のクラスタに行く
	call readfat12
	movb SectorPerCluster,%dh
	mov %ax,%cx
	call cluster2sector
_main_no_new_cluster:
	# 残りファイルサイズを減算する
	sub $0x200,%bp
	ja _main_load_loop
	# ジャンプする
	pop %ax
	xor %bx,%bx
	push %bx
	mov $0x05,%bh
	push %bx
	retfw

# input  なし
# output %cx ルートディレクトリ情報の位置を示すLBA
getrootdirpos:
	push %ax
	movw ReservedSectors,%cx
	movb TotalFATs,%al
getrootdirpos_loop:
	addw SectorsPerFAT,%cx
	dec %al
	jnz getrootdirpos_loop
	pop %ax
	ret

# input なし
# output %cx FAT情報の位置を示すLBA
getfatpos:
	movw ReservedSectors,%cx
	ret

# input  %cx     クラスタ番号
# output %bx:%cx そのクラスタのディスク上の先頭位置を示すLBA
cluster2sector:
	push %ax
	push %dx
	push %si
	movw MaxRootExtries,%ax
	shl $5,%ax
	add $0x1,%ah
	shr $9,%ax	# ルート情報のセクタ数
	mov %cx,%si
	dec %si
	dec %si
	call getrootdirpos
	add %ax,%cx	# データ領域の先頭セクタ
	xor %bh,%bh
	movb SectorPerCluster,%bl
	mov %si,%ax
	mul %bx
	mov %dx,%bx
	add %ax,%cx
	jnc cluster2sector_no_carry
	inc %bx		# 繰り上がり
cluster2sector_no_carry:
	pop %si
	pop %dx
	pop %ax
	ret

# input  %bx:%cx LBA
# input  %dl     ドライブ番号
# input  %si     出力先アドレス
readdisk:
	# LBAをint $0x13のパラメータに変換する
	push %ax
	push %bx
	push %cx
	push %dx
	push %dx
	mov %cx,%ax
	mov %bx,%dx
	divw SectorsPerTrack
	mov %dx,%cx
	inc %cx
	and $0x3F,%cl	# セクタ番号
	xor %dx,%dx
	divw NumHeads
	mov %dl,%dh		# ヘッド番号
	mov %al,%ch		# シリンダ番号(下位)
	shl $6,%ah
	or %ah,%cl		# シリンダ番号(上位)
	pop %ax
	mov %al,%dl		# %dlの値を復元
	# ディスクを読み込む
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
	# TODO: メッセージ表示
	jmp error_exit

# input  %di     探すファイル名(11文字での表現)へのポインタ
# input  %dl     ドライブ番号
# output %bx:%ax ファイルサイズ  (見つからない場合未定義)
# output %cx     先頭クラスタ番号(見つからない場合未定義)
# output ZF      見つかったら0、見つからなかったら1
searchfile:
	# ローカル変数
	# %ax ルート情報の残り数
	# %bh ファイル名比較用バッファ
	# %bl メモリ上のルート情報の残り数
	# %cx 今見ているルート情報のディスク上の位置(LBA)
	# %si 今見ている情報のメモリ上の位置
	# %bp ファイル名の比較位置
	push %si
	push %dx
	push %bp
	movw MaxRootExtries,%ax
	call getrootdirpos
	mov $1,%bl
searchfile_loop:
	dec %bl
	jnz searchfile_no_load
	# ルート情報を1セクタ読み込む
	push %bx
	xor %bx,%bx
	mov $ROOT_CACHE_ADDR,%si
	call readdisk
	pop %bx
	inc %cx
	mov $0x10,%bl
searchfile_no_load:
	# ファイル名を比較する
	xor %bp,%bp
searchfile_cmp_loop:
	movb (%bp,%si),%bh
	cmpb (%bp,%di),%bh
	jnz searchfile_cmp_loop_end
	inc %bp
	cmp $11,%bp
	jb searchfile_cmp_loop
	# 見つかった
	movw 0x1A(%si),%cx
	movw 0x1C(%si),%ax
	movw 0x1E(%si),%bx
	test %bp,%bp	# set ZF=0
	jmp searchfile_end
searchfile_cmp_loop_end:
	add $0x20,%si
	dec %ax
	jnz searchfile_loop
	# ZF=1
searchfile_end:
	pop %bp
	pop %dx
	pop %si
	ret

# input  %ax  クラスタ番号
# input  %dl  ドライブ番号
# output %ax  FATのクラスタ情報
readfat12:
	push %bx
	push %cx
	push %dx
	push %si
	mov %al,%dh		# %dhは何番目の情報かの下位8ビットを表す
	shr $1,%ax		# %axは何番目の「3バイトの塊」かを表す
	mov %ax,%bx
	shl $1,%bx
	add %ax,%bx
	mov %bx,%ax		# %axは「3バイトの塊」がFATの先頭から何バイト目から始まるかを表す
	and $0x1,%bh	# %bxは%axを0x200で割ったあまり(メモリ上のオフセット)
	shr $9,%ax		# %axは「FAT上で何番目のセクタか」を表す
	cmp fat_cache_number,%ax
	je readfat12_no_read_disk
	# ディスクからFATのデータをロードする
	movw %ax,fat_cache_number
	call getfatpos
	add %ax,%cx		# %cxに「ディスク上で何番目のセクタか」が入る
	push %bx		# スタックにメモリ上のオフセットが入る
	xor %bx,%bx
	mov $FAT_CACHE_ADDR,%si
	call readdisk
	inc %cx
	add $0x200,%si
	call readdisk
	pop %bx			# %bxにメモリ上のオフセットが入る
readfat12_no_read_disk:
	add $FAT_CACHE_ADDR,%bx
	# メモリ上のFATのデータを読み込む
	test $1,%dh
	jz readfat12_even
	# 奇数番目
	movb 1(%bx),%al
	shr $4,%al
	movb 2(%bx),%ah
	mov %ah,%bl
	shl $4,%bl
	or %bl,%al
	shr $4,%ah
	jmp readfat12_end
readfat12_even:
	# 偶数番目
	movb (%bx),%al
	movb 1(%bx),%ah
	and $0x0F,%ah
readfat12_end:
	pop %si
	pop %dx
	pop %cx
	pop %bx
	ret

error_exit:
	# TODO: メッセージを表示してキー入力待機
	int $0x18

boot_file_name:
	.ascii "BOOT    BIN"

.align 2
fat_cache_number:
	.short 0xFFFF
