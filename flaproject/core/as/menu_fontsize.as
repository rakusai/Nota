/*
 * 
 * dlg_fontsize
 * フォントサイズ変更ダイアログ
 * 
 */

DlgBack.useHandCursor = false;
DlgBack.onPress = function(){
	
};

if (MyLang == "en"){
	dlg_message = "Font\nSize";
	
}

//フォントサイズリストの初期化
slist = new Array(10,12,14,16,18,24,30,36,48,60,72,96,120);

sizeList.removeAll();
sizeList.vScrollPolicy = "off";

for(var i=0;i<slist.length;i++){
	sizeList.addItem(slist[i]);
}

listenerObject = new Object();
listenerObject.change = function(eventObject){

	//選択がクリックされた
	var indx = sizeList.selectedIndex;//Math.floor(((_ymouse)/LH));
	if (indx == null)
		return;
	
	//サイズ設定
	var name = this._name;
	var fontsize = slist[indx];
	var fm = new TextFormat();
	fm.size = fontsize;


	_parent.setFormat(fm);
	
	
	//文字枠を変更
	_root.Main.FlagSelect.moveResizeTab();  
};
sizeList.addEventListener("change", listenerObject)

/*

function onSizeBtnRelease(){
	//サイズ設定
	var name = this._name;
	var nsize = name.substr(1);
	var fm = new TextFormat();
	fm.size = nsize;


	_parent.setFormat(fm);
	
	
	//文字枠を変更
	_root.Main.FlagSelect.moveResizeTab();
};
*/
function selectSize(fontsize){
	//リストを選択
	var indx;
	for(var i=0;i<slist.length;i++){
		if (fontsize == slist[i]){
			indx = i;
			break;
		}
	}
	//選択
	sizeList.selectedIndex = indx;

	//表示場所を調整
	if (indx < sizeList.vPosition || 
		sizeList.vPosition + sizeList.rowCount < indx)
	{
		var vp = indx - int(sizeList.rowCount/2);
		if (vp < 0){
			vp = 0;
		}
		sizeList.vPosition = vp;
	}
}

scrollUp.onRollOver = function(){
	
	//タイマーをスタートさせよう
	clearInterval(sid);
	sid = setInterval(scrollList,240,false);
	
}

scrollUp.onRollOut = function(){

	clearInterval(sid);

}
function scrollList(down){
	if (down){
		sizeList.vPosition++;
	}else{
		sizeList.vPosition--;
	}
}


scrollDown.onRollOver = function(){
	//タイマーをスタートさせよう
	clearInterval(sid);
	sid = setInterval(scrollList,240,true);
	
}

scrollDown.onRollUp = function(){
	clearInterval(sid);
	
}