/* 
 INFORMATION
 Name:			Stuffed Sort Table class
 Author:		Sergey Smirnov / Stuffed Guys
 Site:			www.stuffedguys.org
 Desc:			Provides a easy way to sort rows in a table without page reload.
 */
var stuffedSortOrder = false;
var stuffedCompareAsStrings = false;

function StuffedSortTable(){
};

StuffedSortTable.prototype.getParentNodeByTagName = function(child, tagName){
	if (!child || !tagName) 
		return false;
	var parentNode = child;
	var foundParent = false;
	while (!foundParent) {
		if (!parentNode) 
			break;
		if (parentNode.tagName.toLowerCase() == tagName.toLowerCase()) {
			foundParent = parentNode;
		}
		else {
			parentNode = parentNode.parentNode;
		}
	}
	return foundParent;
};

StuffedSortTable.prototype.getChildNodesByTagName = function(parent, tagName){
	if (!parent || !parent.childNodes || !tagName) 
		return false;
	
	var children = parent.childNodes;
	var nodes = new Array();
	for (var i = 0; i < children.length; i++) {
		if (!children[i].tagName || children[i].tagName.toLowerCase() != tagName.toLowerCase()) {
			continue;
		}
		nodes.push(children[i]);
	}
	if (nodes.length == 0) 
		nodes = false;
	return nodes;
};

StuffedSortTable.prototype.getObjParams = function(obj){
	if (!obj) 
		return false;
	var allParams = new Array();
	for (i in obj) {
		allParams.push(i + ' = ' + obj[i]);
	}
	return allParams;
};

StuffedSortTable.prototype.compareRows = function(a, b){
	var newA = (stuffedCompareAsStrings ? String(a.value) : Number(a.value));
	var newB = (stuffedCompareAsStrings ? String(b.value) : Number(b.value));
	
	if (newA > newB) {
		return (stuffedSortOrder == 'asc' ? 1 : -1);
	}
	else 
		if (newA < newB) {
			return (stuffedSortOrder == 'asc' ? -1 : 1);
		}
		else {
			return 0;
		}
};

StuffedSortTable.prototype.sortBy = function(obj, order){
	if (!obj) 
		return false;
	
	var td = this.getParentNodeByTagName(obj, 'td');
	if (!td) 
		return false;
	
	var sortIndex = td.cellIndex;
	
	var tr = this.getParentNodeByTagName(td, 'tr');
	if (!tr) 
		return false;
	
	var tbody = this.getParentNodeByTagName(td, 'tbody');
	if (!tbody) 
		return false;
	
	// default sort order is ascending
	if (order && (order.toLowerCase() == 'asc' || order.toLowerCase() == 'desc')) {
		stuffedSortOrder = order;
	}
	else {
		if (obj.curOrder) {
			stuffedSortOrder = (obj.curOrder == 'asc' ? 'desc' : 'asc');
		}
		else {
			stuffedSortOrder = 'asc';
		}
	}
	
	var rows = this.getChildNodesByTagName(tbody, 'tr');
	var sortRows = new Array();
	
	stuffedCompareAsStrings = false;
	
	for (var i = 0; i < rows.length; i++) {
		var oRow = rows[i];
		
		// skip the row in which a sort link was clicked (this is considered to be
		// a header)
		if (oRow.rowIndex == tr.rowIndex) 
			continue;
		
		// skip this row if it has a 'noSort' attribute set
		if (oRow.attributes && oRow.attributes.noSort) 
			continue;
		
		var cells = this.getChildNodesByTagName(oRow, 'td');
		var sortTd = cells[sortIndex];
		
		var sortValue = false;
		// if special sortValue attribute is specified for a cell we use it,
		// otherwise we will sort by the contents of the cell
		if (sortTd.attributes && sortTd.attributes.sortValue) {
			sortValue = sortTd.attributes.sortValue.nodeValue;
		}
		else {
			sortValue = sortTd.innerHTML;
		}
		
		// if we have at least one string value we force comparision as a
		// string
		if (stuffedCompareAsStrings == false && isNaN(sortValue)) {
			stuffedCompareAsStrings = true;
		}
		
		var oRowSort = new Object();
		oRowSort['row'] = oRow;
		oRowSort['value'] = sortValue;
		sortRows.push(oRowSort);
	}
	
	sortRows = sortRows.sort(this.compareRows);
	sortRows.reverse();
	
	for (var i = 1; i < sortRows.length; i++) {
		var thisRow = sortRows[i].row;
		var prevRow = sortRows[i - 1].row;
		tbody.insertBefore(thisRow, prevRow);
	}
	
	obj.curOrder = stuffedSortOrder;
};
