/*
 * 
 * dlg_strokebox
 * 線の太さダイアログ
 * 
 */
 
menu = this;


DlgBack.useHandCursor = false;
DlgBack.onPress = function(){
	
};
dragging = false;

if (MyLang == "en"){
	dlg_message = "Pen width : \nclick the \npen point.";
	
}

function setPenColor(param){
	//ペンの太さの色をセット
	var myColor  = new Color(penTriangle);
	myColor.setRGB(param);
	
	var white = (param == "0xffffff");
	//ペンの太さ選択背景
	penTriangleBackForWhite._visible = white;
	
}


function init(){
	
	//初期ペンの太さ
	var t = _root.Main.penwidth;
	thicknessbox.value = t;
	penMask._height = 76*(40-t)/40;	
	
	//初期ペンカラー
	setPenColor(_root.Main.pencolor);

}

form = new Object(); 
form.change = function(eventObj){
	_root.Main.penwidth = thicknessbox.value;
	init();
}
thicknessbox.addEventListener("change", form);


thicknessSlider.onPress = function(){
	
	//ドラッグ開始
	dragging = true;
	apply();
};

thicknessSlider.onMouseMove = function(){
	
	//ドラッグ中
	if (dragging){
		apply();
	}
};

thicknessSlider.onRelease = function(){
	
	//ドラッグ終了
	dragging = false;
	playSound("KASHA");
	
};
thicknessSlider.onReleaseOutside = thicknessSlider.onRelease;

function apply(){
	
	var thickness = Math.round(45-45*(thicknessSlider._ymouse/thicknessSlider._height));
	if (thickness > 30)
		thickness = 30;
	if (thickness < 1)
		thickness = 1;
	
	_root.Main.penwidth = thickness;
	thicknessbox.value = thickness;
	penMask._height = 76*(40-thickness)/40;	
}


