/*
 * 
 * init1
 * グローバルの第1フレーム
 * 
 */
 
 stop();

/////////////////////////////////////////////
//初期化
/////////////////////////////////////////////
Stage.scaleMode = "noScale"; //自動縮尺なし
Stage.showMenu = false; //メニューを表示しない
_focusrect = false; //フォーカス矩形なし


/////////////////////////////////////////////
//Flashバージョンチェック
/////////////////////////////////////////////

var flashver = getVersion();
if (flashver != undefined){
	var current_target = flashver.split(",");
	flashver = current_target[0].split(" ")[1];
}

/////////////////////////////////////////////
//ローディング表示
/////////////////////////////////////////////

//タイマースタート
myDate = new Date;
startTime = myDate.getTime();

mnintervalID = setInterval(onLoadTimer,100);

function onLoadTimer(){
	
	//現在どこまで読み込んだか
	var gLoad = Math.round(_root.getBytesLoaded()/_root.getBytesTotal()*100);
				
	if (gLoad >= 100){
		//ロード完了
		clearInterval(mnintervalID);
		gotoAndStop(2);		
	}else if (gLoad != oldgLoad){
		//一定期間が経過してから
		currentTime = myDate.getTime();
		
		if (currentTime - startTime > 200){
			LoadingArea._y = 150;
			LoadingArea.gotoAndStop(gLoad);
			LoadingArea.LoadingCircle.t = gLoad + "%"; 
		}
	}	
	oldgLoad = gLoad;
	
};
