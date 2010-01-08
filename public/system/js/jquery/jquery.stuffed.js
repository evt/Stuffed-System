/**
 * jQuery.Stuffed
 * Copyright (c) Sergey Smirnov - eycher@gmail.com
 * ver 1.0 - 2009/12/08
 */

(function($) {

	$.stuffed = {
		__stash: {},
		
		defaults: {
			loadingHTML: 'Loading, please wait&hellip;',
			
			markErrorFields: function(jqField) {
				jqField.parents("td:first").prev().css({
					color: 'red'
				})
			},
			
			clearErrorFields: function(jqField) {
				jqField.parents("td:first").prev().css({
					color: '#000'
				})
			} 
		},
	
		setDefaults: function(o) {
			$.stuffed.defaults = $.extend({}, $.stuffed.defaults, o);
		},
		
		getDefault: function(key) {
			return $.stuffed.defaults[key];
		},
		
		stash: function(o) {
			if (!o) return false;
			if (typeof o == 'object') {
				for (i in o) $.stuffed.__stash[i] = o[i];
			} else {
				return $.stuffed.__stash[o];
			}
		}
	};
	
	/* options = {
		data, rowClass, removeOnClose, success = function, error = function, loadingHTML
		jqRow, chainEvent
	} */
	$.fn.stuffed_extraRow = function(url, o) {
		o = $.extend({}, $.stuffed.defaults, o);

		return this.each(function() {
			var jqThis = $(this);
	
			if (jqThis.data('inProcess')) {
				return false;
			} else {
				jqThis.data("inProcess", true);
			}
			
			if (o.jqRow) {
				var jqRow = o.jqRow;
			} else {
				var jqRow = this.tagName.toLowerCase() == 'tr' ? jqThis : jqThis.parents("tr:first");
			}

			var rowTagName = jqRow.get(0).tagName.toLowerCase(); 
			var jqExtraRow = jqThis.data('jqExtraRow');
			
			// the additional row has not been created yet
			if (!jqExtraRow) {
				jqExtraRow = $(document.createElement(rowTagName)).attr({
					"__stuffed": 1,
					"class": o.rowClass || jqRow.attr('class') // "class" should be quoted or JS errors in IE8 at least
				});
				jqExtraRow.data("__opened", true).insertAfter(jqRow);
				
				var totalCells = 0;
				
				if (rowTagName == "tr") {
					jqRow.children().each(function() {
						var colSpan = $(this).attr('colSpan');
						totalCells += colSpan ? parseInt(colSpan) : 1;
					});
				}
				
				if (rowTagName == "tr") {
					var jqCell = $(document.createElement('td')).attr({colSpan: totalCells}).css({padding: 0});	
				} else {
					var jqCell = $(document.createElement('div')).css({padding: 0});
				}
				
				jqCell.appendTo(jqExtraRow);				
				if (o.loadingHTML) jqCell.html(o.loadingHTML);				
				
				jqThis.data('jqExtraRow', jqExtraRow);
				jqExtraRow.data('jqOriginalRow', jqRow);

				if (o.chainEvent) jqExtraRow.data('chainEvent', o.chainEvent)
				
				if (!jqRow.data('jqAllExtraRows')) jqRow.data('jqAllExtraRows', []);
				var jqAllExtraRows = jqRow.data('jqAllExtraRows');
				jqAllExtraRows.push(jqExtraRow);
				
				$.ajax({
					url: url,
					data: o.data,
					cache: false,
					success: function (data, textStatus) {
						if (o.success) {
							o.success(data, jqCell);
							jqCell.find("input[type=text], textarea").eq(0).focus();
						} else {
							jqCell.hide().html(data).fadeIn("normal", function() {
								jqCell.find("input[type=text], textarea").eq(0).focus();								
							});
						}
						jqThis.removeData('inProcess');
						if (o.chainEvent) $.stuffed.eventChain.add(o.chainEvent);
					},
					error: function(XMLHttpRequest, textStatus, errorThrown) {
						jqThis.removeData('inProcess');
						if (o.error) {
							o.error(XMLHttpRequest.responseText, jqCell);
						} else if (XMLHttpRequest.responseText) {
							$.prompt(XMLHttpRequest.responseText);
						}
						jqThis.removeData('jqExtraRow');
						jqExtraRow.remove();
					}
				});
			} 
		
			// the additional row already exists we just need to toggle its visibility	
			else {
				// if the row is currently opened, close it
				if (jqExtraRow.data("__opened")) {
					jqExtraRow.removeData("__opened");
					
					jqExtraRow.find(rowTagName == "tr" ? "td:first" : "div:first").fadeOut("normal", function () {
						jqThis.removeData('inProcess');
						if (o.removeOnClose) {
							jqThis.removeData('jqExtraRow');
							jqExtraRow.remove();
						} else {
							jqExtraRow.hide();
						}
					});
					if (o.chainEvent) $.stuffed.eventChain.remove(o.chainEvent);
				} else {
					jqExtraRow.data("__opened", true).show();
					jqExtraRow.find(rowTagName == "tr" ? "td:first" : "div:first").fadeIn("normal", function() {
						jqThis.removeData('inProcess');
					});
					if (o.chainEvent) $.stuffed.eventChain.add(o.chainEvent);
				}
			}
		});
	};
	
	$.fn.stuffed_initForm = function(o) {
		return this.each(function() {
			$(this).submit(function() {
				$(this).stuffed_submitForm(o);
				return false;
			});
		});
	};
	
	$.fn.stuffed_submitForm = function(o) {
		o = $.extend({
			on_success: null, // execute function inside the standard success handler
			success:	null, // replace success handler with the specified function
			dataType:	null,  // non standard jQuery Ajax dataType
			markErrorFields: null, // handler to mark specified error field as errouneous on error
			clearErrorFields: null, // handler to clear the marking on the previosly marked error fields
			beforeSend: null // function to run before sending the form, if it will return false, the form won't be sent
		}, $.stuffed.defaults, o);
		
		return this.each(function() {
			var oForm = this;
			var jqForm = $(this);
			if (!jqForm.attr('action')) return false;
			
			if (o.beforeSend && !o.beforeSend(jqForm)) {
				return false;
			}
			
			if (o.clearErrorFields) {
				jqForm.find('[wasErrorMarked]').each(function(){
					o.clearErrorFields($(this));
				}).removeAttr('wasErrorMarked');
			}
			
			var jqProgress = jqForm.find("[submitProgress]");
			if (jqProgress.length > 0) setTimeout(function() {jqProgress.show()}, 0);
			
			$.ajax({
				type: jqForm.attr('method') || 'get',
				url: jqForm.attr('action'),
				dataType: (o.dataType ? o.dataType : 'html'),
				cache: false,
				data: jqForm.stuffed_formValues(),
				beforeSend: function(request) {
					request.setRequestHeader("X-Expect-JSON-In-Error", 1);
				},
				error: function(XMLHttpRequest, textStatus, errorThrown) {
					var data = XMLHttpRequest.responseText;
		
					jqProgress.hide();
					
					try { var json = eval('(' + data + ')') } catch(e) {};
		
					var afterPromptFocusOn = jqForm.find(":text, :password").not("[readonly]").eq(0);
								
					if (typeof json == 'object' && json.msg) {
						if (json.fields) {
							if (o.markErrorFields) {
								for (var i = 0; i < json.fields.length; i++) {
									var jqField = $(oForm[json.fields[i]]);
									o.markErrorFields(jqField);
									jqField.attr({wasErrorMarked: true});
								}
							}
		
							afterPromptFocusOn = jqForm.find("[name="+json.fields[0]+"]").eq(0);
						}
		
						data = json.msg;
					}
		
					if (data) {
						$.prompt(data, {
							callback: function(){
								afterPromptFocusOn.focus();
							}
						});
					} else {
						afterPromptFocusOn.focus();
					}
				},
				success: function (data, textStatus) {
					jqProgress.hide();
				
					if (o.success) {
						o.success(data, jqForm);
					} else {
						jqForm.parent().fadeOut('normal', function() {
							var jqFormContainer = $(this);
							jqFormContainer.html(data).fadeIn('normal', function() {
								if (o.on_success) o.on_success(data, jqFormContainer);
								jqFormContainer.find(":text, :password").not("[readonly]").eq(0).focus();
							});
							if ($.scrollTo) $.scrollTo(jqFormContainer, {duration: 1000})
						});
					}
				}
			})
		});
	};
	
	$.fn.stuffed_formValues = function() {
		var oData = {};
		
		this.each(function() {
			var oForm = this;
			
			if (!oForm.elements || !oForm.length) return oData;
		
			for (i = 0; i < oForm.length; i++) {
				var field = oForm.elements[i];
				// skip the field if it is a checkbox or a radio button and it is not checked
				if ((field.type == 'checkbox' || field.type == 'radio') && !field.checked) continue;
				
				// skip the field if it doesn't have a name (submit button)
				if (!field.name) continue;
		
				if (oData[field.name] == null) {
					oData[field.name] = [$(field).val()];
				} else {
					oData[field.name].push($(field).val());
				}
			}
		});
		
		return oData;		
	};
	
	$.fn.stuffed_clearForm = function(o) {
		o = $.extend({
			except: null // array of names to skip
		}, o);
		return this.each(function() {
			var form = this;
			for (i in form.elements) {
				var element = form.elements[i];
				if (o.except && $.inArray(element.name, o.except) > -1) continue;
				if (!element.type || !element.tagName) continue;
				if (element.type == 'text' || element.tagName.toLowerCase() == 'textarea') element.value = ''; 
				if (element.type == 'checkbox' || element.type == 'radio') element.checked = false;
				// selecting the first element in popupmenu
				if (element.tagName.toLowerCase() == 'select') element[0].selected = true;
			}
		});
	};

	var colorTransition = ['transparent','#ffe','#ffd','#ffc','#ffb','#ffa','#ff9'];
	
	var colorFade = function(jqThis, colors) {
		if (colors.length == 0) return false; 
		jqThis.css({ background: colors.pop() });
		setTimeout(function() { colorFade(jqThis, colors) }, 100);
	};

	$.fn.stuffed_flashElement = function(firstDelay) {
		return this.each(function() {
			var jqThis = $(this);
		  	setTimeout(function() { 
					colorFade(jqThis, [].concat(colorTransition)) 
				}, 
				firstDelay == null ? 300 : firstDelay
			);
		});
	}
	
	// o - loadingHTML, chainEvent, data, on_success
	$.fn.stuffed_load = function(url, o) {
		if  (!url) return this;
		o = $.extend({}, $.stuffed.defaults, o);
		return this.each(function() {
			var jqThis = $(this);
			jqThis.data('disableDefault', true);
			if (o.loadingHTML) jqThis.html(o.loadingHTML);
			$.ajax({
				url: url,
				data: o.data,
				success: function (data) {
					if (o.on_success) o.on_success(data);
					jqThis.hide().html(data).fadeIn("fast", function() {
						$(this).find("input[type=text]:first").focus()
					});
					if (o.chainEvent) $.stuffed.eventChain.add(o.chainEvent);
				}
			});
		});
	}
	
	$.fn.objIsEmpty = function() {
		var obj = this.get(0);
		for (var prop in obj) {
			if (obj.hasOwnProperty(prop)) return false;
		}
		return true;
	}
	
})(jQuery);