#!/usr/bin/perl -w
use strict;
use Getopt::Long qw/:config no_ignore_case/;
use File::Basename;
use GO::OntologyProvider::OboParser;
use SVG;
use List::Util qw(max);

=pod

yangchao@macrogencn.com   on  2017-04-18

USAGE: GOEnrich.pl

-l --blast [FILE]  	blast file

-b --bg [FIlE]		background file

-f --fg  [FILE]  		foreground file

-g --go_dir [DIR]		[ /MGCN/Databases/GO/GO_June2016 ]

-o --output <STR>		output prefix     

-O --out_dir <DIR>	 	output DIR [ "." ]

-r --first_N_row [INT]		[ 9 ]

-a --ancestor		

-i --no_diff

-h --help

EXAMPLE:

 get background file:

 GOEnrich.pl  -l blastout.txt   -o prefix [-a] 

 GO enrichment :

 GOEnrich.pl  -f file.fg  -b  file.bg -o prefix    [ -i  ]

=cut

my %opts=(
	r => 9,
	go_dir => "/MGCN/Databases/GO/GO_June2016",
	O => ".",
);
GetOptions(\%opts,
	"h|help",
	"f|fg=s",
	"b|bg=s",
	"l|blast=s",
	"o|output=s",
	"O|out_dir=s",
	"r|first_N_row=i",
	"a|ancestor",
	"i|no_diff",
	"g|go_dir=s",
);
die `pod2text $0` if($opts{h} or !$opts{o} or !$opts{l} && (!$opts{f} || !$opts{b}));
$opts{O}=~s/\/$//g;
system "mkdir -p $opts{O}";
if($opts{b}){
	my $basename=basename $opts{b};
	$basename=~s/\.\w+$//;
	die "option --output can not be same as the basename of option --bg" if( $basename and $basename eq $opts{o});
}


my ($fg_gene_num,$bg_gene_num);
my (%go);
if($opts{l}){
	my %obo;
	for my $on( qw /F C P/){
		$obo{$on}=GO::OntologyProvider::OboParser->new(ontologyFile => "$opts{go_dir}/go-basic.obo", aspect=>"$on");
	}
	
	open IN,"<$opts{l}" or die $!;
	open OUT,">$opts{O}/$opts{o}.go.bg" or die $!;
	my %has;
	my %id2term;
	while(<IN>){
		chomp;	
		my @F=split /\t/;
		next if $has{$F[0]};
		my @go= /(GO:\d{7})/g;
		$has{$F[0]}++;
		my %ids;
		for my $g(@go){
			for my $on(qw /C F P/){
				my $node=$obo{$on}->nodeFromId($g);
				next unless $node;
				my @nodes=($node);
				push @nodes,$node->ancestors if $opts{a};
				for my $n(@nodes){
					my $id=$n->goid;
					$ids{$id}++;
					$id2term{$id}= "$on\t".$n->term if !$id2term{$id};
				}
			}
		}
		for my $g(sort keys %ids){
			print OUT "$F[0]\t$g\t".$id2term{$g}."\n";
		}
	}
	close IN;
}
else{
	open IN,"$opts{go_dir}/secondLevel" or die $!;
	my %secondLevel;
	while(<IN>){
		chomp;
		my @F=split /\t/;
		$secondLevel{$F[1]}++;
	}
	close IN;
	
	open IN,"<$opts{f}" or die $!;
	my %fg;
	while(<IN>){
		chomp;
		my @F=split /\t/;
		$fg{$F[0]}=$F[1];
		$fg_gene_num++;
	}
	close IN;
	open IN,"<$opts{b}" or die $!;
	my %all_gene;
	my %annot;
	while(<IN>){
		chomp;
		my @F=split /\t/;
		$all_gene{$F[0]}++;
		$go{bg}{$F[1]}{$F[0]}++;
		$annot{$F[1]}="$F[2]\t$F[3]" if !$annot{$F[1]};
		$go{fg}{$F[1]}{$F[0]}++ if $fg{$F[0]};
		$go{sl}{$F[2]}{$F[1]}{$F[0]}=$F[3] if( $secondLevel{$F[1]} and $fg{$F[0]});
	}
	close IN;
	$bg_gene_num= scalar keys %all_gene;
	
	open OUT,">$opts{O}/$opts{o}.secondLevel.txt" or die $!;
	if($opts{i}){
		print OUT "Ontology\tCategory\tTerm\tGene_Num\tGenes\n";
	}else{
		print OUT "Ontology\tCategory\tTerm\tUP_Gene_Num\tDown_Gene_Num\tUP_Genes\tDown_Genes\n";
	}
	my $sl_count=0;
	for my $on(sort keys %{$go{sl}}){
		for my $c(sort keys %{$go{sl}{$on}}){
			$sl_count++;
			my (@up,@down,@genes);
			@genes=sort keys %{$go{sl}{$on}{$c}};
			my $term=$go{sl}{$on}{$c}{$genes[0]};
			if($opts{i}){
				print OUT "$on\t$c\t$term\t". scalar @genes ."\t". ( join ";",@genes) ."\n";
			}else{
				for my $gene(@genes){
					push @up,$gene if $fg{$gene}>0;
					push @down,$gene if $fg{$gene}<0;
				}
				print OUT "$on\t$c\t$term\t". scalar @up ."\t". scalar @down ."\t".(join ";",@up)."\t".(join ";",@down)."\n";
			}
		}
	}
	close OUT;
	system "txt_to_excel.pl  -s tab -r 1 -f  -n '$opts{o}' $opts{O}/$opts{o}.secondLevel.txt";
	#print STDERR "$sl_count\n";
	&plotSecondLevel ;
	
	&plot_go;
}

