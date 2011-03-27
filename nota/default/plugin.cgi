#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/08/14
#LastUpdate: 2005/12/18
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
	
	local %COOKIE = ();
	&nota_get_cookie(\%COOKIE);

	local %FORM = ();
	&nota_get_form(\%FORM);
	
	#ログイン情報の取得
	local $login = NOTA::Login->new;
	$login->getlogin(\%COOKIE);
	
	#ページの取得
	local $page = $FORM{'page'};
	local $fname = $FORM{'fname'};
	if (!defined($page) || $page eq ""){
		#頁が空白
		&error;
		return;
	}
	if (!defined($fname) || $fname eq ""){
		#ファイル名が空白
		&error;
		return;
	}
	
	#バリデーション
	&nota_validate($page);
	&nota_validate($fname,'path');
	
	#扱うデータのパス
	local $data_path = "$m_imgdir/$page/$fname";
	local $page_path = "$m_datadir/$page.ndf";
	
	my $action = $FORM{'action'};
	if ($action eq "write"){
		#書き込み
		&writeData;
	}elsif ($action eq "read" ){
		#読み込み
		&readData;
	}else{
		#エラー
		&error;
	}
	
}

#-----------------------------------------------------------#
#-- ファイル書き込み ---------------------------------------#
sub writeData
{
	my $objectid = $fname;
	$objectid =~ s/\.\w+$//g;
	#ファイル保存
	#存在しないときは作成する
	if (! (-e "$data_path")){
		if (!&makeData){
			&error;
			return;
		}
	}
	
	#既存データを書き込み権限つきで読み込み
	my $io = IO::File->new($data_path, '+<');
	if (!$io){
		&error;
		return;
	}
	flock($io, 2); #ファイルロック
	my @lines = $io->getlines;
	
	#XMLをリストにする
	my $ndf = NOTA::NDF->new;
	if (!$ndf->parse("@lines")){
		$io->close;
		&error;
		return;
	}

	#ファイルの更新日時を得る
	my $preftime = localtime( (stat("$data_path"))[9]);
	#ログトルか？
	my $logtext = "";
	my $undotext = "";
	
	my $local_date = &getLocalDate;
	my %delid = ();
	my $LOG = "";

	foreach (keys(%FORM)){
		if ($_ =~ /^(\w*)\.(\w*)/){
			
			my $id = $1;
			my $param = $2;
			my $value = $FORM{$_};
			
			#値の追加
			if ($value eq""){
				$oldvalue = $ndf->deleteItem($id,$param);
				if ($oldvalue ne ""){
					$LOG .= "$id.$oldvalue";
				}
			}else{
				$oldvalue = $ndf->setItem($id,$param,$value);
				if ($oldvalue ne ""){
					$LOG .= "$id.$oldvalue";
				}else{
					$LOG .= "$id.$param=>\n";
				}
			}
		}
	}
	#ページの更新日時を変更
	$ndf->setItem('head','update',$local_date);
	#上書き処理
	$io->seek(0, 0);		#書き込み位置を先頭に
	$ndf->write($io);
	$io->truncate(tell($io));		#ファイルサイズを調整
	$io->close;
	
	#ログファイルに出力
	if (open(DATA,">> $page_path.log")) {
		binmode DATA, ":encoding(utf-8)"; #utf8フラグを落として出力
		flock(DATA, 2);			#ロック
		$LOG =~ s/\n$//sg;
		$LOG =~ s/\t/\\t/sg;
		$LOG =~ s/\n/\t/sg;
		my $user  = $login->get_user;
		my $power = $login->get_power;
		if ($power eq ""){
			#ログ保存のためにログアウト状態のときは"none"に置換
			$user = "none";
			$power = "none";
		}
		print DATA "$local_date\t$user\t$power\tPLUGIN\t$objectid\t$LOG\n";
		close(DATA);
	}
	#（書き込み後の）ファイルの更新日時を得る
	my $ftime = localtime( (stat("$data_path"))[9]);
	
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
	print "Content-type: text/plain; charset=utf-8\n\n";
	print "preftime=$preftime&";
	print "ftime=$ftime&";
	print "update=$local_date&res=OK&";
	
}

