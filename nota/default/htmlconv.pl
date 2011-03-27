#!/usr/bin/perl

#-----------------------------------------------------------#
#Programmmed by Isshu Rakusai,2004-2005
#LastUpdate: 2005/10/04
#-----------------------------------------------------------#

use Image::Magick;
use utf8;
use notalib::NDF;

binmode STDIN,  ":bytes"; 
binmode STDOUT, ":encoding(utf-8)"; 

#-----------------------------------------------------------#
#--  HTML出力 ----------------------------------------------#
sub printHtml
{
	my ($page,$lang) = @_;
	
	my $ndf = NOTA::NDF->new;
	if (!$ndf->parsefile("$m_datadir/$page.ndf")){
		#オープンエラー
		if ($ndf->get_errorcode == 100){
			if ($lang eq "en"){
				&nota_error_html("Can't open file.");
			}else{
				&nota_error_html("ファイルを開けません。");
			}
		}else{
			if ($lang eq "en"){
				&nota_error_html("Failure to parse XML.", $ndf->get_errortext);
			}else{
				&nota_error_html("XMLの解析に失敗しました。",$ndf->get_errortext);
			}
		}
		return;
	}
		
	#ページ属性を求める
	my $title = "NOTA - " . $ndf->getItem('head','title');
	&nota_xmlescape($title);	#エスケープ
	my $pagewidth = $ndf->getItem('head','width');
	if (!defined($pagewidth)){
		$pagewidth = 1000;
	}
	my $pageheight = $ndf->getItem('head','height');
	if (!defined($pageheight)){
		$pageheight = $pagewidth * 1.414;
	}
	my $pagebgcolor = $ndf->getItem('head','bgcolor');
	if (!defined($pagebgcolor)){
		$pagebgcolor = "FFFFFF";
	}else{
		$pagebgcolor = colorChange($pagebgcolor);
	}
	#HTML化
	local $itemhd = "";	#ここに<style>内の#layer一覧
	local $items = "";	#layerの各要素
	local %ZLIST = ();	#アイテムの順序
	#本文を求める
	&getPageItems($page,$ndf);
	
	my $metarobot = '';
	if ($m_norobot == 1){
		$metarobot = "<meta content=NONE name=ROBOTS>\n\t<meta content=NOINDEX,NOFOLLOW name=ROBOTS>";
	}
	my $gotoflash = "./?$page";
	if ($page eq "home"){
		$gotoflash = "./";
	}
	
	#ページ数の取得
	if ($ybottom > $pageheight){
		$pageheight = (int($ybottom / $pageheight)+1) * $pageheight;
	}
	
	#日英表記分け
	my %japanese = (
		'NOTA Portal' => 'NOTAポータルへ', 
		'NOTA in Flash' => 'FLASH版に移動する', 
		'Home' => 'ホーム',
		'Help' => 'ヘルプ',
		'FAQ' => '質問集',
		'Manual' => '使い方',
		'Share Nota' => '友人に教える',
		'FullScreen' => '全画面',
		'Feedback' => 'ご意見',
		'Show RSS Feed' => 'RSSを表示',
	);
	my $words = join('|',keys( %japanese ));
	
	#テンプレートの読み込み
	my $temppath = $m_themedir . "/html.html";
	if (open(DATA,"<:encoding(utf-8)", "./$temppath")){
		@htmls = <DATA>;
		close(DATA);
	}else{
		&nota_error_html("テンプレートファイルが開けません。");
		return;
	}
	
	#テンプレートを置換してHTML出力
	print "Content-type: text/html; charset=UTF-8\n\n";
	foreach (@htmls){
		$_ =~ s/<!--NOTA TITLE-->/$title/;
		$_ =~ s/<!--NOTA META INFO-->/$metarobot/;
		$_ =~ s/<!--NOTA PAGE WIDTH-->/$pagewidth/;
		$_ =~ s/<!--NOTA PAGE HEIGHT-->/$pageheight/;
		$_ =~ s/<!--NOTA ITEM HEAD-->/$itemhd/;
		$_ =~ s/<!--NOTA HTML ITEM-->/$items/;
		$_ =~ s/<!--NOTA SIDE BAR-->/$sidebar/;
		$_ =~ s/<!--NOTA GOTO FLASH-->/$gotoflash/;
		$_ =~ s/<!--NOTA GOTO SCREEN-->/\.\/?$page\.screen/;
		$_ =~ s/<!--NOTA GOTO RSS-->/rss.cgi/;
		$_ =~ s/<!--NOTA LIST-->/sidebar.cgi?page=$page&html=1/;
		$_ =~ s/<!--NOTA GOTO MAIL-->/mail.cgi?page=$page/;
		$_ =~ s/<!--NOTA PAGE BGCOLOR-->/#$pagebgcolor/;
		if ($lang eq "en"){
			$_ =~ s/<!--NOTA GOTO HELP-->/http:\/\/nota\.jp\/en\/help\//;
			$_ =~ s/<!--NOTA GOTO CONTACT-->/http:\/\/nota\.jp\/en\/contact\//;
		}else{
			$_ =~ s/<!--NOTA GOTO HELP-->/http:\/\/nota\.jp\/help\//;
			$_ =~ s/<!--NOTA GOTO CONTACT-->/http:\/\/nota\.jp\/contact\//;
		}
		if ($lang eq "ja"){
			$_ =~ s/($words)/$japanese{$1}/go;
		}
		$_ =~ s/<!--THEME DIR-->/$m_themedir/;
		print $_;
	}	
	

}

