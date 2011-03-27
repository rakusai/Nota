#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/08/26
#LastUpdate: 2005/12/01
#-----------------------------------------------------------#

require 'option.pl';
require 'nota.pl';

use utf8;
use notalib::Login;
use notalib::NDF;

binmode STDOUT, ":encoding(utf-8)"; 
binmode STDIN, ":encoding(utf-8)"; 

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
#メイン
sub main
{
	local %FORM = ();
	&nota_get_form(\%FORM);
	local %COOKIE = ();
	&nota_get_cookie(\%COOKIE);
	
	#LocalConnetionに使うID
	my $sdir = $ENV{'SERVER_NAME'} . $ENV{'SCRIPT_NAME'};
	$sdir =~ /.*\//;
	$sdir = $&;
	$sdir .= $ENV{'HTTP_USER_AGENT'};
	$sdir =~ s/[^a-zA-Z0-9]//g;
	
	#ログイン情報の取得
	local $login = NOTA::Login->new;
	$login->getlogin(\%COOKIE);
	
#	local $user,$pass,$editmode,$anonymous;
#	local $mypower = &login_getlogin(\%COOKIE, \$user, \$pass, \$editmode, \$anonymous);
	
	#ログインを外部で行うとき
	if ($login->get_certify eq "skip"){
		if ($login->get_power eq ''){
			#ログインしていなければインデックスページへ戻る
			&nota_error_html("トップページに戻ってログインしてください。","<a href=\"../../\">トップページへ</a>");
			return;
		}
	}
	#&nota_error_html("Failure to parse XML.","$user $pass $mypower");
	
	#使用言語
	local $lang = &nota_get_lang();
	
	#頁番号の取得
	my $ishtml = 0, $isscreen = 0;
	my $page = $FORM{'page'};
	if (!$page || $page eq ""){
		$page = $ENV{'QUERY_STRING'};
	}
	if ($page =~ s/\.html$//g){
		#HTML版
		$ishtml = 1;
	}elsif ($page =~ s/\.screen$//g){
		#FULL SCREEN版
		$isscreen = 1;
	}
	if (!$page || $page eq ""){
		$page = 'home';
	}
	
	#
	
	if ($ishtml){
		#HTML表示を行う
		require 'htmlconv.pl';
	}
	#バリデーション
	&nota_validate($page);

	#ページを表示する
	if (-e "$m_datadir/$page.ndf"){
		my $title = "NOTA";
		my @lines = ();
		my $ndf = NOTA::NDF->new;
		if ($ndf->parsefile("$m_datadir/$page.ndf")){
			
			$title = "NOTA - " . $ndf->getItem('head','title');
			&nota_xmlescape($title);	#エスケープ
			
		}else{
			#オープンエラー
			if ($ndf->get_errorcode == 100){
				if ($lang eq "en"){
					&nota_error_html("Can't open file.");
				}else{
					&nota_error_html("ファイルを開けません。");
				}
			}else{
				if ($lang eq "en"){
					&nota_error_html("Failure to parse XML.", $ndf->get_errortext);
				}else{
					&nota_error_html("XMLの解析に失敗しました。",$ndf->get_errortext);
				}
			}
			return;
		}
		if ($ishtml){
			#HTMLページを出力
			if ($login->is_access_forbidden){
				#第3者の閲覧禁止
				if ($lang eq "en"){
					&nota_error_html("Can't open page.","This NOTA doesn't open to the public. Please login to access.");
				}else{
					&nota_error_html("ページを表示できません。","このNOTAは、第三者への表示が制限されています。ログインしてご利用ください。");
				}
				return;
			}
			&printHtml($page,$lang);
		}else{
			#Flashページを出力
			my $innertext = &getPageText($ndf);#出力する文字データをピックアップ
			if ($login->is_access_forbidden){
				#第3者の閲覧禁止
				$innertext = "";
			}
			my $linkurl = "page=$page&sdir=$sdir";
			&show($sdir,$linkurl,$title,$page,$innertext);
		}
	}elsif (-e "$m_datadir/$page.csv"){
		#旧バージョンのデータ
		my $linkurl = "page=$page&sdir=$sdir";
		&show($sdir,$linkurl,"NOTA - Convert",$page,"");
	}else{
		#ページがない
		if ($lang eq "en"){
			&nota_error_html("Page not found.");
		}else{
			&nota_error_html("ページが見つかりません。");
		}
	}

}

