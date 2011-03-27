/*
 * 
 * flag_select
 * オブジェクト操作枠
 * 
 */

stop();
this.useHandCursor = false;

comment_txt.autoSize = true;
FlagSelect = this;
pFlag = null;

//吸着情報を格納する配列
var m_AdsorbList= new Array();

//-------------------------------------------------------//
//作成者情報
//-------------------------------------------------------//
function showSelect(curpFlag){
	//Flag登録
	if (m_SelList.length > 0){
/*		var id = 0;
		var q = 100000;
		for (var i=0;i<m_SelList.length;i++){
			var q2 = m_DataList[m_SelList[i].num].x * m_DataList[m_SelList[i].num].y;
			if (q2 < q){
				q = q2;
				id = i;
			}
		}
		
		pFlag = eval("_root.Main." + m_SelList[id].num);
*/		pFlag = eval("_root.Main." + m_SelList[0].num);
		}
	//場所を移動する
	
	FlagSelect._x = pFlag._x;
	FlagSelect._y = pFlag._y;
	
	/////////////////////////////////////
	//編集可能かどうかによってハンドルの表示・非表示を切り替える
	
	//選択されているオブジェクト内を検索し、
	//サイズ変更可能か、回転可能か判断する
	var isDelete = true;  //削除可能か
	var isMove = true;    //移動可能か
	var isResize = true;  //サイズ変更可能か
	var isRotate = true;  //回転可能か
	
	
	for (var i=0;i<m_SelList.length;i++){
		//枠を書く
		var obj = eval("_root.Main." + m_SelList[i].num);
		
		if (_root.Main.IsFlagGuestLock(m_SelList[i].num,true)){
			isDelete = false;
			isMove = false;
			isResize = false;
			isRotate = false;
		}
	
		if (pFlag.fileicon._visible || pFlag.plugin._visible){
			isResize = false;
		}
		if (pFlag.plugin._visible || pFlag.textbox._visible || pFlag.fileicon._visible){
			//テキストは回転できない
			isRotate = false;
		}
	}
	
	if (m_SelList.length > 1){
		//複数選択時
		isResize = false;
		isRotate = false;
	}
	
	
	FlagSelect.resizetab._visible = isResize;
	FlagSelect.rotationtab._visible = isRotate;
	FlagSelect.delbtn._visible = isDelete;
	FlagSelect.movetab.gotoAndStop(isMove ? 1:2);
	
	//選択枠調整
	moveResizeTab();
	
	//作成者情報表示
	showAuth();
	
	FlagSelect._visible = true;
	
	
}

function showAuth(){
	//作成者情報を表示
	
	var author = m_DataList[pFlag._name].author;
	var crdate = m_DataList[pFlag._name].date;
	var update = m_DataList[pFlag._name].update;
	if (crdate == undefined){ crdate = "";}
	if (update == undefined){ update = "";}

	var allText = "";
	//作成者
	allText += "<font color='#000000' size='12'>" + author +  "</font>";
//	allText += "<font color='#bd362e' size='12'>" + Vars.author +  "</font>\n";
	//作成日、更新日
	//秒を切る
	var re = crdate.lastIndexOf(":");
	if (re >= 0) crdate = crdate.substr(0,re);
	var re2 = update.lastIndexOf(":");
	if (re2 >= 0) update = update.substr(0,re2);
//	allText = Vars.authorname + " / ";
	if (MyLang == "en"){
		allText += "<BR>Create ";
	}else{
		allText += "<BR>作成 ";
	}
	allText += crdate;
	if (crdate.substr(0,13) != update.substr(0,13)){//時間(hour)が違うなら
		if (MyLang == "en"){
			allText += "<BR>Update ";
		}else{
			allText += "<BR>更新 ";
		}
		allText += update;
		
	}
	

	//テキストセット
	FlagSelect.comment_txt.htmlText = allText;
	
	//場所
	setAuthHeight();

	
};
function setAuthHeight(){
	//作成者情報のテキストの高さを計算
	
//	updateAfterEvent();//今すぐ更新
	var isshow = (m_SelList.length <= 1);
	FlagSelect.comment_txt._visible = isshow;
	FlagSelect.comment_back._visible = isshow;


	//スケールを平均か
	if (FlagSelect.comment_txt._visible){
		mapsc = _root.Main._xscale;
		sc = 100 / _root.Main._xscale * 100;
		if (FlagSelect.comment_txt._xscale != sc){
			FlagSelect.comment_txt._xscale = sc;
			FlagSelect.comment_txt._yscale = sc;
//			FlagSelect.comment_back._xscale = sc;
//			FlagSelect.comment_back._yscale = sc;
		}
		//大きさ
		H = FlagSelect.comment_txt._height;
//		if (H > 1*sc/100 && oldH != H){
			FlagSelect.comment_txt._y = -H - 20;
			FlagSelect.comment_back._height =  H + 5;
			FlagSelect.comment_back._width =  (FlagSelect.comment_txt._width + 5);
			FlagSelect.comment_back._y = -FlagSelect.comment_back._height-15-2;
//			FlagSelect.comment_back._visible = true;
//			oldH = H;
//		}
	}
};

