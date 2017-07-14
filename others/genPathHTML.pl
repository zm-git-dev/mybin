#!/usr/bin/perl -w

=pod
description: generate pathway html files
author: Zhang Fangxian, zhangfx@genomics.cn
created date: 20090806
modified date: 20100205, 20100127, 20091204, 20091201, 20091010, 20090814, 20090807
=cut

use Getopt::Long;

my ($indir, $help);

GetOptions("indir:s" => \$indir, "help|?" => \$help);

if (!defined $indir || defined $help) {
	print STDERR << "USAGE";
description: generate pathway html files
usage: perl $0 [options]
options:
	-indir *: input directory, containing *.path files
	-help|?: print help information
USAGE
	exit 1;
}

if (!-d "$indir") {
	print STDERR "directory $indir not exists\n";
	exit 1;
}

@files = glob("$indir/*.path.xls");
for $i (0 .. $#files) {
	$name = (split /[\\\/]/, $files[$i])[-1];
	$name =~ s/\.path\.xls$//;
	$htmlFile = $files[$i];
	$htmlFile =~ s/path\.xls$/htm/;

	$code = <<HTML;
<html>
<head>
<meta http-equiv="content-type" content="text/html; charset=utf-8">
<title>$name</title>
<style type="text/css">
	a {
		text-decoration: none;
		outline: none;
		hide-focus: expression(this.hideFocus=true);
	}
	a:hover {
		color:#FF0000;
		text-decoration:none;
		outline:none;
		hide-focus: expression(this.hideFocus=true);
	}
	body {
		font-size: 12px;
		font-family: "Microsoft YaHei","微软雅黑","雅黑宋体","新宋体","宋体","Microsoft JhengHei","华文细黑",STHeiti,MingLiu;
		background-color: #FFFFFF;
		padding-left: 8%;
		padding-right: 8%;
	}
	table {
		width: 100%;
		border: 0px;
		border-top: 4px #009933 solid;
		border-bottom: 4px #009933 solid;
		text-align: center;
		border-collapse: collapse;
		caption-side: top;
	}
	th {
		border-bottom: 2px #009933 solid;
		padding-left: 5px;
		padding-right: 5px;
	}
	td {
		padding-left: 5px;
		padding-right: 5px;
	}
	table caption{
		font-weight: bold;
		font-size: 16px;
		color: #009933;
		margin-bottom: 8px;
	}
	#backtop{
		font-size: 16px;
		position: fixed;
		bottom: 5%;
		right: 2%;
	}
</style>
<script type="text/javascript">
<!--
function reSize2() {
	try {
		parent.document.getElementsByTagName("iframe")[0].style.height = document.body.scrollHeight + 10;
		parent.parent.document.getElementsByTagName("iframe")[0].style.height = parent.document.body.scrollHeight;
	} catch(e) {}
}

preRow = null;
preColor = null;
function colorRow(trObj) {
	if (preRow != null) {
		preRow.style.backgroundColor = preColor;
	}
	preRow = trObj;
	preColor = trObj.style.backgroundColor;
	trObj.style.backgroundColor = "FF9900";
}

function diffColor(tables) {
	color = ["#FFFFFF", "#CCFF99"];
	for (i = 0; i < tables.length; i++) {
		trObj = tables[i].getElementsByTagName("tr");
		for (j = 1; j < trObj.length; j++) {
			trObj[j].style.backgroundColor = color[j % color.length];
		}
	}
}

function markColor(table) {
	trs = table.getElementsByTagName("tr");
		for (i = 1; i < trs.length; i++) {
			if(table.rows[i].cells.length > 4){
				if(table.rows[i].cells[5].innerHTML < 0.05){
					//trs[i].style.fontWeight = "500";
					table.rows[i].cells[5].style.color = "#FF0000";
					table.rows[i].cells[5].style.fontWeight = "900";
				}
				if(table.rows[i].cells[4].innerHTML < 0.05){
					table.rows[i].cells[4].style.color = "#FF0000";
				}
			}
		}
}

