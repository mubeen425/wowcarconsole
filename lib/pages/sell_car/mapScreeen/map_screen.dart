import 'dart:async';
import 'dart:ui' as ui;

import 'package:fl_carmax/pages/buy_car/search/search_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_cluster_manager/google_maps_cluster_manager.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../models/car_listing_model.dart';
import '../../buy_car/search/search_page.dart';
import 'car_cluster_model.dart';

class CarMapScreen extends StatefulWidget {
  final SearchProvider searchProvider;
  const CarMapScreen({super.key, required this.searchProvider});

  @override
  State<CarMapScreen> createState() => _CarMapScreenState();
}

class _CarMapScreenState extends State<CarMapScreen> {
  late ClusterManager _clusterManager;
  Set<Marker> _markers = {};
  final Completer<GoogleMapController> _controller = Completer();
  bool _isClusterExpanded = false; // Track if a cluster is expanded

  static const CameraPosition _initialCameraPosition = CameraPosition(
    target: LatLng(13.7563, 100.5018),
    zoom: 10,
  );

  @override
  void initState() {
    super.initState();
    _initClusterManager();
    // Listen to SearchProvider changes
    widget.searchProvider.addListener(_onSearchProviderChanged);
  }

  @override
  void dispose() {
    widget.searchProvider.removeListener(_onSearchProviderChanged);
    super.dispose();
  }

  void _onSearchProviderChanged() {
    if (mounted) {
      _updateClusterItems();
    }
  }

  void _initClusterManager() {
    final clusterItems = widget.searchProvider.searchController.text.isEmpty
        ? widget.searchProvider.apiCarList.map((car) => CarClusterItem(car)).toList()
        : widget.searchProvider.searchCarList.map((car) => CarClusterItem(car)).toList();

    _clusterManager = ClusterManager<CarClusterItem>(
      clusterItems,
      _updateMarkers,
      markerBuilder: _markerBuilder,
      stopClusteringZoom: 17.0,
    //  initialZoom: _initialCameraPosition.zoom,
    );
  }

  void _updateClusterItems() {
    final clusterItems = widget.searchProvider.searchController.text.isEmpty
        ? widget.searchProvider.apiCarList.map((car) => CarClusterItem(car)).toList()
        : widget.searchProvider.searchCarList.map((car) => CarClusterItem(car)).toList();

    _clusterManager.setItems(clusterItems);
    _isClusterExpanded = false; // Reset expanded state
    _clusterManager.updateMap();
  }

