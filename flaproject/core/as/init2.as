/*
 * 
 * init2
 * グローバルの第２フレーム
 * 
 */

stop();
//設置サーバー取得
//System.useCodepage = true;
//Macか
_global.isMacOS = false;

back._x = 0;
back._y = 0;
back._width = 3000;
back._height = 2000;
back._alpha = 0;


//ページ番号
_global.MyPage = '';
//ファイルが存在するパス
_global.SDIR      = sdir;
_global.SERVER = "";
_global.IMAGESERVER = "";

//扉を中央に表示
_global.PaperW = 1000;
_global.PageH = 1414;
_global.PaperH = PageH;

_global.MyID = "guest";
_global.PageEdit = null;
_global.PageLock = null;
if (editmode == "true"){
	setEditMode(true,"","");
}

//上下マージン
//_global.MT = 50;	//ツールバーの高さ
_global.ML = 0;
_global.MAX_SC = 100;//最大スケール
_global.MIN_SC = 95;//最小スケール

//オブジェクトの初期表示

Main._visible = false;
Pen._visible = false;
Pen.swapDepths(110050);
minitool._visible = false;
minitool._y = MT;


//最初のページ
_global.MyPage = page;

//最初のページ
_global.MyScreen = screen;

//参加条件と公開レベル
_global.MyAnonymous = anonymous;

//音を読み込む
sdSHU = new Sound;
sdSHU.attachSound("SHU.wav");
sdPAGE = new Sound;
sdPAGE.attachSound("se-page2.wav");
sdKON = new Sound;
sdKON.attachSound("KON.wav");
sdKASHA = new Sound;
sdKASHA.attachSound("KASHA.wav");
sdCOIN = new Sound;
sdCOIN.attachSound("be-coin.wav");	
sdPOU = new Sound;
sdPOU.attachSound("POU.wav");	
/*
//コンテキストメニュー
var my_cm:ContextMenu = new ContextMenu();
if (my_cm){
	my_cm.hideBuiltInItems();
//	my_cm.customItems.push(new ContextMenuItem("大きく",ZoomIn));
//	my_cm.customItems.push(new ContextMenuItem("小さく",ZoomOut));
//	my_cm.customItems.push(new ContextMenuItem("印刷...",printPage,true));
	my_cm.customItems.push(new ContextMenuItem("ヘルプ...",showHelp));
	_root.menu = my_cm;
}

/////////////////////////////////////////////
//ヘルプ表示
/////////////////////////////////////////////

function showHelp(){
	getURL("javascript:showHelp();");
	
//	getURL("http://nota.jp/help/","_blank");
}
*/
/////////////////////////////////////////////
//編集開始・終了
/////////////////////////////////////////////

function startEdit(commandafteredit){

	commandAfterEdit = commandafteredit;

	
	if (MyPower != undefined){
		_root.DialogBox._visible = false;
	}
	
	_root.DialogBox.gotoAndStop("edit");
	_root.DialogBox.showDlg();
	
	//もし、すでにログインしているならば、
	//ダイアログを出さずにそのままログインする
	if (MyPower != undefined){
		_root.DialogBox.doEdit();
		_root.DialogBox._visible = true;
	}

};



function stopEdit(){
	//閲覧へ

//	//ツール選択
//	for (var i=0;i<PluginList.length;i++) {
//		PluginList[i].onSelectTool("editStop");		//ツールの表示を更新
//	}	

	//閲覧モード
	if (PageEdit != false){
		_root.setEditMode(false);
	}

	//Tab更新
//	if (MyScreen == 1){
		//全画面表示ならupdateを再読込する
//		getURL("javascript:location.reload();","upload");
//	}else{
		getURL("javascript:setEditMode('false');");
//	}
	/*
	//第3者閲覧禁止なら、データを消す
	if (MyAnonymous == "none"){
		_root.Main.clearMapData();
		_root.startEdit();
	}	
	*/
	/*
	//閲覧モードへ（この処理はなくせないか？）
	myViewVars = new LoadVars();
	myViewVars.action = "certify";
	myViewVars.mode = "view";
	myViewVars.onLoad = onAccountViewLoad;
	
	myViewVars.sendAndLoad(SERVER + "account.cgi",myViewVars);

*/
};

