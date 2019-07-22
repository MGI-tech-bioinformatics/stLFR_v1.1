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

my ($list, $result, $shell, $cpu, %flag, $watchDog, $bamdir, $vcfdir,
  $reference, $extractHAIRS, $hapcut2, $python3, $linkfragment, $compareblock, $chromsize, $ref,
  $threads, $linkdist, $line, $phasedvcf,
);
GetOptions(
  "i=s"   => \$list,
  "o=s"   => \$result,
  "s=s"   => \$shell,
  "fb=s"  => \$bamdir,
  "fv=s"  => \$vcfdir,
  "cpu=i" => \$cpu,
  "ref=s" => \$ref,
);
die "perl $0 -i input -o result -s shell -fb bamdir -fv vcfdir -ref ref\n" unless defined $list && defined $result && defined $shell && defined $bamdir && defined $vcfdir && defined $ref;

$watchDog     = "$Bin/../watchDog_v1.0.pl";
$extractHAIRS = "$TOOL_PATH/HapCUT2-master/build/extractHAIRS";
$hapcut2      = "$TOOL_PATH/HapCUT2-master/build/HAPCUT2";
$linkfragment = "$TOOL_PATH/HapCUT2-master/utilities/LinkFragments.py";
$compareblock = "$TOOL_PATH/HapCUT2-master/utilities/calculate_haplotype_statistics.py";
$python3      = "$TOOL_PATH/python3/python3";
$reference    = $$REF_H_DBPATH{"$ref.fa"};
$chromsize    = $$REF_H_DBPATH{"$ref.chrom.size"};
$phasedvcf    = $$REF_H_DBPATH{"$ref.pvcf"};
$cpu        ||= 70;
$threads    ||= 6;
$linkdist   ||= 1000000;

#=============================================#
# build shell
#=============================================#
open S1,">$shell/run6.bamvcf_HaplotypeAssembly.1.sh";
open S2,">$shell/run6.bamvcf_HaplotypeAssembly.2.sh";

