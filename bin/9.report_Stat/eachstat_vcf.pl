#!/usr/bin/env perl
use warnings;
use strict;

die "perl $0 <vcf> <out> <bcftools> <sample>"unless @ARGV==4;

my @stat;
my @item = qw/Total_SNP dbSNP_rate Novel_SNP Novel_SNP_Rate Ti\/Tv Total_INDEL dbINDEL_Rate/;
my ($ti, $tv) = (0) x 2;

open SNP,"$ARGV[2] view --types snps $ARGV[0] | ";
while(<SNP>){
  next if /^#/;
  chomp;
  my @a = split;
  $stat[0]++;
  if($a[2] eq "."){ $stat[2]++; }else{ $stat[1]++; }
  my $ref = $a[3];
  foreach my $alt (split /\,/, $a[4]){
    next unless length($alt) == 1;
    if($ref eq "A" && $alt eq "G"){
      $ti++;
    }
    elsif($ref eq "G" && $alt eq "A"){
      $ti++;
    }
    elsif($ref eq "C" && $alt eq "T"){
      $ti++;
    }
    elsif($ref eq "T" && $alt eq "C"){
      $ti++;
    }
    else{
      $tv++;
    }
  }
}
close SNP;
$stat[1] = $stat[0] > 0 ? int($stat[1] / $stat[0] * 10000 + 0.5) / 100 : 0;
$stat[3] = int((100 - $stat[1]) * 100 + 0.5) / 100;
$stat[1] .= "%";
$stat[3] .= "%";
$stat[4] = int($ti / $tv * 100 + 0.5) / 100;

open INDEL,"$ARGV[2] view --types indels $ARGV[0] | ";
while(<INDEL>){
  next if /^#/;
  chomp;
  my @a = split;
  $stat[5]++;
  $stat[6]++ if $a[2] ne ".";
}
close INDEL;
$stat[6] = $stat[5] > 0 ? int($stat[6] / $stat[5] * 10000 + 0.5) / 100 : 0;
$stat[6] .= "%";

open OT,">$ARGV[1]";
print OT "Sample\t$ARGV[3]\n";
for(my $i = 0; $i < @item; $i++){
  print OT "$item[$i]\t$stat[$i]\n";
}
close OT;


