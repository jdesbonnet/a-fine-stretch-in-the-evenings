<%@page pageEncoding="UTF-8"%><%@page 
import="java.util.Calendar"
import="java.util.Date"
import="java.text.SimpleDateFormat"
import="java.util.TimeZone"
import="ie.wombat.astro.Sun"
import="ie.wombat.finestretch.TimezoneDB"
%><%@include file="_key.jsp"%><%!

public static final int blocksPerHour = 4;
public static final float pixelsPerHour = 24;
public static final float pixelsPerDay = 2;
public static final float topMargin = 16;

double[] correctSunRiseSet(double riseSet[]) {
	double[] ret = new double[2];
	ret[Sun.RISE] = riseSet[Sun.RISE] == Sun.ABOVE_HORIZON  ? 0 : riseSet[Sun.RISE];
	ret[Sun.SET] = riseSet[Sun.SET] == Sun.ABOVE_HORIZON 
			| riseSet[Sun.SET]==Sun.BELOW_HORIZON 
			//| riseSet[Sun.SET]>24 
			//| riseSet[Sun.SET] < riseSet[Sun.RISE] 
			? 24 : riseSet[Sun.SET];
	return ret;
}
	
%><%

SimpleDateFormat df = new SimpleDateFormat ("dd MMM");

double lat0 = 53.3;
double lon0 = -9;
double lat1 = -999;
double lon1 = -999;

if (request.getParameter("lat0") != null) {
	try {
		lat0 = Double.parseDouble(request.getParameter("lat0"));
	} catch (NumberFormatException e) {
	}
}

if (request.getParameter("lon0") != null) {
	try {
		lon0 = Double.parseDouble(request.getParameter("lon0"));
	} catch (NumberFormatException e) {
	}
} 

TimeZone tz0;
if (request.getParameter("tz0")!=null) {
	tz0 = TimeZone.getTimeZone(request.getParameter("tz0"));	
} else {
	String tzId = TimezoneDB.getInstance().getTimezoneId(lat0, lon0);
	System.err.println (tzId);
	tz0 = TimeZone.getTimeZone(tzId);
}

if (request.getParameter("lat1") != null) {
	try {
		lat1 = Double.parseDouble(request.getParameter("lat1"));
	} catch (NumberFormatException e) {
	}
}

if (request.getParameter("lon1") != null) {
	try {
		lon1 = Double.parseDouble(request.getParameter("lon1"));
	} catch (NumberFormatException e) {
	}
} 

TimeZone tz1;
if (request.getParameter("tz1")!=null) {
	tz1 = TimeZone.getTimeZone(request.getParameter("tz1"));	
} else {
	String tzId = TimezoneDB.getInstance().getTimezoneId(lat0, lon0);
	System.err.println (tzId);
	tz1 = TimeZone.getTimeZone(tzId);
}


%><!DOCTYPE html>
<html>
<head>
<title>Day/Night for latitude <%=lat0 %>, longitude <%=lon0 %></title>

