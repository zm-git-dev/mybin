#!/usr/bin/perl
use strict;
use warnings;

=pod

gff_to_bed.pl gff_files


=cut

die `pod2text $0` unless @ARGV;
for my $file(@ARGV){
	open IN,"<$file" or die $!;
	my $old_file=$file;
	$file=~ s/\.\w+$/\.bed/;
	open OUT,">$file" or die $!;
	my %hash;
	while(<IN>){
		chomp;
		s/\r//g;
		next if /^#/;
		next if /^\s*$/;
		my @array=split /\t/;
		next unless ($array[2] eq "exon");
		if($array[8] =~ /ID=([^;]+);Parent=([^;]+)/){
			$hash{$2}{$1}=[$array[0],$array[3],$array[4],$array[6],];
		}elsif($array[8] =~ /transcript_id \"(\S+)\"\;/){
			my $transcript_id=$1;
			my $exon_id;
			if(exists $hash{$transcript_id}{0}){
				$exon_id =keys %{$hash{$transcript_id}};
			}else{
				$exon_id=0;
			}
			$hash{$transcript_id}{$exon_id}=[$array[0],$array[3],$array[4],$array[6],];
		}else{
			die "$old_file:gff or gtf format error!\n";
		}
	}
	close IN;
	
	my ($str1,$str2);
	my %sorted;
	for my $parent (#sort{
			#	my $n=(keys %{$hash{$a}})[0];
			#	my $m=(keys %{$hash{$b}})[0];
			#	$hash{$a}{$n}->[0] cmp $hash{$b}{$m}->[0] 
			#}
			keys %hash){
		my ($block_count,$block_size,$block_start,$chr,$strand);
		my ($low,$high);
		for my $id(keys %{$hash{$parent}}){
			if(!$low){
				$low= $hash{$parent}{$id}->[1] < $hash{$parent}{$id}->[2] ? $hash{$parent}{$id}->[1]:$hash{$parent}{$id}->[2];
				$high= $hash{$parent}{$id}->[1] > $hash{$parent}{$id}->[2] ? $hash{$parent}{$id}->[1]:$hash{$parent}{$id}->[2];
				$chr=$hash{$parent}{$id}->[0];
				$strand=$hash{$parent}{$id}->[3];
				next;
			}
			$low= $low<$hash{$parent}{$id}->[1] ? $low : $hash{$parent}{$id}->[1];
			$low= $low<$hash{$parent}{$id}->[2] ? $low : $hash{$parent}{$id}->[2];
			$high= $high >$hash{$parent}{$id}->[1] ? $high : $hash{$parent}{$id}->[1];
			$high= $high >$hash{$parent}{$id}->[2] ? $high : $hash{$parent}{$id}->[2];
		}
		for my $id(sort {
					$hash{$parent}{$a}->[1] <=> $hash{$parent}{$b}->[1];
				}
				keys %{$hash{$parent}}){
			my $start= $hash{$parent}{$id}->[1] -$low;
			my $size= $hash{$parent}{$id}->[2] - $hash{$parent}{$id}->[1]+1;
			$block_start.= (defined $block_start  ? ",$start" :"$start");
			$block_size.=(defined $block_size ? ",$size" : "$size");
			$block_count++;
		} 
		$sorted{$chr}{"".($low-1)}{$high}="$chr\t".($low-1)."\t$high\t.\t0\t$strand\t".($low-1)."\t$high\t0\t$block_count\t$block_size\t$block_start";
	}
	
	for my $chr(sort keys %sorted){
		for my $start(sort {$a <=> $b}keys %{$sorted{$chr}}){
			for my $end(sort {$a <=> $b}keys %{$sorted{$chr}{$start}}){
				print OUT "$sorted{$chr}{$start}{$end}\n";
			}
		}
	}
	close OUT;
	
}