#-----------------------------------------------------------#
#--  フォントスタイル --------------------------------------#
sub getFontStyle
{
	my $text = "";
	my $i = 0;
	while ($i <= 120){
		my $h = int(1.23*$i + 4.95);
		
		$text .= "#f$i  { font-size: ${i}px; line-height: ${h}px }\n";

		$i ++;
	}
	return $text;
}

#-----------------------------------------------------------#
#--  ページのアイテムを変数にセットする --------------------#
sub getPageItems
{
	my ($page,$ndf) = @_;

	#変数を定義
	my %AITEMS = ();	#各要素をY値をキーとしてセット
	my %P = ();
	my $i = 0;
	my $mkdir = 0;
	my $id = '';
	my $text = "";
	my $startitem = 1;
	$ybottom = 0;
	local %DRAWINGS = (); #画像ファイルのファイル名をセット
	$isdrawing_update = 0; #画像の更新の有無
	my $ref_array = $ndf->get_ndfarray;
	foreach (@$ref_array){
		if ($_ =~ /^(\w*):(\w*)=(.*)/){
			my $nid = $1;
			my $param = $2;
			my $value = $3;
			#IDの替わり時を捉える
			if (($nid ne 'head' && $id ne $nid) || $i == $ndf->get_ndfarray_count -1){
				if ($i == $ndf->get_ndfarray_count -1){
					$P{"$param"} = "$value";#最後の項目
				}
				$text = "";

				#ファイル名とテキストのエンコード
				$P{'text'} =~ s/%2B/\+/g;	#+記号過去との互換性
				$P{'text'} =~ s/%2C/,/g;	#区切り 過去との互換性
				$P{'text'} =~ s/&apos;/'/g;	#なぜか' が&apos;になる。過去との互換性
				
				if ($P{'tool'} eq "TEXT"){
					#文字列
					#リンク先の変更
					$P{'text'} =~ s/<A HREF="link\.cgi\?url=http/<A HREF="http/g;
					$P{'text'} =~ s/<A HREF="link\.cgi\?url=mailto/<A HREF="mailto/g;
					$P{'text'} =~ s/<A HREF="link\.cgi\?url=([^"]*)/<A HREF=".\/?$1\.html/g;
					$P{'text'} =~ s/TARGET="link"//g;
					$P{'text'} =~ s/\$amp;/&/g;
					$P{'text'} =~ s/\$equal;/=/g;
					#特殊フォーマットが必要
					$P{'text'} =~ s/<TEXTFORMAT LEADING="[0-9]*">//g;
					$P{'text'} =~ s/<\/TEXTFORMAT>//g;
					$P{'text'} =~ s/<\/P>/<BR>/g;
					$P{'text'} =~ s/(<P[^>]*>|<\/P>)//g;
					$P{'text'} =~ s/(<U>|<\/U>)//g;
					$P{'text'} =~ s/<BR>$//g;
					#フォントサイズの変換
					$P{'text'} =~ s/SIZE="([0-9]+)"/ID="f$1"/g;
					$P{'text'} =~ s/<FONT (FACE=".*?" |)/<FONT /g;
					$text .= $P{'text'};
					#背景色の変換
					my $bgcolor = colorChange($P{'bgcolor'});
					if ($bgcolor ne "ffffff" && $bgcolor ne "FFFFFF"){
						$bgcolor = "background-color: #$bgcolor;";
					}else{
						$bgcolor = "";
					}
					#Z-index
					my $pzi = 0;
					if ($P{'height'} > 0 && !($P{'text'} =~ /<A/)){
						$pzi = arrageZindex(7000-$P{'width'}*$P{'height'}/100 * 0.6);
					}else{
						$pzi = arrageZindex(8000);
					}
					my $sti = $P{'y'};
					while (length($sti) < 20){ $sti = "0" . $sti; }
					$itemhd .= "#layer$i { z-index: $pzi; position: absolute; top: $P{'y'}px; left: $P{'x'}px; width: $P{width}px; visibility: visible; display: block; $bgcolor }\n";
					
					$AITEMS{"$sti"} .= "\t<div id=\"layer$i\">\n";
					$AITEMS{"$sti"} .= "\t$text</div>\n\n";
					
				}
				elsif ($P{'tool'} eq "FILE"){
					#ファイルと画像
					if ($P{'fname'} =~ /\.(jpg|swf)$/){	#画像
						my $picsize = '';
						my $lyrsize = '';
						if ($P{'width'} > 0){
							$picsize = "width=\"$P{'width'}\"";
							$lyrsize = "width: $P{'width'}px; ";
						}
						if ($P{'height'} > 0){
							$picsize .= " height=\"$P{'height'}\"";
						}
						if ($P{'fname'} =~ /\.jpg$/){
							$text .= "\t<img src=\"view.cgi?page=$page&fname=". url_encode($P{'fname'}) . "\" alt=\"$P{'fname'}\" $picsize>";
						}else{
							$text = &nota_print_flash("file$i","view.cgi?page=$page&fname=". url_encode($P{'fname'}) . "\"","","exactfit","#FFFFFF","transparent",$P{'width'},$P{'height'});
						}
						my $sti = $P{'y'};
						my $pzi = 0;
						if ($P{'height'} > 0){
							$pzi = arrageZindex(7000-$P{'width'}*$P{'height'}/100);
						}elsif ($P{'width'} > 0){
							$pzi = arrageZindex(7000-$P{'width'}*$P{'width'}/100);
						}else{
							$pzi = arrageZindex(7000-20*20/100);
						}
						while (length($sti) < 20){ $sti = "0" . $sti; }
						$itemhd .= "#layer$i { z-index: $pzi; position: absolute; top: $P{'y'}px; left: $P{'x'}px; ${lyrsize}visibility: visible; display: block; }\n";
						
						$AITEMS{"$sti"} .= "\t<div id=\"layer$i\">\n";
						$AITEMS{"$sti"} .= "$text\t</div>\n\n";
					}else{			#その他のファイル
						my $ext = $P{'fname'};
						$ext =~ s/.*\.//g;
						if ($ext =~ /(doc|wft)/){
							$ext = "doc";
						}elsif ($ext =~ /pdf/){
							$ext = "pdf";
						}elsif ($ext =~ /(jtd|jtdc)/){
							$ext = "jtd";
						}elsif ($ext =~ /(xls|cls)/){
							$ext = "xls";
						}elsif ($ext =~ /(html|htm)/){
							$ext = "html";
						}elsif ($ext =~ /ppt/){
							$ext = "ppt";
						}elsif ($ext =~ /(zip|lzh|tar|gz)/){
							$ext = "zip";
						}else{
							$ext = "fileicon";
						}
						
						$text .= "<a href=\"view.cgi?page=$page&fname=". url_encode($P{'fname'}). "\"><img src=\"res/$ext.gif\" alt=\"$P{'fname'}\" border=0><BR>$P{'fname'}</a>";
						#Z-index
						my $sti = $P{'y'};
						my $pzi = arrageZindex(8000);
						while (length($sti) < 20){ $sti = "0" . $sti; }
						$itemhd .= "#layer$i { z-index: $pzi; position: absolute; top: $P{'y'}px; left: $P{'x'}px; width: 100px; visibility: visible; display: block; }\n";
						$AITEMS{"$sti"} .= "\t<div id=\"layer$i\" align=center>\n";
						$AITEMS{"$sti"} .= "\t$text</div>\n\n";
					}
				}
				elsif ($P{'tool'} eq "PLUGIN"){
					#プラグイン
#					$text = &nota_print_flash("plugin$i","plugin.swf?ver=$m_version&plg=$P{'plugin'}&id=$nid&page=$page&fname=$P{'fname'}","","noscale","#FFFFFF","transparent",$P{'width'},$P{'height'});

					#Z-index
#					my $sti = $P{'y'};
#					my $pzi = 0;
#					if ($P{'height'} > 0 && $P{'width'} > 0){
#						$pzi = arrageZindex(7000-$P{'width'}*$P{'height'}/100);
#					}else{
#						$pzi = arrageZindex(7000-100*100/100);
#					}
#					while (length($sti) < 20){ $sti = "0" . $sti; }
#					$itemhd .= "#layer$i { z-index: $pzi; position: absolute; top: $P{'y'}px; left: $P{'x'}px; ${lyrsize}visibility: visible; display: block; }\n";
					
#					$AITEMS{"$sti"} .= "\t<div id=\"layer$i\">\n";
#					$AITEMS{"$sti"} .= "$text\t</div>\n\n";
					
				}
				elsif ($P{'tool'} eq "SHAPE"){
					#図形
					#色
					my $bgcolor = $P{'bgcolor'};
					if ($bgcolor =~ /0x/){
						$bgcolor = hex($bgcolor);#10進数に戻す
					}
					#回転によるずれを計算
					#通常時
					
					#0-90の時
					my $pright = $P{'width'};
					my $pleft = 0;
					my $ptop = 0;
					my $pbottom = $P{'height'};

					if ($P{'rotation'} <= 90){
						$pright = $P{'width'}*cos2($P{'rotation'});
						$pleft = -$P{'height'}*cos2(90-$P{'rotation'});
						$ptop = 0;
						$pbottom = $P{'width'}*sin2($P{'rotation'})+$P{'height'}*sin2(90-$P{'rotation'});
					}elsif ($P{'rotation'} <= 180){
						#90-180の時
						$pright = 0;
						$pleft = -($P{'width'}*cos2(180-$P{'rotation'})+$P{'height'}*cos2($P{'rotation'}-90));
						$ptop = -$P{'height'}*sin2($P{'rotation'}-90);
						$pbottom = $P{'width'}*sin2(180-$P{'rotation'});
					}elsif ($P{'rotation'} <= 270){
						#180-270の時
						$pright = $P{'height'}*cos2(270-$P{'rotation'});
						$pleft = -$P{'width'}*cos2($P{'rotation'}-180);
						$ptop = -($P{'height'}*sin2(270-$P{'rotation'})+$P{'width'}*sin2($P{'rotation'}-180));
						$pbottom = 0;
					}else{
						#270-360の時
						$pright = $P{'width'}*cos2(360-$P{'rotation'})+$P{'height'}*cos2($P{'rotation'}-270);
						$pleft = 0;
						$ptop = -$P{'width'}*sin2(360-$P{'rotation'});
						$pbottom = $P{'height'}*sin2($P{'rotation'}-270);
					}
					$pright  = int($pright);
					$pleft   = int($pleft);
					$ptop    = int($ptop);
					$pbottom = int($pbottom);
					
					my $nw = $pright-$pleft+1;
					my $nh = $pbottom-$ptop+1;
					
					my $swfurl = "shape.swf?ver=$m_version&shp=$P{'shape'}&rot=$P{'rotation'}&clr=$bgcolor&aph=$P{'transparent'}&w=$P{'width'}&h=$P{'height'}";
					$text = &nota_print_flash("shape$i","$swfurl","","noscale","#FFFFFF","transparent",$nw,$nh);
					#Z-index
					my $pzi = arrageZindex(7000-$P{'width'}*$P{'height'}/100);
					$P{'x'} += $pleft;
					$P{'y'} += $ptop;
					my $sti = $P{'y'};
					while (length($sti) < 20){ $sti = "0" . $sti; }
					$itemhd .= "#layer$i { z-index: $pzi; position: absolute; top: $P{'y'}px; left: $P{'x'}px; visibility: visible; display: block; }\n";
					$AITEMS{"$sti"} .= "\t<div id=\"layer$i\">\n";
					$AITEMS{"$sti"} .= "$text\t</div>\n\n";
					

				}
				elsif ($P{'tool'} eq "DRAW"){
					#手書き線
					#色変換
					my $stcolor = colorChange($P{'fgcolor'});
					#画像のパス
					my $imgfname = "$id" . '_' . "$P{'update'}";
					$imgfname =~ s/( |:|\/)//g;
				    $DRAWINGS{"$imgfname"} = 1;
				    #拡張子をブラウザで判別
				    my $ext = &getExtByAgent();
				    $imgfname .= $ext;
					my $imgpath = "$m_drawingdir/$page/$imgfname";
					#ポイントの整理
					my @xlist = split(/:/,$P{'xline'} ? $P{'xline'} : $P{'x'});
					my @ylist = split(/:/,$P{'yline'} ? $P{'yline'} : $P{'y'});
					my $pi = 0;
					my $b = $P{'thickness'};
					my $ylinetop    = $ylist[0];
					my $ylinebottom = $ylist[0];
					my $xlineleft   = $xlist[0];
					my $xlineright  = $xlist[0];
					my @drawlines = ();
					while ($pi < $#xlist){
						#線を分割して、配列に収納する
						if ($xlist[$pi] ne '#' && $xlist[$pi+1] ne '#'){
							push(@drawlines,"$xlist[$pi]:$ylist[$pi]:$xlist[$pi+1]:$ylist[$pi+1]");
						    
						    #領域のサイズを計算する
							my ($x1,$x2) = split(/[\^,]/,$xlist[$pi+1]);
							my ($y1,$y2) = split(/[\^,]/,$ylist[$pi+1]);
					    	$xlineleft   = $x1	if ($x1 < $xlineleft);
					    	$ylinetop    = $y1	if ($y1 < $ylinetop);
					    	$xlineright  = $x1	if ($x1 > $xlineright);
					    	$ylinebottom = $y1	if ($y1 > $ylinebottom);
					    	
					    	$xlineleft   = $x2	if ($x2 < $xlineleft   && defined($x2));
					    	$ylinetop    = $y2	if ($y2 < $ylinetop    && defined($y2));
					    	$xlineright  = $x2	if ($x2 > $xlineright  && defined($x2));
					    	$ylinebottom = $y2	if ($y2 > $ylinebottom && defined($y2));
						}else{
							#線の切れ目
							push(@drawlines,"#");
						}
						$pi++;
					}
					#最後の切れ目
					push(@drawlines,"#");
					#画像化
					if (!-e "$imgpath"){
						#フォルダの作成(最初だけ)
						if ($mkdir == 0){
							mkdir("$m_drawingdir/$page", 0755);
							$mkdir = 1;
						}
						#画像ファイルの作成
						my $iw = $xlineright - $xlineleft+$b*2;
						my $ih = $ylinebottom - $ylinetop+$b*2;
						my $image = Image::Magick->new;
						$image->Read("res/drawformat.png");
						$image->Scale(geometry=>geometry,width=>${iw},height=>${ih});
						#$image->ReadImage('xc:white');
						#$image->Set(size=>"${iw}x${ih}");
						my $points = "";
						my $isbezier = 0;
						foreach (@drawlines){
							if ($_ eq "#"){
								if ($points ne ""){
									#描画
									if ($isbezier){
									    $image->Draw(stroke=>"#$stcolor", primitive=>'bezier', 
									    points=>"$points",antialias=>'true', 
									    strokewidth=>$P{'thickness'});
									}else{
									    $image->Draw(stroke=>"#$stcolor", primitive=>'polyline', 
										points=>"$points",antialias=>'true', 
									    strokewidth=>$P{'thickness'});
									}
								    $points = "";
							    }
							}else{
								#ImageMagickに渡すパラメータ作成
								my ($xs,$ys,$xe,$ye) = split(/:/,$_);
								
								my ($x1,$x2) = split(/[\^,]/,$xs);
								my ($y1,$y2) = split(/[\^,]/,$ys);
								my ($x3,$x4) = split(/[\^,]/,$xe);
								my ($y3,$y4) = split(/[\^,]/,$ye);
								if ($xe =~ /[\^,]/){
									$isbezier = 1;
								}
								$x1 -= $xlineleft-$b; $x2 -= $xlineleft-$b; $x3 -= $xlineleft-$b; $x4 -= $xlineleft-$b;
								$y1 -= $ylinetop -$b; $y2 -= $ylinetop -$b; $y3 -= $ylinetop -$b; $y4 -= $ylinetop -$b;
								if ($isbezier){
									$points .= "$x1,$y1 $x4,$y4 $x3,$y3 $x3,$y3 ";
								}else{
									$points .= "$x1,$y1 $x3,$y3 ";
								}
							}
						}
					    #画像を保存
						#$image->Transparent('white');
					    $image->Write("$imgpath");
					    $isdrawing_update = 1;
				    }
					$text = "<img src=\"view.cgi?dir=$page&fname=$imgfname\" class=\"AlphaPng\" alt=\"drawing\">";
					#z-index
					my $pzi = arrageZindex(7000);
					my $sti = $ylinetop;
					while (length($sti) < 20){ $sti = "0" . $sti; }
					$xlineleft -= $b;
					$ylinetop  -= $b;
					$itemhd .= "#layer$i { z-index: $pzi; position: absolute; top: ${ylinetop}px; left: ${xlineleft}px; visibility: visible; display: block; }\n";
					
					$AITEMS{"$sti"} .= "\t<div id=\"layer$i\">\n";
					$AITEMS{"$sti"} .= "\t$text</div>\n\n";
				}
				#アイテムの一番下の位置
				my $ih = 0;
				if ($P{'height'}){
					$ih = $P{'height'};
				}
				if ($P{'y'} + $ih > $ybottom){
					$ybottom = $P{'y'} + $ih;
				}

				#新しいアイテムの始まり
				$id = $nid;
				%P = ();
			}
			#項目を記録
			$P{"$param"} = "$value";
			
		}
		$i++;	#配列数
	}
	#yの値が低い順に並べ替えを行って、追加
	#最新10のみ
	foreach ((sort keys %AITEMS)){
		$items .= $AITEMS{$_};
	}
	
	#更新があったときは古い手描き画像を削除
	if ($isdrawing_update){
		&delete_drawing($page,*DRAWINGS);
	}
	return;
}

