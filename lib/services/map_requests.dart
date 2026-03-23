import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:ridercms/utils/constants/app_constants.dart';
import '../models/route.dart';

const String googleMapsApiKey = AppConstants.googleMapsApiKey;

class GoogleMapsServices {
  Future<RouteModel> getRouteByCoordinates(LatLng l1, LatLng l2) async {
    String url =
        "https://maps.googleapis.com/maps/api/directions/json?origin=${l1.latitude},${l1.longitude}&destination=${l2.latitude},${l2.longitude}&key=$googleMapsApiKey";

    Uri uri = Uri.parse(url);

    try {
      http.Response response = await http.get(uri);

      // Specify Map type for better type safety
      Map<String, dynamic> values = jsonDecode(response.body);

      if (values["status"] != "OK") {
        throw Exception("Google Maps API Error: ${values["status"]} - ${values["error_message"] ?? 'No route found'}");
      }

      if ((values["routes"] as List).isEmpty) {
        throw Exception("No route found!");
      }

      // Accessing the first route and leg
      Map<String, dynamic> routeData = values["routes"][0];
      Map<String, dynamic> leg = routeData["legs"][0];

      RouteModel route = RouteModel(
        points: routeData["overview_polyline"]["points"],
        distance: Distance.fromMap(leg['distance']),
        timeNeeded: TimeNeeded.fromMap(leg['duration']),
        endAddress: leg['end_address'],
        startAddress: leg['start_address'],
      );

      return route;
    } catch (e) {
      // Re-throw the exception so the UI can handle it
      throw Exception("Failed to fetch route: $e");
    }
  }
}