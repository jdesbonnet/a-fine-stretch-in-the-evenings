/**
 * Draw daylight chart in SVG
 */
(function( $ ) {

	var options;
	var svgEl;
	var wrapperEl;
	var map;
	var marker;
	
	var methods = {
			 init : function( opts ) {
				 options = opts;
				 wrapperEl = this.get(0);
				 init();
			 },
			 update: function (newData) {
				 update(newData);
			 }
	};
	 
	$.fn.daylightchart = function(method) {
		// Method calling logic
		if ( methods[method] ) {
			return methods[ method ].apply( this, Array.prototype.slice.call( arguments, 1 ));
		} else if ( typeof method === 'object' || ! method ) {
			return methods.init.apply( this, arguments );
		} else {
			$.error( 'Method ' +  method + ' does not exist' );
		}
	};
	
	// Create structures that only need to be created onece.
	function init() {	
		var id = wrapperEl.id;
		var formEl = document.createElement("form");
		$(wrapperEl).append(formEl);
		$(formEl).html('<table><tr>\
				<td>Latitude:</td><td><input type="text" class="lat" id="lat_'+id+'" value="888"/></td>\
				<td>Longitude:</td><td><input type="text" class="lon" id="lon_'+id+'" value="777"/></td>\
				<td><button type="button" class="mapBtn" id="mapbtn_'+id+'">Map</button></td>\
				<td>Timezone:</td><td><span class="tz" id="tz_'+id+'"></span></td>\
				</tr></table>\
				');
		
		$(wrapperEl).append('<div class="mapDialog" id="mapdialog_' + id 
				+ '" title="Map selector"><div class="map" id="map_'+id+'"></div>');
		


		svgEl = document.createElementNS("http://www.w3.org/2000/svg", "svg");
		svgEl.setAttribute("width","640");
		svgEl.setAttribute("height","760");
		
		$(wrapperEl).append(svgEl);
		
		

		// Using Google Maps in jQuery UI Dialog:
		// http://iwritecrappycode.wordpress.com/2011/07/18/google-maps-in-jquery-ui-dialog/
		//$(wrapperEl).find(".mapDialog").dialog({
		$("#mapdialog_"+wrapperEl.id).dialog({
			width:640,height:480,
			autoOpen:false,
			resizeStop: function(event, ui) {google.maps.event.trigger(map, 'resize')  },
            open: function(event, ui) {google.maps.event.trigger(map, 'resize'); }      
		});
		
		initializeMap();
		
		//$(wrapperEl).find(".mapBtn").click(function() {
		$("#mapbtn_"+wrapperEl.id).click(function() {
			$("#mapdialog_"+wrapperEl.id).dialog("open");
		});
		
		drawChart();
	}
		
	function update (newData) {
		options.data = newData;
		$(svgEl).empty();
		drawChart();
	}
	
	function drawChart() {		
		defsEl = document.createElementNS("http://www.w3.org/2000/svg", "defs");
		$(defsEl).append('\
				 <linearGradient id="twilight" x1="0%" y1="0%" x2="100%" y2="0%"> \
			      <stop offset="0%" style="stop-color:rgb(0,0,128);stop-opacity:1" /> \
			      <stop offset="4%" style="stop-color:rgb(0,0,255);stop-opacity:1" /> \
			      <stop offset="8%" style="stop-color:rgb(48,32,255);stop-opacity:1" /> \
			      <stop offset="92%" style="stop-color:rgb(48,32,255);stop-opacity:1" /> \
			      <stop offset="96%" style="stop-color:rgb(0,0,255);stop-opacity:1" /> \
			      <stop offset="100%" style="stop-color:rgb(0,0,128);stop-opacity:1" /> \
			    </linearGradient> \
			    <linearGradient id="day" x1="0%" y1="0%" x2="100%" y2="0%"> \
			      <stop offset="0%" style="stop-color:rgb(255,255,0);stop-opacity:1" /> \
			      <stop offset="50%" style="stop-color:rgb(255,200,0);stop-opacity:1" /> \
			      <stop offset="100%" style="stop-color:rgb(255,255,0);stop-opacity:1" /> \
			    </linearGradient> \
	');
		svgEl.appendChild(defsEl);
		
		// Background is black
		var rectEl = document.createElementNS("http://www.w3.org/2000/svg", "rect");
		rectEl.setAttribute("x",options.leftMargin);
		rectEl.setAttribute("y",options.topMargin);
		rectEl.setAttribute("width",options.pixelsPerHour*24);
		rectEl.setAttribute("height",options.pixelsPerDay*365);
		$(svgEl).append(rectEl);
		
		for (var i = 0; i < options.data.riseSet.length; i++) {
			var rec = options.data.riseSet[i];
			// Twilight
			var twilightRectEl = document.createElementNS("http://www.w3.org/2000/svg", "rect");
			twilightRectEl.setAttribute("x",options.leftMargin + rec[0]*options.pixelsPerHour);
			twilightRectEl.setAttribute("y",options.topMargin + i*options.pixelsPerDay);
			twilightRectEl.setAttribute("width", (rec[3] - rec[0])*options.pixelsPerHour);
			twilightRectEl.setAttribute("height", options.pixelsPerDay);
			twilightRectEl.setAttribute("fill", "url(#twilight)");
			$(svgEl).append(twilightRectEl);

			var dayRectEl = document.createElementNS("http://www.w3.org/2000/svg", "rect");
			dayRectEl.setAttribute("x",options.leftMargin + rec[1]*options.pixelsPerHour);
			dayRectEl.setAttribute("y",options.topMargin + i*options.pixelsPerDay);
			dayRectEl.setAttribute("width", (rec[2] - rec[1])*options.pixelsPerHour);
			dayRectEl.setAttribute("height", options.pixelsPerDay);
			dayRectEl.setAttribute("fill", "url(#day)");
			$(svgEl).append(dayRectEl);
		}
		
		// Horizontal grid
		for (var h = 0; h < 24; h++) {
			var hx = h * options.pixelsPerHour + options.leftMargin + 0.5;
			var lineEl = document.createElementNS("http://www.w3.org/2000/svg", "line");
			lineEl.setAttribute("x1",hx);
			lineEl.setAttribute("y1",options.topMargin);
			lineEl.setAttribute("x2",hx);
			lineEl.setAttribute("y2",options.topMargin + 365*options.pixelsPerDay);
			lineEl.setAttribute("stroke","#888");
			lineEl.setAttribute("stroke-opacity","0.5");
			$(svgEl).append(lineEl);
			
			var textEl = document.createElementNS("http://www.w3.org/2000/svg", "text");
			textEl.setAttribute("x",hx);
			textEl.setAttribute("y",options.topMargin-2);
			textEl.setAttribute("style","font-size:8pt");
			$(textEl).append(""+h+"h");
			$(svgEl).append(textEl);
		
		}
		
		var textEl = document.createElementNS("http://www.w3.org/2000/svg", "text");
		textEl.setAttribute("x",options.leftMargin + 24*options.pixelsPerHour + 2);
		textEl.setAttribute("y",options.topMargin-12);
		textEl.setAttribute("style","font-size:8pt");
		$(textEl).append ("day len");
		$(svgEl).append(textEl);
		
		var textEl = document.createElementNS("http://www.w3.org/2000/svg", "text");
		textEl.setAttribute("x",options.leftMargin + 24*options.pixelsPerHour + 50);
		textEl.setAttribute("y",options.topMargin-12);
		textEl.setAttribute("style","font-size:8pt");
		$(textEl).append ("Δ");
		$(svgEl).append(textEl);
		var textEl = document.createElementNS("http://www.w3.org/2000/svg", "text");
		textEl.setAttribute("x",options.leftMargin + 24*options.pixelsPerHour + 42);
		textEl.setAttribute("y",options.topMargin);
		textEl.setAttribute("style","font-size:8pt");
		$(textEl).append ("m/day");
		$(svgEl).append(textEl);
		
		// Vertical grid
		var dayLength,prevDayLength=0;
		for (var i = 0; i < 365; i+=7) {
			var lineEl = document.createElementNS("http://www.w3.org/2000/svg", "line");
			lineEl.setAttribute("x1",options.leftMargin);
			lineEl.setAttribute("y1",options.topMargin + i*options.pixelsPerDay);
			lineEl.setAttribute("x2",options.leftMargin + 24*options.pixelsPerHour);
			lineEl.setAttribute("y2",options.topMargin + i*options.pixelsPerDay);
			lineEl.setAttribute("stroke","#888");
			lineEl.setAttribute("stroke-opacity","0.5");
			$(svgEl).append(lineEl);

			var textEl = document.createElementNS("http://www.w3.org/2000/svg", "text");
			textEl.setAttribute("x",0);
			textEl.setAttribute("y",options.topMargin + i*options.pixelsPerDay+4);
			textEl.setAttribute("style","font-size:8pt");
			$(textEl).append(""+options.data.riseSet[i][4]);
			$(svgEl).append(textEl);
			
			dayLength =options.data.riseSet[i][2]-options.data.riseSet[i][1];
			
			var textEl = document.createElementNS("http://www.w3.org/2000/svg", "text");
			textEl.setAttribute("x",options.leftMargin + 24*options.pixelsPerHour + 2);
			textEl.setAttribute("y",options.topMargin + i*options.pixelsPerDay+4);
			textEl.setAttribute("style","font-size:8pt");
			$(textEl).append(formatTime(dayLength));

			$(svgEl).append(textEl);
			
			if (prevDayLength>0) {
				var textEl = document.createElementNS("http://www.w3.org/2000/svg", "text");
				textEl.setAttribute("x",options.leftMargin + 24*options.pixelsPerHour + 70);
				textEl.setAttribute("y",options.topMargin + i*options.pixelsPerDay+4);
				textEl.setAttribute("style","font-size:8pt;");
				textEl.setAttribute("text-anchor","end");

				$(textEl).append(""+parseFloat(60*(dayLength-prevDayLength)/7).toFixed(2));
				$(svgEl).append(textEl);
			}
			prevDayLength = dayLength;
			
		}
		
	
		// refresh 
		// http://stackoverflow.com/questions/3642035/jquerys-append-not-working-with-svg-element
		//$(wrapperEl).html($(wrapperEl).html()); 
		$(svgEl).html($(svgEl).html()); 
		
		if (options.onChange) {
			$(wrapperEl).find("input").change(function() {
					options.onChange(
					$(wrapperEl).find(".lat").val(),
					$(wrapperEl).find(".lon").val()
					);
			}
			);
		}	
		
		$("#lat_" + wrapperEl.id).val(options.data.latitude);
		$("#lon_" + wrapperEl.id).val(options.data.longitude);	
		$("#tz_" + wrapperEl.id).html(options.data.timezone.id);
	
	};
	
	function formatTime (h) {
		return (h|0) + "h"  + (((h*60)%60)|0) + "m";
	}

	function initializeMap () {
				
		var mapCenter = new google.maps.LatLng(
				//$("#lat_"+id).val(), 
				//$("#lon_"+id).val()
				options.data.latitude,
				options.data.longitude
			);
		
		var mapOptions = {
		          center: mapCenter,
		          zoom: 6
		        };
		
		map = new google.maps.Map(
				document.getElementById("map_" + wrapperEl.id),
	            mapOptions);
		
		marker = new google.maps.Marker({
		    position: mapCenter,
		    map: map
		});
		
		// Map click event handler
		google.maps.event.addListener(map, 'click', function(e) {
			if (marker != null) {
				marker.setMap(null);
			}
			marker = new google.maps.Marker({
			    position: e.latLng,
			    map: map
			});
			$("#lat_"+wrapperEl.id).val(e.latLng.lat());
			$("#lon_"+wrapperEl.id).val(e.latLng.lng());
			
			if (options.onChange) {
				options.onChange(e.latLng.lat(), e.latLng.lng());
			}
		});
	}
	
})( jQuery );