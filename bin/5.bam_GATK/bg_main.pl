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
  $gatk, $reference, $javadir, $bgzip, $tabix, $python2, $vcffilter, $ref, $dbsnp,
  $g, $G, $m, $M, $x, $X,
  $threads, $line,
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
$javadir   = "$TOOL_PATH/jre1.8.0_101/bin";
$gatk      = "$TOOL_PATH/gatk-4.0.3.0/gatk";
$bgzip     = "$TOOL_PATH/vcftools/bgzip";
$tabix     = "$TOOL_PATH/vcftools/tabix";
$python2   = "$TOOL_PATH/Python-2.7.14/python";
$vcffilter = "$Bin/vcffilter.py";
$reference = $$REF_H_DBPATH{"$ref.fa"};
$dbsnp     = $$REF_H_DBPATH{"$ref.dbsnp"};
$cpu     ||= 70;
$threads ||= 6;
$g       ||= 11;
$G       ||= 61;
$m       ||= 0.11;
$M       ||= 0.265;
$x       ||= 5.5;
$X       ||= 3.95;

#=============================================#
# build shell
#=============================================#
open S1,">$shell/run5.bam_GATK.1.sh";
open S2,">$shell/run5.bam_GATK.2.sh";

open LIST,$list;
while(<LIST>){
  chomp;
  next if /^#/;
  next if /^sample.*path/;
  my @info = split /\s+/;

  $flag{$info[0]}++;
  next if $flag{$info[0]} > 1;  # pass if duplicated samples

  $line = 0;
  `mkdir -p $result/$info[0]/split`;
  open FAI,"$reference.fai";
  while(<FAI>){
    chomp;
    my @fai = split;
    next if $fai[0] =~ /^GL|NC|hs37d5|\_/;
    $line++;
    print S1 "export PATH=\"$javadir:\$PATH\" \n";
    print S1 "$gatk --java-options \"-Xmx10G -Djava.io.tmpdir=$result/$info[0]/tempData\" HaplotypeCaller -R $reference -I $indir/$info[0]/split/$info[0].sort.rmdup.$fai[0].bam -L $fai[0] --dbsnp $dbsnp -O $result/$info[0]/split/$info[0].gatk4.$fai[0].vcf\n";

    print S2 "rm -fr $result/$info[0]/tempData\n" if $line == 1;
    print S2 "awk '(\$1~/^#/){print}'  $result/$info[0]/split/$info[0].gatk4.$fai[0].vcf >  $result/$info[0]/$info[0].gatk4.vcf\n" if $line == 1;
    print S2 "awk '(\$1!~/^#/){print}' $result/$info[0]/split/$info[0].gatk4.$fai[0].vcf >> $result/$info[0]/$info[0].gatk4.vcf\n";
  }
  close FAI;

  print S2 "cd $result/$info[0]\n";
  print S2 "$python2 $vcffilter $result/$info[0]/$info[0].gatk4.vcf $info[0] -g $g -G $G -m $m -M $M -x $x -X $X\n";
  print S2 "$bgzip -f $result/$info[0]/filter.gq.ad.$info[0].gatk4.vcf\n";
  print S2 "$tabix -f -p vcf $result/$info[0]/filter.gq.ad.$info[0].gatk4.vcf.gz\n";
  print S2 "$bgzip -f $result/$info[0]/$info[0].gatk4.vcf\n";
  print S2 "$tabix -f -p vcf $result/$info[0]/$info[0].gatk4.vcf.gz\n";

}
close LIST;
$line += 8; # add 8 lines for remove tempData, vcf filter, add vcf header, bgzip and index vcf.gz

close S1;
close S2;
#=============================================#
# write main shell script
#=============================================#
open MAINSHELL,">>$shell/pipeline.sh";
print MAINSHELL "echo ========== 5.bam GATK start at : `date` ==========\n";
print MAINSHELL "perl $watchDog --mem 10g --num_paral $cpu --num_line 2     $shell/run5.bam_GATK.1.sh\n";
print MAINSHELL "perl $watchDog --mem 1g  --num_paral $cpu --num_line $line $shell/run5.bam_GATK.2.sh\n";
print MAINSHELL "echo ========== 5.bam GATK   end at : `date` ==========\n\n";
close MAINSHELL;

