/*
 * 
 * common
 * グローバル関数，定数を定義
 * 
 */

/////////////////////////////////////////////
//初期化
/////////////////////////////////////////////

//言語の選択
_global.MyLang = lang;
//NOTAのバージョン
_global.MyVersion = ver;

//ツールバーの読み込み
toolbar_name = toolbar;
delete toolbar;//Toolbarという名前がFlashVars変数とかさなるので消す。

_global.MT = 48;	//ツールバーの高さ
createEmptyMovieClip("Toolbar",1000);
if (toolbar_name != undefined){
	Toolbar.loadMovie("./toolbars/" + toolbar_name + ".swf");	
}else{
	_global.MT = 0;
}


if (toolh != undefined){
	_global.MT = toolh;//ツールバーの高さ
}


/////////////////////////////////////////////
//定義されたMovieClipを管理する配列
/////////////////////////////////////////////
_global.PluginList = new Array();


/////////////////////////////////////////////
//ツールバーのクラスを定義
/////////////////////////////////////////////

_global.NotaTool = function(theReceiver) {
	//コンストラクタ
	_global.MyToolbar = theReceiver;
	this.receiver = theReceiver;
	for (var i=0;i<PluginList.length;i++){
		if (PluginList[i] == theReceiver){
			return;
		}
	}
	PluginList.push(theReceiver);
}

//////////////////////////////////////
//コマンド実行

//コマンド名を送る
NotaTool.prototype.command = function(cname){
	var ok = true;
	switch (cname){
	case "zoomIn":
		_root.ZoomIn();
		break;
	case "zoomOut":		
		_root.ZoomOut();
		break;
	case "print":		
		_root.printPage();
		break;
	case "newPage":
		_root.newPage();
		break;
	case "copyPage":
		_root.copyPage();
		break;
	case "deletePage":
		_root.deletePage();
		break;
	case "lockPage":
		_root.dateditPage();
		break;
	case "startEdit":
		_root.startEdit();
		break;
	case "stopEdit":		
		_root.stopEdit();
		break;
	case "selectView":
		ok = _root.Main.setToolOption("view");
		break;
	case "selectPen":
		ok = _root.Main.setToolOption("pen");
		break;
	case "selectEraser":
		ok = _root.Main.setToolOption("eraser");
		break;
	case "selectShape":
		ok = _root.Main.setToolOption("shape");
		break;
	case "selectText":
		ok = _root.Main.setToolOption("text");
		break;	
	case "undo":
		ok = _root.Main.undoFlag();
		break;
	case "redo":		
		ok = _root.Main.undoFlag(true);
		break;
	}
	
	return ok;
}

NotaTool.prototype.getLang = function(){

	if (MyLang == undefined){
		return "ja";
	}
	return MyLang;
}

NotaTool.prototype.setToolHeight = function(height,width){
	//ツールバーの高さを設定
	//ロード時に通知が来ることが前提
	_global.MT = height;
	_root.minitool._y = MT;	
	
	if (width != undefined){
		_root.minitool._x = width;	
		
	}
	
}

//-------------------------------------------------------//
//plugin クラスの定義
//-------------------------------------------------------//
_global.NotaAPI = function(theReceiver) {
	//コンストラクタ
	//プラグインとして指定されたもの以外は認めず
	this.registerd = true;
	if (theReceiver._name != "plugin"){
		this.registerd = false;
	}
	
	this.receiver = theReceiver;
	for (var i=0;i<PluginList.length;i++){
		if (PluginList[i] == theReceiver){
			return;
		}
	}
	PluginList.push(theReceiver);
}

//////////////////////////////////////
//情報取得

//オブジェクトIDを取得
NotaAPI.prototype.getObjectID = function(){
	if (HtmlMode == true){
		return ObjectID;
	}else{
		if (this.registerd){
			return this.receiver._parent._name;
		}else{
			return this.receiver._parent._parent._name;
		}
	}
}
//オブジェクトの属性を取得
NotaAPI.prototype.getObjectProperty = function(){
	if (HtmlMode == true){
		return undefined; //HTMLモードでは無効
	}else{
		var num = this.getObjectID();
		return m_DataList[num];
	}	
}
//ページのIDを取得
NotaAPI.prototype.getPageID = function(){
	return MyPage;
}
//ページが凍結されているか取得
NotaAPI.prototype.getPageLock = function(){
	return (PageLock == true);
}
//現在のページの番号を取得
NotaAPI.prototype.getPageWidth = function(){
	return _root.Main.page_num;
}
//ページの総数を取得
NotaAPI.prototype.getPageCount = function(){
	return _root.Main.page_cnt;
}
//ページの表示倍率を取得
NotaAPI.prototype.getPageScale = function(){
	var scale = _root.Main.curscale;
	if (!scale){
		return 100;
	}
	return scale;
}
//ログインユーザーIDを取得
NotaAPI.prototype.getUserID = function(){
	return MyID; //HTML・閲覧モードではundefined
}
//ログインユーザーの権限を取得
NotaAPI.prototype.getUserPower = function(){
	return MyPower;	//HTML・閲覧モードではundefined
}
//編集モードか否かを取得
NotaAPI.prototype.getEditMode = function(){
	return (PageEdit == true);
}
//HTMLモードか否かを取得
NotaAPI.prototype.getHtmlMode = function(){
	return (HtmlMode == true);
}
//表示言語を取得
NotaAPI.prototype.getLang = function(){
	return MyLang;
}
//NOTAのバージョンを取得
NotaAPI.prototype.getNotaVersion = function(){
	return MyVersion;
}

