#!/usr/bin/perl -w
use strict;

die "perl $0 <indir> <out>"unless @ARGV==2;

my $indir = $ARGV[0];
my %stat;
my $id1 = "Sample:Clean reads:Clean bases(bp):Mapped reads:Mapped bases(bp):Mapping rate:Mean MAQ:MAQ10:MAQ20:MAQ30:Duplicate reads:Duplicate rate:Mismatch bases(bp):Mismatch rate:Chimerical rate:Average sequencing depth:Coverage:Coverage at least 4X:Coverage at least 10X:Coverage at least 20X:AT_DROPOUT:GC_DROPOUT";
my @sample = `ls $indir`;

foreach my $sample (@sample){
	chomp $sample;
	$stat{$sample}{"Sample"} = $sample;
	my @chimerical = ();
	open IN3,"$indir/$sample/$sample.sorted.bam.flagstat";
	while(<IN3>){
		chomp;
		my @a = split /\s+/;
		$chimerical[0] = $a[0] if /total/;
		$chimerical[1] = $a[0] if /mapped \(/;
		$chimerical[2] = $a[0] if /properly paired/;
		$chimerical[3] = $a[0] if /singletons/;
	}
	close IN3;
  open IN4,"$indir/$sample/$sample.sorted.bam.stats";
  while(<IN4>){
    chomp;
    next if /^#/;
    if(/^SN/){ 
      my @a = split /\t/;
      $stat{$sample}{"Clean reads"} = $a[2] if $a[1] eq "raw total sequences:";
      $stat{$sample}{"Mapped reads"} = $a[2] if $a[1] eq "reads mapped:";
      $stat{$sample}{"Duplicate reads"} = $a[2] if $a[1] eq "reads duplicated:";
    }
  }
  close IN4;

  if($chimerical[0] > 0){
  	$stat{$sample}{"Mapping rate"} = int( $stat{$sample}{"Mapped reads"} / $stat{$sample}{"Clean reads"} * 10000 + 0.5) / 100;$stat{$sample}{"Mapping rate"} .= "%";
  	$stat{$sample}{"Duplicate rate"} = int($stat{$sample}{"Duplicate reads"} / $stat{$sample}{"Clean reads"} * 10000 + 0.5) / 100;$stat{$sample}{"Duplicate rate"} .= "%";
  	$stat{$sample}{"Chimerical rate"} = int(($chimerical[1] - $chimerical[2] - $chimerical[3]) / $chimerical[0] * 10000 + 0.5) / 100;$stat{$sample}{"Chimerical rate"} .= "%";
  }
  else{
    $stat{$sample}{"Mapping rate"} = 0;
    $stat{$sample}{"Duplicate rate"} = 0;
    $stat{$sample}{"Chimerical rate"} = 0;
  }
	
	open IN1,"$indir/$sample/$sample.sorted.bam.info_1.xls";
	while(<IN1>){
		chomp;
		my @a = split /\t/;
		$stat{$sample}{$a[0]} = $a[1];
	}
	close IN1;
	$stat{$sample}{"Clean bases(bp)"} = $stat{$sample}{"Clean reads"} * $stat{$sample}{"Readlength"};
	$stat{$sample}{"Mapped bases(bp)"} = $stat{$sample}{"Mapped reads"} * $stat{$sample}{"Readlength"};

	open IN2,"$indir/$sample/$sample.sorted.bam.info_2.xls";
	while(<IN2>){
		chomp;
		my @a = split /\t/;
		$stat{$sample}{$a[0]} = $a[1];
	}
	close IN2;

  $stat{$sample}{"Genome depth CV"} = "-";
  $stat{$sample}{"GC depth CV"}     = "-";

  open IN3,"$indir/$sample/$sample.gcbias_summary_metrics.txt";
  while(<IN3>){
    chomp;
    next if /^#/;
    my %id;
    my @a = split /\t/;
    if(/AT_DROPOUT/){
      for(my $i = 0; $i < @a; $i++){
        $id{"AT_DROPOUT"} = $i if $a[$i] eq "AT_DROPOUT";
        $id{"GC_DROPOUT"} = $i if $a[$i] eq "GC_DROPOUT";
      }
      my $value = <IN3>;
      chomp $value;
      my @b = split /\t/, $value;
      $stat{$sample}{"AT_DROPOUT"} = $b[ $id{"AT_DROPOUT"} ];
      $stat{$sample}{"GC_DROPOUT"} = $b[ $id{"GC_DROPOUT"} ];
    }
  }
  close IN3;

}

open OT1,">$ARGV[1]"; 
foreach my $key ( split /\:/, $id1 ){
	chomp $key;
	print OT1 "$key";
	foreach my $sample (@sample){
		chomp $sample;
		print OT1 "\t$stat{$sample}{$key}";	
	}
	print OT1 "\n";
}
close OT1;

