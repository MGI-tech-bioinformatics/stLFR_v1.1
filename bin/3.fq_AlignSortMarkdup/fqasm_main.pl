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
  $bwa, $samtools, $reference, $java, $picard, $ref,
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
$bwa       = "$TOOL_PATH/bwa/bwa";
$samtools  = "$TOOL_PATH/samtools-1.3/bin/samtools";
$java      = "$TOOL_PATH/jre1.8.0_101/bin/java";
$picard    = "$TOOL_PATH/picard/picard.jar";
$reference = $$REF_H_DBPATH{"$ref.fa"};
$cpu     ||= 70;
$threads ||= 15;

#=============================================#
# build shell
#=============================================#
open S1,">$shell/run3.fq_AlignSortMarkdup.1.sh";

open LIST,$list;
while(<LIST>){
  chomp;
  next if /^#/;
  next if /^sample.*path/;
  my @info = split /\s+/;

  $flag{$info[0]}++;
  next if $flag{$info[0]} > 1;  # pass if duplicated samples

  `mkdir -p $result/$info[0]`;
  print S1 "$bwa mem -R \"\@RG\\tID:$info[0]\\tPL:COMPLETE\\tPU:COMPLETE\\tLB:COMPLETE\\tSM:$info[0]\" -t $threads $reference $indir/$info[0]/clean_read_1.fq.gz $indir/$info[0]/clean_read_2.fq.gz > $result/$info[0]/bwa_mem.sam 2>$result/$info[0]/bwa_mem.err\n";
  print S1 "awk '\$2!~/^2/' $result/$info[0]/bwa_mem.sam | $samtools view -bhS --threads $threads -t $reference.fai -T $reference - | $samtools sort --threads $threads -m 1000000000 -T $result/$info[0]/$info[0].sort -o $result/$info[0]/$info[0].sort.bam -\n";
  print S1 "$java -Xmx10240m -jar $picard MarkDuplicates I=$result/$info[0]/$info[0].sort.bam O=$result/$info[0]/$info[0].sort.rmdup.bam M=$result/$info[0]/$info[0].sort.rmdup.metrics.txt VALIDATION_STRINGENCY=SILENT READ_NAME_REGEX='[a-zA-Z0-9]+#([0-9]+)_([0-9]+)_([0-9]+)' TMP_DIR=$result/$info[0]\n";
  print S1 "$samtools index $result/$info[0]/$info[0].sort.rmdup.bam\n";
  print S1 "rm $result/$info[0]/bwa_mem.* $result/$info[0]/$info[0].sort.bam\n";

}
close LIST;

close S1;

#=============================================#
# write main shell script
#=============================================#
open MAINSHELL,">>$shell/pipeline.sh";
print MAINSHELL "echo ========== 3.fq align start at : `date` ==========\n";
print MAINSHELL "perl $watchDog --mem 10g --num_paral $cpu --num_line 5 $shell/run3.fq_AlignSortMarkdup.1.sh\n";
print MAINSHELL "echo ========== 3.fq align   end at : `date` ==========\n\n";
close MAINSHELL;

