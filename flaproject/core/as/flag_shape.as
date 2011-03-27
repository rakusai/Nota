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
//	(pFlag._name == _root.Main.oldfnum);
	
	//選択せよ
//	if (!bsel){
		_root.Main.moveFlagFocus(pFlag._name,"nofocus");
//	}
	//図形のクリック
	if (bsel){
		//すでに選択されているなら移動
//		if (!_root.Main.IsFlagGuestLock(pFlag._name,true)){
			_root.Main.FlagSelect.startMove(false);
//		}
	}
	
	
};



//-------------------------------------------------------//
//プロパティーの変更を監視し、関数の代わりに使用する。
//-------------------------------------------------------//
/*
clearInterval(loadid);
loadid = setInterval(onFlagLoad2,100,null);

function onFlagLoad2(){
	pFlag._visible = true;
	clearInterval(loadid);

	if (setDepthsFlag == 1){
		//深度を設定(0.5秒後)
		setDepthsFlag = 0;
		_root.Main.setFlagDepths(pFlag);
	}	
}
*/
/*
this.onEnterFrame = function (){


	
};

*/

