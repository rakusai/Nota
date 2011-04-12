/*
 * 
 * dlg_colorbox
 * 色選択ダイアログ
 * 
 */
 
 //256色選択パレット
pDlg = this;

DlgBack.useHandCursor = false;
DlgBack.onPress = function(){
	
};

DlgBack.onRollOver = function(){
	//通常のカーソルに戻せ！
	showMyCursor(false);	
};


if (MyLang == "en"){
	dlg_message = "Color : select favorite color.";
	
}

var WH = 14;//色選択の■の大きさ
var MG = 6.5;//縦、横のマージン
createEmptyMovieClip("colorptsel",100);
createEmptyMovieClip("colorptover",99);


//カラーパレットセット
var cur_palette = 0;

PaletteList = new Array();
ColorList = new Array();
setDefaultPalette();
changePalette(cur_palette);

btnBack.onPress = function(){
	//前のパレット
	cur_palette--;
	if (cur_palette < 0){
		cur_palette = PaletteList.length-1;
	}
	changePalette(cur_palette);
}

btnNext.onPress = function(){
	//次のパレット
	cur_palette++;
	if (cur_palette > PaletteList.length-1){
		cur_palette = 0;
	}	
	changePalette(cur_palette);
	
}

//カラーセットをサーバーから読み込む
function loadColorSet(){

}



//デフォルトパレットをセット
function setDefaultPalette(){
	
	var obj = new Object();
	obj.name = "NOTA 標準";
	obj.vlength = 7;
	obj.hlength = 12;
	
	//1.白黒
	var i=0;
	for(var c=0;c<7;c++){
		if (c == 6)	var g = "FF";
		else		var g = getS(240*c/6);
		rgb = "" + g + g + g;
		ColorList.push(rgb);
		i++;
	}
	Hlist = new Array(0,22,40,57,80,110,130+5,160+5,180,200,220);//色合い
	Llist = new Array(45,70,95,115,160,190,220);//明るさ
	Slist = new Array(185,185,185,200,200,200,200);//鮮やかさ
	
	//黄色のための鮮やかさ
	LlistY = new Array(45,70,95,120,170,195,220);//明るさ
	SlistY = new Array(220,220,230,240,240,240,240);//鮮やかさ
	
	//2.カラー
	for(var r=0;r<11;r++){
		for(var g=0;g<7;g++){
			if (r == 1){ //オレンジ
				rgb = "" + HLStoRGB(Hlist[r],Llist[g],SlistY[g]);//色合い,明るさ,濃度
			}else if (r == 2){ //黄色
				rgb = "" + HLStoRGB(Hlist[r],LlistY[g],SlistY[g]);//色合い,明るさ,濃度
			}else {
				rgb = "" + HLStoRGB(Hlist[r],Llist[g],Slist[g]);//色合い,明るさ,濃度
			}
			ColorList.push(rgb);
			i++;
		}
	}	
	obj.colorset = ColorList.join(',');
	
	PaletteList.push(obj);
	
	
}


//カラーパレットの選択と変更
function changePalette(indx){
	
	var obj = PaletteList[indx];	
	//色を分解
	ColorList = new Array();
	var orglist = obj.colorset.split(",");
	for (var i=0;i<orglist.length;i++) {
		if (orglist[i].substr(0,2) != "//"){
	  		ColorList.push(orglist[i]);
		}
	}
	//矩形はどうするか？
	hlength = obj.hlength;
	vlength = obj.vlength;
	//数によって、大きさを変える
	WH = 168/hlength;
	colorptover._visible = false;
	colorptover.clear();
	colorptover.lineStyle(2,"0xFFFFFF",100);
	colorptover.moveTo(0, 0);
	colorptover.lineTo(0+WH, 0);
	colorptover.lineTo(0+WH, 0+WH);
	colorptover.lineTo(0, 0+WH);
	colorptover.lineTo(0, 0);
	colorptsel.clear();
	colorptsel.lineStyle(2,"0x000000",100);
	colorptsel.moveTo(0, 0);
	colorptsel.lineTo(0+WH, 0);
	colorptsel.lineTo(0+WH, 0+WH);
	colorptsel.lineTo(0, 0+WH);
	colorptsel.lineTo(0, 0);
	//パレット名更新
	dlg_palette = obj.name;
	//色を塗る
	paintColor();
	//色を選択
	selectColor();
}


//色を塗る2
function paintColor(){
	colorbg.clear();
	var i=0;
	for(var h=0;h<hlength;h++){
		for(var v=0;v<vlength;v++){
			//色を塗る
			if (ColorList[i] != undefined){
				var x = h*WH;
				var y = v*WH;
				var rgb = "0x" + ColorList[i];
				colorbg.beginFill(rgb);
				colorbg.moveTo(x, y);
				colorbg.lineTo(x+WH, y);
				colorbg.lineTo(x+WH, y+WH);
				colorbg.lineTo(x, y+WH);
				colorbg.lineTo(x, y);
				colorbg.endFill();
				i++;
			}
		}
	}
}

colorbg.onRollOver = function(){

}
colorbg.onRollOut = function(){
	
	colorptover._visible = false;
	
}

colorbg.onMouseMove = function(){
	//色の上を移動
	var x = this._xmouse;
	var y = this._ymouse;
	
	
	//座標から、インデックスへ変換	
	var xi = Math.floor(x / WH);
	var yi = Math.floor(y / WH);
	var indx = xi*vlength + yi;
	if (indx >= 0 && indx < ColorList.length && 
		xi >= 0 && xi < hlength && yi >= 0 && yi < vlength)
	{
		colorptover._x = MG + Math.floor(x / WH) * WH;
		colorptover._y = MG + Math.floor(y / WH) * WH;
		colorptover._visible = true;
	}
}

colorbg.onPress = function(){
	//ボタンが押された
	
	var x = this._xmouse;
	var y = this._ymouse;
	
	//座標から、インデックスへ変換	
	var xi = Math.floor(x / WH);
	var yi = Math.floor(y / WH);
	var indx = xi*vlength + yi;
	if (indx >= 0 && indx < ColorList.length){
		var rgb = "0x" + ColorList[indx];
		_root.minitool.onSetColor(rgb);
		selectColor(rgb);
	}

}

function selectColor(mycolor){
	//現在選択中のカラーを選択
	if (mycolor == undefined){
		mycolor = myoldcolor;
	}
	colorptsel._visible = false;
	for (var i=0;i<ColorList.length;i++){
		if (Number("0x" + ColorList[i]) == Number(mycolor)){
			var xi = Math.floor(i/vlength);
			var yi = Math.floor(i%vlength);
			
			colorptsel._x = MG + xi * WH;
			colorptsel._y = MG + yi * WH;
			colorptsel._visible = true;
		}
	}
	myoldcolor = mycolor;
};




