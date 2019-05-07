#!/usr/bin/perl -w
use strict;

die "perl $0 <path> <hapdir> <vcfdir> <statdir>"unless @ARGV==4;

my (%name, %name_flag);
`mkdir -p $ARGV[1]`;
my $list = "chr\tswitch rate\tmismatch rate\tflat rate\tmissing rate\tphased count\tAN50\tN50\tmax block snp frac\tphasing rate";

open IN,$ARGV[0];
while(<IN>){
  next if /^#/;
  next unless /\S+/;
  next if /sample.*\s+path/;
  chomp;
  my @a = split;
  $name_flag{$a[0]}++;
  next if $name_flag{$a[0]} > 1;

  process($ARGV[1], $a[0], "5.phase_HaplotypeAssembly_withoutindel", "hapcut2");
  process($ARGV[1], $a[0], "5.phase_HaplotypeAssembly_withindel", "hapcut2_SNP+InDel");

}
close IN;

sub process{
  my ($dir, $name, $type, $header) = (@_);

  my %stat = ();
  my @chr = ();
  my $chr;
  open RESULT,"$dir/$type/$name/$name.hapcut_stat.txt";
  while(<RESULT>){
    chomp;
    next unless /\S+/;
    next if /compare L0 with giab/;
    next if /chrM|MT|Y/;

#    if(!/\:/ && /^chr/){
    if(!/\:/ && !/combine all chrs/){
      $chr = $_;
      push @chr, $chr;
      $stat{$chr}{"chr"} = $chr;
      next;
    }
    elsif(/combine all chrs/){
      $chr = "chrAll";
      push @chr, $chr;
      $stat{$chr}{"chr"} = $chr;
      next;
    }
    my @b = split /\:/;
    $b[1] =~ s/^\s+//;
    $stat{$chr}{$b[0]} = $b[1];
  }
  close RESULT;

  foreach my $chr (@chr){
    next if $chr eq "chrAll";
    open FILE,"$ARGV[2]/$name/split/$name.gatk4.$chr.vcf";
    while(<FILE>){
      chomp;
      next if /^#/;
      my @b = split /\t/;
      
      # only snp when phasing only by snp, 20190505
      next if $type =~ /withoutindel/ && (length($b[3]) > 1 || length($b[4]) > 1);
      
      my $genotype = (split /\:/, $b[9])[0];
      my ($g1, $g2) = (split /\/|\|/, $genotype)[0, 1];
      $stat{$chr}{"het"} += 1 if $g1 ne $g2;
      $stat{"chrAll"}{"het"} += 1 if $g1 ne $g2;
    }
    close FILE;
    $stat{$chr}{"phasing rate"} = (defined $stat{$chr}{"het"} > 0) ? $stat{$chr}{"phased count"} / $stat{$chr}{"het"} : 0;
  }

  $chr = "chrAll";
  $stat{$chr}{"phasing rate"} = (defined $stat{$chr}{"het"} > 0) ? $stat{$chr}{"phased count"} / $stat{$chr}{"het"} : 0;

  open OT,">$ARGV[3]/Phasingcount.$name.$header.xls";
  print OT "$list\n";
  foreach my $chr (@chr){
    print OT "$chr";
    foreach my $key(split /\t/, $list){
      next if $key eq "chr";
      #$stat{$chr}{$key} = int($stat{$chr}{$key} * 10000 + 0.5) / 10000 if $stat{$chr}{$key} =~ /\d+\.\d+/;
      print OT "\t$stat{$chr}{$key}";
    }
    print OT "\n";
  }
  close OT;

};



