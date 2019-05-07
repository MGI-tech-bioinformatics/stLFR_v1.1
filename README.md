# stLFR_v1.1

Introduction
-------
Tools of stLFR(Single Tube Long Fragment Reads) data analysis

stLFR FAQs is directed to bgi-MGITech_Bioinfor@genomics.cn.

Download source code package from https://github.com/MGI-tech-bioinformatics/stLFR_v1.1

Updates 
-------
May 6, 2019
There are severl updates in stLFR_v1.1:
1. Users could use an alternative reference type (hg19 or hs37d5) in stLFR_v1.1 by --ref option instead of only hg19.
2. Updated CNV and SV detection tools are implied in stLFR_v1.1 for decreasing false discovery rate.
3. Three figures, illustrating stLFR fragment distribution and coverage, are added.
4. NA12878 benchmark VCF by GIAB is used for haplotype phasing error calculation.

Download/Install
----------------
Due to the size limitation of GitHub repository, followed softwares need to be installed to the specific directory (stLFR_v1/tools):

1. HapCUT2-master; 2. R-3.5.2; 3. bam2depth; 4. cnv; 5. gatk-4.0.3.0;

6. jre1.8.0_101; 7. python3; 8. vcftools; 9. Python-2.7.14; 10. SOAPnuke-1.5.6; 

11. bwa; 12. fqcheck; 13. gnuplot-5.2.2; 14. picard; 15.samtools-1.3.

Furthermore, you need to download the following database to the specific directory:

1. hg19.fa (stLFR_v1.1/db/reference/hg19);

2. hg19.dbsnp.vcf (stLFR_v1.1/db/dbsnp);

3. hs37d5.fa (stLFR_v1.1/db/reference/hs37d5);

4. hs37d5.dbsnp.vcf (stLFR_v1.1/db/dbsnp);

5. phased vcf (stLFR_v1.1/db/phasedvcf).

Or you can download the above database and softwares from BGI Cloud Drive:

1. tools Link: https://pan.genomics.cn/ucdisk/s/B7Nryq
2. database Link: https://pan.genomics.cn/ucdisk/s/vmU3aq

Usage
-------
1. Make sure 'path' file on a right format, you can refer to 'path' file in the example.

2. Run the automatical delivery script.

        stLFR path
        stLFR path --ref hs37d5

Result
-------
After all analysis processes ending, you will get these files below:

1. Raw data and alignment summary: Alignment.statistics.xls 
2. Variant summary: Variant.statistics.xls 
3. GCbias figure: GCbias.pdf 
4. Insertsize figure: Insertsize.pdf 
5. Depth distribution figure: Sequencing.depthSequencing.depth.pdf 
6. Depth accumulation figure: Sequencing.depth.accumulation.pdf          
7. GCbias metrics: *.gcbias_metrics.txt，*.gcbias_summary_metrics.txt
8. Insertsize metrics: *.insertsize_metrics.txt
9. Phasing statistics only by SNP: Phasingcount.*.hapcut2.xls (compare with GIAB vcf)
10. Phasing statistics by SNP and InDel: Phasingcount.*.hapcut2_SNP+InDel.xls (compare with GIAB vcf)
11. Fragment coverage figure: *.frag_cov.pdf
12. Fragment length distribution figure: *.fraglen_distribution_min5000.pdf
13. Fragment per barcode distribution figure: *.frag_per_barcode.pdf



License
-------
Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions： 
  
The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
  
THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