#-----------------------------------------------------------#
#--  古い手描き画像を削除 ----------------------------------#
sub delete_drawing
{
	local($page, *array ) = @_ ; #使用中ファイルの連想配列
	#古い画像ファイルを削除
	#ディレクトリを開く
	if (!opendir(DIR,"$m_drawingdir/$page/")) { 
		return 0;
	}
	my $fname = "";
	while (defined($fname = readdir(DIR))){
		if ($fname =~ /([^\.]+)\.(gif|png)$/){
			#画像ファイル
			if ($array{"$1"} != 1){
				#現在使用していないなら削除
				unlink("$m_drawingdir/$page/$fname");
			}
		}
	}
	closedir(DIR);

	
	return 1;
}

#-----------------------------------------------------------#
#--  URLエンコード -----------------------------------------#
sub url_encode
{
    my $str = shift;
	utf8::encode($str);	#UTF8文字列を、同じ内部表現のままバイト列に変換
	$str =~ s/([^\w ])/'%' . unpack('H2', $1)/eg;
	$str =~ tr/ /+/;

    return($str);
}

#-----------------------------------------------------------#
#--  sin、cosを度で求める ----------------------------------#
sub cos2
{
	my $f = $_[0];
	if ($f == 90 || $f == 270){
		return 0;
	}else{
		return cos(3.14/180 * $f);
	}
}
sub sin2
{
	my $f = $_[0];
	if ($f == 0 || $f == 180){
		return 0;
	}else{
		return sin(3.14/180 * $f);
	}
}