//-------------------------------------------------------//
//吸着ポイントの保存
//-------------------------------------------------------//

function saveAbsorbPoint(num){
	
	m_AdsorbList= new Array();
	//次回の吸着ポイントとして保存する
	for (var i=0;i<m_SelList.length;i++){
		var num = m_SelList[i].num;
		var flg = eval("_root.Main." + num);
		var rect = flg.fobject.getBounds(_root.Main);
		if (!rect){
			//TextBoxなら(fobjectのgetBoundsできない！)
			rect = flg.getBounds(_root.Main);
		}
		absorb = new Object();
		absorb.axis = "xcenter";
		absorb.value = (rect.xMin + rect.xMax)/2;
		m_AdsorbList.push(absorb);
		
		absorb = new Object();
		absorb.axis = "x";
		absorb.value = rect.xMin;
		m_AdsorbList.push(absorb);
		
		absorb = new Object();
		absorb.axis = "x";
		absorb.value = rect.xMax;
		m_AdsorbList.push(absorb);
		
		absorb = new Object();
		absorb.axis = "ycenter";
		absorb.value = (rect.yMin + rect.yMax)/2;
		m_AdsorbList.push(absorb);
	
		absorb = new Object();
		absorb.axis = "y";
		absorb.value = rect.yMin;
		m_AdsorbList.push(absorb);
		
		absorb = new Object();
		absorb.axis = "y";
		absorb.value = rect.yMax;
		m_AdsorbList.push(absorb);	
		
		absorb = new Object();
		absorb.axis = "rot";
		absorb.value = m_DataList[num].rotation;
		m_AdsorbList.push(absorb);			
		
	}
	
	if (m_SelList.length <= 0){
		//用紙の境界線に吸着
		absorb = new Object();
		absorb.axis = "x";
		absorb.value = 0;
		m_AdsorbList.push(absorb);		
		
		absorb = new Object();
		absorb.axis = "x";
		absorb.value = PaperW;
		m_AdsorbList.push(absorb);		
		
		absorb = new Object();
		absorb.axis = "y";
		absorb.value = 0;
		m_AdsorbList.push(absorb);	
		
		absorb = new Object();
		absorb.axis = "y";
		absorb.value = PageH;
		m_AdsorbList.push(absorb);		
	}

}

//-------------------------------------------------------//
//delbtnイベントハンドラ
//-------------------------------------------------------//
FlagSelect.delbtn.onRelease = function(){
	//削除ボタンが押された
	_root.Main.deleteFlag();
};


//-------------------------------------------------------//
//movetabイベントハンドラ
//-------------------------------------------------------//
/*FlagSelect.movetab.onRollOver = function(){
	_root.Main.moveFlagFocus(pFlag._name);
	
	_parent.SetSelection();
};

FlagSelect.movetab.onRollOut = function(){
	//カーソル変更
	setCursor();

};
*/

