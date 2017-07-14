#!/usr/bin/perl -w
use strict;
use Sqlite_connect;
use Trinotate;
use Getopt::Long;

=pod

USAGE: get_go.pl  [opt] swissprot.blastout

opt:

-t --trinotate	str		default:/MGCN/Databases/Uniprot/Trinotate.sqlite

-s --sep	str		default:"\t"

-f --full			get full list of go.id ,go.namespace,go.name

-a --ancestor			get ancestor go

-h --help

=cut
my %opts=(
	t => "/MGCN/Databases/Uniprot/Trinotate.sqlite",
	s => "\t",
);
GetOptions(\%opts,
	"t|trinotate=s",
	"s|sep=s",
	"f|full",
	"a|ancestor",
	"h|help",
);
die `pod2text $0` if($opts{h} or !@ARGV  );

my $dbproc=&connect_to_db($opts{t});

for my $file(@ARGV){
	open IN,"<$file" or die $!;
	my %have;
	(my $out=$file)=~s/\.\w+$/\.go/;
	open OUT,">$out" or die $!;
	while(<IN>){
		chomp;
		my @F=split /\t/;
		next if $have{$F[0]};
		$have{$F[0]}++;
		my @arr=split /\|/,$F[1];
		my @out;
		my $query= "select g.id, g.namespace,g.name from go g ,uniprotIndex u where u.Accession=? and u.AttributeType='G' and u.LinkId=g.id ";
		my $statementHandle=$dbproc->prepare($query);
		$statementHandle->execute($arr[1]);
		my @output;
		while(my @row=$statementHandle->fetchrow_array){
			push @output , ($opts{f} ? join ",",@row  : $row[0]);
		}
		next unless @output;
		my $str=join $opts{s},@output;
		print OUT "$F[0]\t$str\n";
	}
	close IN;
	close OUT;
}
