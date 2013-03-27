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
	
	my $page = $FORM{'page'};#閲覧者のデータ
	if (!defined($page) || $page eq ""){
		$page = 'home';
	}

	#バリデーション
	&nota_validate($page);

	#ログイン情報の取得
	local $login = NOTA::Login->new;
	$login->getlogin(\%COOKIE);

	if ($login->is_access_forbidden){
		#第3者の閲覧禁止
		&error("page=$page&editmode=false&user=" . $login->get_user . "&anonymous=" . $login->get_anonymous);
		return;
	}
	local $oneid = $FORM{'oneid'};#必要なデータのID
	
	#バリデーション
	&nota_validate($page);
	
	my $action = $FORM{'action'};
	if ($action eq "getfiles"){
		#ページの一覧を返す
		&printPageList($m_datadir);
	}elsif ($action eq "getmasterfiles"){
		#マスターページの一覧を返す
		&printPageList("$m_notadata_dir/master/data");
	}elsif ($action eq "getftime"){
		#ファイルの更新日時を返す
		&printFileTime($page);
	}elsif ($page){
		#頁のデータを返す
		&printPage($page);
	}else{
		#エラー
		&error;
	}
}

#-----------------------------------------------------------#
#--  ファイルの更新日時を返す ------------------------------#
sub printFileTime
{
	my ($page) = $_[0];
	
	#ファイルの更新日時を得る
	my $ftime = localtime( (stat("$m_datadir/$page.ndf"))[9]);

	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
	print "Content-type: text/plain; charset=utf-8\n\n";
	print "page=$page&";
	print "ftime=$ftime&";
	print "res=OK&";
	
}

#-----------------------------------------------------------#
#--  ページのデータを返す ----------------------------------#

sub printPage
{
	my ($page) = shift;		# 引数展開
	
	#XMLを読み込む
	my $ndf = NOTA::NDF->new;
	if (!$ndf->parsefile("$m_datadir/$page.ndf")){
		&error;
		return;
	}
	
	#ファイルの更新日
	my $ftime = localtime( (stat("$m_datadir/$page.ndf"))[9]);
	
	#出力
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
	print "Content-type: text/plain; charset=utf-8\n\n";
	
	print "page=$page&";
	print "ftime=$ftime&page=$page&";
	print "editmode=" . $login->get_editmode . "&";
	print "user=" . $login->get_user . "&";
	print "power=" . $login->get_power . "&";
	print "anonymous=" . $login->get_anonymous . "&";
	
	if ($FORM{'param'} eq "temp"){
		print "use=temp&";
	}
	
	my $i = -1;#ID番号
	my $oldid="";
	my $ref_array = $ndf->get_ndfarray;
	foreach (@$ref_array){
		if (!defined($oneid) || $id eq $oneid){#一つ分のデータのみ返す時に使う
			if ($_ =~ /^([\w\-_]*):([\w\-_]*)=(.*)/){
				my $id = $1;
				my $param = $2;
				my $value = $3;
				if ($id eq 'head'){
					#ファイルのヘッダーを出力
					print "$param=$value&";
				}else{
					if ($param eq "text"){
						#過去との互換性
						$value =~ s/<.?TEXTFORMAT.*?>//g;
						$value =~ s/<FONT FACE="[^"]*"/<FONT/g;
						$value =~ s/<\/P>/<BR>/g;
						$value =~ s/(<P[^>]*>|<\/P>)//g;
						$value =~ s/<BR>$//g;
						#編集モードの時は、リンクターゲットを変える
						$value =~ s/<A HREF="link\.cgi\?url=([^"]*)"/<A HREF="link\.cgi\?page=$page&url=$1"/g;
					}
					#ファイル名とテキストのエンコード
					if ($param eq "text" || $param eq "fname"){
						$value =~ s/%2B/\+/g;	#+記号過去との互換性
						$value =~ s/(&#44;|%2C)/,/g;	#区切り %2Cは過去との互換性
						$value =~ s/%/%25/g;	#まず、これ
						$value =~ s/\+/%2B/g;	#エンコード
						$value =~ s/&/%26/g;	#エンコード
					}
					if ($id ne $oldid){
						$i += 1;
						print "id$i=$id&";
						$oldid = $id;
					}
					print "$param$i=$value&";
					if ($id eq $oneid){
						#一致した！
						return;
					}
				}
			}
		}
	}
	print "res=OK&";
}


#-----------------------------------------------------------#
#--  ページの一覧を返す ------------------------------------#
sub printPageList
{
	my $dir = shift;
	
	#新旧のファイルをどう処理するか
	#datとndfを別々に検索する
	
	#datファイルが見つかった場合は、NDFに変換する！
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
	print "Content-type: text/plain; charset=utf-8\n\n";
	
	#ファイルの一覧を更新日時順に並び替えたリストを取得
	my $ndf = NOTA::NDF->new;
	if (!$ndf->getFileList($m_datadir)){
		print "res=ERR&";
		return;
	}
	
	#出力
	my $i = 0;
	my $ref_filelist = $ndf->get_filelist;
	foreach (@$ref_filelist){
		my ($id,$author,$title,$edit,$update) = @$_;
		if ($lang eq "en"){
			$title =~ s/%title%/Paper/g;
			$title =~ s/%author%/Author/g;
		}else{
			$title =~ s/%title%/用紙/g;
			$title =~ s/%author%/あなたの名前/g;	#エンコード
		}
		$title =~ s/(\r\n|\r|\n)//g;	#エンコード
		$title =~ s/(&#44;|%2C)/,/g;	#区切り %2Cは過去との互換性
		$title =~ s/%/%25/g;	#まず、これ
		$title =~ s/\+/%2B/g;	#エンコード
		$title =~ s/&/%26/g;	#エンコード
		
		print "id$i=$id&update$i=$update&edit$i=$edit&title$i=$title&";
		$i++;
	}
	
	print "res=OK&";

}


#-----------------------------------------------------------#
#--  エラー処理 ----------------------------------------------#
sub error
{
	my $errparam = shift;
	
	print "Content-type: text/plain; charset=utf-8\n\n";
	print "$errparam&res=ERR&\n";
}


#-----------------------------------------------------------#
#-----------------------------------------------------------#
#END_OF_SCRIPT