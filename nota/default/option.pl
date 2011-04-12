#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/08/25
#LastUpdate: 2005/08/25
#-----------------------------------------------------------#

#-----------------------------------------------------------#
#----- マスターパスワード ----------------------------------#

$m_master_passwd = 'test2';

#NOTAを管理するマスターパスワードを指定してください。
#このパスワードが空白の場合、index.cgiはエラーを返します。
#絶対に他人に教えないようにしてください。

#-----------------------------------------------------------#
#----- 各種パス --------------------------------------------#

#注意：パスの最後にハイフンはつけない
#なるべく絶対パスで指定してください

#この値を適切に変更してください。
$m_notadata_dir = "/Users/rakusai/Work/Nota/notadata/";
  #m_notadata_dirは、notadataフォルダの場所を指定します。
  #このフォルダはセキュリティ上の理由から
  #httpでアクセスできない場所においてください

#ローカルNOTAのための
#my $doc_person = $ENV{'DOCUMENT_PERSONAL'};
#$doc_person =~ s/\\/\//g;
#$doc_person = 'D:';

#複数NOTAの運用方法
$m_multi_account = 1;

#一つのNOTAしか使わない  : 0
#シンボリックリンクもしくはmode_rewrite等でフォルダを切り分ける場合 : 1

#-----------------------------------------------------------#
#----- 各種パス詳細 ----------------------------------------#

#ここより下は上の値が決まれば自動で決定します
#必要な場合のみ変更してください

my $m_group = '';
if ($m_multi_account == 1){
	#スクリプト名の最後のディレクトリを抜き出す
	if ($ENV{'SCRIPT_NAME'} =~ /([^\/]+)\/[^\/]*$/g){
		$m_group = $1;
	}
}else{
	$m_group = 'nota';
}

if ($m_group =~ /^DEL/){
	#削除済みアカウントは無効
	$m_group = '';
}

#ページデータ収納フォルダ
$m_datadir = "$m_notadata_dir/$m_group/data";
#画像／添付ファイル収納フォルダ
$m_imgdir = "$m_notadata_dir/$m_group/img";
#ゴミ箱フォルダ
$m_trashdir = "$m_notadata_dir/$m_group/trash";
#手書き線画像フォルダ(HTML表示に必要)
$m_drawingdir ="$m_notadata_dir/$m_group/drawing";
#アカウントファイル
$m_memberpath = "$m_notadata_dir/$m_group/account/member.csv";
#BASIC認証ファイル(この設定はedit/.htaccessにも記述せよ)
$m_passwdpath = "$m_notadata_dir/$m_group/account/passwd.dat";

#テンプレート画像フォルダ(このフォルダはhttpでアクセスできる場所に置く)
$m_templatedir = "template";
#テンプレート画像フォルダのURL（相対パスでも可）
$m_template_html_dir = "template";

#-----------------------------------------------------------#
#----- 設定 ------------------------------------------------#

#画像収納フォルダの最大サイズ(単位MB)
$m_max_imgdir_size = 100;
#投稿画像ファイル最大サイズ(単位MB)
$m_max_imgfile_size = 5;

#テーマ選択
$m_theme = "original";
$m_themedir = "themes/" . $m_theme;


#検索ロボットを回避
$m_norobot = 0;
#FastCGIの利用
$m_fastcgi = 0;

1;
