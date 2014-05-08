import flash.external.*;

/*
 *
 * main
 * 編集ボード
 *
 */

 //グローバル変数
localpath = "/";

backboard._width = PaperW;
backboard._height = PaperH;
backboard._x = 0;
backboard._y = 0;

createEmptyMovieClip("canvasLine",-20);//ページ区切り線を描画
createEmptyMovieClip("canvasDef",100000);//ロードされた線の描画領域
createEmptyMovieClip("canvasMine",100001);//自分の作業描画領域
createEmptyMovieClip("canvasDel",100002);//消しゴムの描画領域

//データ記憶配列
unloaded = true;
_global.m_DataList = new Array();
_global.m_SelList = new Array();


//ページの区切りを書き込む


//描画用の板（画布）
Canvas._visible = false;
Canvas._x = 0;
Canvas._y = 0;
Canvas._width = backboard._width;
Canvas._height = backboard._height;

Canvas._alpha = 0;
Canvas.swapDepths(100003);
Canvas.useHandCursor = false;
backboard.swapDepths(-100);
backboard.useHandCursor = false;
this.useHandCursor = false;

FlagSelect._visible = false;
FlagSelect.swapDepths(100010);
/*
FlagFile._visible = false;
FlagPhoto._visible = false;
FlagPlugin._visible = false;
FlagShape._visible = false;
FlagText._visible = false;
*/
shape_temp._visible = false;
FlagLink._visible = false;
FlagLink.swapDepths(100011);

//地図の移動・縮尺変更に使用
curscale = 100;
PageDragging = false;
startp = new Object();
startm = new Object();
lasttime = -1;


////////////////////////////////////////////////////
//ツールとペンの初期設定
oldfnum = -1;
m_toolname = "view";
curshape = "circle";

pencolor = 0x14ade0;
penwidth = 3;
erasesize = 23;

//前回の色を読み込み
var so = new SharedObject;
so = SharedObject.getLocal("NOTA");
if (so.data.mycolor != undefined){
	pencolor = so.data.mycolor;
}
delete so;


//元の旗は非表示
resizePageH();

//接続を受け付ける
map_lc =  new LocalConnection();
map_lc.startTime = getTimer();
map_lc.connect(SDIR + MyPage);

//第一声
playSound("KASHA");

//書き込み変数
WriteAccessCnt = 0;


////////////////////////////////////////////////////////////////////////
//
//
//ページデータの読み込み！
//
//
////////////////////////////////////////////////////////////////////////

LoadMapData();

function clearMapData(){
	//マップのデータを全て消去
	var i=0;
	for (i=0;i<m_DataList.length;i++){
		if (eval(i) != undefined){
			eval(i).removeMovieClip();
			delete eval(i);
		}
	}
	//手書きメモリを消去
	canvasDef.clear();

	delete _global.DataList;
	_global.m_DataList = new Array();

	//Mapを消す
	_root.Main._visible = false;

}

function LoadMapData(forupdate){

	//ロード中の写真があれば、全て、停止せよ！
	if (loadoldpage != MyPage){
		clearMapData();
	}

	if (loadoldpage == undefined){
		//初めてなら、白紙ページを表示
		moveMap(ML,MT);
	}
	loading = true;

	//地図データの読み込み！
	delete myLoadVars;
	myLoadVars = new LoadVars();
	myLoadVars.onLoad = onLoadData;
	myLoadVars.forupdate = forupdate; //内部の定期更新用か？
	var myDate = new Date;
	if (MyPage == undefined)
		myLoadVars.load(SERVER + "read.cgi?param=backup&date" + myDate.getTime());
	else
		myLoadVars.load(SERVER + "read.cgi?param=backup&page=" + MyPage
						+ "&date=" + myDate.getTime());



};

loadErrorCnt = 0;

function onLoadData(success){
	//データが読み込まれた！
/*
	//UserIDを記憶
	_global.MyID =this.user;
	_global.MyPasslen =this.passlen;
	_global.MyAutoLogin = (this.autologin != "false");
*/
	_global.MyAnonymous = this.anonymous;

	if (!success || this.res != "OK"){
		//ページが見つからない
		if (this.anonymous == "none"){
			//第3者への閲覧が禁止されている

			_root.startEdit();
		}else if (loadErrorCnt < 2){
			//3秒後にもう一度読み込む
			clearInterval(updateIntervalID);
			updateIntervalID = setInterval(updatePage,3000);
		}else{
			if (MyLang == "en"){
				ErrorMes("Page not found.\r" + MyPage);
			}else{
				ErrorMes("ページが見つかりませんでした。\r" + MyPage);
			}
		}
		loadErrorCnt++;
		return;
	}
	loadErrorCnt = 0;
	if (MyPage != myLoadVars.page){
//		ErrorMes("別のページを読み込み中です。\r" + MyPage);
		return;
	}

	//効果音
	if (myLoadVars.forupdate == true){
		playSound("POU");
	}

	//まず、用紙のサイズをセットする
	if (myLoadVars.width != undefined)
		_global.PaperW = myLoadVars.width;//1000;
	else
		_global.PaperW = 1000;
	if (myLoadVars.height != undefined)
		_global.PageH = myLoadVars.height;//1414;
	else
		_global.PageH = 1414;

	_global.PaperH = PageH;
	backboard._width = PaperW;
	backboard._height = PageH;
	Canvas._width = backboard._width;
	Canvas._height = backboard._height;


	if (myLoadVars.use != "temp"){
		//ページ番号は？
		_global.MyPage = myLoadVars.page;

		//編集モードか閲覧モードか
		if (myLoadVars.editmode == "true"){//この行かまうな
			//編集モード
			if (PageEdit != true){
				_root.setEditMode(true,myLoadVars.user,myLoadVars.power);
			}
		}else{
			//閲覧モード
			if (PageEdit != false){
				_root.setEditMode(false);
			}
		}

		//編集権限は？
		_global.PageDatEdit = myLoadVars.edit;
		_global.PageLock = (PageDatEdit == "admin" && MyPower != "admin");
		for (var i=0;i<PluginList.length;i++) {
			PluginList[i].onPageLock((PageDatEdit == "admin"));
		}
		//ページの作者は？
		_global.PageAuthor = myLoadVars.author;

		if (PageLock && myLoadVars.forupdate != true){
			if (PageEdit){
				//管理者でなければ、ツールを戻す
				if (MyLang == "en"){
					ErrorMes("This page is locked. Only administrators can edit this page.");
				}else{
					ErrorMes("このページは凍結されています。管理者以外は編集できません。");
				}
				if (m_toolname != "view"){
					setToolOption("view");
				}
			}
		}


		//ファイルの更新日
		MyFTime = myLoadVars.ftime;

		//既存選択オブジェクトのID
		for (var i=0;i<m_SelList.length ;i++){
			m_SelList[i].oldid = m_DataList[m_SelList[i].num].id;
		}


		//取り消しメモリ等の削除
		if (loadoldpage != MyPage){
			//異なるページを読み込み
			m_UndoList = new Array();	//Undo用のメモリ
			m_RedoList = new Array();	//Undo用のメモリ
			UndoPos = 0;

			//ページが違うなら、全情報を削除
			for (i=0;i<m_DataList.length;i++){
				eval(i).removeMovieClip();
				delete eval(i);
			}
			delete _global.DataList;
			_global.m_DataList = new Array();

		}
		//ページの重さ情報を消す
		oldpageweight = null;
		//タイトルを記憶
		_global.MyPageTitle = myLoadVars.title;

		//初期位置を読み込む
		if (unloaded){
			unloaded = false;
			loadMapPosition();
		}
		//先にスクロール
		if (loadoldpage != MyPage){
			//地図の場所を読み込む
			moveMap(ML,MT);
		}
		//Map表示
		_root.Main._visible = true;
	}
	//手書きメモリを消去
	canvasDef.clear();

	//背景色
	changePageBack(myLoadVars["bgcolor"]);

	//データ整理
	var i=0;
	while (myLoadVars["id" + i ]  >  0){
		//すでにIDがあるか検索
		var indx = findID(myLoadVars["id" + i]);
		if (indx >= 0){
			m_DataList[indx].del = 2; //放置フラグ
			//更新されているか？
			if (myLoadVars["update" + i] > m_DataList[indx].update){
				m_DataList[indx].del 		= 3; //更新フラグ
				m_DataList[indx].id 		= myLoadVars["id" + i];
				m_DataList[indx].author 	= myLoadVars["author" + i];
				m_DataList[indx].tool 		= myLoadVars["tool" + i];
				m_DataList[indx].date 		= myLoadVars["date" + i];
				m_DataList[indx].update 	= myLoadVars["update" + i];
				m_DataList[indx].x 			= myLoadVars["x" + i];
				m_DataList[indx].y 			= myLoadVars["y" + i];
				m_DataList[indx].xline 		= myLoadVars["xline" + i];
				m_DataList[indx].yline 		= myLoadVars["yline" + i];
				m_DataList[indx].width 		= myLoadVars["width" + i];
				m_DataList[indx].height		= myLoadVars["height" + i];
				m_DataList[indx].scale		= myLoadVars["scale" + i];
				m_DataList[indx].edit		= myLoadVars["edit" + i];

				m_DataList[indx].text 		= myLoadVars["text" + i];
				m_DataList[indx].fname 		= myLoadVars["fname" + i];
				m_DataList[indx].shape 		= myLoadVars["shape" + i];
				m_DataList[indx].bgcolor 	= myLoadVars["bgcolor" + i];
				m_DataList[indx].transparent= myLoadVars["transparent" + i];
				m_DataList[indx].fgcolor 	= myLoadVars["fgcolor" + i];
				m_DataList[indx].thickness 	= myLoadVars["thickness" + i];
				m_DataList[indx].plugin 	= myLoadVars["plugin" + i];

				m_DataList[indx].param = myLoadVars["param" + i];
				m_DataList[indx].comment = myLoadVars["comment" + i];
				m_DataList[indx].rotation= myLoadVars["rotation" + i];
			}else if (m_DataList[indx].tool == "DRAW"){
				//手書き線は常に再描画
				m_DataList[indx].del 	= 3; //更新フラグ
			}

		}else{

			//新規オブジェクトだ！
			var obj = new Object();
			obj.del 		= 3;
			obj.id 			= myLoadVars["id" + i];
			obj.author 		= myLoadVars["author" + i];
			obj.tool 		= myLoadVars["tool" + i];
			obj.date 		= myLoadVars["date" + i];
			obj.update 		= myLoadVars["update" + i];
			obj.x 			= myLoadVars["x" + i];
			obj.y 			= myLoadVars["y" + i];
			obj.xline 		= myLoadVars["xline" + i];
			obj.yline 		= myLoadVars["yline" + i];
			obj.width 		= myLoadVars["width" + i];
			obj.height		= myLoadVars["height" + i];
			obj.scale		= myLoadVars["scale" + i];
			obj.edit		= myLoadVars["edit" + i];

			obj.text 		= myLoadVars["text" + i];
			obj.fname 		= myLoadVars["fname" + i];
			obj.shape 		= myLoadVars["shape" + i];
			obj.bgcolor 	= myLoadVars["bgcolor" + i];
			obj.transparent = myLoadVars["transparent" + i];
			obj.fgcolor 	= myLoadVars["fgcolor" + i];
			obj.thickness 	= myLoadVars["thickness" + i];
			obj.plugin 		= myLoadVars["plugin" + i];

			obj.param = myLoadVars["param" + i];
			obj.comment = myLoadVars["comment" + i];
			obj.rotation= myLoadVars["rotation" + i];
			_global.m_DataList.push(obj);//追加
		}
		i++;
	}


	//オブジェクトを読み込み
	for (var i=0;i<m_DataList.length;i++){
		if (myLoadVars.use == "temp"){
			if (m_DataList[i].tool == "DRAW"){
				if (m_DataList[i].author != "template"){
					//手書き線は常に再描画
					m_DataList[i].del 	= 3; //更新フラグ
				}
			}
		}
		if (m_DataList[i].del == 0){
			//削除されているので、消せ！
			if (myLoadVars.use == "temp"){
				if (m_DataList[i].author == "template"){
					_global.m_DataList[i].del = 1;
					eval(i)._visible = false;
				}
			}else{
				_global.m_DataList[i].del = 1;
				eval(i)._visible = false;
			}
		}
		else if (m_DataList[i].del == 2){
			//放置
			_global.m_DataList[i].del = 0;
			eval(i)._visible = true;
		}
		else if (m_DataList[i].del == 3){
			//更新せよ！
			_global.m_DataList[i].del = 0;
			//読み込み
			_root.Main.loadFlag(i);
		}
	}
	//番号がずれてしまったら選択をリセット
	for (var i=0;i<m_SelList.length ;i++){
		var num = m_SelList[i].num;
		if (m_SelList[i].oldid != m_DataList[num].id ||
			m_DataList[num].del == 1)
		{
			//選択解除
			moveFlagFocus(-1,'nosound');
			break;
		}
	}

	//ページ数調整
	resizePageH();
	//テキストのリザイズは時間がかかるので、1秒あける
	if (!rsintervalID)
		rsintervalID = setInterval(resizePageH,1000);

	loadoldpage = MyPage;//この値は、書き込みでも使います
	loading = false;

	delete this;

};

