#!/usr/bin/perl -w
use strict;

=pod 

USAGE:
	go_network.pl  fg.txt  bg.txt   out_prefix

=cut

die `pod2text $0` unless @ARGV==3;
open IN,"<$ARGV[0]" or die $!;

my %fg;
while(<IN>){
	chomp;
	my @F=split /\t/;
	$fg{$F[0]}=$F[1]>0 ? 1 : -1 ;
}
close IN;
open IN,"<$ARGV[1]" or die $!;
my %bg;
my %go;
while(<IN>){
	chomp;
	my @F=split /\t/;
	if( $fg{$F[0]}){
		$go{$F[2]}{$F[1]}++;
		$bg{$F[2]}{$F[1]}{ $fg{$F[0]} }++;
	}
}
close IN;

my %updown;
for my $t(keys %bg){
	for my $go(keys %{$bg{$t}}){
		if( scalar keys %{$bg{$t}{$go}} ==2){
			$updown{$t}{$go}=0;
		}elsif( $bg{$t}{$go}{1}){
			$updown{$t}{$go}=1;
		}else{
			$updown{$t}{$go}=-1;
		}
	}
}

use GO::OntologyProvider::OboParser;
my %hash;
my %id2term;
for my $t(keys %go){
	my $on=GO::OntologyProvider::OboParser->new(ontologyFile => "/MGCN/Databases/GO/GO_June2016/go-basic.obo",aspect => "$t");
	for my $go(sort keys %{$go{$t}}){
		my $node=$on->nodeFromId($go);
		$id2term{$go}=$node->term;
		for my $an($node->ancestors){
			my $an_id=$an->goid;
			next unless $go{$t}{$an_id};
			$hash{$t}{$go}{$an_id}++;
			$id2term{$an_id}= $an->term;
		}
	}
}

use Data::Dumper;
#print Dumper(\%go);
#exit(0);

for my $t(keys %hash){
	for my $go(sort keys %{$hash{$t}}){
		my @GO= sort keys %{$hash{$t}{$go}};
		if(@GO>1){
			for my $i(0 .. $#GO-1){
				for my $j($i .. $#GO){
					if( $hash{$t}{ $GO[$i] }{ $GO[$j] } ){
						delete $hash{$t}{ $go }{$GO[$j]};
					}elsif( $hash{$t}{$GO[$j]}{$GO[$i]}){
						delete $hash{$t}{$go}{$GO[$i]};
					}
				}
			}
		}	
	}
}

for my $t(keys %hash){
	open OUT,">$ARGV[2].GO.Network.$t" or die $!;
	print OUT "Gene Ontology\tSourceGO\tSourceNode\tTargetGO\tTargetNode\n";
	for my $go1(sort keys %{$hash{$t}}){
		for my $go2(sort keys %{$hash{$t}{$go1}}){
			print OUT "$t\t$go1\t".$id2term{$go1}."\t$go2\t".$id2term{$go2}."\n";
		}
	}
	close OUT;
}
for my $t(sort keys %updown){
	open OUT,">$ARGV[2].GO.Network.color.$t" or die $!;
	print OUT "Gene Ontology\tGO_ID\tGO_Term\tUpDown\n";
	for my $go(sort{ $updown{$t}{$a}<=>$updown{$t}{$b} } keys %{$updown{$t}}){
		print OUT"$t\t$go\t".$id2term{$go}."\t".$updown{$t}{$go}."\n";
	}
	close OUT;
}
