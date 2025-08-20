import 'dart:convert';
import 'dart:developer';

import 'package:http/http.dart' as http;

import '../../../common_libs.dart';
import '../../../helper/cities_alert_dialog.dart';
import '../../../helper/language_constant.dart';
import '../../../main.dart';
import '../../../models/car_listing_model.dart';
import '../../../utils/constant.dart';
import '../../../utils/widgets.dart';
import '../compare_page/compare_controller.dart';

class HomeProvider extends ChangeNotifier {
  final Set recentlyAddedFav = {};
  final Set<int> recommendedFav = {};
  Set<int> recommendedFav1 = {};
  List<CarListing> cars = []; // Keep for backward compatibility
  List<CarListing> featuredCars = [];
  List<CarListing> nonFeaturedCars = [];
  String currentCity = 'Surat';
  String selectedLanguage = 'Thai';  // default to Thai
  final Map<String, String> languages = {
    // 'English': 'en',
    // 'Thai': 'hi',
    // 'Bahasa': 'id',
    // 'Chinese': 'zh',
    // 'Arabic': 'ar',
    'English': 'en',
    'Arabic': 'ar',
    //  'Bahasa': 'id',
    'Chinese': 'zh',
    'Thai': 'hi',
    //  'Turkish': 'tr'
  };

  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLangCode = prefs.getString(laguageCode) ?? 'hi';  // Thai code

    final matchingEntry = languages.entries.firstWhere(
          (entry) => entry.value == savedLangCode,
      orElse: () => const MapEntry('Thai', 'hi'),
    );

