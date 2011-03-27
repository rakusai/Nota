#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/08/14
#LastUpdate: 2005/11/11
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
#--  メインプログラム --------------------------------------#
sub main
{
	#デコード
	local %FORM = ();
	&nota_get_form(\%FORM);
	local %COOKIE = ();
	&nota_get_cookie(\%COOKIE);

	#ログイン情報の取得
	local $login = NOTA::Login->new;
	$login->getlogin(\%COOKIE);

	#パスを代入
	local $mfile = $m_memberpath;
	local $pwfile = $m_passwdpath;
	my $action = $FORM{'action'};
	
	#アカウント操作
	if ($action eq "certify" || $action eq "login"){
		#ログイン
		&dologin;
	}elsif ($action eq 'getlist'){
		#アカウントの一覧を返す
		&getlist;
	}elsif ($action eq 'record'){
		#アカウントを登録
		&record;
	}elsif ($action eq 'delete'){
		#アカウントを削除
		&delete;
	}else{
		#それ以外
		&error;
	}
}

#-----------------------------------------------------------#
#--  管理者権限があるかチェック ----------------------------#
sub checkAdmin
{
	if ($login->get_power ne 'admin'){
		#管理者ではないのでエラー出力
		&error;
		return 0;
	}
	return 1;

}

#-----------------------------------------------------------#
#--  ログイン処理 ------------------------------------------#
sub dologin
{
	#ログイン
	$user     = $FORM{'user'};
	$pass     = $FORM{'pass'};
	$remember = $FORM{'autologin'};
	
	$login->dologin($user, $pass, $remember);
	
	if ($login->get_power eq ""){
		#認証失敗
		&error;
		return;
	}else{
		#認証成功
		print "Pragma: no-cache\n";
		print "Cache-Control: no-cache\n";
		print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
		print "Content-type: text/plain; charset=utf-8\n\n";
		print "res=OK&";
		print "user=" . $login->get_user . "&";
		print "power=" . $login->get_power . "&";
		print "anonymous=" . $login->get_anonymous . "&";
	}
}

#-----------------------------------------------------------#
#--  アカウントの一覧を返す --------------------------------#
sub getlist
{
	#管理者のみ
	if (!checkAdmin()){
		return;
	}

	#読み出したメンバー情報を出力
	if (!open(DATA,"< $mfile")) { 
		&error;
		return;
	}
	my @lines = <DATA>;
	close(DATA);
	
	#結果を出力する
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
	print "Content-type: text/plain; charset=utf-8\n\n";
	
	#並べ替えよ！
	@lines = sort(@lines);

	my $i = 0;
	foreach (@lines){
		#データを見る
		my ($del,$name,$password,$power,$etc) = split(/,/,$_);
		
		if ($del eq '0'){
			print "name$i=$name&";
			print "pw$i=$password&";
			print "power$i=$power&";
			$i++;
		}
	}
	print "res=OK&";
	
}



#-----------------------------------------------------------#
#--  アカウント削除 ----------------------------------------#
sub delete
{
	#管理者のみ
	if (!checkAdmin()){
		return;
	}

	my $f_name = $FORM{'name'};

	#バリデーション
	&nota_validate($f_name);

	#削除する
	if ($f_name eq $user){
		#自分は削除できない
		&error;
		return;
	}
	#ファイルを開く
	if (!open(DATA,"+< $mfile")) { 
		&error;
		return;
	}
	flock(DATA,2);	#ロック
	my @lines = <DATA>;
	
	my $found = 0;
	foreach (@lines){
		#データを見る
		my($del,$name,$password,$power,$etc) = split(/,/,$_);
		
		if ($name eq $f_name && $del eq '0'){
			#一致
			$_ = "1,$name,$password,$power,\n";
			$found = 1;
			last;
		}
	}
	if ($found == 0){
		#見つからない
		close(DATA);
		&error;
		return;
	}
	#書き込み
	truncate(DATA, 0);		#ファイルサイズを0byteに
	seek(DATA, 0, 0);			#書き込み位置を先頭に
	print DATA @lines;
	#ファイルを閉じる
	close(DATA);
	#パスワードファイルの生成
	&createpwfile(@lines);

	#最後に結果を出力する
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
	print "Content-type: text/plain; charset=utf-8\n\n";
	print "res=OK&";
}

