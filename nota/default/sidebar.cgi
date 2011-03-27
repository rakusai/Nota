#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/08/14
#LastUpdate: 2005/12/01
#-----------------------------------------------------------#

require 'option.pl';
require 'nota.pl';

use utf8;
use notalib::Login;
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
#-- メイン  ------------------------------------------------#
sub main
{
	local %FORM = ();
	&nota_get_form(\%FORM);
	local %COOKIE = ();
	&nota_get_cookie(\%COOKIE);
	
	#LocalConnetionに使うID
	local $sdir = $ENV{'SERVER_NAME'} . $ENV{'SCRIPT_NAME'};
	$sdir =~ /.*\//;
	$sdir = $&;
	$sdir .= $ENV{'HTTP_USER_AGENT'};
	$sdir =~ s/[^a-zA-Z0-9]//g;
	
	#ログイン情報の取得
	local $login = NOTA::Login->new;
	$login->getlogin(\%COOKIE);
	
	#使用言語
	local $lang = &nota_get_lang();
	
	#ページ番号の取得
	local $page  = $FORM{'page'};
	if (!$page || $page eq ""){
		$page = "home";
	}
	
	#バリデーション
	&nota_validate($page);
	
	if ($FORM{'type'} eq "account"){
		#管理ページ出力
		&printOptionPage();
	}elsif ($FORM{'type'} eq "bottom"){
		#フルスクリーン時のボトムバー表示
		&printSidebarBottom();
	}elsif ($FORM{'action'} eq "convert"){
		#旧データ変換
		&convertPage();
	}else{
		#一覧ページ出力
		&printListPage();
	}
}


#-----------------------------------------------------------#
#-- サイドバーの出力  --------------------------------------#
sub printListPage
{
	my $text = &getFileList($page);
	
	#スクロール位置の取得
	my $scrolly = $COOKIE{'scrolly'};
	if ($scrolly =~ /$page/){
		$scrolly =~ s/(\&|;)(.*)//g;
		if ($scrolly eq "" || !$scrolly){
			$scrolly = 0;
		}
	}else{
		$scrolly = 0;
	}
	my $openarea = $COOKIE{'openarea'};
	
	my $metarobot = '';
	if ($m_norobot == 1){
		$metarobot = "<meta content=NONE name=ROBOTS>\n\t<meta content=NOINDEX,NOFOLLOW name=ROBOTS>";
	}

	print "Content-type: text/html; charset=utf-8\n\n";

	print <<"END_OF_HEAD";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	$metarobot
	<title>NOTA - List</title>
	<link rel="stylesheet" type="text/css" href="$m_themedir/styles/side.css">
	<script type="text/javascript">
	function init() {
		//Show last opened area
		showArea($openarea);
		//Scroll to last position
		scrollTo(0,$scrolly);
	}
	function setCookie(page) {
		var y=0;
		if(document.all){ 
			y = document.body.scrollTop; 
		} 
		else if(document.layers || document.getElementById){ 
			y = pageYOffset; 
		}
	 	document.cookie = "scrolly=" + y + "&"  + page  +";";
	}
	function changeTitle(page,newtitle){
		//ページタイトルを動的に変更
	    var theExisting = document.getElementById("a" + page);
		if(theExisting){
			theExisting.removeChild(theExisting.firstChild);
			theExisting.firstChild.nodeValue = newtitle;
	        theExisting.appendChild(document.createTextNode(newtitle));
	    }
	}
	function showArea(indx) {
		//Create images from list
		if (indx == undefined){
			return;
		}
		var cap  = document.getElementById("cap" + indx);
		var area = document.getElementById("area" + indx);
		if (area.style.display != "block"){
			closeArea();
			cap.className = "opentitle";
			area.style.display = "block";
			//Save to cookie
		 	document.cookie = "openarea=" + indx +";";
		}else{
			closeArea();
			//Save to cookie
		 	document.cookie = "openarea=;";
		}
	}
	function closeArea() {
		//Close image list
		for (var i=0; i<100; i++){
			var cap  = document.getElementById("cap" + i);
			var area = document.getElementById("area" + i);
			if (area){
				area.style.display = "none";
				cap.className = "title";
			}else{
				break;
			}
		}
	}
/*
	function changeBox(tabname){
		//表示ボックスを切り替え
		var listBox   = document.getElementById("listBox");
		var insertBox = document.getElementById("insertBox");
		var optionBox = document.getElementById("optionBox");
		if (tabname == "list"){
			//一覧タブ
			listBox.style.display   = "block";
			insertBox.style.display = "none";
			optionBox.style.display  = "none";
		}else if (tabname == "insert"){
			//貼るタブ
			listBox.style.display   = "none";
			insertBox.style.display = "block";
			optionBox.style.display  = "none";
		}else if (tabname == "option"){
			//管理タブ
			listBox.style.display   = "none";
			insertBox.style.display = "none";
			optionBox.style.display  = "block";
		}
		loadBox(tabname);
	}
*/
	</script>
</head>
<body onLoad="init()">
	<table width="100%" border="0" cellpadding="0" cellspacing="0">
	<tr><td>
	$text
	</td></tr>
	</table>
</body>
</html>
END_OF_HEAD
}