//////////////////////////////////////
//選択と移動
NotaAPI.prototype.selectObject = function(){
	//選択
	resetFocus();
	_root.Main.moveFlagFocus(this.getObjectID());

};

NotaAPI.prototype.SetSelection = function() { selectObject(); };

NotaAPI.prototype.resizeObject = function(){
	//移動
	_root.Main.FlagSelect.moveResizeTab();
	
};

NotaAPI.prototype.moveResizeTab = function() { resizeObject(); };


//////////////////////////////////////
//プラグイン間の連係
NotaAPI.prototype.findObject = function(plugin,index){
	//検索
	if (!this.registerd){
		if (MyLang == "en"){
			MessageBox("Only supplied plugins are allowed to use findObject function.");
		}else{
			MessageBox("findObject関数は、プラグインとして追加したFlashでないと使えません。");
		}
		return null;
	}
	var hitcnt = 0;
	for (var i=0;i<m_DataList.length;i++){
		var obj = m_DataList[i];
		if (obj.tool == "PLUGIN" && obj.del != 1){
			if (obj.plugin == plugin){
				if (hitcnt == index || index == undefined){
					var fobject = eval("_root.Main." + i).fobject;
					return fobject;
				}
				hitcnt++;
			}
		}
	}	
	
};


//-------------------------------------------------------//
//plugin関数 サーバー通信
//-------------------------------------------------------//

//////////////////////////////////////
//読み込み
NotaAPI.prototype.loadData = function(){

	//サーバーからデータを取得
	if (!this.registerd){
		if (MyLang == "en"){
			MessageBox("Only supplied plugins are allowed to use loadData function.");
		}else{
			MessageBox("loadData関数は、プラグインとして追加したFlashでないと使えません。");
		}
		return false;
	}		
	this.myLoadVars = new LoadVars();
	this.myLoadVars.onLoad = this.onInnerLoadData;
	this.myLoadVars.receiver = this.receiver;
	var myDate = new Date;
	this.myLoadVars.load(SERVER + "plugin.cgi?action=read&fname=" + this.getObjectProperty().fname + 
					"&page=" + this.getPageID() + "&date=" + myDate.getTime());

	return true;
}

NotaAPI.prototype.onInnerLoadData = function(success){
	//ロード完了
	var resultObj = null;

	if (success && this.res != "ERR"){
		resultObj = new Object();
		//IDを列挙してデータを入れる
		resultObj.idlist = new Array();
		var oldid = "";
		for (propname in this){
			//ID配列に収納
			var s = propname.indexOf(".");
			if (s >= 0){
				var id = propname.substr(0,s);
				if (id != "head" && oldid != id){
					resultObj.idlist.push(id);
					oldid = id;	
				}
			}
			//データを収納
			resultObj[propname] = this[propname];
		}
		resultObj.idlist.reverse();
	}
	//プラグインに通知
	this.receiver.onLoadData(resultObj);
	delete this;
}


//////////////////////////////////////
//書き込み
NotaAPI.prototype.writeData = function(newobj){
	//サーバーにデータを送信
	if (!this.registerd){
		if (MyLang == "en"){
			MessageBox("Only supplied plugins are allowed to use writeData function.");
		}else{
			MessageBox("writeData関数は、プラグインとして追加したFlashでないと使えません。");
		}
		return false;
	}
	this.myWriteVars = new LoadVars();
	this.myWriteVars.action = "write";//保存お願い
	this.myWriteVars.page = this.getPageID();
	this.myWriteVars.fname =  this.getObjectProperty().fname;
	
	//データを入れる
	for (propname in newobj){
		if (propname.indexOf(".") >= 0){
			this.myWriteVars[propname] = newobj[propname];
		}
	}
	
	this.ResVars = new LoadVars;
	this.ResVars.Vars = this.myWriteVars;
	this.ResVars.NotaAPI = this;
	this.ResVars.trycnt = 0;
	this.ResVars.onLoad = this.onInnerWriteData;
	this.ResVars.receiver = this.receiver;
	
	_root.statusbar.accessFlag.gotoAndPlay("start");
	this.WriteAccess = true; //書き込み中
	
	this.myWriteVars.sendAndLoad("plugin.cgi",this.ResVars);
	
	return true;

}

