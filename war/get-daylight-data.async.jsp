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
<%@page pageEncoding="UTF-8"%><%@include file="_key.jsp"%><%@page 
import="java.util.Calendar"
import="ie.wombat.astro.Sun"
import="java.util.Date"
import="java.text.SimpleDateFormat"
import="java.util.TimeZone"%><%!


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
				+ "&lng=" + longitude + "&format=xml&key=QN7MRGRNLXNZ");
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

response.setContentType("application/json");

SimpleDateFormat df = new SimpleDateFormat ("dd MMM");

double lat = 53.3;
double lon = -9;


if (request.getParameter("lat") != null) {
	try {
		lat = Double.parseDouble(request.getParameter("lat"));
	} catch (NumberFormatException e) {
	}
}

if (request.getParameter("lon") != null) {
	try {
		lon = Double.parseDouble(request.getParameter("lon"));
	} catch (NumberFormatException e) {
	}
} 

TimeZone tz;
if (request.getParameter("tz")!=null) {
	tz = TimeZone.getTimeZone(request.getParameter("tz"));	
} else {
	//tz = TimeZone.getDefault();
	String tzId = fetchTimezone(lat, lon);
	System.err.println (tzId);
	tz = TimeZone.getTimeZone(tzId);
}

%>{
"latitude": <%=lat %>,
"longitude": <%=lon %>,
"timezone": {"id":"<%=tz.getID() %>"},
"riseSet":[
<% 
	Calendar cal = Calendar.getInstance();
	cal.setTimeZone(tz);

	int year = cal.get(Calendar.YEAR);
	
	long tzOffset;

	cal.set(Calendar.YEAR,year);
	cal.set(Calendar.MONTH, 0);
	cal.set(Calendar.DAY_OF_MONTH,1);

	int r,s,tlr,tls;
	
	DecimalFormat numberFormat = new DecimalFormat("0.000");
	
	for (int i = 0; i < 365; i++) {
		
		Date date = cal.getTime();
		

		tzOffset = tz.getOffset(date.getTime());
		
		double[] riseSet = correctSunRiseSet(Sun.calcRiseSet(date,tzOffset,lat,lon, Sun.SUNRISE));
		double[] twilight = correctSunRiseSet(Sun.calcRiseSet(date,tzOffset,lat,lon, Sun.CIVIL_TWILIGHT));
		
		if (i>0) {
			out.write (",");
		}
		out.write ("\n[" + numberFormat.format(twilight[Sun.RISE]) 
		             + "," + numberFormat.format(riseSet[Sun.RISE]) 
				+ "," + numberFormat.format(riseSet[Sun.SET]) 
				+ "," + numberFormat.format(twilight[Sun.SET]) 
				+ ",\"" + df.format(date) +"\""
				+ "]");

		cal.add(Calendar.HOUR,24);
	}
%>
]
}
