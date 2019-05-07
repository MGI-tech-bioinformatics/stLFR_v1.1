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
    $soapnuke, $adapter,
);
GetOptions(
  "i=s"   => \$list,
  "o=s"   => \$result,
  "s=s"   => \$shell,
  "f=s"   => \$indir,
  "cpu=i" => \$cpu,
);
die "perl $0 -i input -o result -s shell -f indir\n" unless defined $list && defined $result && defined $shell && defined $indir;

$cpu     ||= 70;
$watchDog  = "$Bin/../watchDog_v1.0.pl";
$soapnuke  = "$TOOL_PATH/SOAPnuke-1.5.6/SOAPnuke";
$adapter   = "-f AAGTCGGAGGCCAAGCGGTCTTAGGAAGACAA -r AAGTCGGATCGTAGCCATGTCGTTCTGTGAGCCAAGGAGTT";
$adapter   = "-f CTGTCTCTTATACACATCTTAGGAAGACAAGCACTGACGACATGA -r TCTGCTGAGTCGAGAACGTCTCTGTGAGCCAAGGAGTTGCTCTGG";

#=============================================#
# build shell
#=============================================#
open S1,">$shell/run2.fq_Filter.1.sh";

open LIST,$list;
while(<LIST>){
  chomp;
  next if /^#/;
  next if /^sample.*path/;
  my @info = split /\s+/;

  $flag{$info[0]}++;
  next if $flag{$info[0]} > 1;  # pass if duplicated samples

  `mkdir -p $result/$info[0]`;
  print S1 "$soapnuke filter -l 10 -q 0.1 -n 0.01 -Q 2 -G -T 4 $adapter -1 $indir/$info[0]/split_read.1.fq.gz -2 $indir/$info[0]/split_read.2.fq.gz -o $result/$info[0] -C clean_read_1.fq.gz -D clean_read_2.fq.gz\n";

}
close LIST;

close S1;

#=============================================#
# write main shell script
#=============================================#
open MAINSHELL,">>$shell/pipeline.sh";
print MAINSHELL "echo ========== 2.fq filter start at : `date` ==========\n";
print MAINSHELL "perl $watchDog --mem 4g --num_paral $cpu --num_line 1 $shell/run2.fq_Filter.1.sh\n";
print MAINSHELL "echo ========== 2.fq filter   end at : `date` ==========\n\n";
close MAINSHELL;