    selectedLanguage = matchingEntry.key;
    notifyListeners();
  }

  Future<void> updateLanguage(BuildContext context, String newLanguage) async {
    if (selectedLanguage != newLanguage) {
      cars = []; // Clear the cars list to avoid stale data
      // Update selected language and save to SharedPreferences
      selectedLanguage = newLanguage;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(laguageCode, languages[newLanguage]!);

      // Immediately update the locale for instant UI language change
      Locale newLocale = Locale(languages[newLanguage]!);
      if (context.mounted) {
        MyApp.setLocale(context, newLocale);
      }

      // Trigger UI rebuild immediately
      notifyListeners();

      // Update compare list with new language (non-blocking)
      if (context.mounted) {
        Provider.of<CompareProvider>(context, listen: false).updateCompareListWithNewLanguage();
      }

      // Navigate to main screen to reflect UI changes
      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/BottomNavigation');
      }

      // Fetch data in the background after navigation
      _recentlyAddedCars = fetchRecentlyAddedCars(); // Non-blocking assignment
      await Future.wait([
        fetchFeaturedCars(),
        fetchNonFeaturedCars(),
      ]); // Fetch data concurrently
    }
  }

  bool isLoading = true;
  void showLanguagesDialog(BuildContext context) async {
    String? newLanguage = await showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: languages.keys.map((lang) {
              return GestureDetector(
                onTap: () {
                  Navigator.pop(context, lang);

                },
                child: PrimaryContainer(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding:
                  const EdgeInsets.symmetric(vertical: 13, horizontal: 19),
                  child: Row(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 2.4.h,
                            width: 2.4.h,
                            decoration: BoxDecoration(
                              color: selectedLanguage == lang
                                  ? primaryColor
                                  : white,
                              shape: BoxShape.circle,
                              boxShadow: selectedLanguage == lang
                                  ? [myPrimaryShadow]
                                  : [myBoxShadow],
                            ),
                          ),
                          const CircleAvatar(
                            backgroundColor: white,
                            radius: 3,
                          )
                        ],
                      ),
                      widthSpace15,
                      Text(lang, style: blackMedium16),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (newLanguage != null) {
      // Use updateLanguage to set language, refresh data, and update locale
     if(context.mounted){
       await updateLanguage(context, newLanguage);
     }
    }
  }
Future<List<CarListing>>? get recentlyAddedCars => _recentlyAddedCars;

  Future<List<CarListing>>? _cachedRecentlyAddedCars;
  Future<List<CarListing>>? _recentlyAddedCars;
  //Future<List<CarListing>> getRecentlyAddedCarsOnce({bool isFeatured = false}) {
  //  _recentlyAddedCars ??= fetchRecentlyAddedCars(isFeatured: isFeatured); // Pass the parameter here
  //  return _recentlyAddedCars!;
 // }
  Future<List<CarListing>> fetchFeaturedCars() async {
    return fetchRecentlyAddedCars(isFeatured: true);
  }

  Future<List<CarListing>> fetchNonFeaturedCars() async {
    return fetchRecentlyAddedCars(isFeatured: false);
  }


Future<List<CarListing>> refreshRecentlyAddedCars() async {
  _recentlyAddedCars = fetchRecentlyAddedCars(); // this already returns Future<List<CarListing>>
  final data = await _recentlyAddedCars!;
  notifyListeners();
  return data; // ✅ return list of cars so UI can use it
}



  // Future<List<CarListing>> getRecentlyAddedCarsOnce() {
  //   if (_cachedRecentlyAddedCars != null) {
  //     return _cachedRecentlyAddedCars!;
  //   }

  //   _cachedRecentlyAddedCars = fetchRecentlyAddedCars();
  //   return _cachedRecentlyAddedCars!;
  // }
  late Future<List<CarListing>> recentlyAddedFuture;
  Future<List<CarListing>> fetchRecentlyAddedCars({bool isFeatured = false}) async {
    log("Working Here: ${isFeatured ? 'Featured' : 'Non-Featured'}");
    // Set the is_featured parameter based on whether it's featured or non-featured
    String isFeaturedParam = isFeatured ? '1' : '0';
    String? apiLanguage = await getApiLanguage();
    final url = Uri.parse(
        'https://www.wowcar.co.th/wp-json/listivo/v1/all-listings-with-guids?per_page=10&page=1&lang=${apiLanguage ?? 'en'}&is_featured=$isFeaturedParam');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final data = jsonData["results"];
        if (data is! List) {
          log("❌ Expected 'results' to be a List but got: ${data.runtimeType}");
          return [];
        }

        // Parse the car listings
        List<CarListing> fetchedCars = data
            .map((e) {
          try {
            return CarListing.fromJson(e);
          } catch (e) {
            log("❌ Error parsing car: $e");
            return null;
          }
        }).whereType<CarListing>()
            .toList();

        // Sort by postDate DESC
        fetchedCars.sort((a, b) {
          final dateA = DateTime.tryParse(a.postDate ?? '') ?? DateTime(2000);
          final dateB = DateTime.tryParse(b.postDate ?? '') ?? DateTime(2000);
          return dateB.compareTo(dateA); // Newest first
        });

        // Store cars in the appropriate list based on whether they're featured
        if (isFeatured) {
          featuredCars = fetchedCars;
          log("✅ Fetched ${featuredCars.length} featured cars");
        } else {
          nonFeaturedCars = fetchedCars;
          log("✅ Fetched ${nonFeaturedCars.length} non-featured cars");
        }

        // Also update the main cars list for backward compatibility
        cars = isFeatured ? featuredCars : nonFeaturedCars;

        if (fetchedCars.isNotEmpty) {
          log("First car model: ${fetchedCars.first.modelsListD![0]}");
        }

        notifyListeners();
        return fetchedCars;
      } else {
        log("❌ Failed with status code: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      log("❌ Exception during fetch: $e");
      return [];
    }
  }

  // Add getters for convenience
  List<CarListing> get allFeaturedCars => featuredCars;
  List<CarListing> get allNonFeaturedCars => nonFeaturedCars;

  Future<void> handleRefresh() async {
    List<CarListing> data = await refreshRecentlyAddedCars();
    recentlyAddedFuture = Future.value(data);
    notifyListeners();
  }

  void toggleRecommendedFavorite(
      int index, CarListing car, BuildContext context) {
    if (recommendedFav.contains(index)) {
      recommendedFav.remove(index);
      _showSnackBar(context, '${car.title} ${translation(context).removedFav}');
    } else {
      recommendedFav.add(index);
      _showSnackBar(context, '${car.title} ${translation(context).addedFav}');
    }
    notifyListeners();
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 2),
        content: Text(message, style: whiteMedium14),
      ),
    );
  }

  void showCitiesDialog(context) async {
    currentCity = await showDialog(
            context: context,
            builder: (context) =>
                CitiesAlertDialog(initialCity: currentCity)) ??
        currentCity;
    notifyListeners();
  }

  void toggleCompare(context, CarListing car) {
    final provider = Provider.of<CompareProvider>(context, listen: false);
    provider.toggleCar(car);
  }
}
