#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/08/14
#LastUpdate: 2005/12/18
#-----------------------------------------------------------#

require 'option.pl';
require 'nota.pl';

use Image::Magick;
use utf8;
use MIME::Base64 qw(encode_base64 decode_base64);
use notalib::Login;
use notalib::SimpleHttp;
use notalib::SimpleFile;
use Encode qw(encode decode);

binmode STDIN,  ":bytes";
binmode STDOUT, ":encoding(utf8)";

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
	#スクリプトパス
	local $sdir = $ENV{'SERVER_NAME'} . $ENV{'SCRIPT_NAME'};
	$sdir =~ /.*\//;
	$sdir = $&;
	$sdir .= $ENV{'HTTP_USER_AGENT'};
	$sdir =~ s/[^a-zA-Z0-9]//g;

	local $thisfile = 'upload.cgi';

	#標準入力取得
	local %FORM = ();
	&getForm( *FORM ) ;
	local %COOKIE = ();
	&nota_get_cookie(\%COOKIE);

	#現在ページから、イメージのディレクトリを
	local $page = $FORM{'page'};
	local $align = $FORM{'align'};

	#バリデーション
	&nota_validate($page);
	&nota_validate($align);

	if (!defined($page) || $page eq ""){
		#頁が空白
		if ($lang eq "en"){
			&error("Pages are not specified.");
		}else{
			&error("ページが指定されていません。");
		}
		return;
	}

	#ログイン情報の取得
	local $login = NOTA::Login->new;
	$login->getlogin(\%COOKIE);

	#編集モードか
	if ($login->get_power eq '' || $login->get_editmode ne 'true'){
		#権限なし
		if ($lang eq "en"){
			&error("Please login to insert images.");
		}else{
			&error("編集モードのときに利用します。");
		}
		return;
	}

	#使用言語
	local $lang = &nota_get_lang();

	#対象ページを含んだパスを定義
	local $imgdir = "$m_imgdir/$page";


	my $action = $FORM{'action'};
	if ($action  eq 'regist' ){
		#投稿
		&regist();
	}elsif ($action eq 'regist2' ){
		#テンプレートから投稿
		&regist2();
	}elsif ($action eq 'copy' ){
		#コピー
		&copy();
	}elsif ($FORM{'msg'}){
		#エラー表示
		&error($FORM{'msg'});
	}else{
		#投稿処理
		if ($FORM{'fname'} ne ""){
			#投稿処理
			my $fname = $FORM{'fname'}; #最初からUTF8になっている
			my $date = $FORM{'date'};
			#バリデーション
			&nota_validate($fname,'path');
			&nota_validate($date);
			&showFlash($fname);
		}else{
			#投稿フォーム表示
			&printForm;
		}
	}
}

#-----------------------------------------------------------#
#-- 登録処理 -----------------------------------------------#
sub regist
{
	#必要データ
	my $filedata = $FORM{'imgfdata'};
	my $fname    = $FORM{'upFileName'};
	my $quality  = $FORM{'quality'};

	#まず、UTF8に変換
	&nota_convert($fname,'utf8');

	#ファイル名をタイトルと拡張子に分割
	$fname =~ s/.*(\\|\/)//;		#ディレクトリ区切り / より前をカット(IEのみ)
	my $title = $fname;
	my $ext = "";
	if ($title =~ s/(\.[0-9a-zA-Z]+)$//){	#拡張子を取る
		$ext = $1;					#ヒットした拡張子
		$ext =~ s/[A-Z]/lc($&)/ge;	#小文字に変換
	}

	#バリデーション
	&nota_validate($title,'path');
	&nota_validate($quality);

	#投稿ファイルサイズチェック
	my $fsize = length($filedata);
	if( $fsize > $m_max_imgfile_size * 1024 * 1024 ){
		if ($lang eq "en"){
			&error( "The file size must be under 5MB.") ;
		}else{
			&error( "ファイルは5MB以下のものを選択して下さい。") ;
		}
		return;
	}elsif( $fsize < 1 ){
		if ($lang eq "en"){
		&error( "Select a file first, please." );
		}else{
		&error( "ファイルが選択されていません。name : $fname" );
		}
		return;
	}
	#データ容量
	my $userdir = $m_imgdir; #imgフォルダの一つ上の階層
	$userdir =~ s/\/img//g;
	my $file = NOTA::SimpleFile->new;
	my $used_size = $fsize + $file->getDirectorySize($userdir);
	$used_size = int($used_size / 1024 / 1024 * 10) / 10;
	if ($used_size >= $m_max_imgdir_size){
		#ディスクの合計サイズを超えている
		if ($lang eq "en"){
			&error( "The disk is full. No files are acceptable." );
		}else{
			&error( "データ容量がいっぱいです。これ以上ファイルを送信することはできません。" );
		}
		return;
	}

	#イメージデータ保存
	$fname = &saveImgData($title,$ext,$filedata,$quality);

	#ファイルは保存されたか？
	if( -e "$imgdir/" . encode_base64url($fname) ){
		&showFlash($fname);
	}else{
		if ($lang eq "en"){
			&error( "File saving failure." );
		}else{
			&error( "ファイルの保存に失敗しました：$fname" );
		}
		return;
	}
}

