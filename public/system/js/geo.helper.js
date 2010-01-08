/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
/*  Latitude/longitude spherical geodesy formulae & scripts (c) Chris Veness 2002-2009            */
/* - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -  */
/* 
 * Short version from 16 Sep 2009 for Idefit
 * Original — http://www.movable-type.co.uk/scripts/latlong.html
 */
/*
 * Use Haversine formula to calculate distance (in km) between two points specified by
 * latitude/longitude (in numeric degrees)
 *
 * from: Haversine formula - R. W. Sinnott, "Virtues of the Haversine",
 *       Sky and Telescope, vol 68, no 2, 1984
 *       http://www.census.gov/cgi-bin/geo/gisfaq?Q5.1
 */
function geoCalculateDistance(lat1, lon1, lat2, lon2){
	var toRad = function(v){
		return v * Math.PI / 180
	}
	var R = 6371; // earth's mean radius in km
	var dLat = toRad(lat2 - lat1);
	var dLon = toRad(lon2 - lon1);
	lat1 = toRad(lat1), lat2 = toRad(lat2);
	
	var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
	Math.cos(lat1) * Math.cos(lat2) *
	Math.sin(dLon / 2) *
	Math.sin(dLon / 2);
	var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
	var d = R * c;
	
	return d.toFixed(2);
}

// Source — http://www.provide.net/~bratliff/adjust.js
function geoPixelsCalc(googleMap){
	var offset = 268435456;
	var radius = offset / Math.PI;
	
	function LToX(x){
		return Math.round(offset + radius * x * Math.PI / 180);
	}
	
	function LToY(y){
		return Math.round(offset - radius * Math.log((1 + Math.sin(y * Math.PI / 180)) / (1 - Math.sin(y * Math.PI / 180))) / 2);
	}
	
	function XToL(x){
		return ((Math.round(x) - offset) / radius) * 180 / Math.PI;
	}
	
	function YToL(y){
		return (Math.PI / 2 - 2 * Math.atan(Math.exp((Math.round(y) - offset) / radius))) * 180 / Math.PI;
	}

//	X = X pixel offset of new map center from old map center
//	Y = Y pixel offset of new map center from old map center

//	result.lng = Longitude of adjusted map center
//	result.lat = Latitude  of adjusted map center
	
	this.XYToLL = function(X, Y){
		var x = googleMap.getCenter().lng();
		var y = googleMap.getCenter().lat();
		var z = googleMap.getZoom();
		  
		return {
			lng: XToL(LToX(x) + (X << (21 - z))),
			lat: YToL(LToY(y) + (Y << (21 - z)))
		};
	}

//	lng = Longitude of marker center
//	lat = Latitude  of marker center

//	result.x = X pixel offset of marker center from map center
//	result.y = Y pixel offset of marker center from map center
	
	this.LLToXY = function(lng, lat){
		var x = googleMap.getCenter().lng();
		var y = googleMap.getCenter().lat();
		var z = googleMap.getZoom();  
		
		return {
			x: (LToX(lng) - LToX(x)) >> (21 - z),
			y: (LToY(lat) - LToY(y)) >> (21 - z)
		};
	}
	
	return this;
}