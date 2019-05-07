args = commandArgs(TRUE)

indir  = args[1]
output = args[2]
xmax = 100
ymax = 2

sample = list.files( indir )
col = rainbow(9)

pdf(output, height = 6, width = 8)
par(font.lab = 1, font.axis = 1, cex.lab = 1.2, cex.axis = 1.2, mar=c(3.5, 3.5, 1.5, 1), mgp=c(2, 0.7, 0))
for(i in 1:length(sample)){
	file <- paste(indir, "/", sample[i], "/", sample[i], ".gcbias.xls", sep = "")
	data <- read.table(file, head = T)

  data <- subset(data, WINDOWS >= 1000)
  rate <- as.numeric(data[,2]) / sum(as.numeric(data[,2]))

	if( i > 1 ){
        par(new=T)
        plot(x = data[,1], y = data[,5], xlim = c(0, xmax), ylim = c(0, ymax), col = col[i], type = "p", lwd = 2, pch = 19, cex = 0.8, axes=F, ann = F)
    }
    else{
        plot(x = data[,1], y = data[,5], xlim = c(0, xmax), ylim = c(0, ymax), col = col[i], type = "p", lwd = 2, pch = 19, cex = 0.8, xlab = "GC (%)", ylab = "Normalized Coverage", main = "GC bias Curve of Genome")
        abline(h=c(0.5, 1, 1.5), col = "grey", lty = 2)
        par(new=T)
        plot(x = data[,1], y = rate * 10, xlim = c(0, xmax), ylim = c(0, ymax), col = rgb(1, 170/255,170/255), lwd = 5, axes = F, ann = F, type = "h")
    }
}
ncol = floor(length(sample)/5)+1
legend("topleft", col = col, sample, pch = 19, bty = "n", ncol = 1, cex = 0.8)
dev.off()

