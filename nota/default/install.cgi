#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/08/26
#LastUpdate: 2005/12/02
#-----------------------------------------------------------#

require 'option.pl';
require 'nota.pl';

use utf8;
use FindBin;
use notalib::NDF;
use notalib::SimpleFile;

binmode STDIN,  ":bytes"; 
binmode STDOUT, ":encoding(utf-8)"; 


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
	
	local $mode = '';
	local $mode_title = '';
	if ($FORM{'mode'} eq "check"){
		$mode = 'check';
		$mode_title = '動作チェック';
	}elsif ($FORM{'mode'} eq "account"){
		$mode = 'account';
		$mode_title = 'サイト管理';
	}else{
		$mode = 'option';
		$mode_title = 'オプション設定';
	}
	
	#このスクリプトの名前
	local $script_fname = $ENV{'SCRIPT_NAME'};
	$script_fname =~ s/.*\///;
	#このスクリプトの一つ上のパス
	$script_parent_dir = $FindBin::Bin;
	$script_parent_dir =~ s/\/[^\/]*$//;
	
	#ログイン処理
	if ($FORM{'action'} =~ /(login|logout)/)
	{
		#クッキーに保存
		&loginSetCookie($FORM{'master_passwd'});
	}
	if ($FORM{'action'} =~ /(save)/){ 
		#パスワードが変更されている
		if ($m_master_passwd eq $FORM{'master_passwd'}){
			#新旧が一致するなら
			#クッキーに保存
			&loginSetCookie($FORM{'new_master_passwd'});
			$m_master_passwd = $FORM{'new_master_passwd'};
		}
	}
	#ヘッダーの出力
	&printHeader;
	
	#パスワードチェック
	if ($m_master_passwd ne '' && $m_master_passwd ne $COOKIE{'master_passwd'}){
		#ログイン画面を表示
		&loginForm;
		return;
	}
	
	#インストールチェック
	if ($mode eq "check"){
		&checkInstall;
	}elsif ($mode eq "option"){
		&optionFrom;
	}elsif ($mode eq "account"){
		&accountManage;
	}
	#フッターの出力
	&printFooter;

}

#-----------------------------------------------------------#
#ヘッダー出力
sub printHeader
{
	print "Content-type: text/html; charset=utf-8\n\n";
	print <<"END_OF_HEAD";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv=Content-Type content="text/html; charset=utf-8">
	<title>NOTAの管理 - $mode_title</title>
    <style type="text/css">
<!--
body {
	background-color: #CCCCCC;
	padding: 30px;
}
#content {
	background-color: #FFFFFF;
	padding-left: 20px;
	padding-right: 20px;
	border: 1px solid #666666;
}
table {
	border: 1px solid #003399;
}

td {
	border: 1px solid #003399;
	margin: 5px;
	padding: 3px;
}
-->
    </style>
</head>
<body>
	<div id="content">
	<h2><img src="res/nota.png" border="0" align="absmiddle">NOTAの管理 @ $ENV{'HTTP_HOST'}</h2>
	<hr>
	<h4>メニュー：
	<a href="./$script_fname?mode=option">オプション設定</a> | 
	<a href="./$script_fname?mode=check">動作チェック</a> | 
	<a href="./$script_fname?mode=account">サイト管理</a> | 
	<a href="./$script_fname?action=logout">ログアウト</a> | 
	<a href="./">NOTAのトップページを開く</a>
	</h4>
	<hr>
	<h2>$mode_title</h2>
END_OF_HEAD

}

#-----------------------------------------------------------#
#フッター出力
sub printFooter
{
	print <<"END_OF_FOOT";
	</div>
	&copy; Isshu Rakusai <a href="http://nota.jp/">NOTA</a>
	</body>
	</html>
END_OF_FOOT

}

#-----------------------------------------------------------#
#ログイン処理
sub loginSetCookie
{
	$master_passwd = shift;

	#クッキーに保存
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
	print "Set-Cookie: master_passwd=$master_passwd;\n";
	
	$COOKIE{'master_passwd'} = $master_passwd;

}


