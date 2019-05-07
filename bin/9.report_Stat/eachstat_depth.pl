#!/usr/bin/perl
use warnings;
use strict;
use Getopt::Long;
use FindBin qw($Bin);

=pod

=head1 Usage
	perl $0 [option] <bam> <outdir>
		-q	base quality
		-Q	mapping quality
		-l	genome size default:2897310462
		-hg	hg19 or hg18 or other default:hg19
    -bd bam2depth software
    -n  non N region
		-h	help

hg19:2897310462 hg18:2885270602 mm9:2725765481 mm10:2730871774
=cut
		

my ($basethres,$mapQthres,$total_chr,$help,$hg,$bam2depth,$non);
GetOptions("q:i"=>\$basethres,"Q:i"=>\$mapQthres,"l:i"=>\$total_chr,"hg:s"=>\$hg,"h"=>\$help, "bd:s" => \$bam2depth,"n:s"=>\$non);

$hg ||= "hg19";
$total_chr ||= 2897310462;
$basethres ||= 0;
$mapQthres ||= 0;
die `pod2text $0` if(@ARGV<2 || $help);

my $bam=shift;
my $outdir=shift;

mkdir $outdir unless -d $outdir;

if($hg =~ /hg19/i){
	open DEPTH,"$bam2depth -q $basethres -Q $mapQthres $bam -b $non | " or die;
}
elsif($hg =~ /hs37d5/i){
  open DEPTH,"$bam2depth -q $basethres -Q $mapQthres $bam -b $non | " or die;
  $total_chr = 2900340137;
}
else
{
	open DEPTH,"$bam2depth -q $basethres -Q $mapQthres $bam |" or die;
}

my %depth=();
my $maxCov=0;
my $Average_sequencing_depth=0;
my $Average_sequencing_depth4=0;
my $Average_sequencing_depth10=0;
my $Average_sequencing_depth20=0;
my $Coverage=0;
my $Coverage4=0;
my $Coverage10=0;
my $Coverage20=0;

my $Coverage_bases=0;
my $Coverage_bases_4=0;
my $Coverage_bases_10=0;
my $Coverage_bases_20=0;

my $total_Coverage_bases=0;
my $total_Coverage_bases_4=0;
my $total_Coverage_bases_10=0;
my $total_Coverage_bases_20=0;

while(<DEPTH>)
{
	chomp;
	$depth{$_}+=1;
}
close DEPTH;

my @depth=sort {$a<=>$b} keys %depth;

open HIS,">$outdir/depth_frequency.txt" or die;
open CUM,">$outdir/cumu.txt" or die;

foreach my $depth1 (sort {$a<=>$b} keys %depth)
{
	next if($depth1==0);
	my $per=$depth{$depth1}/$total_chr;
	$total_Coverage_bases += $depth1*$depth{$depth1};
	$Coverage_bases += $depth{$depth1};

	if($depth1>=4)	
	{
		$total_Coverage_bases_4 += $depth1 * $depth{$depth1};
		$Coverage_bases_4 += $depth{$depth1};
	}
	if($depth1>=10)
	{
		$total_Coverage_bases_10 += $depth1 * $depth{$depth1};
		$Coverage_bases_10 += $depth{$depth1};
	}
	if($depth1>=20)
	{
		$total_Coverage_bases_20 += $depth1 * $depth{$depth1};
		$Coverage_bases_20 += $depth{$depth1};
	}



	$maxCov=$per if($maxCov<$per);
	my $tmp=0;
	print HIS "$depth1\t$per\n";
	foreach my $depth2(@depth)
	{
		$tmp+=$depth{$depth2} if($depth2 >= $depth1); 
	}
	$tmp=$tmp/$total_chr;
	print CUM "$depth1\t$tmp\n";
}

$Average_sequencing_depth=$total_Coverage_bases/$total_chr;
$Coverage=$Coverage_bases/$total_chr;
$Average_sequencing_depth4=$total_Coverage_bases_4/$total_chr;
$Coverage4=$Coverage_bases_4/$total_chr;
$Average_sequencing_depth10=$total_Coverage_bases_10/$total_chr;
$Coverage10=$Coverage_bases_10/$total_chr;
$Average_sequencing_depth20=$total_Coverage_bases_20/$total_chr;
$Coverage20=$Coverage_bases_20/$total_chr;


print "Average sequencing depth\t",sprintf("%.2f",$Average_sequencing_depth),"\n";
print "Coverage\t",sprintf("%.2f%%",100*$Coverage),"\n";
print "Coverage at least 4X\t",sprintf("%.2f%%",100*$Coverage4),"\n";
print "Coverage at least 10X\t",sprintf("%.2f%%",100*$Coverage10),"\n";
print "Coverage at least 20X\t",sprintf("%.2f%%",100*$Coverage20),"\n";


close HIS;
close CUM;

