import 'package:fl_carmax/pages/buy_car/provider/home_provider.dart'; // Import HomeProvider
import 'package:fl_carmax/pages/buy_car/search/search_provider.dart'; // Import SearchProvider
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart'; // Add provider import
import 'package:sizer/sizer.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({Key? key}) : super(key: key);

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _preloadData(); // Preload data on splash screen
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app returns from background, restart the splash flow
     // _preloadData();
    }
  }

  Future<void> _preloadData() async {
    final homeProvider = Provider.of<HomeProvider>(context, listen: false);
  //  final searchProvider = Provider.of<SearchProvider>(context, listen: false);

    // Preload necessary data
    await Future.wait([
      homeProvider.fetchFeaturedCars(),
      homeProvider.fetchNonFeaturedCars(),
     // searchProvider.fetchWishlist(),
    ]);

    // After the data is preloaded, navigate to the BottomNavigation screen
    if (mounted) {
      Future.delayed(const Duration(seconds: 2)).then(
            (value) {
          Navigator.pushReplacementNamed(context, '/BottomNavigation');
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion(
      value: const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Image.asset(
            'assets/images/logo1.jpg',
            height: 30.h,
            width: 30.h,
          ),
        ),
      ),
    );
  }
}
