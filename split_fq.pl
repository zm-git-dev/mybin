#!/usr/bin/perl -w 
use strict;
use File::Basename qw /basename/;
use FileHandle;
use Getopt::Long;

=pod

USAGE: split_fq.pl  seq_1.fq seq_2.fq seqs.fna

-s  split seq by samples

-o  outputdir		[ deault : output ]

-h --help

=cut

my %opts=(
	'o' => 'output',
);
GetOptions(\%opts,
	"s",
	"o=s",
	"h|help",
);
die `pod2text $0` if($opts{h} or @ARGV <3);
my $fq1=shift @ARGV;
my $fq2=shift @ARGV;
$opts{o}=~s/\/$//;

my %hash;
my %sample;
my @samples;
my %tmp;
my %fh;
for my $f(@ARGV){
	local $/="\n>";
	my $base=basename($f,".fna");
	unless($opts{s}){
		push @samples,$base;
		open $fh{"$base\_1"},"| gzip -c  >$base\_1.fq.gz";
		open $fh{"$base\_2"},"| gzip -c  >$base\_2.fq.gz";
	}
	open IN,"<$f" or die $!;
	while(<IN>){
		chomp;
		s/^>//;
		my @F=split /\n/,$_,2;
		my ($s,$r)=$F[0]=~/(.*)\_\d+ (\S+)/;
		$hash{$r}{$base}++;
		$sample{$r}{$s}++;
		$tmp{$s}++;
	}
	close IN;
}

system "mkdir -p $opts{o}";
if($opts{s}){
	for my $s(keys %tmp){
		push @samples,$s;
		open $fh{"$s\_1"},"| gzip -c  >$opts{o}/$s\_1.fq.gz";
		open $fh{"$s\_2"},"| gzip -c  >$opts{o}/$s\_2.fq.gz";
	}
}
open FQ1, $fq1=~/\.gz$/ ? "gzip -dc $fq1 |" : "<$fq1"    or die $!;
open FQ2, $fq2=~/\.gz$/ ? "gzip -dc $fq2 |" : "<$fq2"    or die $!;
while(<FQ1>){
	my $l2=<FQ1>;my $l3=<FQ1>;my $l4=<FQ1>;
	my $r1=<FQ2>;my $r2=<FQ2>;my $r3=<FQ2>;my $r4=<FQ2>;
	chomp;
	/\@(\S+)/;
	my $r=$1;
	for my $s(@samples){
		next unless( $hash{$r}{$s} || $sample{$r}{$s}) ;
		$fh{"$s\_1"}->print("$_\n$l2$l3$l4");
		$fh{"$s\_2"}->print("$r1$r2$r3$r4");
	}
}
close FQ1;close FQ2;

for my $fh(keys %fh){
	close $fh;
}
