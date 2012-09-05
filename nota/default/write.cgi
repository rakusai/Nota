#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/08/14
#LastUpdate: 2006/02/01
#-----------------------------------------------------------#

require 'option.pl';
require 'nota.pl';

use utf8;
use MIME::Base64 qw(encode_base64 decode_base64);
use IO::File;
use notalib::Login;
use notalib::SimpleFile;
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
	
	#ファイル操作クラス
	local $file = NOTA::SimpleFile->new;

	#ログイン情報の取得
	local $login = NOTA::Login->new;
	$login->getlogin(\%COOKIE);
	
	if ($login->get_power eq ''){
		#権限なし！
		&error;
		return;
	}
	
	#ページの取得
	local $page = $FORM{'page'};
	if (!defined($page) || $page eq ""){
		#頁が空白
		&error;
		return;
	}
	
	#バリデーション
	&nota_validate($page);
	
	#パス
	local $page_path = "$m_datadir/$page.ndf";
	
	my $action = $FORM{'action'};
	if ($action eq "mkpage"){
		#新規ページ作成
		&makePage;
	}elsif ($action eq "rmpage" ){
		#ページの削除
		&removePage;
	}elsif ($action eq "record" ){
		#ページの書き換え
		&writePage;
	}elsif ($action eq "master" ){
		#マスターページの適用
		&setMasterPage;
	}else{
		#エラー
		&error;
	}
}

#-----------------------------------------------------------#
#-- 新規ページの作成 ---------------------------------------#
sub makePage
{
	#新規ページの作成
	if ($page eq 'home' || -e "$page_path"){
		#すでに存在します
		&error("exist");
		return;
	}
	if ($login->get_power ne 'admin' && $login->get_power ne 'member'){
		#作成権限なし
		&error("power");
		return;
	}
	
	#データ容量
	my $userdir = $m_imgdir; #imgフォルダの一つ上の階層
	$userdir =~ s/\/img//g;
	my $file = NOTA::SimpleFile->new;
	my $used_size = $file->getDirectorySize($userdir);
	$used_size = int($used_size / 1024 / 1024 * 10) / 10;
	if ($used_size >= $m_max_imgdir_size){
		#容量オーバー
		&error("capacity");
		return;
	}

	#新規ページのタイトル
	$title = $FORM{'title'};
	#バリデーション
	&nota_validate($title,'text');
	#UTF-8フラグを立てる
	utf8::decode($title);
	
	#日付
	my $date = &getLocalDate();

	#XMLをリストにする
	my $ndf = NOTA::NDF->new;
	
	#ヘッダのデフォルト値をセット
	$ndf->setItem('head','id',$page);
	$ndf->setItem('head','date',$date);
	$ndf->setItem('head','update',$date);
	$ndf->setItem('head','version','2.0');
	$ndf->setItem('head','title',$title);
	$ndf->setItem('head','author',$login->get_user);
	$ndf->setItem('head','width','800');
	$ndf->setItem('head','height','1131');
	
	#ページ書き込み
	if (!$ndf->writefile("$m_datadir/$page.ndf")){
		&error("open");
		return;
	}

	#マスターページを適用して終了
	&setMasterPage();
	
}