#-----------------------------------------------------------#
#ログインフォームを出力
sub loginForm
{
	if ($FORM{'action'} eq "login"){
		print "<h4 style=\"color:red\">パスワードが違います。</h4>";
	}

	print <<"END_OF_LOGIN";
	<p>管理画面へログインします。<br>
	マスターパスワードを入力して、[ログイン]ボタンを押してください。</p>
	<form name="form" method="post" action="">
	  <table width="500" border="0" align="center" cellpadding="0" cellspacing="0">
        <tr>
          <td>マスターパスワード<br>
            <input name="action" type="hidden" value="login">
            <input name="master_passwd" type="password" size="30">
            <input type="submit" name="Submit" value="ログイン">
          <br></td>
        </tr>
      </table>
	  </form>
END_OF_LOGIN

}
#-----------------------------------------------------------#
#チェック項目を出力
sub printLine
{
	my ($msg,$ok) = @_;
	print "\t\t<tr><td nowrap>$msg</td>";
	if (length($ok) > 1){
		print "<td nowrap>$ok</td>";
	}elsif ($ok){
		print "<td nowrap><font color=\"green\">OK</font></td>\n";
	}else{
		print "<td nowrap><font color=\"red\">NG</font></td>\n";
	}
	print "\t\t</tr>";
	
}
#-----------------------------------------------------------#
#チェック項目の見出しを出力
sub printLineSubject
{
	my ($msg) = @_;
	print "\t\t<tr><td colspan=\"2\" nowrap><h3>$msg</h3></td></tr>\n";
	
}



#-----------------------------------------------------------#
#インストールチェック

sub checkInstall
{

	print "<p>NOTAの全機能が正しく動作するかチェックします。<br>";
	print "インストールの設定は個別に対応してください。</p>";


#チェック項目
#プログラム
#imagemacgickは入っているか？
#cgiに実行権限はあるか。
#データファイル
#アカウント設定ファイルに書き込み権限はあるか？
#dataファイルに書き込み権限があるか？
#home.ndf(or home.ndf)、template.ndf)はあるか？
#home.ndfは書き込み可能か？
#img,trash,drawingフォルダに書き込み権限があるか確認する。
#テンプレートファイル
#テンプレート画像のメニューファイルはあるか？
#テンプレート画像の i フォルダに書き込み権限はあるか？

#http://の指している場所にメニューファイルはあるか？

	#プログラム
	print "<table>\n";
	printLineSubject("プログラム関連");
	
	printLine("Perlのバージョンは5.8.0以降か",($] ge "5.008"));
	
	
	eval{"use Image::Magick;"};
	printLine("ImageMagickが動作するか",(!$@));

	$ok = 0;
	if (open(DATA,"+< option.pl")) {
		$ok = 1;
	}
	printLine("option.plは書き込み可能か",$ok);

	$permission = "755";
	if (opendir(DIR,"./")) {
		while (defined($fname = readdir(DIR))){
			if ($fname =~ /\.(cgi)$/i){
				@st = stat($fname);
				$p = substr((sprintf "%03o", $st[2]), -3);
				printLine($fname . "のパーミッションは" . $permission . "か",($p eq $permission));
			}
		}
	}

	#ユーザーデータ
	printLineSubject("ユーザーデータ関連");
	$ok = 0;
	if (mkdir("$m_notadata_dir/testdir", 0755)) {
		rmdir("$m_notadata_dir/testdir");
		$ok = 1;
	}
	printLine("notadataフォルダにフォルダを作成可能か",$ok);

	$ok = 0;
	if (-e ("$m_notadata_dir/master/")) {
		$ok = 1;
	}
	printLine("notadataフォルダにmasterフォルダは存在するか",$ok);
	
	my $ok = 0;
	if (open(DATA,"+< $m_memberpath")) {
		$ok = 1;
		close(DATA);
	}
	printLine("accountフォルダの設定ファイルに書き込み可能か",$ok);

	$ok = 0;
	if (open(DATA,"+< $m_passwdpath")) {
		$ok = 1;
		close(DATA);
	}
	printLine("accountフォルダのパスワードファイルに書き込み可能か",$ok);

	$ok = 0;
	if (open(DATA,"> $m_imgdir/test.tmp")) {
		close(DATA);
		unlink("$m_imgdir/test.tmp");
		$ok = 1;
	}
	printLine("imgフォルダに書き込み可能か",$ok);
	$ok = 0;
	if (open(DATA,"> $m_trashdir/test.tmp")) {
		close(DATA);
		unlink("$m_trashdir/test.tmp");
		$ok = 1;
	}
	printLine("trashフォルダに書き込み可能か",$ok);
	$ok = 0;
	if (open(DATA,"> $m_drawingdir/test.tmp")) {
		close(DATA);
		unlink("$m_drawingdir/test.tmp");
		$ok = 1;
	}
	printLine("drawingフォルダに書き込み可能か",$ok);

	$ok = 0;