#-----------------------------------------------------------#
#-- 登録処理2 ファイルから ---------------------------------#
sub regist2
{
	my $dir   = $FORM{'dir'};
	my $fname = $FORM{'fname'};
	my $url = $FORM{'url'};

	#バリデーション
	&nota_validate($dir,'path');
	&nota_validate($fname,'path');
	&nota_validate($url,'uri');

	if ($url =~ /^http/){
		#インターネット経由で貼り付け
		my $http = NOTA::SimpleHttp->new;

		if (!$http->request($url)){
			if ($lang eq "en"){
				&error( "Can't get file from internet." );
			}else{
				&error( "インターネット経由でファイルを取り込めません。" );
			}
			return;
		}
		#bodyデータとファイル名を取り出す
		$FORM{'imgfdata'} = $http->get_body();
		$FORM{'upFileName'} = $http->get_filename("index.html");

	}else{
		#ファイルを開く
		if( open( FROM, "< $m_templatedir/$dir/$fname") ){
			binmode( FROM );
			$FORM{'imgfdata'} = '';
			while( <FROM> ) { $FORM{'imgfdata'} .= $_; }
			close( FROM ) ;
		}else{
			if ($lang eq "en"){
				&error( "File not found." );
			}else{
				&error( "ファイルが見つかりません。" );
			}
			return;
		}
		#変数に値をセット
		$FORM{'upFileName'} = $fname;
	}
	#登録
	&regist;

}

#-----------------------------------------------------------#
#-- 複製処理 -----------------------------------------------#
sub copy
{
	#ファイルの複製
	#()内の数字を増やして、既存のファイルと重複しないファイル名にする
	my $fname   = $FORM{'fname'};
	my $srcpage = $FORM{'srcpage'};

	#バリデーション
	&nota_validate($fname,'path');
	&nota_validate($srcpage);

	#UTF8がくるので、SHIFTJISに変換
	my $fname_sjis = $fname;
	&nota_convert($fname_sjis,'shiftjis','utf8');

	my $title = $fname;
	$title =~ s/(\.[0-9a-zA-Z]+)$//;	#拡張子だけにする
	my $ext = $1;					#ヒットした拡張子

	#元ファイルがあるか？
	my $source_path = "";
	if (-e "$m_imgdir/$srcpage/$fname_sjis"){
		$source_path = "$m_imgdir/$srcpage/$fname_sjis";
	}elsif (-e "$imgdir/$fname_sjis"){
		$source_path = "$imgdir/$fname_sjis";
	}elsif (-e "$m_trashdir/$srcpage/$fname_sjis"){
		$source_path = "$m_trashdir/$srcpage/$fname_sjis";
	}elsif (-e "$m_imgdir/$srcpage/".encode_base64url($fname)){
		$source_path = "$m_imgdir/$srcpage/".encode_base64url($fname);
	}elsif (-e "$imgdir/".encode_base64url($fname)){
		$source_path = "$imgdir/".encode_base64url($fname);
	}elsif (-e "$m_trashdir/$srcpage/".encode_base64url($fname)){
		$source_path = "$m_trashdir/$srcpage/".encode_base64url($fname);
	}else{
		print "Content-type: text/plain; charset=utf-8\n\n";
		print "res=OK";
		return;
	}

	#すでに存在していないかチェック
	my $rep = 2;
	while( -e "$imgdir/".encode_base64url("$title$ext") ){
		$title =~ s/\([0-9]+\)$//;	#最後のかっこを消して
		$title .= "($rep)";			#番号付きのかっこをつける
		$rep += 1;						#数を増やす
	}
	my $newfname = "$title$ext";

	my $file = NOTA::SimpleFile->new;

	#画像ファイルコピー
	if (!$file->copyFile($source_path,"$imgdir/".encode_base64url($newfname))){
		#失敗してもOKを返す
		print "Content-type: text/plain; charset=utf-8\n\n";
		print "res=ERR";
		return;
	}
	$newfname = url_encode($newfname);

	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Content-type: text/plain; charset=utf-8\n\n";
	print "res=OK&newfname=$newfname";


}


