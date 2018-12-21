function scenario05_greet(){
	var bars = document.getElementsByClassName("ms-core-brandingText");
	var txt = bars[0].innerText; 
	bars[0].innerText = "SharePoint Customization Troubleshooting Workshop";
	var bar = document.getElementById("suiteBarLeft");
	bar.style.backgroundColor = "#f2f2f2";
	bar.style.color = "#666666";
	var suiteLinks = document.getElementsByClassName("ms-core-suiteLink-a");
	for(var i=0; i < suiteLinks.length; i++) { 
  	  suiteLinks[i].style.color = "#666666";
	}
}

_spBodyOnLoadFunctionNames.push("scenario05_greet");