#	if (-e "$m_datadir/template.ndf"){
#		$ok = 1;
#	}
#	printLine("dataフォルダにtemplate.ndfは存在するか",$ok);

	$ok = 0;
	if (-e "$m_datadir/home.ndf"){
		$ok = 1;
	}
	printLine("dataフォルダにhome.ndfは存在するか",$ok);

	$ok = 0;
	if (open(DATA,"+< $m_datadir/home.ndf")) {
		$ok = 1;
	}
	printLine("dataフォルダのhome.ndfは書き込み可能か",$ok);
	

	
	#テンプレート画像
	printLineSubject("テンプレート画像関連");
	$ok = 0;
	if (-e ("template/$dir/")) {
		$ok = 1;
	}
	printLine("templateフォルダは存在するか",$ok);
	
#	$ok = 0;
#	if (-e "template/template.xml"){
#		$ok = 1;
#	}
#	printLine("templateフォルダにtemplate.xmlは存在するか",$ok);
	
#	$ok = 0;
#	my $ndf = NOTA::NDF->new;
#	if ($ndf->parsefile("template/template.xml")){
#		#データを見る
#		my @idlist = ();
#		$ndf->getBodyIDList(\@idlist);
#		foreach (@idlist){
#			my $dir = $_;
#			#一つ画像を取り出す
#			if (opendir(DIR,"template/$dir/")) {
#				while (defined($fname = readdir(DIR))){
#					if ($fname =~ /\.(jpg|gif|png)$/i){
#						$ok = "<img src=\"template/$dir/$fname\" height=\"30\">";
#						last;
#					}
#				}
#			}
#		}
#	}
#	printLine("templateフォルダの最初の画像は表示されるか",$ok);

	
	print "</table>\n";
		
	print ("\n\t<p>すべての確認が終了しました。<br>すべてOKなら問題なく使用できます。一つでもNGがあれば、問題を修正してください。</p>\n");

	return 1;	
	
}


#------------------------------------------------------------------------#
#-- サイト管理フォームの表示 --------------------------------------------#
sub accountManage
{
	if ($FORM{'action'} eq "add"){
		addAccount($FORM{'site'},$FORM{'admin'},$FORM{'pass'});
		return;
	}
	#削除
	elsif ($FORM{'action'} eq "delete"){
		deleteAccount($FORM{'sitechk'});
		return;
	}
	
	#通常フォーム
	print <<"END_OF_HTML";
		<form action="$script_fname" method="post" name="nota">
			<p>サイトID、管理者ID、パスワードを入力して、<br>
				[追加]ボタンを押して下さい。</p>
			<table width="240">
				<tr><td nowrap>
					<p>サイトID: （http:///sample.jp/nota/○○/ の○○に入る文字。サイト固有のIDを英数半角で）<br>
						<input type="text" name="site" size="24" border="0">						
					</p>
					<p>管理者ID: （tanakaなど。あなたのIDを半角英数で指定）<br>
						<input type="text" name="admin" size="24" border="0"></p>
					<p>管理者の初期パスワード: (忘れない文字を半角英数で設定してください)<br>
						<input type="password" name="pass" size="24" border="0"></p>
					<p><input type="hidden" name="mode" value="$FORM{'mode'}">
					<input type="hidden" name="action" value="add">
					<input type="submit" value="追加" name="add">
					</p>
				</td></tr>
			</table>
		</form>
		
		<form action="$script_fname" method="post" name="nota2">
		<p>サイトIDにチェックをつけて、削除できます。</p>
		<input type="hidden" name="mode" value="$FORM{'mode'}">
		<input type="hidden" name="action" value="delete">
		<table>
END_OF_HTML

	#ユーザーフォルダ一覧
	printLineSubject("ユーザーフォルダ一覧");
	if ($FORM{'getsize'} eq '1'){
		printLine("サイトID","使用容量");
	}else{
		printLine("サイトID","使用容量（<a href=\"$script_fname?mode=$mode&getsize=1\">取得</a>）");
	}
	if (opendir(DIR,"$m_notadata_dir")) {
		while (defined($dir = readdir(DIR))){
			if (-d "$m_notadata_dir/$dir" && !($dir =~ /^\.*$/)){
				if ($FORM{'getsize'} eq '1'){
					my $file = NOTA::SimpleFile->new;
					$size = $file->getDirectorySize("$m_notadata_dir/$dir");
					$size = sprintf( "%0.1f", $size / 1024 / 1024) . " MB";
				}else{
					$size = "--";
				}
				printLine("<input name=\"sitechk\" type=\"radio\" value=\"$dir\">$dir","$size");
			}
		}
	}
	print "</table>\n";
	print "<p><input type=\"submit\" value=\"削除\" name=\"delete\"></p>\n";
	print "</form>\n";


}
#------------------------------------------------------------------------#
#-- サイトの追加 --------------------------------------------------------#
sub addAccount
{
	my ($site,$admin,$pass) = @_;
	
	if ($site eq ""){
		error("サイトIDが入力されていません。");
		return;
	}
	if ($site =~ /default|template|data|master/){
		error("${site}はシステムで利用するため、作成できません。");
		return;
	}
	if (-e "$m_notadata_dir/$site"){
		error("${site}はすでに取られています。");
		return;
	}
	if ($admin eq "" || $pass eq ""){
		error("管理者IDとパスワードが入力されていません。");
		return;
	}
	#プログラム
	if (-e "$script_parent_dir/$site"){
		if (!unlink ("$script_parent_dir/$site")){
			error("既存のプログラムフォルダのシンボリックリンクが削除できません。");
			return;
		}
	}
	if (!symlink( "$script_parent_dir/default", "$script_parent_dir/$site" )){
		error("プログラムフォルダのシンボリックリンクが作成できません。");
		return;
	}
	#データ
	if (!cpdir("$m_notadata_dir/default","$m_notadata_dir/$site")){
		unlink ("$nota_dir/$site");
		error("NOTAデータフォルダがコピーできません。");
		return;
	}
	#データを変更
	if( open( DATA, "> $m_notadata_dir/$site/account/member.csv") ){
		print DATA "0,$admin,$pass,admin,\n";
		close( DATA ) ;
	}else{
		error("アカウントファイルが開けません。");
		return;
	}
	error("${site}を作成しました！",$site);
	
}

