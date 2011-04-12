/*
 * 
 * flag_text
 * 文字列オブジェクト
 * 
 */
 
pFlag = this;//親の参照

//変数初期化
photoloading = 0;  //0:まだ 1:読み込み中 2:読み込み済み
textchange = false;

//最初は、書き込めない
textbox.border = false;
textbox.type = "dynamic";

//データを読み込んで表示
_root.Main.showFlagObjectData(pFlag._name);
setDepthsFlag = 1;
pFlag._visible = true;

//-------------------------------------------------------//
//プロパティーの変更を監視し、関数の代わりに使用する。
//-------------------------------------------------------//
clearInterval(loadid);
loadid = setInterval(onFlagLoad2,150,null);

function onFlagLoad2(){
	pFlag._visible = true;
	clearInterval(loadid);

	if (setDepthsFlag == 1){
		//深度を設定(0.5秒後)
		setDepthsFlag = 0;
		_root.Main.setFlagDepths(pFlag);
	}	
	
	if (selected == true){
		//選択指示あり
		//FlagSelectを表示させる
		_root.Main.FlagSelect.moveResizeTab();//このオブジェクトをセットする

		//テキストの選択
		setTextSelect();
		selected = false;
	}
	
}



//-------------------------------------------------------//
//テキストボックス関数／イベント
//-------------------------------------------------------//

function deleteBlankBox(){
	if (textbox.inclt != true){
		return;
	}
	
	//テキストが空になった状態で
	//フォーカスを失った場合、アイテムを削除する
	if (!_root.Main.isFlagSelected(pFlag._name)){
		if (textbox.text == "" || textbox.text == "\r"){
			//データを削除せよ！
			_root.Main.deleteInterFlag(pFlag._name);
			//フォーカスを消す。
			_root.Main.moveFlagFocus(-1);
		}
	}
	
};


function setTextSelect(){
	//アイテムが選択されたときに呼ばれる
	
	//テキストボックスの調整
	var num = pFlag._name;
	if (!_root.Main.IsFlagGuestLock(num,true)){
		//他人のページで人の文を変更不可	
		//入力可能にする
		textbox.type = "input";
	}
	fillTextBack(false);	//背景色削除
	
};


function killTextSelect(){
	//アイテムの選択が解除されたときに呼ばれる

	//テキストボックスの調整
	//textbox.border = false;
	textbox.type = "dynamic"; //入力不可にする
	fillTextBack(true);	//背景色描画
	deleteBlankBox();	//文字が無い場合、アイテムを消す
	

};


function saveText(){
	//テキストボックスの変更を保存
	
	if (textsvIntervalID != undefined){
		clearInterval(textsvIntervalID);
		textsvIntervalID = undefined;
	}

	if (textbox._visible && textchange == true){	//変更フラグのある時
		//データを保存する
		var htmltext = textbox.htmlText;

		if (m_DataList[pFlag._name].text != htmltext){
			//変更フラグを解除
			textchange = false;
			var obj = new Object();	//差分を代入
			obj.text = htmltext;
			obj.height = Math.round(textbox._height);	//テキストボックスの高さ
			_root.Main.updateFlag(pFlag._name,obj);	

		}
	}

};




function fillTextBack(fill){
	
	clearInterval(fillInterval);

	//テキストの背景を描く
	//印刷する時に、textboxのbgcolorが
	//印刷されないので、手動で描いている
	//なんとも面倒だ
	var bgcolor = m_DataList[pFlag._name].bgcolor;
	if (fill && textbox._visible && 
		bgcolor.length > 2 && bgcolor != 0xFFFFFF)
	{
		var obj = pFlag;
		obj.clear();
		obj.beginFill(bgcolor,100);
		obj.moveTo(0,0);
		obj.lineTo(textbox._width,0);
		obj.lineTo(textbox._width,textbox._height);
		obj.lineTo(0,textbox._height);
		obj.lineTo(0,0);
		obj.endFill();
	}else{
		pFlag.clear();
	}
	
};

