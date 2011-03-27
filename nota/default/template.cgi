#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/08/14
#LastUpdate: 2005/11/16
#-----------------------------------------------------------#

require 'option.pl';
require 'nota.pl';

use Image::Magick;
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
	
	&printMenu;
	
}


#-----------------------------------------------------------#
#--  メニューHTMLを表示 ------------------------------------#
sub printMenu
{
	#ログイン情報の取得
	local $login = NOTA::Login->new;
	$login->getlogin(\%COOKIE);

	if ($login->get_editmode ne 'true'){
		#権限なし
		&nota_error_html("編集モードでないと利用できません。");
		return;
	}
	
	my $sdir = $ENV{'SERVER_NAME'} . $ENV{'SCRIPT_NAME'};
	$sdir =~ /.*\//;
	$sdir = $&;
	$sdir =~ s/[^a-zA-Z0-9]//g;
	
	#現在ページ
	local $page = $FORM{'page'};
	#バリデーション
	&nota_validate($page);
	
	#使用言語
	local $lang = &nota_get_lang();
	
	print "Content-type: text/html; charset=utf-8\n\n" ;
	
	&printHead;
	&printUplaodForm;
#	&printExtendInsert;
	&printMaterials;
	&printPlugins;
	&printMasters("$m_notadata_dir/master/data");
	&printFoot;

}

