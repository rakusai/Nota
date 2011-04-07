/*
 * 
 * statusbar
 * ステータスバー
 * 
 */
 

pageWeight._xscale = 0;

this.useHandCursor = false;

this.onPress = function(){
	
	
}

commandtxt.onChanged = function(){
	//dammyTextの文字が変更された！
	clearInterval(textcrIntervalID);
	textcrIntervalID = setInterval(parseText,300,null);

};

function parseText(){
	//ショートカットコマンドの実行
	clearInterval(textcrIntervalID);
	var inputtext = commandtxt.text;
	commandtxt.text = "";
	
	if (PageEdit != true){
		//編集モードじゃない
		return;
	}	
	
	if (inputtext == ""){
		//文字が空
		return;
	}
	
	//ここで、テキストを解釈する
	switch (inputtext){
	case "c":
	case "1":
		_root.Main.addShape("circle");
		break;
	case "r":
		_root.Main.addShape("roundrect");
		break;
		break;
	case "h":
		_root.Main.addShape("heart");
		break;
	case "2":
		_root.Main.addShape("arrow");
		break;
	case "3":
		_root.Main.addShape("triangle");
		break;
	case "4":
		_root.Main.addShape("rectangle");
		break;
	case "5":
		_root.Main.addShape("pentagon");
		break;
	case "6":
		_root.Main.addShape("hexagon");
		break;
	case "7":
	case "s":233
		_root.Main.addShape("star");
		break;
	case "8":
		_root.Main.addShape("thorn");
		break;
	case "nota":
		_root.Main.addShape("nota");
		break;
	case "notan":
		_root.Main.addShape("notan");
		break;
	default:
		_root.Main.addText(inputtext);
		break;
	}

}
