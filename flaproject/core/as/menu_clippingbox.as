/*
 * 
 * dlg_clippingobx
 * 写真を図形で切り抜くダイアログ
 * 
 */

menu = this;

shapes = new Array("rectangle","roundrect","circle","triangle","star","hexagon","pentagon","heart","thorn");

DlgBack.useHandCursor = false;
DlgBack.onPress = function(){
	
};

if (MyLang == "en"){
	dlg_message = "Cut image : \nselect a \npattern.";
	
}


for (var i=1;i<=9;i++){
	var obj = eval("shape" + i);
	obj.gotoAndStop(shapes[i-1]);
	obj.onRelease = onShapeMRelease;
}

ura = 0;
function onShapeMRelease(){
	//図形が選択された
	
	//数字と、名前の関係
	var num = this._name.substr(5,1);
	var sname = shapes[num-1];
	if (sname == "rectangle"){
		sname = "";	
	}
	
	if (ura == 0 && num == 1){
		ura++;	
	}else if (ura == 1 && num == 2){
		ura++;	
	}else if (ura == 2 && num == 1){
		ura++;	
	}else if (ura == 3 && num == 2){
		sname = "nota";//裏コマンド！
		ura = 0;	
	}else{
		ura = 0;	
	}
	
	//クリッピング
	for (var i=0;i<m_SelList.length;i++){
		//図形の色を設定
		_root.Main.changeFlagMask(m_SelList[i].num,sname);
	}			
	
	
	menu._visible = false;
	
	playSound("KASHA");
	
};