#------------------------------------------------------------------------#
#-- サイトの削除 --------------------------------------------------------#
sub deleteAccount
{
	my ($site) = @_;

	if ($site eq ""){
		error("サイトIDが入力されていません。");
		return;
	}
	if ($site =~ /default|template|data|master/){
		error("${site}はシステムで利用するため、削除できません。");
		return;
	}
	if (!-e "$m_notadata_dir/$site"){
		error("${site}は存在しません。");
		return;
	}
	#データ
	if (!rename ("$m_notadata_dir/$site","$m_notadata_dir/DEL_$site")){
		error("データフォルダの名前を変更できません。");
		return;
	}
	#プログラム
	if (-e "$script_parent_dir/$site"){
		if (!unlink ("$script_parent_dir/$site")){
			error("プログラムフォルダが削除できません。");
		}
	}
	
	error("${site}を削除しました！");

}

#------------------------------------------------------------------------#
#-- ディレクトリのコピー ------------------------------------------------#
sub cpdir
{
	my ($from_dir,$to_dir) = @_;

	if (-e $to_dir){
		return 0;
	}

	if (!mkdir ($to_dir,0707)){
		return 0;
	}
	$str = system "cp -r -p $from_dir/* $to_dir";
	if ($str eq ""){
		return 0;
	}

	return 1;
}

#------------------------------------------------------------------------#
#-- エラー処理 ----------------------------------------------------------#
sub error
{
	my ($error_msg,$site) = @_;
	
	my $toppage = '';
	if (defined($site)){
		$toppage = "<a href=\"../$site/\">${site}のトップページへ移動</a>";
	}else{
		$toppage = "<a href=\"javascript:history.back();\">戻る</a>";
	}

	print <<"END_OF_ERROR";
		<center>
		<h2 style="color:#800000;">$error_msg</h2>
		<br><br>
		<p>[ $toppage ]</p>
		</center>
END_OF_ERROR

}

