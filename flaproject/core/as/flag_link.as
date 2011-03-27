/*
 * 
 * flag_link
 * リンク操作
 * 
 */

pThis = this;

btnLinkJump._visible = false;
linktarget._visible = false;
linktarget.gotoAndStop(1);


function jumpUrl(surl){
	//内部クリックから、ページを移動する
	url = surl;
	this._visible = true;
	this._x = dblClickTextPtX;
	this._y = dblClickTextPtY;
	if (PageEdit == true){
		//編集モードで、クリックしたら
		if (!dblClickText){ 
			//説明表示
			btnLinkJump._visible = true;
			if (surl.substr(0,3) == "./?"){
				surl = surl.substr(3);
			}else if (surl.substr(0,7) == "http://"){
				surl = surl.substr(7);
			}
			
			btnLinkJump.dlg_url = surl; //URLを表示
			linktarget._visible = false;
			//3秒で消える
			clearInterval(openid);
			openid = setInterval(timerOpenUrl,3000,false);
			return;
		}
	}
	//閲覧モードなら、直ぐにジャンプ
	btnLinkJump._visible = false;
	linktarget._visible = true;
	linktarget.gotoAndPlay(1);
	//間を空けてジャンプ
	clearInterval(openid);
	openid = setInterval(timerOpenUrl,200,true);

}

function timerOpenUrl(isshow){
	clearInterval(openid);
	
	if (isshow){
		//リンクを開く
		getURL(url);
		//3秒で消える
		openid = setInterval(timerOpenUrl,3000,false);
	}else{
		//表示を消す
		pThis._visible = false;
	}
		
}