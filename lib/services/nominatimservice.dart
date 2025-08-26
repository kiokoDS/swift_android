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
}