#-----------------------------------------------------------#
#--  オブジェクトの上下関係 --------------------------------#
sub arrageZindex
{
	my $zindex = int($_[0]);
	if ($zindex < 30){
		$zindex = 30;
	}
	while (defined($ZLIST{"$zindex"})){
		#重複がなくなるまで繰り返す
		$zindex++;
	}
	$ZLIST{"$zindex"} = 1;
	
	return $zindex;
}

#-----------------------------------------------------------#
#--  色の形式変換 ------------------------------------------#
sub colorChange
{
	my $color = shift;

	if (!$color || $color eq "" || $color eq "n"){
		return "FFFFFF";
	}
	elsif ($color eq "0"){
		return "000000";
	}
	elsif ($color =~ /0x/){
		$color =~ s/0x//g;
	}
	else{
		$color = sprintf('%X',$color);
	}
	
	while (length($color) < 6){
		$color = "0" . $color;
	}
	return $color;

}

#-----------------------------------------------------------#
#--  ブラウザによってGIFかPNGかを返す ----------------------#
sub getExtByAgent
{
	my $UserAgent = $ENV{'HTTP_USER_AGENT'} ;
	if ( $UserAgent =~ /MSIE ([0-9])/i && $UserAgent !~ /Opera/) {
		#IE
		if (($1 le "4"  && $UserAgent =~ /Mac/) || ($1 le "6" && $UserAgent =~ /Windows/)){
			#Mac IE 4以下 or Win IE 6以下
			return ".gif";
		}
	}elsif ( $UserAgent !~ /compatible/i && $UserAgent =~ /; [IU][;\)]/ )
	{
		#NN
		$UserAgent =~ /Mozilla\/([0-9])/i ;
		if ($1 le "4") {
			#NN 4以下
			return ".gif";
		}
	}
	
	#透過PNG対応ブラウザ
	return ".png";
}

#-----------------------------------------------------------#
#END_OF_SCRIPT