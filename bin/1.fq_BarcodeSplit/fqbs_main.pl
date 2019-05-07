#!/usr/bin/perl
use strict;
use warnings;
use FindBin qw($Bin);
use Cwd qw(abs_path);
use File::Basename;
use Getopt::Long;
use Pod::Usage;

my ($list, $result, $shell, $cpu,
  $barcode_position,
  %flag, %samplepathflag, $watchDog);
GetOptions(
  "i=s"   => \$list,
  "o=s"   => \$result,
  "s=s"   => \$shell,
  "cpu=i" => \$cpu,
);
die "perl $0 -i input -o result -s shell \n" unless defined $list && defined $result && defined $shell;

$cpu              ||= 70;
$watchDog           = "$Bin/../watchDog_v1.0.pl";
$barcode_position ||= "101_10,117_10,133_10";

#=============================================#
# build shell
#=============================================#
open S1,">$shell/run1.fq_BarcodeSplit.1.sh";
open S2,">$shell/run1.fq_BarcodeSplit.2.sh";
open S3,">$shell/run1.fq_BarcodeSplit.3.sh";

open LIST,$list;
while(<LIST>){
  chomp;
  next if /^#/;
  next if /^sample.*path/;
  my @info = split /\s+/;
  $info[2] ||= $barcode_position;

  $samplepathflag{$info[0]}{$info[1]}++;
  next if $samplepathflag{$info[0]}{$info[1]} > 1;  # pass if duplicated lines

  $flag{$info[0]}[0]++;
  `mkdir -p $result/tmp/$info[0]_$flag{$info[0]}[0]`;
  my $fq1 = `ls $info[1]/*read_1.fq.gz`;chomp $fq1;
  my $fq2 = `ls $info[1]/*read_2.fq.gz`;chomp $fq2;
  print S1 "perl $Bin/split_barcode_stLFR.pl -i1 $fq1 -i2 $fq2 -r $info[2] -o $result/tmp/$info[0]_$flag{$info[0]}[0]\n";
  print S1 "sh $Bin/basesize.sh $result/tmp/$info[0]_$flag{$info[0]}[0]/split_stat_read1.log $result/tmp/$info[0]_$flag{$info[0]}[0]/BaseSize.stat\n";
  push @{$flag{$info[0]}[1]}, "$result/tmp/$info[0]_$flag{$info[0]}[0]/split_read.1.fq.gz";
  push @{$flag{$info[0]}[2]}, "$result/tmp/$info[0]_$flag{$info[0]}[0]/split_read.2.fq.gz";
  push @{$flag{$info[0]}[3]}, "$result/tmp/$info[0]_$flag{$info[0]}[0]/split_stat_read1.log";
}
close LIST;

foreach my $sample(sort keys %flag){
  `mkdir -p $result/$sample`;
  print S2 "cat ".(join "\t", @{$flag{$sample}[1]})." > $result/$sample/split_read.1.fq.gz\n";
  print S2 "cat ".(join "\t", @{$flag{$sample}[2]})." > $result/$sample/split_read.2.fq.gz\n";
  print S2 "perl $Bin/merge_split_stat_read1_log.pl ".(join " ",@{$flag{$sample}[3]})." > $result/$sample/split_stat_read1.log\n";

  print S3 "rm -fr $result/tmp\n";
}

close S1;
close S2;
close S3;

#=============================================#
# write main shell script
#=============================================#
open MAINSHELL,">>$shell/pipeline.sh";
print MAINSHELL "echo ========== 1.fq barcode split start at : `date` ==========\n";
print MAINSHELL "perl $watchDog --mem 15g --num_paral $cpu --num_line 2 $shell/run1.fq_BarcodeSplit.1.sh\n";
print MAINSHELL "perl $watchDog --mem 1g  --num_paral $cpu --num_line 1 $shell/run1.fq_BarcodeSplit.2.sh\n";
print MAINSHELL "perl $watchDog --mem 1g  --num_paral $cpu --num_line 1 $shell/run1.fq_BarcodeSplit.3.sh\n";
print MAINSHELL "echo ========== 1.fq barcode split   end at : `date` ==========\n\n";
close MAINSHELL;

