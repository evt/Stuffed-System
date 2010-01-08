/**
 * jQuery hashchange 1.0.1
 * 
 * History: 
 * 	1.0.1 - added proper onhashchange detection & removed unused and excessive code
 * 
 * Warning!
 * 	You need to ALWAYS make changes to document.location.hash through $.locationHash(newHash) function 
 * 
 * (based on jquery.history)
 *
 * Copyright (c) 2008 Chris Leishman (chrisleishman.com)
 * Dual licensed under the MIT (MIT-LICENSE.txt)
 * and GPL (GPL-LICENSE.txt) licenses.
 */
(function($) {
	$.fn.extend({
	    hashchange: function(callback) { this.bind('hashchange', callback) }
	});
	
	var curHash;
	// hidden iframe for IE (earlier than 8)
	var iframe;
	
	$(document).ready(function() {
		// this test requires that document.body is present already 
		if (isHashChangeSupported()) {
			$.extend({ 
				locationHash: function(hash) {
					if (!hash) hash = '#';
					else if (hash.charAt(0) != '#') hash = '#' + hash;
					location.hash = hash;
				}  
			});
			return;
		} 
		
		$.extend({
			locationHash: function(hash) {
				if (curHash === undefined) return;
		
				if (!hash) hash = '#';
				else if (hash.charAt(0) != '#') hash = '#' + hash;
				
				location.hash = hash;
				
				if (curHash == hash) return;
				curHash = hash;
				
				if ($.browser.msie) updateIEFrame(hash);
				$.event.trigger('hashchange');
			}
		});		
	
		$(window).unload(function() { iframe = null });
	    
		curHash = location.hash;
		if ($.browser.msie) {
			// stop the callback firing twice during init if no hash present
			if (curHash == '') curHash = '#';
			// add hidden iframe for IE
			iframe = $('<iframe />').hide().get(0);
			$('body').prepend(iframe);
			updateIEFrame(location.hash);
			setInterval(checkHashIE, 100);
		} else {
			setInterval(checkHash, 100);
		}
	});

	function checkHash() {
	    var hash = location.hash;
	    if (hash != curHash) {
	        curHash = hash;
	        $.event.trigger('hashchange');
	    }
	}
	
	function checkHashIE() {
	    // On IE, check for location.hash of iframe
	    var idoc = iframe.contentDocument || iframe.contentWindow.document;
	    var hash = idoc.location.hash;
	    if (hash == '') hash = '#';
		
	    if (hash != curHash) {
	        if (location.hash != hash) location.hash = hash;
	        curHash = hash;
	        $.event.trigger('hashchange');
	    }
	}
	
	function updateIEFrame(hash) {
	    if (hash == '#') hash = '';
	    var idoc = iframe.contentWindow.document;
	    idoc.open();
	    idoc.close();
	    if (idoc.location.hash != hash) idoc.location.hash = hash;
	}
	
	
	/**
	 * isEventSupported determines if a given element supports the given event
	 * function from http://yura.thinkweb2.com/isEventSupported/
	 * Simplified a little to check only for "onhashchange" event
	 */
	function isHashChangeSupported(){
		if (!document.body) return false;
		
		// IE8 in IE7 compatibility mode doesn't fire onhashchange although it is reported as supported
		if ($.browser.msie && document.documentMode && document.documentMode < 8) return false;
		
		var element = document.body;
		var eventName = 'onhashchange';
		
		// When using `setAttribute`, IE skips "unload", WebKit skips "unload" and "resize"
		// `in` "catches" those
		var isSupported = (eventName in element);
		
		if (!isSupported && element.setAttribute) {
			element.setAttribute(eventName, 'return;');
			isSupported = typeof element[eventName] == 'function';
		}
		
		return isSupported;
	}

})(jQuery);