function onAccountViewLoad(success){
	//ツール選択
	
	if (!success || myViewVars.res == "ERR"){
		//ページが見つからない
		if (MyLang == "en"){
			ErrorMes("Logout failure.");
		}else{
			ErrorMes("閲覧モードに入れません。");
		}
		return;
	}

	
	//閲覧モード
	if (PageEdit != false){
		_root.setEditMode(false);
	}
	
	//第3者閲覧禁止なら、データを消す
	if (myViewVars.anonymous == "none"){
		_root.Main.clearMapData();
		_root.startEdit();
	}	

	//Tab更新
//	if (MyScreen == 1){
		//全画面表示ならupdateを再読込する
//		getURL("javascript:location.reload();","upload");
		
//	}else{
		getURL("javascript:setEditMode('false');");

//	}
};


function setEditMode(edit,user,power){
	
	var authortext = "";
	var sound = false;
	if (edit){
		//編集開始
		_global.MyID = user;
		_global.MyPower = power;
		_root.minitool._visible = true;
		authortext = MyID + "(" + MyPower + ")";
		//まずはペンモードに
		_root.Main.setToolOption("view",false);
		//選択解除
		resetFocus();
		//切り替え効果音
		sound = (PageEdit == false);
	}else{
		//編集終了
		if (_global.PageEdit == true){
			//選択
			_root.Main.moveFlagFocus(-1);
			//ペンを消す
			_root.Main.setToolOption("view",false);
		}
		_root.minitool._visible = false;
		//切り替え効果音
		sound = (PageEdit == true);
	}
	if (sound){
		//切り替え効果音
		playSound("PAGE");
	}
	//ツールバーの更新
	if (MyToolbar){
		for (var i=0;i<PluginList.length;i++) {
			PluginList[i].onSetEditMode(edit,MyID,MyPower,sound);
		}
	}else{
		//Toolbarがロードされていなければ、できるまでTimerで待つ
		toolbareditid = setInterval(setToolbarEditMode,100,edit,MyID,MyPower,sound);
	}
	
	//編集モードの更新
	_global.PageEdit = edit;
	
	if (PageEdit == true){
		switch(commandAfterEdit){
		case "newpage":
			newPage();
			break;
		case "copypage":
			copyPage();
			break;
		case "deletepage":
			deletePage();
		}
		commandAfterEdit = "";
	}
};

function setToolbarEditMode(edit,id,power,sound){
	
	if (MyToolbar){
		for (var i=0;i<PluginList.length;i++) {
			PluginList[i].onSetEditMode(edit,id,power,sound);
		}
		clearInterval(toolbareditid);
		toolbareditid = null;
	}
}



/////////////////////////////////////////////
//カーソル表示
/////////////////////////////////////////////
_global.showMyCursor = function(isshow, type, param) {
	if (isshow != 2){
		_root.Pen._visible = isshow;
	}
	if (isshow) {
		//オリジナルカーソル
		if (isshow != 2){
			Mouse.hide();
		}
		if (type != null) {
			_root.Pen.gotoAndStop(type);
		}
	
		//ペン先の色を決定
		if (type == "pen"){
			var myColor  = new Color(_root.Pen.penink);
			myColor.setRGB(param);
			//ペンの太さの色
			_root.minitool.strokebox.setPenColor(param);
		}
		if (type == "shape"){
			var myColor  = new Color(_root.Pen.shape);
			myColor.setRGB(param);
			
			//ペンの太さの色
			_root.minitool.toolbtntab.setColor();
			//貼り付ける図形の形状
			_root.Pen.shape.gotoAndStop(_root.Main.curshape);
			_root.Pen.shape._x = -_root.Pen.shape._width/2;
			_root.Pen.shape._y = -_root.Pen.shape._height/2;
			_root.Pen.shapebase._width = _root.Pen.shape._width*1.52;
			_root.Pen.shapebase._y = _root.Pen.shape._height/2+3;
			_root.Pen.shapebase._x = -_root.Pen.shapebase._width/2;
		}
	}else{
		//通常カーソル
		Mouse.show();
		Pen._rotation = 0;
	}
};

