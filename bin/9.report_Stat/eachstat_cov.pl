#!/usr/bin/perl -w
use strict;
use FindBin qw($Bin);

die "perl $0 <bam> <out> <samtools>" unless @ARGV >= 2;

my ($total_read, $maq10, $maq20, $maq30, $maq, $mismatch, $mismatch_rate);
my $samtools = (@ARGV == 3) ? $ARGV[2] : "$Bin/samtools";
my $length;

open BAM," $samtools view $ARGV[0] |";
while(<BAM>){
	chomp;
	next if /^@/;
	my @info = split /\t/;
	$length = length($info[9]);
	$total_read++;
	if($info[4] >= 10){
		$maq10++;
		if($info[4] >= 20){
			$maq20++;
			if($info[4] >= 30){
				$maq30++;
			}
		}
	}
	$maq += $info[4];
	if(/NM:i:(\d+)/){$mismatch += $1;}
}
close BAM;

$mismatch_rate = int($mismatch / ($length * $total_read) * 10000 + 0.5) / 100;
$maq = int($maq / $total_read * 100 + 0.5) / 100;
$maq10 = int($maq10 / $total_read * 10000 + 0.5) / 100;
$maq20 = int($maq20 / $total_read * 10000 + 0.5) / 100;
$maq30 = int($maq30 / $total_read * 10000 + 0.5) / 100;
open OT,">$ARGV[1]";
print OT "Readlength\t$length\nCleanRead\t$total_read\nMismatch bases(bp)\t$mismatch\nMismatch rate\t$mismatch_rate%\nMean MAQ\t$maq\nMAQ10\t$maq10%\nMAQ20\t$maq20%\nMAQ30\t$maq30%\n";
close OT;