function startMove(bytab){
	
	//移動を開始する
	if (!PageEdit)
		return;	
		
		
	//サイズの変更を開始
	if (!bytab){	
		if (_root.Main.IsFlagGuestLock(pFlag._name,1)){
			return;	//ゲストは編集できない
		}	
	}

	
	startX = FlagSelect._x;
	startY = FlagSelect._y;
	
	startXpos = _root.Main._xmouse - startX;
	startYpos = _root.Main._ymouse - startY;
	
	startW = FlagSelect._width;
	startH = FlagSelect._height;

	dragging = 1;

	//リンク吹き出しを消す
	if (_root.Main.FlagLink._visible){
		_root.Main.FlagLink._visible = false;
	}		
}

FlagSelect.movetab.onPress = function(){
	startMove(true);
};


function absRound(number){
	return Math.abs(Math.round(number));
}

function getMovePos(pt){
	//移動や、サイズ変更時の位置補正
	var x = pt.x;
	var y = pt.y;
	//枠内に収めよ
	if (x < -startW/2) x = -startW/2;
	if (x > PaperW) x = PaperW;
	if (pFlag.textbox._visible){
		if (y < 10) y = 10;
	}else{
		if (y < -startH/2) y = -startH/2;
	}
	if (y > PaperH) y = PaperH;
	//格子に沿うように

	//吸着ポイントに沿うように
	if (dragging == 2 || resizing){
		var can = _root.Main.canvasDel;
		can.clear();
		can.lineStyle(1,0x6699FF,100);
		
		var num = m_SelList[0].num;
		var flag = eval("_root.Main." + num);
		var rect = flag.fobject.getBounds(_root.Main);
		if (!rect){
			rect = flag.getBounds(_root.Main);
		}
		//相対位置を把握せよ！
		rect.xMin -= flag._x;
		rect.xMax -= flag._x;
		rect.yMin -= flag._y;
		rect.yMax -= flag._y;
		
		if (resizing){
			rect.xMin = 0;
			rect.xMax = 0;
			rect.yMin = 0;
			rect.yMax = 0;
		}
		
		//線の描画位置
		var spt = new Object();
		spt.x = 0;
		spt.y = 0;
		can.globalToLocal(spt);
		var ept = new Object();
		ept.x = Stage.width;
		ept.y = Stage.height;
		can.globalToLocal(ept);
		
		
		var xdis = 5;
		var ydis = 5;
		
		for (var i=0;i<m_AdsorbList.length;i++){
			var absorb = m_AdsorbList[i];
			if (absorb.axis == "x"){
				//X軸が近いか？
				if (absRound(absorb.value - (x+rect.xMin)) <= xdis){
					//左上で合わせる
					x = absorb.value-rect.xMin;
					//吸着の補助線を描画
					can.moveTo(x+rect.xMin,spt.y);
					can.lineTo(x+rect.xMin,ept.y);//縦
					xdis = absRound(absorb.value - (x+rect.xMin));
				}
				else if (absRound(absorb.value - (x+rect.xMax)) <= xdis){
					//右下で合わせる
					x = absorb.value-rect.xMax;
					//吸着の補助線を描画
					can.moveTo(x+rect.xMax,spt.y);
					can.lineTo(x+rect.xMax,ept.y);//縦
					xdis = absRound(absorb.value - (x+rect.xMax));
				}
			}else if (absorb.axis == "xcenter"){
				if (absRound(absorb.value - (x+(rect.xMin+rect.xMax)/2)) <= xdis){
					//中央で合わせる
					x = absorb.value-(rect.xMin+rect.xMax)/2;
					//吸着の補助線を描画
					can.moveTo(x+(rect.xMin+rect.xMax)/2,spt.y);
					can.lineTo(x+(rect.xMin+rect.xMax)/2,ept.y);//縦
					xdis = absRound(absorb.value - (x+(rect.xMin+rect.xMax)/2));
				}
			}else if (absorb.axis == "y"){
				//Y軸が近いか？
				if (absRound(absorb.value - (y+rect.yMin)) <= ydis){
					//左上で合わせる
					y = absorb.value-rect.yMin;
					//吸着の補助線を描画
					can.moveTo(spt.x,y+rect.yMin);
					can.lineTo(ept.x,y+rect.yMin);//縦
					ydis = absRound(absorb.value - (y+rect.yMin));
				}else if (absRound(absorb.value - (y+rect.yMax)) <= ydis){
					//左上で合わせる
					y = absorb.value-rect.yMax;
					//吸着の補助線を描画
					can.moveTo(spt.x,y+rect.yMax);
					can.lineTo(ept.x,y+rect.yMax);//縦
					ydis = absRound(absorb.value - (y+rect.yMax));
				}
			}else if (absorb.axis == "ycenter"){
				if (absRound(absorb.value - (y+(rect.yMin+rect.yMax)/2)) <= ydis){
					//中央で合わせる
					y = absorb.value-(rect.yMin+rect.yMax)/2;
					//吸着の補助線を描画
					can.moveTo(spt.x,y+(rect.yMin+rect.yMax)/2);
					can.lineTo(ept.x,y+(rect.yMin+rect.yMax)/2);//縦
					ydis = absRound(absorb.value - (y+(rect.yMin+rect.yMax)/2));
				}
				
			}
		}
		pt.xdis = xdis;
		pt.ydis = ydis;

	}
	
//	x = Math.round((x / 30))*30;
//	y = Math.round((y / 30))*30;
	
	pt.x = Math.round(x);
	pt.y = Math.round(y);
	
	return pt;
	
	
	
	
}