#-----------------------------------------------------------#
#-- ページの削除 -------------------------------------------#
sub removePage
{
	#ページの削除
	if ($page eq 'home'){
		#ホームは消せません
		&error;
		return;
	}
	if ($login->get_power ne 'admin' && $login->get_power ne 'member'){
		#削除権限なし
		&error;
		return;
	}
	#XMLを読み込む
	my $ndf = NOTA::NDF->new;
	if (!$ndf->parsefile($page_path)){
		&error;
		return;
	}
	
	my $author = $ndf->getItem('head','author');
	my $edit = $ndf->getItem('head','edit');

	#作成者
	if ($login->get_power ne 'admin' && ($author eq '' || $login->get_user ne $author)){
		#削除権限なし
		&error;
		return;
	}
	
	#凍結されている
	if ($login->get_power ne 'admin' && $edit eq 'admin'){
		#ページが凍結されており、書き込み権限なし
		&error;
		return;
	}
	my $trashdir = "$m_trashdir/$page";
	
	#画像は全ファイルをゴミ箱に移動
	$file->deleteDirectory("$m_imgdir/$page",0,$trashdir);
	
	#手描き線は全ファイルを完全に削除
	$file->deleteDirectory("$m_drawingdir/$page",1,$trashdir);
	
	#ページのデータとログをゴミ箱に移動
	my $deleted=0;
	if ($file->deleteFile($m_datadir, "$page.ndf",$trashdir))
	{
		$file->deleteFile($m_datadir, "$page.ndf.log",$trashdir);	#ログファイル
		$file->deleteFile($m_datadir, "$page.csv",$trashdir);	#旧データファイル
		$file->deleteFile($m_datadir, "$page.dat",$trashdir);	#旧ヘッダファイル
		$file->deleteFile($m_datadir, "$page.csv.undo",$trashdir);	#旧ログファイル
		$file->deleteFile($m_datadir, "$page.csv.log",$trashdir);	#旧ログファイル
		$deleted = 1;
	}
	
	#結果を出力
	print "Content-type: text/plain; charset=utf-8\n\n";
	if ($deleted > 0){
		print "res=OK&deleted=$deleted";
	}else{
		print "res=ERR";
	}

}


