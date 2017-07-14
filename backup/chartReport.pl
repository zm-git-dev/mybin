#!/usr/bin/perl -w
use strict;
use SOAP::Lite;
use HTTP::Cookies;
use Getopt::Long;

=pod

USAGE
 charReport.pl [opt]  genes_list.txt

OPT:

-t --type  TYPE          [default: GENE_SYMBOL]

-n --name NAME

-b --background BACKGROUND  0 or 1 [default:0]

-l --list 

-c --chartReport CHARTREPORT   output file [default:charReport.txt]

-h --help

=cut

my %opts=(
	t => "GENE_SYMBOL",
	b => 0,
	n => "name",
	c => "charReport.txt",
);
GetOptions(
	\%opts,
	"t|type=s" ,
	"n|name=s" ,
	"b|background=s" ,
	"c|chartReport=s",
	"h|help",

);
die `pod2text $0` if ($opts{h} or !@ARGV);

  my $soap = SOAP::Lite                             
     -> uri('http://service.session.sample')                
     -> proxy('http://david.abcc.ncifcrf.gov/webservice/services/DAVIDWebService',
                cookie_jar => HTTP::Cookies->new(ignore_discard=>1));

 #user authentication by email address
 #For new user registration, go to http://david.abcc.ncifcrf.gov/webservice/register.htm
 my $check = $soap->authenticate('250310130@qq.com')->result;
  	print "\nUser authentication: $check\n";

#http://david.abcc.ncifcrf.gov/api.jsp?type=GENE_SYMBOL&ids=MAMSTR,DSG3,ELAC2,C11orf70,CD63,GRAMD1C,&tool=chartReport&annot=BBID,BIOCARTA,COG_ONTOLOGY,INTERPRO,KEGG_PATHWAY,OMIM_DISEASE,PIR_SUPERFAMILY,SMART,UP_SEQ_FEATURE
 if (lc($check) eq "true") { 

 open IN,"<$ARGV[0]" or die $!;
  my $inputIds;
 while(<IN>){
 	chomp;
 	$inputIds.= $inputIds ? ",$_" : $_;
 }
 close IN;

my $list = $soap ->addList($inputIds, $opts{t}, $opts{n}, $opts{b});
# my $list= $soap->addList("MAMSTR,DSG3,ELAC2,C11orf70,CD63,GRAMD1C","GENE_SYMBOL","name3",0  );
 #my $list= $soap->addList("1316_at,1320_at,1405_i_at,1431_at,1438_at,1405_i_at,1431_at,1438_at,1487_at,1494_f_at,1598_g_at","AFFYMETRIX_3PRIME_IVT_ID","name2",0  );
print "\n$list of list was mapped\n"; 

  	
 #list all species  names
 my $allSpecies= $soap ->getSpecies()->result;
 print  "\nAll species: \n$allSpecies\n"; 
 #list current species  names

  my $currentSpecies= $soap ->getCurrentSpecies()->result;	 	  	
 print  "\nCurrent species: \n$currentSpecies\n"; 

#set user defined categories 
my $categories = $soap ->setCategories("BBID,BIOCARTA,COG_ONTOLOGY,INTERPRO,KEGG_PATHWAY,OMIM_DISEASE,PIR_SUPERFAMILY,SMART,UP_SEQ_FEATURE")->result;
#to user DAVID default categories, send empty string to setCategories():
# my $categories = $soap ->setCategories("")->result;
#print "\nValid categories: \n$categories\n\n";  
 
open (chartReport, ">", $opts{c});
print chartReport "Category\tTerm\tCount\t%\tPvalue\tGenes\tList Total\tPop Hits\tPop Total\tFold Enrichment\tBonferroni\tBenjamini\tFDR\n";
#close chartReport;

#open (chartReport, ">>", "chartReport.txt");
#getChartReport 	
my $thd=0.1;
my $ct = 2;
my $chartReport = $soap->getChartReport($thd,$ct);
	my @chartRecords = $chartReport->paramsout;
	#shift(@chartRecords,($chartReport->result));
	#print $chartReport->result."\n";
  	print "Total chart records: ".(@chartRecords+1)."\n";
  	print "\n ";
	#my $retval = %{$chartReport->result};
	my @chartRecordKeys = keys %{$chartReport->result};
	
	#print "@chartRecordKeys\n";
	
	my @chartRecordValues = values %{$chartReport->result};
	
	my %chartRecord = %{$chartReport->result};
	my $categoryName = $chartRecord{"categoryName"};
	my $termName = $chartRecord{"termName"};
	my $listHits = $chartRecord{"listHits"};
	my $percent = $chartRecord{"percent"};
	my $ease = $chartRecord{"ease"};
	my $Genes = $chartRecord{"geneIds"};
	my $listTotals = $chartRecord{"listTotals"};
	my $popHits = $chartRecord{"popHits"};
	my $popTotals = $chartRecord{"popTotals"};
	my $foldEnrichment = $chartRecord{"foldEnrichment"};
	my $bonferroni = $chartRecord{"bonferroni"};
	my $benjamini = $chartRecord{"benjamini"};
	my $FDR = $chartRecord{"afdr"};
	
	print chartReport "$categoryName\t$termName\t$listHits\t$percent\t$ease\t$Genes\t$listTotals\t$popHits\t$popTotals\t$foldEnrichment\t$bonferroni\t$benjamini\t$FDR\n";
	
	
	for my $j (0 .. (@chartRecords-1))
	{			
		%chartRecord = %{$chartRecords[$j]};
		$categoryName = $chartRecord{"categoryName"};
		$termName = $chartRecord{"termName"};
		$listHits = $chartRecord{"listHits"};
		$percent = $chartRecord{"percent"};
		$ease = $chartRecord{"ease"};
		$Genes = $chartRecord{"geneIds"};
		$listTotals = $chartRecord{"listTotals"};
		$popHits = $chartRecord{"popHits"};
		$popTotals = $chartRecord{"popTotals"};
		$foldEnrichment = $chartRecord{"foldEnrichment"};
		$bonferroni = $chartRecord{"bonferroni"};
		$benjamini = $chartRecord{"benjamini"};
		$FDR = $chartRecord{"afdr"};			
		print chartReport "$categoryName\t$termName\t$listHits\t$percent\t$ease\t$Genes\t$listTotals\t$popHits\t$popTotals\t$foldEnrichment\t$bonferroni\t$benjamini\t$FDR\n";				 
	}		  	
	
	close chartReport;
	print "\n$opts{c} generated\n";
} 
__END__
	

