/*
 * 
 * menu
 * メニュー
 * 
 */

//サブメニューを消す
hideSubmenu();

stop();
menu = this;



/////////////////////////////////////////////////////
//コマンド振り分け
function onBtnRelease(btnname){
	//ボタンが押された
	switch (btnname){
	case "b1":
		b1Release();
		break;
	case "b2":
		b2Release();
		break;
	case "f1":
		f1Release();
		break;
	case "tr":
		trRelease();
		break;
	case "bd":
		bdRelease();
		break;
	case "cut":
		_root.Main.cutFlag(true);
		break;
	case "copy":
		_root.Main.cutFlag(false);
		break;
	case "paste":
		_root.Main.pasteFlag(false);
		break;
	case "bg":
		_root.masterPage();
		break;		
	}
	
};

function onBtnRollOver(btnname){
	//ボタンをマウス通過
	hideSubmenu();//メニューを隠す

	switch (btnname){
	case "sb":
		sbOver();
		break;
	case "cc":
		ccOver();
		break;
	case "f1":
		f1Over();
		break;
	case "m1":
		m1Over();
		break;
	case "l1":
		l1Over();
		break;
	case "bd":
		bdOver();
		break;
	case "tc":	//太さ
		tcOver();
		break;
	case "tr":
	case "cut":
	case "copy":
	case "paste":
		hideSubmenu();
		break;
	}
	
};


/////////////////////////////////////////////////////
//コマンド実行
function b1Release(){
	//ファイルを開く
	_root.Main.openFlagFile(m_SelList[0].num);
	playSound("PAGE");	
};

function b2Release(){
	//ファイルを保存
	_root.Main.openFlagFile(m_SelList[0].num,true);
	playSound("PAGE");	
};
function selectLink(url,title){
	//リンク先が選択された。
	fm = new TextFormat();
	fm.underline = true;
	fm.color = "0x0000FF";
	trace("リンク作成成功");
	fm.url = "link.cgi?page=" + MyPage + "&url=" + url;
	fm.target = "link";

	setFormat(fm,null,title);//titleは非選択時の文字挿入用
};

function cancelLink(){
	//リンクを解除する
	//アンダーラインをとる	
	var targetflag = eval("_root.Main." + SelTarget);
	of = new TextFormat();
	if (SelStart > 0)
		of = targetflag.textbox.getTextFormat(SelStart-1);
	else
		of = targetflag.textbox.getTextFormat(SelEnd);
	if (Number(of.color) == Number("0x0000FF")){//青だったら、強制的に黒に
		of.color = "0x000000";
	}

	fm = new TextFormat();
	fm.underline = false;
	fm.url = "";
	fm.color = of.color;


	setFormat(fm,false);		
};
function trRelease(){
	//透過
	playSound("KASHA");
	for (var i=0;i<m_SelList.length;i++){
		_root.Main.changeFlagTranslate(m_SelList[i].num);
	}		

};

b3.onRelease = function(){
	//色
	fm = new TextFormat();
	fm.color = 0xFF0000;
	
	setFormat(fm);
};

function f1Release(){
	//普通
	fm = new TextFormat();
	fm.font = "Arial";
	
	setFormat(fm);
};

function bdRelease(){

	//太字に
	if (m_SelList.length > 0){
		//フォーカスあらば、文字色
		if (fm){
			//テキストの色を取得
			cubd = fm.bold;
		}
	}
			
	var fm = new TextFormat();
	fm.bold = !cubd;
	
	setFormat(fm);
};

function onSetColor(mycolor){
	//色を設定
	if (toolbtntab._currentframe >= 5){
		if (m_SelList.length > 0){
			for (var i=0;i<m_SelList.length;i++){
				//図形の色を設定
				_root.Main.changeFlagBack(m_SelList[i].num,mycolor);
			}			
		}else{
			//ペンの色を設定
			_root.Main.setPenColor(mycolor);
		}
		//色を保存
		var so = new SharedObject;
		so = SharedObject.getLocal("NOTA");
		so.data.mycolor = mycolor;
		so.flush();
		delete so;
		
		playSound("KASHA");
		
	}
	else if (toolbtntab._currentframe == 1){
		//ページの背景色
		//図形の色を設定
		_root.Main.changePageBack(mycolor,1);
		
		playSound("KASHA");
	}
	else if (!fm){
		//背景色として設定
		for (var i=0;i<m_SelList.length;i++){
			//図形の色を設定
			_root.Main.changeFlagBack(m_SelList[i].num,mycolor);
		}		
		playSound("KASHA");
		
	}else{
		//文字色設定
		var fm = new TextFormat();
		fm.color = mycolor;
		setFormat(fm);
	}
	
};