#-----------------------------------------------------------#
#-- フルスクリーン時のボトムバー表示 -----------------------#
sub printSidebarBottom
{
	#日英表記分け
	my %label = ();
	if ($lang eq "en"){
		%label =("submit","Upload","upload","&nbsp;File Upload : ","quality","High Quality","waiting","Now Uploading.","cancel","Cancel");
	}else{
		%label =("submit","貼り付け","upload","&nbsp;ファイルの貼り付け：","quality","高精細","waiting","送信中です。","cancel","中止する");
	}
	
	print "Content-type: text/html; charset=utf-8\n\n" ;
	print <<"END_OF_HTML";
<!DOCTYPE html PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<title>NOTA Upload Form</title>
	<link rel="stylesheet" type="text/css" href="$m_themedir/styles/side.css">
	<style type="text/css">
	body {
	margin: 2px 0px 0px 5px;
	}
	</style>
	<script type="text/javascript">
	<!--
	function startUpload(){
		document.getElementById("submitform").style.display = "none";
		document.getElementById("waitingform").style.display = "inline";
		document.form.submit();
	}
	function stopUpload(visible){
		//Stop or Finish Uploading
		document.getElementById("submitform").style.display = "block";
		document.getElementById("waitingform").style.display = "none";
		document.form.reset();
	}
	function hideUpload(visible){
		//Hide Uploading
		document.getElementById("submitform").style.display = "none";
		document.getElementById("waitingform").style.display = "none";
	}
	-->
	</script>
</head>
<body>
		<form name="form" id="form" method="post" enctype="multipart/form-data" action="upload.cgi" target="link">
		<span id="submitform" style="display:none;">
		$label{'upload'}<input type="hidden" name="action" value="regist">
		<input type="hidden" name="page" value="$page">
		<input type="hidden" name="align" value="$align">
		<input type="file" name="imgfname" size="14">
		<input type="button" name="upload" onclick="startUpload();" value="$label{'submit'}">
		<input type="checkbox" name="quality" value="1" border="0"><font size="-1">$label{'quality'}</font>
		</span>
		<span id="waitingform" class="uploadwainting">
		<img src="$m_themedir/images/ajax-loader.gif" align="absmiddle">
		$label{'waiting'}<a href="javascript:;" onclick="window.parent.link.location.replace('about:blank');stopUpload();">[ $label{'cancel'} ]</a>
		</span>
		</form>
</body>
</html>
END_OF_HTML

}