#-----------------------------------------------------------#
#-- ヘッダー表示 -------------------------------------------#
sub printHead
{

	print <<"END_OF_HEAD";
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	$metarobot
	<title>NOTA - Insert</title>
	<link rel="stylesheet" type="text/css" href="$m_themedir/styles/side.css">
	<script type="text/javascript">
	var oJsr;
	function newWillustrator(){
		// New Willustrator
		oJsr = new JSONscriptRequest('http://willustrator.org/json/new_image?jsonp=onWillustrator');
		oJsr.buildScriptTag();
		oJsr.addScriptTag();
	}
	function onWillustrator(data) {
		// Callback from Willustrator
		
		if (data['error']){
			alert("Willustrator:" + data['error']);
			return;
		}
		//NOTAにプラグインを追加
		window.open("link.cgi?page=$page&url=plugin:willustrator:" + data['png'],"link");
		
		//サブウインドウを開く
		//(引数以外のパラメータも下記でセットできます)
		var para =""
		+",toolbar="	 +0
		+",location="	 +0
		+",directories=" +0
		+",status=" 	 +0
		+",menubar="	 +1
		+",scrollbars="  +1
		+",resizable="	 +1
		+",width="		 +800
		+",height=" 	 +600;
		thePopup=window.open(data['edit'],"_blank",para);
		thePopup.focus();
		
		oJsr.removeScriptTag();
	}
	function startUpload(){
		//Start Uploading
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
	function showImage(indx) {
		//Create images from list
		var cap = document.getElementById("cap" + indx);
		var place = document.getElementById("area" + indx);
		var urls = document.getElementById("url" + indx);
		if (place.style.display != "block"){
			closeImageList();
			//Insert Images
			var urllist = urls.firstChild.nodeValue.split(";");
			for (var i=0; i<urllist.length-1; i++){
				//Create tags
				var vars = urllist[i].split(",");
				var dir = vars[0];
				var fname = vars[1];
				var thumfname = vars[2];

				var atag = document.createElement("a");
				atag.setAttribute("href","upload.cgi?action=regist2&dir=" + dir + "&page=$page" + "&fname=" + fname);
				atag.setAttribute("target","link");
				
				//Create images
				var img = document.createElement("img");
				atag.appendChild(img);
				img.setAttribute("src","$m_template_html_dir/" + dir + "/i/" + thumfname);
				img.setAttribute("border","1");


				place.firstChild.appendChild(atag);
				place.firstChild.appendChild(document.createTextNode(" "));
			}
			cap.className = "opentitle";
			urls.firstChild.nodeValue = "";
			place.style.display = "block";
		}else{
			closeImageList();
		}
	}
	function closeImageList() {
		//Close image list
		for (var i=0; i<100; i++){
			var place = document.getElementById("area" + i);
			var cap = document.getElementById("cap" + i);
			if (place){
				place.style.display = "none";
				cap.className = "title";
			}else{
				break;
			}
		}
	}
	</script>
</head>
<body>
END_OF_HEAD

}

#-----------------------------------------------------------#
#-- フッター表示 -------------------------------------------#
sub printFoot
{
	print "</body>\n</html>";
}


#-----------------------------------------------------------#
#-- 投稿フォーム表示 ---------------------------------------#
sub printUplaodForm
{
	#日英表記分け
	my %label = ();
	if ($lang eq "en"){
		%label =("title","File Upload","upload","&nbsp;File Upload : ","quality","High Quality","waiting","Now Uploading.","cancel","Cancel","note","Select a file and click upload button. It may take several minutes.");
		if ($align eq "bottom"){
			$label{'submit'} = "Upload";
		}else{
			$label{'submit'} = "&lt; Upload";
		}
	}else{
		%label =("title","ファイルの貼り付け","upload","&nbsp;ファイルの貼り付け：","quality","高精細","waiting","送信中です。","cancel","中止する","note","「参照」を押してファイルを選んだ後、「貼り付け」ボタンを押して、しばらくお待ちください。");
		if ($align eq "bottom"){
			$label{'submit'} = "貼り付け";
		}else{
			$label{'submit'} = "←貼り付け";
		}
	}

	if ($align ne "bottom"){
		$label{'upload'} = "";
	}
	
	print <<"END_OF_HTML";
	<h3>$label{'title'}</h3>
	<form name="form" id="form" method="post" class="sideform" enctype="multipart/form-data" action="upload.cgi" target="link">
	<div id="submitform">
	$label{'upload'}<input type="hidden" name="action" value="regist">
	<input type="hidden" name="page" value="$page">
	<input type="hidden" name="align" value="$align">
	<input type="file" name="imgfname" size="14">
	<input type="button" name="upload" onclick="startUpload();" value="$label{'submit'}">
	<input type="checkbox" name="quality" value="1"><font size="-1">$label{'quality'}</font>
	</div>
	<div id="waitingform" class="uploadwainting">
	<img src="$m_themedir/images/ajax-loader.gif" alt="loading" align="absmiddle"><br />
	$label{'waiting'}<a href="javascript:;" onclick="window.parent.link.location.replace('about:blank');stopUpload();">[ $label{'cancel'} ]</a>
	</div>
	</form>
	<div class="templatenotes">$label{'note'}</div>
END_OF_HTML

}
#-----------------------------------------------------------#
#--  フォト蔵連携、URLからの貼り付けフォームを出力 ---------#
sub printExtendInsert
{
	print <<"END_OF_UP";
	<h3>フォト蔵から画像を探す</h3>
	<form name="pz" method="get" action="photozou/photozou.php" target="_blank">
	<input type="text" name="q" value="" />
	<input type="hidden" name="page" value="$page" />
	<input type="submit" value="フォト蔵から探す" />
	</form>
	<form name="pzc" method="get" action="photozou/photozou.php" target="_blank">
	<input type="hidden" name="q" value="shirt" />
	<input type="hidden" name="page" value="$page" />
	<input type="submit" value="Ｃシャツ関連の画像を探す" />
	</form>
	
	<form name="pzc" method="get" action="upload.cgi" target="link">
	<input type="hidden" name="action" value="regist2" />
	<input type="hidden" name="page" value="$page" />
	<input type="text" name="url" value="" />
	<input type="submit" value="URLから貼り付け" />
	</form>
	
END_OF_UP


}

#-----------------------------------------------------------#
#--  マスターページの一覧を出力 ----------------------------#
sub printMasters
{
	my $dir = shift;

#	$editbtn =  "<div style=\"float:right;\"><a href=\"../master/\" target=\"_blank\">編集</a></div>\n";
	if ($lang eq "en"){
		print "\t<h3>Master Pages</h3>\n";
	}else{
		print "\t<h3>用紙デザイン</h3>\n";
	}
	
	#リストを取得
	my $ndf = NOTA::NDF->new;
	if (!$ndf->getFileList($dir)){
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
			$title =~ s/%author%/あなた/g;	#エンコード
		}
		&nota_xmlescape($title);	#エスケープ

		print "\t\t<a href=\"link.cgi?page=$page&url=master:$id\" target=\"link\" title=\"Created by $author\" class=\"title\">\n";
		print "\t\t<img src=\"$m_themedir/images/table.gif\" alt=\"PageIcon\" class=\"smallicon\" border=\"0\">$title</a>\n";
		$i++;
	}
	
}

#-----------------------------------------------------------#
#--  素材画像のメニューとサムネイル一覧を出力 --------------#
sub printMaterials
{
	#メニュー表示
	my $urls = "";
	if ($lang eq "en"){
		print "\t<h3>Clipart</h3>\n";
	}else{
		print "\t<h3>クリップアート</h3>\n";
	}

	my $indx = 0;
	if (opendir(DIR1,"$m_templatedir/")) {
		while (defined($dir = readdir(DIR1))){
			if (-d ("$m_templatedir/$dir") && !($dir =~ /^\.*$/)){
				#フォルダの情報を取得
				my $ndf = NOTA::NDF->new;
				if ($ndf->parsefile("$m_templatedir/$dir/${dir}.xml")) { 
			#		return;
				}
				my $title = "";
				if ($lang eq "en"){
					$title = $ndf->getItem("head","title");
				}else{
					$title = $ndf->getItem("head","title-ja");
				}
				if (!defined($title) || $title eq ""){
					$title = $dir;
				}
				my $author = $ndf->getItem("head","author");
				my $web    = $ndf->getItem("head","web");
				my $license= $ndf->getItem("head","license");
				
				print "\t\t<a href=\"javascript:showImage('$indx');\" class=\"title\" id=\"cap$indx\">\n";
				print "\t\t<img src=\"$m_themedir/images/folder.gif\" alt=\"PageIcon\" class=\"smallicon\" border=\"0\">$title</a>\n";
				#画像のサムネイルを出力
				$urls .= &printImages($dir,$indx);
				print "\t\t<div id=\"area$indx\" class=\"childarea\"><div class=\"imagelist\"></div>\n";
				if ($license eq ""){
					$license = "Copyright";
				}
				if ($web ne ""){
					print "\t\t<div class=\"templatenotes\">$license<br><a href=\"$web\" target=\"_blank\">$author</a><br>\n";
				}else{
					print "\t\t<div class=\"templatenotes\">$license<br>$author<br>\n";
				}
				print "</div>\n\t\t</div>\n";
				$indx++;
			}
		}
		closedir(DIR1);
	}
	

	print "\t<div class=\"displaynone\">\n";
	print "$urls";
	print "\t</div>\n";

}

