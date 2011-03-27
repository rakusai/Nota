//Open Popup Window

function openPopup(e,url,targetName,width,height){

	//サブウインドウを開く
	//(引数以外のパラメータも下記でセットできます)
	var para =""
	+",toolbar="	 +0
	+",location="	 +0
	+",directories=" +0
	+",status=" 	 +0
	+",menubar="	 +1
	+",scrollbars="  +1
	+",resizable="	 +1
	+",width="		 +width
	+",height=" 	 +height;

	thePopup=window.open(url,targetName,para);
	thePopup.focus();
}

