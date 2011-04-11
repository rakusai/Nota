#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2004/08/25
#LastUpdate: 2006/02/01
#-----------------------------------------------------------#

use utf8;
binmode STDIN,  ":bytes"; 
binmode STDOUT, ":encoding(utf-8)"; 

use XML::Parser;
use Encode qw/from_to/;
use Encode::Guess;

use IO::Dir;
use File::stat;



#-----------------------------------------------------------#
#--  NOTAバージョン定義 ------------------------------------#

$m_version = "218";

#-----------------------------------------------------------#
#--  フォームのPOSTとGETを取得 -----------------------------#
sub nota_get_form
{
	my( $array ) = @_ ;

	my $buffer = "";
	if ($ENV{'REQUEST_METHOD'} eq "POST") { read(STDIN,$buffer,$ENV{'CONTENT_LENGTH'}); }
	else { $buffer = $ENV{'QUERY_STRING'}; }
	my @pairs = split(/&/,$buffer);
	foreach (@pairs)
	{
		my ($name, $value) = split(/=/, $_);
		$name =~ tr/+/ /;
		$name =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		$value =~ tr/+/ /;
		$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		#連想配列へ格納
		$$array{$name} = $value;
	}
}

#-----------------------------------------------------------#
#--  クッキー取得  -----------------------------------------#
sub nota_get_cookie
{
	my( $array ) = @_ ;
	
	my $buffer = $ENV{'HTTP_COOKIE'};
	my @pairs = split(/; /,$buffer);
	foreach (@pairs)
	{
		my ($name, $value) = split(/=/, $_);
		$value =~ tr/+/ /;
		$value =~ s/%([a-fA-F0-9][a-fA-F0-9])/pack("C", hex($1))/eg;
		#連想配列へ格納
		$$array{$name} = $value;
	}

}
#-----------------------------------------------------------#
#--  表示言語の取得  ---------------------------------------#
sub nota_get_lang
{
	#クッキーがあるか
	my $lang = $COOKIE{'lang'};
	if (defined($lang) && $lang ne ""){
		&nota_validate($lang);
		return $lang;
	}
	
	#環境変数から
	$lang = $ENV{'HTTP_ACCEPT_LANGUAGE'};
	if ($lang =~ /^ja/){
		return "ja";
	}else{
		return "en";
	}

}


#-----------------------------------------------------------#
#-- HTMLでエラー出力 ---------------------------------------#
sub nota_error_html
{
	my ($title,$text) = @_;

	#日英表記分け
	my %japanese = (
		'Back' => '前の画面へ戻る', 
		'Home' => 'トップページへ移動', 
		'Manual' => 'ノータの使い方を見る'
	);
	my $words = join('|',keys( %japanese ));
	
	
	#テンプレートの読み込み
	my $temppath = $m_themedir . "/error.html";
	if (open(DATA,"<:encoding(utf-8)", "./$temppath")){
		@htmls = <DATA>;
		close(DATA);
	}
	
	#テンプレートを置換して出力
	print "Pragma: no-cache\n";
	print "Cache-Control: no-cache\n";
	print "Expires: Sun, 10 Jan 1990 01:01:01 GMT\n";
	print "Content-type: text/html\n\n";
	foreach (@htmls){
		$_ =~ s/<!--NOTA ERROR TITLE-->/$title/;
		$_ =~ s/<!--NOTA ERROR TEXT-->/$text/;
		$_ =~ s/<!--THEME DIR-->/$m_themedir/;
		if ($lang eq "ja"){
			$_ =~ s/($words)/$japanese{$1}/go;
		}
		print $_;
	}
}

#-----------------------------------------------------------#
#-- Flashのコードを出力 ------------------------------------#
sub nota_print_flash
{
	my ($name,$movie,$flashvars,$scale,$bgcolor,$wmode,$width,$height) = @_;
	return <<"END_FLASH";
		<object classid="clsid:D27CDB6E-AE6D-11cf-96B8-444553540000"
			 codebase="http://download.macromedia.com/pub/shockwave/cabs/flash/swflash.cab#version=6,0,0,0"
			 width="$width" height="$height" id="$name" align="">
			<param name="movie" value="$movie">
			<param name="FlashVars" value="$flashvars">
			<param name="quality" value="high"> 
			<param name="scale" value="$scale">
			<param name="menu" value="false">
			<param name="wmode" value="$wmode">
			<param name="bgcolor" value="$bgcolor">
			<param name="salign" value="LT">
			<embed src="$movie" FlashVars="$flashvars"
			 quality="high" bgcolor="$bgcolor" wmode="$wmode" scale="$scale" salign="LT" menu="false"
			 width="$width" height="$height" name="$name" align="" type="application/x-shockwave-flash"
			 pluginspage="http://www.macromedia.com/go/getflashplayer">
			</embed>
		</object>
END_FLASH
	
}

