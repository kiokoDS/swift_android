import 'dart:convert';
import 'package:http/http.dart' as http;

class PhotonService {
  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    final url = Uri.parse(
      'https://photon.komoot.io/api/?q=$query'
      '&limit=5'
      '&lang=en'
      '&lat=-1.2921'
      '&lon=36.8219'
      '&bbox=33.909821,-4.678047,41.899578,5.506', // 🇰🇪 restrict to Kenya
    );

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final List features = data['features'] ?? [];

      // Only keep features in Kenya
      final kenyanResults = features.where((f) {
        final country = f['properties']?['country']?.toString().toLowerCase();
        return country == 'kenya';
      }).toList();

      return kenyanResults.map((f) {
        final props = f['properties'] ?? {};
        final coords = f['geometry']?['coordinates'] ?? [0, 0];

        return {
          'displayName': props['name'] ??
              '${props['street'] ?? ''} ${props['city'] ?? ''} ${props['country'] ?? ''}',
          'lat': coords[1].toString(),
          'lon': coords[0].toString(),
        };
      }).toList();
    } else {
      throw Exception("Failed to load Photon results");
    }
  }

  Future<Map<String, dynamic>> reverseGeocode(double lat, double lon) async {
    final url = Uri.parse(
      'https://photon.komoot.io/reverse?lat=$lat&lon=$lon&lang=en',
    );

    final response = await http.get(url);
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final props = data['features'][0]['properties'];
      return {
        "displayName": props['name'] ??
            '${props['street'] ?? ''} ${props['city'] ?? ''} ${props['country'] ?? ''}',
        "lat": lat,
        "lon": lon,
      };
    } else {
      throw Exception("Failed reverse geocode");
    }
  }
}
