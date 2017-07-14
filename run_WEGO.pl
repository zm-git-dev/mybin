#!/usr/bin/perl -w
use strict;
use threads;
use LWP;
use LWP::Simple;

=pod

USAGE: run_WEGO.pl   sample.go


=cut

die `pod2text $0` if !@ARGV;
my $s=1;
(my $prefix=$ARGV[0]) =~s/\.(\w)*$//;

my $ua=LWP::UserAgent->new;
$ua->agent("Mozilla/5.0");
my $res1=$ua->post(
	"http://wego.genomics.org.cn/cgi-bin/wego/Process.pl",
	{
		'archive'=>'2009-10-01',
		'format'=>'native',
		'file0'=>["$ARGV[0]"],
		'file1' => [''],
		'file2' => [''],
		'upload'=>"upload",
	},
	'Content_Type'=>'form-data' 
);

my ($id);

####  get id value ####
while(1){
	sleep($s);
	my $c1=$res1->content;
	if ($c1=~/Processing job: ([\d\.]+)/){
		$id=$1;
		my $res2=$ua->get("http://wego.genomics.org.cn/cgi-bin/wego/Edit.pl?id=$id");
		my $c2=$res2->content;
		if($c2=~/box/){
			last;
		}
	}
}

#### get summary file ####
while(1){
	my $res3=$ua->get("http://wego.genomics.org.cn/cgi-bin/wego/Summary.pl?id=$id");
	my $c3=$res3->content;
	if($c3 !~/In progressing/){
		open OUT,">$$.txt" or die $!;
		print OUT "$c3";
		close OUT;
		open OUT2,">$prefix.summary.xls" or die $!;
		open IN,"<$$.txt" or die $!;
		while(<IN>){
			if(/(Cellular Component:|Biological Process:|Molecular Function:)/){
				print OUT2 "$1\n";
			}elsif(my @sum= /(\d+).*(\([\d\.]+\)).*(GO:\d+).*nbsp;([^<]+)/g){
				my $str=  join "\t",@sum;
				$str=~s/\\//;
				print OUT2 "$str\n";
			}
		}
		close IN;
		close OUT2;
		unlink "$$.txt";
		last;
	}
	sleep($s);
}

#### get result.png  ####
my $res4=$ua->post("http://wego.genomics.org.cn/cgi-bin/wego/Render.pl",{
	'id' => "$id",
	'width' => '2000',
	'height' => '500',
	'finish' => 'finish',
});
sleep($s);

my $res5=getstore("http://wego.genomics.org.cn/cgi-bin/wego/Downloader.pl/result.dat.png.gz?id=$id&format=png","$prefix.png.gz");
while(1){
	sleep($s);
	if(is_success($res5) ){
		system "gunzip $prefix.png.gz";
		unlink "$prefix.png.gz";
		last;
	}
}