this.onMouseMove = function() {
	//カーソルをあわせる
	Pen._x = _xmouse;
	Pen._y = _ymouse;
	if (_root.Pen._visible){
		updateAfterEvent();
	}
};


/////////////////////////////////////////////
//エラーメッセージの表示
/////////////////////////////////////////////
_global.MessageBox = function(string,sound){
	//エイリアス
	ErrorMes(string,sound);
}
_global.ErrorMes = function(string,sound){

	//約1秒後に消える
	AlertBox.gotoAndStop("message");
	AlertBox.dlg_message_text = string;
	AlertBox.showDlg();

	
	//サウンド
	if (sound != false){
		playSound("COIN");
	}
		
};
_global.getTm = function(){

	//現在時刻システム秒で返す
	myDate = new Date;
	return Math.floor(myDate.getTime());

};

/////////////////////////////////////////////
//フォーカスのリセット
/////////////////////////////////////////////
_global.resetFocus = function(){

	Selection.setFocus("_root.statusbar.commandtxt");
	Selection.setFocus("_root.statusbar.commandtxt");

}
/////////////////////////////////////////////
//音を鳴らす
/////////////////////////////////////////////
_global.playSound = function(sound){

	switch (sound){
	case "SHU":
		sdSHU.start();
		break;
	case "PAGE":
		sdPAGE.start();
		break;		
	case "KON":
		sdKON.start();
		break;	
	case "KASHA":
		sdKASHA.start();
		break;	
	case "COIN":
		sdCOIN.start();
		break;			
	case "POU":
		sdPOU.start();
		break;			
	}
}


/////////////////////////////////////////////
//背景クリップ
/////////////////////////////////////////////

//地図移動
back.useHandCursor = false;
back.onPress = function(){ Main.backboard.onPress(); };
back.onRelease = function(){ Main.backboard.onRelease(); };
back.onReleaseOutside = back.onRelease;


/////////////////////////////////////////////
//拡大・縮小表示
/////////////////////////////////////////////


function getRealScale(){
	
//	return 100;

	var stageW = Stage.width-ML-17;
	var stageH = Stage.height-MT-17;
	var maxsc = (stageW)/PaperW*100;
	if (maxsc < MIN_SC) maxsc = MIN_SC;
	if (maxsc > MAX_SC) maxsc = MAX_SC;
	
	return maxsc;
	
};

var scaleset = new Array(40,60,80,100,130,170,250);
function ZoomIn() {
	//拡大
	//全体の大きさ
	var stageW = Stage.width-ML-17;
	var stageH = Stage.height-MT-17;
	var maxsc = getRealScale();
	
	var dd = Main._xscale;
	if (dd >= scaleset[scaleset.length-1]) {
		if (MyLang == "en"){
			ErrorMes("You can't zoom in anymore.");
		}else{
			ErrorMes("これ以上、大きく表示できません。");
		}
		return;
	}
	for (var i=0;i<scaleset.length;i++){
		if (dd < scaleset[i] -10){
			dd = scaleset[i];
			break;
		}
	}

	_root.Main.changeMapScale(dd);

};

function ZoomOut() {
	//縮小
	//全体の大きさ
	var stageW = Stage.width-ML-17;
	var stageH = Stage.height-MT-17;

	var minsc = (stageH)/PageH*100;
	if (minsc > 100){
		minsc = 100;
	}
//	var maxsc = (stageW)/PaperW*100;
	var dd = Main._xscale;
	if (dd <= minsc) {
		if (MyLang == "en"){
			ErrorMes("You can't zoom out anymore.");
		}else{
			ErrorMes("これ以上、小さく表示できません。");
		}
		return;
	}

	for (var i=0;i<scaleset.length;i++){
		if (dd <= scaleset[i]){
			dd = scaleset[i-1];
			break;
		}
	}

	if (dd < minsc+10) {
		dd = minsc;
	}
	
	_root.Main.changeMapScale(dd);

};


