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
	die "Usage: update_loader.pl <loader binary> <image file>\n";
}

my $loader_data;
my $image_data;

# boot loader
open(IN,"< $ARGV[0]") or die("Loader binary open failed\n");
binmode(IN);
read(IN,$loader_data,-s IN);
close(IN);

if(length($loader_data)>=510) {
	$loader_data=substr($loader_data,0,510)
} else {
	$loader_data.=("\x00"x(510-length($loader_data)));
}
$loader_data.="\x55\xAA";

# disk image
open(IN,"< $ARGV[1]") or die("Image file open failed\n");
binmode(IN);
read(IN,$image_data,-s IN);
close(IN);

open(OUT,"> $ARGV[1]") or die("Image file open (to write) failed\n");
binmode(OUT);
print OUT $loader_data;
print OUT substr($image_data,512);
close(OUT);
