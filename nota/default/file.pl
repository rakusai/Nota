#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2006/05/26
#LastUpdate: 2006/05/26
#-----------------------------------------------------------#

use utf8;
binmode STDIN,  ":bytes"; 
binmode STDOUT, ":encoding(utf-8)"; 

#-----------------------------------------------------------#
#-- ファイル存在確認 ---------------------------------------#
sub existFile
{
	my ( $from ) = shift;

	#コード変換
#	utf8::encode($from); #utf8フラグを取る
#	&nota_convert($from,'shiftjis','utf8');#shiftJISに変換
	if (-e $from){
		return 1;
	}else{
		return 0;
	}

}


#-----------------------------------------------------------#
#-- ファイルコピー -----------------------------------------#
sub copyFile
{
	my ( $from, $to ,$encode ) = @_ ;
	
	#ディレクトリの作成
	$to =~ /^(.*)\//g;
	my $todir = $1;
	if (! (-e $todir)){
		mkdir($todir,0755);	
	}
	
	#コード変換
	if ($encode){
		utf8::encode($from); #utf8フラグを取る
		&nota_convert($from,'shiftjis','utf8');#shiftJISに変換
		utf8::encode($to); #utf8フラグを取る
		&nota_convert($to,'shiftjis','utf8');#shiftJISに変換
	}
	
	#コピー
	my $result = 0;
	if( open( FROM, "< $from") ){
		binmode( FROM );
		if( open( DATA, "> $to") ){
			binmode( DATA );
			print DATA <FROM>;
			close( DATA ) ;
			$result = 1;
		}
		close( FROM ) ;
	}
	return $result;
}

#-----------------------------------------------------------#
#--  フォルダ内のファイルを全て削除しフォルダも削除 --------#
sub deleteDirectory
{
	my ($dir,$unlink) = @_;

	#ディレクトリを開く
	if (!opendir(DIR,"$dir/")) { 
		return 0;
	}
	my $fname = "";
	while (defined($fname = readdir(DIR))){
		if ($fname !~ /^[\.]+$/){
			if ($unlink){
				#完全削除
				unlink("$dir/$fname");
			}else{
				#ゴミ箱に移動
				&deleteFile($dir, $fname);
			}
		}
	}
	closedir(DIR);
	
	#フォルダも削除
	rmdir($dir);
	
	return 1;
}

#-----------------------------------------------------------#
#-- ファイルをゴミ箱に移動 ---------------------------------#
sub deleteFile
{
	#ゴミ箱側は$pageフォルダを自動で補う
	
	my ($dir,$fname) = @_;
	#ファイルが存在しない
	if (! (-e "$dir/$fname")){
		return 0;
	}
	#ゴミ箱に同一の名前のファイルが存在するなら、前のファイルを削除
	if (-e "$m_trashdir/$page/$fname"){
		unlink ("$m_trashdir/$page/$fname");
	}
	#必要ならゴミ箱にフォルダを作成
	if (! (-e "$m_trashdir/$page")){
		mkdir("$m_trashdir/$page",0755);	#ディレクトリの作成
	}
	#移動
	return rename ("$dir/$fname","$m_trashdir/$page/$fname");
}

1;