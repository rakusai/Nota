/*
 * 
 * flag_shape
 * 図形オブジェクト
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
//shapeイベントハンドラ
//-------------------------------------------------------//
shape.useHandCursor = false;//手のカーソルにしない。

shape.onPress = function(){
	if (PageEdit && m_DataList[pFlag._name].edit != "locked")
		onShapePress();	
	else
		_root.Main.backboard.onPress();	
}

shape.onRelease = function() {
	if (PageEdit && m_DataList[pFlag._name].edit != "locked"){
		resetFocus();
		_root.Main.FlagSelect.movetab.onRelease();
	}else{
		_root.Main.backboard.onRelease();	
	}
}
shape.onReleaseOutside = shape.onRelease;

function onShapePress(){
	//選択されているか？
	var bsel = _root.Main.isFlagSelected(pFlag._name);
	
	//選択せよ
    _root.Main.moveFlagFocus(pFlag._name,"nofocus");
	//図形のクリック
	if (bsel){
		//すでに選択されているなら移動
        _root.Main.FlagSelect.startMove(false);
	}
	
	
};

