#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#Created: 2007/02/26
#ファイルの複製、削除、ディレクトリの削除などを行うパッケージ
#-----------------------------------------------------------#

package NOTA::SimpleFile;

use utf8;
binmode STDIN,  ":bytes"; 
binmode STDOUT, ":encoding(utf-8)"; 

use strict;
use warnings;

#-----------------------------------------------------------#
#--  コンストラクタ ----------------------------------------#
sub new
{
	my $class = shift;
	my $self  = {};
	bless ($self, $class);
}

#-----------------------------------------------------------#
#-- ファイル存在確認 ---------------------------------------#
sub existFile
{
	my ($self, $from ) = @_;

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
	my ($self, $from, $to ,$encode ) = @_ ;
	
	#ディレクトリの作成
	$to =~ /^(.*)\//g;
	my $todir = $1;
	if (! (-e $todir)){
		mkdir($todir,0755);	
	}
	
	#コード変換
	if ($encode){
		utf8::encode($from); #utf8フラグを取る
		main::nota_convert($from,'shiftjis','utf8');#shiftJISに変換
		utf8::encode($to); #utf8フラグを取る
		main::nota_convert($to,'shiftjis','utf8');#shiftJISに変換
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
#-- ファイルをゴミ箱に移動 ---------------------------------#
sub deleteFile
{
	#ゴミ箱側は$pageフォルダを自動で補う
	
	my ($self, $dir,$fname,$trashdir) = @_;
	#ファイルが存在しない
	if (! (-e "$dir/$fname")){
		return 0;
	}
	
	#ゴミ箱に同一の名前のファイルが存在するなら、前のファイルを削除
	if (-e "$trashdir/$fname"){
		unlink ("$trashdir/$fname");
	}
	#必要ならゴミ箱にフォルダを作成
	if (! (-e "$trashdir")){
		mkdir("$trashdir",0755);	#ディレクトリの作成
	}
	#移動
	return rename ("$dir/$fname","$trashdir/$fname");
}

#-----------------------------------------------------------#
#--  フォルダ内のファイルを全て削除しフォルダも削除 --------#
sub deleteDirectory
{
	my ($self, $dir,$unlink,$trashdir) = @_;

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
				$self->deleteFile($dir, $fname, $trashdir);
			}
		}
	}
	closedir(DIR);
	
	#フォルダも削除
	rmdir($dir);
	
	return 1;
}

#-----------------------------------------------------------#
#----- ディレクトリのサイズを取得する ----------------------#
sub getDirectorySize
{
	my ($self, $dir) = @_;

	#ディレクトリを開く
	if (!opendir(DH,"$dir")) { 
		return 0;
	}
	my $allsize = 0;
	my $fname;
	my @files = readdir(DH);
	closedir(DH);
	foreach $fname (@files){
		next if ($fname eq '.');
		next if ($fname eq '..');
		
		#ディレクトリなら
		if ( -d "$dir/$fname"){
			#再帰的にサイズを取得して足す
			$allsize += $self->getDirectorySize("$dir/$fname");
			
		}else{
			#ファイルならサイズを取得
			my $size = -s "$dir/$fname";
			if ($size > 0){
				$allsize += $size;
			}
		}
	}
	
	return $allsize;

}



#-----------------------------------------------------------#
#END_OF_SCRIPT
1;