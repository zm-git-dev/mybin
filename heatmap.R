library(gplots)
library(ggplot2)

pdf("heatmap.pdf")
pathway=c("GPCR pathway","MAPK pathway","Wnt pathway","Hippo-YAP pathway","Integrin pathway","Transcription factors","Associated with Cajal")
setwd("/home/mgcn/work/project/zhaolijun/")
data <- read.table("diff_gene_fpkm_multi.txt", sep="\t",header = T)
  da=data
  rownames(da)=da$name
  da=da[,c(2,3)]
  da=as.matrix(da)
  x=as.matrix( log2(da+1)  )
  heatmap.2(x,Rowv=F,Colv=F,col=colorpanel(80,"green","white","red"),,srtCol =0,adjCol=c(0,0) ,RowSideColors = c(rep(rainbow(7),times=c(16,7,8,11,14,25,23)) ),scale="none", key=TRUE, density.info="none", trace="none", cexRow=0.5,cexCol=1, margins=c(2,10),colRow =c(rep(rainbow(7),times=c(16,7,8,11,14,25,23)) )  )
  heatmap.2(x,Rowv=F,Colv=F,col=colorpanel(80,"green","white","red"),,srtCol =0,adjCol=c(0,0) ,RowSideColors = c(rep(rainbow(7),times=c(16,7,8,11,14,25,23)) ),scale="column", key=TRUE, density.info="none", trace="none", cexRow=0.5,cexCol=1, margins=c(2,10),colRow=c(rep(rainbow(7),times=c(16,7,8,11,14,25,23)) ) )
  

dev.off()