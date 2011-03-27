/*
 * 
 * dlg_delete
 * ページ削除ダイアログ
 * 
 */
 
pDlg = this;
DlgBack.draggable = true;
showDlg();

function showDlg(){
	//ダイアログの表示
	if (MyLang == "en"){
		dlg_delete_title = "■Delete Page";
		dlg_delete_message = "Press OK to delete current page.";
		dlg_delete_cancel = "Cancel";
	}
	
	//ファイル名の表示
	if (MyLang == "en"){
		dlg_delete_text = "Are you sure you delete current page \""
							+ MyPageTitle + "\"?";
	
	}else{
		dlg_delete_text = "「" + MyPageTitle + 
		"」を削除します。よろしければ[OK]をクリックしてください。";
	}	
	
	//ツール選択
	for (var i=0;i<PluginList.length;i++) {
		PluginList[i].onSelectTool("deletePage");		//ツールの表示を更新
	}

}

okbtn.onRelease = function(){
	//ＯＫが押された
	
	//実際にページを削除する
	vars = new LoadVars();
	vars.action = "rmpage";
	vars.page = MyPage;
	//消した後に開くべきページは？
//	delpage = MyPage;
//	var nextID = _root.List.findNextID();
	vars.onLoad = onDeletePage;
	vars.sendAndLoad(SERVER + "write.cgi",vars);		
	
}

cancelbtn.onRelease = function(){
	//キャンセルが押された
	pDlg.gotoAndStop("close");
	
}
delbtn.onRelease = cancelbtn.onRelease;

function onDeletePage(success){
	
	//ダイアログを閉じる
	pDlg.gotoAndStop("close");
	
	if (success && vars.res != "ERR"){
		//トップのページを開く
		getURL(SERVER + "./");
		
//				var tab_lc = new LocalConnection();
//				tab_lc.send("tab" + SDIR,"selectTab",1,"home");
//				getURL("sidebar.cgi?page=" + "home","list");
//		_root.Main.openPage("home");
		//一覧からアイテムを消す(Javascriptで)
//		var list_lc = new LocalConnection();
//		list_lc.send("list" + SDIR,"setSelect","home",delpage);
	
//				getURL("link.cgi?url=home","link");
//				_root.Main.openPage("home");

	}else{
		if (MyLang == "en"){
			ErrorMes("You have no authority to delete this page.");
		}else{
			ErrorMes("ページを削除できません。削除権限がありません。");//確認
		}
	}
	
}