#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai
#CreateDate: 2007/02/27
#NDFファイルのデータを追加・編集・削除するパッケージ
#-----------------------------------------------------------#

package NOTA::NDF;

use utf8;
binmode STDIN,  ":bytes"; 
binmode STDOUT, ":encoding(utf-8)"; 

use XML::Parser;
use Encode qw/from_to/;
use Encode::Guess;

use IO::Dir;
use IO::File;
use File::stat;

use strict;
use warnings;

my $record = ''; #処理中のIDを覚えておくためのスタック
my $current_element = ''; #処理中のエレメントを覚えておくためのスタック
my $current_line = '';
my $ref_item_array; #扱う配列のリファレンスをセットする


#-----------------------------------------------------------#
#--  コンストラクタ ----------------------------------------#
sub new
{
	my $class = shift;
	my $self  = {};
	$self->{ndfarray} = []; #無名配列へのリファレンス
	$self->{filelist} = []; #無名配列へのリファレンス
	$self->{errortext} = "";
	$self->{errornum} = "";
	$self->{oldversion} = 0;
	bless ($self, $class);
}

#-----------------------------------------------------------#
#--  取得系関数 --------------------------------------------#
sub get_ndfarray
{
	my $self = shift;
	return $self->{ndfarray};
}
sub get_ndfarray_count
{
	my $self  = shift;
	my $ref   = $self->{ndfarray};
	my $count = @$ref;
	return $count;
}
sub get_filelist
{
	my $self = shift;
	return $self->{filelist};
}
sub is_oldversion
{
	my $self = shift;
	return $self->{oldversion};
}
sub get_filelist_count
{
	my $self  = shift;
	my $ref   = $self->{filelist};
	my $count = @$ref;
	return $count;

	return $count;
}

sub get_errortext
{
	my $self = shift;
	return $self->{errortext};
}
sub get_errorcode
{
	my $self = shift;
	return $self->{errorcode};
}


#-----------------------------------------------------------#
#----- NDFリストに値を追加・セットする ---------------------#
#sub addNDFList
sub setItem
{
	my ($self,$itemid,$param,$value) = @_;

	#バリデーション
	main::nota_validate($itemid,'xmltag');
	main::nota_validate($param,'xmltag');
	main::nota_validate($value,'text');
	
	#UTF-8フラグを立てる
	if (!Encode::is_utf8($value)){
		utf8::decode($value);
	}
	my $oldvalue = "";
	my $olditemid = "";
	my $setchk = 0;
	my $i = 0;
	my $ref_array = $self->{ndfarray};
	foreach (@$ref_array){
		if ($_ =~ /^([\w\-_]*):([\w\-_]*)=(.*)/){
			if ($1 eq $itemid && $2 eq $param){
				#上書き
				$oldvalue = "$2=>$3\n";
				$_ = "$itemid:$param=$value";
				$setchk = 1;
				return $oldvalue;
			}
			if ($1 ne $olditemid && $itemid eq $olditemid){
				#この位置に追加
				$ref_array = $self->{ndfarray};
				splice(@$ref_array,$i,0,"$itemid:$param=$value");
				$setchk = 1;
			}
			$olditemid = $1;
		}
		$i++;
	}
	#新たに追加
	if (!$setchk){
		$ref_array = $self->{ndfarray};
		push (@$ref_array,"$itemid:$param=$value");
	}
	return $oldvalue;
}

#-----------------------------------------------------------#
#----- NDFリストから値を削除する ---------------------------#
#sub deleteNDFList
sub deleteItem
{
	my ($self,$itemid,$param) = @_;

	my $oldvalue = "";
	my @newlist = ();
	my $ref_array = $self->{ndfarray};
	foreach (@$ref_array){
		if ($_ =~ /^([\w\-_]*):([\w\-_]*)=(.*)/){
			if ($1 eq $itemid && ($2 eq $param || !$param)){
				#削除
				$oldvalue .= "$2=>$3\n";
			}else{
				push (@newlist,$_);
			}
		}
	}
	
	$self->{ndfarray} = [@newlist];
	return $oldvalue;
	
}
#-----------------------------------------------------------#
#----- NDFリストの値を取得する -----------------------------#
#sub getNDFList
sub getItem
{
	my ($self,$itemid,$param) = @_;

	my $ref_array = $self->{ndfarray};
	foreach (@$ref_array){
		if ($_ =~ /^([\w\-_]*):([\w\-_]*)=(.*)/){
			if ($1 eq $itemid && $2 eq $param){
				return $3;
			}
		}
	}
	return;
}