FlagSelect.movetab.onMouseMove = function(){
	//移動中
	var pt = new Object;
	pt.x = _root.Main._xmouse - startXpos;
	pt.y = _root.Main._ymouse - startYpos;

	pt = getMovePos(pt);
	
	if (dragging == 1){
		
		//ゲストは、他人の部品の移動許可をしない
		for (var i=0;i<m_SelList.length;i++){
			var obj = eval("_root.Main." + m_SelList[i].num);
			if (_root.Main.IsFlagGuestLock(obj._name)){
				FlagSelect.movetab.onRelease();//ドラッグ終了
				return;
			}
		}
		//2px以上で移動を認める
		if (Math.abs(pt.x-startX) > 2 || Math.abs(pt.y-startY) > 2){
			dragging = 2;
		}
	}
	
	if (dragging == 2){
		for (var i=0;i<m_SelList.length;i++){
			var obj = eval("_root.Main." + m_SelList[i].num);
			//枠の移動
			FlagSelect._x = pt.x;
			FlagSelect._y = pt.y;
			//オブジェクトの移動
			obj._x = pt.x + m_SelList[i].selx;
			obj._y = pt.y + m_SelList[i].sely;
		}
	}
	updateAfterEvent();
	
}

FlagSelect.movetab.onRelease = function(){
	//ドラッグ終わり
	//場所を求め、情報更新
	if (dragging <= 1){
		dragging = 0;
		return;
	}
	dragging = 0;

	//補助線消去
	_root.Main.canvasDel.clear();

	//移動
	if (startX != FlagSelect._x || startY != FlagSelect._y){
		var curtime = getTm();
		playSound("SHU");
		for (var i=0;i<m_SelList.length;i++){
			var flg = eval("_root.Main." + m_SelList[i].num);
			var obj = new Object();	//差分を代入
			obj.x = Math.round(flg._x);
			obj.y = Math.round(flg._y);
			//保存
			_root.Main.updateFlag(m_SelList[i].num,obj,curtime);	

		}
		
	}
	
};
FlagSelect.movetab.onReleaseOutside = FlagSelect.movetab.onRelease;

//-------------------------------------------------------//
//resizetabイベントハンドラ
//-------------------------------------------------------//

FlagSelect.resizetab.onRollOver = function(){
	_root.Pen._rotation = pFlag._rotation;
	showMyCursor(true,"resize");
};

FlagSelect.resizetab.onRollOut = function(){
	showMyCursor(false);
};

FlagSelect.resizetab.onPress = function(){
	//サイズの変更を開始
	if (_root.Main.IsFlagGuestLock(pFlag._name)){
		return;	//ゲストは編集できない
	}
	
	if (pFlag.breakpic == 1){
		return;
	}
	
	resizing = true;
	
};