#-----------------------------------------------------------#
#--  ページのデータを返す ----------------------------------#
sub readData
{

	#存在しないときは旧バージョンの存在を疑う
	if (! (-e "$data_path")){
		if (!&makeData){
			&error;
			return;
		}
	}
	#開く
	my $oldver = 0;
	
	my $ndf = NOTA::NDF->new;
	if (!$ndf->parsefile($data_path)){
		&error;
		return;
	}
	
	#ファイルの更新日
	my $ftime = localtime( (stat("$data_path"))[9]);
	
	#出力
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
	print "Content-type: text/plain; charset=utf-8\n\n";
	print "ftime=$ftime&page=$page&";

	my $i = 0;#ID番号
	my $ref_array = $ndf->get_ndfarray;
	foreach (@$ref_array){
		if ($_ =~ /^(\w*):(\w*)=(.*)/){
			my $id = $1;
			my $param = $2;
			my $value = $3;
			#値のurlエンコード
			$value =~ s/%/%25/g;	#まず、これ
			$value =~ s/\+/%2B/g;	#エンコード
			$value =~ s/&/%26/g;	#エンコード
			print "$id.$param=$value&";
			$i += 1;
		}
	}
	print "res=OK&";

}

#-----------------------------------------------------------#
#-- 新規ページの作成 ---------------------------------------#
sub makeData
{
	#新規ページの作成
	if (-e "$data_path"){
		#すでに存在します
		&error;
		return 0;
	}

	#XMLをリストにする
	my $ndf = NOTA::NDF->new;
	
	#旧バージョンを開けるなら
	my $old_path = $data_path;
	$old_path =~ s/\.xml$/\.txt/g;
	
	if (open(DATA,"< $old_path")) { 
		local @lines = <DATA>;
		close(DATA);
		#旧バージョンを変換する
		if (!&convertData("@lines",$ndf)){
			&error;
			return 0;
		}
	}
	
	my $local_date = &getLocalDate;
	#ヘッダ
	$ndf->setItem('head','date',$local_date);
	$ndf->setItem('head','update',$local_date);
	
	#ページ書き込み
	mkdir("$m_imgdir/$page",0755);	#ディレクトリの作成
	$ndf->writefile($data_path);
	
	return 1;
}


#-----------------------------------------------------------#
#--  ページのデータを旧バージョンから変換する --------------#
sub convertData
{
	my ($line, $ndf) = @_;
	#カウンターかどうか
	if ($line =~ /^count=(\d+).?.?date=([\w\.\/]+)/s){
		my $count = $1;
		my $date = $2;
		$ndf->setItem("head","date",$date);
		$ndf->getItem("default","count",$count);
		return 1;
	}
	#掲示板かどうか？
	my $isbbs = 0;
	my @list = split(/\<\|\>/,$line);
	foreach(@list){
		my ($id,$date,$name,$email,$text) = split(/\<\>/,$_);
		if ($id > 0){
			$ndf->getItem($id,"date",$date);
			$ndf->getItem($id,"name",$name);
			$ndf->getItem($id,"email",$email);
			$ndf->getItem($id,"text",$text);
			$isbbs = 1;
		}
	}

	return $isbbs;
	

}
#------------------------------------------------------------#
#--  現在日時を取得 -----------------------------------------#
sub getLocalDate
{
	my ($sec,$min,$hour,$mday,$month,$year,$wday) = localtime(time + $diff*60*60);
	$month++;
	my @num =("00","01","02","03","04","05","06","07","08","09");
	$month = $num[$month] if ( $month<=9 );
	$mday  = $num[$mday]  if ( $mday<=9 );
	$hour  = $num[$hour]  if ( $hour<=9 );
	$min   = $num[$min]   if ( $min<=9 );
	$sec   = $num[$sec]   if ( $sec<=9 );
	$year += 1900;
	my $temp =  "$year/$month/$mday $hour:$min:$sec";
	
	return ($temp);
}

#-----------------------------------------------------------#
#--  エラー処理 --------------------------------------------#
sub error
{
	print "Content-type: text/plain; charset=utf-8\n\n";
	print "res=ERR&\n";
}



#-----------------------------------------------------------#
#END_OF_SCRIPT