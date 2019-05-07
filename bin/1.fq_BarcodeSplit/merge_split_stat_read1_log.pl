#!/usr/bin/perl
use strict;
use warnings;

my %hash;

my $Barcode_types;
my $Reads_pair_num;
my $Reads_pair_num_split;

for my $log (@ARGV){
    read_log($log) if(-f $log);
}



print "$Barcode_types";
my @keys=keys %hash;
my $Real_Barcode_types=$#keys+1;
print "Real_Barcode_types = $Real_Barcode_types (",100*$Real_Barcode_types/3623878656," %)\n";
print "Reads_pair_num = $Reads_pair_num\n";
print "Reads_pair_num(after split) = $Reads_pair_num_split (",100*$Reads_pair_num_split/$Reads_pair_num," %)\n";
my $n=1;
foreach my $key(@keys){
    print $n,"\t",$hash{$key},"\t",$key,"\n";
    $n++;
}


sub read_log{
    my $file=shift;
    open IN,$file;

    $Barcode_types=<IN>;
    <IN>;
    my $line=<IN>;
    chomp $line;
    my @f=split(/\s+/,$line);
    $Reads_pair_num+=$f[2];
    <IN>;
    while(<IN>){
         chomp;
         my @f=split;
         $hash{$f[2]}+=$f[1];
         $Reads_pair_num_split+=$f[1];
    }
    close IN;
}

