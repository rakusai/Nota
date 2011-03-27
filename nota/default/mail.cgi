#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/08/14
#LastUpdate: 2005/11/16
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
	&main;
}


#-----------------------------------------------------------#
#-- メインプログラム ---------------------------------------#
sub main
{
	local %FORM = ();
	&nota_get_form(\%FORM);
	local %COOKIE = ();
	&nota_get_cookie(\%COOKIE);
	
	#ユーザー名の取得
	local $user = $COOKIE{'user_id'};
	local $pass = $COOKIE{'pass_wd'};
	#バリデーション
	&nota_validate($user);
	&nota_validate($pass);
	
	#現在ページ
	local $page = $FORM{'page'};
	#バリデーション
	&nota_validate($page);
	
	#使用言語
	local $lang = &nota_get_lang();
	
	#表示
	&show();

}

#-----------------------------------------------------------#
#--  素材画像のメニューとサムネイル一覧を出力 --------------#
sub show
{
#	my ($sdir,$linkurl,$title,$page,$innertext) = @_;
	
	my $metarobot = '';
	if ($m_norobot == 1){
		$metarobot = "<meta content=NONE name=ROBOTS>\n\t<meta content=NOINDEX,NOFOLLOW name=ROBOTS>";
	}
	
	if ($user eq "" || !defined($user)){
		$user = "○○";
	}
	
	my $port = "";
	if ($ENV{'SERVER_PORT'} ne "80"){
		$port = ":" .$ENV{'SERVER_PORT'};
	}
	local $url = "http://".  $ENV{'SERVER_NAME'}. $port . $ENV{'SCRIPT_NAME'};
	$url =~ /.*\//;
	$url = $&;


	#テンプレートの読み込み
	my $temppath = $m_themedir . "/mail_ja.html";
	if ($lang eq "en"){
		$temppath = $m_themedir . "/mail_en.html";
	}
	if (open(DATA,"<:encoding(utf-8)", "./$temppath")){
		@htmls = <DATA>;
		close(DATA);
	}else{
		&nota_error_html("テンプレートファイルが開けません。");
		return;
	}
	
	#テンプレートを置換して出力
	print "Content-type: text/html; charset=utf-8\n\n";
	foreach (@htmls){
		$_ =~ s/<?!--NOTA TITLE-->?/$title/;
		$_ =~ s/<?!--NOTA META INFO-->?/$metarobot/;
		$_ =~ s/<?!--NOTA SITE URL-->?/$url/;
		$_ =~ s/<?!--NOTA CURRENT URL-->?/$url\?$page/;
		$_ =~ s/<?!--NOTA MYID-->?/$user/;
		$_ =~ s/<!--THEME DIR-->/$m_themedir/;
		print $_;
	}

}


#-----------------------------------------------------------#
#END_OF_SCRIPT