#-----------------------------------------------------------#
#-- ファイル書き込み ---------------------------------------#
sub writePage
{
	#既存データ読み込み
	#ファイルを読み込んでから解析
	my $io = IO::File->new($page_path, '+<');
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
	#凍結
	if ($login->get_power ne 'admin' && $ndf->getItem('head','edit') eq 'admin'){
		#ページが凍結されており、書き込み権限なし
		$io->close;
		&error;
		return;
	}

	#ファイルの更新日時を得る
	my $preftime = localtime( (stat("$page_path"))[9]);
	my $logtext = "";
	my $undotext = "";
	my $changeedit = 0; #凍結情報を操作
	my $item_last_update = "";
	my $pageauthor = $ndf->getItem('head','author');
	
	local $local_date = &getLocalDate;
	my %delid = ();
	my %LOG = ();
	my %LOGCOMMAND = ();

	foreach (keys(%FORM)){
		if ($_ =~ /^([\w\-_]+):([\w\-_]+)/){
			
			my $id = $1;
			my $param = $2;
			my $value = $FORM{$_};
			my $author = $ndf->getItem($id,'author');
			if ($id ne 'head' && !$ndf->getItem($id,'date') && !($FORM{"$id:tool"})){
				#削除済みのアイテムを編集しようとしている
				$delid{$id} = 1;
			}
			if (defined($delid{$id})){
				#削除済みIDをスキップ
				next;
			}
			if ($id ne 'head' && $login->get_power ne 'admin' &&
				$login->get_user ne $pageauthor && $login->get_user ne $author && defined($author))
			{
				#管理人以外が他人のページの人の部品を操ろうとしている
				$io->close;
				&error;
				return;
			}
			if ($id eq 'head' && $param eq 'edit'){
				#凍結情報を操作
				$changeedit = 1;
			}
			if ($param eq 'text'){
				#HTMLを一部加工（すでにエスケープされている）
				$value =~ s/&apos;/'/g; 	#「'」が&apos;になるが、後で自分が処理できない
				$value =~ s/(\r|\n)//g;	#HTMLなので改行はとる
				$value =~ s/<.?TEXTFORMAT.*?>//g;
				$value =~ s/<FONT FACE="[^"]*"/<FONT/g;
				#link指定の&page=以降を削除
				$value =~ s/<A HREF="link\.cgi\?page=([a-zA-Z0-9]*)&url=([^"]*)"/<A HREF="link\.cgi\?url=$2"/g;
			}else{
				#テキストを一部加工（エスケープされていない）
				$value =~ s/(\r|\n)//g;	#改行はとる
			}
			if ($param eq 'id'){
				#日付の更新
				if (!$ndf->getItem($id,'date')){
					$LOG{"$id"} .= $ndf->setItem($id,'date',$local_date);
					$LOGCOMMAND{"$id"} = "INSERT";
				}
				if ($id ne 'head'){
					#headの更新日の書き換えは最後に
					$item_last_update = $ndf->getItem($id,'update');
					$LOG{"$id"} .= $ndf->setItem($id,'update',$local_date);
				}
			}elsif ($param eq 'del'){
				#部品の削除
				if ($value eq '1'){
					#付属のファイルを削除せよ！
					$fname = $ndf->getItem($id, 'fname');
					if ($fname ne ''){
						my $fname_sjis = $fname;
						utf8::encode($fname_sjis); #utf8フラグを取る
						&nota_convert($fname_sjis,'shiftjis','utf8');#shiftJISに変換
						my $trashdir = "$m_trashdir/$page";
						$file->deleteFile("$m_imgdir/$page",encode_base64url($fname),$trashdir); 
						$file->deleteFile("$m_imgdir/$page",$fname_sjis,$trashdir);
					}
					$delid{$id} = 1;
					$LOG{"$id"} = $ndf->deleteItem($id);
					$LOGCOMMAND{"$id"} = "DELETE";
				}
			}else{
				#値の追加
				$LOG{"$id"} .= $ndf->setItem($id,$param,$value);
				if (!$LOGCOMMAND{"$id"}){ $LOGCOMMAND{"$id"} = "UPDATE";}
			}
		}
	}
	#ページの更新日時を変更
	if (!$changeedit){
		$ndf->setItem('head','update',$local_date);
	}
	#上書き処理
	$io->seek(0, 0);		#書き込み位置を先頭に
	$ndf->write($io);
	$io->truncate(tell($io));		#ファイルサイズを調整
	$io->close;
	
	#ログファイルに出力
	if (open(DATA,">> $page_path.log")) {
		binmode DATA, ":encoding(utf-8)"; #utf8フラグを落として出力
		flock(DATA, 2);			#ロック
		foreach ((sort keys %LOG)){
			$LOG{$_} =~ s/\n$//sg;
			$LOG{$_} =~ s/\t/\\t/sg;
			$LOG{$_} =~ s/\n/\t/sg;
			$command = $LOGCOMMAND{$_};
			print DATA "$local_date\t" . $login->get_user . "\t" . $login->get_power . "\t$command\t$_\t" . $LOG{$_} . "\n";
		}
		close(DATA);
	}
	#ログファイルの容量リミットは？
	
	#（書き込み後の）ファイルの更新日時を得る
	my $ftime = localtime( (stat("$page_path"))[9]);
	
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
	print "Content-type: text/plain; charset=utf-8\n\n";
	
	print "update=$local_date&res=OK&";
	print "changeedit=$changeedit&";
	print "preftime=$preftime&";
	print "ftime=$ftime&";
	print "item_last_update=$item_last_update&";
	print "update=$local_date&res=OK&";
	
}