function findID(id){
	for (i=0;i<m_DataList.length;i++){
		//オブジェトをロードする
		if (m_DataList[i].id == id){
			return i;
		}
	}
	return -1;
};

function loadFlag(i){
	//オブジェクトをロードする
	var obj = m_DataList[i];
	if (obj.del == 1){
		return;//deleted Item
	}
	if (eval(i) == undefined){//定義されていれば、前と同じということになる
		if (obj.tool == "FILE" || obj.tool == "SHAPE" || obj.tool == "PLUGIN"
			|| obj.tool == "TEXT")
		{
			//図形、ファイル（絵、または添付）、文字
			switch (obj.tool){
				case "FILE":
					var ext = obj.fname.substr(obj.fname.lastIndexOf(".")+1);//拡張子
					if (ext == "jpg" || ext == "swf"){
						attachMovie("FlagPhoto",i,i);
					}else{
						attachMovie("FlagFile",i,i);
					}
					break;
				case "SHAPE":
					attachMovie("FlagShape",i,i);
					break;
				case "PLUGIN":
					attachMovie("FlagPlugin",i,i);
					break;
				case "TEXT":
					attachMovie("FlagText",i,i);
					break;
			}
			eval(i)._visible = false;
			eval(i).focusEnabled = true;

		}else if (obj.tool == "DRAW"){
			//線ですね
			//区切りを分解して配列へ
			drawStringToList(obj);
			//そして描画
			drawRoad(obj);
		}
	}else{
		//既存オブジェクトの更新
		_root.Main.showFlagObjectData(i);
		eval(i)._visible = true;
	}

};

///////////////////////////////////////////////////////////////
//データの更新確認
///////////////////////////////////////////////////////////////

//一定間隔で更新をチェック
chatMode = false;
checkCount = 0;
startPageUpdateCheck(false);

function startPageUpdateCheck(ischatmode){
	clearInterval(ftimeIntervalID);
	ftimeIntervalID = setInterval(checkFTime,1000*10);
	chatMode = ischatmode;
	checkCount = 0;
}


function checkFTime(){
	if (MyPage == null)
		return;
	if (!_root.Main._visible)
		return;

	checkCount++;

	if (chatMode){
		//チャットモード
		//10秒に一回
		if (checkCount > 18){
			//10秒×18 = 3分間で終了
			chatMode = false;
			checkCount = 0;
			return;
		}
	}else{
		//通常モード
		//30秒に一回
		if (Math.floor((checkCount % 3)) != 1){
			//3回に一度だけチェック
			//ページを呼んだ直後の10秒後にチェックがはいるように調整
			return;
		}
	}


	myFTimeVars = new LoadVars();
	myFTimeVars.onLoad = onMyFTimeVars;

	var myDate = new Date;
	myFTimeVars.load(SERVER + "read.cgi?action=getftime&page=" + MyPage
					 + "&date=" + myDate.getTime());

};

function onMyFTimeVars(sucess){

	if (!sucess || this.res != "OK"){
		return;
	}
	if (this.ftime > MyFTime && this.page == MyPage){
		//更新されている！

		//自分の情報を書き込み中の場合は、回避する
		if (WriteAccessCnt == 0){
			updatePage(); //更新
			MyFTime = this.ftime;
		}
		//一度、他人による更新が行われたら、５分間は10秒毎チェック
		startPageUpdateCheck(true);
	}
};
function updatePage(){
	//ページを更新する
	clearInterval(updateIntervalID);
	if (!_root.Main._visible)
		return;

	if (WriteAccessCnt > 0){
		//自分が書き込み中なら、3秒後に再度呼び出し
		//onMyFTimeVarsで一度、チェックしているが、その後またバッティングする可能性アリ
		updateIntervalID = setInterval(updatePage,3000);
	}else if (Canvas.isUsingPen == true){
		//手書き描画中or消しゴム使用中なら3秒後に再度呼び出し
		//自分の手描きをWriteした後、updateされるから
		updateIntervalID = setInterval(updatePage,3000);
	}else if ((oldfnum != null && oldfnum >= 0) && m_DataList[oldfnum].tool == "TEXT"){
		//「テキスト」を選択中なら3秒後に再度呼び出し
		updateIntervalID = setInterval(updatePage,3000);
	}else{
		//更新
		LoadMapData(true);
	}

}

///////////////////////////////////////////////////////////////
//地図データの書き込み
///////////////////////////////////////////////////////////////

function WriteMapData(num,draw_numlist,newobj){

	//保存

	var Vars = new LoadVars();
	Vars.action = "record";//保存お願い
	Vars.page = loadoldpage;
	//MyPageにしないのは、ページ切り替え後、新しいページにアイテムを
	//保存してしまうから。
	//ページは同一か？
	var pageSame = (loadoldpage == MyPage);
	var delfiles = "";

	var title_changed = false;
	if (pageSame){
		//タイトル取得
		title_changed = getPageTitle();
		if (title_changed){
			Vars["head:title"] = MyPageTitle;//タイトル
		}
		//編集モードでなければキャンセル
		if (!PageEdit || PageLock){
			return;
		}
	}

	//大きさ
	//一つのアイテムを書き換え（ヘッダー含む）
	if (num != undefined){
		var obj = newobj;
		if (obj != undefined){
			//差分だけ更新
			if (num == 'head'){
				obj.id = 'head';//差分があっても、IDだけは収納する
			}else{
				obj.id = m_DataList[num].id;//差分があっても、IDだけは収納する
			}
		}else{
			//メンバを全部を送る
			obj = new Object();
			obj = m_DataList[num];
		}
		for (propname in obj){
			if (propname != "xlist" && propname != "ylist" && //手書き配列は送らない
				propname != "selx" && propname != "sely" &&  //選択位置
				propname != "num" && propname != "mem" &&
				propname != "newpic" &&
				propname != "date" && propname != "update")
			{
				if (obj[propname] != undefined){
					//データが有効なら
					Vars[obj.id + ":" + propname] = obj[propname];
				}
			}
		}
	}
	//複数個同時に(手書き線を消すときに使う)
	for (var i=0;i<draw_numlist.length;i++){
		var obj = m_DataList[draw_numlist[i]];
		if(obj.del == 1){
			//線の完全削除
			Vars[obj.id + ":" + "id"] = obj.id;
			Vars[obj.id + ":" + "del"] = 1;//削除の場合、idとdelだけで足る
		}else{
			//線の部分変更
			Vars[obj.id + ":" + "id"] = obj.id;//差分があっても、IDだけは収納する
			Vars[obj.id + ":" + "xline"] = obj.xline;
			Vars[obj.id + ":" + "yline"] = obj.yline;

		}
	}

	ResVars = new LoadVars;
	ResVars.Vars = Vars;
	ResVars.titlechanged = title_changed;
	if (num != undefined){
		ResVars.num = num;
	}
	ResVars.trycnt = 0;
	ResVars.pageSame = pageSame;
	ResVars.onLoad = onLoadResVars;

	_root.statusbar.accessFlag.gotoAndPlay("start");
//	WriteAccess = true; //書き込み中
	WriteAccessCnt++;
//	_root.statusbar.writecnt = WriteAccessCnt;
	_root.statusbar.accessFlag._xscale = 100 + WriteAccessCnt*10;

	Vars.sendAndLoad(SERVER + "write.cgi",ResVars);

	//ページの動作の重さを量る（経験値）
	var pageweight = getPageWeight();

	if (pageweight >= 100 && (pageweight > oldpageweight || !oldpageweight)){
		_root.AlertABox.gotoAndStop("limit");
		oldpageweight = pageweight;
	}
};

onLoadResVars = function(success){
	_root.statusbar.accessFlag.gotoAndStop("stop");
	WriteAccessCnt--;
	_root.statusbar.accessFlag._xscale = 100 + WriteAccessCnt*10;

	if (!success || this.res == "ERR"){
		//書き込み失敗！
		//3回だけ試してみる！！
		if (this.trycnt < 3){
			this.trycnt++;
			Vars = this.Vars;
			_root.statusbar.accessFlag.gotoAndPlay("start");
			WriteAccessCnt++;
			_root.statusbar.writecnt = WriteAccessCnt;
			_root.statusbar.accessFlag._xscale = 100 + WriteAccessCnt*10;

			Vars.sendAndLoad(SERVER + "write.cgi",this);

		}else{
			if (MyLang == "en"){
				ErrorMes("Writing failure.");
			}else{
				ErrorMes("書き込みに失敗しました。");
			}
		}
		return;
	}
	if (this.pageSame){
		//作成日と更新日
		var update_byothers = false;
		if (this.num != undefined && this.update != undefined){
			if (m_DataList[this.num].date == null){//新規作成時
				_global.m_DataList[this.num].date = this.update; //作成日を書き換え
			}
			if (m_DataList[this.num].update == this.item_last_update ||
			    this.item_last_update == undefined || this.item_last_update == "")
			{
				//自分で更新
				_global.m_DataList[this.num].update   = this.update; //更新日を書き換え
			}else{
				update_byothers = true;
			}
			if (isFlagSelected(this.num) && m_SelList.length == 1){
				FlagSelect.showAuth();//作成者情報表示更新
			}
		}
		//ページ数調整
		resizePageH();
		//更新確認
		if (this.preftime > MyFTime){
			//更新されている！
			update_byothers = true;
		}
		if (update_byothers){
			//他人によって書き込み前に更新
			clearInterval(updateIntervalID);
			updateIntervalID = setInterval(updatePage,1000);
			//更新間隔をあげる
			startPageUpdateCheck(true);
		}
		MyFTime = this.ftime;//書き込み後の更新時間

		if (this.titlechanged){
			//一覧を更新
			_root.updateSidebar();
		}
		//ヘッダー情報変更
		if (this.changeedit == '1'){
			_global.PageDatEdit = this.Vars["head:edit"];
			if (PageDatEdit == "admin"){
				if (MyLang == "en"){
					ErrorMes("This page has been locked.");
				}else{
					ErrorMes("ページを凍結しました。");
				}
			}else{
				if (MyLang == "en"){
					ErrorMes("This page has been unlocked.");
				}else{
					ErrorMes("ページの凍結を解除しました。");
				}
			}
			for (var i=0;i<PluginList.length;i++) {
				PluginList[i].onPageLock((PageDatEdit == "admin"));
			}
			//一覧の更新
			_root.updateSidebar();
		}
	}
};