#-----------------------------------------------------------#
#--  イメージデータ保存 ------------------------------------#
sub saveImgData
{
	my ($title, $ext , $img_data , $quality) = @_ ;

	#ContentTypeから拡張子を取得
	if ($ext eq ""){
		$ext = &getExtFromMimeType($FORM{'upContentType'});
	}

	#画像ファイルか
	my $imgtype = '.jpg.gif.png.bmp.pict.tif.jpeg';
	my $isimage = 0;
	if ($imgtype =~ /$ext/ && $ext ne ""){
		#画像ファイル
		$isimage = 1;
		$ext = ".jpg";#拡張子を強制的にjpgに
	}

	#ファイル名決定
	my $rep = 2;
	while( -e "$imgdir/" . encode_base64url("$title$ext") ){	#すでに存在していないかチェック
		$title =~ s/\([0-9]+\)$//;	#最後のかっこを消して
		$title .= "($rep)";			#番号付きのかっこをつける
		$rep += 1;						#数を増やす
	}
	my $newfname = "$title$ext";

	#マックバイナリ対策
	if ($FORM{'upMacbin'}) {
		my $length = substr($img_data,83,4);
		$length = unpack("%N",$length);
		$img_data = substr($img_data,128,$length);
	}

	#ファイル保存
	mkdir($imgdir,0755);	#ディレクトリの作成

	if ($isimage == 1){
		#画像
		my $i = Image::Magick->new;
		$i->BlobToImage($img_data);
		my ($w, $h) = $i->Get('width', 'height');
		$i->Set(quality => '80');
		my $max = 700;
		if ($quality eq '1'){
			$max = 1000;
			$i->Set(quality => '90');
		}
		if ($w > $max || $h > $max){
			$i->Scale($max . 'x' . $max);#比率を保って縮小
		}
		if ($w * $h < 350*350){
			$i->Set(quality => '100');	#小さい画像はクオリティを上げる
		}
		$i->Opaque(color=>'silver', fill=>'white');
		$i->Write(filename => "$imgdir/" . encode_base64url($newfname));

		#分割保存されている場合は最初を採用
		my $path = "$imgdir/" . encode_base64url($newfname);
		if( -e "$path.0" ){
			rename("$path.0","$path");
			my $n = 1;
			while (-e "$path.$n"){	#残りは削除
				unlink("$path.$n");
				$n++;
			}
		}
	}else{
		#画像ではない
		if( open( DATA, "> $imgdir/" . encode_base64url($newfname)) ){
			flock( DATA, 2 ) ;
			truncate( DATA, 0 ) ;
			seek( DATA, 0, 0 ) ;
			binmode( DATA ) ;
			print DATA $img_data ;
			close( DATA ) ;
		}
	}

	return( $newfname ) ;
}