function ZoomAll(){
	//全体表示
	var stageW = Stage.width-ML-17;
	var stageH = Stage.height-MT-17;
	var minsc = (stageH)/PageH*100;
	_root.Main.changeMapScale(minsc);
};

function ZoomReal(){
	//実寸表示（全幅表示）
	var stageW = Stage.width-ML-17;
	var stageH = Stage.height-MT-17;
	var maxsc = getRealScale();
//	if (maxsc > 100)
//		maxsc = 100;
	_root.Main.changeMapScale(maxsc);

};



/////////////////////////////////////////////
//ページ作成・削除・属性変更・印刷
/////////////////////////////////////////////

function updateSidebar(){
	//一覧の表示を更新する
	//タイトル変更・新規ページへリンク作成・属性変更時に呼ばれる
	
	getURL("javascript:clickTab('list',false,true);");
//	getURL("javascript:window.list.loadBox('list','true');");

//	tab_lc = new LocalConnection();
//	tab_lc.send("tab" + SDIR + MyPage,"updateList");
}


function newPage(afterCreateAccount){
	//ツールボタンからページの新規作成
	
	if (PageEdit != true){
		//編集モードでなければ、まず編集モードへ
		startEdit("newpage");
		return;
	}

	//まずはペンモードに
	if (_root.Main.m_toolname != "view"){
		_root.Main.setToolOption("view",false);
	}
	
	//ページを作成
	createNewPage("home","",onNewPage);

/*	
	//次にテンプレートの作成
	_root.masterAfterCreateAccount = afterCreateAccount;
	_root.newPageAfterMaster = true;
	DialogBox.gotoAndStop("master");
	DialogBox.showDlg();
*/	
}

function copyPage(afterCreateAccount){
	//ツールボタンからページの新規作成
	//現在のページのコピーページを作成
	
	if (PageEdit != true){
		//編集モードでなければ、まず編集モードへ
		startEdit("copypage");
		return;
	}

	//まずはペンモードに
	if (_root.Main.m_toolname != "view"){
		_root.Main.setToolOption("view",false);
	}
	
	//ページを作成
	createNewPage(MyPage,"Copy of " + MyPageTitle,onNewPage,"");

}


function createNewPage(masterpage,pagetitle,newevent,masterdir){
	//ページを作成
	if (pagetitle == "" || pagetitle == undefined){
		var jo;
		if (MyLang == "en"){
			jo = MyID + "'s New Page";
		}else{
			jo = MyID + "の新しい紙";
		}
		pagetitle = jo + "" +"(" + _root.getMT(myDate.getMonth()+1)+"/"+
		_root.getMT(myDate.getDate())+")";
	}
	
	if (MyLang == "en"){
		msg = "Now creating new Page...\nPlease wait a minute.";
	}else{
		msg = "新しいページを作成しています...\nしばらくお待ち下さい。";
	}
	MessageBox(msg,false);
	
	if (masterdir == undefined){
		masterdir = "master";
	}	
	var page = getNewPageNum();
	var myDate = new Date;//日付を新規に作る
	vars = new LoadVars();
	vars.action = "mkpage";
	vars.page = page;
	vars.master = masterpage;

	vars.masterdir = masterdir;
	vars.back = "home";
	vars.title = pagetitle;
	vars.onLoad = newevent;
	vars.sendAndLoad(SERVER + "write.cgi",vars);
}

function onNewPage(success){
	if (success && vars.res != "ERR"){
		//ページを開く
		var url = SERVER + "./?" + vars.page;
		if (MyScreen == 1){
			url += ".screen";
		}
		getURL(url);

	}else{
		//エラー
		switch (vars.errcode){
		case "capacity":
			//容量オーバー
			if (MyLang == "en"){
				ErrorMes("Data capacity is above the limit. you can't create new pages.");
			}else{
				ErrorMes("データ容量がいっぱいです。ページを作ることができません。");
			}
			break;
		default:
			//編集権限なし
			if (MyLang == "en"){
				ErrorMes("You have no authority to create new pages.");
			}else{
				ErrorMes("新規ページの作成に失敗しました。権限がありません。");
			}
			break;
		}
	}
}	