////////////////////////////////////////////////////////////////////////
//
//
//他のムービーとの通信
//
//
////////////////////////////////////////////////////////////////////////

map_lc.openPage = function(newpage){
	//ページを開く
	openPage(newpage)


};

function openPage(newpage){
	if (oldOpenPage == newpage){//２重受信を防ぐ
		return;
	}

	oldOpenPage = newpage;


	//ページの切り替えを行え！
	_global.MyPage = newpage;
	//データの読み込み
	LoadMapData();

}

map_lc.changeAnonymous = function(power){
	//参加条件と公開レベルが変更された
	//account.swfから
	_global.MyAnonymous = power;

}

function ex_addImg(fname){
	//新しい絵がアップロードされた！
	if (PageEdit != true){
		if (MyLang == "en"){
			ErrorMes("Please login to insert images.");
		}else{
			ErrorMes("画像を貼り付けるには、編集モードに切り替えて下さい。");
		}
		return;
	}
	if (PageLock){
		//凍結されています。
		if (MyLang == "en"){
			ErrorMes("This page is locked. Only administrators can edit this page.");
		}else{
			ErrorMes("このページは凍結されています。管理者以外は編集できません。");
		}
		return;
	}

	//ファイルを登録！
	addFile(fname);

};

function ex_msgBox(msg){

	//メッセージを表示する
	ErrorMes(msg);

}

function ex_openUrl(surl){

	//プラグイン命令
	if (surl.substr(0,8) == "command:"){
		curflag.plugin.onCommandLink(surl.substr(8));
		return;
	}
	if (surl.substr(0,7) == "plugin:"){
		var plgname = surl.substr(7);
		//さらにパラメータがあるか？
		var cr = plgname.indexOf(":");
		if (cr != -1){
			plgparam = plgname.substr(cr+1);
			plgname = plgname.substr(0,cr);
		}

		//プラグインを追加せよ（暫定）
		if (PageEdit != true){
			return;
		}
		if (PageLock){
			//凍結されています。
			if (MyLang == "en"){
				ErrorMes("This page is locked. Only administrators can edit this page.");
			}else{
				ErrorMes("このページは凍結されています。管理者以外は編集できません。");
			}
			return;
		}
		//追加
		addPlugin(plgname,plgparam);

		return;
	}
	if (surl.substr(0,7) == "master:"){
		//マスターページの適用
		var masterid = surl.substr(7);

		if (PageEdit != true){
			return;
		}
		if (PageLock){
			//凍結されています。
			if (MyLang == "en"){
				ErrorMes("This page is locked. Only administrators can edit this page.");
			}else{
				ErrorMes("このページは凍結されています。管理者以外は編集できません。");
			}
			return;
		}
		_root.masterPage(masterid);

		return;
	}

	//指定のアドレスのページを開け！
	if (surl.substr(0,5) == "http:" ||
		surl.substr(0,6) == "https:" ||
		surl.substr(0,7) == "mailto:" ||
		surl.substr(0,4) == "ftp:")
	{
		//外部のページ
		surl = Replace(surl,"$amp;","&");	//特殊エンコードlink.cgi?page=urlのurlに=&があると動作しないから
		surl = Replace(surl,"$equal;","=");

		//吹き出しを表示させ、ジャンプするか問う
		FlagLink.jumpUrl(surl);


//			getURL(surl,"_top");//別ウィンドウで開くようにせよ！
//			getURL(surl,"_blank");//別ウィンドウで開くようにせよ！
	}else{
		//内部のページ

		//編集中の文字がある場合は、やめる
		//フォーカスを奪う
		if (MyScreen == 1){
			surl += ".screen";
		}

		//吹き出しを表示させ、ジャンプするか問う
		FlagLink.jumpUrl("./?" + surl);

	}

};

ExternalInterface.addCallback("addImg", this, ex_addImg);
ExternalInterface.addCallback("msgBox", this, ex_msgBox);
ExternalInterface.addCallback("openUrl", this, ex_openUrl);


////////////////////////////////////////////////////////////////////////
//点と線の読み書きを行う！
////////////////////////////////////////////////////////////////////////

function getMouseX(){
	return _xmouse;
}

function getMouseY(){
	return _ymouse;
}

function drawRoad(obj){
	//線を描画する
	canvasDef.lineStyle(obj.thickness, obj.fgcolor,90);
	var bmove = true;
	for (n=0;n<obj.xlist.length;n++){
		var x = Replace(String(obj.xlist[n]),",","^").split("^");//過去との互換性
		var y = Replace(String(obj.ylist[n]),",","^").split("^");
		if (x[0] == "#" || x[0] == ""){
			bmove = true;
		}else if (bmove){
			canvasDef.moveTo(x[0],y[0]);
			bmove = false;
		}else{
			if (x[1] != undefined && y[1] != undefined){
				canvasDef.curveTo(x[1],y[1],x[0],y[0]);
			}else{
				canvasDef.lineTo(x[0],y[0]);
			}
		}

	}

};




function selectRoad(){
/*
	//現在のマウス地点の下に道があるか確かめ、あるなら、それらを
	//強調表示せよ
	var px = getMouseX();
	var py = getMouseY();

	var i=0;
	var mindis = 100;
	var minnum = 0;
	var minnumw = 0;
	while (myLoadVars["id" + i] > 0){
		if (myLoadVars["del" + i] != 1 && myLoadVars["pt" + i] == 0)
		{
			//点と道が近くにあるか？
			for (k=0;k<myLoadVars["xlist"+i].length;k++){
				if (myLoadVars["xlist"+i][k] != "#"){
					dis = Math.sqrt(Math.pow(myLoadVars["xlist"+i][k]-px,2)+
							Math.pow(myLoadVars["ylist"+i][k]-py,2));
					if (dis < mindis){
						mindis = dis;//もっとも近い位置のものを探す
						minnum = i;
						minnumw = k;
					}
				}
			}
		}
		i++;
	}
	//さらに、コメントの場所を移動
	eval(minnum)._x = px;
	eval(minnum)._y = py;
//	eval(minnum)._x = myLoadVars["xlist"+minnum][minnumw];
//	eval(minnum)._y = myLoadVars["yist"+minnum][minnumw];

	//ある！
	moveFlagFocus(minnum,true);//フォーカスを移動。
*/
}


/*
function crossRoad(roadsX1,roadsY1,roadsX2,roadsY2,len){
	//始点と終点で線を引き交わっているかで考える
	//もしく各点が異常に近いかどうか
	if (len == undefined || len < 1){
		len = 30;//どのくらい離れているのか？
	}
	var dis = 0;
	for (r=0;r<roadsX1.length;r++){
		for (k=0;k<roadsX2.length;k++){
			if (roadsX1[r] != "#" && roadsX2[k] != "#" ){
				dis = Math.sqrt(Math.pow(roadsX1[r]-roadsX2[k],2)+Math.pow(roadsY1[r]-roadsY2[k],2));
				if (dis < len){
					//同じ線として認定する！
					return dis;
				}
			}
		}
	}
	return -1;
};
*/

function drawStringToList(obj){
	//点の文字列を配列に形式変換
	if (obj.xline != "" && obj.xline != undefined){
		obj.xlist = obj.xline.split(":");
		obj.ylist = obj.yline.split(":");
	}else{
		obj.xlist = obj.x.split(":");
		obj.ylist = obj.y.split(":");
	}

}

function drawListToString(obj){
	//点の配列を文字列に形式変換

	//保存
	obj.x = "0";
	obj.y = "0";
	obj.xline = "";
	obj.yline = "";
	var sp = "";
	for (var i=0;i<obj.xlist.length;i++){
		obj.xline += sp + obj.xlist[i];
		obj.yline += sp + obj.ylist[i];
		sp = ":";
	}

	//さらに、既存の道で自分が描いたもので、種類が同じ場合は、連結する
/*	var i=0;
	for (i=0;i<m_DataList.length;i++){
		var obj = m_DataList[i];
		var numobj = m_DataList[num];
		if (obj.del != 1 && i != num && obj. == numobj.)
		{
			//交差しているか？
			if (crossRoad(obj.xlist,obj.ylist,numobj.xlist,numobj.ylist) >= 0)
			{
				//既存の線に追加する。
				trace("同じ線とみなす！");
				obj.xlist.push("#");
				obj.ylist.push("#");
				obj.xlist = obj.xlist.concat(numobj.xlist);
				obj.ylist = obj.yist.concat(numobj.xlist);
				num = i;//IDの乗り換え！
				_global.m_DataList.pop();//一つ減らせ！
				break;
			}
		}
		i++;
	}
*/
};


function getAncp(n){
	//"num,num"で区切られた数字から最初の数字だけを取り出す
	var na = Replace(String(n),",","^").split("^");
	return Number(na[0]);
}


function registerErase(){
	//線の消去を行う
	canvasDef.clear();
	var DelReserve = new Array();//削除するindexを配列で
	//現在の点から
	var i=0;
	var curtime = getTm();
	for (i=0;i<m_DataList.length;i++){
		var obj = m_DataList[i];
		if (obj.del != 1 && obj.tool == "DRAW"){
			//線だけ抽出
			//かつ自分が描いた線である
			var change = false;
			var xlist = obj.xlist;//線だけね。
			var ylist = obj.ylist;
			var able = true;
			if (obj.author != MyID && MyPower != "admin"){
				able = false;
			}
            var n=0;
            for (n=0;n<xlist.length;n++){
                if (xlist[n] != "#"){
                    ap = new Object();//点を絶対座標に変換してhittestを行う
                    ap.x = getAncp(xlist[n]);
                    ap.y = getAncp(ylist[n]);
                //	ap.y += 30;
                    canvasDel.localToGlobal(ap);
                    if (canvasDel.hitTest(ap.x,ap.y,true)){
                        if (!able){
                            //権限なし
                            if (MyLang == "en"){
                                ErrorMes("You can't delete objects of others.");
                            }else{
                                ErrorMes("他人の書き込みは削除できません。");
                            }
                        }else{
                            //円の中に入っている！
                            xlist[n] = "#";
                            change = true;
                            //周囲の点を全部消せ！
                            if (n == xlist.length-2)	xlist[n+1] = "#";//最後から２番目
                            else if (n == 1)			xlist[n-1] = "#";//最初から２番目
                        }
                    }
                }
            }
			//新リストの作成（端の-とだぶった-の削除）
			if (change){
				var newxlist = new Array();
				var newylist = new Array();
				var v = 0;
				for (n=0;n < xlist.length;n++){
					sep = (xlist[n] == "#");
					if (sep) {ylist[n] = "#";}
					if (!sep || v > 0){	//セパレートではないか、前に有効文字のあるセパレートか
						newxlist.push(xlist[n]);
						newylist.push(ylist[n]);
					}
					if (sep && v == 1){ //有効文字が一つしかないのにセパレート
						newxlist.pop();	newxlist.pop();
						newylist.pop();	newylist.pop();
					}
					if (sep) {	v=0; }
					else     {  v++; }
				}
				if (v == 0){ //最後に不要なセパレート
					newxlist.pop();
					newylist.pop();
				}
				var newobj = new Object();	//保存データ
				//ここで、変更を適用。
				newobj.xlist = newxlist;
				newobj.ylist = newylist;
				if (newxlist.length < 2){
					//完全に削除された
					newobj.del = 1;
				}else{
					//部分削除
					drawListToString(newobj);
				}
				//データを記憶
				updateFlag(i,newobj,curtime,true);	//この時点では保存しない！
				//保存予約
				DelReserve.push(i);
				//残りの線を描画
				drawRoad(obj);
			}else{
				//残りの線を描画
				drawRoad(obj);
			}
		}
	}

	//消しゴムのクリア！
	canvasDel.clear();
	//削除
	if (DelReserve.length > 0){
		playSound("SHU");
		WriteMapData(undefined,DelReserve);
	}


};