#-----------------------------------------------------------#
#--  ページのアイテムを変数にセットする --------------------#
sub getPageText
{
	my $ndf = shift;

	#変数を定義
	my %P = ();
	my $mkdir = 0;
	my $id = '';
	my $text = "";
	my $ref_array = $ndf->get_ndfarray;
	foreach (@$ref_array){
		if ($_ =~ /^(\w*):(\w*)=(.*)/){
			my $nid = $1;
			my $param = $2;
			my $value = $3;
			if ($param eq "text"){
			#IDの替わり時を捉える
				$P{'text'} = $param;
				
				#ファイル名とテキストのエンコード
				$value =~ s/%2B/\+/g;	#+記号過去との互換性
				$value =~ s/%2C/,/g;	#区切り 過去との互換性
				$value =~ s/&apos;/'/g;	#なぜか' が&apos;になる。過去との互換性
				
				#文字列
				#リンク先の変更
				$value =~ s/<A HREF="link\.cgi\?url=http/<a href="http/g;
				$value =~ s/<A HREF="link\.cgi\?url=mailto/<a href="mailto/g;
				$value =~ s/<A HREF="link\.cgi\?url=/<a href=".\/?/g;
				$value =~ s/TARGET="link"//g;
				$value =~ s/<\/A>/<\/a>/g;
				$value =~ s/\$amp;/&/g;
				$value =~ s/\$equal;/=/g;
				#タグの消去
				$value =~ s/(<FONT[^>]*>|<\/FONT>)//g;
				$value =~ s/(<TEXTFORMAT[^>]*>|<\/TEXTFORMAT>)//g;
				$value =~ s/(<U[^>]*>|<\/U>)//g;
				$value =~ s/(<BR[^>]*>|<\/BR>)//g;
				$value =~ s/<P[^>]*>//g;
				$value =~ s/<\/P>/ /g;

				$text .= "\t\t<p>" . $value . "</p>\n";
			}
		}
	}
	return $text;
}

