#!/usr/bin/perl -w 
use strict;
use Getopt::Long;
use File::Basename;
use GD;
use List::Util qw (max);
use Data::Dumper;

=pod

yangchao@macrogencn.com  on 2017-04-18

USAGE:  keggMap.pl  

-k --ko 

-l --list

-o --output

-n --nodiff

-d --dir 		[ /MGCN/Databases/KEGG/map ]

-h --help

=cut

my %opts=(
	d  => '/MGCN/Databases/KEGG/map',
);
GetOptions(\%opts,
	"k|ko=s",
	"l|list=s",
	"o|output=s",
	"d|dir=s",
	"n|nodiff",
	"h|help",
);

die `pod2text $0` if($opts{h} or !$opts{k}  or !$opts{o} or !$opts{n} && !$opts{l} );

$opts{o}=~s/\/$//;
system "mkdir -p $opts{o}";
my %gene2val;
if(!$opts{n}){
	open IN,"<$opts{l}" or die $!;
	while(<IN>){
		chomp;
		next if (/^#/ or /^\s*$/);
		my @F=split /\t/;
		next if @F !=2;
		$gene2val{ $F[0] }=$F[1];
	}
}
close IN;

open KO,"<$opts{k}" or die $!;
my %map;
my %html;
while(<KO>){
	chomp;
	next if (/^#/ or /^\s*$/);
	my @F=split /\t/;
	next if @F <3;
	for my $ko(split /,/,$F[2]){
		my $mapImg="$opts{d}/map$ko.png";
		next unless -f $mapImg;
		open CONF,"<$opts{d}/map$ko.conf" or die $!;
		while(<CONF>){
			chomp;
			my $col= ($opts{n} or  !$opts{n} && $gene2val{$F[0]}>0)? 'red' : 'green';
			if(/^rect\D+(\d+),(\d+)\D+(\d+),(\d+).*($F[1]|$F[3])/){
				push @{$map{$ko}{rect}},[$F[0],$1,$2,$3,$4,$col];
				$html{"map$ko"}{"$1,$2,$3,$4"}{$col}{$5}{$F[0]}=$opts{n}? 1 : $gene2val{$F[0]};
			}elsif(/^line\D+(\d+),(\d+)\D+(\d+),(\d+).*($F[1]|$F[3])/){
				push @{$map{$ko}{line}},[$F[0],$1,$2,$3,$4,$col];
				my ($p1,$p2,$p3,$p4)=($1,$2,$3,$4);
				if($p1==$p3){
					$p1-=10;
					$p3+=10;
				}elsif($p2==$p4){
					$p2-=10;
					$p4+=10;
				}
				$html{"map$ko"}{"$p1,$p2,$p3,$p4"}{$col}{$5}{$F[0]}=$opts{n} ? 1 : $gene2val{$F[0]};
			}else{
			}
		}
		close CONF;
	}
}
close KO;


for my $ko(sort keys %map){
	open PNG,"<$opts{d}/map$ko.png" or die $!;
	open OUT,">$opts{o}/map$ko.png" or die $!;
	my $im_src=GD::Image->new(*PNG);
	binmode OUT;
	print OUT $im_src->png;
	close PNG;
	close OUT;
	
	open PNG,"<$opts{o}/map$ko.png" or die $!;
	my  $im=GD::Image->new(*PNG);
	my $red=$im->colorAllocate(255,0,0);
	my $green=$im->colorAllocate(0,255,0);
	my $black=$im->colorAllocate(0,0,0); 
	my %drawed;
	for my $type( %{$map{$ko}}){
		for my $t ( @{$map{$ko}{$type}}){
			my $col= $t->[-1] eq 'red' ? $red : $green;
			if($type eq 'rect'){
				if(!$drawed{$type}{"$t->[1],$t->[2],$t->[3],$t->[4]"}){
					$drawed{$type}{"$t->[1],$t->[2],$t->[3],$t->[4]"}++;
					if(keys %{$html{"map$ko"}{"$t->[1],$t->[2],$t->[3],$t->[4]"}} == 2){
						$im->filledRectangle($t->[1],($t->[2]+$t->[4])/2,$t->[3],$t->[4],$green);
						$im->filledRectangle($t->[1],($t->[2]+$t->[4])/2,$t->[3],$t->[2],$red);
						$im->copyMerge($im_src,$t->[1],$t->[2],$t->[1],$t->[2],48,20,40);
					}else{
						$im->filledRectangle($t->[1],$t->[2],$t->[3],$t->[4],$col);
						$im->copyMerge($im_src,$t->[1],$t->[2],$t->[1],$t->[2],48,20,40);
					}
				}
			}elsif($type eq 'line'){
				if(!$drawed{$type}{"$t->[1],$t->[2],$t->[3],$t->[4]"}){
					$drawed{$type}{"$t->[1],$t->[2],$t->[3],$t->[4]"}++;
					$im->line($t->[1],$t->[2],$t->[3],$t->[4],$col);
					if($t->[1] == $t->[3]){
						$im->line($t->[1]-1,$t->[2],$t->[3]-1,$t->[4],$col);
						$im->line($t->[1]+1,$t->[2],$t->[3]+1,$t->[4],$col);
						$im->line($t->[1]+2,$t->[2],$t->[3]+2,$t->[4],$col);
					}else{
						$im->line($t->[1],$t->[2]-1,$t->[3],$t->[4]-1,$col);
						$im->line($t->[1],$t->[2]+1,$t->[3],$t->[4]+1,$col);
						$im->line($t->[1],$t->[2]+2,$t->[3],$t->[4]+2,$col);
					}
				}else{
					if($col == $red){
						$im->line($t->[1],$t->[2],$t->[3],$t->[4],$col);
						if($t->[1] == $t->[3]){
							$im->line($t->[1]-1,$t->[2],$t->[3]-1,$t->[4],$col);
						}else{
							$im->line($t->[1],$t->[2]-1,$t->[3],$t->[4]-1,$col);
						}
					}else{
						if($t->[1] == $t->[3]){
							$im->line($t->[1]+1,$t->[2],$t->[3]+1,$t->[4],$col);
							$im->line($t->[1]+2,$t->[2],$t->[3]+2,$t->[4],$col);
						}else{
							$im->line($t->[1],$t->[2]+1,$t->[3],$t->[4]+1,$col);
							$im->line($t->[1],$t->[2]+2,$t->[3],$t->[4]+2,$col);
						}
					}
				}
			}
		}
	}
	open OUT,">$opts{o}/map$ko.png" or die $!;
	binmode OUT;
	print OUT $im->png;
	close PNG;
	close OUT;
}


for my $map(keys %html){
	my $html= <<"HTML";
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<title>$map</title>
<style type="text/css">
<!--
area {cursor: pointer;}
-->
</style>
<script type="text/javascript">
function showInfo(info){
	obj = document.getElementById("result");
	obj.innerHTML = "<div style='cursor: pointer; position: absolute; right: 5px; color: #000;' onclick='javascript: document.getElementById(\\\"result\\\").style.display= \\\"none\\\";'title= 'close'>X</div>"+info;
	obj.style.top = document.body.scrollTop;
	obj.style.left = document.body.scrollLeft;
	obj.style.display = ""; 
}
</script>
</head>
<body>
<map name="$map">
HTML

	for my $rect(keys %{$html{$map}}){
		my $tmp="<ul>";
		for my $col(qw /red green/){
			next unless $html{$map}{$rect}{$col};
			my $color= $col eq 'red' ? '#f00' : '#0f0';
			my $regulate=$opts{n} ? 'Gene' : $col eq 'red' ? 'Up regulated' : 'Down regulated';
			$tmp.= "<li style=\\\"color: $color;\\\">$regulate<ul>";
			for my $ko(  sort{ $opts{n} ? $a cmp $b :  max(values %{$html{$map}{$rect}{$col}{$b}})<=> max(values %{$html{$map}{$rect}{$col}{$a}})  } keys %{$html{$map}{$rect}{$col}}){
				$tmp.="<li>$ko: ";
				for my $gene(sort { abs($html{$map}{$rect}{$col}{$ko}{$b}) <=> abs($html{$map}{$rect}{$col}{$ko}{$a}) } keys %{$html{$map}{$rect}{$col}{$ko}}){
					my $add= $opts{n} ? "$gene, " : "$gene ($html{$map}{$rect}{$col}{$ko}{$gene}), ";
					$tmp.= $add;
				}
				$tmp=~s/, $/<\/li>/;
			}
			$tmp.= "</ul></li>";
		}
		$tmp.="</ul>";
		$html.= "<area shape='rect' coords='$rect' onmouseover='javascript: showInfo(\"$tmp\");' />\n";
	}
	$html.= "</map>\n<img src='./$map.png' usemap='#$map' />\n<div id='result' style='position: absolute; width: 50%; border: 1px solid #000; background-color: #fff; filter: alpha(opacity=95); opacity: 0.95; font-size: 12px; padding-right: 20px; display: none;' onmouseover=\"javascript: this.style.filter= 'alpha(opacity=100)'; this.style.opacity=1;\" onmouseout=\"javascript: this.style.filter = 'alpha(opacity=95)'; this.style.opacity = 0.95;\"></div>\n</body></html>";
	open HTML,">$opts{o}/$map.html" or die $!;
	print HTML $html;
	close HTML;
}