////////////////////////////////////////////////////////////////////////
//
//
//４つの道具のモードの切り替え
//
//
////////////////////////////////////////////////////////////////////////

function setCursor(){

	//カーソルをセットする必要が生じたときに呼び出される
	 switch (m_toolname){
		case "pen":
			//道
			showMyCursor(true,"pen",pencolor);//色も同時に指定する
			break;
		case "shape":
			//地点
			showMyCursor(true,"shape",pencolor);
			break;
		case "text":
			//文字入力
			showMyCursor(true,"text");
			break;
		case "eraser":
			//消しゴム
			showMyCursor(true,"eraser");
			break;
		default:
			//閲覧モード（ペンを消す）
			showMyCursor(false);
			break;
	}


};

function setMiniTool(){
	//どのツールセットを表示するか切り替える
	_root.minitool.hideSubmenu();
	if (PageEdit){
		_root.minitool._visible = true;
	}
	var obj = _root.minitool.toolbtntab;
	if (m_toolname == "view"){
		//編集・表示
		var isText=true,isShape=true,isPlugin=true,isImage=true,isFile=true;
		obj._visible = true;
		if (m_SelList.length > 0){
			for (var i=0;i<m_SelList.length;i++){
				var tool = m_DataList[m_SelList[i].num].tool;
				if (tool != "TEXT")		isText   = false;
				if (tool != "SHAPE")	isShape  = false;
				if (tool != "PLUGIN")	isPlugin = false;
				if (tool == "FILE"){
					if (m_DataList[m_SelList[i].num].fname.indexOf(".jpg") >= 0)
						isFile = false;
					else
						isImage = false;
				}else{
					isImage = false;
					isFile = false;
				}
			}
			if (isText)			obj.gotoAndStop("text");
			else if (isShape)	obj.gotoAndStop("shape");
			else if (isPlugin)	obj.gotoAndStop("etc");
			else if (isImage)	obj.gotoAndStop("image");
			else if (isFile)	obj.gotoAndStop("file");
			else				obj.gotoAndStop("etc");


		}else{
			//非選択
			obj.gotoAndStop("normal");
		}

	}else if (m_toolname == "pen"){
		//線
		obj._visible = true;
		obj.gotoAndStop("color");
	}else if (m_toolname == "shape"){
		//図形
		obj._visible = true;
		obj.gotoAndStop("addshape");
	}else{
		//消しゴム、テキスト
		obj._visible = false;
	}


};

function getEditMode(){
	//描画（編集）モードか否か
	return Canvas._visible;
};




function setToolOption(toolname,sound){

	//ページがロックされていたら、他は選択できない
	if (PageLock && toolname != "view"){
		if (MyLang == "en"){
			ErrorMes("This page is locked. Only administrators can edit this page.");
		}else{
			ErrorMes("このページは凍結されています。管理者以外は編集できません。");
		}
		return false;
	}

	//同じなら、終了
	if (m_toolname == toolname){
		return;
	}

	//ペンの種類を取得
	m_toolname = toolname;
	//サウンド
	if (sound != false){
		playSound("KON");
	}

	//設定を適用せよ！
	setMiniTool();
	for (var i=0;i<PluginList.length;i++) {
		PluginList[i].onSelectTool(toolname);		//ツールの表示を更新
	}

	//描画モードの設定/解除
	if (toolname == "view"){
		//閲覧モード（ペンを消す）
		Canvas._visible = false;
	}else{
		//描画モード
		Canvas._visible = true;
		//選択の初期化
		moveFlagFocus(-1);
	}

	//ダイアログを閉じる
	_root.DialogBox.gotoAndStop("close");

	//表示品質を変更
	if (m_toolname == "pen" || m_toolname == "eraser"){
		_quality = "MEDIUM";
	}else{
		_quality = "HIGH";
	}
	if (newtool == "view"){
		setCursor();
	}

	return true;
};



function setPenColor(mycolor){
	//ペンの色を変える
	pencolor = mycolor;
	//ペン先の色
	if (m_toolname == "pen")
		showMyCursor(2,"pen",mycolor);
	else
		showMyCursor(2,"shape",mycolor);


};

////////////////////////////////////////////////////////////////////////
//
//
//図形、テキスト、写真、プラグインの追加
//
//
////////////////////////////////////////////////////////////////////////


function addShape(shape){
	//図形の作成
	var obj     = new Object();
	obj.id 		= getTm();
	obj.del 	= 0;
	obj.author 	= MyID;
	obj.tool 	= "SHAPE";
	obj.shape 	= shape;
	obj.bgcolor = _root.Main.pencolor;
//	if (_root.Pen._currentframe == 2){
//		obj.width 	= Math.round(_root.Pen.shape._width);
//		obj.height 	= Math.round(_root.Pen.shape._height);
//	}else{
	_root.Main.shape_temp.gotoAndStop(obj.shape);
	obj.width 	= Math.round(_root.Main.shape_temp._width);
	obj.height 	= Math.round(_root.Main.shape_temp._height);
//	}
	obj.x 		= Math.round(_root.Main.getMouseX()-obj.width/2);
	obj.y 		= Math.round(_root.Main.getMouseY()-obj.height/2);
	obj.rotation = 0;
	if (obj.y < 10){
		obj.y = 10;
	}
	if (obj.x < 0){
		obj.x = 0;
	}
	if (obj.x > PaperW){
		obj.x = PaperW- obj.width;
	}
	//保存処理
	_root.Main.updateFlag(-1,obj);
	//作成
	var num = m_DataList.length-1;
	_root.Main.loadFlag(num);
	//表示更新
	_root.Main.setToolOption("view",false);
	playSound("SHU");
	_root.Main.moveFlagFocus(num,"noselect");

}

function addText(string){
	//文字の作成
	var obj     = new Object();
	obj.del 	= 0;
	obj.id 		= getTm();
	obj.author 	= MyID;
	obj.tool 	= "TEXT";
	obj.text 	= string;
	obj.bgcolor = "0xFFFFFF";
	obj.x 		= Math.round(_root.Main.getMouseX())-3;
	obj.y 		= Math.round(_root.Main.getMouseY())-10;
	obj.width 	= 300;	//初期の大きさ
	if (obj.y < 10){
		obj.y = 10;
	}
	if (obj.x < 0){
		obj.x = 0;
	}
	if (obj.x > PaperW){
		obj.x = PaperW- obj.width;
	}
	if (obj.x + obj.width > PaperW){
		obj.width = PaperW - obj.x;
	}
	obj.height 	= 20;		//初期の大きさ（推定）
	obj.rotation= 0;

	//保存処理
	_root.Main.updateFlag(-1,obj);
	//作成
	var num = m_DataList.length-1;
	_root.Main.loadFlag(num);
	//表示更新
	_root.Main.setToolOption("view",false);
	playSound("SHU");
	_root.Main.moveFlagFocus(num,"noselect");

	if (string != ""){
		//この部分は、statusbarから呼ばれる
		Selection.setFocus("_root.Main." + num + ".textbox");
		Selection.setFocus("_root.Main." + num + ".textbox");
		Selection.setSelection(0,0);

		clearInterval(textselID);
		textselID = setInterval(setTextSel,10,string.length);
	}else{
		clearInterval(textselID);
		textselID = setInterval(setTextSelNew,500,num);
	}

}

function setTextSelNew(num){
	//テキストのカーソル位置をセット
	Selection.setFocus("_root.Main." + num + ".textbox");
	clearInterval(textselID);

}

function setTextSel(param){
	//テキストのカーソル位置をセット
	clearInterval(textselID);

	Selection.setSelection(param,param);

}

function addFile(fname){
	//ファイルを登録！
	var mid = new Object();
	mid.x = Stage.width/2-170;
	mid.y = Stage.height/2-170;
	_root.Main.globalToLocal(mid);

	//メンバ代入
	var obj 	= new Object();
	obj.id 		= getTm();
	obj.del 	= 0;
	obj.author 	= MyID;
	obj.tool 	= "FILE";
	obj.fname 	= fname;
	obj.shape 	= "";//切り抜き
	obj.transparent = 0;//透過
	obj.x 		= Math.round(mid.x);
	obj.y 		= Math.round(mid.y);
	obj.width	= 0;
	obj.height 	= 0;
	obj.rotation= 0;
	obj.newpic 	= 1;	//新規作成であることをチェック

	//保存処理
	updateFlag(-1,obj);
	//作成
	var num = m_DataList.length-1;
	loadFlag(num);
	//表示更新
	_root.Main.setToolOption("view",false);
	playSound("SHU");
	_root.Main.moveFlagFocus(num,"noselect");

};


function addPlugin(pluginname,pluginparam){
	//プラグインの作成
	var mid = new Object();
	mid.x = Stage.width/2-170;
	mid.y = Stage.height/2-170;
	_root.Main.globalToLocal(mid);

	var myDate 	= new Date;
	var obj     = new Object();
	obj.id 		= getTm();
	obj.del 	= 0;
	obj.author 	= MyID;
	obj.tool 	= "PLUGIN";
	obj.plugin 	= pluginname;//プラグインの種類
	obj.fname 	= Math.round(myDate.getTime()) + ".xml";//データファイル
	obj.x 		= Math.round(mid.x);
	obj.y 		= Math.round(mid.y);
	obj.width 	= 0;
	obj.height 	= 0;
	obj.rotation= 0;
	obj.newpic 	= 1;	//新規作成であることをチェック

	obj.param 	= pluginparam;


	//保存処理
	updateFlag(-1,obj);
	//作成
	var num = m_DataList.length-1;
	loadFlag(num);
	//表示更新
	_root.Main.setToolOption("view",false);
	playSound("SHU");
	_root.Main.moveFlagFocus(num,"noselect");

};






////////////////////////////////////////////////////////////////////////
//
//
//Flagオブジェクト に関する関数群
//
//
////////////////////////////////////////////////////////////////////////



function findNumFromID(id){
	//IDからnumを探す。なければ-1を返す(非表示でも返す)
	for (var i=0;i<m_DataList.length;i++){
		if (id == m_DataList[i].id)
			return i;
	}
	return -1;

};

