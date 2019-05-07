#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use File::Basename;
use Getopt::Long;
use Pod::Usage;
use lib "$Bin/../../lib/perl5";
use MyModule::GlobalVar qw($REF_H_DBPATH $TOOL_PATH);

my ($list, $result, $shell, $cpu, %flag, $watchDog, 
  $bamdir, $vcfdir, $phasedir, $ref,
  $lfrcnv, $sp, $lfrcnv_chr, $lfrcnv_ref, $minsize,
  $threads, 
);
GetOptions(
  "i=s"   => \$list,
  "o=s"   => \$result,
  "s=s"   => \$shell,
  "fb=s"  => \$bamdir,
  "fv=s"  => \$vcfdir,
  "fp=s"  => \$phasedir,
  "cpu=i" => \$cpu,
  "ref=s" => \$ref,
);
die "perl $0 -i input -o result -s shell -fb bamdir -fv vcfdir -ref ref\n" unless defined $list && defined $result && defined $shell && defined $bamdir && defined $vcfdir && defined $phasedir;

$watchDog     = "$Bin/../watchDog_v1.0.pl";
$lfrcnv       = "$TOOL_PATH/cnv/LFR-cnv";
$cpu        ||= 70;
$threads    ||= 8;
$sp         ||= 0.001;
$lfrcnv_chr = ($ref eq "hs37d5") ? "N"      : "Y";
$lfrcnv_ref = ($ref eq "hs37d5") ? "GRCH37" : $ref;
$minsize    ||= 1000;

#=============================================#
# build shell
#=============================================#
open S1,">$shell/run7.bamvcf_CNV.1.sh";
open S2,">$shell/run7.bamvcf_CNV.2.sh";

open LIST,$list;
while(<LIST>){
  chomp;
  next if /^#/;
  next if /^sample.*path/;
  my @info = split /\s+/;

  $flag{$info[0]}++;
  next if $flag{$info[0]} > 1;  # pass if duplicated samples

  `mkdir -p $result/tempData`;
  print S1 "cd $result\n";
  print S1 "$lfrcnv -ncpu $threads -bam $bamdir/$info[0]/$info[0].sort.rmdup.bam -vcf $vcfdir/$info[0]/filter.gq.ad.$info[0].gatk4.vcf.gz -phase $phasedir/$info[0]/split -pname hapblock_$info[0]\_XXX -tmp $result/tempData/$info[0] -sp $sp -out $result/$info[0] -ref $lfrcnv_ref -chr $lfrcnv_chr -lcnv $minsize\n";
  print S1 "cp $result/$info[0]/ALL.200.format.cnv.$minsize.highconfidence $result/$info[0]/$info[0].CNV.result.xls\n";

  print S2 "rm -fr $result/tempData\n";

}
close LIST;

close S1;
close S2;
#=============================================#
# write main shell script
#=============================================#
open MAINSHELL,">>$shell/pipeline.sh";
print MAINSHELL "echo ========== 7.bamvcf CNV start at : `date` ==========\n";
print MAINSHELL "perl $watchDog --mem 15g --num_paral $cpu --num_line 3 $shell/run7.bamvcf_CNV.1.sh\n";
print MAINSHELL "perl $watchDog --mem 1g  --num_paral $cpu --num_line 1 $shell/run7.bamvcf_CNV.2.sh\n";
print MAINSHELL "echo ========== 7.bamvcf CNV   end at : `date` ==========\n\n";
close MAINSHELL;

