import 'dart:convert';
import 'package:dio/dio.dart';

class MapboxService {
  final Dio _dio = Dio();
  final String accessToken = "pk.eyJ1Ijoia2lva28xMjEiLCJhIjoiY21la2FxMG8wMDViYjJrcXZ3MWFmd2ZvZSJ9.3FCWY9P2G8ZKrmLG1XZWcw";

  Future<List<Map<String, dynamic>>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    final encodedQuery = Uri.encodeComponent(query);
    final url =
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$encodedQuery.json'
        '?access_token=$accessToken'
        '&autocomplete=true'
        '&limit=5'
        '&country=ke'; // ✅ Restrict to Kenya

    try {
      final response = await _dio.get(url);
      final data = jsonDecode(response.toString());

      return (data['features'] as List)
          .map((f) => {
                "displayName": f["place_name"],
                "lat": f["geometry"]["coordinates"][1].toString(),
                "lon": f["geometry"]["coordinates"][0].toString(),
              })
          .toList();
    } catch (e) {
      print("Mapbox search error: $e");
      return [];
    }
  }
}
