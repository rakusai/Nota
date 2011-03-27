/*
 * 
 * dlg_print
 * プリントダイアログ
 * 
 */
 
 pDlg = this;
DlgBack.draggable = true;
showPrint();


function showPrint(){
	//印刷ダイアログの表示
	
	if (MyLang == "en"){
		dlg_print_title = "■Print Page";
		dlg_print_message = "Select pages you print, then press [Next].";
		dlg_print_bitmap = "Print as bitmap";		
		dlg_print_next = "Next";		
		dlg_print_cancel = "Cancel";
	}
	
	//ツール選択
	for (var i=0;i<PluginList.length;i++) {
		PluginList[i].onSelectTool("print");		//ツールの表示を更新
	}	
	
	//ページ数計算
	PageStart.removeAll();
	PageEnd.removeAll();
	for (var i=1;i<=_root.Main.page_cnt;i++){
		if (MyLang == "en"){
			PageStart.addItem('pp.' + i);
			PageEnd.addItem('pp.' + i);
		}else{
			PageStart.addItem(i + 'ページ');
			PageEnd.addItem(i + 'ページ');
		}
	}
	
	if (isNewFlash){
		PageStart.selectedIndex = 0;
	}else{
		//現在何ページ目が表示されているのか？
		PageStart.selectedIndex = Math.round(-_root.Main._y / (PageH * _root.Main._xscale / 100));
	}
	PageEnd.selectedIndex = _root.Main.page_cnt-1;
	
	//表示
	if (isNewFlash){
		PrintMes.gotoAndStop(1);
		PageEnd._visible = true;
	}else{
		PrintMes.gotoAndStop(2);
		PageEnd._visible = false;
	}
}


PrintNext.onRelease = function(){
	//印刷開始
	if (isNewFlash)
		printNew();
	else
		printOld();
	
};

PrintCancel.onRelease = function(){

	//ダイアログを閉じる
	gotoAndStop("close");	
	
};
delbtn.onRelease = PrintCancel.onRelease;


function printNew(){
	//バージョン7.0以上の印刷
//	_root.Main._xscale = 102;
//	_root.Main._yscale = 102;
	if (PageStart.selectedIndex > PageEnd.selectedIndex){
		//範囲指定がおかしいので、入れ替える
		var st = PageStart.selectedIndex;
		PageStart.selectedIndex = PageEnd.selectedIndex;
		PageEnd.selectedIndex = st;
	}
	
	//選択を解除
	_root.Main.moveFlagFocus(-1);
	//テキストの全描画
	_root.Main.showTextBoxInClient(true);
	//倍率をなるべくあげて、実際の印刷精度に合わせる
	var oldscale = _root.Main._xscale;
	_root.Main._visible = false;
	_root.Main._xscale = 1000;
	_root.Main._yscale = 1000;

	clearInterval(pn2);
	pn2 = setInterval(printNew2,1000,oldscale);
}

function printNew2(oldscale){
	
	clearInterval(pn2);
	

	//ダイアログを非表示にする
	pDlg._visible = false;	
	
	// PrintJob オブジェクトを作成
	my_pj = new PrintJob();                        // オブジェクトをインスタンス化
	
	// 印刷ダイアログボックスを表示
	if (my_pj.start())
	{
		
		// 印刷ジョブを初期化
	
		//Mainのスケールを、用紙の幅に合わせる
		_root.Main.setAutoSizeOff(true); //一時的にオートサイズをオフにする
		_root.Main._xscale = my_pj.pageWidth * 100 / PaperW;
		_root.Main._yscale = _root.Main._xscale;
		_root.Main.canvasLine._visible = false;

//		var printW = PaperW;
		
		//ここは、この数値で固定する必要がある？なぜかは不明
		var printW = 1000;
		var printH = PageH;
	//	var printH = 1414;
	

//	var printW = _root.Main._width*100*my_pj.pageWidth/my_pj.paperWidth/_root.Main._xscale-50;
//		var printH = _root.Main._width*1.41*100/_root.Main._yscale;
//		var printH = printW * 1.35;
//		var printH = printW * my_pj.pageHeight / my_pj.pageWidth;
//		var printH = printW*1.41;//my_pj.pageHeight / my_pj.pageWidth;
//		var printH = _root.Main._width*1.41*100/(my_pj.pageWidth / 10);//my_pj.pageHeight / my_pj.pageWidth;
		// 指定の領域を印刷ジョブに追加
		// 印刷するページごとに繰り返す
	//	for (var i=PrintStart.selectedIndex;i<=_root.PrintEnd.selectedIndex;i++){
		
		
		for (var i=0;i<_root.Main.page_cnt;i++){
			if (PageStart.selectedIndex <= i && i <= PageEnd.selectedIndex){
				//印刷範囲内であるか
				if (my_pj.addPage(_root.Main,{xMin:0,xMax:printW,yMin:printH*i,yMax:printH*(i+1)},{printAsBitmap:PrintBitmap.selected}))
				{
				}
			}
		}
	
		
		// スプーラからプリンタにページを送る
		my_pj.send();                                   // ページを印刷
	}
	// 後処理
	delete my_pj; 	
	
	//元に戻す
	_root.Main._xscale = oldscale;
	_root.Main._yscale = oldscale;
	_root.Main._visible = true;
	_root.Main.canvasLine._visible = true;
	_root.Main.setAutoSizeOff(false);
	
	//ダイアログ表示を戻す
	pDlg._visible = true;
	
	//ダイアログを閉じる
	gotoAndStop("close");	
	
	
};

function printOld(){
	//旧バージョンの印刷
	//印刷開始
	//まず、１ページが収まるように
	//Mainの幅を1010にする（すなわちスケール100）
	//余白を少し削る
	var sc = _root.Main._xscale;
	var x = _root.Main._x;
	var y = _root.Main._y;
	
	//現在何ページ目が表示されているのか？
	var nPage = PageStart.selectedIndex;
//	var nPage = Math.round(-_root.Main._y / (PageH * _root.Main._xscale / 100));
	//選択を解除
	_root.Main.moveFlagFocus(-1);
	//テキストの全描画
	_root.Main.showTextBoxInClient(true);
	
	_root.Main._xscale = 1000/PaperW*102;
	_root.Main._yscale = 1000/PaperW*102;
	_root.Main._x = -10;
	_root.Main._y = -10 - nPage*1414*1.02;
	//printAsBitmap("Main", "bmovie");
	
	function waitPrint(){
		clearInterval(intervalID);
		
		if (PrintBitmap.selected)
			printAsBitmapNum(_root.Main,"bmovie");
		else
			printNum(_root.Main,"bmovie");
	};
	var intervalID = setInterval(waitPrint,200);		

	//ダイアログを閉じる
	gotoAndStop("close");	

	
};
