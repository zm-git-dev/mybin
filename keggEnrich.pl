#!/usr/bin/perl -w
use strict;
use Getopt::Long qw /:config no_ignore_case/;
use File::Basename;

=pod

yangchao@macrogencn.com   on  2017-04-18

USAGE: keggEnrich.pl

-l --blast [FILE]  	blast file

-b --bg [FIlE]		background file

-f --fg  [FILE]  		foreground file

-k --kegg_dir [DIR]		[ /MGCN/Databases/KEGG ]

-n --nodisease

-s --species [STR]	[all]|animal|plant|archaea|bacteria|fungi|micro|protist|other

-o --output <STR>		output prefix     

-O --out_dir <DIR>		output DIR [ "./" ]

-r --first_N_row [INT]		[ 20 ]

-e --edge [STR]		near edge species short name ,such as : hsa , ath 		

-q --qvalue 

-i --no_diff

-h --help

EXAMPLE:

 get background file:

 keggEnrich.pl  -l blastout.txt  -s plant  -e ath  -n  -o prefix  
 
 kegg enrichment :

 keggEnrich.pl  -f file.fg  -b  file.bg -o prefix    [ -i -q  -r row_num ]

=cut

my %opts=(
	k => '/MGCN/Databases/KEGG',
	s => 'all',
	r => 20,
	O => ".",
);
GetOptions(\%opts,
	"h|help",
	"f|fg=s",
	"b|bg=s",
	"l|blast=s",
	"k|kegg_dir=s",
	"n|nodisease",
	"s|species=s",
	"o|output=s",
	"O|out_dir=s",
	"e|edge=s",
	"r|first_N_row=i",
	"q|qvalue",
	"i|no_diff",
);
$opts{s}="\L$opts{s}\E";
$opts{s}= "all" unless $opts{s} =~ /^(animal|plant|archaea|bacteria|fungi|micro|protist|other)$/;
$opts{O}=~s/\/$//g;
system "mkdir -p $opts{O}";
die `pod2text $0` if($opts{h} or !$opts{o} or !$opts{l} && (!$opts{f} || !$opts{b})  );
die "option -o can not contain directory!" if($opts{o}=~/\// );
if($opts{b}){
	my $basename=basename $opts{b};
	$basename=~s/\.\w+$//;
	die "option --output can not be same as the basename of option --bg" if( $basename and $basename eq $opts{o});
}

my %edge;
if($opts{e}){
	open IN,"<$opts{k}/near_edge_species.ko.list" or die $!;
	while(<IN>){
		chomp;
		my @F=split /\t/;
		next unless $F[0] eq $opts{e};
		for my $ko(split /,/,$F[1]){
			$edge{$ko}++;
		}
	}
	close IN;
}

open IN,"<$opts{k}/map_title.tab" or die $!;
my (%title,%disease);
while(<IN>){
	chomp;
	next if $.==1;
	my @F=split /\t/;
	$title{$F[0]}="$F[1]\t$F[2]\t$F[3]";
	$disease{$F[0]}++ if $F[1] eq "Human Diseases";
}
close IN;

my ($fg_gene_num,$bg_gene_num);
my (%ko);
if($opts{l}){
	my %id2ko;
	open IN,"<$opts{k}/map_class/$opts{s}.tab" or die $!;
	while(<IN>){
		chomp;
		next if $.==1;
		my @F=split /\t/;
		my $str;
		for my $ko(split /,/,$F[2]){
			next if ($opts{e} && !$edge{$ko}  or  $opts{n} && $disease{$ko});
			$str.= $str ? ",$ko" : $ko;
		}
		next unless $str;
		$id2ko{$F[0]}="$F[1]\t$str\t$F[0]";
	}
	close IN;
	
	open IN,"<$opts{l}" or die $!;
	open OUT,">$opts{O}/$opts{o}.kegg.bg" or die $!;
	my %has;
	while(<IN>){
		chomp;	
		my @F=split /\t/;
		next if $has{$F[0]};
		$has{$F[0]}++;
		if($id2ko{$F[1]}){
			print OUT "$F[0]\t$id2ko{$F[1]}\n";
		}
	}
	close IN;
}else{
	open IN,"<$opts{f}" or die $!;
	my %fg;
	while(<IN>){
		chomp;
		my @F=split /\t/;
		$fg{$F[0]}++;
		$fg_gene_num++;
	}
	close IN;
	open IN,"<$opts{b}" or die $!;
	open OUT,">$opts{O}/$opts{o}.kopath.txt" or die $!;
	print OUT "GeneID\tKO\tko\tkeggid\n";
	while(<IN>){
		chomp;
		my @F=split /\t/;
		$bg_gene_num++;
		print OUT "$_\n" if  $fg{$F[0]};
		for my $k(split /,/,$F[2]){
			$ko{bg}{$k}{$F[0]}=$F[1];
			if($fg{$F[0]}){
				$ko{fg}{$k}{$F[0]}=$F[1];
			}
		}
		
	}
	close IN;

	system "txt_to_excel.pl -f  -s  tab -r 1  -n $opts{o} $opts{O}/$opts{o}.kopath.txt" ;
	open R,">__$$.R" or die $!;
	for my $k(sort keys %{$ko{fg}}){
		my $m= scalar keys %{$ko{bg}{$k}};
		my $n= $bg_gene_num - $m;
		my $x= (scalar keys %{$ko{fg}{$k}})-1;
		print R "phyper($x,$m,$n,$fg_gene_num,lower.tail=F)\n";
	}
	close R;
	my %pq;
	my @pvalues= split /\n/,`Rscript __$$.R | awk '{print \$2}' 2> /dev/null  ` ;
	my $p=join ",",@pvalues;
	open R,">__$$.R" or die $!;
	print R<<R;
library(qvalue)
p <- c($p)
q <- qvalue(p,lambda=0)
q\$qvalues
R
	close R;
	my @qvalues= split /\n/,`Rscript __$$.R 2> /dev/null |awk '{for(x=2;x<=NF;x++) print \$x}' `;
	my $i=0;
	for my $k(sort keys %{$ko{fg}}){
		$pq{$k}{p}=$pvalues[$i];
		$pq{$k}{q}=$qvalues[$i];
		$i++;
	}
	system "rm __$$.R";
	my %kegg;
	open OUT,">$opts{O}/$opts{o}.path.txt" or die $!;
	print OUT "KEGG_A_class\tKEGG_B_class\tPathway\tDEG Num($fg_gene_num)\tAllGeneNum($bg_gene_num)\tRichFactor\tPvalue\tQvalue\tPathwayID\tGenes\tKOS\n";
	for my $k(sort {$pq{$a}{p}<=>$pq{$b}{p}} keys %pq){
		my ($genes,$KOs);
		my @arr=split /\t/,$title{$k};
		for my $gene(sort keys %{$ko{fg}{$k}}){
			my $tmp=$ko{fg}{$k}{$gene};
			$genes.= $genes ? "; $gene" : $gene;
			$KOs  .= $KOs   ? " + $tmp"  : $tmp;
			$kegg{$arr[0]}{$arr[1]}{$gene}++;
		}
		my $n1=scalar keys %{$ko{fg}{$k}};
		my $n2=scalar keys %{$ko{bg}{$k}};
		my $richFactor= $n1/$n2;
		if(!$title{$k} or ! $n1 or !$n2 or !$richFactor or !$pq{$k}{p} or !$pq{$k}{q} or !$k or !$genes or !$KOs){
			print STDERR ":$title{$k}:$n1:$n2:$richFactor:$pq{$k}{p}:$pq{$k}{q}:$k:$genes:$KOs\n";
		}
		print OUT "$title{$k}\t$n1\t$n2\t$richFactor\t$pq{$k}{p}\t$pq{$k}{q}\tko$k\t$genes\t$KOs\n";
	}
	close OUT;
	system "txt_to_excel.pl -f -s tab -r 1  -n $opts{o} $opts{O}/$opts{o}.path.txt";
	my $v= $opts{q} ? 'Qvalue' : 'Pvalue';
	&plotGradient($v);
	open OUT,">$opts{O}/$opts{o}.tmp" or die $!;
	for my $A(sort keys %kegg){
		for my $B(sort{ scalar keys %{$kegg{$A}{$a}} <=> scalar keys %{$kegg{$A}{$b}} } keys %{$kegg{$A}}){
			my $num= scalar keys %{$kegg{$A}{$B}};
			print OUT "$A\t$B\t$num\n";
		}
	}
	close OUT;
	&plotBarplot();
	my $nodiff = $opts{i} ? "-n" : "";
	system "keggMap.pl -k $opts{O}/$opts{o}.kopath.txt  -l  $opts{f} -o $opts{O}/$opts{o}\_map  $nodiff ";
	&getHTML;
}

sub plotGradient{
	my $value=shift @_;
	open OUT,">__$$.R" or die $!;
	print OUT<<R;
library("ggplot2")
dat <- read.csv("$opts{O}/$opts{o}.path.txt",sep="\\t",check.names=F)
colnames(dat) <- c("A","B","Pathway","GeneNum","AllGeneNum","RichFactor","Pvalue","Qvalue","PathwayID","Genes","KOs")
n <- nrow(dat)
if(n >$opts{r}){
	dat <- dat[1:20,]
}
p <- ggplot(dat,aes(x=RichFactor,y=Pathway))+
	geom_point(aes(size=GeneNum,color=$value))+
	scale_color_continuous("$value",low="red",high="blue")+
	scale_size("GeneNumber")+
	labs(title="Top $opts{r} of Pathway Enrichment",x="RichFactor",y="Pathway")+
	theme_bw()
ggsave(file="$opts{O}/$opts{o}.Bubble.png",dpi=300)
R
	system "Rscript __$$.R";
	system "rm __$$.R";
}

sub plotBarplot{
	open OUT,">__$$.R" or die $!;
	print OUT<<R;
library("ggplot2")
dat <- read.csv("$opts{O}/$opts{o}.tmp",sep="\\t",header=F)
colnames(dat) <- c("A","B","Count")
n <- nrow(dat)
dat\$A <- factor(dat\$A,levels=rev(unique(dat\$A)))
dat\$B <- factor(dat\$B,levels=dat\$B)
m <- max(dat\$Count)

p <- ggplot(dat,aes(x=B,y=Count,label=Count))+
	geom_bar(stat="identity",aes(fill=A))+
	coord_flip()+
	geom_text(nudge_y=0.05*m,size=4)+
	labs(x="",y="Number of Genes",fill="",title="KEGG pathway annotation")+
	theme_bw()+
	theme(legend.key.width=unit(0.1,"cm"),legend.key.height=unit(3,"cm"),legend.text=element_text(angle=270,size=5),legend.text.align=0.5 )
ggsave(file="$opts{O}/$opts{o}.Barplot.png",dpi=300)
R
	system "Rscript __$$.R";
	system "rm __$$.R $opts{O}/$opts{o}.tmp";
}

sub getHTML{
	my $code= <<HTM;
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<title>$opts{o}</title>
<style type="text/css">
	a {
		text-decoration : none;
		outline: none;
		hide-focus: expression(this.hideFocus=true);
	}
	a:hover {
		color: #FF0000;
		text-decoration:none;
		outline:none;
		hide-focus: expression(this.hideFocus=true);
	}
	body {
		font-size: 12px;
		font-family: "Microsoft YaHei","微软雅黑","雅黑宋体","新宋体","宋体","Microsoft JhengHei","华文细黑",STHeiti,MingLiu;
		background-color: #FFFFFF;
		padding-left: 8%;
		padding-right: 8%;
	}
	table{
		width=: 100%;
		boder: 0px;
		border-top: 4px #009933 solid;
		border-bottom: 4px #009933 solid;
		text-align: center;
		border-collapse: collapse;
		caption-side: top;
	}
	th {
		border-bottom: 2px #009933 solid;
		padding-left: 5px;
		padding-right: 5px;
	}
	td{
		padding-left: 5px;
		padding-right: 5px;
	}
	table caption {
		font-weight: bold;
		font-size: 16px;
		color: #009933;
		margin-bottom: 8px;
	}
	#backtop{
		font-size: 16px;
		position: fixed;
		bottom: 5%;
		right: 2%;
	}
</style>
<script type="text/javascript">
function reSize2(){
	try{
		parent.document.getElementsByTagName("iframe")[0].style.height=document.body.scrollHeight+10;
		parent.parent.document.getElementsByTagName("iframe")[0].style.height=parent.document.body.scrollHeight;
	}catch(e){

	}
}

function colorRow(trObj){
	trObj.style.backgroundColor="FF9900";
}

function diffColor(tables){
	color=["#FFFFFF","#CCFF99"];
	for (i=0; i<tables.length; i++){
		trObj=tables[i].getElementsByTagName("tr");
		for (j=1; j<trObj.length; j++){
			trObj[j].style.backgroundColor= color[j % color.length];
		}
	}
}

function markColor(table){
	trs=table.getElementsByTagName("tr");
	for(i=1;i<trs.length;i++){
		if(table.rows[i].cells.length>4){
			if(table.rows[i].cells[5].innerHTML <= 0.05){
				table.rows[i].cells[5].style.color="#FF0000";
				table.rows[i].cells[5].style.fontWeight="900";
			}
			if(table.rows[i].cells[6].innerHTML <= 0.05){
				table.rows[i].cells[6].style.color= "#FF0000";
				table.rows[i].cells[6].style.fontWeight='900';
			}
		}
	}
}

function showPer(tableObj) {
        trObj = tableObj.getElementsByTagName("tr");
        if (trObj.length < 2) {
                return;
        }
        sum1 = trObj[0].cells[2].innerHTML.replace(/^.*\\(([\\d]+)\\).*\$/, "\$1");
        if (trObj[0].cells.length > 4) {
                sum2 = trObj[0].cells[3].innerHTML.replace(/^.*\\(([\\d]+)\\).*\$/, "\$1");
        }
        if (trObj[0].cells.length > 4) {
                trObj[0].cells[2].innerHTML = "DEGs genes with pathway annotation (" + sum1 + ")";
                trObj[0].cells[3].innerHTML = "All genes with pathway annotation (" + sum2 + ")";
        }else{
                trObj[0].cells[2].innerHTML = "All genes with pathway annotation (" + sum1 + ")";
        }
        for (i = 1; i < trObj.length; i++) {
                trObj[i].cells[2].innerHTML += " (" + (Math.round(trObj[i].cells[2].innerHTML * 10000/ sum1) / 100) + "%)";
                if (trObj[0].cells.length > 4) {
                        trObj[i].cells[3].innerHTML += " (" + (Math.round(trObj[i].cells[3].innerHTML * 10000/ sum2) / 100) + "%)";
                }
        }
}


window.onload=function(){
	setTimeout("reSize2()",1);
}
</script>
HTM
	open IN,"<$opts{O}/$opts{o}.path.txt" or die $!;
	chomp (my $line=<IN>);
	my @head=split /\t/,$line;
	my $index=0;
	$head[3]=~s/DEG Num\((\d+)/DEGs genes with pathway annotation\($1/;
	my $fg_n=$1;
	$head[4]=~s/AllGeneNum\((\d+)/All genes with pathway annotation\($1/;
	my $bg_n=$1;

	$code.="</head><body><table><caption>$opts{o} Pathway Enrichment</caption><tr><th>#</th><th>". (join "</th><th>",@head[2..8]) ."</th></tr>";
	my $table2="<p><br/></p>\n<table>\n<caption>Pathway Detail</caption>\n<tr><th>#</th><th>Pathway</th><th>Differentially expressed genes</th></tr>\n";
	while(<IN>){
		chomp;
		next if /^\s*$/;
		$index++;
		my @F=split /\t/;
		$F[-4]=sprintf("%.6f",$F[-4]);
		$F[-5]=sprintf("%.6f",$F[-5]);
		$F[5]=sprintf("%.4f",$F[5]);
		my $g1=sprintf("%.2f",100*$F[3]/$fg_n);
		my $g2=sprintf("%.2f",100*$F[4]/$bg_n);
		$code.="<tr><td>$index</td><td style='text-align: left;'><a href='#gene$index' title='click to view genes' onclick='javascript: colorRow(document.getElementsByTagName(\"table\")[1].rows[$index]);'>$F[2]</a></td><td>". (join "</td><td>","$F[3] ($g1\%)","$F[4] ($g2\%)", @F[5..8])."</td></tr>";
		(my $map=$F[8])=~s/ko/map/;
		$table2.="<tr><td>$index</td><td style='text-align: left;'>\n";
		$table2.= -f "$opts{O}/$opts{o}\_map/$map.html" ? "<a href='$opts{o}\_map/$map.html' title='click to view map' target='_blank'>$F[2]</a>" : "$F[2] (no map in kegg database)";
		$table2.="</td><td style='text-align: left;'><a name='gene$index'>$F[-2]</a></td></tr>\n";
	}
	close IN;
	my $diff="<script type='text/javascript'>\ndiffColor([document.getElementsByTagName('table')[0],document.getElementsByTagName('table')[1]]);markColor(document.getElementsByTagName('table')[0]);    </script>";
	$code.="</table>$table2</table><div id='backtop'><a href='#'>Back Top</a></div>$diff</body></html>";
	open  HTML,">$opts{O}/$opts{o}.html" or die $!;
	print HTML "$code";
	close HTML;
	
}
