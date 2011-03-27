/*
 * 
 * flag_plugin
 * プラグインオブジェクト
 * 
 */
 
pFlag = this;//親の参照

//変数初期化
photoloading = 0;  //0:まだ 1:読み込み中 2:読み込み済み

//枠の初期化
createEmptyMovieClip("Border",100);//選択用の境界線
Border._x = 0;
Border._y = 0;
Border._alpha = 0;
Border.useHandCursor = false;

//データを読み込んで表示
_root.Main.showFlagObjectData(pFlag._name);
setDepthsFlag = 1;
pFlag._visible = false;


//-------------------------------------------------------//
//プラグインの移動と選択
//-------------------------------------------------------//
back.useHandCursor = false;//手のカーソルにしない。

back.onPress = function(){
	if (PageEdit && m_DataList[pFlag._name].edit != "locked")
		onPluginPress();
	else
		_root.Main.backboard.onPress();	
}

back.onRelease = function() {
	if (PageEdit && m_DataList[pFlag._name].edit != "locked"){
		resetFocus();
		_root.Main.FlagSelect.movetab.onRelease();
	}else{
		_root.Main.backboard.onRelease();	
	}
}
back.onReleaseOutside = back.onRelease;

function onPluginPress(){
	//選択されているか？
	var bsel = _root.Main.isFlagSelected(pFlag._name);

	//選択せよ
	_root.Main.moveFlagFocus(pFlag._name,"nofocus");

	//プラグインのクリック
	if (bsel){
	//すでに選択されているなら移動
		_root.Main.FlagSelect.startMove(false);
	}
		
};



Border.onRollOver = function(){
	DrawBorder();
	if (PageEdit && !PageLock && m_DataList[pFlag._name].edit != "locked"){
		if (!_root.Main.isFlagSelected(pFlag._name)){
			Border._alpha = 80;
		}
	}else{
		Border._alpha = 0;
	}

}
Border.onRollOut = function(){
	if (PageEdit && !PageLock && m_DataList[pFlag._name].edit != "locked"){
		if (!_root.Main.isFlagSelected(pFlag._name)){
			Border._alpha = 0;
		}
	}
	

}
Border.onPress = function(){
	if (PageEdit && !PageLock && m_DataList[pFlag._name].edit != "locked"){
		Border._alpha = 0;
		onPluginPress();
	}
	
}
Border.onRelease = back.onRelease;
Border.onReleaseOutside = back.onRelease;

//-------------------------------------------------------//
//プロパティーの変更を監視し、関数の代わりに使用する。
//-------------------------------------------------------//

sizeloop = 0;

function onPluginLoad(){
	if (photoloading == 1){
		clearInterval(loadid);
		loadid = setInterval(onPluginLoad2,300,null);
	}
}

function onPluginLoad2(){
	//サイズ調整
	
	//回数増加
	sizeloop++;
	
	if (fobject._width != 20.5 && fobject._height != 20.5 &&
		fobject._width > 0     && fobject._height > 0)
	{
		//Timer終了
		clearInterval(loadid);
		photoloading = 2;//読み込み完了

		pFlag._visible = true;
		//深度を設定
		_root.Main.setFlagDepths(pFlag);
		//移動
		_root.Main.FlagSelect.moveResizeTab();
		
		//新規作成のファイルならサイズを保存する
		if (PageEdit == true && m_DataList[pFlag._name].newpic == 1)
		{
			m_DataList[pFlag._name].newpic = 0;
			var obj = new Object();	//差分を代入
			//SWFなら
			var clipBounds = fobject.getBounds(fobject._parent);
			xMax = clipBounds.xMax - fobject._x;
			yMax = clipBounds.yMax - fobject._y;
				
				
			obj.scale = "100:100";
			obj.width = Math.round(xMax);
			obj.height = Math.round(yMax);	//テキストボックスの高さ
			_root.Main.updateFlag(pFlag._name,obj);
		}
		//境界線を背景を作る（閲覧モードでも）
		DrawBorder();

	}else if (sizeloop > 20){
		//6秒経過
		clearInterval(loadid);
		loadid = setInterval(onPluginLoad2,800,null);

	}
}

function DrawBorder(){
	
	var clipBounds = fobject.getBounds(fobject._parent);
	xMax = clipBounds.xMax - fobject._x;
	yMax = clipBounds.yMax - fobject._y;
		
	var lw = 8;
	var ld = lw/2;
	Border.clear();
	Border.lineStyle(lw,0x3C3C3C,50);

	Border.moveTo(-ld,-ld);
	Border.lineTo(xMax+ld,-ld);
	Border.lineTo(xMax+ld,yMax+ld);
	Border.lineTo(-ld,yMax+ld);
	Border.lineTo(-ld,-ld);	
	
	back._width = xMax;
	back._height = yMax;

}
