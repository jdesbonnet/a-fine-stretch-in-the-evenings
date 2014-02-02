package ie.wombat.finestretch;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.MalformedURLException;
import java.net.URL;
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
		String key = latitude + "," + longitude;
		
		if (tzCache.containsKey(key)) {
			System.err.println ("tzCacheHit on key=" + key + " value=" + tzCache.get(key));
			cacheHits++;
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
		    
		    System.err.println ("TimezoneDB: zoneId=" + zoneId);
		    tzCache.put(key, zoneId);
		    
		    return zoneId;
		    
		} catch (MalformedURLException e) {
	    // ...
		} catch (IOException e) {
	    // ...
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
