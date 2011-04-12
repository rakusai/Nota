/*
 * 
 * flag_text
 * 文字列オブジェクト
 * 
 */
 
pFlag = this;//親の参照

//変数初期化
photoloading = 0;  //0:まだ 1:読み込み中 2:読み込み済み

//データを読み込んで表示
_root.Main.showFlagObjectData(pFlag._name);
setDepthsFlag = 1;
pFlag._visible = true;

//-------------------------------------------------------//
//fileiconイベントハンドラ
//-------------------------------------------------------//


fileicon.onPress = function(){
	//選択せよ
	if (PageEdit){
		onFilePress();
	}else{
		//編集モードでなければ
		this._x += 2;
		this._y += 2;
	}
};

fileicon.onMouseMove = function(){
	//手のカーソルを用いるか否か
	this.useHandCursor = (!PageEdit);

};


fileicon.onRelease = function(){
	if (!PageEdit){
		//編集モードでなければ添付ファイルをその場で開く
		this._x -= 2;
		this._y -= 2;
		_root.Main.openFlagFile(pFlag._name);
	}else{
		//移動
		resetFocus();
		_root.Main.FlagSelect.movetab.onRelease();
	
	}
};

fileicon.onReleaseOutside = function(){
	if (!PageEdit){
		//編集モードでなければ
		this._x -= 2;
		this._y -= 2;
	}else{
		//移動
		resetFocus();
		_root.Main.FlagSelect.movetab.onRelease();
	
	}
};


saveicon.onRelease = function(){
	//添付ファイルをダウンロード
	_root.Main.openFlagFile(pFlag._name,true);
	
};

function onFilePress(){
	//選択せよ
	_root.Main.moveFlagFocus(pFlag._name,"nofocus");
	
    //すでに選択されているなら移動
    _root.Main.FlagSelect.movetab.onPress();
	
	
};