#-----------------------------------------------------------#
#----- NDFリストのBodyのIDの配列を返す ---------------------#
sub getBodyIDList
{
	my ($self, $array) = @_ ;
	my $oldid = "";
	my $ref_array = $self->{ndfarray};
	foreach (@$ref_array){
		if ($_ =~ /^([\w\-_]*):([\w\-_]*)=(.*)/){
			if ($1 ne "head" && $1 ne $oldid){
				push(@$array, $1);
				$oldid = $1;
			}
		}
	}
	return;
}


#-----------------------------------------------------------#
#----- NDFリストからXML文書を生成 --------------------------#
sub writefile
{
	my ($self,$path) = @_;

	#ファイルを書き込み権限付きで開く
	my $io = IO::File->new($path, 'w');
	if (!$io){
		$self->{errorcode} = 100;
		return 0;
	}
	#書き込む
	flock($io, 2); #ファイルロック
	$self->write($io);
	#閉じる
	$io->close;

	return 1;

}

#-----------------------------------------------------------#
#----- NDFリストからXML文書に書き込む ----------------------#
sub write
{
	my ($self,$io) = @_;
	my $itemid="";
	
	binmode($io, ":encoding(utf-8)"); #utf8フラグを落として出力
	$io->print("<?xml version=\"1.0\" encoding=\"utf-8\"?>\n");

	my $ndftext = "<?xml version=\"1.0\" encoding=\"utf-8\"?>\n";
	$io->print("<nota>\n");
	$io->print("\t<head>\n");
	my $ref_array = $self->{ndfarray};
	foreach (@$ref_array){
		if ($_ =~ /^head:([a-z]*)=(.*)/){
			my $param = $1;
			my $value = $2;
			main::nota_xmlescape($value);	#エスケープ
			$io->print("\t\t<$param>$value</$param>\n");
		}
	}
	$io->print("\t</head>\n");
	$io->print("\t<body>\n");
	foreach (@$ref_array){
		if ($_ =~ /^([\w\-_]*):([\w\-_]*)=(.*)/ && $1 ne "head"){
			if ($1 ne $itemid){
				if ($itemid ne ""){
					$io->print("\t\t</item>\n");
				}
				$itemid = $1;
				$io->print("\t\t<item id=\"$1\">\n");
			}
			#エスケープ < と > と & のエスケープ　
			#ただし、もともとHTMLになっている場合は、CDATAに入れるだけ
			#Flashから送られてきたものだから、最初からエスケープされている
			
			#文字列中に<か>がある場合はCDATAに入れる
			my $param = $2;
			my $value = $3;
			if ($param eq 'text'){
				#HTML文書です。
				$value = "<![CDATA[" . $value . "]]>";
			}else{
				main::nota_xmlescape($value);	#エスケープ
			}
			$io->print("\t\t\t<$param>$value</$param>\n");
		}
	}
	if ($itemid ne ""){
		$io->print("\t\t</item>\n");
	}
	$io->print("\t</body>\n");
	$io->print("</nota>\n");
	
	return 1;
}

#-----------------------------------------------------------#
#----- XMLのタグの開始ハンドラー ---------------------------#
sub _handle_start_element
{
	my ($expat, $element, %attrs) = @_;
	
	if ($record eq ''){
		if ($element eq "head"){
			$record = "head";
		}elsif ($element eq "item" && defined($attrs{'id'})){
			$record = $attrs{'id'};
		}
		$current_element = '';
	}else{
		push(@$ref_item_array,"$record:$element=");
		$current_element = $element;
	}
}

#-----------------------------------------------------------#
#----- XMLのタグの終了ハンドラー ---------------------------#
sub _handle_end_element
{
	my ($expat, $element) = @_;
	
	if ($element eq "head" || $element eq "item"){
		if ($element ne $current_element){
			$record = '';
		}
	}
}

#-----------------------------------------------------------#
#----- XMLの文字列ハンドラー -------------------------------#
sub _handle_characters
{
	my ($expat, $text) = @_;

	return if ($text =~ /^\s*$/m); #空白文字は無視する
	
	#XML::Parserのバグ回避
	$text =~ s/\\FF3E;/＾/g;
	$text =~ s/\\FF3F;/＿/g;
	$text =~ s/\\FF7E;/ｾ/g;
	$text =~ s/\\FF7F;/ｿ/g;
	#追加した配列に文字列を追加
	$$ref_item_array[-1] .= $text;
	$current_line= $expat->current_line;
	
}