#-----------------------------------------------------------#
#--  ファイルの一覧を返す ----------------------------------#
sub getFileList
{
	my ($page) = @_;


	#HTML形式か
	my $ishtml = 0;
	if (defined($FORM{'html'}) && $FORM{'html'} ne ""){
		$ishtml = 1;
	}
	
	#ファイルの一覧を取得
	my $findstr = $FORM{'findstr'};
	utf8::decode($findstr);	#utf8のフラグを立てる

	my $text = "";
	
	#第3者の閲覧禁止かチェック
	if ($login->is_access_forbidden){
		$text = "<div class=\"templatenotes\">";
		if ($lang eq "en"){
			$text .= "This NOTA is private use only. Please login to access.";
		}else{
			$text .= "このNOTAは、非公開です。ログインしてご利用ください。";
		}
		$text .= "</div>";
		return $text;
	}
	
	#ファイルの一覧を更新日時順に並び替え、返す
	my $ndf = NOTA::NDF->new;
	if (!$ndf->getFileList($m_datadir)){
		#ファイル配列が空のとき
		if ($lang eq "en"){
			$text .= "\tError File Not Found.<hr>\n";
		}else{
			$text .= "\tファイルが見つかりません。<hr>\n";
		}
		#バージョンが古いとき
		if ($ndf->is_oldversion){
			if ($lang eq "en"){
				$text .= "\t<a href=\"sidebar.cgi?action=convert\">Convert all documents into new formats. Click here to start.</a><hr>\n";
			}else{
				$text .= "\t<a href=\"sidebar.cgi?action=convert\">旧バージョンのデータがあります。ここを押して、古いデータを新しいデータに変換してください。</a><hr>\n";
			}
		}
	}
	
	
	#新しい順に並べ替えを行って、返す
	my $filecnt = 0;
	my $currentdate = "";
	my $i = 0;
	my %TAGS = ();
	my $ref_filelist = $ndf->get_filelist;
	foreach (@$ref_filelist){
		my ($id,$author,$title,$edit,$update) = @$_;
		
		#タイトルと作者名で検索
		if ($findstr && $findstr ne ""){
			if (!("$title,$author" =~ /$findstr/i)){
				#飛ばす！
				next;
			}
		}
		&nota_xmlescape($title);	#エスケープ

		#表示用のタイトルから分類タグを取る
		my $testtitle = $title;
		$title =~ s/([\[［].*?[\]］])//g; #[]の外の文字を削除
		if (length($title) > 20){
			$title = substr($title, 0,20) . "..."; #20文字にカット
		}
		
		#今日、昨日を得る
		my $today = getLocalDay(0);
		my $yesterday = getLocalDay(-24);
		#秒は取る
		$update =~ s/ (.*)$//g;
		if ($lang eq "en"){
			#英語表記の日付に
			if ($update eq $today){
				$update = "Today";
			}elsif ($update eq $yesterday){
					$update = "Yesterday";
			}else{
				my @months =("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
				$update =~ s/(\w+)\/(\w+)\/(\w+)/$months[$2-1] $3, $1/g;
			}
		}else{
			#日本語表記の日付に
			if ($update eq $today){
				$update = "今日";
			}elsif ($update eq $yesterday){
					$update = "昨日";
			}else{
				$update =~ s/(\w+)\/(\w+)\/(\w+)/$1年$2月$3日/g;
			}
		}
		#日付を追加
		if ($currentdate ne $update){
			$text .= "\t<h4>$update</h4>\n";
			$currentdate = $update;
		}
		#タイトル行
		my $class = "title";
		my $authordiv = "";
		if ($id eq $page){
			$class = "selectedtitle";
			$authordiv = "\n<span class=\"author\">by $author</span>";
		}
		
		if ($edit eq "admin"){
			$edit = "<img class=\"lockimg\" src=\"$m_themedir/images/lock.gif\" alt=\"Lock\" align=\"right\">";
		}else{
			$edit = "";
		}
		
		my $imgsrc = "note.gif";
		if ($id eq "home" || $id eq ""){
			$imgsrc = "home.gif";
		}elsif ($id eq $page){
			$imgsrc = "noteedit.gif";
		}
		my $getparam = "?$id";
		if ($id eq "home"){
			$getparam = "";
		}
		
		my $htmlprm = "";
		if ($ishtml == 1){
			if ($id eq "home"){
				$htmlprm = "?home.html";
			}else{
				$htmlprm = ".html";
			}
		}
		my $line = "\t$edit\n" . 
			"\t<a class=\"$class\" href=\"./$getparam$htmlprm\" onClick=\"setCookie('$id')\" target=\"_parent\">\n" . 
			"\t<img src=\"$m_themedir/images/$imgsrc\" alt=\"PageIcon\" class=\"smallicon\" border=\"0\">\n" . 
			"\t$title$authordiv</a>\n";

		#タグに分類する
		while ($testtitle =~ s/[\[［](.*?)[\]］]//){
			if ($1 ne ''){
				$TAGS{$1} .= "$line\n";
			}
		}

		$text .= $line;
		
		$filecnt += 1;
	}
	#タグの分類を追加
	if (%TAGS > 0){
		my $tagtext = "";
		if ($lang eq "en"){
			$tagtext .= "<h4>Tags</h4>\n";
		}else{
			$tagtext .= "<h4>タグ</h4>\n";
		}
		$i = 0;
		while (($tag,$val) = each %TAGS) {
			$tagtext .= "<a href=\"javascript:showArea('$i');\" class=\"title\" id=\"cap$i\">\n" .
				"<img src=\"$m_themedir/images/folder.gif\" alt=\"PageIcon\" class=\"smallicon\" border=\"0\">$tag</a>\n" .
				"<div id=\"area$i\" class=\"childarea\"><div class=\"filelist\">" . $val . "</div></div>\n";
			$i++;
		}
		$text = $tagtext . $text;
	}
	#検索結果を表示
	if ($findstr && $findstr ne ""){
		my $result = '';
		if ($lang eq "en"){
			$result = "\t<div class=\"subject\">Search: \"$findstr\"</div>\n";
			if ($filecnt == 0){
				$result .= "\t<div class=\"templatenotes\">Did not match any documents.</div>\n";
			}elsif ($filecnt == 1){
				$result .= "\t<div class=\"templatenotes\">$filecnt file has found.</div>\n";
			}else{
				$result .= "\t<div class=\"templatenotes\">$filecnt files have found.</div>\n";
			}
		}else{
			$result = "\t<div class=\"subject\">探す： \"$findstr\"</div>\n";
			if ($filecnt == 0){
				$result .= "\t<div class=\"templatenotes\">ファイルは見つかりませんでした。</div>\n";
			}else{
				$result .= "\t<div class=\"templatenotes\">$filecnt 個のファイルが見つかりました。</div>\n";
			}
		}
		$text = $result . $text;
	}
	
	return $text;
	
}

#-----------------------------------------------------------#
#-- 旧バージョンのデータ変換処理  --------------------------#
sub convertPage
{
	
	print "Content-type: text/html;\n\n";
	print <<"END_OF_CONV";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv=Content-Type content="text/html; charset=utf-8">
	$metarobot
	<title>NOTA - Convert</title>
	<link rel="stylesheet" type="text/css" href="$m_themedir/styles/side.css">
</head>
<body>
<h3>NOTAデータの変換処理</h3>
<div class="templatenotes">
旧バージョンのデータ(dat,csv)を新バージョン互換のデータ(ndf)に変換します。
旧バージョンのデータは残ります。
</div>
<hr>
END_OF_CONV

	my $curtime = &getLocalTime();
	print ("開始時刻：$curtime<hr>\n");
	
	my %FILES = ();
	
	#ディレクトリを開く
	if (!opendir(DIR,"$m_datadir/")) { 
		return 0;
	}
	my $i=0;
	my $page;
	while (defined($page = readdir(DIR))){
		$page =~ s/\.(\w+)$//;	#拡張子を取る
		my $ext = $1;
		if ($ext =~ /dat/){
			#DATファイル
			#旧ファイルは、新ファイルへ更新
			my $ndf = NOTA::NDF->new;
			if ( !-e "$m_datadir/$page.ndf"){
				print ("<a href=\"./?$page\" target=\"_parent\">$page</a> 変換中<b>...</b>");
				if ($ndf->convertToNewNota($m_datadir,$page)){
					print ("<font color=\"green\">変換成功</font><br>\n");
				}else{
					print ("<font color=\"red\">変換失敗</font><br>\n");
				}
			}else{
				print ("<a href=\"./?$page\" target=\"_parent\">$page</a> <font color=\"gray\">変換済み</font><br>\n");
			}
		}
	}
	closedir(DIR);
	
	$curtime = &getLocalTime();
	print ("<hr>終了時刻：$curtime<hr>\n");
	print ("すべての変換が終了しました。\n");
	print ("</body></html>");

	return 1;	
	
}


#-----------------------------------------------------------#
#-- 設定ページ  --------------------------------------------#
sub printOptionPage
{
	#編集モードか
	if ($login->get_editmode ne 'true'){
		#権限なし
		if ($lang eq "en"){
			&error("Please login to access.");
		}else{
			&nota_error_html("編集モードでないと利用できません。");
		}
		return;
	}
	#管理Flash
	my $accounttext = &nota_print_flash("account","account.swf?ver=$m_version","lang=$lang&sdir=$sdir&page=$page&","noscale","#EFF6E7","","175","240");
	
	if ($login->get_power ne "admin"){
		if ($lang eq "en"){
			$accounttext = "<div class=\"templatenotes\">Administrators Only.</div>";
		}else{
			$accounttext = "<div class=\"templatenotes\">管理者しかアクセスできません。</div>";
		}
	}
	
	#データ容量
	my $userdir = $m_imgdir; #imgフォルダの一つ上の階層
	$userdir =~ s/\/img//g;
	my $file = NOTA::SimpleFile->new;
	my $used_size = $file->getDirectorySize($userdir);
	$used_size = sprintf("%.1f", $used_size / 1024 / 1024 );
	my $free_size = sprintf("%.1f", $m_max_imgdir_size - $used_size);
	if ($free_size < 0){
		$free_size = "0";
	}
	my $used_percent = int($used_size / $m_max_imgdir_size * 100);
	if ($used_percent > 100){
		$used_percent = "100";
	}
	my $free_percent = 100 - $used_percent;
	
	#日英表記分け
	my @label = ();
	my @check = ();
	if ($lang eq "en"){
		@label =("User Account","Editing Rules","A","Admin","M","Member","G","Guest","Add objects","Edit/Delete your objects","Edit object of others","Create pages","Delete your pages","Delete objects of others","Delete pages of others","Lock pages","Manage user account","Version","Data Capacity","Used space","Free space","Capacity");
		@check = ("×","&nbsp;-","△");
		$capacitycomment = "You can't create new pages or paste files if the capacity of data is above the limit.";
	}else{
		@label =("コミュニティの参加者","編集権限表","管","管理者","会","会員","ゲ","ゲスト","追加書き込み","自分の部品の編集・削除","他人の部品の編集","新規ページの作成","自分のページの削除","他人の部品の削除","他人のページの削除","ページの凍結","ユーザー管理","バージョン情報","データ容量","使用容量","空き容量","総容量");
		@check = ("○","×","△");
		$capacitycomment = "容量がいっぱいになると、新しいページの作成やファイルの貼り付けができなくなります。";
	}
	
	#バージョン
	my $v_ver = $m_version;
	$v_ver =~ s/\d/\.$&/g;

	
	print "Content-type: text/html; charset=utf-8\n\n";
	
	print <<"END_OF_ADMIN";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	$metarobot
	<title>NOTA - List</title>
	<link rel="stylesheet" type="text/css" href="$m_themedir/styles/side.css">
</head>
<body>
	<h3>$label[0]</h3>
$accounttext
	<h3>$label[18]</h3>
	<div class="capacity" >
	  <div class="usedspace" style="width:$used_percent%"></div>
	</div>
	<table width="150"  border="0" cellspacing="0" cellpadding="0" class="detailtbl">
	  <tr>
	    <td valign="middle" width="18"><div class="sikaku" style="background-color: #33CCFF;"></div></td>
	    <td valign="middle" nowrap>$label[19] :</td>
	    <td valign="middle" nowrap>$used_size MB</td>
	  </tr>
	  <tr>
	    <td valign="middle" width="18"><div class="sikaku" style="background-color: #FF3399;"></div></td>
	    <td valign="middle" nowrap>$label[20] :</td>
	    <td valign="middle" nowrap>$free_size MB</td>
	  </tr>
	  <tr>
	    <td valign="middle" width="18"><div class="sikaku" ></div></td>
	    <td valign="middle" nowrap>$label[21] :</td>
	    <td valign="middle" nowrap>$m_max_imgdir_size MB</td>
	  </tr>
	</table>
	<div class="templatenotes">$capacitycomment</div>
	<h3>$label[1]</h3>
	<table width="176"  border="0" cellspacing="0" cellpadding="0" class="detailtbl">
	<tr>
		<td width="68%" nowrap>&nbsp;</td>
		<td width="7%" nowrap>$label[2]</td>
		<td width="7%" nowrap>$label[4]</td>
		<td width="7%" nowrap>$label[6]</td>
	</tr>
	<tr>
		<td nowrap>$label[8]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[0]</td>
	</tr>
	<tr>
		<td nowrap>$label[9]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[0]</td>
	</tr>
	<tr>
		<td nowrap>$label[10]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[2]</td>
		<td nowrap>$check[1]</td>
	</tr>
	<tr>
		<td nowrap>$label[11]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[1]</td>
	</tr>
	<tr>
		<td nowrap>$label[12]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[1]</td>
	</tr>
	<tr>
		<td nowrap>$label[13]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[2]</td>
		<td nowrap>$check[1]</td>
	</tr>
	<tr>
		<td nowrap>$label[14]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[1]</td>
		<td nowrap>$check[1]</td>
	</tr>
	<tr>
		<td nowrap>$label[15]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[1]</td>
		<td nowrap>$check[1]</td>
	</tr>
	<tr>
		<td nowrap>$label[16]</td>
		<td nowrap>$check[0]</td>
		<td nowrap>$check[1]</td>
		<td nowrap>$check[1]</td>
	</tr>
	</table>
	<div class="templatenotes">
		<b>$label[2]</b>: $label[3] 
		<b>$label[4]</b>: $label[5] 
		<b>$label[6]</b>: $label[7]
	</div>
	<h3>$label[17]</h3>
	<p><img src="res/nota.png" border="0" alt="NOTA"><br />
	NOTA ver$v_ver <br />
	&copy; Isshu Rakusai, NOTA Network. All rights reserved. <br />
	<a target="_parent" href="http://nota.jp">http://nota.jp</a></p>

	<h3>Special Thanks</h3>
	<p>User Manual:<br />
	Kentaro Higaki</p>

	<p>Install Manual:<br />
	Keita Akimoto</p>

	<p>Logo Design:<br />
	Yoshio Shingyouji</p>
</body>
</html>
END_OF_ADMIN

}



#------------------------------------------------------------#
#--  現在日時を取得 -----------------------------------------#
sub getLocalDay
{
	my $diff = shift;
	my ($sec,$min,$hour,$mday,$month,$year,$wday) = localtime(time + $diff*60*60);
	$month++;
	my @num =("00","01","02","03","04","05","06","07","08","09");
	$month = $num[$month] if ( $month<=9 );
	$mday  = $num[$mday]  if ( $mday<=9 );
	$year += 1900;
	my $temp =  "$year/$month/$mday";
	
	return ($temp);
}

#-----------------------------------------------------------#
#--  現在日時 ----------------------------------------------#
sub getLocalTime
{
	my ($sec,$min,$hour,$mday,$month,$year,$wday) = localtime(time);
	$month++;
	my @num =("00","01","02","03","04","05","06","07","08","09");
	$month = $num[$month] if ( $month<=9 );
	$mday  = $num[$mday]  if ( $mday<=9 );
	$hour  = $num[$hour]  if ( $hour<=9 );
	$min   = $num[$min]   if ( $min<=9 );
	$sec   = $num[$sec]   if ( $sec<=9 );
	$year += 1900;
	my $temp =  "$hour:$min:$sec";
	
	return ($temp);
}


#-----------------------------------------------------------#
#END_OF_SCRIPT
