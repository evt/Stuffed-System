/* 

		INFORMATION

		Name:			Stuffed Loading class
		Version:		1.0
		Author:			Sergey Smirnov / Stuffed Guys
		Site:			www.stuffedguys.org
		Desc:			Fades out the page and shows loading block in the middle
		
*/

function StuffedLoading(o) {
	// Defaults
	var opt = {
		html: 'Please wait...',
		zIndex: '5000',
		opacity: '0.4',
		width: '200px',
		padding: '20px'
	};
	
	if (o) {
		for (i in o) {
			opt[i] = o[i];
		}
	}
	
	var ie6 = ($.browser.msie && $.browser.version < 7);

	var box = '<div>';		
	if (ie6) {
		box += '<iframe toFade="1" style="background: #777"></iframe>';
	} else { 
		box +='<div toFade="1" style="background: #777"></div>';
	}	
	box += '<div toShow="1" style="width: '+opt.width+'; position: absolute; background: #E5F1FE; padding: '+opt.padding+'; text-align: center; border: 7px solid #fff">'+opt.html+'</div>';
	box += '</div>';
	
	var jqBox = $(box).css({zIndex: opt.zIndex});
	var toShow = jqBox.children("[toShow]");
	var toFade = jqBox.children("[toFade]");

	var jqWindow = $(window);

// ============================================================================
// Privileged methods

	this.show = function () {
		$(document.body).append(jqBox);
		
		positionPrompt();
		stylePrompt();	
		
		if (ie6) jqWindow.scroll(ie6scroll); //ie6, add a scroll event to fix position:fixed
		jqWindow.resize(positionPrompt);
		
		// Show it
		toFade.fadeIn("normal");
		toShow.show("normal");
	};

	this.hide = function () {
		removePrompt();
	};
	
	this.html = function(html) {
		toShow.html(html);
	}

// ============================================================================
// Private methods
	
	var getWindowScrollOffset = function(){ 
		return (document.documentElement.scrollTop || document.body.scrollTop) + 'px'; 
	};		
	
	var getWindowSize = function(){ 
		var size = {
			width: window.innerWidth || (window.document.documentElement.clientWidth || window.document.body.clientWidth),
			height: window.innerHeight || (window.document.documentElement.clientHeight || window.document.body.clientHeight)
		};
		return size;
	};
	
	var ie6scroll = function(){ 
		jqBox.css({ top: getWindowScrollOffset() }); 
	};
	
	var positionPrompt = function(){
		var wsize = getWindowSize();
		jqBox.css({ position: (ie6)? "absolute" : "fixed", height: wsize.height, width: "100%", top: (ie6)? getWindowScrollOffset():0, left: 0, right: 0, bottom: 0 });
		toFade.css({ position: "absolute", height: wsize.height, width: "100%", top: 0, left: 0, right: 0, bottom: 0 });
		toShow.css({ position: "absolute", top: "40%", left: "50%", marginLeft: ((((toShow.css("paddingLeft").split("px")[0]*1) + toShow.width())/2)*-1) });					
	};
	
	var stylePrompt = function(){
		toFade.css({ zIndex: opt.zIndex+1, display: "none", opacity: opt.opacity });
		toShow.css({ zIndex: opt.zIndex+2, display: "none" });
	};
	
	var removePrompt = function(callCallback, clicked, msg){
		toShow.remove(); 
		if (ie6) jqWindow.unbind('scroll',ie6scroll); //ie6, remove the scroll event
		jqWindow.unbind('resize',positionPrompt);
					
		toFade.fadeOut("normal", function(){
			toFade.remove();
			jqBox.remove();
		});
	};
};