#-----------------------------------------------------------#
#----- ファイルを開きNDF文書を解析してデータのリストを作成 -#
sub parsefile
{
	my ($self,$path) = @_;

	#ファイルを読み込んでから解析
	my $io = IO::File->new($path, 'r');
	if (!$io){
		$self->{errorcode} = 100;
		return 0;
	}
	my @lines = $io->getlines;
	$io->close;

	return $self->parse("@lines");

}
#-----------------------------------------------------------#
#----- NDF文書を解析してデータのリストを作成 ---------------#
sub parse
{
	my ($self,$xml) = @_;
	
	my $paser = new XML::Parser;
	
	#バリデーション
	main::nota_validate($xml,'text');	#テキストとして
	#XML::Parserのバグ回避
	$xml =~ s/\xEF\xBC\xBE/\\FF3E;/g; #＾
	$xml =~ s/\xEF\xBC\xBF/\\FF3F;/g; #＿
	$xml =~ s/\xEF\xBD\xBE/\\FF7E;/g; #ｾ
	$xml =~ s/\xEF\xBD\xBF/\\FF7F;/g; #ｿ
	#配列のリファレンスを記録
	$ref_item_array = $self->{ndfarray};  #配列のリファレンスをコピー
	
	$paser->setHandlers(Start => \&_handle_start_element,
	                 End => \&_handle_end_element,
	                 Char => \&_handle_characters);
	eval{$paser->parse($xml)};

	#UTF-8フラグを立てる
	if (!Encode::is_utf8($xml)){
		utf8::decode($xml);
	}
	
	if ($@){
		#パースエラー
		my $errortext = $$ref_item_array[-1]; #エラーメッセージ
		main::nota_xmlescape($errortext);
		$self->{errorcode} = 200;
		$self->{errortext} = "Error at line: $current_line, <br>" . $errortext;
		return 0;
	}
	return 1;
}

#-----------------------------------------------------------#
#----- NOTA1.xを2.0のデータに変換する ----------------------#
sub convertToNewNota
{
	my ($self, $dir,$page) = @_;
	
	#DATファイルを読み込む
	my $io = IO::File->new("$dir/$page.dat", 'r');
	if (!$io){
		return 0;
	}
	my @lines = $io->getlines;
	$io->close;
	
	foreach (@lines){
		if ($_ =~ /^auth=(.*)/){
			$self->setItem('head','author',$1);	#authをauthorに
		}elsif ($_ =~ /^title=(.*)/){
			$self->setItem('head','title',$1);
		}elsif ($_ =~ /^date=(.*)/){
			$self->setItem('head','date',$1);
		}elsif ($_ =~ /^update=(.*)/){
			$self->setItem('head','update',$1);
		}elsif ($_ =~ /^edit=(.*)/){
			$self->setItem('head','edit',$1);
		}elsif ($_ =~ /^height=(.*)/){
			$self->setItem('head','height',$1);
		}elsif ($_ =~ /^width=(.*)/){
			$self->setItem('head','width',$1);
		}
	}
	$self->setItem('head','version','2.0');
	#CSVファイル
	if (open(DATA,"< $dir/$page.csv")) { 
		@lines = <DATA>;
		close(DATA);
	}else{
		return 0;
	}
	foreach (@lines){
		#データを見る
		my ($del,$id,$auth,$tool,$date,$update,$x,$y,$w,$h,$aparam,$bparam,$cparam,$comment,$rotation,$etc) = split(/,/,$_);
		if ($del ne "1" && defined($x) && $x ne ""){
			$self->setItem($id,'author',$auth);	#auth→author
			$self->setItem($id,'tool',$tool);
			$self->setItem($id,'date',$date);
			$self->setItem($id,'update',$update);
			#x,y
			if ($tool eq "DRAW"){
				my @xlist = split(/:/,$x);
				my @ylist = split(/:/,$y);
				my $stroke = "";
				my $i=0,
				my $x1;
				my $y1;
				foreach $x1 (@xlist){
					$y1 = $ylist[$i];
					if ($i != 0){
						$stroke .= " ";
					}
					$stroke .= "($x1,$y1)";
					$i++;
				}
				$self->setItem($id,'x',$x);
				$self->setItem($id,'y',$y);
			}else{
				$self->setItem($id,'x',$x);
				$self->setItem($id,'y',$y);
			}
			$self->setItem($id,'width',$w);
			$self->setItem($id,'height',$h);
			#aparam
			if ($tool eq "FILE"){
				$self->setItem($id,'fname',$aparam);
			}
			elsif ($tool eq "TEXT"){
				$self->setItem($id,'text',$aparam);
			}
			elsif ($tool eq "SHAPE"){
				$self->setItem($id,'shape',$aparam);
			}
			elsif ($tool eq "PLUGIN"){
				$self->setItem($id,'plugin',$aparam);
			}
			elsif ($tool eq "DRAW"){
				$self->setItem($id,'fgcolor',$aparam);
			}
			#bparam
			if ($tool eq "SHAPE" || $tool eq "TEXT"){
				$self->setItem($id,'bgcolor',$bparam);
			}
			elsif ($tool eq "PLUGIN"){
				$bparam =~ s/\.txt$/\.xml/g;
				$self->setItem($id,'fname',$bparam);
			}
			elsif ($tool eq "FILE"){
				if ($bparam =~ /:/){
					$self->setItem($id,'scale',$bparam);
				}else{
					$self->setItem($id,'shape',$bparam);
				}
			}
			elsif ($tool eq "DRAW"){
				if ($bparam eq ''){
					$bparam = 3;
				}
				$self->setItem($id,'thickness',$bparam);
			}
			#cparam
			if ($tool eq "SHAPE" || $tool eq "FILE"){
				if ($cparam eq ''){
					$cparam = 100;
				}
				$self->setItem($id,'transparent',$cparam);
			}
			if ($rotation eq ''){
				$rotation = 0;
			}
			$self->setItem($id,'rotation',$rotation);
		}
	}
	#NDFファイル書き込み
	$self->writefile("$dir/$page.ndf");
	
	return 1;
}