FlagSelect.resizetab.onRelease = function(){
	//サイズ変更を終了
	if (resizing){
		resizing = false;
		//内容を保存せよ。
		var obj = new Object();	//差分を代入
		var w,h;
		
		//補助線消去
		_root.Main.canvasDel.clear();

		if (pFlag.textbox._visible){
			//テキストの場合
			w = pFlag.fobject._width;
			h = pFlag.fobject._height;
			
		}else{
			//それ以外
			var rect = pFlag.fobject.getBounds(pFlag.fobject._parent);
			w = rect.xMax;
			h = rect.yMax;
			
			if (pFlag.photo._visible && pFlag.fileext == "swf"){
				//SWFなら、大きさの比率を保存
				obj.scale = Math.round(pFlag.photo._width/pFlag.photo.picture._width * 100) + ":" + 
				Math.round(pFlag.photo._height/pFlag.photo.picture._height*100);
			}		
		}
		obj.width = Math.round(w);
		obj.height = Math.round(h);

		//保存
		_root.Main.updateFlag(pFlag._name,obj);
		//サイズによって上下関係を変更
		_root.Main.setFlagDepths(pFlag);
		
	}
};
FlagSelect.resizetab.onReleaseOutside = function(){
	
	showMyCursor(false);
	FlagSelect.resizetab.onRelease();
	
	
};
FlagSelect.resizetab.onMouseMove = function(){
	//サイズを変更する
	if (resizing){
		var pt = new Object;
		pt.x = _root.Main._xmouse;
		pt.y = _root.Main._ymouse;
		pt = getMovePos(pt);
		_root.Main.localToGlobal(pt);
		FlagSelect.globalToLocal(pt);

		var w = pt.x;
		var h = pt.y;
		
//		ErrorMes("resize" + pt.x + "|" + pt.y + "|" + 
//				 _root.Main._ymouse);
/*		
		var w = _xmouse;
		var h = _ymouse;
*/		
		
		if (pFlag.photo._visible && pFlag.fileext == "swf"){
			//SWFなら、Flashが原点と違う場所にある場合、w,h値を修正
			var rect = pFlag.fobject.picture.getBounds(pFlag.fobject);
			var xMax = rect.xMax;
			var yMax = rect.yMax;

			var ow = pFlag.photo.picture._width;
			var oh = pFlag.photo.picture._height;
			
			w  = w * ow / xMax;
			h  = h * oh / yMax;
		}
		
		//最小値の設定
		if (w < 10)		w = 10;
		if (h < 10)		h = 10;
//		if (w > 1000)	w = 1000;
		
		var robj;
		if (pFlag.photo._visible){
			//縦横比保持の場合は、補助線が縦横どちらが
			//近いかによって、どちらに合わせるか決める
			var ow = pFlag.photo.picture._width;
			var oh = pFlag.photo.picture._height;
			
			//ここで、縦横比が1に近い場合は1に合わせる
			//基本は、縮小しようとしている辺の80%以内になったら、縦横比が
			//くずれることを許す
			var jyuouhi = false;
			if ((h < w*oh/ow * 0.85 && h < w*oh/ow - 35) || 
				(w < h*ow/oh * 0.85 && w < h*ow/oh - 35))
			{
				if (Key.isDown(Key.SHIFT)){
					//縦横比に添え！
					jyuouhi = true;
				}
			}else{
				//縦横比に添え！
				jyuouhi = true;
			}
			if (jyuouhi){
				if (pt.xdis > pt.ydis){
					w = h*ow/oh;
				}else{
					h = w*oh/ow;				
				}
			}
			
			pFlag.photo._width = w;	
			pFlag.photo._height = h;
			//マスキングクリップの調整
			if (!pFlag.shape.hitArea){
				pFlag.shape._width = w;
				pFlag.shape._height = h;
			}
		}else if(pFlag.textbox._visible){
			//テキストの場合
			//横を変えれば、縦はついてくるので、横だけ変更
			if (w < 32) {
				w = 32;//32が最小値
			}
			pFlag.textbox._width = w;
		}else if(pFlag.shape._visible){
			//図形の場合
			var ow = m_DataList[pFlag._name].width;
			var oh = m_DataList[pFlag._name].height;

			if (Key.isDown(Key.SHIFT)){
				//縦横比に従う
				h = w*oh/ow;
			}
			
			pFlag.shape._width = w;
			pFlag.shape._height = h;				
		}
		
		
		moveResizeTab();
		updateAfterEvent();
		
	}
};

