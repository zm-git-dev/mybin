ARGV=commandArgs()
library(ggplot2)


da=read.table(ARGV[6],sep="\t")
da=da[,c(2,4,5,8)]
colnames(da)= c("count","class","term","Percent")
da$term=rev( factor(da$term,levels=da$term ) )
pdf("GO_barplot.pdf")
ggplot(data=da,aes(y=Percent,x=term,label=da$count) )+
	geom_bar(stat="identity",aes(fill=class) )+
	scale_y_log10()+
	coord_flip()+
	geom_text(nudge_y=6,size=2)+
	labs(x="GO term",y="Percent of Genes",fill="")
		
dev.off()

