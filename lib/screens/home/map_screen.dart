import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import '../../controllers/map_controller.dart';
import '../../utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  static const CameraPosition _kInitialPosition = CameraPosition(
    target: LatLng(-1.286389, 36.817223),
    zoom: 13,
  );

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(MapController());

    return Scaffold(
      backgroundColor: kBgDark,
      body: Stack(
        children: [
          // 1. Google Map
          Obx(() => GoogleMap(
                initialCameraPosition: _kInitialPosition,
                markers: controller.markers.value,
                onMapCreated: controller.onMapCreated,
                myLocationEnabled: true,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
              )),

          // 2. Overlay Header
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Obx(() => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: kBgCard.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.flash_on, color: kPrimary, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              '${controller.booths.length} Stations Nearby',
                              style: const TextStyle(color: kTextPrimary, fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),

          // 3. Recenter Button
          Positioned(
            right: 16,
            bottom: MediaQuery.of(context).size.height * 0.3 + 16,
            child: FloatingActionButton(
              onPressed: () => controller.recenter(),
              backgroundColor: kBgCard,
              child: const Icon(Icons.my_location, color: kPrimary),
            ),
          ),

          // 4. Sliding Bottom Sheet
          DraggableScrollableSheet(
            initialChildSize: 0.3,
            minChildSize: 0.15,
            maxChildSize: 0.8,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: kBgDark,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 20)],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Obx(() {
                        if (controller.isLoading.value) {
                          return const Center(child: CircularProgressIndicator(color: kPrimary));
                        }

                        if (controller.booths.isEmpty) {
                          return const Center(
                            child: Text(
                              "No stations found nearby",
                              style: TextStyle(color: kTextSecondary),
                            ),
                          );
                        }

                        return ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          itemCount: controller.booths.length,
                          itemBuilder: (context, index) {
                            final booth = controller.booths[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        color: kPrimary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(child: Icon(Icons.ev_station, color: kPrimary, size: 28)),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            booth.name,
                                            style: const TextStyle(color: kTextPrimary, fontSize: 15, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            booth.locationAddress,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(color: kTextSecondary, fontSize: 12),
                                          ),
                                          const SizedBox(height: 8),
                                          StatusBadge(
                                            label: '${booth.availableSlots} Slots Available',
                                            color: booth.availableSlots > 0 ? kPrimary : kDanger,
                                            bgColor: (booth.availableSlots > 0 ? kPrimary : kDanger).withValues(alpha: 0.1),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () => controller.navigateToBooth(booth),
                                      icon: const Icon(Icons.near_me_outlined, color: kPrimary),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