  void _updateMarkers(Set<Marker> markers) {
    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

 /* Future<Marker> _markerBuilder(Cluster<CarClusterItem> cluster) async {
    if (cluster.isMultiple) {
      final icon = await _createClusterMarker(cluster.count);
      return Marker(
        markerId: MarkerId(cluster.getId()),
        position: cluster.location,
        icon: icon,
        onTap: () => {},
        // onTap: () => _onClusterTapped(cluster),
      );
    } else {
      final car = cluster.items.first.car;
      final icon = await _createCarMarkerWithImage(car);
      return Marker(
        markerId: MarkerId(car.id),
        position: cluster.location,
        icon: icon,
        infoWindow: InfoWindow(
          title: car.title,
          snippet: car.price,
        ),
      );
    }
  }
*/
  Future<Marker> _markerBuilder(Cluster<CarClusterItem> cluster) async {
    // Always draw the same count‐circle icon, even if cluster.count == 1
    final BitmapDescriptor icon = await _createClusterMarker(cluster.count);
    return Marker(
      markerId: MarkerId(cluster.getId()),
      position: cluster.location,
      icon: icon,
        onTap: () {
          showModalBottomSheet(
              isScrollControlled: true,
              useSafeArea: true,
              enableDrag: true,
              showDragHandle: true,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height* 0.8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              context: context,
              builder: (context) {
                final carListFromMap = cluster.items.map((item) => item.car).toList();
                return SearchPage(
                  isMapScreen: true,
                  carsListFromMap: carListFromMap,
                );
              });
        }

    );
  }

  Future<BitmapDescriptor> _createCarMarkerWithImage(CarListing car) async {
    const double width = 510;
    const double height = 590;
    const double imageHeight = 410;
    const double padding = 16.0;
    const double borderRadius = 24;

    // Validate imageUrl before attempting to load
    if (car.imageUrl.isEmpty || !Uri.parse(car.imageUrl).hasAuthority) {
      return _createCarPriceMarker(car.price); // Fallback to price marker if imageUrl is invalid
    }

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final RRect background = RRect.fromLTRBR(
      0,
      0,
      width,
      height,
      const Radius.circular(borderRadius),
    );

    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawRRect(background, shadowPaint);

    final Paint backgroundPaint = Paint()..color = Colors.white;
    canvas.drawRRect(background, backgroundPaint);

    try {
      final NetworkImage image = NetworkImage(car.imageUrl);
      final ImageStream stream = image.resolve(ImageConfiguration.empty);
      final Completer<ui.Image> completer = Completer<ui.Image>();
      stream.addListener(ImageStreamListener((ImageInfo info, bool _) {
        completer.complete(info.image);
      }));

      final ui.Image carImage = await completer.future;

      final RRect imageClip = RRect.fromRectAndCorners(
        const Rect.fromLTWH(0, 0, width, imageHeight),
        topLeft: const Radius.circular(borderRadius),
        topRight: const Radius.circular(borderRadius),
      );

      canvas.save();
      canvas.clipRRect(imageClip);
      canvas.drawImageRect(
        carImage,
        Rect.fromLTWH(0, 0, carImage.width.toDouble(), carImage.height.toDouble()),
        const Rect.fromLTWH(0, 0, width, imageHeight),
        Paint(),
      );
      canvas.restore();

      final TextPainter titlePainter = TextPainter(
        text: TextSpan(
          text: car.title,
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width - 2 * padding);

      titlePainter.paint(
        canvas,
        Offset(
          (width - titlePainter.width) / 2,
          imageHeight + padding,
        ),
      );
    } catch (e) {
      debugPrint('Error loading image for car ${car.id}: $e');
      return _createCarPriceMarker(car.price);
    }

    final ui.Image markerImage = await recorder.endRecording().toImage(
      width.toInt(),
      height.toInt(),
    );

    final ByteData? byteData = await markerImage.toByteData(
      format: ui.ImageByteFormat.png,
    );

    final Uint8List bytes = byteData!.buffer.asUint8List();
    return BitmapDescriptor.fromBytes(bytes);
  }

  Future<BitmapDescriptor> _createCarPriceMarker(String price) async {
    const double padding = 8.0;
    const double borderRadius = 20.0;
    const int width = 220;
    const int height = 90;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);

    final RRect rrect = RRect.fromLTRBR(
      0,
      0,
      width.toDouble(),
      height.toDouble(),
      const Radius.circular(borderRadius),
    );

    final Paint backgroundPaint = Paint()..color = const Color(0xFFFFA726);
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;

    canvas.drawRRect(rrect, backgroundPaint);
    canvas.drawRRect(rrect, borderPaint);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: price,
        style: const TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width - (padding * 2));

    textPainter.paint(
      canvas,
      Offset(
        (width - textPainter.width) / 2,
        (height - textPainter.height) / 2,
      ),
    );

    final ui.Image image = await recorder.endRecording().toImage(width, height);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  Future<BitmapDescriptor> _createClusterMarker(int count) async {
    const int size = 100;

    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    final Paint paint = Paint()..color = Colors.orange;
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    const double radius = size / 2;

    canvas.drawCircle(const Offset(radius, radius), radius, paint);
    canvas.drawCircle(const Offset(radius, radius), radius, borderPaint);

    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '$count',
        style: const TextStyle(
          fontSize: 40,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        radius - textPainter.width / 2,
        radius - textPainter.height / 2,
      ),
    );

    final ui.Image image = await recorder.endRecording().toImage(size, size);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List bytes = byteData!.buffer.asUint8List();

    return BitmapDescriptor.fromBytes(bytes);
  }

  void _onClusterTapped(Cluster<CarClusterItem> cluster) async {
    if (cluster.items.length <= 1) return;

    final GoogleMapController controller = await _controller.future;
    final LatLng center = cluster.location;

    // Settings for stacking markers
    const double verticalSpacing = 0.00008;
    double startLat = center.latitude - (verticalSpacing * (cluster.items.length - 1) / 2);

    Set<Marker> newMarkers = {};
    int idx = 0;
    for (var item in cluster.items) {
      final car = item.car;
      final icon = await _createCarPriceMarker(car.price);

      newMarkers.add(
        Marker(
          markerId: MarkerId(car.id),
          position: LatLng(startLat + (idx * verticalSpacing), center.longitude),
          icon: icon,
          infoWindow: InfoWindow(
            title: car.title,
            snippet: car.price,
          ),
          onTap: () async {
            // Show detailed marker with image when tapped
            final detailedIcon = await _createCarMarkerWithImage(car);
            if(context.mounted){
              setState(() {
                _markers = {
                  Marker(
                    markerId: MarkerId(car.id),
                    position: LatLng(startLat + (idx * verticalSpacing), center.longitude),
                    icon: detailedIcon,
                    infoWindow: InfoWindow(
                      title: car.title,
                      snippet: car.price,
                    ),
                  ),
                };
              });
            }
            final controller = await _controller.future;
            controller.showMarkerInfoWindow(MarkerId(car.id));
          },
        ),
      );
      idx++;
    }

    setState(() {
      _markers = newMarkers;
      _isClusterExpanded = true; // Mark cluster as expanded
    });

    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: center,
          zoom: 17.5,
        ),
      ),
    );
  }

  void _onMapTapped(LatLng position) async {
    if (_isClusterExpanded) {
      // Collapse the cluster and reset to original clustered state
      _isClusterExpanded = false;
      _updateClusterItems();
      final GoogleMapController controller = await _controller.future;
      controller.hideMarkerInfoWindow(MarkerId(_markers.first.markerId.value));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GoogleMap(
        initialCameraPosition: _initialCameraPosition,
        markers: _markers,
        onMapCreated: (controller) {
          _controller.complete(controller);
          _clusterManager.setMapId(controller.mapId);
        },
        onCameraMove: _clusterManager.onCameraMove,
        onCameraIdle: _clusterManager.updateMap,
     //   onTap: _onMapTapped, // Handle map taps
      ),
    );
  }
}