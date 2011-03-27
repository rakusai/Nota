/*
 * 
 * dlg_addshape
 * 図形を追加するダイアログ
 * 
 */


setColor();

shapes = new Array("circle","rectangle","roundrect","triangle","star","hexagon","pentagon","heart","thorn","arrow");

if (MyLang == "en"){
	dlg_color = "Color";
	dlg_message = "Select a shape.";
}

for (var i=1;i<=10;i++){
	var obj = eval("shape" + i);
	var shape = shapes[i-1];
	if (shape == "arrow"){
		//ボタン表示用の矢印を使用
		shape += "_show";
	}
	obj.gotoAndStop(shape);
	obj.onPress = onShapePress;
	obj._y = 2 + (18-obj._height);//下位置合わせ
}

DlgBack.useHandCursor = false;
DlgBack.onRollOver = function(){
	//通常のカーソルに戻せ！
	showMyCursor(false);
	
	
}
shapeblank.useHandCursor = false;
shapeblank.onRollOver = function(){
	//通常のカーソルに戻せ！
	showMyCursor(false);
	
	
}
cc.onRelease = onBtnRelease;
cc.onRollOver = onBtnRollOver;

function onBtnRelease(){
	//ボタンが押された
	_parent.onBtnRelease(this._name);
};

function onBtnRollOver(){
	//ボタンをマウス通過
	_parent.onBtnRollOver(this._name);
	//通常のカーソルに戻せ！
	showMyCursor(false);
	
};


ura = 0;
notan = 0;

function onShapePress(){
	//図形が選択された
	
	//数字と、名前の関係
	var num = this._name.substr(5);
	
	var name = shapes[num-1];
	
	if (ura == 0 && num == 1){
		ura++;	
	}else if (ura == 1 && num == 2){
		ura++;	
	}else if (ura == 2 && num == 1){
		ura++;	
	}else if (ura == 3 && num == 2){
		name = "nota";//裏コマンド！
		ura = 0;	
	}else{
		ura = 0;	
	}
	
	if (notan == 0 && num == 6){
		notan++;	
	}else if (notan == 1 && num == 6){
		notan++;	
	}else if (notan == 2 && num == 6){
		notan++;	
	}else if (notan == 3 && num == 6){
		name = "notan";//裏コマンド！
		notan = 0;	
	}else{
		notan = 0;	
	}	
	
	_root.Main.curshape = name;
	_root.Pen.shape.gotoAndStop(_root.Main.curshape);

	playSound("KASHA");
	setColor();
	
};

function setColor(){
	//現在の図形の選択を描画
	var num = 1;
	for (var i=1;i<=10;i++){
		if (_root.Main.curshape == shapes[i-1]){
			num = i;
		}
	}
	if (_root.Main.curshape == "nota" || _root.Main.curshape == "notan"){
		num = -1;	
	}
	
	
	for (var i=1;i<=10;i++){
		var obj = eval("shape" + i);
		myColor  = new Color(obj);
		if (num == -1){
			myColor.setRGB(0xCCFF00);//裏コマンド(黄緑色)		
		}else if (i == num){
			myColor.setRGB(_root.Main.pencolor);//選択（青）
		}else{
			myColor.setRGB(0x999999);//非選択
//			myColor.setRGB(0xFFFFFF);//非選択
		}
	}		
	
};