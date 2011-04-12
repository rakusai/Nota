/*
 * 
 * flag_photo
 * 写真オブジェクト
 * 
 */
 
pFlag = this;//親の参照
//変数初期化
photoloading = 0;  //0:まだ 1:読み込み中 2:読み込み済み

//形を初期化
shape._width = 0;
shape._height = 0;

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
//photoイベントハンドラ
//-------------------------------------------------------//
photo.useHandCursor = false;//手のカーソルにしない。
shape.useHandCursor = false;//手のカーソルにしない。

shape.onPress = function(){
	if (PageEdit && m_DataList[pFlag._name].edit != "locked")
		onPhotoPress();
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

function onPhotoPress(){
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



Border.onRollOver = function(){
	DrawBorder();
	if (PageEdit && !PageLock  && pFlag.fileext == "swf" &&
		m_DataList[pFlag._name].edit != "locked")
	{
		if (!_root.Main.isFlagSelected(pFlag._name)){
			Border._alpha = 80;
		}
	}else{
		Border._alpha = 0;
	}

}
Border.onRollOut = function(){
	if (PageEdit && !PageLock  && pFlag.fileext == "swf" &&
		m_DataList[pFlag._name].edit != "locked")
	{
		if (!_root.Main.isFlagSelected(pFlag._name)){
			Border._alpha = 0;
		}
	}
	

}
Border.onPress = function(){
	if (PageEdit && !PageLock  && pFlag.fileext == "swf" &&
		m_DataList[pFlag._name].edit != "locked")
	{
		Border._alpha = 0;
		onPhotoPress();
	}
	
}
Border.onRelease = shape.onRelease;
Border.onReleaseOutside = shape.onRelease;

//-------------------------------------------------------//
//プロパティーの変更を監視し、関数の代わりに使用する。
//-------------------------------------------------------//
//var texttest = "";
sizeloop = 0;
test = "";
function onPhotoLoad(){
	
	//ながれとしては　width:20.5  イベント一度目
	//直後 width :0 
	//最後に width:任意　イベント2度目
	//となる
	//一度目のイベントは無視する
	if (photoloading == 1){
		clearInterval(loadid);
		loadid = setInterval(onPhotoLoad2,300,null);
		
	}
	
	if (photo.picture.getBytesTotal() <= 0){
		//読み込みエラー発生！
		//サイズ0 なら読み込み失敗
		pFlag.breakpic = 1;
		photo.picture.removeMovieClip()
		photo.attachMovie("FlagBreak","picture",0);
	}
	
}


function onPhotoLoad2(){

	//この関数はなぜか2回呼ばれる。
	//最初は、width=0 で　次に値が入るので最初の 0は無視する

	
	//回数増加
	sizeloop++;
	//サイズ調整
	if (photo._width != 20.5 && photo._height != 20.5 &&
		photo._width > 0     && photo._height > 0)
	{
		clearInterval(loadid);
		
		photoloading = 2;//読み込み完了
		//画像の場合だけ、サイズ調整
		setPhotoSize();
		//深度を設定
		_root.Main.setFlagDepths(pFlag);
		pFlag._visible = true;
		
		//新規作成のファイルならサイズを保存する
		if (PageEdit == true && m_DataList[pFlag._name].newpic == 1){
			m_DataList[pFlag._name].newpic = 0;
			var obj = new Object();	//差分を代入
			var xMax = fobject._width;
			var yMax = fobject._height;
			if (photo._visible && pFlag.fileext == "swf"){
				//SWFなら
				var clipBounds = fobject.getBounds(fobject._parent);
				xMax = clipBounds.xMax - fobject._x;
				yMax = clipBounds.yMax - fobject._y;
				
				obj.scale = "100:100";
				//もし、サイズが0なら削除せよ
				if (xMax <= 0 || yMax <= 0){
					if (MyLang == "en"){
						MessageBox("You can't insert an unavailable flash.");
					}else{
						MessageBox("中身がないフラッシュは貼り付けられません。");
					}
					_root.Main.deleteFlag();						
					return;
				}
				
			}
			obj.width = Math.round(xMax);
			obj.height = Math.round(yMax);	//テキストボックスの高さ
			

			
			_root.Main.setFlagDepths(pFlag);//深さ調整
			_root.Main.updateFlag(pFlag._name,obj);

			
		}
		
		//境界線を背景を作る（閲覧モードでも）
		DrawBorder();	
	}else if (sizeloop > 20){
		//3秒経過
		//ゆっくり待つ
		clearInterval(loadid);
		loadid = setInterval(onPhotoLoad2,800,null);
		
	}
}


//-------------------------------------------------------//
//写真・プラグインの展開後の処理
//-------------------------------------------------------//

function setPhotoSize(){
	
	if (photoloading != 2){
		return;
	}
	
	//画像のサイズをセットする
	var obj = m_DataList[pFlag._name];

	//縦横比保持の場合はよこしか見ない
	//SWFファイルの場合
	if (pFlag.fileext == "swf" && obj.scale.length > 0 && 
		pFlag.breakpic != 1){
		//Flashの場合は、数値はScaleに変換してみてやる
		var perl = obj.scale.split(":");
		photo._xscale = perl[0];
		photo._yscale = perl[1];
	}else{
		var w = photo.picture._width;
		var h = photo.picture._height;
		if (obj.width > 0){
			photo._width = obj.width;
			if (obj.height > 0)
				photo._height = obj.height;
			else
				photo._height = photo._width*h/w;
		}
	}
	//マスキングクリップの調整
	if (!shape.hitArea){
		shape._width = photo._width;	//マスキング
		shape._height = photo._height;
	}

	//タブの位置調整
	_root.Main.FlagSelect.moveResizeTab();
	

};

function DrawBorder(){
	
	if (pFlag.fileext == "swf"){
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
	}

}