function updateFlag(num,obj,time,nosave){
	//オブジェクトを更新したときに呼び出す。
	//objに差分の変数を入れる



	//変更前のデータをアンドゥーにいれるのがポイント
	var undo = new Object();
/*
	cn++;
	var text1 = "";
	for (propname in obj){
			//新データを配列に入れる
		text1 += propname + "\t" + obj[propname] + "\r";
	}
	_root.testmes.text += text1;
	ErrorMes("書き込み開始だ20！:" + cn + ":" + cn2 + "\r" + text1);
*/


	if (num == -1){
		//配列に追加する
		_global.m_DataList.push(obj);
		num = m_DataList.length -1;
		undo.del = 1;	//新規作成Flag
	}else{
		//もし、masterをいじるなら、authorを自分にする
		if (m_DataList[num].author == "master"){
			obj.author = MyID;
		}
		//変数を呼び、既存の配列に代入
		for (propname in obj){
			//ここで、古いデータをUndoに入れる
			undo[propname] = m_DataList[num][propname];
			//新データを配列に入れる
			_global.m_DataList[num][propname] = obj[propname];
		}
	}
	//アンドゥー配列に追加
	while (m_UndoList.length > UndoPos){	//現在位置より先は削除
		m_UndoList.pop();	//posとlenを同じにする
	}
	m_RedoList = new Array();	//redoはクリア
	undo.id = m_DataList[num].id;
	undo.tool = m_DataList[num].tool; //種類は必ず必要
	undo.mem = time;//一気に処理したいときの共通ID
	m_UndoList.push(undo);
	UndoPos++;	//位置を繰り上げる
	//最大50個までとしよう
	while (m_UndoList.length > 50){
		m_UndoList.shift();
		UndoPos--;
	}
	//保存処理(差分だけという点に注目)
	if (nosave == undefined){
		WriteMapData(num,null,obj);
	}
};


function undoFlag(isRedo){
	//オブジェクトの復活
	var loop = true;
	while (loop){
		loop = false;
		var undo = null;
		if (isRedo){
			//Redo
			if (m_RedoList.length <= 0){
				if (MyLang == "en"){
					ErrorMes("You can't redo anymore.");
				}else{
					ErrorMes("これ以上、取り消しを元に戻すことはできません。");
				}
				return false;
			}
			UndoPos++;//一つ番号を上げる
			undo = m_RedoList.pop();
			if (undo.mem != undefined && undo.mem == m_RedoList[m_RedoList.length-1].mem){
				loop = true;	//次もよろしく
			}
			if (m_RedoList.length <= 0){
				//Redo無効化
			}
		}else{
			//Undo
			//現在編集中のテキストが、保存できないか検討
			for (var i=0;i<m_SelList.length ;i++){
				if (m_DataList[i].tool == "TEXT"){
					var flg = eval(m_SelList[i].num);
					flg.saveText();
				}
			}
			if (UndoPos <= 0){
				if (MyLang == "en"){
					ErrorMes("You can't undo anymore.");
				}else{
					ErrorMes("これ以上、取り消すことはできません。");
				}
				return false;
			}
			UndoPos--;//一つ番号を戻す
			undo = m_UndoList[UndoPos];
			if (undo.mem != undefined && undo.mem == m_UndoList[UndoPos-1].mem){
				loop = true;	//次もよろしく
			}
		}
		//メンバを元にもどせ！
		var num = findNumFromID(undo.id);
		if (num == -1) continue;	//見つからないなら次へ
		var redo = new Object();	//現在の状態
		for (propname in undo){
			redo[propname] = m_DataList[num][propname];
			if (propname != "mem")
				_global.m_DataList[num][propname] = undo[propname];
		}
		if (!isRedo){
			//Redoに備え現在の状態をRedoリストに記録しておく
			redo.num = num;
			redo.mem = undo.mem;
			m_RedoList.push(redo);
		}
		//元の状態を適用
		var obj = m_DataList[num];
		var isDraw = (obj.tool == "DRAW");
		if (undo.del == 0){	//削除の取り消し＝復活
			eval(num)._visible = true;
			if (obj.tool == "FILE" || obj.tool == "PLUGIN"){
				//この場合、ファイルをゴミ箱から戻さねばならない
				var fname = obj.fname;
				CopyVars = new LoadVars();
				CopyVars.load(SERVER + "upload.cgi?action=copy&fname=" + escape(fname) +
										"&srcpage=" + MyPage + "&page=" + MyPage);
			}
			//この場合全メンバを送る
			undo = m_DataList[num];
		}else if (undo.del == 1){	//新規作成の取り消し＝削除
			eval(num)._visible = false;
			if (isFlagSelected(num)){
				moveFlagFocus(-1);
			}
		}else if (!isDraw){	//普通のオブジェクトの変更
			_root.Main.showFlagObjectData(num,undo);
		}
		if (isDraw){
			//手書き文字だ！(難関)
			//基本的には全て書き直すしかない。
			canvasDef.clear();
			for (var i=0;i<m_DataList.length;i++){
				var obj = m_DataList[i];
				if (obj.del == 0 &&
					obj.tool == "DRAW")
				{
					//区切りを分解して配列へ
					drawStringToList(obj);
					drawRoad(m_DataList[i]);
				}
			}
		}

		//保存処理
		WriteMapData(num,null,undo);
	}
	return true;
};

function IsTextBoxInClient(num,forprint){
	//そのテキストボックスは現在表示すべきものかどうか？
	var obj = eval(num);
	var cb = obj.getBounds(_root.Main);
	if (cb.yMax - cb.yMin < Math.round(m_DataList[num].height)){
		cb.yMax = cb.yMin + Math.round(m_DataList[num].height);
	}
	var pt = new Object();
	pt.x = cb.xMin;	pt.y = cb.yMin;
	_root.Main.localToGlobal(pt);
	cb.xMin = pt.x; cb.yMin = pt.y;
	pt.x = cb.xMax;	pt.y = cb.yMax;
	_root.Main.localToGlobal(pt);
	cb.xMax = pt.x; cb.yMax = pt.y;

	var pt1 = new Object();
	var pt2 = new Object();
	pt1.x = 0;
	pt1.y = 0;
	pt2.x = Stage.width;
	pt2.y = Stage.height;

	//テキストボックスがこの中にあるか？
	if ((((pt1.y < cb.yMin && cb.yMin < pt2.y) ||
		(pt1.y < cb.yMax && cb.yMax < pt2.y)  ||
		(cb.yMin < pt1.y && pt2.y < cb.yMax)) &&
		((pt1.x < cb.xMin && cb.xMin < pt2.x) ||
		(pt1.x < cb.xMax && cb.xMax < pt2.x)  ||
		(cb.xMin < pt1.x && pt2.x < cb.xMax)) ) ||
		forprint == true)
	{
		if (!obj.textbox.inclt){
			if (m_DataList[num].text == undefined){
				obj.textbox.text = "";
			}else{
				obj.textbox.htmlText = m_DataList[num].text;
			}
			obj.textbox.inclt = true;
			//深度を設定
			setFlagDepths(obj);
		}
	}else{
		if (obj.textbox.inclt != false){
			obj.textbox.inclt = false;
			obj.textbox.text = "";
		}
	}

	if (forprint == true){
		obj.autoSize = "right";
		obj.wordWrap = true;
		obj.border = true;
	}

}

function showTextBoxInClient(forprint){
	//テキストボックスの内、現在のクライアント内で表示すべき物を自動で
	//表示させる！

	for (var i=0;i<m_DataList.length;i++){

		if (m_DataList[i].tool == "TEXT"/* && m_DataList[i].del == 0*/){
			IsTextBoxInClient(i,forprint);
		}
	}

}

function setAutoSizeOff(isoff){

	//テキストボックスの下が正しく印刷されないバグの回避
	for (var i=0;i<m_DataList.length;i++){

		if (m_DataList[i].tool == "TEXT"/* && m_DataList[i].del == 0*/){
			var obj = eval(i);
			if (isoff){
				obj.textbox.autoSize = false;
				//obj.back._height = obj._height;
			}else{
				obj.textbox.autoSize = true;
			}
		}
	}

}

function check_recently_updated(datestr){
    var yd = datestr.split(" ");
    var date = yd[0].split("/");
    var time = yd[1].split(":");
    var d = new Date(date[0], date[1]-1, date[2],time[0],time[1],time[2]);
    var today = new Date();
    if (today.getTime() - d.getTime() < 3*24*60*60*1000){
        return true;
    }

    return false;
}