NotaAPI.prototype.onInnerWriteData = function(success){
	//セーブ完了
	
	_root.statusbar.accessFlag.gotoAndStop("stop");
	this.NotaAPI.WriteAccess = false;
	
	if (!success || this.res == "ERR"){
		//書き込み失敗！
		//3度だけ試してみる！！
		if (this.trycnt <= 3){
			this.trycnt++;
			Vars = this.Vars;
			_root.statusbar.accessFlag.gotoAndPlay("start");
			this.NotaAPI.WriteAccess = true;
			Vars.sendAndLoad("plugin.cgi",this);
			return;
			
		}else{
			ErrorMes("プラグイン：書き込みに失敗しました。");
		}
	}
	//プラグインに通知
	var resultObj = null;
	if (success && ResultVars.re != "ERR"){
		resultObj = new Object();
		//プロパティを列挙してデータを入れる
		for (propname in this){
			//データを収納
			resultObj[propname] = this[propname];
		}
	}
	this.receiver.onWriteData(resultObj);	
	delete this;

};	


/////////////////////////////////////////////
//時間の処理
/////////////////////////////////////////////

function getMT(tm){
	if (tm < 10)
		return "0" + tm;
	
	return "" + tm;
};

_global.getNewPageNum = function(){
	//新規作成するページの番号を発行
	myDate = new Date;//日付を新規に作る
	var page =  myDate.getFullYear()+
				getMT(myDate.getMonth()+1)+
				getMT(myDate.getDate())+
				getMT(myDate.getHours())+
				getMT(myDate.getMinutes())+
				getMT(myDate.getSeconds());
	
	return page;
};

_global.getCurTime = function(){
	//新規作成するページの番号を発行
	myDate = new Date;//日付を新規に作る
	var page =  myDate.getFullYear()+"/"+
				getMT(myDate.getMonth()+1)+"/"+
				getMT(myDate.getDate())+" "+
				getMT(myDate.getHours())+":"+
				getMT(myDate.getMinutes());
	
	return page;
};


/////////////////////////////////////////////
//文字列処理
/////////////////////////////////////////////
_global.Replace = function(str,bfr,aft){
	//str内のbfrをaftに置換する
	if (str == undefined){
		return str;
	}
	var st=0,re=0;
	var res = "";
	while (re >= 0){
		re = str.indexOf(bfr,st);	
		if (re != undefined && re >= 0){
			res += str.substr(st,re-st);
			res += aft;
			st = re + bfr.length;
		}
	}
	res += str.substr(st);
	
	//置換結果を返す
	return res;
};

/////////////////////////////////////////////
//カラー変換処理
/////////////////////////////////////////////

//HLSをRGBに変換
HLSMAX   =240;/*RANGE*/ /* H,L, and S vary over 0-HLSMAX */
RGBMAX   =255;   /* R,G, and B vary over 0-RGBMAX */
                        /* HLSMAX BEST IF DIVISIBLE BY 6 */
                        /* RGBMAX, HLSMAX must each fit in a byte. */
/* Hue is undefined if Saturation is 0 (grey-scale) */
/* This value determines where the Hue scrollbar is */
/* initially set for achromatic colors */

_global.HLStoRGB = function(hue,lum,sat)
{ 

   var R,G,B;                /* RGB component values */
   var Magic1,Magic2;       /* calculated magic numbers (really!) */

   if (sat == 0) {            /* achromatic case */
      R=G=B=Math.floor((lum*RGBMAX)/HLSMAX);
   }
   else  
   {                    /* chromatic case */
      /* set up magic numbers */
      if (lum <= (HLSMAX/2))
         Magic2 = Math.floor((lum*(HLSMAX + sat) + (HLSMAX/2))/HLSMAX);
      else
         Magic2 = lum + sat - Math.floor(((lum*sat) + (HLSMAX/2))/HLSMAX);
      Magic1 = 2*lum-Magic2;

      /* get RGB, change units from HLSMAX to RGBMAX */
      R = Math.floor((HueToRGB(Magic1,Magic2,hue+(HLSMAX/3))*RGBMAX + (HLSMAX/2))/HLSMAX); 
      G = Math.floor((HueToRGB(Magic1,Magic2,hue)*RGBMAX + (HLSMAX/2)) / HLSMAX);
      B = Math.floor((HueToRGB(Magic1,Magic2,hue-(HLSMAX/3))*RGBMAX + (HLSMAX/2))/HLSMAX); 
   }
   
   //２桁の16進数文字列としてRGBを返す
   return "" + getS(R) + getS(G) + getS(B);

};

_global.getS = function(tm){
	var test = tm.toString(16);
	if (tm == 0){
		return "00";
		
	}else{
		if (test.length < 2)
			return "0" + test;
	}
	return test.toUpperCase();
};

//Private
_global.HueToRGB =function(n1,n2,hue) 
{ 

   /* range check: note values passed add/subtract thirds of range */
   if (hue < 0)
      hue += HLSMAX;

   if (hue > HLSMAX)
      hue -= HLSMAX;

   /* return r,g, or b value from this tridrant */
   if (hue < (HLSMAX/6))
      return ( n1 + Math.floor(((n2-n1)*hue+(HLSMAX/12))/(HLSMAX/6)) );
   if (hue < (HLSMAX/2))
      return ( n2 );
   if (hue < ((HLSMAX*2)/3))
      return ( n1 + Math.floor(((n2-n1)*(((HLSMAX*2)/3)-hue)+(HLSMAX/12))/(HLSMAX/6))); 
   else
      return ( n1 );
};