function showPer(tableObj) {
	trObj = tableObj.getElementsByTagName("tr");
	if (trObj.length < 2) {
		return;
	}
	sum1 = trObj[0].cells[2].innerHTML.replace(/^.*\\(([\\d]+)\\).*\$/, "\$1");
	if (trObj[0].cells.length > 4) {
		sum2 = trObj[0].cells[3].innerHTML.replace(/^.*\\(([\\d]+)\\).*\$/, "\$1");
	}
	if (trObj[0].cells.length > 4) {
		trObj[0].cells[2].innerHTML = "DEGs genes with pathway annotation (" + sum1 + ")";
		trObj[0].cells[3].innerHTML = "All genes with pathway annotation (" + sum2 + ")";
	}else{
		trObj[0].cells[2].innerHTML = "All genes with pathway annotation (" + sum1 + ")";
	}
	for (i = 1; i < trObj.length; i++) {
		trObj[i].cells[2].innerHTML += " (" + (Math.round(trObj[i].cells[2].innerHTML * 10000/ sum1) / 100) + "%)";
		if (trObj[0].cells.length > 4) {
			trObj[i].cells[3].innerHTML += " (" + (Math.round(trObj[i].cells[3].innerHTML * 10000/ sum2) / 100) + "%)";
		}
	}
}

window.onload = function() {
	setTimeout("reSize2()", 1);
}
//-->
</script>
HTML
	$code .= "</head><body>";
	open IN, "< $files[$i]" || die $!;
	chomp($content = <IN>);
	@temp = split /\t/, $content;
	shift @temp; shift @temp;
	$pre = shift @temp;
	pop @temp;
	$gene = pop @temp;
	if(scalar(@temp) > 2){
		$gene_list_title = "Differentially expressed genes";
	}
	else{
		$gene_list_title = "Genes";
	}
	$code .= "<table><caption>$name Pathway Enrichment</caption><tr><th>#</th><th>" . substr($pre, 0) . "</th><th>" . (join "</th><th>", @temp) . "</th></tr>";
	$table2 = "<p><br /></p><table><caption>Pathway Detail</caption><tr><th>#</th><th>" . substr($pre, 0) . "</th><th>$gene_list_title</th></tr>";
	$index = 0;
	while (<IN>) {
		chomp;
		next if (/^$/);
		$index++;
		@temp = split /\t/, $_;
		shift @temp; shift @temp;
		$pre = shift @temp;
		pop @temp;
		$gene = pop @temp;
		$gene =~ s/;/, /g;
		if(scalar(@temp) > 2){
			$temp[-2] = sprintf("%.6f", $temp[-2]);
			$temp[-3] = sprintf("%.6f", $temp[-3]);
		}
		$code .= "<tr><td>$index</td><td style=\"text-align: left;\"><a href='#gene$index' title='click to view genes' onclick='javascript: colorRow(document.getElementsByTagName(\"table\")[1].rows[$index]);'>$pre</a></td><td>" . (join "</td><td>", @temp) . "</td></tr>";
		$map = $temp[-1];
		$map =~ s/ko/map/;
		$table2 .= "<tr><td>$index</td><td style=\"text-align: left;\">";
		if (-f "$indir/$name\_map/$map.html") {
			$table2 .= "<a href='$name\_map/$map.html' title='click to view map' target='_blank'>$pre</a>";
		} else {
			$table2 .= "$pre (no map in kegg database)";
		}
		$table2 .= "</td><td style=\"text-align: left;\"><a name='gene$index'></a>$gene</td></tr>";
	}
	$table2 .= "</table>";
	$code .= "</table>$table2<div id=\"backtop\"><a href=\"#\">Back Top</a></div><script type='text/javascript'>showPer(document.getElementsByTagName('table')[0]);\ndiffColor([document.getElementsByTagName('table')[0], document.getElementsByTagName('table')[1]]);markColor(document.getElementsByTagName('table')[0]);</script></body></html>";
	close IN;

	open HTML, "> $htmlFile" || die $!;
	print HTML "$code";
	close HTML;
}

exit 0;
