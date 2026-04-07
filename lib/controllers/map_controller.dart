import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';
import '../models/booth_models.dart';
import '../services/booth_service.dart';
import '../providers/user_provider.dart';

class MapController extends GetxController {
  final BoothService _boothService = BoothService();
  
  var booths = <PublicBooth>[].obs;
  var markers = <Marker>{}.obs;
  var isLoading = true.obs;
  
  GoogleMapController? mapController;
  Timer? _refreshTimer;

  @override
  void onInit() {
    super.onInit();
    _initMap();
  }

  Future<void> _initMap() async {
    await fetchBooths();
    _startPolling();
    _determinePosition();
  }

  void _startPolling() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(minutes: 2), (timer) {
      fetchBooths(showLoading: false);
    });
  }

  Future<void> fetchBooths({bool showLoading = true}) async {
    try {
      final BuildContext? context = Get.context;
      if (context == null) return;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = await userProvider.getFreshToken();

      if (token == null) return;

      if (showLoading) isLoading.value = true;
      final fetchedBooths = await _boothService.getBooths(token);
      booths.value = fetchedBooths;
      
      final boothMarkers = fetchedBooths.map((booth) => Marker(
        markerId: MarkerId(booth.boothUid),
        position: LatLng(booth.latitude, booth.longitude),
        infoWindow: InfoWindow(title: booth.name, snippet: booth.locationAddress),
        icon: BitmapDescriptor.defaultMarkerWithHue(
          booth.status == 'online' ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed
        ),
      )).toList();

      markers.value = boothMarkers.toSet();
    } catch (e) {
      if (kDebugMode) print("Error fetching booths: $e");
    } finally {
      if (showLoading) isLoading.value = false;
    }
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    
    if (permission == LocationPermission.deniedForever) return;

    final position = await Geolocator.getCurrentPosition();
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(position.latitude, position.longitude),
        14,
      ),
    );
  }

  Future<void> recenter() async {
    try {
      final position = await Geolocator.getCurrentPosition();
      mapController?.animateCamera(
        CameraUpdate.newLatLng(
          LatLng(position.latitude, position.longitude),
        ),
      );
    } catch (e) {
      if (kDebugMode) print("Error recentering: $e");
    }
  }

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  void animateToBooth(double lat, double lng) {
    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(lat, lng),
        16, // Zoom in closer
      ),
    );
  }

  Future<void> navigateToBooth(PublicBooth booth) async {
    final lat = booth.latitude;
    final lng = booth.longitude;
    
    if (Platform.isIOS) {
      final appleUrl = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng&dirflg=d');
      if (await canLaunchUrl(appleUrl)) {
        await launchUrl(appleUrl);
        return;
      }
    }

    final googleUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    
    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else {
      final browserUrl = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving');
      if (await canLaunchUrl(browserUrl)) {
        await launchUrl(browserUrl, mode: LaunchMode.externalApplication);
      } else {
        Get.snackbar('Error', 'Could not launch maps',
          snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }
}
