#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/08/14
#LastUpdate: 2005/12/21
#-----------------------------------------------------------#

require 'option.pl';
require 'nota.pl';

use utf8;
use notalib::Login;

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
	#日本語URLに対応していないサーバーのため、
	#バイナリーの中身を返すつなぎ役をする

	local %FORM = ();
	&nota_get_form(\%FORM);
	local %COOKIE = ();
	&nota_get_cookie(\%COOKIE);

	my $page = $FORM{'page'};
	my $fname = $FORM{'fname'};
	my $dir = $FORM{'dir'};
	
	#バリデーション
	&nota_validate($page,'path');
	&nota_validate($fname,'path');
	
	if (!defined($fname)){
		&nota_error_html("File not specified.");
		return;
	}
	
	#ログイン情報の取得
	local $login = NOTA::Login->new;
	$login->getlogin(\%COOKIE);
	
	#使用言語
	local $lang = &nota_get_lang();

	#認証
	if ($login->is_access_forbidden){
		#第3者の閲覧禁止
		if ($lang eq "en"){
			&nota_error_html("RSS access forbidden","This NOTA is private use only. Please login to access.");
		}else{
			&nota_error_html("RSSを表示できません。","このNOTAは、非公開です。ログインしてご利用ください。");
		}
		return;
	}

	#MIMEタイプの取得
	my $minetype = &getMimeTypeFromExt($fname);
	#ディレクトリの取得
	if (defined($dir) && $dir ne ''){
		$dir = "$m_drawingdir/$dir";#手書き線の画像
	}else{
		$dir = $m_imgdir;
	}
	
	#ShiftJISに変換
	my $unifname = $fname;
	&nota_convert($fname,'shiftjis','utf8');

	#ファイルを開く
	my $bin_buf = "";
	if (open(DATA,"< $dir/$page/$fname") || open(DATA,"< $dir/$fname")){
		binmode( DATA );
		while( <DATA> ) { $bin_buf .= $_; }
		$filesize = (stat ( DATA )) [7] ;
		close(DATA);
	}else{
		#失敗
		&nota_error_html("File not found.");
		return;
	}
	
	#ファイル名をUnicodeで送るべきかShiftJISで送るべきか、ブラウザで判断せよ
	my $charset = 'shift_jis';
	if ($ENV{'HTTP_USER_AGENT'} =~ /(Firefox)/){
		$fname = $unifname;
		$charset = 'utf-8';
	}
	
	#バイナリ出力
	binmode( STDOUT );
	if ($FORM{'f'} eq "save" || $FORM{'save'} eq "1"){	#ダウンロード処理
		print "Content-Length: $filesize\n"; 
		print "Content-disposition: attachment; filename=\"$fname\"\n"; 
		print "Content-type: $minetype; name=\"$fname\"; charset=\"$charset\"\n\n";
	}else{
		print "Content-Length: $filesize\n"; 
		print "Content-disposition: filename=\"$fname\"\n"; 
		print "Content-type: $minetype; name=\"$fname\"; charset=\"$charset\"\n\n";
		
	}
	print $bin_buf;

}


#-----------------------------------------------------------#
#--  マインタイプを返す ------------------------------------#
sub getMimeTypeFromExt
{
	# --- 拡張子からMIMEタイプを作る
	my $fname = shift;
	my $f_mime = "";

	if   ($fname =~ /\.jpe?g$/i) { $f_mime = 'image/jpeg'; }		# JPEG
	elsif($fname =~ /\.gif$/i) { $f_mime = 'image/gif';  }			# GIF
	elsif($fname =~ /\.png$/i) { $f_mime = 'image/png';  }			# PNG
	elsif($fname =~ /\.bmp$/i) { $f_mime = 'image/bmp';  }			# BMP

	elsif($fname =~ /\.txt$/i) { $f_mime = 'text/plain';  }			# TEXT
	elsif($fname =~ /\.s?html?$/i){ $f_mime = 'text/html'; }			#HTML

	elsif($fname =~ /\.lzh$/i) { $f_mime = 'application/lha'; }
	elsif($fname =~ /\.zip$/i) { $f_mime = 'application/zip'; }
	elsif($fname =~ /\.pdf$/i) { $f_mime = 'application/pdf'; }
	elsif($fname =~ /\.mid$/i) { $f_mime = 'audio/mid'; }
	elsif($fname =~ /\.docx?$/i) { $f_mime = 'application/msword'; }
	elsif($fname =~ /\.xlsx?$/i) { $f_mime = 'application/ms-excel'; }
	elsif($fname =~ /\.pptx?$/i) { $f_mime = 'application/ms-powerpoint'; }
	elsif($fname =~ /\.ram$/i) { $f_mime = 'audio/realaudio'; }
	elsif($fname =~ /\.rm$/i)  { $f_mime = 'application/realmedia'; }
	elsif($fname =~ /\.mpg$/i) { $f_mime = 'video/mpeg'; }
	elsif($fname =~ /\.mp3$/i) { $f_mime = 'audio/mpeg'; }
	elsif($fname =~ /\.swf$/i) { $f_mime = 'application/x-shockwave-flash';  }
	else 					   { $f_mime = 'application/octet-stream'; }	# それ以外

	return ($f_mime);

}


#-----------------------------------------------------------#
#-----------------------------------------------------------#
#END_OF_SCRIPT