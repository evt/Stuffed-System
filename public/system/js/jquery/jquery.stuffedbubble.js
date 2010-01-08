				/**
 * Stuffed Bubble, a jQuery plugin
 * Copyright (c) Sergey Smirnov - eycher@gmail.com
 * ver 1.0 - 2009/12/09
 */

(function($) {
	$.stuffedBubble = {
		defaults: {
			bubble: {
				width: 200,
				height: 200
			},
			border: {
				color: '#000',
				size: 8,
				radius: 20,
				opacity: 0.5
			},
			content: {
				radius: 14
			},
			showTimeout: 200,
			hideTimeout: 200
		},
		
		setDefaults: function(o) {
			// "true" to make a deep copy
			$.stuffedBubble.defaults = $.extend(true, {}, $.stuffedBubble.defaults, o);
		}
	};
	
	$.fn.stuffedBubble = function(o) {
		o = $.extend(true, {}, $.stuffedBubble.defaults, o);
		
		return this.each(function() {
			var jqThis = $(this);
			
			jqThis.mouseover(function(e) {
				if (jqThis.data("__stuffedBubbleHideTimer")) clearInterval(jqThis.data("__stuffedBubbleHideTimer"));
				
				var jqBubble = jqThis.data("__stuffedBubble");
				if (jqBubble && jqBubble.is(":visible")) return false;
				
				jqThis.data("__stuffedBubbleShowTimer", setTimeout(function() {
						// checking if jqBubble is in data AGAIN because 200 ms has passed since last check above 
						jqBubble = jqThis.data("__stuffedBubble");
						if (!jqBubble) {
							jqBubble = $.fn.stuffedBubble.create(jqThis, o);
							jqThis.data("__stuffedBubble", jqBubble);
						}
						
						$.fn.stuffedBubble.show(jqBubble, e);
					}, o.showTimeout)
				);
			})
			
			jqThis.mouseout(function(e) {
				if (jqThis.data("__stuffedBubbleShowTimer")) clearInterval(jqThis.data("__stuffedBubbleShowTimer"));
				jqThis.data("__stuffedBubbleHideTimer", setTimeout(function() {
						var jqBubble = jqThis.data("__stuffedBubble");
						if (jqBubble) jqBubble.hide("fast");
					}, o.hideTimeout)
				);
			});
		});
	};
	
	$.fn.stuffedBubble.show = function(jqBubble, e) {
		if (!e || !e.target) return false;

		var target = $(e.target).offset();
		target.width = $(e.target).width();
		target.height = $(e.target).height();
		
		var bubble = {
			o: jqBubble.data("o") || {}, 
			width: jqBubble.width(),
			height: jqBubble.height(),
			position: "right" // default position is to the right of the target element
		};

		// ideal position		
		bubble.left = target.left + target.width + 5;			
		bubble.top = target.top + parseInt(target.height/2) - parseInt(bubble.height/2);
		
		// top correction according to the actual window size
		if (bubble.top + bubble.height > $(window).height()) {
			bubble.top = $(window).height() - bubble.height;
		}
		if (bubble.top < 0) bubble.top = 0; 
		
		// position correction according to the actual window size
		if (bubble.left + bubble.width > $(window).width()) {
			var newLeft = target.left - bubble.width - 5 - (bubble.o.arrow ? bubble.o.arrow.width : 0);
			// only use left position if it fits in the screen, otherwise stay at the default "right" one
			if (newLeft >= 0) {
				bubble.position = "left";
				bubble.left = newLeft;
			}
		} 
		
		jqBubble.css({ left: bubble.left, top: bubble.top });

		// arrow, display display & position
		var border = { jQuery: jqBubble.children("div").eq(0) };
		var content = { jQuery: jqBubble.children("div").eq(1) };
		var arrow = { jQuery: jqBubble.children("div").eq(2) };

		if (bubble.o.arrow) {
			arrow.jQuery.css({
				position: 'absolute',
				left: bubble.position == "right" ? 0 : bubble.width,
				opacity: bubble.o.border.opacity,
				width: bubble.o.arrow.width,
				height: bubble.o.arrow.height,
				overflow: 'hidden',
				backgroundImage: "url("+bubble.o.arrow.url+")",
				backgroundPosition: bubble.position == "right" ? "0 0" : bubble.o.arrow.width+"px 0"  	
			});

			arrow.top = target.top + parseInt(target.height/2) - bubble.top - parseInt(bubble.o.arrow.height/2);
	
			if (arrow.top + bubble.o.arrow.height > bubble.height - bubble.o.border.radius) {
				arrow.top = bubble.height - bubble.o.border.radius - bubble.o.arrow.height;
			}
			arrow.jQuery.css({ top: arrow.top });
			
			if (bubble.position == "right") {
				border.jQuery.css({ left: bubble.o.arrow.width });
				content.jQuery.css({ left: bubble.o.border.size+bubble.o.arrow.width });
			}
		} else {
			arrow.jQuery.hide();
		}
		
		return jqBubble.show("fast");
	};
	
	$.fn.stuffedBubble.create = function(jqThis, o) {
		if (!o) o = {};
		
		var jqBubble = $("<div><div></div><div></div><div></div></div>").css({
			position: 'absolute',
			width: o.bubble.width,
			height: o.bubble.height,
			display: 'none'
		});
		
		jqBubble.attr({__stuffedBubble: true});
		jqBubble.data("o", o);
		
		jqBubble.mouseover(function() {
			jqThis.mouseover();
		}).mouseout(function() {
			jqThis.mouseout();
		});

		var jqDivs = jqBubble.children("div");
		
		// border
		jqDivs.eq(0).css({
			position: 'absolute',
			overflow: 'hidden',
			left: 0,
			top: 0,
			width: o.bubble.width,
			height: o.bubble.height,
			background: o.border.color,
			opacity: o.border.opacity,
			'-moz-border-radius': o.border.radius, 
			'-webkit-border-radius': o.border.radius
		});

		// content
		jqDivs.eq(1).html(o.html).css({
			position: 'absolute',
			overflow: 'hidden',			
			left: o.border.size,
			top: o.border.size,
			background: '#fff',
			width: o.bubble.width - (o.border.size*2),
			height: o.bubble.height - (o.border.size*2),
			'-moz-border-radius': o.content.radius, 
			'-webkit-border-radius': o.content.radius
		});
		
		return jqBubble.appendTo("body");
	};

})(jQuery);