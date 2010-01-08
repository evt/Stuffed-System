/* 
 INFORMATION
 Name:			Stuffed Selection class
 Version:		1.0
 Author:		Sergey Smirnov / Stuffed Guys
 Site:			www.stuffedguys.org
 Desc:			Cross-browser textarea selection handling.
 
 */
function StuffedSelection(textBoxId){
	if (!textBoxId) return false;
	var textBox = document.getElementById(textBoxId);
	if (!textBox) 
		return false;
	
	this.textBox = textBox;
	
	// ie
	if (document.selection && textBox.isTextEdit) {
		textBox.focus();
		
		this.type = 1;
		this.selection = document.selection;
		this.range = this.selection.createRange();
		this.text = this.range.text;
	}
	
	// something fancy
	else 
		if (textBox.selectionEnd != null) {
			this.selectionStart = textBox.selectionStart;
			this.selectionEnd = textBox.selectionEnd;
			this.scrollTop = textBox.scrollTop;
			
			this.type = 2;
			this.startText = (textBox.value).substring(0, this.selectionStart);
			this.text = (textBox.value).substring(this.selectionStart, this.selectionEnd);
			this.endText = (textBox.value).substring(this.selectionEnd, textBox.textLength);
		}
		
		// something dull
		else {
			this.type = 0;
		}
	
	if (this.text == null || this.text == 'undefined') {
		this.text = '';
	}
};

StuffedSelection.prototype.get = function(){
	return this.text;
};

StuffedSelection.prototype.insert = function(content){
	if (!this.textBox || content == null) 
		return false;
	
	if (this.type == 1) {
		if ((this.selection.type == 'Text' || this.selection.type == 'None') && this.range != null) {
			this.range.text = content;
		}
	}
	
	else 
		if (this.type == 2) {
			this.textBox.value = this.startText + content + this.endText;
			
			var cpos = this.selectionStart + (content.length);
			
			this.textBox.selectionStart = cpos;
			this.textBox.selectionEnd = cpos;
			this.textBox.scrollTop = this.scrollTop;
		}
		
		else {
			this.textBox.value += content;
		}
	
	this.textBox.focus();
};
