/*
 * 
 * scrollbar
 * スクロールバー
 * 
 */

thisH = 0;
barH = 0;

if (this._name == "ScrollH"){
	horizontal  = true;
}else{
	horizontal  = false;
}

//なぜかここで、スクロール位置を初期化
_root.Main.setScrollPos();

/*
if (horizontal){
	barback._x = -0.5;
}
*/
function setPos(pos,a_size,a_all,ishorizontal){
	//サイズと、場所を報告させる
	thisH = a_all-34;
	
	//はずれた値を調整
	if (pos < -1)
		pos = 0;
	if (pos > 100)
		pos = 100;
//	if (a_size > 100)
//		a_size = 100;
	
	if (pos == -1 || a_size >= 99.7){
		enable = false;
		alpha = 50;
	}else{
		alpha = 100;
		enable = true;
		barH = thisH * a_size/ 100;
		if (barH < 10){//15以下はつかむことができないから
			barH = 10;
		}
	
		bar._height =barH ;
		bar._y = ((thisH-barH) * pos / 100)+17;
		if (barH < 16){
			bargrip._height = barH-2;
		}else{
			bargrip._height = 14;
		}
		bargrip._y = bar._y + bar._height/2 - bargrip._height/2;
	}

	//有効か？
	bar._visible = enable;
	barback.enabled = enable;
	bargrip._visible = enable;
	scUp.enabled = enable;
	scDown.enabled = enable;
	scUp._alpha = alpha;
	scDown._alpha = alpha;
	
	barback._height = a_all+17+1;
/*	
	if (ishorizontal){
		barback._visible = enable;
		scUp._visible = enable;
		scDown._visible = enable;
				
	}
*/	

	//オスボタン
//	scUp._y = 0.5;//16.5;//17;
//	scUp._x = 16.5;
	
//	scDown._x = -0.5;
	scDown._y = a_all-17;
	
	//記録
//	horizontal = ishorizontal;

	
};

dragging = false;
startpos = 0;
bar.useHandCursor = false;
scDown.useHandCursor = false;
scUp.useHandCursor = false;
barback.useHandCursor = false;

function moveBar(newy,movebar,scroll){
	//バーを動かし、スクロールする
	if (!enable)
		return;
	if (newy < 17)
		newy = 17;
	else if (newy > thisH+17-barH)
		newy = thisH+17-barH;
		
	if (movebar){
		bar._y = newy;
		bargrip._y = bar._y + bar._height/2 - bargrip._height/2;
	}
	if (scroll != false){
		//通知
		var per = (newy-17)/(thisH-barH)*100;
//		per = Math.round(per/10)*10;
		
		_root.Main.Scroll(per,horizontal);	
		//場所保存
//		_root.Main.saveMapPosition();
	
	}
	
};

bar.gotoAndStop(1);
bar.onPress = function(){
	//スクロールバーのドラッグ開始
	dragging = true;
	_root.Main.prepareForScroll(true);

	scnt = 0;
	
	startpos = bar._y
	starty = _ymouse;
	bar.gotoAndStop(3);
	lasttime = getTimer();

//	clearInterval(dragID);
//	dragID = setInterval(onDagScrollBar ,30,null);


	
};

bar.onRollOver = function(){
	//カーソルもどす
	showMyCursor(false);
	bar.gotoAndStop(2);
};
bar.onRollOut = function(){
	
	bar.gotoAndStop(1);
};
/*
function movePage(){
	if (dragging){
		//移動
		var type = 1;
		if (type == 1){
			var spantime  = (getTimer() - lasttime);		
			if (spantime < 100){
				var testy = startpos + (_ymouse -starty);
				var newy = Math.round(testy/10) * 10;
				moveBar(newy,false,true);
				updateAfterEvent();
			}			
		}else{
			//タイプ2(1秒マウスが止まったときだけ)
				scnt++;
			if (scnt > 3){
				scnt = 0;
				var testy = startpos + (_ymouse -starty);
				var newy = Math.round(testy/10) * 10;
				moveBar(newy,false,true);
				updateAfterEvent();
			}
		}
		

//		clearInterval(moveID);
//		moveID = undefined;
		lasttime = getTimer();
		oldx = _root._xmouse;
		oldy = _root._ymouse;

	}	
};
*/
lasttime = 0;