////////////////////////////////////////////////////
//サブメニューの表示

function sbOver(){
	//文字サイズ選択ボックスの表示
	restoreFocus();
	setTimer();
	
	if (m_SelList.length > 0){
		//フォーカスあらば、文字色
		if (fm){
			//テキストの色を取得
			fontsizebox.selectSize(fm.size.toString(10));
		}
	}

	fontsizebox._visible = true;

};

function ccOver(){
	//文字色選択ボックスの表示
	restoreFocus();
	setTimer();
	
	//背景色の設定なら現在地を選択
	if (toolbtntab._currentframe == 1){
		//背景色
		//ペンの色を取得
		colorbox.selectColor(_root.Main.pagebgcolor);		
		
	}else{
		if (m_SelList.length > 0){
			//フォーカスあらば、文字色
			if (fm){
				//テキストの色を取得
				colorbox.selectColor("0x" + fm.color.toString(16));
			}else{
				//オブジェクトの背景色を設定
				colorbox.selectColor(m_DataList[m_SelList[0].num].bgcolor);
			}
		}else{
			//ペンの色を取得
			colorbox.selectColor(_root.Main.pencolor);		
		}
	}
	
	//カラーセットを表示
	colorbox._visible = true;
	colorbox.loadColorSet();
};



function bdOver(){
	//フォント選択
	restoreFocus();

};

function tcOver(){
	//線の太さボックスを表示
	setTimer();
	strokebox.init();
	strokebox._visible = true;	
};

function m1Over(){
	//画像クリッピングボックスを表示
	setTimer();
	clippingbox._visible = true;	
};

function l1Over(){
	//リンク設定ダイアログ表示
	restoreFocus();
	setTimer();
	
	linklist.setList();//ページを追加
	linklist.source = menu;//呼び出しもとを設定
	linklist._visible = true;

}

function hideSubmenu(){
	//サブメニューを消す
	clearInterval(intervalID);
	linklist._visible = false;
	colorbox._visible = false;
	clippingbox._visible = false;
	fontsizebox._visible = false;
	strokebox._visible = false;
	
};

function setFormat(format,select,newtext){
	hideSubmenu();
	//ゲストは変更できない
	if (_root.Main.IsFlagGuestLock(SelTarget)){
		return;
	}

	playSound("KASHA");

	var targetflag = eval("_root.Main." + SelTarget);
	
	//選択した文字にフォーマットを適用
	if (SelStart == SelEnd && newtext != null){
		Selection.setFocus("_root.Main." + SelTarget + ".textbox");
		Selection.setSelection(SelStart,SelStart);
		targetflag.textbox.replaceSel(newtext);
		SelEnd = SelStart + newtext.length;
	}
	
	targetflag.textbox.setTextFormat(SelStart,SelEnd,format);
	//データを保存する
	targetflag.textchange = true;	//変更された
	targetflag.saveText();

};

function restoreFocus(){
	//フォーカスを記憶
	fm = null;
	var arTarget = Selection.getFocus().split(".");
	if (arTarget[2] != undefined){
		SelTarget = arTarget[2];
		SelStart = Selection.getBeginIndex();
		SelEnd = Selection.getEndIndex();
		if (SelStart != SelEnd){
			var targetflag = eval("_root.Main." + SelTarget);
			SelText = targetflag.textbox.text.substr(SelStart,SelEnd-SelStart);
			
			//文字が選択されているとき、フォーマットを取得
			fm = new TextFormat();
			fm = targetflag.textbox.getTextFormat(SelStart,SelEnd);
		}else{
			SelText = "";
		}
	}
	
};

function setTimer(){
	//マウスが出るのを監視
	clearInterval(intervalID);
	intervalID = setInterval(Timer,500);
	
};


//マウスが、ここから出て行ったなら。
function Timer(){
	var pt = new Object();
	pt.x = _root._xmouse;
	pt.y = _root._ymouse;
	
	var target;
	if (linklist._visible)
		target = linklist;
	else if (colorbox._visible)
		target = colorbox;
	else if (clippingbox._visible)
		target = clippingbox;
	else if (fontsizebox._visible)
		target = fontsizebox;
	else if (strokebox._visible)
		target = strokebox;
		
	menu.globalToLocal(pt);
	if (!toolbtntab.hitTest(_root._xmouse,_root._ymouse,true) && 
		!target.hitTest(_root._xmouse,_root._ymouse,true))
	{
		if (toolbtntab._currentframe != 2 || Selection.getFocus().indexOf("url") == -1){
			hideSubmenu();
			clearInterval(intervalID);
		}
	}
	
};
	
	
