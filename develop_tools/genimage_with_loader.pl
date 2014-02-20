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

if(@ARGV!=2) {
	die "Usage: generate_image_with_loader.pl <loader binary> <output image file>\n";
}

my $image_data;

# boot loader
open(IN,"< $ARGV[0]") or die("Loader binary open falied\n");
binmode(IN);
read(IN,$image_data,-s IN);
close(IN);

if(length($image_data)>=510) {
	$image_data=substr($image_data,0,510)
} else {
	$image_data.=("\x00"x(510-length($image_data)));
}
$image_data.="\x55\xAA";

# FAT
my $fat_data="\xF0\xFF\xFF".("\x00"x(0x1200-3));
$image_data.=$fat_data.$fat_data;

# root directory info
# label is "NO_TITLE"
my $volume_label=
	"\x4E\x4F\x5F\x54\x49\x54\x4C\x45\x20\x20\x20\x08\x00\x00\x76\xB1".
	"\xBD\x3A\xBD\x3A\x00\x00\x76\xB1\xBD\x3A\x00\x00\x00\x00\x00\x00";
my $root_data_blank="\x00"x(0x20*(0xE0-1));
$image_data.=$volume_label.$root_data_blank;

# storage
my $strage="\x00"x(0x163E00);
$image_data.=$strage;

# write the data to file
open(OUT,"> $ARGV[1]") or die("Output image file open error\n");
binmode(OUT);
print OUT $image_data;
close(OUT);
