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

my ($list, $result, $shell, $cpu, $indir, %flag, $watchDog,
  $samtools, $reference, $ref,
  $threads,
);
GetOptions(
  "i=s"   => \$list,
  "o=s"   => \$result,
  "s=s"   => \$shell,
  "f=s"   => \$indir,
  "cpu=i" => \$cpu,
  "ref=s" => \$ref,
);
die "perl $0 -i input -o result -s shell -f indir -ref ref\n" unless defined $list && defined $result && defined $shell && defined $indir && defined $ref;

$watchDog  = "$Bin/../watchDog_v1.0.pl";
$samtools  = "$TOOL_PATH/samtools-1.3/bin/samtools";
$reference = $$REF_H_DBPATH{"$ref.fa"};
$cpu     ||= 70;
$threads ||= 6;

#=============================================#
# build shell
#=============================================#
open S1,">$shell/run4.bam_Split.1.sh";

open LIST,$list;
while(<LIST>){
  chomp;
  next if /^#/;
  next if /^sample.*path/;
  my @info = split /\s+/;

  $flag{$info[0]}++;
  next if $flag{$info[0]} > 1;  # pass if duplicated samples

  `mkdir -p $result/$info[0]/split`;
  open FAI,"$reference.fai";
  while(<FAI>){
    chomp;
    my @fai = split;
    next if $fai[0] =~ /^GL|NC|hs37d5|\_/;
    print S1 "$samtools view --threads $threads -h -F 0x400 $indir/$info[0]/$info[0].sort.rmdup.bam $fai[0] |awk  '{if(\$1~/#/){split(\$1,a,\"#\"); if(a[2]!~/0_0_0/){print \$0,\"\\tBX:Z:\"a[2]} }else{print}}' - | $samtools view --threads $threads -bh - > $result/$info[0]/split/$info[0].sort.rmdup.$fai[0].bam\n";
    print S1 "$samtools index $result/$info[0]/split/$info[0].sort.rmdup.$fai[0].bam\n";
  }
  close FAI;

}
close LIST;

close S1;

#=============================================#
# write main shell script
#=============================================#
open MAINSHELL,">>$shell/pipeline.sh";
print MAINSHELL "echo ========== 4.bam split start at : `date` ==========\n";
print MAINSHELL "perl $watchDog --mem 1g --num_paral $cpu --num_line 2 $shell/run4.bam_Split.1.sh\n";
print MAINSHELL "echo ========== 4.bam split   end at : `date` ==========\n\n";
close MAINSHELL;

