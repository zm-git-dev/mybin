#!/usr/bin/perl -w
use Bio::SeqIO;

=pod

	fq2fa.pl  input.fq  output.fa

=cut

die `pod2text $0` unless (@ARGV ==2);

open IN,"$ARGV[0]" or die $!;
open OUT,">$ARGV[1]" or die $!;

#my $in = Bio::SeqIO->newFh(-fh => \*IN,-format => 'Fastq');
#my $out= Bio::SeqIO->newFh(-fh => \*OUT,-format => 'Fasta');

#print $out $_ while(<$in>);

while(<IN>){
	chomp;
	s/^\@//;
	my $l1=$_;
	my $l2=<IN>;
	<IN>;<IN>;
	print OUT ">$l1\n$l2";
}
close IN;
close OUT;