<style type="text/css">
TABLE.dayNight {border:0px; padding: 0px;}
TABLE.dayNight TD {border: 0px; padding: 0px;}
TABLE.dayNight TD.n {background: #00a; width:5px;} 
TABLE.dayNight TD.d {background: #ff0; width:5px;}
TABLE.dayNight TD.ne {background: #008; width:5px;} 
TABLE.dayNight TD.de {background: #fe0; width:5px;}
INPUT.lat, INPUT.lon {width:4em;}
INPUT.tz {width:15em;}
.chart {width:660px; border:1px solid #888;border-radius:6px;padding:8px;}
.map {background:yellow;width:100%;height:100%}
#map {width:100%;height:100%;}

</style>
<link rel="stylesheet" type="text/css" href="//code.jquery.com/ui/1.10.4/themes/smoothness/jquery-ui.css" />

<script src="//ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"></script>
<script src="//code.jquery.com/ui/1.10.4/jquery-ui.js"></script>
<script src="https://maps.googleapis.com/maps/api/js?sensor=false"></script>
<script src="daylightchart.js"></script>
<script>

var map;

var lat0 = <%=lat0 %>;
var lon0 = <%=lon0 %>;
var lat1 = <%=lat1 %>;
var lon1 = <%=lon1 %>;

function initializeMap () {

	var mapOptions = {
	          center: new google.maps.LatLng(0,0),
	          zoom: 1
	        };
	
	map = new google.maps.Map(
			document.getElementById("map"),
            mapOptions);
	
	var marker0 = new google.maps.Marker({
	    position: new google.maps.LatLng(lat0,lon0),
	    draggable:true,
	    map: map
	});
	google.maps.event.addListener(marker0, 'dragend', function() {
		alert('chart0');
		drawChart("chart0",this.getPosition().lat(),this.getPosition().lng());
	});

	var marker1 = new google.maps.Marker({
	    position: new google.maps.LatLng(lat1,lon1),
	    draggable:true,
	    map: map
	});
	google.maps.event.addListener(marker1, 'dragend', function() {
		alert('chart1');
		drawChart("chart1",this.getPosition().lat(),this.getPosition().lng());
	});
	
}


function drawChart(chartId, latitude, longitude) {
	$.ajax( {
		url: "get-daylight-data.async.jsp",
		data: "lat=" + latitude + "&lon=" + longitude
	}).done(function(data) {
		console.log(data);
		alert ("about to update chart with chartId=" + chartId + " found " + $("#"+chartId).size());
		alert ("#"+chartId + " id=" + $("#"+chartId).daylightchart("getId"));
		$("#"+chartId).daylightchart("update", data);
	});
}

$(function(){
	
	$("#mapPopup").dialog({
		width:640,height:480,
		autoOpen:false,
		resizeStop: function(event, ui) {
			google.maps.event.trigger(map, 'resize');
			map.setCenter(new google.maps.LatLng(0,0));
		},
        open: function(event, ui) {
        	google.maps.event.trigger(map, 'resize'); 
			map.setCenter(new google.maps.LatLng(0,0));
        }      
	});
	
	$("#mapBtn").click(function(){
		$("#mapPopup").dialog("open");
	});
	
	
	$.ajax( {
		url: "get-daylight-data.async.jsp",
		data: "lat=<%=lat0%>&lon=<%=lon0%>"
	}).done(function(data) {
		$("#chart0").daylightchart({
			width:1024,
			pixelsPerHour: 22,
			pixelsPerDay: 2,
			leftMargin: 42,
			topMargin: 20,
			data: data,
			onChange: function(lat,lon) {
				//window.location.href= "?lat0=" + lat + "&lon0=" + lon +"&lat1=" + lat1 + "&lon1=" + lon1;
				drawChart("chart0",lat,lon);
			}
		});
		alert ("Chart0 ID: " + $("#chart0").daylightchart("getId"));
	});
	
	if (lat1 != -999) {
	$.ajax( {
		url: "get-daylight-data.async.jsp",
		data: "lat=<%=lat1%>&lon=<%=lon1%>"
	}).done(function(data) {
		$("#chart1").daylightchart({
			width:1024,
			pixelsPerHour: 22,
			pixelsPerDay: 2,
			leftMargin: 42,
			topMargin: 20,
			data: data,
			onChange: function(lat,lon) {
				window.location.href= "?lat0=" + lat0 + "&lon0=" + lon0 +"&lat1=" + lat + "&lon1=" + lon;
			}
		});
		alert ("Chart1 ID: " + $("#chart1").daylightchart("getId"));
	});
	}
	
	initializeMap();
	
	
	
});
</script>

</head>

<body>

<!-- 
<header>
<svg width="1280" height="64" >
<rect x="0" y="0" width="100%" height="100%" fill="yellow" />
<text x="0" y="48" style="font-size:24pt;">A fine 
<tspan lengthAdjust="spacingAndGlyphs" textLength="1000" >stretch</tspan> 
in the evenings</text>
</svg>
</header>
-->


<button id="mapBtn" type="button">Display Map</button>
<div id="mapPopup" title="World Map"><div id="map"></div></div>

<table>
<!-- 
<tr><td></td><td  colspan="1"><div id="map2"></div></td></tr>
-->
<tr>
<td><div class="chart" id="chart0"></div></td>
<td><div class="chart" id="chart1"></div></td>
</table>

<footer>
<p>
A Fine Stretch In the Evenings, version 0.1, 29 Jan 2014.
Got any queries? Email Joe at jdesbonnet@gmail.com 
</p>
</footer>
</body>

</html>