#------------------------------------------------------------------------#
#-- オプション設定の表示 ------------------------------------------------#
sub optionFrom
{
	if ($FORM{'action'} eq "save"){
		if (&saveOption != 1){
			return;
		}
	}
	if ($m_master_passwd eq "" || !$m_master_passwd){
		$errormsg1 = "<font color=\"red\">マスターパスワードが空です。</font>";
	}
	if (! -e $m_notadata_dir){
		$errormsg2 = "<font color=\"red\">フォルダは存在しません。</font>";
	}
	
	
	print <<"END_OF_HTML";
	<p>NOTAのオプションを設定します。<br>
	この設定は、全てのユーザーのフォルダに適用されます。<br>
	注意：この処理を実行する前に、option.plのパーミッションを書き込み可能にしてください。
	</p>
	<form name="form1" method="post" action="">
	  <table width="700">
        <tr>
          <td valign="top" nowrap>マスターパスワード</td>
          <td><input name="new_master_passwd" type="password" id="new_master_passwd" size="30" value="$m_master_passwd"><input name="master_passwd" type="hidden" id="master_passwd" value="$m_master_passwd">
            $errormsg1<br>
            NOTAを管理するマスターパスワードを指定してください。<br>
          このパスワードで、本管理画面にアクセスできます。<br>
          絶対に他人に教えないようにしてください。
        </td>
        </tr>
        <tr>
          <td valign="top" nowrap>notadataフォルダのパス</td>
          <td><input name="notadata_dir" type="text" id="notadata_dir" size="30" value="$m_notadata_dir">
            $errormsg2<br>
            例：/home/htdocs/notadata<br>
            notadataフォルダの場所を指定します。<br>注意：パスの最後にハイフンはつけないでください。<br>
            なるべく絶対パスで指定してください<br>
          このフォルダはセキュリティ上の理由から<br>
httpでアクセスできない場所においてください</td>
        </tr>
        <tr>
          <td valign="top" nowrap>ユーザーフォルダの<br>最大サイズ</td>
          <td><input name="max_imgdir_size" type="text" id="max_imgdir_size" size="3" maxlength="3" value="$m_max_imgdir_size">
          MB<br>デフォルト：30MB。半角数字で入力してください。</td>
        </tr>
        <tr>
          <td valign="top" nowrap>投稿ファイル最大サイズ</td>
          <td><input name="max_imgfile_size" type="text" id="max_imgdir_size2" size="3" value="$m_max_imgfile_size">
          MB<br>デフォルト：5MB。半角数字で入力してください。
          </td>
        </tr>
      </table>
      <p>
	<input type="hidden" name="action" value="save">
	<input type="hidden" name="mode" value="$FORM{'mode'}">
      <input type="submit" name="Submit" value="保存"></p>
	  </form>
END_OF_HTML
}


#------------------------------------------------------------------------#
#-- オプション設定の保存 ------------------------------------------------#
sub saveOption
{

	$new_master_passwd = $FORM{'new_master_passwd'};
	$notadata_dir = $FORM{'notadata_dir'};
	$max_imgdir_size = $FORM{'max_imgdir_size'};
	$max_imgfile_size = $FORM{'max_imgfile_size'};
	
	#バリデーション
	if ($new_master_passwd eq "" || !$new_master_passwd){
		&error("マスターパスワードが空です。");
		return;
	}
	if ($new_master_passwd =~ /\W/){
		&error("マスターパスワードに無効な文字列が含まれています。");
		return;
	}
	if ($notadata_dir eq "" || !$notadata_dir){
		&error("notadataフォルダのパスが空です。");
		return;
	}
	if (! -e($notadata_dir)){
		&error("${notadata_dir}フォルダは存在しません。");
		return;
	}
	if ($max_imgdir_size eq "" || !$max_imgdir_size || $max_imgdir_size =~ /\D/){
		&error("ユーザーフォルダの最大サイズが無効です。");
		return;
	}
	if ($max_imgfile_size eq "" || !$max_imgfile_size || $max_imgfile_size =~ /\D/){
		&error("投稿ファイル最大サイズが無効です。");
		return;
	}
	if( open( DATA, "< option.pl") ){
		@lines = <DATA>;
		close( DATA ) ;
		foreach (@lines){
			$_ =~ s/^(\s*\$m_master_passwd\s*=\s*["']).*?(["']\s*;)/$1$new_master_passwd$2/g;
			$_ =~ s/^(\s*\$m_notadata_dir\s*=\s*["']).*?(["']\s*;)/$1$notadata_dir$2/g;
			$_ =~ s/^(\s*\$m_max_imgdir_size\s*=\s*["']?).*?(["']?\s*;)/$1$max_imgdir_size$2/g;
			$_ =~ s/^(\s*\$m_max_imgfile_size\s*=\s*["']?).*?(["']?\s*;)/$1$max_imgfile_size$2/g;
		}
	}
	if( open( DATA, "> option.pl") ){
		print DATA @lines;
		close( DATA ) ;
		
		#書き込み成功 変数にもセット
		$m_master_passwd    = $new_master_passwd;
		$m_notadata_dir     = $notadata_dir;
		$m_max_imgdir_size  = $max_imgdir_size;
		$m_max_imgfile_size = $max_imgfile_size;
		
		return 1;
	}
	error("オプション設定の書き込みに失敗しました。option.plに書き込み権限を与えてください。");
	return;
	


}

#------------------------------------------------------------------------#
#END_OF_SCRIPT