function onDagScrollBar(){
	

	
	
	
}

bar.onMouseMove = function(){
	if (dragging){
		//時間が詰まり過ぎていれば、無視
		//この値をページの重さに応じて変えるのが妥当
		var spantime  = (getTimer() - lasttime);		
		if (spantime < 30){
			return;
		}
		
		//バー描画
		var testy = startpos + (_ymouse -starty);
		moveBar(testy,true,false);
		//移動
		var newy = Math.round((testy-17)/30)*30 + 17;
		if (newy != oldnewy){
			moveBar(newy,false,true);
			lasttime = getTimer();
			updateAfterEvent();
		}
		oldnewy = newy;
		bargrip._y = bar._y + bar._height/2 - bargrip._height/2;

	
		
	}
};


bar.onRelease = function(){
	if (dragging){
		//Timerをキル
		clearInterval(dragID);
		dragID = undefined;
		//バー描画
		var testy = startpos + (_ymouse -starty);
		moveBar(testy,true,false);
		//移動
		var newy = Math.round((testy-17)/30)*30 + 17;
		if (newy != oldnewy){
			moveBar(newy,false,true);
		}

		_root.Main.prepareForScroll(false);
	
	}
	
	dragging = false;
	bar.gotoAndStop(2);
	
	//フォーカスを
//	Selection.setFocus("_root." + this._parent._name + "." + this._name);
	
	
	//場所保存
	_root.Main.saveMapPosition();
	
};
bar.onReleaseOutside = function(){
	bar.onRelease();
	bar.gotoAndStop(1);
	
};

barback.onRollOver = function(){
	//カーソル切る
	showMyCursor(false);
};

barback.onPress = function(){
	//１ページ分移動させる
	onePageScroll((_ymouse > bar._y));
			
};

function onePageScroll(isDown){
	if (isDown){
		//下へ
		var newy = bar._y + bar._height;
		moveBar(newy,true);		
	}else{
		//上へ		
		var newy = bar._y  - bar._height;
		moveBar(newy,true);
	}
}


scDown.onRollOver = function(){
	//カーソル切る
	showMyCursor(false);
}

scUp.onRollOver = function(){
	//カーソル切る
	showMyCursor(false);
}
scDown.onPress = function(){
	//下へ移動
	var newy = bar._y + 30;
	moveBar(newy,true);
	scID = setInterval(scPage ,150,true);

	
};
scDown.onRelease = function(){
	clearInterval(scID);
	
	_root.Main.prepareForScroll(false);

};

scDown.onReleaseOutside = scDown.onRelease;
scUp.onRelease = scDown.onRelease;
scUp.onReleaseOutside = scDown.onRelease;

scUp.onPress = function(){
	//上へ移動
	var newy = bar._y  - 30;
	moveBar(newy,true);
	scID = setInterval(scPage ,150,false);
	//フォーカスを
//	Selection.setFocus("_root." + this._parent._name + "." + this._name);
	
};

function scPage(isDown){
	_root.Main.prepareForScroll(true);

	if (isDown){
		var newy = bar._y  + 30;
		moveBar(newy,true);
	}else{
		var newy = bar._y  - 30;
		moveBar(newy,true);
	}	
};

function moveDown(delta){
	//下へ移動
	var v = 15;
	if (delta != null && delta >= 1){
		trace("delta = " + delta);
		v = 8*delta;
	}
	
	var newy = bar._y + v;
	moveBar(newy,true);
};
function moveUp(delta){
	//上へ移動
	var v = 15;
	if (delta != null && delta >= 1){
		trace("delta = " + delta);
		v = 8*delta;
	}
	
	var newy = bar._y  - v;
	moveBar(newy,true);	
};