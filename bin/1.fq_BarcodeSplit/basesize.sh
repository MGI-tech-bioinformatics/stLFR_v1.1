split_stat_read1=$1
BaseSize=$2
perl -e '$n=0;while(<>){$n++;chomp;@t=split; if($n>=5){$B=$t[1]*(100+100); $G=$B/(1e+6); print "$t[0]\t$t[1]\t$B\t$G\t$t[2]\n"; } }' $1 > $2
awk '{print $4}' $2 >$2.plot