#-----------------------------------------------------------#
#--  アカウント追加／更新 ----------------------------------#
sub record
{
	my $f_name =     $FORM{'name'};
	my $f_power =    $FORM{'power'};
	my $f_param =    $FORM{'param'};
	my $f_password = $FORM{'password'};
	
	#バリデーション
	&nota_validate($f_name);
	&nota_validate($f_power);
	&nota_validate($f_param);
	&nota_validate($f_password);
	
	#権限のチェック
	if ($f_power ne "admin" && $f_param eq "add" && $anonymous eq "signup"){
		#$anonymous=signupなら、だれでも会員orゲストが作れる
	}else{
		#それ以外の処理は管理人のみが可能
		if (!checkAdmin()){ #無理なら&errorを出力
			#更新処理または、管理人の作成は管理者しか認めない
			return;
		}
	}
	
	#情報を書き込む（一つずつ）
	#パスワードが空欄なら、権限の情報だけ書き込む
	if ($f_name eq "" || $f_password eq ""){
		#名前もしくはパスワードがない
		&error;
		return;
	}
	if ($f_name eq $user){
		#自分は管理者しかなれない
		$f_power = 'admin';
	}
	#ファイルを開く
	if (!open(DATA,"+< $mfile")) { 
		&error;
		return;
	}
	flock(DATA,2);	#ロック
	my @lines = <DATA>;
	
	if ($f_param eq 'add'){
		#新しい人
		foreach (@lines){
			#データを見る
			my($del,$name,$password,$power,$etc) = split(/,/,$_,5);
			
			if ($name eq $f_name && $del eq '0'){
				#すでに存在するエラー
				close(DATA);
				&error;
				return;
			}
		}
		my $line = "0,$f_name,$f_password,$f_power,\n";
		push (@lines,$line);
		#追加書き込み
		seek(DATA, 0, 2);			#書き込み位置を最後に
		print DATA $line;
	}else{
		#上書き
		foreach (@lines){
			#データを見る
			my ($del,$name,$password,$power,$etc) = split(/,/,$_,5);
			
			if ($name eq $f_name && $del eq '0'){
				#一致
				$password = $f_password if (defined($f_password));
				$power = $f_power if (defined($f_power));
				$del = 0;
			}
			$_ = "$del,$name,$password,$power,$etc";
		}
		#書き込み
		truncate(DATA, 0);		#ファイルサイズを0byteに
		seek(DATA, 0, 0);			#書き込み位置を先頭に
		print DATA @lines;
	}
	#ファイルを閉じる
	close(DATA);
	#パスワードファイルの生成
	&createpwfile(@lines);
	
	#自分のパスワードを変更した場合は、再ログインする
	if ($f_name eq $login->get_user && $f_param ne 'add'){
		$login->dologin($f_name, $f_password, $login->get_remember);
		if ($login->get_power eq ""){
			#認証失敗
			&error;
			return;
		}
	}
	#最後に結果を出力する
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
	print "Content-type: text/plain; charset=utf-8\n\n";
	print "res=OK&";
	
}

#-----------------------------------------------------------#
#--  パスワードファイル生成 --------------------------------#
sub createpwfile
{
	#BASIC認証用のパスワードファイルを作成
	my (@lines) = @_;
	my @pwlines = ();
	foreach (@lines){
		#データを見る
		my($del,$name,$password,$power,$etc) = split(/,/,$_);
		
		if ($del ne '1'){
			push (@pwlines, "$name:" . encrypt($password) . "\n");
		}
	}
	
	if (open(DATA,"> $pwfile")) {
		print DATA @pwlines;
		close(DATA);
		return 1;
	}else{
		return 0;
	}

}


#-----------------------------------------------------------#
#-- crypt暗号 ----------------------------------------------#
sub encrypt {
	my ($in) = @_;
	my ($salt, $enc, @s);
	if ($in eq ''){
		return '';
	}

	@s = ('a'..'z', 'A'..'Z', '0'..'9', '.', '/');
	srand;
	$salt = $s[int(rand(@s))] . $s[int(rand(@s))];
	$enc = crypt($in, $salt) || crypt ($in, '$1$' . $salt);
	$enc;
}

#-----------------------------------------------------------#
#-- crypt照合 ----------------------------------------------#
sub decrypt {
	my ($in, $dec) = @_;

	my $salt = $dec =~ /^\$1\$(.*)\$/ && $1 || substr($dec, 0, 2);
	if (crypt($in, $salt) eq $dec || crypt($in, '$1$' . $salt) eq $dec) {
		return (1);
	} else {
		return (0);
	}
}

#-----------------------------------------------------------#
#--  エラー処理  -------------------------------------------#
sub error
{
	print "Content-type: text/plain; charset=utf-8\n\n";
	print "res=ERR&\n";
}


#-----------------------------------------------------------#
#END_OF_SCRIPT