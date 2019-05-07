#!/bin/sh
#$ -S /bin/sh

if [ $# -lt 5 ]
then
        echo -en "Usage:\n\t bash $0 <bam> <outdir> <name> <distance> <size> <samtools>\n"
        exit
fi

sort_markdup_bam=$1
outdir=$2
name=$3
frag_split_distance=$4
frag_size_cutoff=$5
if [ $# == 6 ]
then
  samtools=$6
else
  bindir=`pwd $0`
  samtools=${bindir}/../../tools/samtools-1.3/bin/samtools
fi
chrom=`basename ${sort_markdup_bam} | cut -d '.' -f 4`

#=============================================================================#

${samtools} view -h -F 0x400 ${sort_markdup_bam} \
  | awk -F $'\t' '($1!~/#0_0_0$/){print}' \
  | awk -F $'[#\t]' '($1!~/^@/){print $1,$2,$4,$5,$6}' OFS="\t" \
  | sort -V -k2,2 -k 4,4 \
  | awk -F $'\t' -v chr=${chrom} -v split_dist=${frag_split_distance} '{
    if(NF==5 && $5>=30){
      barcode=$2
      pos=$4
      if(prev_barcode==""){
        count=1
        subid=1
        minpos=pos
        maxpos=pos
      }
      else if(barcode==prev_barcode){
        if(pos < prevpos){print NR, "error" > "output_"chr".txt"; exit}
        else if(pos-prevpos<=split_dist){
          maxpos=pos
          count++
        }
        else if(pos-prevpos>split_dist){
          print prev_barcode,subid,chr,minpos,maxpos,maxpos-minpos,count
          subid++
          count=1
          minpos=pos
          maxpos=pos
        }
      }
      else if (barcode!=prev_barcode){
        print prev_barcode,subid,chr,minpos,maxpos,maxpos-minpos,count
        subid=1
        count=1
        minpos=pos
        maxpos=pos
      }
      prev_barcode=barcode
      prevpos=pos
    }
  }' OFS="\t" \
  > ${outdir}/${name}.${chrom}.frag1.txt
  