open LIST,$list;
while(<LIST>){
  chomp;
  next if /^#/;
  next if /^sample.*path/;
  my @info = split /\s+/;

  $flag{$info[0]}++;
  next if $flag{$info[0]} > 1;  # pass if duplicated samples
  $line = 0;

  print S2 "rm $result\_withindel/$info[0]/$info[0].*\n";
  print S2 "rm $result\_withoutindel/$info[0]/$info[0].*\n";
  $line += 2;

  open FAI,"$reference.fai";
  my (@w_hap, @wo_hap, @vcf, @w_frag, @wo_frag, @pvcf) = () x 6;
  while(<FAI>){
    chomp;
    my @fai = split;
    next if $fai[0] =~ /^GL|NC|hs37d5|\_|Y|MT|chrM/;

    # build with indel
    print S1 "mkdir -p $result\_withindel/$info[0]/tempData $result\_withindel/$info[0]/split\n";
    print S1 "$extractHAIRS --indels 1 --ref $reference --10X 1 --bam $bamdir/$info[0]/split/$info[0].sort.rmdup.$fai[0].bam --VCF $vcfdir/$info[0]/split/$info[0].gatk4.$fai[0].vcf --out $result\_withindel/$info[0]/tempData/1.$info[0].$fai[0].unlinked_frag\n";
    print S1 "$python3 $linkfragment --bam $bamdir/$info[0]/split/$info[0].sort.rmdup.$fai[0].bam --vcf $vcfdir/$info[0]/split/$info[0].gatk4.$fai[0].vcf --fragments $result\_withindel/$info[0]/tempData/1.$info[0].$fai[0].unlinked_frag --out $result\_withindel/$info[0]/split/linked_fragment.$info[0].$fai[0] -d $linkdist\n";
    print S1 "$hapcut2 --nf 1 --fragments $result\_withindel/$info[0]/split/linked_fragment.$info[0].$fai[0] --vcf $vcfdir/$info[0]/split/$info[0].gatk4.$fai[0].vcf --output $result\_withindel/$info[0]/split/hapblock_$info[0]\_$fai[0]\n";
    print S1 "echo $fai[0] > $result\_withindel/$info[0]/tempData/2.$info[0].$fai[0].hapcut_stat.txt\n";
    print S1 "$python3 $compareblock -h1 $result\_withindel/$info[0]/split/hapblock_$info[0]\_$fai[0] -v1 $vcfdir/$info[0]/split/$info[0].gatk4.$fai[0].vcf -f1 $result\_withindel/$info[0]/split/linked_fragment.$info[0].$fai[0] -pv $phasedvcf.$fai[0].vcf -c $chromsize >> $result\_withindel/$info[0]/tempData/2.$info[0].$fai[0].hapcut_stat.txt\n";

    # build without indel
    print S1 "mkdir -p $result\_withoutindel/$info[0]/tempData $result\_withoutindel/$info[0]/split\n";
    print S1 "$extractHAIRS --10X 1 --bam $bamdir/$info[0]/split/$info[0].sort.rmdup.$fai[0].bam --VCF $vcfdir/$info[0]/split/$info[0].gatk4.$fai[0].vcf --out $result\_withoutindel/$info[0]/tempData/1.$info[0].$fai[0].unlinked_frag\n";
    print S1 "$python3 $linkfragment --bam $bamdir/$info[0]/split/$info[0].sort.rmdup.$fai[0].bam --vcf $vcfdir/$info[0]/split/$info[0].gatk4.$fai[0].vcf --fragments $result\_withoutindel/$info[0]/tempData/1.$info[0].$fai[0].unlinked_frag --out $result\_withoutindel/$info[0]/split/linked_fragment.$info[0].$fai[0] -d $linkdist\n";
    print S1 "$hapcut2 --nf 1 --fragments $result\_withoutindel/$info[0]/split/linked_fragment.$info[0].$fai[0] --vcf $vcfdir/$info[0]/split/$info[0].gatk4.$fai[0].vcf --output $result\_withoutindel/$info[0]/split/hapblock_$info[0]\_$fai[0]\n";
    # add for snp 20190513
    print S1 "less $result\_withoutindel/$info[0]/split/hapblock_$info[0]\_$fai[0] |perl -e 'while(<>){chomp;\@a=split;next if !/^BLOCK/ && (length(\$a[5]) > 1 || length(\$a[6]) > 1); print \"\$_\\n\"; }' > $result\_withoutindel/$info[0]/split/hapblock_$info[0]\_$fai[0].snp && echo $fai[0] > $result\_withoutindel/$info[0]/tempData/2.$info[0].$fai[0].hapcut_stat.txt\n";
    print S1 "$python3 $compareblock -h1 $result\_withoutindel/$info[0]/split/hapblock_$info[0]\_$fai[0].snp -v1 $vcfdir/$info[0]/split/$info[0].gatk4.$fai[0].vcf -f1 $result\_withoutindel/$info[0]/split/linked_fragment.$info[0].$fai[0] -pv $phasedvcf.$fai[0].vcf -c $chromsize >> $result\_withoutindel/$info[0]/tempData/2.$info[0].$fai[0].hapcut_stat.txt\n";

    # cat result
    print S2 "cat $result\_withindel/$info[0]/split/linked_fragment.$info[0].$fai[0] >> $result\_withindel/$info[0]/$info[0].linked_fragment\n";
    print S2 "cat $result\_withindel/$info[0]/split/hapblock_$info[0]\_$fai[0] >> $result\_withindel/$info[0]/$info[0].hapblock\n";
    print S2 "cat $result\_withindel/$info[0]/tempData/2.$info[0].$fai[0].hapcut_stat.txt >> $result\_withindel/$info[0]/$info[0].hapcut_stat.txt\n";
    print S2 "cat $result\_withoutindel/$info[0]/split/linked_fragment.$info[0].$fai[0] >> $result\_withoutindel/$info[0]/$info[0].linked_fragment\n";
    print S2 "cat $result\_withoutindel/$info[0]/split/hapblock_$info[0]\_$fai[0] >> $result\_withoutindel/$info[0]/$info[0].hapblock\n";
    print S2 "cat $result\_withoutindel/$info[0]/tempData/2.$info[0].$fai[0].hapcut_stat.txt >> $result\_withoutindel/$info[0]/$info[0].hapcut_stat.txt\n";
    $line += 6;
    
    # get chromosome array
    push @w_hap,   "$result\_withindel/$info[0]/split/hapblock_$info[0]\_$fai[0]";
    push @w_frag,  "$result\_withindel/$info[0]/split/linked_fragment.$info[0].$fai[0]";
    push @wo_hap,  "$result\_withoutindel/$info[0]/split/hapblock_$info[0]\_$fai[0].snp";
    push @wo_frag, "$result\_withoutindel/$info[0]/split/linked_fragment.$info[0].$fai[0]";
    push @vcf,     "$vcfdir/$info[0]/split/$info[0].gatk4.$fai[0].vcf";
    push @pvcf,    "$phasedvcf.$fai[0].vcf";

  }
  close FAI;

  print S2 "echo \"combine all chrs\" >> $result\_withindel/$info[0]/$info[0].hapcut_stat.txt \n";
  print S2 "$python3 $compareblock -h1 ".(join " ", @w_hap)." -v1 ".(join " ", @vcf)." -f1 ".(join " ",@w_frag)." -pv ".(join " ",@vcf)." -c $chromsize >> $result\_withindel/$info[0]/$info[0].hapcut_stat.txt \n";
  print S2 "echo \"combine all chrs\" >> $result\_withoutindel/$info[0]/$info[0].hapcut_stat.txt \n";
  print S2 "$python3 $compareblock -h1 ".(join " ", @wo_hap)." -v1 ".(join " ", @vcf)." -f1 ".(join " ",@wo_frag)." -pv ".(join " ",@pvcf)." -c $chromsize >> $result\_withoutindel/$info[0]/$info[0].hapcut_stat.txt \n";
  print S2 "rm -fr $result\_withindel/$info[0]/tempData\n";
  print S2 "rm -fr $result\_withoutindel/$info[0]/tempData\n";

}
close LIST;

close S1;
close S2;
#=============================================#
# write main shell script
#=============================================#
open MAINSHELL,">>$shell/pipeline.sh";
print MAINSHELL "echo ========== 6.bamvcf haplotype assembly start at : `date` ==========\n";
print MAINSHELL "perl $watchDog --mem 15g --num_paral $cpu --num_line 6     $shell/run6.bamvcf_HaplotypeAssembly.1.sh\n";
print MAINSHELL "sh $shell/run6.bamvcf_HaplotypeAssembly.2.sh\n";
print MAINSHELL "echo ========== 6.bamvcf haplotype assembly   end at : `date` ==========\n\n";
close MAINSHELL;

