args<-commandArgs(TRUE)

frag_file=args[1]
outpdf=args[2]

frag_data=read.table(frag_file,header = T,stringsAsFactors = F)

read_len=100
frag_data$frag_cov=frag_data$readcount*100/frag_data$length

library(ggplot2)
pdf(outpdf)

ggplot(data=subset(frag_data,frag_cov<=0.5))+
  geom_histogram(aes(x=frag_cov,y=stat(width*density)),binwidth=0.02)+
  xlab("coverage for each long fragment")+
  theme_bw()

dev.off()