textbox.onSetFocus = function(){
	var time = new Date;

	//選択せよ
	if (time.getTime()-mdowntime < 1000){
		_root.Main.moveFlagFocus(pFlag._name,"noremove");
	}
};

textbox.onKillFocus = function(){
	//テキストボックスがフォーカスを失う
	if (PageEdit){
		//データを保存する
		//ここは非常に気をつけなければ、ならない。
		//ユーザーの変更があるときのみ認めらるべきである
		saveText();
	}
	
};
textbox.onChanged = function(){
	//テキストボックスの文章が変更された。
	//サイズ変更
	if (_root.Main.FlagSelect.resizetab._y != textbox._y + textbox.textHeight)
	{
		//タブの位置調整
		_root.Main.FlagSelect.moveResizeTab();	
	}

	//自動でサイズ調整
	if (textbox.autoSize != true){
		textbox.autoSize = true;
	}
	
	//保存処理
	textchange = true; //変更フラグ
	if (textsvIntervalID != undefined)
		clearInterval(textsvIntervalID);
	textsvIntervalID = setInterval(saveText,3*1000);//3秒ごと

};


//自動するクロール変数
scintervalID = 0;
mdrag = false;

//マウスが移動ではなく、その場で離されたかどうか
this.onMouseDown = function(){
	if(_root._ymouse < 25){
		//タイトルバーだ。
		return;
	}

	//スクロールバーを押している
	if (_root._ymouse > Stage.height-18){
		return;
	}
	//ダブルクリックとみなす
	var time = new Date;
	_global.dblClickText = false;
	if (Math.pow(oldx-this._xmouse,2) + Math.pow(oldy-this._ymouse,2) <= 16){
		//前回とクリック点がほぼ同じかつ3秒以内
		if (time.getTime()-mdowntime < 3000){
			_global.dblClickText = true;
		}			
	}

	//場所を記憶
	_global.dblClickTextPtX = _root.Main._xmouse;
	_global.dblClickTextPtY = _root.Main._ymouse;
	oldx = this._xmouse;
	oldy = this._ymouse;
	oldsel = _root.Main.oldfnum;
	//時間を記憶
	mdowntime = time.getTime();

	if (textbox._visible){
		//テキストのドラッグ開始
		mdrag = true;
	}


	
};


function movebarTimer(down){
	//テキストの自動スクロール
	if (_root.Main.PageDragging){
		//Mapをドラッグで移動中ならキャンセル
		return;
	}
	if (mdrag && textbox._visible && _root.Main.isFlagSelected(pFlag._name)){
		var p = new Object;
		p.x = 0;
		var dif=0;
		if (down){
			p.y = textbox.textHeight;
			pFlag.localToGlobal(p);
			if (p.y < Stage.height-17-20){
				stopMovebar();
				return;	
			}
			dif = -25;
		}else{
			p.y = 0;
			pFlag.localToGlobal(p);
			if (p.y > 28+20){
				stopMovebar();
				return;
			}
			dif = 25;
		}
		var nextx = _root.Main._x;
		var nexty = _root.Main._y + dif;
		//移動
		_root.Main.moveMap(nextx,nexty);
	}
};

function stopMovebar(){
	//自動スクロールタイマーストップ
	if (scintervalID != 0){
		clearInterval(scintervalID);
		scintervalID = 0;
		//場所保存
		_root.Main.saveMapPosition();
	}

	
};

this.onMouseMove = function(){
	if (mdrag && textbox._visible && _root.Main.isFlagSelected(pFlag._name))
	{
		//マウスがクライアントの外にあるなら
		var x = _root._xmouse;
		var y = _root._ymouse;	
		if (y > Stage.height-17){
			if (scintervalID == 0){
				scintervalID = setInterval(movebarTimer,50,true);
			}
		}else if (y < 28){
			if (scintervalID == 0){
				scintervalID = setInterval(movebarTimer,50,false);
			}
		}else{
			stopMovebar();
		}
	}
};

this.onMouseUp = function(){
	mdrag = false;
	stopMovebar();

};
