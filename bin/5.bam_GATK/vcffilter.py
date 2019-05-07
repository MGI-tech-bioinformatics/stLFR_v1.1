#!/usr/bin/env python

from __future__ import division
import vcf
import argparse as ap
import os

def main():
    args = get_options()
    vcf_reader = open_reader(args.infile)
    intfile, outfile = process_path(args.infile)
    vcf_writer = vcf.Writer(open(intfile, 'w'), vcf_reader)
    vcf_filter(vcf_reader, vcf_writer, args)
    vcf_writer.close()
    rewrite_header(intfile, outfile)
    remove_intfile(intfile)


def get_options():
    parser = ap.ArgumentParser(description='Filter a VCF file based on GQ and ref/alt ratio. Input VCF can be in bgzip format. The output VCFs Filter column will be marked with stLFR_SNP or stLFR_INDEL for filtered variants and will be unzipped.')
    parser.add_argument("infile", type=str, help="path to the VCF file to be filtered.")
    parser.add_argument("sample", type=str, help="name of VCF sample to be filtered")
    requiredNamed = parser.add_argument_group('required named arguments')
    requiredNamed.add_argument("-g", "--snp_gq_filter", type=int,\
                    help="GQ score over which snp records should be kept", required=True)
    requiredNamed.add_argument("-G", "--ind_gq_filter", type=int,\
                    help="GQ score over which indel records should be kept", required=True)
    requiredNamed.add_argument("-m", "--snp_ad_min", type=float,\
                    help="Minimum ref/alt ratio for SNP filtering", required=True)
    requiredNamed.add_argument("-M", "--ind_ad_min", type=float,\
                    help="Minimum ref/alt ratio for InDel filtering", required=True)
    requiredNamed.add_argument("-x", "--snp_ad_max", type=float,\
                    help="Maximum ref/alt ratio for SNP filtering", required=True)
    requiredNamed.add_argument("-X", "--ind_ad_max", type=float,\
                    help="Maximum ref/alt ratio for InDel filtering", required=True)
    return parser.parse_args()


def open_reader(infile):
    try:
        vcf_reader = vcf.Reader(filename = infile)
    except IOError:
        print "Cannot Open", infile
        raise
    else:
        return vcf_reader


def process_path(file):
    filename = file.split('/').pop()
    try:
        basename = '.'.join(filename.split('.')[0:filename.split('.').index('vcf')+1])
    except ValueError:
        print file, "is not a VCF (does not contain .vcf extension)"
        raise
    else:
        outname = 'filter.gq.ad.' + basename
        intname = outname + '.int'
        return intname, outname


def vcf_filter(vcf_reader, vcf_writer, args):
    filtered = 0
    processed = 0
    for record in vcf_reader:
        is_snp = check_var(record)
        if record.genotype(args.sample)['GT'] != "0/1":
            vcf_writer.write_record(record)
        else:
            if check_GQ(record, args, is_snp) and check_AD(record, args, is_snp):
                vcf_writer.write_record(record)
            else:
                if is_snp: record.FILTER = "stLFR_SNP"
                else: record.FILTER = "stLFR_INDEL"
                vcf_writer.write_record(record)
                filtered += 1
        processed += 1
        if processed%25000 == 0: print record.CHROM, "-", processed, "records processed,", filtered, "records filtered."
    print "VCF Filtering Completed"
    print processed, "records processed,", filtered, "records filtered."


def check_GQ(record, args, is_snp):
    if is_snp: GQfilter = args.snp_gq_filter
    else: GQfilter = args.ind_gq_filter
    if record.genotype(args.sample)['GQ'] >= GQfilter:
        return True
    else: return False


def check_AD(record, args, is_snp):
    if is_snp:
        ADmin = args.snp_ad_min
        ADmax = args.snp_ad_max
    else:
        ADmin = args.ind_ad_min
        ADmax = args.ind_ad_max
    ref = record.genotype(args.sample)['AD'][0]
    alt = record.genotype(args.sample)['AD'][1]
    if alt == 0:
        return False
    elif ref/alt >= ADmin and ref/alt <= ADmax:
        return True
    else: return False


def check_var(record):
    if len(record.REF) > 1 or len(record.ALT[0]) > 1:
        return False
    else: return True


def rewrite_header(intfile, outfile):
    print "Adding filter lines to header."
    filter_line = '##FILTER=<ID=stLFR_SNP,Description="Hard Filter for stLFR SNPs">\n'
    filter_line += '##FILTER=<ID=stLFR_INDEL,Description="Hard Filter for stLFR indels">\n'
    filter_written = False
    with open(intfile, 'r') as intvcf, open(outfile, 'w') as out:
        for line in intvcf:
            if line.startswith('#'):
                if (line.find('FILTER=<ID=') >= 0 or line.find('CHROM\tPOS') >= 0) \
                    and filter_written == False:
                        out.write(filter_line)
                        filter_written = True
                out.write(line)
            else:
                out.write(line)


def remove_intfile(intfile):
    print "Removing intermediate file."
    os.remove(intfile)
    print "Intermediate file removed."


if __name__ == "__main__":
    main()
