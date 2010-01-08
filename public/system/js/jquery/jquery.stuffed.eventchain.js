/**
 * jQuery Stuffed Event Chain
 * Version 1.1 
 * Copyright (c) 2009 Sergey Smirnov - eycher@gmail.com
 * 
 * 1.1 — moved to using jquery.hashchange instead of jquery.history
 */

(function($) {
	$.stuffed.eventChain = {
		signature: '/',
		separator: {
			events: '/',
			type:	'.',
			params:	':'
		},
		
		init: function() {
			var evThis = this;
			$(window).hashchange(function(e) {
				var newChain = evThis.parseHash(document.location.hash.substr(1));

				// if the very first step is different in the old and new chains,
				// and also new chain contains at least something (ie. it's not the case
				// when hash was cleared completely) we then silently clear the current chain
				// without doing any rollbacks on the steps being removed
				if (newChain[0] && evThis.chain[0] && evThis.eventsDiffer(newChain[0], evThis.chain[0])) {
					evThis.chain = [];
					evThis.run(newChain);
					return;
				}

				
				var idxNewChain = {};
				for (var i = 0; i < newChain.length; i++) {
					var event = newChain[i];
					if (!idxNewChain[event.id]) idxNewChain[event.id] = {};
					idxNewChain[event.id][event.type] = event; 
				}
				
				var idxOldChain = {};
				for (var i = 0; i < evThis.chain.length; i++) {
					var event = evThis.chain[i];
					if (!idxOldChain[event.id]) idxOldChain[event.id] = {};
					idxOldChain[event.id][event.type] = event; 
				}

				// #/content:default/ul_386/ul_385 -> #/content:default/ul_385 
				// rollback ul_386 and do nothing else, in other words;
				// rollback what is present in evThis.chain and missing in newChain and
				// run what is missing in evThis.chain and present in newChain
				evThis.rollback(
					$.grep(evThis.chain, function(event, i) {
						return (!idxNewChain[event.id] || !idxNewChain[event.id][event.type]);
					})
				);
				
				evThis.run(
					$.grep(newChain, function(event, i) {
						return (!idxOldChain[event.id] || !idxOldChain[event.id][event.type]);
					})
				);
			});				

			var hash = document.location.hash.substr(1);
			if (hash) this.run(this.parseHash(hash));
			
			return this;
		},
		
		rollback: function(chain) {
			if (!chain || chain.length < 1) return this;
			var event = chain.pop();
			$('#'+event.id).livequery(function() {
				$(this).trigger(event.type, { 
					isRollback: true, 
					noHashUpdate: true,
					params: event.params 
				});

				event.noHashUpdate = true;
				$.stuffed.eventChain.remove(event);
								
				// expire livequery
				$('#'+event.id).expire();
			});
			$.stuffed.eventChain.rollback(chain);
		},
		
		run: function(chain) {
			if (!chain || chain.length < 1) return this;
			var event = chain.shift();
			$('#'+event.id).livequery(function() {
				$(this).trigger(event.type || "click", {
					noHashUpdate: true,
					params: event.params
				});
				$('#'+event.id).expire();
			});
			$.stuffed.eventChain.run(chain);
			return this;
		},
		
		add: function(o) {
			if (!o) o = {};
			if (typeof o == 'string') o = { id: o };
			if (!o.type) o.type = 'click';
			
			if (!this.chain || o.newChain) {
				this.chain = [];
			} else {
				// first, remove element with the same id and event type from the chain
				this.chain = $.grep(this.chain, function(element, i) {
					return (element.id != o.id || element.type != o.type);
				});
			}
			
			var event = {
				id: o.id,
				type: o.type,
				params: o.params
			};
			
			this.chain.push(event);
			
			if (!o.noHashUpdate) this.updateHash();
			
			return this;
		},
	
		remove: function(o) {
			if (!o) o = {};
			if (!o.type) o.type = 'click';
			
			if (!this.chain || this.chain.length < 1) return this;
			
			this.chain = $.grep(this.chain, function(element, i) {
				return (element.id != o.id || element.type != o.type);
			});
			
			if (!o.noHashUpdate) this.updateHash();
			
			return this;
		},
		
		parseHash: function(hash) {
			var self = this;
			
			if (!hash || hash.substr(0, this.signature.length) != this.signature) {
				return [];
			}

			return $.map(hash.substr(this.signature.length).split(this.separator.events), function(element, i) {
				var found = element.split(self.separator.params);
				var params;
				
				if (found[1]) {
					var pairs = found[1].split('&');
					for (var i = 0; i < pairs.length; i++) {
						var key_value = pairs[i].split('=');
						if (!params) params = {};
						if (!params[ key_value[0] ]) params[ key_value[0] ] = [];
						params[ key_value[0] ].push( decodeURIComponent(key_value[1].replace(/\$/g, '%')).replace(/\+/g, " ") ); 
					}
					element = found[0];
				}

				var event = element.split(self.separator.type);
				// default event type is click
				if (!event[1]) event[1] = 'click';

				return {
					id: event[0],
					type: event[1],
					params: params
				};
			});			
		},
		
		updateHash: function() {
			var hash = '';
			var self = this;
			
			if (this.chain && this.chain.length > 0) {
				hash = this.signature+$.map(this.chain, function(element, i) {
					var string = element.id+(element.type && element.type != 'click' ? self.separator.type+element.type : '')
					if (element.params) {
						string += self.separator.params+$.param(element.params || {}).replace(/%/g, '$');
					}
					return string; 
				}).join(this.separator.events);
			}
			
			if (document.location.hash.substr(1) != hash) {
				if ($.locationHash) 
					$.locationHash(hash);
				else 
					document.location.hash = hash;
			}
			
			return this;
		},
		
		eventsDiffer: function(event1, event2) {
			if (!event1 && !event2) return false;
			if (!event1 || !event2) return true;
			if (event1.id != event2.id && event1.type != event2.type) return true;
			if (event1.params && !event2.params) return true;			
			if (!event1.params && event2.params) return true;
			if ($.param(event1.params || {}) != $.param(event2.params || {})) return true;
			
			return false;
		}
	};
})(jQuery);