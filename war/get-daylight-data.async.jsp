<%@page pageEncoding="UTF-8"%><%@include file="_key.jsp"%><%@page
import="java.io.BufferedReader"
import="java.io.InputStreamReader"
import="java.io.IOException"
import="java.net.URL" 
import="java.net.MalformedURLException"
import="java.util.Calendar"
import="java.util.Date"
import="java.util.TimeZone"
import="java.text.DecimalFormat"
import="java.text.SimpleDateFormat"
import="ie.wombat.finestretch.TimezoneDB"
import="ie.wombat.astro.Sun"
%><%!

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

//Key is in _key.jsp so as to avoid checking a working key into GitHub.
TimezoneDB.getInstance().setKey(timezoneDbKey);

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
	String tzId = TimezoneDB.getInstance().getTimezoneId(lat,lon);
	System.err.println ("Timezone at " + lat + "," + lon + ": " + tzId);
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