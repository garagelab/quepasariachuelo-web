if (window.relocalizaciones) {
  $(function() {
    for (i = 0; i < relocalizaciones.length; i++) {
      var row = relocalizaciones[i];

      if (!row["relocation"]) continue;

      var source = Layer.stringToLatLng(row["location"]);
      var target = Layer.stringToLatLng(row["relocation"]);

      var map = $('#relocalizaciones').data('map');

      new google.maps.Polyline({
         map: map,
         path: [source, target],
         strokeColor: '#f00000',
         strokeOpacity: 0.5,
         strokeWeight: 2,
         geodesic: true
      });

      new google.maps.Marker({
        map: map,
        position: target
      });
    }
  });
}
