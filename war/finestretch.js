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
		drawChart("chart0",this.getPosition().lat(),this.getPosition().lng());
	});

	var marker1 = new google.maps.Marker({
	    position: new google.maps.LatLng(lat1,lon1),
	    draggable:true,
	    map: map
	});
	google.maps.event.addListener(marker1, 'dragend', function() {
		drawChart("chart1",this.getPosition().lat(),this.getPosition().lng());
	});
	
}


function drawChart(chartId, latitude, longitude) {
	$("#"+chartId).data("daylightchart").showLoadAnimation(true);
	$.ajax( {
		url: "get-daylight-data.async.jsp",
		data: "lat=" + latitude + "&lon=" + longitude
	}).done(function(data) {
		console.log(data);
		$("#"+chartId).data("daylightchart").update(data);
		$("#"+chartId).data("daylightchart").showLoadAnimation(false);
	});
}
