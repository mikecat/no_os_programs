#!/usr/bin/perl

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

use strict;

if(@ARGV<2 && 4<@ARGV) {
	die(
		"Usage: update_loader2_hdd.pl <loader file> <image file> [partition] [mask size]\n".
		"\npartition: 1-4 (default is 1)\n"
	);
}

my $partition=1;
if(@ARGV>=3) {
	$partition=int($ARGV[2]);
	if($partition<1 || 4<$partition) {
		die("Invalid partition number\n");
	}
}

my $mask_size=0x3D;
if(@ARGV>=4) {
	$mask_size=int($ARGV[3]);
	if($mask_size>0x200) {
		$mask_size=0x200;
	}
}

my $loader_data="";
open(IN,"< $ARGV[0]") or die("Loader file open error\n");
binmode(IN);
read(IN,$loader_data,-s IN);
close(IN);

if(length($loader_data)>=510) {
	$loader_data=substr($loader_data,0,510)
} else {
	$loader_data.=("\x00"x(510-length($loader_data)));
}
$loader_data.="\x55\xAA";

open(IMG,"+< $ARGV[1]") or die("Image file open error\n");
# パーティション情報を読み込み、目的のパーティションに移動する
my $mbr="";
unless(defined(sysread(IMG,$mbr,0x200))) {
	close(IMG);
	die("MBR read error\n");
}
my $mbr_sector_pos=0x1C6+0x10*($partition-1);
if(substr($mbr,$mbr_sector_pos+4,4) eq "\x00\x00\x00\x00") {
	close(IMG);
	die("Specified partition is blank\n");
}
my @sector_raw=unpack("C4",substr($mbr,$mbr_sector_pos,4));
my $sector_high=$sector_raw[2]|($sector_raw[3]<<8);
my $sector_low=$sector_raw[0]|($sector_raw[1]<<8);
seek(IMG,0,0);
for(my $i=0;$i<$sector_high;$i++) {
	seek(IMG,0x200*0x10000,1);
}
seek(IMG,0x200*$sector_low,1);

if($mask_size>3) {
	# マスク対象のデータ(ファイルシステム情報を想定)を読み込む
	my $masked_data="";
	seek(IMG,3,1);
	unless(defined(sysread(IMG,$masked_data,$mask_size-3))) {
		close(IMG);
		die("Mask data read error\n");
	}
	substr($loader_data,3,$mask_size-3)=$masked_data;
	seek(IMG,-$mask_size,1);
}
unless(defined(syswrite(IMG,$loader_data,0x200))) {
	close(IMG);
	die("Data write error\n");
}
close(IMG);
