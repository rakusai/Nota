/*
 * 
 * dlg_linklist
 * リンク生成ダイアログ
 * 
 */

menu = this;

DlgBack.useHandCursor = false;
DlgBack.onPress = function(){
	
};

if (MyLang == "en"){
	dlg_url = "The outside URL :";
	dlg_message = "Link : select a page or enter a outside \nURL to link."
}

//入力文字制限（ (！) から（チルダ) までの文字のみを入力できます）
url_txt.restrict = "¥u0021-¥u007E";
//現在のページを見る
			
//ページを追加
//setList();
hrefList.setStyle("rollOverColor","0x6FB8DB");

hrefList.setStyle("textSelectedColor","0xFFFFFF");
hrefList.setStyle("selectionColor","0x3399CC");
hrefList.setStyle("backgroundColor","0xD8F4FE");
hrefList.setStyle("borderStyle","none");
//hrefList.setStyle("backgroundColor","0xC8ECF2");

//ページ一覧をコンボにセット
function onLoadPageData(success){
	//ページの一覧を読み込んだ
	if (!success || _root.m_PageVars.res == "ERR"){
		if (MyLang == "en"){
			ErrorMes("Fail to get a list of pages.");//確認
		}else{
			ErrorMes("ページの一覧の読み込み失敗");
		}
		return;	
	}

	//コンボに追加
	var i=0;
	while (_root.m_PageVars["id" + i].length > 0){
		if (_root.m_PageVars["title"+i].length < 1){
			if (MyLang == "en"){
				_root.m_PageVars["title"+i] = "(Untitled)";	
			}else{
				_root.m_PageVars["title"+i] = "(タイトルなし)";	
			}
		}
		var title = _root.m_PageVars["title"+i];
		hrefList.addItem(title);
		i++;
	}
	oldloadpage = MyPage;

	

};

function setList(){
	//リストに文字代入
	hrefList.removeAll();
	var i=0;
	if (MyLang == "en"){
		hrefList.addItem("【Link to New Page】");
		hrefList.addItem("【Remove Link】");
	}else{
		hrefList.addItem("【新規ページを作成】");
		hrefList.addItem("【リンクを解除】");
	}
	//ページ一覧を読み込む
	if (oldloadpage != MyPage){
		_root.m_PageVars = new LoadVars();
		_root.m_PageVars.onLoad = onLoadPageData;
		_root.m_PageVars.load(SERVER + "read.cgi?action=getfiles");
	
	}else{
		onLoadPageData(true);
	}
	//URL入力欄の処理
	var seltext = menu._parent.SelText;
	if (seltext.substr(0,7) == "http://"){
		url_txt.text = seltext;
	}else{
		url_txt.text = "http://";
	}
};

listenerObject = new Object();
listenerObject.change = function(eventObject){
  // 必要なコードをここに記述
  

	//選択がクリックされた
//	var LH = dammy_txt.textHeight;
	var indx = hrefList.selectedIndex;//Math.floor(((_ymouse)/LH));
	if (indx == null)
		return;
	//テキストの最初の行
//	indx += link_txt.scroll-1;//スクロール行数を考慮
	//表示を消す
	menu._visible = false;
	//呼び出しもとの関数を呼び出す
	if (indx == 0){
		//新規ページ作成（選択中のテキストをタイトルにする）
		_root.createNewPage("home",_parent.SelText,onNewPage);

	}else if (indx > 1){
		//リンクを設定
		var page = _root.m_PageVars["id" + (indx-2)];
		var title = _root.m_PageVars["title" + (indx-2)];
		menu.source.selectLink("" + page,title);
	}else{
		//リンクを解除
		menu.source.cancelLink();
	}
  
};
hrefList.addEventListener("change", listenerObject)

function onNewPage(success){
	//新しいページへリンクを張る
	if (success && this.res != "ERR"){
		//テキストにリンク設定
		menu.source.selectLink("" + this.page,this.title);
		//一覧を更新
		_root.updateSidebar();
	}else{
		//編集権限なし
		if (MyLang == "en"){
			ErrorMes("You have no authority to create new pages.");
		}else{
			ErrorMes("新規ページの作成に失敗しました。権限がありません。");
		}
	}
	
}

okbtn.onRelease = function(){
	//外部URLへのリンクを貼る
	var url = url_txt.text;
	var enurl = url;
//	enurl = Replace(enurl,"&","$amp;");	//特殊エンコードlink.cgi?page=urlのurlに=&があると動作しないから
//	enurl = Replace(enurl,"=","$equal;");
	
	//表示を消す
	menu._visible = false;
	//呼び出しもとの関数を呼び出す
	menu.source.selectLink(enurl,url);
	
}