#-----------------------------------------------------------#
#--  一つの画像フォルダから画像を取り出す  -----------------#
sub printImages
{
	my ($dir,$indx) = @_;
	
	my $text = "\t\t<span id=\"url$indx\">";
	my $mkdir = 0;
	if (opendir(DIR,"$m_templatedir/$dir/")) {
		while (defined($fname = readdir(DIR))){
			if ($fname =~ /\.(jpg|gif|png|swf)$/i){
				my $thumfname = $fname;
				if ($fname =~ /swf$/i){
					#Flashなら、画像形式のサムネイルが前提となる
					$thumfname =~ s/swf$/png/g;
					if (!-e "$m_templatedir/$dir/i/$thumfname"){
						$thumfname =~ s/png$/gif/g;
					}
				}else{
					#サムネイル画像がないなら、生成する
					if (! -e "$m_templatedir/$dir/i/$thumfname"){
						if ($mkdir == 0){
							mkdir("$m_templatedir/$dir/i", 0755);
							$mkdir = 1;
						}
						&makeThumbnail("$m_templatedir/$dir","$thumfname");
					}
				}
				if (-e "$m_templatedir/$dir/i/$thumfname"){
					$text .=  "$dir,$fname,$thumfname;";
				}
			}
		}
		closedir(DIR);
	}
	$text .=  "</span>\n";

	return $text;
}

#-----------------------------------------------------------#
#--  プラグインの一覧を出力 --------------------------------#
sub printPlugins
{
	if ($lang eq "en"){
		print "\t<h3>Plugins</h3>\n";
	}else{
		print "\t<h3>プラグイン</h3>\n";
	}
	
	#プラグインフォルダを開く
	if (opendir(DIR,"plugins/")) {
		while (defined($plugin = readdir(DIR))){
			if (-d ("plugins/" . $plugin) && !($plugin =~ /^\.+$/)){
				my $ndf = NOTA::NDF->new;
				if ($ndf->parsefile("plugins/$plugin/${plugin}.xml")) { 
					#リンクを出力
					my $title = "";
					if ($lang eq "en"){
						$title = $ndf->getItem("head","title");
					}else{
						$title = $ndf->getItem("head","title-ja");
					}
					my $author = $ndf->getItem("head","author");
					my $web    = $ndf->getItem("head","web");
					my $link   = $ndf->getItem("head","link");
					my $target = "";
					if (!defined($link) || $link eq ""){
						$link  = "link.cgi?page=$page&url=plugin:$plugin";
						$target= "link";
					}
					print "\t\t<a href=\"$link\" target=\"$target\" title=\"Developed by $author ($web)\" class=\"title\">\n";
					print "\t\t<img src=\"$m_themedir/images/screen.gif\" alt=\"PageIcon\" class=\"smallicon\" border=\"0\">$title</a>\n";
				}
			}
		}
		closedir(DIR);
	}
	
}

#-----------------------------------------------------------#
#--  サムネイル画像の作成 ----------------------------------#
sub makeThumbnail
{
	my ($dir,$fname) = @_;
	
	my $max = 100;
	my $i = Image::Magick->new;
	$i->Read(filename => "$dir/$fname");
	my ($w, $h) = $i->Get('width', 'height');
	$i->Set(quality => '80');
	if ($w > $max || $h > $max){
		$i->Scale($max . 'x' . $max);#比率を保って縮小
	}
	$i->Write(filename => "$dir/i/$fname");

	#分割保存されている場合は最初を採用
	if( -e "$dir/i/$fname.0" ){
		rename("$dir/i/$fname.0","$dir/i/$fname");
		my $n = 1;
		while (-e "$dir/i/$fname.$n"){
			unlink("$dir/i/$fname.$n");
			$n++;
		}
	}

}


#-----------------------------------------------------------#
#END_OF_SCRIPT