function showFlagObjectData(num, obj){
	//オブジェクトのデータをタイプに合わせて読み込む
	if (obj == undefined)	//全部の変数を読み込む
		obj = m_DataList[num];
	var pFlag = eval(num);
	var FElement = pFlag;//.FElement;
	//基本属性
	if (obj.x != undefined){	//位置
		pFlag._x = obj.x;
		pFlag._y = obj.y;
	}
	switch (m_DataList[num].tool){
	case "TEXT":
		//テキスト
		var textbox = FElement.textbox;
		var fobject = textbox;
		pFlag.fobject = textbox;
        if (check_recently_updated(obj.update)){
            FElement.newmark.gotoAndStop(1);
        }else{
            FElement.newmark.gotoAndStop(2);
        }
		if (obj.width != undefined)//幅
			textbox._width = obj.width;
		if (obj.text != undefined && obj.text != ""){
			if (textbox.autoSize != true){
				textbox.autoSize = true;//自動でサイズ調整
			}
		}
		if (obj.text != undefined){//テキスト
			pFlag.textchange = false;
			textbox.inclt = false;//これをセットしないとテキストが変わらない
			IsTextBoxInClient(num);
		}
		if (obj.bgcolor != undefined){//背景色
			if (obj.bgcolor.length > 2 && obj.bgcolor != 0xFFFFFF){
				textbox.background = true;
				textbox.backgroundColor = obj.bgcolor;
			}else{
				textbox.background = false;
			}
		}
		pFlag.photoloading = 2;//ロード完了

		//テキストが空で選択中なら、フォーカスを与えよ！
		if (obj.text == ""){
			if (isFlagSelected(num)){
				Selection.setFocus("_root.Main." + num + ".textbox");
				Selection.setFocus("_root.Main." + num + ".textbox");
			}
		}
		break;
	case "SHAPE":
		//図形
		if (obj.rotation != undefined){	//回転
			pFlag._rotation = obj.rotation;
		}
		shape = FElement.shape;
		var fobject = shape;
		pFlag.fobject = shape;
		if (obj.shape != undefined){
			shape.clear();
			shape.gotoAndStop(obj.shape);//形
		}
		if (obj.width != undefined){
			shape._width = obj.width;	//大きさ
			shape._height = obj.height;
			setFlagDepths(pFlag); //深度を設定
		}
		if (obj.bgcolor != undefined){
			var myColor  = new Color(shape);
			myColor.setRGB(obj.bgcolor);
		}
		//透過処理
		if (obj.transparent != undefined){
			if (obj.transparent > 1 && obj.transparent < 100)
				shape._alpha = obj.transparent;
			else
				shape._alpha = 100;
		}
		break;
	case "FILE":
		var fname = m_DataList[num].fname;
		var ext = fname.substr(fname.lastIndexOf(".")+1);//拡張子
		pFlag.fileext = ext;
		if (ext != "jpg" && ext != "swf"){
			//ふつうのファイルである
            if (check_recently_updated(obj.update)){
                FElement.newmark.gotoAndStop(1);
            }else{
                FElement.newmark.gotoAndStop(2);
            }
			//FElement.gotoAndStop("fileicon");
			var fileicon = FElement.fileicon;
			//pFlag.fileicon = fileicon;
			var fobject = fileicon;
			pFlag.fobject = fileicon;
			fileicon.fname_txt.text = fname;
			var myTextFormat = new TextFormat();
			myTextFormat.align = "center";
			myTextFormat.underline = true;
			fileicon.fname_txt.setTextFormat(myTextFormat);
			//拡張子によるアイコン訳
			var icon = "all";
			switch (ext){
			case "jtd":
			case "jtdc":
				icon = "jtd";
				break;
			case "doc":
			case "docx":
			case "wtf":
				icon = "doc";
				break;
			case "xls":
			case "xlsx":
			case "csv":
				icon = "xls";
				break;
			case "html":
			case "htm":
				icon = "html";
				break;
			case "pdf":
				icon = "pdf";
				break;
			case "ppt":
			case "pptx":
				icon = "ppt";
				break;
			case "zip":
			case "lzh":
			case "cab":
				icon = "zip";
				break;
			case "wav":
			case "au":
			case "aif":
			case "mp3":
			case "aac":
			case "mid":
			case "wma":
				icon = "sound";
				break;
			case "avi":
			case "wmv":
			case "mpg":
			case "mpeg":
			case "ra":
				icon = "movie";
				break;
			}
			fileicon.filetype.gotoAndStop(icon);
			setFlagDepths(pFlag); //深度を設定
		}else{
			//画像
			if (obj.rotation != undefined){	//回転
				pFlag._rotation = obj.rotation;
			}

			var photo = FElement.photo;
			var shape = FElement.shape;
			var fobject = photo;
			pFlag.fobject = photo;
			//マスキング処理
			if (obj.shape != undefined || obj.fname != undefined){
				//変更時と、初期ロード時に呼び出される
				if (obj.shape != undefined && obj.shape.length > 0 &&
					obj.shape != "rectangle")
				{
					//マスキング
					shape.clear();
					shape.gotoAndStop(obj.shape);
					shape.hitArea = null;
					photo.setMask(shape);
					//マスキング
					if (shape._currentframe == 1){
						//無効な形
						//マスキングなし(SWF含む)
						shape._width = 0;
						shape._height = 0;
						photo.setMask(null);
						shape.hitArea = photo;
					}else{
						shape.hitArea = null;
						photo.setMask(shape);
					}

				}else{
					//マスキングなし(SWF含む)
					shape._width = 0;
					shape._height = 0;
					photo.setMask(null);
					shape.hitArea = photo;
				}
			}

			//読み込み
			if (pFlag.photoloading == 0){
				pFlag.photoloading = 1;	//読み込み中
				photo.picture.loadMovie(IMAGESERVER + "view.cgi?page=" + MyPage +
										"&fname=" + escape( obj.fname));
			}else{
				pFlag.setPhotoSize();//切り抜きを変えた時など
			}
			//透過処理
			if (obj.transparent != undefined){
				if (obj.transparent > 1 && obj.transparent < 100)
					photo._alpha = obj.transparent;
				else
					photo._alpha = 100;
			}

		}
		break;
	case "PLUGIN":
		//プラグイン
		if (obj.plugin != undefined){
			//FElement.gotoAndStop("plugin");
			var plugin = FElement.plugin;
			//pFlag.plugin = plugin;
			var fobject = plugin;
			pFlag.fobject = plugin;
			//ver 2.0ベータから2.0正式版への互換性
			obj.fname = Replace(obj.fname,".txt",".xml");
			m_DataList[num].fname = obj.fname;
			//ロード
			if (pFlag.photoloading == 0){
				pFlag.photoloading = 1;	//読み込み中
				plugin.loadMovie("plugins/" + obj.plugin + "/" + obj.plugin + ".swf?id=" + num +
							 "&bparam=" + obj.fname  + "&fname=" + obj.fname + "&page=" + MyPage);
				//bparamは過去との互換性維持のため
			}else{
				pFlag.setPhotoSize();
			}
		}
		break;
	}
	//選択オブジェクトならタブの位置調整
	if (isFlagSelected(num)){
		_root.Main.FlagSelect.showSelect();
	}
};


//-------------------------------------------------------//
//深度の設定
//-------------------------------------------------------//

function findFlagDepth(n){
	var i=0;
	for (i=0;i<m_DataList.length;i++){
		if (m_DataList[i].del == 0 && i != n){
			if (eval(i).areasize == eval(n).areasize){
				return true;
			}
		}
	}
	return false;
};

function setFlagDepths(pFlag){

	//深度を面積から求めて適用せよ！
	var areasize = 0;
	var obj = m_DataList[pFlag._name];

	switch (m_DataList[pFlag._name].tool){
	case "TEXT":
		//テキスト
		if ((pFlag.textbox._height == undefined || pFlag.textbox._height == 21.2) &&
			pFlag.waitT == undefined)
		{
			pFlag.waitT = setInterval(setFlagDepths,100);
			return; //無効
		}
		clearInterval(pFlag.waitT);
		areasize = pFlag.textbox._width * pFlag.textbox._height/10 * 0.6;	//テキストは８かけ
		break;
	case "SHAPE":
		//図形
		areasize = pFlag.shape._width * pFlag.shape._height/10;
		break;
	case "FILE":
		var fname = m_DataList[pFlag._name].fname;
		var ext = fname.substr(fname.lastIndexOf(".")+1);//拡張子
		if (ext != "jpg" && ext != "swf"){
			areasize = pFlag.fileicon._width * pFlag.fileicon._height/10;
		}else{
			areasize = pFlag.photo._width * pFlag.photo._height/10;
		}
		break;
	case "PLUGIN":
		areasize = pFlag.plugin._width * pFlag.plugin._height/10;
		break;
	}
	if (areasize > 90000){
		areasize = 90000;
	}
	pFlag.areasize = Math.floor(90000-areasize);
	var test = _root.Main.findFlagDepth(pFlag._name);
	while (test){
		pFlag.areasize += 1;
		test = _root.Main.findFlagDepth(pFlag._name);
	}
	//深度を設定
	pFlag.swapDepths(pFlag.areasize);

};

function isFlagSelected(num,id){
	//現在選択されているか
	for (var i=0;i<m_SelList.length;i++){
		if (id != undefined && m_DataList[m_SelList[i].num].id == id){
			return true;
		}
		if (num != undefined && m_SelList[i].num == num){
			return true;
		}
	}

	return false;

};

function moveFlagFocus(num,option){
	//選択
	if (!PageEdit || PageLock){
		return;//編集モードじゃない
	}

	if (num == -1 && oldfnum == num ){
		return;
	}
	if (num != -1 && m_toolname != "view"){
		return;//選択ツールではない
	}
	if (m_DataList[num].edit == "locked"){
		return;//ロックされている
	}

	var multi = "";  //複数選択オプション
	var added = null;
	var mainsel = oldmainsel;
	var with_sound = false; //変更があれば、音を鳴らすべし
	//Shiftキーありや？
	if (Key.isDown(Key.SHIFT) || Key.isDown(Key.CONTROL) || option == "shift"){
		//追加もしくは除去
		if (isFlagSelected(num)){
			multi = "remove";
		}else{
			multi = "add";
		}
	}else{
		//単独選択
		if (isFlagSelected(num)/* && m_SelList.length == 1*/){
			return;//処理しない
		}
		//現在の状態を吸着のため、記憶
		FlagSelect.saveAbsorbPoint();
	}


	//古いものの処理
	var textdeleted = false;
	var teststr="";
	//選択の解除
	var found = false;
	for (var i=m_SelList.length-1;i>=0;i--){
		var rm = false;
		if (m_SelList[i].num != num){
			if (multi == ""){
				rm = true;
			}else{
				var obj = eval("_root.Main."  + m_SelList[i].num);
				obj.killTextSelect(); //テキストならば
				teststr += "killtextsel" + m_SelList[i].num;
			}
		}else{
			if (multi == "remove"){
				rm = true;
			}
			found = true;
		}
		if (rm){
			var obj = eval("_root.Main."  + m_SelList[i].num);
			_root.Main.setFlagDepths(obj);//深度を再設定

			if (obj.textbox._visible){
				textdeleted = true;
			}

			//配列から削除せよ
			m_SelList.splice(i,1);
			mainsel = m_SelList[0].num;
			with_sound = true;
			obj.killTextSelect(); //テキストならば

		}
	}

	//新しいものの処理
	var obj = undefined;
	if (num >= 0 && multi != "remove"){
		setCursor(); //カーソル
		setTextSelect();
		obj = eval(num);
		obj.selected = true;	//選択せよ！（作成時）
		obj.setTextSelect();	//選択せよ！（既存テキスト）

		//今、配列になければ追加せよ
		if (!found/* || multi != "add"*/){
			var newsel = new Object();
			newsel.num = num;
			m_SelList.push(newsel);
			added = num;
			mainsel = num;
			with_sound = true;

		}
	}else{
		//選択の解除
		if (m_SelList.length <= 0){
			//入力フォーカスの消去
			resetFocus();

		}else{
			num = m_SelList[0].num;
			obj = eval(num);
		}
	}

	//地点情報のフォーカスが変わった。
	if (num >= 0 && option != "nosound" && with_sound){
		playSound("KASHA");
	}

	//選択枠の変更
	if (m_SelList.length > 0){
		if (option != "noselect"){
			_root.Main.FlagSelect.showSelect();
		}
	}else{
		_root.Main.FlagSelect._visible = false;
	}

	//メンバの記憶
	if (m_SelList.length > 0){
		oldfnum = num;
		curflag = obj;
	}else{
		oldfnum = -1;
		curflag = null;
	}

	//複数選択時にテキストボックスが含まれる場合は、フォーカス解除
	if ((textdeleted && m_SelList.length > 0 && num >= 0 && multi == "remove") || //削除
		(m_DataList[added].tool == "TEXT" && m_SelList.length > 1))//追加
	{
		resetFocus();

		clearInterval(waitd_id);
		waitd_id = setInterval(waitd,300);

	}

	//ツールセット切り替え
	setMiniTool();
	//リンク吹き出しを消す
	if (_root.Main.FlagLink._visible){
		_root.Main.FlagLink._visible = false;
	}

};

//入力フォーカスの消去(Timer仕様)
function waitd(){
	clearInterval(waitd_id);
	//入力フォーカスの消去
	resetFocus();
};


//-------------------------------------------------------//
//添付ファイルを開く
//-------------------------------------------------------//

function openFlagFile(num,isDownload){
	//ファイルを開く
//	System.useCodepage = true;
	var fname = m_DataList[num].fname;

	//SP2対応
	var tempVars = new LoadVars();
	if (isDownload == true){
		getURL(SERVER + "view.cgi?page="+ MyPage+"&save=1&fname="+escape(fname));
	}else{
		getURL(SERVER + "view.cgi?page="+ MyPage+"&fname="+escape(fname));

	}


};

//-------------------------------------------------------//
//オブジェクト操作
//-------------------------------------------------------//

function changeFlagMask(num,sname){
	//写真のマスク変更(すでに値が変更された後なり)
	if (_root.Main.IsFlagGuestLock(num)){
		return;	//ゲストは編集できない
	}
	var obj = new Object();	//差分を代入
	obj.shape = sname;
	_root.Main.showFlagObjectData(num,obj);
	//showObjectData(obj);	//適用
	_root.Main.updateFlag(num,obj);
};