#-----------------------------------------------------------#
#----- GMT日付に変換 ---------------------------------------#
sub nota_get_gmt
{
	my ($date) = @_;
	my ($secg, $ming, $hourg, $mdayg, $mong, $yearg, $wdayg) = gmtime($date);
	my @mons = ('Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec');
	my @week = ('Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat');
	my $dt= sprintf("%s\, %02d-%s-%04d %02d:%02d:%02d GMT", $week[$wdayg], $mdayg, $mons[$mong], $yearg+1900, $hourg, $ming, $secg);
	
	return $dt;

}


#-----------------------------------------------------------#
#----- 文字コード変換 --------------------------------------#
sub nota_convert
{
	#エンコードする
	local ($data,$to,$from) = @_;

	#fromが分からなければ、自動で推定する
	if (!defined($from)){
		my $enc = guess_encoding($data,qw/euc-jp shiftjis utf8/);
	    if( ref $enc ){
	        $from = $enc->name;
	    } else {
			#utf8とみなす
			$from = 'utf8';
	    }
	}

	#変換
	if ($to eq 'shiftjis' && $from eq 'utf8'){
		$data =~ s/\xEF\xBD\x9E/\xE3\x80\x9C/g; #～記号の変換バグがある(Encodeでも変わらず)
	}
	
	from_to( $data, $from, $to );
	
	if ($to eq 'utf8' && $from eq 'shiftjis'){
		$data =~ s/\xE3\x80\x9C/\xEF\xBD\x9E/g; #～記号の変換バグがある(Encodeでも変わらず)
	}
	
	$_[0] = $data;
	return $from;

}

#-----------------------------------------------------------#
#----- < と > と & をエスケープする ------------------------#
sub nota_xmlescape
{
	my $text = $_[0];
	
	if (!defined($text) || $text eq ""){
		return;
	}
	
	#テキストをエスケープ
	my %escaped = ('<' => '&lt;', '>' => '&gt;', '&' => '&amp;');
	$text =~ s/([<>&])/$escaped{$1}/go;
	
	$_[0] = $text;
	
}

#-----------------------------------------------------------#
#----- < と > と & をアンエスケープする --------------------#
sub nota_xmlunescape
{
	my $text = $_[0];
	
	if (!defined($text) || $text eq ""){
		return;
	}
	
	#テキストをアンエスケープ
	my %unescaped = ('lt' => '<', 'gt' => '>', 'amp' => '&');
	$text =~ s/&(lt|gt|amp);/$unescaped{$1}/gio;
	
	$_[0] = $text;
	
}


#-----------------------------------------------------------#
#----- 文字列変数中の不正な記号を排除する ------------------#
sub nota_validate
{
	my ($text,$option) = @_;
	
	if (!defined($text) || $text eq ""){
		return;
	}
	
	#optionの値
	#default  アルファベットと数字、ハイフン、アンダーラインのみ
	#path  /:などファイ名として使えない記号を取る
	#url  0-9~!@#$%^&*()-+=a-zA-Z[];',.:"<>?\s以外の文字を削除
	#xmltag  制御コードとタグに使えない文字<>:;\/\\\r\nを消す、
	#text  制御コードを消す
	
	#セキュリティ上、アルファベット以外の文字の混入を防止する
	
	if ($option eq "path"){
		#ファイル名であるか（特にスラッシュの混入を防ぐ）
		$text =~ s/(:|;|\/|\\|\r|\n)//g;
		$text =~ s/[\x00-\x08\x0B-\x1F]//g; #制御コードを消去
	}
	elsif ($option eq "uri" || $option eq "url"){
		#URI/URLであるか
		$text =~ s/[\x00-\x08\x0B-\x1F]//g; #制御コードを消去
	}
	elsif ($option eq "text"){
		#テキストとして
		$text =~ s/[\x00-\x08\x0B-\x1F]//g; #制御コードを消去
	}
	elsif ($option eq "xmltag"){
		#XMLのタグとして
		$text =~ s/(<|>|:|;|\/|\\|\r|\n)//g;
		$text =~ s/[\x00-\x08\x0B-\x1F]//g; #制御コードを消去
	}
	else{
		#基本アルファベット以外許さない（デフォルト）
		$text =~ s/[^0-9a-zA-Z_@\-]//g;
	}
	
	$_[0] = $text;
	
}


#-----------------------------------------------------------#
#END_OF_SCRIPT
1;