#-----------------------------------------------------------#
#-- マスターページの適用 -----------------------------------#
sub setMasterPage
{
	#既存データ読み込み
	my $ndf = NOTA::NDF->new;
	if (!$ndf->parsefile($page_path)){
		&error;
		return;
	}
	#凍結
	if ($login->get_power ne 'admin' && $ndf->getItem('head','edit') eq 'admin'){
		#ページが凍結されており、書き込み権限なし
		&error;
		return;
	}
	
	#マスターページのファイル
	my $masterpage = $FORM{'master'};
	my $masterdir = $FORM{'masterdir'};
	my $masterimgdir;
	#バリデーション
	&nota_validate($masterpage);
	&nota_validate($masterdir);
    if ($masterpage eq "" || $masterpage eq "home" || !$masterpage){
            if ($m_datadir =~ /cshirt/){
                    $masterpage = "20080101000";
            }elsif ($m_datadir =~ /henai/){
                    $masterpage = "20060527060327";
            }else{
                    $masterpage = "home";
            }
    }

	#マスターページのディレクトリ
	if ($masterdir eq "" || !$masterdir){
		$master_datadir = "$m_datadir";
		$master_imgdir = "$m_imgdir";
	}else{
		$master_datadir = "$m_notadata_dir/$masterdir/data";
		$master_imgdir = "$m_notadata_dir/$masterdir/img";
	}
	#マスターページの読み込み
	my $masterndf = NOTA::NDF->new;
	if (!$masterndf->parsefile("$master_datadir/$masterpage.ndf")){
		&error("open masterpage");
		return;
	}
	
	#予約語
	my $pre_author = $ndf->getItem('head', 'author');
	my $pre_title  = $ndf->getItem('head', 'title');
	my $pre_today  = substr(&getLocalDate,0,10);
	
	#現在のページから過去のマスター関係データを削除
	my %delid = ();
	my $ref_array = $ndf->get_ndfarray;
	foreach (@$ref_array){
		if ($_ =~ /^([\w\-_]*):([\w\-_]*)=(.*)/){
			my $id = $1;
			my $param = $2;
			my $value = $3;
			if ($param eq 'author' && $value eq 'master'){
				#アイテムの削除
				$delid{$id} = 1;
			}
		}
	}
	foreach $id (keys(%delid)){
		#付属のファイルを削除せよ！
		$fname = $ndf->getItem($id, 'fname');
		if ($fname ne ''){
                	my $fname_sjis = $fname;
                        utf8::encode($fname_sjis); #utf8フラグを取る
                        &nota_convert($fname_sjis,'shiftjis','utf8');#shiftJISに変換
                        my $trashdir = "$m_trashdir/$page";
                        $file->deleteFile("$m_imgdir/$page",encode_base64url($fname),$trashdir);
                        $file->deleteFile("$m_imgdir/$page",$fname_sjis,$trashdir);

		}
		$ndf->deleteItem($id);
	}
	#ページ背景色も削除
	$ndf->deleteItem("head","bgcolor");
	
	#マスターページの内容を現在のページに書き込み
	my $date = time();
	
	$ref_array = $masterndf->get_ndfarray;
	foreach (@$ref_array){
		if ($_ =~ /^([\w\-_]*):([\w\-_]*)=(.*)/){
			my $id = $1;
			my $param = $2;
			my $value = $3;
			if ($id eq "head"){
				if ($param eq "title"){
					$value =~ s/%title%/$pre_title/g;
					$value =~ s/%author%/$pre_author/g;
					$value =~ s/%today%/$pre_today/g;
				}elsif ($param ne "width" && $param ne "height" && $param ne "bgcolor"){
					next;
				}
			}else{
				#IDを変更する
				$id += int($date); 
			}
			#若干手を加える
			if ($param eq "author"){
				#作者はログイン者とする
				$value = "master";
			}
			
			if ($param eq "fname"){
				#画像、プラグインはデータをコピーする
				my $fname = $value;
				$file->copyFile("$master_imgdir/$masterpage/$fname","$m_imgdir/$page/$fname",1);
			}
			if ($param eq "text"){
				#予約後を置換する
				$value =~ s/%title%/$pre_title/g;
				$value =~ s/%author%/$pre_author/g;
				$value =~ s/%today%/$pre_today/g;
			}
			#追加
			$ndf->setItem($id,$param,$value);
		}
	}
	
	#ページ書き込み
	if (!$ndf->writefile("$m_datadir/$page.ndf")){
		&error("open");
		return;
	}
	
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
	print "Content-type: text/plain; charset=utf-8\n\n" ;
	print "res=OK";

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

#------------------------------------------------------------#
#--  エラー処理 ---------------------------------------------#
sub error
{
	my $errcode = shift;
	
	print "Content-type: text/plain; charset=utf-8\n\n";
	print "res=ERR&errcode=$errcode&\n";
}

sub encode_base64url { 
    my $e = shift;
    utf8::encode($e); #utf8フラグを取る
    $e = encode_base64($e, ""); 
    $e =~ s/=+\z//; 
    $e =~ tr[+/][-_]; 
    return $e; 
} 

#-----------------------------------------------------------#
#END_OF_SCRIPT