function changeFlagBack(num,nextcolor){
	//背景色が変更された
	if (_root.Main.IsFlagGuestLock(num)){
		return;	//ゲストは編集できない
	}
	//保存
	var obj = new Object();	//差分を代入
	obj.bgcolor = nextcolor;
	_root.Main.showFlagObjectData(num,obj);
	_root.Main.updateFlag(num,obj);
};

function changeFlagTranslate(num){
	//透過が変更された
	if (_root.Main.IsFlagGuestLock(num)){
		return;	//ゲストは編集できない
	}
	var curv = m_DataList[num].transparent;
	if (curv == 50){
		curv = 100;
	}else{
		curv = 50;
	}
	var obj = new Object();	//差分を代入
	obj.transparent = curv;
	_root.Main.showFlagObjectData(num,obj);
	_root.Main.updateFlag(num,obj);

};


//-------------------------------------------------------//
//保存
//-------------------------------------------------------//

function IsFlagGuestLock(num,noalert){
	//ゲストが変更できない動作か？
	var author = m_DataList[num].author;
	//管理人以外は他人のページでは、他人の部品を操作できない
	if (PageAuthor != MyID && author != MyID &&
		MyPower != "admin")
	{
		if (!noalert){ //アラートする
			if (MyLang == "en"){
				ErrorMes("You couldn't edit objects in pages of others.");
			}else{
				ErrorMes("他人のページでは人の部品を編集できません。");
			}
		}
		return true;
	}

	if (m_DataList[num].edit == "locked"){
		if (!noalert){ //アラートする
			if (MyLang == "en"){
				ErrorMes("This object is locked. Please unlock it to edit.");
			}else{
				ErrorMes("この部品はロックされています。編集するには、解錠してください。");
			}
		}
		return true;
	}


	return false;

}

function deleteFlag(){
	//オブジェクトの削除

	//オブジェクトの削除
	var success = true;

	//現在の選択
	var curtime = getTm();
	for (var i=0;i<m_SelList.length;i++){
		if (!deleteInterFlag(m_SelList[i].num,curtime)){
			success = false;
		}
	}
	if (!success){
		if (MyLang == "en"){
			ErrorMes("You could not delete objects in pages of others.");
		}else{
			ErrorMes("他人のページでは人の書き込みは削除できませんでした。");
		}
	}
	moveFlagFocus(-1);

};

function deleteInterFlag(num,time){
	//オブジェクトの削除（内部呼び出し用）
	var author = m_DataList[num].author;

	if (IsFlagGuestLock(num,1)){
		//他人のページでは人のオブジェクトは削除できない
		//ロックされている
		return false;
	}

	eval(num)._visible = false;

	//保存
	var obj = new Object();
	obj.del = 1;
	updateFlag(num,obj,time);

	return true;

};

function cutFlag(del){
	//オブジェクトの切り取りorコピー
	if (m_SelList.length <= 0)
		return;

	//メンバをすべて移す
	var so = new SharedObject;
	so = SharedObject.getLocal("NOTA",localpath);
	var minselx = 0,minsely = 0;
	for (var i=0;i<m_SelList.length;i++){
		//一番上と左にあるオブジェクトの相対位置を記録
		if (m_SelList[i].sely < minsely){
			minsely = m_SelList[i].sely;
		}
		if (m_SelList[i].selx < minselx){
			minselx = m_SelList[i].selx;
		}
	}
	for (var i=0;i<m_SelList.length;i++){
		var obj = new Object();
		obj = m_DataList[m_SelList[i].num];
		obj.selx = m_SelList[i].selx-minselx; //選択されている中の相対位置
		obj.sely = m_SelList[i].sely-minsely;
		so.data["clip" + i] = obj;
	}
	so.data.cliplen = m_SelList.length;
	so.data.page = MyPage;
	so.data.myid = MyID; //操作している人
	var success = so.flush();
	delete so;

	if (success == true){
		//サウンド
		playSound("KASHA");
		if (del){
			//オブジェクトの削除
			var curtime = getTm();
			for (var i=0;i<m_SelList.length;i++){
				if (!deleteInterFlag(m_SelList[i].num,curtime)){
					success = false;
				}
			}
			if (!success){
				if (MyLang == "en"){
					ErrorMes("You could not delete objects in pages of others.");
				}else{
					ErrorMes("他人のページでは人の書き込みは削除できませんでした。");
				}
			}
			moveFlagFocus(-1);

		}
	}else{
		if (MyLang == "en"){
			ErrorMes("Cut / Copy failure.");
		}else{
			ErrorMes("切り取り、またはコピーできませんでした。");
		}
	}

};

function pasteFlag(del){
	//貼り付け
	if (PageLock){
		//凍結されています。
		if (MyLang == "en"){
			ErrorMes("This page is locked. Only administrators can edit this page.");
		}else{
			ErrorMes("このページは凍結されています。管理者以外は編集できません。");
		}
		return;
	}

	var so = new SharedObject;
	so = SharedObject.getLocal("NOTA",localpath);

	//メンバをすべて移す
	if (so.data.cliplen != null && so.data.myid == MyID){
		moveFlagFocus(-1);
		for (var i=0;i<so.data.cliplen;i++){
			var obj = new Object();
			obj = so.data["clip" + i];
			obj.id = getTm()+i;
			obj.del = 0;
			obj.author = MyID;
			//中心位置
			var mid = new Object();
			mid.x = (Stage.width)/2-150;
			mid.y = (Stage.height)/2-150;
			_root.Main.globalToLocal(mid);
			obj.y = mid.y+obj.sely; //Y位置のみ現在地に合わせる

			//ファイルの場合はコピーを行う
			if (obj.tool == "FILE" || obj.tool == "PLUGIN"){
				var fname = obj.fname;
				var srcpage = so.data.page;
				CopyVars = new LoadVars();
				CopyVars.obj = obj;
				CopyVars.onLoad = onLoadCopyVars;
				CopyVars.load(SERVER + "upload.cgi?action=copy&fname=" + escape(fname) +
							"&srcpage=" + srcpage + "&page=" + MyPage);
			}else{
				//保存処理
				updateFlag(-1,obj);
				//貼り付けて表示
				var num = m_DataList.length-1;
				loadFlag(num);
				//選択
				moveFlagFocus(num,"shift");
			}
		}
	}

	delete so;

};

onLoadCopyVars = function(success){
	//ファイル名が帰ってくる
	var obj = this.obj;  //thisはCopyVarsが入る
	if (!success || this.res == "ERR"){
		if (MyLang == "en"){
			ErrorMes("Copying file failure.");
		}else{
			ErrorMes("ファイルのコピーに失敗しました。");
		}
		return;
	}
	//名前の決定
	if (this.newfname != undefined && this.newfname != ""){
		obj.fname = this.newfname;
	}else{
		var myDate = new Date;
		obj.fname = Math.round(myDate.getTime()) + ".xml";
	}
	//保存処理
	updateFlag(-1,obj);
	//貼り付けて表示
	var num = m_DataList.length-1;
	loadFlag(num);
	//選択
	moveFlagFocus(num,"shift");
};
function getPageTitle(){
	//頁のタイトルを取得し、変数に代入
	var i=0;
	var ytop = -1;
	var num = -1;
	var tt;
	var pagetitle = "";
	for (i=0;i<m_DataList.length;i++){
		var obj = m_DataList[i];
		if (obj.tool == "TEXT" && obj.del != 1 &&
			obj.text != "")
		{
			tt = eval(i);
			//テキストかつもっとも上に位置するもの
			if (tt._y < ytop || ytop == -1){
				ytop = tt._y;
				num = i;
			}
		}
	}
	if (num == -1){
		//テキストが無かった
		pagetitle = "(タイトルなし)";
	}else{
		//テキストをテキストボックスから代入
		tt = eval(num);
		IsTextBoxInClient(num,true);
		pagetitle = tt.textbox.text;
		if (pagetitle.length < 1){
			pagetitle = "(タイトルなし)";
		}
		//一行目のみ代入
		var re = pagetitle.indexOf("\r");
		if (re == -1 || re > 30){ re = 30; }
		pagetitle = pagetitle.substr(0,re);//30文字まで送る
	}
	//値を返す
	var changed = false;
	if (MyPageTitle != pagetitle && pagetitle != ""){
		if (_global.MyPageTitle != undefined){
			changed = true;
		}
		_global.MyPageTitle = pagetitle;

	}
	return changed;

};


////////////////////////////////////////////////////////////////////////
//
//
//ページの移動と縮尺の変更
//
//
////////////////////////////////////////////////////////////////////////





function loadMapPosition(){
	//地図の初期位置読み込み
	//将来的には、SharedObjectを使って、場所を記憶する

	//全体の大きさ
	var stageW = Stage.width-ML-17;
	var stageH = Stage.height-MT-17;

	//地図の位置情報を読み出す
/*	so = new SharedObject;
	so = SharedObject.getLocal("mapdata",localpath);


	//初期位置
	if (so.data.mapx == undefined || PageEdit != true){
		//標準値
//		changeMapScale(60,2750,1920);//御所が真ん中に来る！
//		changeMapScale(100,0,0);//御所が真ん中に来る！

	}else{
		//適用（スケールだけ）
		this._xscale = so.data.scale;
		this._yscale = so.data.scale;
		//地図が小さすぎる場合
//		minsc = stageW / PaperW * 100;
//		if (_root.Main._xscale < minsc){
//				_root.Main._xscale = minsc;
//				_root.Main._yscale = minsc;
//		}
	}
*/
	if (Stage.width != null){
		var yokosc = stageW / PaperW * 100;//幅いっぱい
		if (yokosc < MIN_SC)//MIN_SC以下はちょっと視認性が落ちるので、やばい。
			yokosc = MIN_SC;
		else
			_global.PageReal = true;//全幅表示
		if (yokosc > MAX_SC)
			yokosc = MAX_SC;

		this._xscale = yokosc;
		this._yscale = yokosc;
	}
    moveMap(ML,MT);


};

function saveMapPosition(){
	//地図の位置情報を保存

};

function setPoint(){
	//初期位置を代入
	startm.x = _root._xmouse;
	startm.y = _root._ymouse;
	startp.x = _root.Main._x;
	startp.y = _root.Main._y;

};

function moveMap(x,y,setscroll){
	//地図の移動
	var mapw = PaperW * _root.Main._xscale / 100;
	var maph = PaperH * _root.Main._xscale / 100;

	var limit = false;

	//全体の大きさ
	var stageW = Stage.width-ML-17;
	var stageH = Stage.height-MT-17;

	//横
	if (mapw <stageW ){
		//中心に
		x = (stageW-mapw)/2+ML;
	}else if (x > ML){
		x = ML;
		limit = true;
	}else if(x < stageW+ML-mapw) {
		x = stageW+ML-mapw;
		limit = true;
	}

	//縦
	if (maph < stageH){
		//中心に
		y = MT;
		limit = true;
	}else if (y > MT){
		y = MT;
		limit = true;
	}else if(y < stageH+MT-maph) {
		y = stageH+MT-maph;
		limit = true;
	}
	//適用
	_root.Main._x = x;
	_root.Main._y = y;
	//スクロールサイズ
	if (setscroll != false)
		setScrollPos();

	//テキストオブジェクトの表示制御
	showTextBoxInClient();

	//頁番号を更新
	updatePageNum();


	return limit;//制限値を超えているか返す
};

