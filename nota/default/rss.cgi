#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/05/28
#LastUpdate: 2006/01/29
#-----------------------------------------------------------#

require 'option.pl';
require 'nota.pl';

use utf8;
use notalib::Login;
use notalib::NDF;

binmode STDIN,  ":bytes";
binmode STDOUT, ":encoding(utf-8)";

if ($m_fastcgi == 1){
	#FastCGI
	eval{"use FCGI;"};
	if (!$@){
		while (FCGI::accept >= 0) {
			&main;
		}
	}
}else{
	&main;
}

#-----------------------------------------------------------#
#-- メインプログラム ---------------------------------------#

sub main
{	

	local %COOKIE = ();
	&nota_get_cookie(\%COOKIE);

	local $uri = 'http://' . $ENV{'SERVER_NAME'} . $ENV{'SCRIPT_NAME'};
	$uri =~ s/[^\/]*?$//g;
	local $strtoppage = "トップページへ";
	local $strgoback = "リンク元へ戻る";
	local $strspace = "　";
	
	#ログイン情報の取得
	local $login = NOTA::Login->new;
	$login->getlogin(\%COOKIE);

	#使用言語
	local $lang = &nota_get_lang();

	if ($login->is_access_forbidden){
		#第3者の閲覧禁止
		if ($lang eq "en"){
			&nota_error_html("RSS access forbidden","This NOTA is private use only. Please login to access.");
		}else{
			&nota_error_html("RSSを表示できません。","このNOTAは、非公開です。ログインしてご利用ください。");
		}
		return;
	}

	#RSSファイルの作成を行う
	#中の本文は、タイトルの次にある文字と、新しく追加された文字を表示させる
	my $ndf = NOTA::NDF->new;
	
	#Homeのヘッダーを取得
	my ($id,$author,$title,$edit,$update) = $ndf->getHead($m_datadir,"home");
	local $itemhd = "";
	local $items = "";
	local $pageupdate = "";
	local $pagetitle = "NOTA - $title";
	local $pageauth = "$author";
	
	#最新のファイルを先頭から10個取得
	if (!$ndf->getFileList($m_datadir,0,10)){
		return;
	}
	
	#出力
	my $ref_filelist = $ndf->get_filelist;
	foreach (@$ref_filelist){
		my ($id,$author,$title,$edit,$update) = @$_;
		#ヘッダ情報
		$update =~ s/\//-/g;
		$update =~ s/ /T/g;
		$update .= "+09:00";
		if ($pageupdate eq ""){
			$pageupdate = $update;
		}
		#本文
		my $body = &getDescription($id);
		
		#エスケープ
		&nota_xmlescape($title);
		
		my $pageuri = "$uri?$id";
		if ($id eq 'home'){
			$pageuri = "$uri";
		}
		
		$itemhd .= "<rdf:li rdf:resource=\"$pageuri\" />\n";
		
		$items .= "<item rdf:about=\"$pageuri\">\n";
		$items .= "<title>$title</title>\n";
		$items .= "<link>$pageuri</link>\n";
		$items .= "<description>$body</description>\n";
		$items .= "<dc:subject />\n";
		$items .= "<dc:date>$update</dc:date>\n";
		$items .= "</item>\n\n";
		
	}
	
	#ファイルの一覧
	print "Content-type: text/xml; charset=utf-8\n\n";
	print <<"END_OF_XML";
<?xml version="1.0" encoding="utf-8"?>
<rdf:RDF
  xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:admin="http://webns.net/mvcb/"
  xmlns:cc="http://web.resource.org/cc/"
  xmlns="http://purl.org/rss/1.0/">

<channel rdf:about="$uri">
<title>$pagetitle</title>
<link>$uri</link>
<description />
<dc:language>ja</dc:language>
<dc:creator>$pageauth</dc:creator>
<dc:date>$pageupdate</dc:date>
<admin:generatorAgent rdf:resource="http://nota.jp/" />

<items>
<rdf:Seq>
$itemhd</rdf:Seq>
</items>
</channel>

$items

</rdf:RDF>
END_OF_XML

}

#-----------------------------------------------------------#
#--  description要素を抽出 ---------------------------------#

sub getDescription
{
	my $page = shift;
	
	my %UPDATE = ();
	
	#変数を定義
	#一番分量の適当な長さのテキストと、一番新しいテキストを表示させる！
	
	my $maxsize = 0;
	my $maxtext = 0;
	my $usemaxt = 0;
	my $text = "";
	
	#XMLを読み込む
	my $ndf = NOTA::NDF->new;
	if (!$ndf->parsefile("$m_datadir/$page.ndf")){
		return;
	}
	my $ref_array = $ndf->get_ndfarray;
	foreach (@$ref_array){
		if ($_ =~ /^(\w*):(\w*)=(.*)/){
			my $id = $1;
			my $param = $2;
			my $value = $3;
			if ($id != 'head'){
				if ($param eq "update"){
					#更新日時を記録
					$UPDATE{$id} = $value;
				}elsif ($param eq "text" || ($param eq "fname" && $value =~ /[^(jpg|swf|xml)]$/i)){
					#タグを全て落とす
					$value =~ s/<\/P>/$strspace/g;
					$value =~ s/<[^>]+>//g;
					$value =~ s/\$amp;/&/g;
					$value =~ s/\$equal;/=/g;
					$value =~ s/%2B/\+/g;	#+記号過去との互換性
						
					if (!($value =~ /^$strtoppage/) && !($value =~ /^$strgoback/)){
						#新しいものから、順に採用する！
						$TEXT{$id} = $value;
						#最も長いテキストを記録
						my $lenp = length($value);
						if ($lenp > $maxsize){
							$maxtext = $id;
							$maxsize = $lenp;
						}
					}
				}
			}
		}
	}
	
	#更新日でソート
	foreach (sort {$UPDATE{$b} cmp $UPDATE{$a} } keys %UPDATE){
		if ($TEXT{$_}){
			if (length($text) < 200){
				if ($_ eq $maxtext){
					$usemaxt = 1;
				}
				$line = $TEXT{$_};
			}elsif ($usemaxt == 0){
				$line = $TEXT{$maxtext};
				$usemaxt = 1;
			}else{
				last;
			}
			#本文に追加
			$line2 = substr($line,0,400);
			$text .= $line2;
			if (length($line2) < length($line)){
				$text .= "...";
			}
			$text .= $strspace;
		}
	}
	return $text;
}


#-----------------------------------------------------------#
#--  現在日時 ----------------------------------------------#
sub getLocalDate
{
	($sec,$min,$hour,$mday,$month,$year,$wday) = localtime(time);
	$month++;
	@num =("00","01","02","03","04","05","06","07","08","09");
	$month = $num[$month] if ( $month<=9 );
	$mday  = $num[$mday]  if ( $mday<=9 );
	$hour  = $num[$hour]  if ( $hour<=9 );
	$min   = $num[$min]   if ( $min<=9 );
	$sec   = $num[$sec]   if ( $sec<=9 );
	$year += 1900;
	$temp =  "$year$month$mday_$hour$min$sec";
	
	return ($temp);
}

#-----------------------------------------------------------#
#END_OF_SCRIPT