sub plot_go{
	open  OUT,">__$$.R" or die $!;
	print OUT <<R;
library(clusterProfiler)
all <- read.csv("$opts{b}",header=F,sep="\\t",quote="")
for (t in c("MF","BP","CC")){

s <- substring(t,2,2)
sub <- all[  all[,3]== s,]
fg <- read.csv("$opts{f}",header=F,sep="\\t",quote="")

bg_gene <- unique( sub[,1])
fg_gene <- fg[,1]
term2gene <- sub[,c(2,1)]
term2name <- sub[,c(2,4)]

ego <- enricher(fg_gene,universe=bg_gene,minGSSize=1,pAdjustMethod="none",  TERM2GENE=term2gene,TERM2NAME=term2name,pvalueCutoff=1,qvalueCutoff=1)
write.table(  summary(ego)[,-6][,-8] , paste("$opts{O}/$opts{o}",t,'txt',sep=".") ,sep="\\t",row.names=F,quote=F)
ego <- enricher(fg_gene,universe=bg_gene,minGSSize=1,TERM2GENE=term2gene,TERM2NAME=term2name,pvalueCutoff=0.05,qvalueCutoff=1)
ego\@ontology= t

pdf(paste("$opts{O}/$opts{o}",t,'pdf',sep="."))
len <- length(rownames(summary( ego )))
if(len >0){

if(len > $opts{r} ){
	plotGOgraph(ego)
}else{
	plotGOgraph(ego,firstSigNodes=len)
}
dev.off()
}

}
	
R
	system "/usr/bin/Rscript __$$.R";
	system "rm __$$.R";
	my %map=(
		CC => "cellular component",
		BP => "biological process",
		MF => "molecular function",
	);
	opendir DIR,"$opts{O}" or die $!;
	my $str1;
	my $str2;
	for my $fi(readdir DIR){
	#	print STDERR "$fi\n";
		next unless $fi=~/^$opts{o}.*\.(BP|MF|CC)\.txt$/;
		$str1.= $str1 ? ",$1" : $1;
		$str2.= " $opts{O}/$fi ";
	}
	system "txt_to_excel.pl -s tab -r 1 -f  -o $opts{O}/$opts{o}.xlsx  $str2  " if $str1;
}