#-----------------------------------------------------------#
#フラッシュファイルの表示
sub show
{
	my ($sdir,$linkurl,$title,$page,$innertext) = @_;
	
	my $metarobot = '';
	if ($m_norobot == 1){
		$metarobot = "<meta content=NONE name=ROBOTS>\n\t<meta content=NOINDEX,NOFOLLOW name=ROBOTS>";
	}
	
	local $sidew = $COOKIE{'sidew'};
	if (!defined($sidew) || $sidew < 20){
		$sidew = 190;
	}
	my $getparam = "?$page";
	if ($page eq "home"){
		$getparam = "";
	}
#	my $toolbar = "blueball";
	my $toolbar = "pearl_flat";
	if ($isscreen == 1){
		$toolbar = "mini_flat";
	}
	
	
	#日英表記分け
	my %japanese = (
		'NOTA Portal' => 'NOTAポータルへ', 
		'Show HTML Version' => 'HTML版を表示', 
		'Home' => 'ホーム',
		'Help' => 'ヘルプ',
		'FAQ' => '質問集',
		'Manual' => '使い方',
		'Share Nota' => '友人に教える',
		'FullScreen' => '全画面',
		'Show RSS Feed' => 'RSSを表示',
		'Feedback' => 'ご意見',
		'Search' => '探す',
		'List' => '一覧',
		'Insert' => '貼る',
		'Option' => '設定',
		'Admin' => '管理人',
		'Member' => '会員',
		'Guest' => 'ゲスト',
		'Japanese' => 'English',
		'is Online' => 'さんが編集中',
		'Welcome, Guest' => 'NOTAへようこそ',
		'\'ja\'' => '\'en\''
	);
	my $words = join('|',keys( %japanese ));
	
	my $tabsrc = "tab.swf?ver=$m_version";
	my $tabvars = "tabcolor=#9EDD6A&sdir=$sdir&editmode=$editmode&page=$page&lang=$lang";
	my $tabflash = &nota_print_flash("tab",$tabsrc,$tabvars,"noscale","#FFFFFF","","200","52");
	
	my $flashsrc = "nota.swf?ver=$m_version";
	my $flashvars = "certify=" . $login->get_certify . "&sdir=$sdir&page=$page&lang=$lang&screen=$isscreen&toolbar=$toolbar&anonymous=" . $login->get_anonymous . "&";
	my $mainflash = &nota_print_flash("mainflash",$flashsrc,$flashvars,"noscale","#F2F2EE","","100%","100%");
	
	#テンプレートの読み込み
	my $temppath = $m_themedir  . "/normal.html";
	if ($isscreen == 1){
		$temppath = $m_themedir . "/screen.html";
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
		$_ =~ s/<!--NOTA TITLE-->/$title/;
		$_ =~ s/<!--NOTA META INFO-->/$metarobot/;
		$_ =~ s/<!--NOTA MAIN FLASH-->/$mainflash/;
		$_ =~ s/<!--NOTA FLASH SRC-->/$flashsrc/;
		$_ =~ s/<!--NOTA FLASHVARS-->/$flashvars/;
		$_ =~ s/<!--NOTA TAB SRC-->/$tabsrc/;
		$_ =~ s/<!--NOTA TABVARS-->/$tabvars/;
		$_ =~ s/<!--NOTA SIDE BAR-->/$sidebar/;
		$_ =~ s/<!--EMBEDDED TEXT-->/$innertext/;
		$_ =~ s/<!--NOTA GOTO HTML-->/\.\/?$page\.html/;
		$_ =~ s/<!--NOTA GOTO SCREEN-->/\.\/?$page\.screen/;
		$_ =~ s/<!--NOTA GOTO RSS-->/rss.cgi/;
		if ($lang eq "en"){
			$_ =~ s/<!--NOTA GOTO HELP-->/http:\/\/nota\.jp\/en\/help\//;
			$_ =~ s/<!--NOTA GOTO CONTACT-->/http:\/\/nota\.jp\/en\/contact\//;
		}else{
			$_ =~ s/<!--NOTA GOTO HELP-->/http:\/\/nota\.jp\/help\//;
			$_ =~ s/<!--NOTA GOTO CONTACT-->/http:\/\/nota\.jp\/contact\//;
		}
		$_ =~ s/<!--THEME DIR-->/$m_themedir/;
		$_ =~ s/<!--NOTA GOTO MAIL-->/mail.cgi?page=$page/;
		$_ =~ s/<!--NOTA TAB FLASH-->/$tabflash/;
		$_ =~ s/<!--NOTA PAGE-->/$page/;
		$_ =~ s/<!--NOTA LIST-->/sidebar.cgi?page=$page/;
		$_ =~ s/<!--NOTA INSERT-->/template.cgi?page=$page/;
		$_ =~ s/<!--NOTA OPTION-->/sidebar.cgi?type=account&page=$page/;
		$_ =~ s/<!--NOTA EDITMODE-->/$login->{editmode}/;
		if ($lang eq "ja"){
			$_ =~ s/($words)/$japanese{$1}/go;
		}
		$_ =~ s/<!--NOTA USER-->/$login->{user}/;
		$_ =~ s/<!--NOTA POWER-->/$login->{power}/;
		print $_;
	}

}




#-----------------------------------------------------------#
#END_OF_SCRIPT
