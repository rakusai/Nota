/*
 * 
 * dlg_signup
 * サインアップダイアログ
 * 
 */

stop();


//新規ユーザー登録
pDlg = this;
DlgBack.draggable = true;//入力文字制限
user.restrict = "0-9a-zA-Z_@.\¥-";
pass.restrict = "0-9a-zA-Z_@.\¥-";

user.text = "";
pass.text = "";

showDlg();

function showDlg(){
	//ダイアログの表示
	if (MyLang == "en"){
		dlg_signup_title = "Welcome";
		dlg_signup_message = "NOTA allow you to create, organize and edit directly on the web. Just fill out the account information below, then click [Sign Up]."
		dlg_signup_user = "UserID：";		
		dlg_signup_pass = "Password：";		
		dlg_signup_ok = "Sign Up";
		dlg_signup_cancel = "Cancel";
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

	//アカウント作成
	doEntry();
	
};

cancelbtn.onRelease = function(){
//	//ダイアログを閉じる
//	pDlg.gotoAndStop("close");
	//ダイアログを元に戻す
	pDlg.gotoAndStop("edit");
	
};
delbtn.onRelease = cancelbtn.onRelease;

function doEntry(){
	//認証へ
	myRecordVars = new LoadVars();
	myRecordVars.action = "record";
	myRecordVars.param = "add";
	myRecordVars.name = user.text;
	myRecordVars.password = pass.text;
	myRecordVars.power = "member";
//	myRecordVars.autologin = autologin.selected;
	myRecordVars.onLoad = onRecordLoad;

	myRecordVars.sendAndLoad(SERVER + "account.cgi",myRecordVars);

	
};
function onRecordLoad(success){

	//データが読み込まれた！
	confirmAccount = false; //認証終了
	if (!success || myRecordVars.res == "ERR")
	{
		//ページが見つからない
		if (MyLang == "en"){
			ErrorMes("This User ID has already taken.");
		}else{
			ErrorMes("そのユーザーIDはすでに取られています。");
		}
		return;
	}
	
	//通った
	if (MyLang == "en"){
		ErrorMes("You got an account successfully. ",false);
	}else{
		ErrorMes("ユーザー登録が完了しました。",false);
	}
	
	//ダイアログを元に戻す
	pDlg.gotoAndStop("edit");
	

}
