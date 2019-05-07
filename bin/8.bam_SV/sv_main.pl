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
  $bamdir, $maq, $p_sv,
  $samtools, $lfrsv,
  $threads, 
);
GetOptions(
  "i=s"   => \$list,
  "o=s"   => \$result,
  "s=s"   => \$shell,
  "fb=s"  => \$bamdir,
  "cpu=i" => \$cpu,
  "maq=i" => \$maq,
);
die "perl $0 -i input -o result -s shell -fb bamdir\n" unless defined $list && defined $result && defined $shell && defined $bamdir;

$watchDog     = "$Bin/../watchDog_v1.0.pl";
$samtools     = "$TOOL_PATH/samtools-1.3/bin/samtools";
$lfrsv        = "$TOOL_PATH/sv/LFR-SV.pl";
$cpu        ||= 70;
$maq        ||= 20;
$threads    ||= 8;
$p_sv       ||= " -g 50000 -m 10 -s 10 -r 2 -l 8000 -b 10000 -p 3 -c 30000 ";

#=============================================#
# build shell
#=============================================#
open S1,">$shell/run8.bam_SV.1.sh";
open S2,">$shell/run8.bam_SV.2.sh";

open LIST,$list;
while(<LIST>){
  chomp;
  next if /^#/;
  next if /^sample.*path/;
  my @info = split /\s+/;

  $flag{$info[0]}++;
  next if $flag{$info[0]} > 1;  # pass if duplicated samples

  `mkdir -p $result/$info[0]/tmp`;
  print S1 "perl $lfrsv -i $bamdir/$info[0]/$info[0].sort.rmdup.bam -o $result/$info[0]/tmp -p $info[0]\n";
  print S1 "sh $result/$info[0]/tmp/run_SV_$info[0].sh\n";
  print S1 "cp $result/$info[0]/tmp/$info[0].list.segment.sv.dp.mb.sort.simple.final.list $result/$info[0]/$info[0].SV.simple.result.xls\n";
  print S1 "cp $result/$info[0]/tmp/$info[0].list.segment.sv.dp.mb.sort.complex.final.list $result/$info[0]/$info[0].SV.complex.result.xls\n";
  print S1 "#sh $result/$info[0]/tmp/run_SV_$info[0]\_plot.sh\n";
  
  print S2 "rm -fr $result/$info[0]/tmp\n";

}
close LIST;

close S1;
close S2;
#=============================================#
# write main shell script
#=============================================#
open MAINSHELL,">>$shell/pipeline.sh";
print MAINSHELL "echo ========== 8.bam SV start at : `date` ==========\n";
print MAINSHELL "perl $watchDog --mem 60g --num_paral $cpu --num_line 5 $shell/run8.bam_SV.1.sh\n";
print MAINSHELL "perl $watchDog --mem 1g  --num_paral $cpu --num_line 1 $shell/run8.bam_SV.2.sh\n";
print MAINSHELL "echo ========== 8.bam SV   end at : `date` ==========\n\n";
close MAINSHELL;