sub plotSecondLevel{
	open IN,"<$opts{O}/$opts{o}.secondLevel.txt" or die $!;
	<IN>;
	my %hash;
	my ($max,$row)=(1,0);
	my %map=(
		C => "Cellular Component",
		P => "Biological Process",
		F => "Molecular Function",
	);
	while(<IN>){
		chomp;
		my @F=split /\t/;
		if($opts{i}){
			$hash{ $map{$F[0]} }{$F[2]}="$F[3]";
			$max=max($max,$F[3]);
		}else{
			$hash{ $map{$F[0]}  }{$F[2]}="$F[3]\_$F[4]";
			$max=max($max,$F[3],$F[4]);
		}
		$row++;
	}
	close IN;
	return 1 if $row <=2;
	my $title="Level 2 GO terms of $opts{o}";
	my $width= $opts{i} ? 1600/($row*2+1) : 1600/($row*3+1);
	my $font_size=$width*2/3;
	my $divisor= $max<=5 ? $max : $max<=20 ? 3 : $max<=100 ? 4 : 5;
	my $remainder=$max % $divisor;
	my $max_1 =  $remainder==0 ? $max : $max+$divisor-$remainder;
	my $height=500/$max_1;

	my $svg=SVG->new(width=>2100,height=>1000);
	$svg->line(x1 => 300, y1 => 95, x2 => 300, y2 => 605, stroke=>'black',"stroke-width"=>2);
	$svg->line(x1 => 300, y1 => 605, x2 => 1900, y2 => 605, stroke=>'black',"stroke-width"=>2);
	$svg->line(x1 => 1900, y1 => 95, x2 => 1900, y2 => 605, stroke=>'black',"stroke-width"=>2);
	$svg->line(x1 => 300, y1 => 95, x2 => 1900, y2 => 95, stroke=>'black',"stroke-width"=>2);
	$svg->line(x1 => 125, y1 => 900, x2 => 1725, y2 => 900, stroke=>'black',"stroke-width"=>2);
	
	for my $ii( 0 .. $divisor){
		my $each_height= 500/$divisor;
		my $yi=600-$ii*$each_height;
		my $out_i = $ii*$max_1/$divisor;
		$svg->line(x1=>295,y1=>$yi,x2=>300,y2=>$yi,stroke=>'black','stroke-width'=>2);
		$svg->text(x => 280, y => $yi, width => $width, height => 50, "font-family"=>"Arial", "text-anchor"=>"end","font-size"=> "18", "-cdata" => "$out_i");
	}
	
	$svg->text(x => 210, y => 350, width => 30, height => 50, "font-family"=>"Arial", "text-anchor"=>"middle","font-size"=> "25", "-cdata" => "Num of Genes","transform"=>"rotate(-90, 210, 350)");
	my $title_x = (2100 - length($title)) / 2;
	$svg->text(x => $title_x, y => 50, width => 50, height => 30, "font-family"=>"Arial", "text-anchor"=>"middle","font-size"=> "25", "-cdata" => "$title");
	
	if ( !$opts{i} ){
		$svg->rect(x => 1920, y => 100, width => 15, height => 15, fill => "red");
		$svg->text(x => 1940, y => 112, width => 15, height => 15, "font-family"=>"Arial", "text-anchor"=>"start","font-size"=> "18", "-cdata" => "up");
		$svg->rect(x => 1920, y => 130, width => 15, height => 15, fill => "green");
		$svg->text(x => 1940, y => 142, width => 15, height => 15, "font-family"=>"Arial", "text-anchor"=>"start","font-size"=> "18", "-cdata" => "down");
	}

	my $x = 300;
	my $locus=125;
	my $xx;
	my @col=("green","red","blue");
	my $Col;
	for my $k ( sort keys %hash ){
		$xx = $x-175;
		$svg->line(x1 => 300, y1 => 605, x2 => 125, y2 => 900, stroke=>'black',"stroke-width"=>2);
		my $mark_1=$x;
		$Col=shift@col;
		for my $i ( sort keys %{$hash{$k}} ){
			$x+=$width;
			if ( $opts{i} ){
				my ($H,$h,$x1);
				$h = $hash{$k}{$i}*$height;
				$x1 = $x+$width/2;
				$H = 600-$h;
				$svg->rect(x => $x, y => $H, width => $width, height => $h, fill => "$Col");
				$svg->line(x1 => $x1, y1 => 605, x2 => $x1, y2 => 610, stroke=>'black',"stroke-width"=>2);
				$svg->text(x => $x1, y => 620, width => $width, height => 50, "font-family"=>"Arial", "text-anchor"=>"end","font-size"=> "15", "-cdata" => "$i","transform"=>"rotate(-60, $x1, 620)");
				$x+=$width;
			}else{
				my @array = split /\_/,$hash{$k}{$i};
				my ($x1,$H1,$h1,$H2,$h2);
				$H1 = 600-$array[0]*$height;
				$h1 = $array[0]*$height;
				$H2 = 600-$array[1]*$height;
				$h2 = $array[1]*$height;
				$x1 = $x+$width/2;
				$svg->rect(x => $x, y => $H1, width => $width, height => $h1, fill => "red");
				$x+=$width;
				$x1 = $x+$width/2;
				$svg->line(x1 => $x, y1 => 605, x2 => $x, y2 => 610, stroke=>'black',"stroke-width"=>2);
				$svg->text(x => $x, y => 610, width => $width, height => 50, "font-family"=>"Arial", "text-anchor"=>"end","font-size"=> "14", "-cdata" => "$i","transform"=>"rotate(-60, $x1, 620)");
				$svg->rect(x => $x, y => $H2, width => $width, height => $h2, fill => "green");
				$x+=$width;
			}
		}
		my $x1 = $x+$width;
		my $x2 = $x1-175;
		$locus = $locus+($x1-$mark_1)/2;
		$svg->text(x => $locus, y => 950, width => 30, height => 50, "font-family"=>"Arial", "text-anchor"=>"middle","font-size"=>22,"-cdata" => "$k");
		if ( $x1 eq "1900" ){
			$svg->line(x1 => 1900, y1 => 605, x2 => $x2, y2 => 900, stroke=>'black',"stroke-width"=>2);
		}else{
			my $x3=$x1-$width/2;
			$svg->line(x1 => $x3, y1 => 605, x2 => $x2, y2 => 900, stroke=>'black',"stroke-width"=>2);
		}
		$locus = $locus+($x1-$mark_1)/2;
	}

	my $out = $svg->xmlify;
	open OUT,">$opts{O}/$opts{o}.secondLevel.svg";
	print OUT $out;
	close OUT;
	
	`convert -density 300 $opts{O}/$opts{o}.secondLevel.svg $opts{O}/$opts{o}.secondLevel.png`;
}

sub plotHTML{
	
}