//-------------------------------------------------------//
//resizeタブの位置
//-------------------------------------------------------//

function moveResizeTab(){

	//変更用リサイズタブを正しい位置に移動する

	//自信も回転させる
	if (m_SelList.length == 1){
		FlagSelect._rotation = pFlag._rotation;
	}else{
		FlagSelect._rotation = 0;
	}
	
	//フォーカスの線を描画
	var obj = FlagSelect;
	obj.clear();
	var xMin=0,yMin=0,xMax=0,yMax=0;
	
	for (var i=0;i<m_SelList.length;i++){
		//枠を書く
		var flg = eval("_root.Main." + m_SelList[i].num);
		
		var x = flg._x - obj._x;
		var y = flg._y - obj._y;
		var x2,y2;
		
		if (flg.textbox._visible){
			//TextBoxなら
			x2 = x + flg.fobject._width;
			y2 = y + flg.fobject._height;
			if (y2 < y + 15){
				y2 = y + 23;//21.2;
			}
		}else{
			//それ以外なら
			var rect = flg.fobject.getBounds(flg.fobject._parent);
			x2 = x + rect.xMax;/* - flg.fobject._x*/;
			y2 = y + rect.yMax/*- obj._y*/;/* - flg.fobject._y*/;
		}

		if (FlagSelect.delbtn._visible){
			obj.lineStyle(2,0x3C3C3C);
		}else{
			obj.lineStyle(2,0xE3E3E3);
		}
		
		//選択枠内での座標を記録
		m_SelList[i].selx = x;
		m_SelList[i].sely = y;
				
		if (m_SelList.length == 1){
			//一つだけ選択
			xMin = x;
			yMin = y;
			xMax = x2;
			yMax = y2;		
			
		}else{
			//全4点を回転を考慮して再計算
			//FlagSelectの相対位置を求める
			//個別の枠を描く
			var ptlist = new Array();
			
			var pt = new Object();
			pt.x = 0; pt.y = 0;
			flg.localToGlobal(pt);
			FlagSelect.globalToLocal(pt);
			obj.moveTo(pt.x,pt.y);
			if (pt.x  < xMin) xMin = pt.x;
			if (pt.y  < yMin) yMin = pt.y;
			if (pt.x > xMax) xMax = pt.x;
			if (pt.y > yMax) yMax = pt.y;		
			
			pt.x = x2-x; pt.y = 0;
			flg.localToGlobal(pt);
			FlagSelect.globalToLocal(pt);
			obj.lineTo(pt.x,pt.y);		
			if (pt.x  < xMin) xMin = pt.x;
			if (pt.y  < yMin) yMin = pt.y;
			if (pt.x > xMax) xMax = pt.x;
			if (pt.y > yMax) yMax = pt.y;		
			
			pt.x =x2-x; pt.y = y2-y;
			flg.localToGlobal(pt);
			FlagSelect.globalToLocal(pt);
			obj.lineTo(pt.x,pt.y);		
			if (pt.x  < xMin) xMin = pt.x;
			if (pt.y  < yMin) yMin = pt.y;
			if (pt.x > xMax) xMax = pt.x;
			if (pt.y > yMax) yMax = pt.y;		
			
			pt.x = 0; pt.y = y2-y;
			flg.localToGlobal(pt);
			FlagSelect.globalToLocal(pt);
			obj.lineTo(pt.x,pt.y);		
			if (pt.x  < xMin) xMin = pt.x;
			if (pt.y  < yMin) yMin = pt.y;
			if (pt.x > xMax) xMax = pt.x;
			if (pt.y > yMax) yMax = pt.y;		
			
			pt.x = 0; pt.y = 0;
			flg.localToGlobal(pt);
			FlagSelect.globalToLocal(pt);
			obj.lineTo(pt.x,pt.y);	
		}
	}
	
	if (FlagSelect.delbtn._visible){
		obj.lineStyle(3,0x005AFF,50);
	}else{
		obj.lineStyle(3,0x999999,50);
	}
	//全体を選択せよ
	obj.moveTo(xMin,yMin);
	obj.lineTo(xMax+1,yMin);
	obj.lineTo(xMax+1,yMax+1);
	obj.lineTo(xMin,yMax+1);
	obj.lineTo(xMin,yMin);	
	

	FlagSelect.movetab._x = xMin;
	FlagSelect.movetab._y = yMin;

	FlagSelect.resizetab._x = /*pFlag.fobject._x +*/ xMax;
	FlagSelect.resizetab._y = /*pFlag.fobject._y +*/ yMax;
	//回転タブも移動する	
	FlagSelect.rotationtab._x = FlagSelect.resizetab._x +7;
	FlagSelect.rotationtab._y = FlagSelect.resizetab._y +7;
	
	//削除ボタンの位置
	var delx = FlagSelect.resizetab._x-20;
	if (delx < xMin+60)
		delx = xMin+60;
	FlagSelect.delbtn._x = delx;
	FlagSelect.delbtn._y = yMin - 15.4;
	
};