function deletePage(action){
	//ページの削除
	if (PageEdit != true){
		//編集モードでなければ、まず編集モードへ
		startEdit("deletepage");
		return;
	}
	
	//ダイアログを表示して確認を取る
	if (MyPage == "home"){
		//homeは削除できない！
		if (MyLang == "en"){
			ErrorMes("You can't delete top page.");//確認
		}else{
			ErrorMes("トップページは削除できません。");//確認
		}
		return;
	}
	if (!MyPage || MyPage < 0){
		//無効なページは削除できない！
		if (MyLang == "en"){
			ErrorMes("This page is unavailable.");//確認
		}else{
			ErrorMes("無効なページは削除できません。");//確認
		}
		return;
	}
	
	//まずはペンモードに
	if (_root.Main.m_toolname != "view"){
		_root.Main.setToolOption("view",false);
	}
	//選択
	_root.Main.moveFlagFocus(-1);
	//選択解除
	resetFocus();		
	//ダイアログ表示
	_root.DialogBox.gotoAndStop("delete");

};



function dateditPage(){
	//ページの編集属性変更
	//凍結か凍結解除か
	if (MyPower != "admin"){
		if (MyLang == "en"){
			ErrorMes("Only administrators can operate this command.");
		}else{
			ErrorMes("管理者以外はこの操作を実行できません。");
		}
		return;
	}	
//	var page = _root.List.cur_selid;

//	var page = MyPage;
//	if (page == undefined){
//		return;
//	}
//	vars = new LoadVars();
//	vars.action = "record";
//	vars.page = page;
	nextedit;	//どちらにするのか
	if (PageDatEdit == "admin")
		nextedit = "default";
	else
		nextedit = "admin";
//	vars["head:edit"] = nextedit;
	
	var obj = new Object;
	obj.id = 'head';
	obj.edit = nextedit;
	_root.Main.WriteMapData('head',null,obj);
	
	
};


function printPage(){
	//ページの印刷ダイアログの表示
	//まずはペンモードに
	if (_root.Main.m_toolname != "view"){
		_root.Main.setToolOption("view",false);
	}
	//選択
	_root.Main.moveFlagFocus(-1);
	//選択解除
	resetFocus();
		
	_root.DialogBox.gotoAndStop("print");
	
};

///////////////////////////////////////////////////////////////
//マスターページの適用
///////////////////////////////////////////////////////////////

function masterPage(masterid){
	//サイドバーからマスターページの選択
	if (PageEdit != true){
		//編集モードでなければ、エラー
		if (MyLang == "en"){
			ErrorMes("Not in Edit Mode.");
		}else{
			ErrorMes("編集モードではありません");
		}
		return;
	}	
	//まずはペンモードに
	if (_root.Main.m_toolname != "view"){
		_root.Main.setToolOption("view",false);
	}
//	_root.masterAfterCreateAccount = false;
//	_root.newPageAfterMaster = false;

	//ページを作成
	createNewPage(masterid,"",onNewPage);

/*

	DialogBox.gotoAndStop("master");
	DialogBox.showDlg(masterid);	
*/	
}
/*
function setMasterPage(masterpage){

	//マスターページの変更
	
	//権限をチェック
	SetMasterVars = new LoadVars();
	SetMasterVars.onLoad = onSetMasterPage;

	SetMasterVars.load(SERVER + "write.cgi?action=master&page="
				 + MyPage + "&master=" + masterpage);

};

function onSetMasterPage(success){

	if (!success || this.res == "ERR"){
		//書き込み失敗！
		if (MyLang == "en"){
			ErrorMes("Set template failure.");
		}else{
			ErrorMes("背景の変更に失敗しました。");
		}
		return;
	}
	
	//ページの更新
	_root.Main.updatePage();

}
*/
/////////////////////////////////////////////
//マウスイベント処理
/////////////////////////////////////////////
mouseListener = new Object();
mouseListener.onMouseWheel = function(delta) {
	if (ComboOpen == true || minitool.linklist._visible == true)
		return;
//	var p = new Object();
	var x = _root.Main._xmouse;
	var y = _root.Main._ymouse;
		
	if ( Key.isDown(Key.CONTROL)){
		dd = Main._xscale;
		
		if (delta > 0){
			//縮小
			var stageW = Stage.width-ML-17;
			var stageH = Stage.height-MT-17;
			var minsc = (stageH)/PaperH*100;
			dd *= 0.8;
			if (dd < minsc)
				dd = minsc;
			
			_root.Main.changeMapScale(dd,x,y,false);
		}else{
			//拡大
			dd *= 1.2;
			if (dd < scaleset[scaleset.length-1])
				_root.Main.changeMapScale(dd,x,y,false);
		}
		return;
	}
	
	if (_root.DialogBox._currentframe == 1){
		//ホイール
		if (delta > 0)
			ScrollV.moveUp(Math.abs(delta));
		else
			ScrollV.moveDown(Math.abs(delta));
	}
};

