args<-commandArgs(TRUE)

indir = args[1]
outpt = args[2]

sample = list.files( indir )
pdf(outpt, height = 6, width = 8)
par(font.lab = 1, font.axis = 1, cex.lab = 1.2, cex.axis = 1.2, mar=c(3.5, 3.5, 1.5, 1), mgp=c(2, 0.7, 0))
col = rainbow(9)

ymax = 0
for ( i in 1:length(sample) ){
  file = paste(indir, "/", sample[i], "/depth_frequency.txt", sep = "")
  data = read.table( file, col.names=c("size", "count"), colClasses=c("numeric", "numeric") )
  data = subset(data, size > 0)
  ymax_sub = which(data$count==data$count[which.max(data$count)], arr.ind=T)
  ymax_sub = data[ymax_sub, 2] * 100
  if( ymax < ymax_sub ){
    ymax = ymax_sub
  }
}
if( ymax < 1 ){
  y_bin = 0.2
}else if( ymax < 5 ){
  y_bin = 1
}else if( ymax < 10 ){
  y_bin = 2
}else{
  y_bin = 5
}

xmax = 100
for ( i in 1:length(sample) ){
  file = paste(indir, "/", sample[i], "/cumu.txt", sep = "")
  data = read.table( file, col.names=c("size", "count"), colClasses=c("numeric", "numeric") )
  data = subset(data, size > 0)
  xmax_sub = which(data$count < 0.02, arr.ind=T)[1]
  xmax_sub = data[xmax_sub, 1]
  if( xmax < xmax_sub ){
    xmax = xmax_sub
  }
}
x_bin = 100
if( xmax > 100 ){
  xmax = (floor(xmax / x_bin) + 1) * x_bin
}

for ( i in 1:length(sample) ){
	file = paste(indir, "/", sample[i], "/depth_frequency.txt", sep = "")
	data = read.table( file, col.names=c("size", "count"), colClasses=c("numeric", "numeric") )
  data = subset(data, count > 0)

	if( i > 1 ){
		par(new=T)
		plot(x = data[,1], y = data[,2]*100, xlim = c(0, xmax), ylim = c(0, ymax), col = col[i], type = "l", lwd = 1.5,
			axes=F, ann = F)
	}
	else{
		plot(x = data[,1], y = data[,2]*100, xlim = c(0, xmax), ylim = c(0, ymax), col = col[i], type = "l", lwd = 1.5,
			xlab = "Depth", ylab = "Rate (%)", main = "", las = 1)
	}
}

legend("topright", col = col, sample, bty = "n", lwd = 2, lty = 1)

dev.off()

