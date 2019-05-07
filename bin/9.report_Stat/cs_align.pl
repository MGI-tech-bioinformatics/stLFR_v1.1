#!/usr/bin/perl -w
use strict;

die "perl $0 <path> <split> <statdir> <out>"unless @ARGV==4;

my %stat = ();
my $list = "Sample name;Raw reads;Raw bases(bp);Clean reads;Clean bases(bp);Total barcode type;Barcode number;Barcode type rate;Reads pair number;Reads pair number(after split);Barcode split rate;Mapped reads;Mapped bases(bp);Mapping rate;Paired mapping rate;Mismatch bases(bp);Mismatch rate;Duplicate reads;Duplicate rate;Total depth;Split barcode(G);Dup depth;Average sequencing depth;Coverage;Coverage at least 4X;Coverage at least 10X;Coverage at least 20X;Mean insert size";
my %namelist;

open IN,$ARGV[0];
while(<IN>){
  next if /^#/;
  next unless /\S+/;
  next if /sample\s+path|sampleID\s+path/;
  chomp;
  my @a = split;
  $namelist{$a[0]} = 1;
  $stat{$a[0]}{"Sample name"} = $a[0];

  # raw fastq
  print STDERR "processing $a[0] raw fastq info ......\n";
  foreach my $fqstat(`ls $a[1]/*_1.fq.fqStat.txt`){
    chomp $fqstat;
    open FQSTAT,$fqstat;
    while(<FQSTAT>){
      chomp;
      next unless /^#/;
      my @b = split;
      if(/#ReadNum/){
        $stat{$a[0]}{"Raw reads"} += 2 * $b[1];
      }
      elsif(/#row_readLen/){
        $stat{$a[0]}{"Raw read length"} = $b[1];
      }
      elsif(/#BaseNum/){
        $stat{$a[0]}{"Raw bases(bp)"} += 2 * $b[1];
      }
    }
    close FQSTAT;
  }
  
  # barcode split
  print STDERR "processing $a[0] barcode info ......\n";
  open SPLIT,"$ARGV[1]/$a[0]/split_stat_read1.log";
  while(<SPLIT>){
    chomp;
    if(/^Barcode_types = .* = (\d+)$/){
      $stat{$a[0]}{"Total barcode type"} = $1;
    }
    elsif(/^Real_Barcode_types = (\d+) \((\S+) \%\)/){
      $stat{$a[0]}{"Barcode number"} = $1;
      $stat{$a[0]}{"Barcode type rate"} = int($2 * 100 + 0.5) / 100;
      $stat{$a[0]}{"Barcode type rate"} .= "%";
    }
    elsif(/^Reads_pair_num\s+= (\d+)/){
      $stat{$a[0]}{"Reads pair number"} = $1;
    }
    elsif(/^Reads_pair_num\(after split\) = (\d+) \((\S+) \%\)/){
      $stat{$a[0]}{"Reads pair number(after split)"} = $1;
      $stat{$a[0]}{"Barcode split rate"} = int($2 * 100 + 0.5) / 100;
      $stat{$a[0]}{"Barcode split rate"} .= "%";
    }
  }
  close SPLIT;

  # pe mapping rate
  print STDERR "processing $a[0] pair-end mapping rate ......\n";
  open FLAGSTAT,"$ARGV[2]/$a[0]/$a[0].sorted.bam.flagstat";
  while(<FLAGSTAT>){
    chomp;
    if(/properly paired \((\S+) : /){
      $stat{$a[0]}{"Paired mapping rate"} = $1;
    }
  }
  close FLAGSTAT;
  
  # insert size
  print STDERR "processing $a[0] insert size ......\n";
  open INSERT,"$ARGV[2]/$a[0]/$a[0].insertsize_metrics.txt";
  while(<INSERT>){
    chomp;
    if(/^MEDIAN_INSERT_SIZE/){
      my @id = split /\s+/;
      my $id;
      for(my $k = 0; $k < @id; $k++){
        $id = $k if $id[$k] eq "MEAN_INSERT_SIZE";
      }
      my $value = <INSERT>;chomp $value;
      $stat{$a[0]}{"Mean insert size"} = int((split /\s+/, $value)[$id] * 100 + 0.5) / 100;
    }
  }
  close INSERT;
  
}
close IN;

# alignment
my %name = ();
open CHART,"$ARGV[2]/Alignment.Summary.xls";
while(<CHART>){
  chomp;
  my @a = split /\t/;
  if(/^Sample/){
    for(my $i = 1; $i < @a; $i++){
      $name{$i} = $a[$i];
    }
    next;
  }
  for(my $i = 1; $i < @a; $i++){
    $stat{ $name{$i} }{$a[0]} = $a[$i];
  }
}
close CHART;

# fix some data
foreach my $name (sort keys %namelist){
  $stat{$name}{"Total depth"} = $stat{$name}{"Reads pair number"} * $stat{$name}{"Raw read length"}  * 2/ 3000000000;
  $stat{$name}{"Split barcode(G)"} = $stat{$name}{"Reads pair number(after split)"} * $stat{$name}{"Raw read length"} * 2 / 1000000000;
  my $rate = $stat{$name}{"Duplicate rate"};
  $rate =~ s/%$//;
  $rate /= 100;
  $stat{$name}{"Dup depth"} = $stat{$name}{"Reads pair number(after split)"} * $stat{$name}{"Raw read length"} * 2 * (1 - $rate) / (3*1000000000);
  $stat{$name}{"Total depth"} = int($stat{$name}{"Total depth"} * 100 + 0.5) / 100;
  $stat{$name}{"Split barcode(G)"} = int($stat{$name}{"Split barcode(G)"} * 100 + 0.5) / 100;
  $stat{$name}{"Dup depth"} = int($stat{$name}{"Dup depth"} * 100 + 0.5) / 100;
}

# output
open OT,">$ARGV[3]";
foreach my $id (split /\;/, $list){
  print OT "$id";
  foreach my $name (sort keys %namelist){
    print OT "\t$stat{$name}{$id}";
  }
  print OT "\n";
}
close OT;