Mouse.addListener(mouseListener);


/////////////////////////////////////////////
//キーイベント処理
/////////////////////////////////////////////
keyListner = new Object();
keyListner.onKeyDown = function(){
	var dd = Main._xscale;
	var textboxsel = false;
	for (var i=0;i<m_SelList.length;i++){
		if (m_DataList[m_SelList[i].num].tool == "TEXT"){
			textboxsel = true;
			break;
		}
		
	}
	
	
	if ( Key.isDown(Key.CONTROL)){
		switch (Key.getCode()){
		case  Key.LEFT:
			var stageW = Stage.width-ML-17;
			var stageH = Stage.height-MT-17;
			var minsc = (stageH)/PaperH*100;
			dd *= 0.9;
			if (dd < minsc)
				dd = minsc;
			
			_root.Main.changeMapScale(dd,null,null,false);
			break;
		case Key.RIGHT:
			dd *= 1.1;
			if (dd < scaleset[scaleset.length-1])
				_root.Main.changeMapScale(dd,null,null,false);
			break;
		case Key.UP:
			//全幅表示
			ZoomReal();
			break;
		case Key.DOWN:
			//全体表示
			ZoomAll();
			break;
		}
		switch (Key.getAscii()){

		case 'x':
		case 'X':
			//Cut
//			if (noselection)
				_root.Main.cutFlag(true);
			break;
		case 67:
			//Copy
//			if (noselection)
				_root.Main.cutFlag(false);
			break;
		case 'V':
			//Paste
//			if (noselection)
				_root.Main.pasteFlag();
			break;
		}
	}else if (!textboxsel){
		//テキストボックスは選択されていない
		if (Selection.getFocus() == null || Selection.getFocus().indexOf("commandtxt") > 0){
			//カレットがなければ
			switch (Key.getCode()){
			case Key.PGUP:
				ScrollV.onePageScroll(false);
				break;
			case Key.PGDN:
				ScrollV.onePageScroll(true);		
				break;
			case Key.UP:
				ScrollV.moveUp();
				break;
			case Key.DOWN:
			case Key.SPACE:
				ScrollV.moveDown();
				break;			
			case Key.LEFT:
				ScrollH.moveUp();
				break;
			case Key.RIGHT:
				ScrollH.moveDown();
				break;		
			case Key.DELETEKEY:
				//オブジェクトの削除
				if (m_SelList.length > 0){
					_root.Main.deleteFlag();
				}
				break;		
			}
		}else if (DialogBox._currentframe >= 2){
			//認証ダイアログが表示されているなら
			switch (Key.getCode()){
			case Key.ENTER:
				//OKボタンと同じ
				DialogBox.okbtn.onRelease();
				break;
			}
		}
	}
	//リンク吹き出しを消す
	if (_root.Main.FlagLink._visible){
		_root.Main.FlagLink._visible = false;
	}
	
};

Key.addListener(keyListner);