sub encode_base64url {
    my $e = encode_base64(shift, "");
    $e =~ s/=+\z//;
    $e =~ tr[+/][-_];
    return $e;
}
#-----------------------------------------------------------#
#--  拡張子を求める ----------------------------------------#
sub getExtFromMimeType
{
	#ContentTypeから拡張子を求める
	my ($ctype) = $_[0];
	my $ext = "";
	if ($ctype =~ /image\/gif/i)		{ $ext=".gif";}
	elsif ($ctype =~ /image\/(jpeg)/i)	{ $ext=".jpg";}
	elsif ($ctype =~ /image\/(jpg)/i)	{ $ext=".jpg";}
	elsif ($ctype =~ /image\/x-png/i)	{ $ext=".png";}
	elsif ($ctype =~ /text\/plain/i)	{ $ext=".txt";}
	elsif ($ctype =~ /lha/i)			{ $ext=".lzh";}
	elsif ($ctype =~ /zip/i)			{ $ext=".zip";}
	elsif ($ctype =~ /pdf/i)			{ $ext=".pdf";}
	elsif ($ctype =~ /audio\/.*mid/i) 	{ $ext=".mid";}
	elsif ($ctype =~ /msword/i) 		{ $ext=".doc";}
	elsif ($ctype =~ /ms-excel/i) 		{ $ext=".xls";}
	elsif ($ctype =~ /ms-powerpoint/i) 	{ $ext=".ppt";}
	elsif ($ctype =~ /audio\/.*realaudio/i) { $ext=".ram";}
	elsif ($ctype =~ /application\/.*realmedia/i) { $ext=".rm";}
	elsif ($ctype =~ /video\/.*mpeg/i) 	{ $ext=".mpg";}
	elsif ($ctype =~ /audio\/.*mpeg/i) 	{ $ext=".mp3";}

	return $ext;

}

#-----------------------------------------------------------#
#-- 現在日時を取得 -----------------------------------------#
sub getLocalDate
{
	my ($sec,$min,$hour,$mday,$month,$year,$wday) = localtime();
	$month++;
	my @week = ("日","月","火","水","木","金","土");
	my $wday = $week[ $wday ];
	my @num =("00","01","02","03","04","05","06","07","08","09");
	$month = $num[$month] if ( $month<=9 );
	$mday  = $num[$mday]  if ( $mday<=9 );
	$hour  = $num[$hour]  if ( $hour<=9 );
	$min   = $num[$min]   if ( $min<=9 );
	$sec   = $num[$sec]   if ( $sec<=9 );
	$year += 1900;
	my $temp =  "$year$month$mday\_$hour$min$sec";

	return ($temp);
}

#-----------------------------------------------------------#
#--  デコード ----------------------------------------------#
sub getForm
{
	#	パラメータ展開
	local( *array ) = @_ ;

	#マルチパートデータの場合
	if( $ENV{'CONTENT_TYPE'} =~ m#^multipart/form-data# ){
		&getMultiPartData( array, 'imgfdata' ) ;
		return ;
	}

	#通常のデコード処理
	my $buffer = "";
	if ($ENV{'REQUEST_METHOD'} eq "POST") { read(STDIN,$buffer,$ENV{'CONTENT_LENGTH'}); }
	else { $buffer = $ENV{'QUERY_STRING'}; }
	my @pairs = split(/&/,$buffer);
	foreach (@pairs)
	{
		my ($name, $value) = split(/=/, $_);
		$value =~ tr/+/ /;
		$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		#連想配列へ格納
		$array{$name} = $value;
	}

}