#-----------------------------------------------------------#
#--  フォルダ内のNDFファイルの一覧を返す -------------------#
#sub getNDFFileList
sub getFileList
{
	my ($self, $dir, $start, $count) = @_ ;

	#カレントディレクトを変更
	chdir "$dir" or die $!;
	
	#ファイルの一覧を更新日時順に並び替えた配列
	my @files = map{ $_->[0] }
	        sort{ $b->[1] <=> $a->[1] }
	            map{ [$_, stat($_)->mtime] }
	                grep{ not /^\.\.?$/ }
	                     IO::Dir->new('.')->read;
	
	#全部を返す
	if (!defined($start)){
		$start = 0;
		$count = @files;
	}
	#ループ
	my $ref_array = $self->{filelist};
	
	my $i = 0;
	my $oldcnt = 0;
	my $page;
	foreach $page (@files){
		$page =~ s/\.(\w+)$//;	#拡張子を取得
		my $ext = $1;
		if ($page =~ /template/){
			next;
		}elsif ($ext =~ /ndf/){
			#NDFファイル
			if ($start <= $i && $i < $start+$count){
				#ファイルに関する詳細情報
				my @tmp = $self->getHead($dir,$page);
				if (@tmp){
					push (@$ref_array,[@tmp]);
				}
			}
			$i++;
		}elsif ($ext =~ /dat/){
			$oldcnt++;
		}
	}
	if ($oldcnt > $i){
		#未変換の旧バージョンのデータが存在
		$self->{oldversion} = 1;
	}
	#全ページ数を返す
	return $i;
}


#-----------------------------------------------------------#
#--  NDFファイルのヘッダ情報を配列で返す -------------------#

sub getHead
{
	my($self, $dir, $page ) = @_ ;

	#ファイルに関する詳細情報
	my @lines = ();
	my $line;
	my $roottag = '';
	if (open(DATA,"< $dir/$page.ndf")) {
		while (defined($line = <DATA>)){
			push(@lines,$line);
			if ($line =~ /<(nota|ndf)>/ && $roottag eq ''){
				$roottag = $1;
			}elsif ($line =~ /^\s*<\/head>\s*$/){
				push(@lines,"</$roottag>");
				last;
			}
		}
		close(DATA);
		#XMLをリストにする
		my $ndf = NOTA::NDF->new;
		$ndf->parse("@lines");
		
		#参照渡しでもらった配列に収納
		#参照渡しでもらった配列に収納
		my $update = $ndf->getItem('head','update');
		my $edit   = $ndf->getItem('head','edit');
		my $title  = $ndf->getItem('head','title');
		my $author = $ndf->getItem('head','author');
		my @tmp    = ($page,$author,$title,$edit,$update);
		
		return @tmp;
	}
}


#-----------------------------------------------------------#
#END_OF_SCRIPT
1;