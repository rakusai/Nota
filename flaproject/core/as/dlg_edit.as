/*
 * 
 * dlg_edit
 * 編集開始ダイアログ
 * 
 */
 
//編集モードへ
pDlg = this;
DlgBack.draggable = true;//入力文字制限
user.restrict = "0-9a-zA-Z_@.\¥-";
pass.restrict = "0-9a-zA-Z_@.\¥-";

user.text = "";
pass.text = "";

showDlg();

function showDlg(){
	//ダイアログの表示
	switch(_root.commandAfterEdit){
	case "newpage":
	case "copypage":
		if (MyLang == "en"){
			dlg_edit_title = "■Create New Page";
		}else{
			dlg_edit_title = "■新しいページを作成";
		}
		//ツール選択
		for (var i=0;i<PluginList.length;i++) {
			PluginList[i].onSelectTool("newPage");		//ツールの表示を更新
		}	
		break;
	case "deletepage":
		if (MyLang == "en"){
			dlg_edit_title = "■Delete Page";
		}else{
			dlg_edit_title = "■ページの削除";
		}
		//ツール選択
		for (var i=0;i<PluginList.length;i++) {
			PluginList[i].onSelectTool("deletePage");		//ツールの表示を更新
		}					
		break;
	default:
		if (MyLang == "en"){
			dlg_edit_title = "■Edit Page";
		}else{
			dlg_edit_title = "■ページの編集";
		}
		//ツール選択
		for (var i=0;i<PluginList.length;i++) {
			PluginList[i].onSelectTool("editStart");		//ツールの表示を更新
		}					
		break;
	}
	
	if (MyLang == "en"){
		dlg_edit_message = "Enter your UserID and Password.";
		dlg_edit_user = "UserID：";		
		dlg_edit_pass = "Password：";		
		dlg_edit_autologin = "Remember my account";
		dlg_edit_cancel = "Cancel";
		dlg_edit_signup = "Click\rHere for\rSign Up";
	}
	
	//参加条件と公開レベル
	signupBtn._visible = (MyAnonymous == "signup");
	edit_signup_txt._visible = (MyAnonymous == "signup");
	
	//前回のユーザーID
	so = new SharedObject;
	so = SharedObject.getLocal("NOTA");
	if (so.data.autologin != undefined){
		autologin.selected = so.data.autologin;
	}
	if (so.data.userid != undefined){
		user.text  = so.data.userid;
		pass.text = so.data.pass;
	}
	
	//フォーカス
	Selection.setFocus("_root.DialogBox.user");

}

okbtn.onRelease = function(){
	//IDとパスワードを送り、確認
	if (user.length == 0 || pass.length == 0){
		if (MyLang == "en"){
			ErrorMes("Please enter your UserID and Password.");
		}else{
			ErrorMes("ユーザーIDとパスワードを入力してください。");
		}
		return;
	}
	
	//認証中か？
	if (confirmAccount == true){
		return;
	}
	confirmAccount = true;

	//編集モードへ
	doEdit();
	
};

signupBtn.onRelease = function(){
	//新規ユーザー登録
	gotoAndStop("signup");
}


cancelbtn.onRelease = function(){
	//ダイアログを閉じる
	pDlg.gotoAndStop("close");
	
};
delbtn.onRelease = cancelbtn.onRelease;


function doEdit(){
	//編集モードへ
	myEditVars = new LoadVars();
	myEditVars.action = "certify";
	myEditVars.mode = "edit";
	myEditVars.user = user.text;
	myEditVars.pass = pass.text;
	myEditVars.autologin = autologin.selected;
	myEditVars.onLoad = onAccountLoad;

	myEditVars.sendAndLoad(SERVER + "account.cgi",myEditVars);

	
};
function onAccountLoad(success){

	//データが読み込まれた！
	confirmAccount = false; //認証終了
	if (!success || myEditVars.res == "ERR" || 
		myEditVars.user == undefined || myEditVars.power == undefined)
	{
		//ページが見つからない
		if (MyLang == "en"){
			ErrorMes("UserID or Password are not correct. Please try again.");
		}else{
			ErrorMes("認証に失敗しました。IDかパスワードのどちらかが正確ではありません。");
		}
		return;
	}
	
	
	so = new SharedObject;
	so = SharedObject.getLocal("NOTA");
	if (autologin.selected){
		so.data.userid = user.text;
		so.data.pass = pass.text;
		so.data.autologin = true;
	}else{
		//記憶しないなら、すべて消去
		so.data.userid = null;
		so.data.pass = null;
		so.data.autologin = false;
	}
	so.flush();
	
	
	//通った
	//ダイアログを閉じる
	pDlg.gotoAndStop("close");
	
	//Tab更新
	getURL("javascript:setEditMode('true','" + myEditVars.user + "','" + myEditVars.power + "');");
	
	//編集モード
	if (PageEdit != true){
		_root.setEditMode(true,myEditVars.user,myEditVars.power);
	}
	//第3者閲覧が禁止されているなら
	if (myEditVars.anonymous == "none"){
		//強制的に読み込み
		_root.Main.LoadMapData();
		//一覧更新 -> JS:setEditMode内で実行
	}else{
		//編集可能か
		_global.PageLock = (PageDatEdit == "admin" && MyPower != "admin");
		
		if (PageLock){
			if (PageEdit){
				//ページがロックされていることを通知
				if (MyLang == "en"){
					ErrorMes("This page is locked. Only administrators can edit this page.");
				}else{
					ErrorMes("このページは凍結されています。管理者以外は編集できません。");
				}
			}
		}	
	}

}
