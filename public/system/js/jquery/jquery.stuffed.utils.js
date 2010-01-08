/**
 * jQuery Stuffed Event Chain
 * Version 1.0
 * Copyright (c) 2009 Sergey Smirnov - eycher@gmail.com 
 */

(function($) {
	$.stuffed.utils = {
		plural_ru: function(o) {
			o = $.extend({
				number: null,
				0: null, // ноль "процентов"
				1: null, // один "процент"
				2: null  // два "процента"
			}, o);
			
			if (String(o.number).match(/1.$/)) return o['0'];
			
			var found = String(o.number).match(/(.)$/);
			if (!found) return "";
			
			var lastDigit = found[1];
			if (lastDigit == 1) return o['1'];
			if (lastDigit > 0 && lastDigit < 5) return o['2'];
			
			return o['0'];
		}
	};
})(jQuery);