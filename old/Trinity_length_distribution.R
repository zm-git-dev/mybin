pdf("length_distribution.pdf")
val <- expression(NULL >= 2000) 
file=c("gene.txt","transcript.txt","ORF.txt")
name=c("Gene","Transcript","ORF")
myxlab=c("(bp)","(bp)","(aa)")
mycol=c("purple","blue","red")
for (i in 1:3){
  da=read.table(file[i],header=F,sep="\t")
  myymax=max(da[,2])+1000
  da=as.matrix(da)
  
  barplot(da[,2],space=0,main=paste("Distribution of",name[i],"Length",sep=" "),col=mycol[i],xlab=paste("Length",myxlab[i],sep=""),ylim=c(0,myymax),legend.text="count" )
  box()
  axis(side=1,at=c(0,4,8,12,16,20.5),labels=c(0,400,800,1200,1600,val),tick=F)
}
dev.off()