function updatePageNum(){

	//頁番号を出力
	var stageH = Stage.height-MT-17;

	//現在どのページを表示しているか？

	//一頁のサイズが分かればよい
	page_num = 1+Math.floor(-(_root.Main._y-MT-stageH/2)/(PageH*_root.Main._xscale/100));

	if (page_num > page_cnt){
		page_num = page_cnt;
	}else if (page_num < 1){
		page_num = 1;
	}
	_root.statusbar.pagenum = "(" + page_num + "/" + page_cnt + ")"

}


function changeMapScale(newscale,x,y,sound){
	oldscale = _root.Main._xscale;

	//全体の大きさ
	var stageW = Stage.width-ML-17;
	var stageH = Stage.height-MT-17;
	//中心位置
	if (x == null){
		mapcnt = new Object();
		mapcnt.x = stageW/2;
		mapcnt.y = stageH/2;
		_root.Main.globalToLocal(mapcnt);
		x = mapcnt.x;
		y  = mapcnt.y;
	}
	//切り替える
	if (sound != false){
		playSound("PAGE");
	}
	_root.Main._xscale = newscale;
	_root.Main._yscale = newscale;
	//切り替え後の場所を適正に保つ
	nextx = stageW/2 - x*newscale/100;
	nexty = stageH/2 - y*newscale/100;
	moveMap(nextx,nexty);

	//旗に対して、スケール変更通知（作成者情報のサイズ変更）
	FlagSelect.setAuthHeight();

	//ステータスバー更新
	curscale = Math.floor(newscale);
	_root.statusbar.scale = curscale + "%";

	//設定保存
	saveMapPosition();

	yokosc =stageW / PaperW * 100;//幅いっぱい
	if (yokosc > MAX_SC)
		yokosc = MAX_SC;
	_global.PageReal = (newscale == yokosc);//最大倍率であることを記憶


};

function Scroll(per,horizontal){
	//スクロールバーがドラッグされた
	oldx = _root.Main._x;
	oldy = _root.Main._y;

	//マップの大きさ
	var mapw = PaperW * _root.Main._xscale / 100;
	var maph = PaperH * _root.Main._xscale / 100;
	//全体の大きさ
	var stageW = Stage.width-ML-17;
	var stageH = Stage.height-MT-17;

	//計算
	if (horizontal)
		moveMap(ML-(mapw-stageW)*per/100,oldy,false);
	else
		moveMap(oldx,MT-(maph-stageH)*per/100,false);



}

function setScrollPos(){

	//マップの大きさ
	var mapw = PaperW * _root.Main._xscale / 100;
	var maph = PaperH * _root.Main._xscale / 100;
	//全体の大きさ
	var stageW = Stage.width-ML-17;
	var stageH = Stage.height-MT-17;

	//スクロールバーのサイズ変更
	_root.ScrollV._x = stageW+ML;
	_root.ScrollV._y = MT;

	if (maph == stageH){
		_root.ScrollV.setPos( -1,-1,
							  stageH+MT,false);

	}else{
		_root.ScrollV.setPos( (MT-_root.Main._y)/(maph-stageH/*+MT*/)*100,
							  (stageH+MT)/maph*100,
							  stageH/*+MT*/,false);
	}

	_root.ScrollH._y = Stage.height;
	_root.ScrollH._x = ML+85;
	_root.statusbar._x = 0;
	_root.statusbar._y = Stage.height-1-16;

	if (mapw == stageW){
		_root.ScrollH.setPos(-1,-1,stageW-85,true);
	}else{
		_root.ScrollH.setPos((ML-_root.Main._x)/(mapw-stageW)*100,
							(stageW)/mapw*100,
							  stageW-85,true);
	}


};

function resizePageH(){
	//現在配置されているオブジェクトにあわせて、ページ数を調整する
	//現在使用中のページ＋１ページが基本
	clearInterval(rsintervalID);
	rsintervalID = null;

	var i=0;
	var ytop = -1;
	//手書き線以外
	for (i=0;i<m_DataList.length;i++){
		var obj = m_DataList[i];
		if (obj.del != 1){
			var y =0;
			if (obj.tool == "PLUGIN"){
				y = eval(i)._y+eval(i).plugin._height;
			}else if (obj.tool == "TEXT"){
				y = eval(i)._y+eval(i).textbox._height;
				if (y < eval(i)._y+Math.abs(m_DataList[i].height) && m_DataList[i].height > 0){
					y = eval(i)._y+Math.abs(m_DataList[i].height);
				}
			}else if (obj.tool == "FILE" || obj.tool == "SHAPE"){
				y = eval(i)._y+eval(i).shape._height;
			}
			if (y > ytop && y != undefined){
				ytop = y-0;
			}
		}

	}
	//手書き線の下端
	var pen_bounds = new Object;
	if (canvasDef._height > 0){
		var pen_bounds = canvasDef.getBounds(_root.Main);
		if (pen_bounds.yMax > ytop){
			ytop = pen_bounds.yMax;
		}
	}

	page_cnt = Math.floor(ytop / PageH)+1;
	if (page_cnt < 1){
		page_cnt = 1;
	}
	var espace = 0;
    //編集モードなら、次ページ作成のためのスペースを用意
    espace = PageH/2;

	if (PaperH != page_cnt*PageH + espace){
		_global.PaperH = page_cnt*PageH + espace;
		backboard._height = PaperH - espace;
		Canvas._height = PaperH;

		//もし、ページ数を減らす場合で、スクロール位置がおかしいなら
		setScrollPos();
	}
	canvasLine.clear();
	//影
	canvasLine.lineStyle(3,0x999999,100);
	canvasLine.moveTo(Number(PaperW)+1,3);
	canvasLine.lineTo(Number(PaperW)+1,page_cnt*PageH+1);//縦
	canvasLine.lineTo(3,page_cnt*PageH+1);//縦
	//ページ横縦
	canvasLine.lineStyle(1,0x999999,100);
	canvasLine.moveTo(0,-1);//一番上の線
	canvasLine.lineTo(PaperW,-1);

	//ページ区切り
	for (i=1;i<=page_cnt;i++){
		canvasLine.moveTo(0,i*PageH);//下の境界
		canvasLine.lineTo(PaperW,i*PageH);

		canvasLine.moveTo(0,(i-1)*PageH);//縦線２本
		canvasLine.lineTo(0,i*PageH);
		canvasLine.moveTo(PaperW,(i-1)*PageH);
		canvasLine.lineTo(PaperW,i*PageH);
	}

	//頁番号を更新
	updatePageNum();

};



function prepareForScroll(isstart){
	//ページスクロール前の準備をする
	if (idmh){
		clearInterval(idmh);
		idmh = null;
	}

	if (!oldpageweight){
		oldpageweight = getPageWeight();
	}

	if (isstart){
		//スクロール開始
		if (oldpageweight > 60){
			_quality = "LOW";
		}else if (oldpageweight > 10){
			_quality = "MEDIUM";
		}


		_root.minitool._visible = false;

		mhprogress = 0;

	}else{
		//スクロールストップ
		_quality = "HIGH";
		if (PageEdit){
			_root.minitool._visible = true;
		}

	}

}

function getPageWeight(){
	//一頁の重さを計測する
	var pageweight = 0;
	for (var i=0;i<m_DataList.length;i++){
		if (m_DataList[i].del != 1){
			var wt = 0;
			switch (m_DataList[i].tool){
			case "SHAPE":
				wt = 0.3;
				break;
			case "PLUGIN":
				wt = 2;
				break;
			case "DRAW":
				wt = 0.2;
				break;
			case "TEXT":
				var len = eval(i).textbox.length;
				if (len > 100){
					wt = Math.round(len/100);
				}else{
					wt = 1;
				}
				break;
			default:
				wt = 1;
				break;
			}
			pageweight += wt;
		}
	}

	if (pageweight > 100){
		_root.statusbar.pageWeight._xscale = 100;
	}else{
		_root.statusbar.pageWeight._xscale = pageweight;

	}

	return pageweight;
};

function changePageBack(nextcolor,save){
	//背景色が変更された
	if (save){
		if (_root.Main.IsFlagGuestLock(num)){
			return;	//ゲストは編集できない
		}
	}
	if (nextcolor == undefined){
		nextcolor = "0xFFFFFF";
	}

	//背景色を変更
	var myColor  = new Color(_root.Main.backboard);
	myColor.setRGB(nextcolor);

	_root.Main.pagebgcolor = nextcolor;

	//保存
	if (save){
		var obj = new Object();	//差分を代入
		obj.bgcolor = nextcolor;
		_root.Main.updateFlag("head",obj);
	}

};

////////////////////////////////////////////////////////////////////////
//全体のサイズ変更イベントハンドラ
/////////////////////////////////////////////////////////////////////////

stageListner = new Object();
stageListner.onResize = function(){

	//全体の大きさ
	var stageW = Stage.width-ML-17;
	var stageH = Stage.height-MT-17;
	//地図のサイズを合わせて変更
	//ムービーの大きさが変更された
	var minsc = stageH / PaperH * 100;

	if (_root.Main._xscale < minsc){
		_root.Main._xscale = minsc;
		_root.Main._yscale = minsc;
	}

	//必要ならば、移動
	var curx = _root.Main._x;
	var cury = _root.Main._y;
	moveMap(curx,cury);
	//	moveMap(0,0);

	//スクロールサイズをあわせる
	setScrollPos();

	//背景のリサイズ
	_root.back._width = Stage.width;
	_root.back._height = Stage.height;

	//倍率補正
	if (PageReal){
		yokosc = stageW / PaperW * 100;//幅いっぱい
		if (yokosc > MAX_SC)
			yokosc = MAX_SC;
		changeMapScale(yokosc,null,null,false);
	}

};
Stage.addListener(stageListner);


////////////////////////////////////////////////////////////////////////
//backboard イベントハンドラ
/////////////////////////////////////////////////////////////////////////

backboard.onRollOver  = function() {
	//カーソル変更
	setCursor();
};



backboard.onPress = function(){

	//全体の大きさ
	var stageW = Stage.width-ML-17;
	var stageH = Stage.height-MT-17;

	if (!getEditMode()/* && oldfnum == -1*/){


		//地図を移動開始
		PageDragging = true;
		if (!isMacOS){
			showMyCursor(true,"hand");
		}
		setPoint();//現在地点

		prepareForScroll(true);//スクロール準備

	}
};


lasttime = 0;
backboard.onMouseMove = function(){
	//地図を移動
	if (PageDragging){
		//時間が詰まり過ぎていれば、無視
		//この値をページの重さに応じて変えるのが妥当
		var spantime  = (getTimer() - lasttime);
		if (spantime < 30){
			return;
		}

		var nextx = startp.x + (Math.round((_root._xmouse- startm.x)/10)*10 );
		var nexty = startp.y + (Math.round((_root._ymouse- startm.y)/10)*10 );
		//制限内か検査
		if (oldnextx != nextx || oldnexty != nexty){
			var limit = moveMap(nextx,nexty);
			oldnextx = nextx;
			oldnexty = nexty;
			//初期位置代入
			if (limit)	setPoint();
			lasttime = getTimer();
			updateAfterEvent();
		}

	}
};

backboard.onRelease = function(){
	//ドラッグの終了
	if (!getEditMode()){
		//選択を解除

		if (oldfnum >= 0){
			moveFlagFocus(-1);
		}
		if (PageDragging){
			PageDragging = false;

			prepareForScroll(false); //スクロール準備終了
			//場所保存
			saveMapPosition();

			//カーソルを元に戻す
			showMyCursor(false);

		}

	}
};


backboard.onReleaseOutside= backboard.onRelease;


