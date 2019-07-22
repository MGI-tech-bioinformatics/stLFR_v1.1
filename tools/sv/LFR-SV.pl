#!/bin/perl -w
use strict;
use Cwd;
use FindBin qw($Bin);
use Getopt::Long;
my $usage=<<'USAGE';


	Program:		LFR-SV.pl
	Version:		0.1
	Author:		 (qianzhaoyang@genomics.cn)
				 guojunfu@genomics.cn
				 shichang@genomics.cn
	Modified Date:
		2019_03_22
	Description:
		LFR SV analyze pipeline


	LFR-SV.pl   [options]

	Options:
			-i|--input					<STR>	LFR bam file,must be sorted,markdup and indexed (necessary)
			-o|--out					<STR>	output directory (necessary)
			-p|--prefix					<STR>	prefix for output files
			-g|--gap					<INT>	distance of gaps for seperate segment, default 30000
			-m|--minreadbar				<INT>	min read count in a barcode in step 2,default 10
			-s|--maxseg					<INT>	max number of segment in a barcode in step 2,default 10
			-r|--minreadseg				<INT>	min read count of a segment in step 2,default 4
			-l|--seglen					<INT>	min segment length(bp) in step 2,default 8000
			-b|--bin					<INT>	bin size for breakpoint in step 2,default 2000
			-a|--minbar					<INT>	min number of support barcodes in step 2,default 5
			-f|--flank					<INT>	flank bin counts around breakpoint for cluster in step 2,default 2
			-c|--clustern				<INT>	filt n percent of cluster(0~100),default 95
			-q|--mapq					<INT>	min mapq for uesd reads in pipline,default 0 
			-t|--type					<INT>	pipline start from , 1:step1, 2:step2...,default 1
			-1|--filt1					<INT>	use filt by depth in step 3,default 1
			-2|--filt2					<INT>	use filt by blacklist in step 3,default 0
			-3|--filt3					<INT>	use filt by mappability in step 3,default 1
			-4|--filt4					<INT>	use filt by heatmap in step 3,default 0
			   --mb						<INT>	mappability cut-off for filt in step 3(0~100),default 30
			   --num					<INT>	running plot shell numbers at same time
			  
	Sample:
	
	perl LFR-SV.pl -i ~/a/b/c/pre.bam -o result

USAGE



my ($bam,$outdir,$pre);
my ($gap_size,$min_read_bar,$max_seg,$min_read_seg,$seg_len,$bin_size,$min_bar,$flank,$clustern,$mapq,$type,$filt1,$filt2,$filt3,$filt4,$mb,$num);
my $path = $Bin;
my $samtools = "$Bin/../samtools/bin/samtools";
my $Rscript = "$Bin/../R/bin/R";