#-----------------------------------------------------------#
#--  マルチパートデータ取得 --------------------------------#
sub getMultiPartData
{
	local( *array, $img_param_name ) = @_ ;

	#	標準入力からデータを読みだす
	my $buf = "" ;
	my $read_data = "" ;
	my $remain = $ENV{ 'CONTENT_LENGTH' } ;
	binmode( STDIN ) ;
	while( $remain ){
		$remain -= sysread( STDIN, $buf, $remain ) ;
		$read_data .= $buf ;
	}

	#	データを解釈する
	my $p1 = 0; # ヘッダ部の先頭
	my $p2 = 0; # ボディ部の先頭
	my $p3 = 0; # ボディ部の終端
	my $delimiter = "" ;
	my $max_count = 0 ;

	while( 1 ){
		#	ヘッダ処理
		$p2 = index( $read_data, "\r\n\r\n", $p1 ) + 4 ;
		my @headers = split( "\r\n", substr( $read_data, $p1, $p2 - $p1 ) ) ;
		my $filename = "" ;
		my $name = "";
		foreach (@headers){
			if( $delimiter eq "" ){
				$delimiter = $_ ;
			}
			elsif( /^Content-Disposition: ([^;]*); name="([^;]*)"; filename="([^;]*)"/i ){
				if( $3 ){
					$filename = $3 ;
				}
			}elsif( /^Content-Disposition: ([^;]*); name="([^;]*)"/i ){
				$name = $2 ;
			}
			#その他、ファイルの情報を取得する(ファイル一つが前提)
			if ( /^Content-Type:([^;]*)/i){
				 $array{'upContentType'} = $1;
			}
			if ($_ =~ /application\/x-macbinary/i) { $array{'upMacbin'}=1; }
		}

		#	ボディ処理
		$p3 = index( $read_data, "\r\n$delimiter", $p2 ) ;
		my $size = $p3 - $p2 ;
		if( $filename ){
			$array{'upFileName'} = $filename;
			#↑文字コードは不明だが、多くはutf8、古いIEでshift-jisの可能性
			$array{$img_param_name} = substr( $read_data, $p2, $size ) ;
		}
		elsif( $name ){
			$array{$name} = substr( $read_data, $p2, $size ) ;
		}

		#	終了処理
		$p1 = $p3 + length( "\r\n$delimiter" ) ;
		if( substr( $read_data, $p1, 4 ) eq "--\r\n" ){
			# すべてのファイルの終端
			last ;
		}
		else{
			#	次のファイルを読み出す
			$p1 += 2 ;
			if( $max_count++ > 16 ){
				last ;
			}
			next ;
		}
	}
}


#-----------------------------------------------------------#
#--  URLエンコード -----------------------------------------#
sub url_encode
{
    my $str = shift;
	$str =~ s/([^\w ])/'%' . unpack('H2', $1)/eg;
	$str =~ tr/ /+/;

    return($str);
}


#-----------------------------------------------------------#
#--  転送用フラッシュファイルの表示 ------------------------#
sub showFlash
{
	my( $fname ) = @_ ;
	$fname = decode("UTF-8", $fname);

	print "Content-type: text/html; charset=utf-8\n\n" ;
	print <<"END_OF_HTML";
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<title>NOTA</title>
		<style type="text/css">
		body {
			margin:0px;
			padding:0px;
			overflow:hidden;
		}
		</style>
	</head>
	<body>
		<script type="text/javascript">
		window.parent.list.stopUpload();
		var player = document.all? window.parent.window["nota"] : window.parent.document["nota"];
		player.addImage("$fname");
		</script>
	</body>
</html>
END_OF_HTML

}

#-----------------------------------------------------------#
#-- メッセージ画面を表示 -----------------------------------#
sub error
{
	my( $msg ) = @_ ;

	print "Content-type: text/html; charset=utf-8\n\n" ;
	print <<"END_OF_HTML";
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
	<head>
		<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
		<title>NOTA</title>
		<style type="text/css">
		body {
			margin:0px;
			padding:0px;
			overflow:hidden;
		}
		</style>
	</head>
	<body>
		<script type="text/javascript">
		window.parent.list.stopUpload();
		var player = document.all? window.parent.window["nota"] : window.parent.document["nota"];
		player.msgBox("$msg");
		</script>
	</body>
</html>
END_OF_HTML

}

#-----------------------------------------------------------#
#END_OF_SCRIPT