//-------------------------------------------------------//
//rotationtabイベントハンドラ
//-------------------------------------------------------//

FlagSelect.rotationtab.onRollOver = function(){
	_root.Pen._rotation = pFlag._rotation;
	showMyCursor(true,"rotation");
};

FlagSelect.rotationtab.onRollOut = function(){
	showMyCursor(false);
};

FlagSelect.rotationtab.onPress = function(){
	//サイズの変更を開始する
	if (_root.Main.IsFlagGuestLock(pFlag._name)){
		return;	//ゲストは編集できない
	}
	rotating = true;
	
};

FlagSelect.rotationtab.onRelease = function(){
	//サイズ変更を終了
	if (rotating){
		rotating = false;
		var degree = pFlag._rotation;
		if (degree < 0)
			degree += 360;
		var obj = new Object();	//差分を代入
		obj.rotation = degree;
		_root.Main.updateFlag(pFlag._name,obj);	
		
	}
};
FlagSelect.rotationtab.onReleaseOutside = function(){
	
	showMyCursor(false);
	FlagSelect.rotationtab.onRelease();
	
};
function getDegree(x,y){
	//xとyの値から、原点からの角度を求める
	var rot = y/x;
	var right = (x > 0);

	//まず、4つに分ける
	var degree;
	if (0 <= rot){
		if (right)
			degree = 0;	
		else
			degree = 180;
	}
	if (0 > rot){
		if (right)
			degree = 360;
		else
			degree = 180;
	}
	//タンジェントの値から、おおよその角度を求める
	for (var i=0;i<=90;i++){
		var nt = Math.tan(Math.PI/180 * i);
		if (nt >= Math.abs(rot)){
			if (0 <= rot)				
				degree += i;
			else
				degree -= i;
			break;
		}
	}
	return degree;
	
};

FlagSelect.rotationtab.onMouseMove = function(){
	//回転させる
	if (rotating){
		//回転角
		var degree = getDegree(_root.Main._xmouse-pFlag._x,_root.Main._ymouse-pFlag._y);
		var objdegree = getDegree(this._x,this._y);

		degree -= objdegree;
		if (degree < 0){
			degree = 360 + degree;	
		}
		//スナップ
		var degs = new Array(0,45,90,135,180,225,270,315,360);
		
		//前の選択オブジェクトに合わせる
		for (var i=0;i<m_AdsorbList.length;i++){
			var absorb = m_AdsorbList[i];
			if (absorb.axis == "rot"){
				degs.push(absorb.value);
			}
		}

		var rdis = 10;
		for (var i=0;i<degs.length;i++){
			if (absRound(degs[i] -  degree) < rdis){
				degree = degs[i];
				rdis = absRound(degs[i] -  degree);
			}
		}
		
		pFlag._rotation = degree;
		FlagSelect._rotation = degree;
		_root.Pen._rotation = degree;

	}
};

