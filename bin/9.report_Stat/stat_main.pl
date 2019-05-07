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

my ($list, $result, $shell, $cpu, %flag, $watchDog, $bamdir, $vcfdir, $cnvdir, $svdir,
  $reference, $ref, $samtools, $bam2depth, $non, $java, $picard, $R, $bcftools,
  $line, $frag_split_distance, $frag_size_cutoff,
);
GetOptions(
  "i=s"   => \$list,
  "o=s"   => \$result,
  "s=s"   => \$shell,
  "fb=s"  => \$bamdir,
  "fv=s"  => \$vcfdir,
  "cpu=i" => \$cpu,
  "ref=s" => \$ref,
  "fc=s"  => \$cnvdir,
  "fs=s"  => \$svdir,
);
die "perl $0 -i input -o result -s shell -fb bamdir -fv vcfdir -ref ref\n" unless defined $list && defined $result && defined $shell && defined $bamdir && defined $vcfdir && defined $ref;

$watchDog     = "$Bin/../watchDog_v1.0.pl";
$samtools     = "$TOOL_PATH/samtools-1.3/bin/samtools";
$bam2depth    = "$TOOL_PATH/bam2depth/bam2depth";
$java         = "$TOOL_PATH/jre1.8.0_101/bin/java";
$picard       = "$TOOL_PATH/picard/picard.jar";
$R            = "$TOOL_PATH/R-3.5.2/bin";
$bcftools     = "$TOOL_PATH/vcftools/bcftools";
$reference    = $$REF_H_DBPATH{"$ref.fa"};
$non          = $$REF_H_DBPATH{"$ref.non"};
$cpu        ||= 70;
$cnvdir     ||= "$result/../6.stLFR_CNV";
$svdir      ||= "$result/../7.stLFR_SV";
$line         = 0;
$frag_split_distance ||= 300000;
$frag_size_cutoff    ||= 5000;

#=============================================#
# build shell
#=============================================#
open S1,">$shell/run9.report_Stat.1.sh";
open S2,">$shell/run9.report_Stat.2.sh";

open LIST,$list;
while(<LIST>){
  chomp;
  next if /^#/;
  next if /^sample.*path/;
  my @info = split /\s+/;

  $flag{$info[0]}++;
  next if $flag{$info[0]} > 1;  # pass if duplicated samples

  `mkdir -p $result/tempData/$info[0]`;
  open FAI,"$reference.fai";
  while(<FAI>){
    chomp;
    my @fai = split;
    next if $fai[0] =~ /^GL|NC|hs37d5|\_/;
    print S1 "sh $Bin/eachstat_fragment_1.sh $bamdir/$info[0]/split/$info[0].sort.rmdup.$fai[0].bam $result/tempData/$info[0] $info[0] $frag_split_distance $frag_size_cutoff $samtools\n";
  }
  close FAI;
  print S1 "$samtools flagstat $bamdir/$info[0]/$info[0].sort.rmdup.bam > $result/tempData/$info[0]/$info[0].sorted.bam.flagstat\n";
  print S1 "$samtools stats $bamdir/$info[0]/$info[0].sort.rmdup.bam > $result/tempData//$info[0]/$info[0].sorted.bam.stats\n";
  print S1 "perl $Bin/eachstat_cov.pl $bamdir/$info[0]/$info[0].sort.rmdup.bam $result/tempData/$info[0]/$info[0].sorted.bam.info_1.xls $samtools\n";
  print S1 "perl $Bin/eachstat_depth.pl $bamdir/$info[0]/$info[0].sort.rmdup.bam $result/tempData/$info[0] -hg $ref -bd $bam2depth -n $non > $result/tempData/$info[0]/$info[0].sorted.bam.info_2.xls\n";
  print S1 "export PATH=\$PATH:$R && $java -Xms8g -Xmx8g -jar $picard CollectInsertSizeMetrics I=$bamdir/$info[0]/$info[0].sort.rmdup.bam O=$result/tempData/$info[0]/$info[0].insertsize_metrics.txt H=$result/tempData/$info[0]/$info[0].insertsize_metrics.pdf VALIDATION_STRINGENCY=SILENT && less $result/tempData/$info[0]/$info[0].insertsize_metrics.txt | sed '1,11d' > $result/tempData/$info[0]/$info[0].insertsize.xls\n";
  print S1 "export PATH=\$PATH:$R && $java -Xms8g -Xmx8g -jar $picard CollectGcBiasMetrics R=$reference I=$bamdir/$info[0]/$info[0].sort.rmdup.bam O=$result/tempData/$info[0]/$info[0].gcbias_metrics.txt CHART=$result/tempData/$info[0]/$info[0].gcbias_metrics.pdf S=$result/tempData/$info[0]/$info[0].gcbias_summary_metrics.txt VALIDATION_STRINGENCY=SILENT && cat $result/tempData/$info[0]/$info[0].gcbias_metrics.txt | grep -v ^#| grep '\\S' | awk 'BEGIN{FS=\"\\t\";OFS=\"\\t\"}{print \$3,\$4,\$5,\$6,\$7,\$8}' > $result/tempData/$info[0]/$info[0].gcbias.xls\n";
  print S1 "perl $Bin/eachstat_vcf.pl $vcfdir/$info[0]/filter.gq.ad.$info[0].gatk4.vcf.gz $result/tempData/$info[0]/$info[0].vcfstat.xls $bcftools $info[0]\n";
  print S2 "sh $Bin/eachstat_fragment_2.sh $result/tempData/$info[0] $info[0] $frag_size_cutoff $R/Rscript && cp $result/tempData/$info[0]/$info[0].*frag*pdf $result/\n";
  $line++;

}
close LIST;

print S2 "perl $Bin/eachstat_aligncat.pl $result/tempData $result/tempData/Alignment.Summary.xls\n";
print S2 "perl $Bin/cs_align.pl $list $result/../1.fq_BarcodeSplit $result/tempData $result/Alignment.statistics.xls\n";
print S2 "rm $result/tempData/Alignment.Summary.xls\n";
print S2 "perl $Bin/cs_vcf.pl $list $result/tempData $result/Variant.statistics.xls\n";
print S2 "perl $Bin/cs_hap.pl $list $result/../ $vcfdir $result\n";
print S2 "$R/Rscript $Bin/figure.depth.R $result/tempData $result/Sequencing.depth.pdf\n";
print S2 "$R/Rscript $Bin/figure.cumu.R $result/tempData $result/Sequencing.depth.accumulation.pdf\n";
print S2 "$R/Rscript $Bin/figure.insert.R $result/tempData $result/Insertsize.pdf\n";
print S2 "$R/Rscript $Bin/figure.gcbias.R $result/tempData $result/GCbias.pdf\n";
print S2 "cp $result/tempData/*/*metrics.txt $result/\n";
print S2 "cp $cnvdir/*/*.CNV.result.xls $result/\n";
print S2 "cp $svdir/*/*.SV.*.result.xls $result/\n";
print S2 "#rm -fr $result/tempData\n";
$line += 13;

close S1;
close S2;
#=============================================#
# write main shell script
#=============================================#
open MAINSHELL,">>$shell/pipeline.sh";
print MAINSHELL "echo ========== 9.report stat start at : `date` ==========\n";
print MAINSHELL "perl $watchDog --mem 8g --num_paral $cpu --num_line 1     $shell/run9.report_Stat.1.sh\n";
print MAINSHELL "perl $watchDog --mem 1g --num_paral $cpu --num_line $line $shell/run9.report_Stat.2.sh\n";
print MAINSHELL "echo ========== 9.report stat   end at : `date` ==========\n\n";
close MAINSHELL;