GetOptions(
		"i|input=s" => \$bam,
		"o|out=s" => \$outdir,
		"p|pre=s" => \$pre,
		"g|gap=i" => \$gap_size,
		"m|minreadbar=i" => \$min_read_bar,
		"s|maxseg=i" => \$max_seg,
		"r|minreadseg=i" => \$min_read_seg,
		"l|seglen=i" => \$seg_len,
		"b|bin=i" => \$bin_size,
		"a|minbar=i"  => \$min_bar,
		"f|flank=i" => \$flank,
		"c|clustern=i" => \$clustern,
		"q|mapq=i" => \$mapq,
		"t|type=i" => \$type,
		"1|filt1=i" =>\$filt1,
		"2|filt2=i" =>\$filt2,
		"3|filt3=i" =>\$filt3,
		"4|filt4=i" =>\$filt4,
		"mb=i" =>\$mb,
		"num=i" =>\$num,
);
die "$usage\n" unless defined($bam) ;
unless( defined($pre)){
	$pre=(split/\//,$bam)[-1];
	$pre=~s/\.bam//;
}
$outdir="./" unless defined($outdir);
if(!-e $outdir){
	`mkdir -p $outdir`;
}
	`mkdir -p $outdir/plot`;

$gap_size=30000 unless defined($gap_size);
$min_read_bar=4 unless defined($min_read_bar);
$max_seg=10 unless defined($max_seg);
$min_read_seg=4 unless defined($min_read_seg);
$seg_len=8000 unless defined($seg_len);
$bin_size=2000 unless defined($bin_size);
$min_bar=5 unless defined($min_bar);
$flank=2 unless defined($flank);
$clustern=95 unless defined($clustern);
$mapq=0 unless defined($mapq);
$type=1 unless defined($type);
$mb=30 unless defined($mb);
$num=3 unless defined($num);
if(defined($filt1) && $filt1!=1){
	$filt1=0;
}else{
	$filt1=1;
}
if(defined($filt2) && $filt2==1){
	$filt2=1;
}else{
	$filt2=0;
}
if(defined($filt3) && $filt3!=1){
	$filt3=0;
}else{
	$filt3=1;
}
if(defined($filt4) && $filt4==1){
	$filt4=1;
}else{
	$filt4=0;
}
die "-n must between 0~100" if ($clustern<0 ||$clustern>=100);

my $name="$pre.list";
my $withchr;
if(`$samtools view -h $bam|head -n 4|grep "SN:chr1"`){
	$withchr=1;
}else{
	$withchr=0;
}
open SH,">$outdir/run_SV_$pre.sh" or die $!;
print SH "#! /bin/bash\necho ==========start at : `date` ==========\n";
#####STEP 1 Extract pe reads info under same barcode #####
if($type==1){
	print SH "\n#### STEP 1 ####\n\n";
	print SH "/usr/bin/time -o $pre\_step_1.log -v perl $path/Get_reads_info.pl $bam $mapq >$outdir/$name &&\n";
	print SH "/usr/bin/time -o $pre\_step_1.1.log -v python $path/Fragment_info.py $outdir/$name $outdir/$pre  &&\n" ;
}
#####STEP 2 Make potential break points links ##### 
if($type <=2){
	print SH "\n#### STEP 2 ####\n\n";
	print SH "/usr/bin/time -o $pre\_step_2.1.log -v perl $path/Split-segment.pl $outdir/$name $gap_size $min_read_bar >$outdir/$name.segment &&\n";
	$name.=".segment";
	print SH "/usr/bin/time -o $pre\_step_2.2.log -v perl $path/Stac-segment.pl $outdir/$name $min_read_seg $seg_len $max_seg >$outdir/$name.stac &&\n";
	print SH "/usr/bin/time -o $pre\_step_2.3.log -v perl $path/Breakpoint-layout.pl $outdir/$name.stac $min_read_seg >$outdir/$name.layout &&\n";
	print SH "/usr/bin/time -o $pre\_step_2.4.log -v perl $path/Cluster_step1.pl $outdir/$name.layout $bin_size $min_bar >$outdir/$name.cluster &&\n";
	print SH "/usr/bin/time -o $pre\_step_2.5.log -v perl $path/Cluster_step2.pl $outdir/$name.cluster $bin_size $flank >$outdir/$name.sv &&\n";
}
#####STEP 3 Filt potential break points links #####
my $name2;
if($type>2){
	$name.=".segment";
}

	$name2=$name.".sv";

if($type<=3){
	print SH "\n#### STEP 3 ####\n\n";
	if($filt1==1){
		print SH "$Rscript $path/fit.R $outdir/$name.cluster $clustern $outdir/$name.cluster.mindepth &&\n";
		print SH "/usr/bin/time -o $pre\_step_3.1.log -v perl $path/Filt_Cluster_depth.pl $outdir/$name.cluster.mindepth $outdir/$name2 >$outdir/$name2.dp && \n";
		$name2.=".dp";
	}
	if($filt2==1){
		print SH "/usr/bin/time -o $pre\_step_3.2.log -v perl $path/Filt_Blacklist.pl $path/sv_blacklist.bed $outdir/$name2 >$outdir/$name2.bl && \n";
		$name2.=".bl";
	}
	if($filt3==1){
		print SH "/usr/bin/time -o $pre\_step_3.3.log -v perl $path/Filt_Mapbility.pl $path/wgEncodeCrgMapabilityAlign100mer.BedGraph-1 $outdir/$name2 >$outdir/$name2.mb $mb && \n";
		$name2.=".mb";
	}
	print SH "sort -nk1 -nk2 -nk3 -nk4 $outdir/$name2 >$outdir/$name2.sort && \n";
	$name2.=".sort";
	if($filt4==1){
		print SH "/usr/bin/time -o $pre\_step_3.4.log -v python $path/Final_judgement.py $bam $mapq $outdir/$name2 && \n";
		$name2.=".after";
	}
}
##### STEP 4 Merge links with near break point #####
if ($type<=4){
	print SH "\n#### STEP 4 ####\n\n";
	print SH "/usr/bin/time -o $pre\_step_4.log -v perl $path/Merge_group.pl $outdir/$name2 $bin_size $flank && \n";
}
##### STEP 5 Filt false positive #####
if ($type<=5){
	print SH "\n### STEP 5 ####\n\n";
	print SH "/usr/bin/time -o $pre\_step_5.1.log -v $path/judge-link-1 $outdir/$name2.simple $bam $outdir/$name2.simple.final $bin_size $withchr && \n";
	print SH "/usr/bin/time -o $pre\_step_5.2.log -v $path/judge-link-1 $outdir/$name2.complex $bam $outdir/$name2.complex.final $bin_size $withchr && \n";

}
##### STEP 6 Make heatmap for each SV #####
if($type<=6){
	print SH "\n#### STEP 6 ####\n\n";
	print SH "/usr/bin/time -o $pre\_step_6.1.log -v perl $path/Plot_heatmap2.pl $bam $outdir/$name2.simple.final $bin_size $mapq $outdir/plot/polt_$pre.simple $withchr && \n";
	print SH "/usr/bin/time -o $pre\_step_6.2.log -v perl $path/Plot_heatmap2.pl $bam $outdir/$name2.complex.final $bin_size $mapq $outdir/plot/polt_$pre.complex $withchr && \n";
	print SH "/usr/bin/time -o $pre\_step_6.3.log -v perl $path/Make_plot_run.pl $outdir $pre $num && \n";
}
##### STEP 7 Add title for final result #####
if($type<=7){
	print SH "\n#### STEP 7 ####\n\n";
	print SH "/usr/bin/time -o $pre\_step_7.1.log -v perl $path/Add_title.pl $outdir/$name2.simple.final  && \n";
	print SH "/usr/bin/time -o $pre\_step_7.2.log -v perl $path/Add_title.pl $outdir/$name2.complex.final  && \n";
}

print SH "echo ==========end at : `date` ==========\n";
close SH;
