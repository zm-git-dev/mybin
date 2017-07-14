#!/usr/bin/perl
use strict;
use warnings;

opendir DIR, "alpha_collated_1/" or die $!;
for my $file(readdir DIR){
	next if($file eq ".." or $file eq ".");
	#print "$file\n";
	open OUT,">>alpha_collated/$file" or die $!;
	open IN,"<alpha_collated_1/$file" or die $!;
	print OUT "\n";
	while(<IN>){
		next if(/^\t/);
		print OUT ;
	}
	close IN;
	close OUT;
}
close DIR;
