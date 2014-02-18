package ie.wombat.finestretch;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.MalformedURLException;
import java.net.URL;
import java.net.URLConnection;
import java.text.DecimalFormat;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;

/**
 * Fetch timezone ID from timezonedb.com and implement a simple cache to reduce 
 * request load.
 * 
 * @author joe
 *
 */
public class TimezoneDB {
	
	private static final TimezoneDB instance = new TimezoneDB();
	
	private static final DecimalFormat df = new DecimalFormat("0.0");
	
	private ConcurrentMap<String,String>tzCache = new ConcurrentHashMap<String,String>();
	private int cacheLookups = 0;
	private int cacheHits = 0;
	
	private String timezoneDbKey;
	
	public static TimezoneDB getInstance() {
		return instance;
	}
	
	public void setKey(String key) {
		this.timezoneDbKey = key;
	}
	
	public String getTimezoneId(double latitude, double longitude) {
		
		cacheLookups++;
		
		// Use string of latitude and longitude combined as key to cache HashMap
		String key = df.format(latitude) + "," + df.format(longitude);
		
		if (tzCache.containsKey(key)) {
			//System.err.println ("tzCacheHit on key=" + key + " value=" + tzCache.get(key));
			cacheHits++;
			return tzCache.get(key);
		}
		
		System.err.println ("cache miss on key=" + key);
		
		 StringBuffer buf = new StringBuffer();
		 try {
			 
			//System.err.println ("apikey="+timezoneDbKey);
			 
			URL url = new URL("http://api.timezonedb.com/?lat=" + latitude 
					+ "&lng=" + longitude + "&format=xml"
					+ "&key=" + timezoneDbKey);
			
			URLConnection con = url.openConnection();
			con.setConnectTimeout(5000); // 5s
			con.setReadTimeout(5000);
			InputStream in = con.getInputStream();
			
		 	BufferedReader reader = new BufferedReader(new InputStreamReader(in));
		 	
		    String line;
		    while ((line = reader.readLine()) != null) {
		        buf.append(line);
		    }
		    reader.close();
		    
		    System.err.println("response from api.timezonedb.com: " + buf.toString());
		    
		    int start = buf.indexOf("<zoneName>",0) + "<zoneName>".length();
		    int end = buf.indexOf("</zoneName>",0);
		 
		    String zoneId = buf.substring(start,end);
		    
		    System.err.println ("TimezoneDB: zoneId=" + zoneId);
		    
		    tzCache.put(key, zoneId);
		    
		    return zoneId;
		    
		} catch (MalformedURLException e) {
	    // ...
		} catch (IOException e) {
			e.printStackTrace();
		}
		 
		 return null;
	}

	public int getCacheLookups() {
		return cacheLookups;
	}

	public int getCacheHits() {
		return cacheHits;
	}

	
}
