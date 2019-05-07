#!/usr/bin/perl -w
use strict;

die "perl $0 <list> <dir> <out>"unless @ARGV==3;

my (%name, %stat, %flag);
my $list = "Sample;Total_SNP;dbSNP_rate;Novel_SNP;Novel_SNP_Rate;Ti/Tv;Total_INDEL;dbINDEL_Rate";

open LIST,$ARGV[0];
while(<LIST>){
  chomp;
  next if /^#/;
  next if /^sample.*path/;
  my @info = split /\s+/;

  $flag{$info[0]}++;
  next if $flag{$info[0]} > 1;  # pass if duplicated samples

  open SNP,"$ARGV[1]/$info[0]/$info[0].vcfstat.xls";
  while(<SNP>){
    chomp;
    my @b = split /\t/;
    $stat{$info[0]}{$b[0]} = $b[1];
  }
  close SNP;
}
close LIST;

open OT,">$ARGV[2]";
foreach my $id(split /\;/, $list){
  print OT "$id";
  foreach my $name (sort keys %stat){
    print OT "\t$stat{$name}{$id}";
  }
  print OT "\n";
}
close OT;

