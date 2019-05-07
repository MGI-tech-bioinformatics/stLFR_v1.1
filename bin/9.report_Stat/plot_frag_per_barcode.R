args<-commandArgs(TRUE)

frag_per_barcode_file=args[1]
outpdf=args[2]

frag_per_barcode_data=read.table(frag_per_barcode_file,stringsAsFactors = F,header = T)

library(ggplot2)

pdf(outpdf)
ggplot(data=subset(frag_per_barcode_data,total_min5000frag_count<=15))+
  geom_histogram(aes(x=total_min5000frag_count,stat(density)),binwidth = 1)+
  xlab("fragment per barcode")+
  theme_bw()

dev.off()


