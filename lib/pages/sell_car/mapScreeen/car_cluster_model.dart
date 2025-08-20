import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../models/car_listing_model.dart';

class CarClusterItem with ClusterItem {
  final CarListing car;

  CarClusterItem(this.car);

  @override
  LatLng get location => LatLng(
    double.tryParse("${car.lat}") ?? 0.0,
    double.tryParse("${car.lng}") ?? 0.0,
  );
}
