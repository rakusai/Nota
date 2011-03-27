#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/09/22
#LastUpdate: 2006/03/16
#-----------------------------------------------------------#

require 'option.pl';
require 'nota.pl';

use utf8;
binmode STDIN,  ":bytes"; 
binmode STDOUT, ":encoding(utf-8)"; 

if ($m_fastcgi == 1){
	#FastCGI
	eval{"use FCGI;"};
	while (FCGI::accept >= 0) {
		&main;
	}
}else{
	#
	&main;
}


#-----------------------------------------------------------#
#-- メインプログラム ---------------------------------------#
sub main
{
	local %FORM = ();
	&nota_get_form(\%FORM);
	
	my $sdir = $ENV{'SERVER_NAME'} . $ENV{'SCRIPT_NAME'};
	$sdir =~ /.*\//;
	$sdir = $&;
	$sdir .= $ENV{'HTTP_USER_AGENT'};
	$sdir =~ s/[^a-zA-Z0-9]//g;

	#URLにジャンプするための変数
	my $page = $FORM{'page'};
	my $date = $FORM{'date'};
	my $delay = $FORM{'delay'};
	my $fname = $FORM{'fname'};
	my $msg = $FORM{'msg'};
	my $url;
	if ($ENV{'QUERY_STRING'} =~ /url=(.*)/){
		#URLを取得する
		#FlashVarsのパラメータで&と=が通らないので一時的に変換
		$url = $1;
		$url =~ s/&/\$amp;/g;
		$url =~ s/=/\$equal;/g;
	}
	
	#バリデーション
	&nota_validate($page);
	&nota_validate($date);
	&nota_validate($delay);
	&nota_validate($url,'url');
	&nota_validate($fname,'path');
	&nota_validate($msg);

	if (defined($fname)){
		#アップロードしたファイル名を指定
		&showFlash('imgup',"link.swf","fname=$fname&sdir=$sdir&page=$page&date=$date");
	}elsif (defined($url)){
		#外部URL指定フラッシュを表示
		&showFlash('link',"link.swf","url=$url&sdir=$sdir&page=$page&delay=$delay");
	}elsif (defined($msg)){
		#外部URL指定フラッシュを表示
		&showFlash('link',"link.swf","msg=$msg&sdir=$sdir&page=$page&delay=$delay");
	}else{
		#エラー
		&error;
	}
}

#-----------------------------------------------------------#
#--  転送用フラッシュファイルの表示 ------------------------#
sub showFlash
{
	my ($title,$movie,$flashvars) = @_;
	
	my $flashsrc = &nota_print_flash("$title","$movie?ver=$m_version","$flashvars","noscale","#FFFFFF","","5","5");

	#転送用SWFを出力
	print "Content-type: text/html; charset=utf-8\n\n";
	print <<"END_OF_HTML";
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
	<head>
		<meta http-equiv=Content-Type content="text/html; charset=utf-8">
		<title>NOTA - $title</title>
		<style>
		body {
			margin:0px;
			padding:0px;
			overflow:hidden;
		}
		</style>
	</head>
	<body>
$flashsrc
	</body>
</html>
END_OF_HTML

}

#-----------------------------------------------------------#
#--  エラー処理 --------------------------------------------#
sub error
{
	print "Content-type: text/plain; charset=utf-8\n\n";
	print "res=ERR&\n";
}


#-----------------------------------------------------------#
#-----------------------------------------------------------#
#END_OF_SCRIPT