function getPlacePredictions(input, callback) {
  const service = new google.maps.places.AutocompleteService();
  service.getPlacePredictions({
    input: input,
    componentRestrictions: { country: 'de' },
    types: ['address']
  }, callback);
}

function getPlaceDetails(placeId, callback) {
  const service = new google.maps.places.PlacesService(
    document.createElement('div')
  );
  service.getDetails({ placeId: placeId }, callback);
}