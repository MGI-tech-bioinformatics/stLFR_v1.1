#!/bin/sh
#$ -S /bin/sh
if [ $# -lt 3 ]
then
        echo -en "Usage:\n\t bash $0 <dir> <name> <size> <Rscript>\n"
        exit
fi

dir=$1
name=$2
frag_size_cutoff=$3
maindir=`dirname $0`
if [ $# == 4 ]
then
  Rscript=$4
else
  Rscript=${maindir}/../../tools/R-3.2.3/bin/Rscript
fi

echo barcode$'\t'subid$'\t'chrom$'\t'begin$'\t'end$'\t'length$'\t'readcount > ${dir}/read_map_pos_sorted_addsubid_mapq30_comb.txt
cat ${dir}/${name}.*.frag1.txt \
  | sort -V -k 1,1 -k 3,3 \
  >> ${dir}/read_map_pos_sorted_addsubid_mapq30_comb.txt

less ${dir}/read_map_pos_sorted_addsubid_mapq30_comb.txt \
  | awk -F $'\t' -v minfrag=${frag_size_cutoff} '(NR==1 || $6>=minfrag){print}' \
  > ${dir}/read_map_pos_sorted_addsubid_mapq30_comb_minfrag${frag_size_cutoff}.txt
  
awk -F $'\t' '(NR>1){fragcount++;
  fraglength=fraglength+$6;
  fragreadcount=fragreadcount+$7}END{ave_fraglen=fraglength/fragcount;
  ave_fragreadcount=fragreadcount/fragcount;
  print "fragcount","ave_fraglen","ave_fragreadcount";
  print fragcount,ave_fraglen,ave_fragreadcount}' OFS="\t" \
  ${dir}/read_map_pos_sorted_addsubid_mapq30_comb_minfrag${frag_size_cutoff}.txt \
  > ${dir}/minfrag${frag_size_cutoff}_mean_len_readcount.txt

echo barcode$'\t'total_min${frag_size_cutoff}frag_count$'\t'total_min${frag_size_cutoff}frag_readcount > ${dir}/barcode_mapq30_min${frag_size_cutoff}frag_totalcounts.txt
awk '{
  if(NR>1){
    barcode=$1
    fragreadcount=$7
    if(prev_barcode==""){
      fraginbarcodecount=1
      totalreadcount=fragreadcount
    }
    else if(barcode==prev_barcode){
      fraginbarcodecount++
      totalreadcount=totalreadcount+fragreadcount
    }
    else if(barcode!=prev_barcode){
      print prev_barcode,fraginbarcodecount,totalreadcount
      fraginbarcodecount=1
      totalreadcount=fragreadcount
    }
    prev_barcode=barcode
    }
  }' OFS="\t" \
  ${dir}/read_map_pos_sorted_addsubid_mapq30_comb_minfrag${frag_size_cutoff}.txt \
  >> ${dir}/barcode_mapq30_min${frag_size_cutoff}frag_totalcounts.txt

awk -F $'\t' '(NR>1){
    barcodecount++;
    fragonbarcode=fragonbarcode+$2;
    barcodereadcount=barcodereadcount+$3
  }
  END{
    ave_fragonbarcode=fragonbarcode/barcodecount;
    ave_barcodereadcount=barcodereadcount/barcodecount;
    print "barcodecount","ave_fragonbarcode","ave_barcodereadcount";
    print barcodecount,ave_fragonbarcode,ave_barcodereadcount
  }' OFS="\t" \
  ${dir}/barcode_mapq30_min${frag_size_cutoff}frag_totalcounts.txt \
  > ${dir}/min${frag_size_cutoff}frag_barcode_summary.txt

${Rscript} ${maindir}/fraglen_hist.R \
  ${dir}/read_map_pos_sorted_addsubid_mapq30_comb_minfrag${frag_size_cutoff}.txt \
  ${dir}/${name}.fraglen_distribution_min${frag_size_cutoff}.pdf
${Rscript} ${maindir}/plot_frag_per_barcode.R \
  ${dir}/barcode_mapq30_min${frag_size_cutoff}frag_totalcounts.txt \
  ${dir}/${name}.frag_per_barcode.pdf
${Rscript} ${maindir}/plot_frag_cov.R \
  ${dir}/read_map_pos_sorted_addsubid_mapq30_comb_minfrag${frag_size_cutoff}.txt \
  ${dir}/${name}.frag_cov.pdf
