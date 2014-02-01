<%@page import="java.text.DecimalFormat"%>
<%@page import="java.io.PrintStream"%>
<%@page import="java.util.HashMap"%>
<%@page import="java.util.Map"%>
<%@page import="com.google.appengine.repackaged.com.google.api.client.json.Json"%>
<%@page import="com.google.appengine.repackaged.org.codehaus.jackson.JsonParser"%>
<%@page import="java.net.MalformedURLException"%>
<%@page import="java.io.IOException"%>
<%@page import="java.io.InputStreamReader"%>
<%@page import="java.io.BufferedReader"%>
<%@page import="java.net.URL"%>
<%@page pageEncoding="UTF-8"%><%@page 
import="java.util.Calendar"
import="ie.wombat.astro.Sun"
import="java.util.Date"
import="java.text.SimpleDateFormat"
import="java.util.TimeZone"%><%@include file="_key.jsp"%><%!


public static final int blocksPerHour = 4;
public static final float pixelsPerHour = 24;
public static final float pixelsPerDay = 2;
public static final float topMargin = 16;

private static Map<String,String>tzCache = new HashMap<String,String>();
private static int tzCacheLookup = 0;
private static int tzCacheHit = 0;

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
String fetchTimezone (double latitude, double longitude) {
	
	tzCacheLookup++;
	
	String key = "latitude" + "," + longitude;
	if (tzCache.containsKey(key)) {
		System.err.println ("tzCacheHit on " + key);
		tzCacheHit++;
		return tzCache.get(key);
	}
	
	 StringBuffer buf = new StringBuffer();
	 try {
		URL url = new URL("http://api.timezonedb.com/?lat=" + latitude 
				+ "&lng=" + longitude + "&format=xml"
				+ "&key=" + timezoneDbKey);
	 	BufferedReader reader = new BufferedReader(new InputStreamReader(url.openStream()));
	    String line;

	    while ((line = reader.readLine()) != null) {
	        buf.append(line);
	    }
	    reader.close();
	    
	    int start = buf.indexOf("<zoneName>",0) + "<zoneName>".length();
	    int end = buf.indexOf("</zoneName>",0);
	 
	    String zoneId = buf.substring(start,end);
	    
	    tzCache.put(key, zoneId);
	    
	    return zoneId;
	    
	} catch (MalformedURLException e) {
    // ...
	} catch (IOException e) {
    // ...
	}
	 
	 return "UTC";
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
	//tz = TimeZone.getDefault();
	String tzId = fetchTimezone(lat0, lon0);
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
	//tz = TimeZone.getDefault();
	String tzId = fetchTimezone(lat1, lon1);
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
.chart {width:660px; }
.map {background:yellow;width:100%;height:100%}
</style>
<link rel="stylesheet" type="text/css" href="//code.jquery.com/ui/1.10.4/themes/smoothness/jquery-ui.css" />

<script src="//ajax.googleapis.com/ajax/libs/jquery/1.10.2/jquery.min.js"></script>
<script src="//code.jquery.com/ui/1.10.4/jquery-ui.js"></script>
<script src="https://maps.googleapis.com/maps/api/js?sensor=false"></script>
<script src="daylightchart.js"></script>
<script>

function drawChart(chartId, latitude, longitude) {
	$.ajax( {
		url: "get-daylight-data.async.jsp",
		data: "lat=" + latitude + "&lon=" + longitude
	}).done(function(data) {
		$("#"+chartId).daylightchart("update", data);
	});
}

$(function(){
	var lat0 = <%=lat0 %>;
	var lon0 = <%=lon0 %>;
	var lat1 = <%=lat1 %>;
	var lon1 = <%=lon1 %>;
	
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
	});
	}
	
	
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

<table>
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

<!-- tzCache=<%=tzCache.size()%>, hit=<%=tzCacheHit%>/<%=tzCacheLookup%> (<%=tzCacheHit*100/tzCacheLookup%>%) -->
</body>

</html>
