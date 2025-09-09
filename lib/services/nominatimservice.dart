import 'dart:convert';
import 'package:http/http.dart' as http;

class NominatimService {
  Future<List<Map<String, dynamic>>> searchLocations(String query) async {
    final url = Uri.parse(
      'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5',
    );

    final response = await http.get(
      url,
      headers: {"User-Agent": "swift"}, // OSM requires this
    );

    if (response.statusCode == 200) {
      final List data = json.decode(response.body);
      return data.map((place) {
        return {
          "displayName": place["display_name"],
          "lat": place["lat"],
          "lon": place["lon"],
        };
      }).toList();
    } else {
      throw Exception("Failed to load locations");
    }
  }

  Future<Map<String, dynamic>> getAddressFromCoordinates(
    double lat,
    double lon,
  ) async {
    final url = 'https://nominatim.openstreetmap.org/reverse?format=json'
        '&lat=$lat&lon=$lon&addressdetails=1';

    final response = await http.get(
      Uri.parse(url),
      headers: {'Accept-Language': 'en-US,en;q=0.9', "User-Agent": "swift"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get address');
    }
  }
}
