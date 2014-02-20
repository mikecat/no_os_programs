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

if(@ARGV!=2 && @ARGV!=3) {
	die "Usage: asbl.pl <input> <output> [object file]\n";
}

if(@ARGV==2 && (-e "asbltemp.o")) {
	die "asbltemp.o exists. This script want to use and delete it. Stopped.\n";
}

my $objfile="";

if(@ARGV==2) {
	$objfile="asbltemp.o";
} else {
	$objfile=$ARGV[2];
}

my $org="";
if(open(IN,"< $ARGV[0]")) {
	while(my $line=<IN>) {
		$line =~ s/\.org ([0-9a-zA-Z]+)/$org=$1/e;
	}
	close(IN);
}

if(system("gcc -c -o $objfile \"$ARGV[0]\"")!=0) {
	exit $?;
}

my $addr="";
if($org ne "") {
	$addr="--start-address=$org";
}

if(open(IN,"objdump -s $addr $objfile |")) {
	my $content="";
	while(my $line=<IN>) {
		$line =~ s/^ [0-9a-zA-Z]+ (([0-9a-zA-Z]+ )+)/$content.=$1/e;
	}
	close(IN);
	$content =~ s/ //g;
	if(open(OUT,"> $ARGV[1]")) {
		binmode(OUT);
		print OUT pack("H*",$content);
		close(OUT);
	}
	my $bytes=int(length($content)/2);
	if($bytes>510) {
		warn sprintf("warning: out of memory for loader ($bytes bytes : +%dB)\n",$bytes-510);
	} else {
		warn "$bytes bytes written.\n";
	}
}
if(@ARGV==2) {
	unlink $objfile;
}
