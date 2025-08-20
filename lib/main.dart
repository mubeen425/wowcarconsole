import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:fl_carmax/bottom_nav_provider.dart';
import 'package:fl_carmax/helper/filter_sheet_provider.dart';
import 'package:fl_carmax/pages/buy_car/brand_related_cars/brand_related_cars_page.dart';
import 'package:fl_carmax/pages/buy_car/car_detail/car_detail_provider.dart';
import 'package:fl_carmax/pages/buy_car/compare_page/compare_controller.dart';
import 'package:fl_carmax/pages/buy_car/provider/home_provider.dart';
import 'package:fl_carmax/pages/buy_car/search/search_provider.dart';
import 'package:fl_carmax/pages/sell_car/test_drive_or_inspection/test_drive_or_inspection_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import 'bottom_navigation.dart';
import 'firebase_options.dart';
import 'helper/language_constant.dart';
import 'models/car_listing_model.dart';
import 'pages/account/edit_profile/edit_profile.dart';
import 'pages/account/favourite/favourite_page.dart';
import 'pages/account/help/help_page.dart';
import 'pages/account/language/language_page.dart';
import 'pages/account/my_booking/my_booking_page.dart';
import 'pages/account/terms_and_condition/terms_and_condition_page.dart';
import 'pages/auth/login_page.dart';
import 'pages/auth/register_page.dart';
import 'pages/auth/verification_page.dart';
import 'pages/buy_car/book_test_drive/book_test_drive_page.dart';
import 'pages/buy_car/brand/brand_page.dart';
import 'pages/buy_car/buy_car.dart';
import 'pages/buy_car/check_out/check_out_page.dart';
import 'pages/buy_car/location/confirm_location_page.dart';
import 'pages/buy_car/notification/notification_page.dart';
import 'pages/buy_car/owner_details/owner_details_page.dart';
import 'pages/buy_car/payment/payment_page.dart';
import 'pages/buy_car/payment/payment_sucess_page.dart';
import 'pages/buy_car/recommend_recently_added/recommend_recently_added_page.dart';
import 'pages/buy_car/reviews/reviews_page.dart';
import 'pages/buy_car/search/search_page.dart';
import 'pages/on_boarding/on_boarding_page.dart';
import 'pages/sell_car/add_address/add_address_page.dart';
import 'pages/sell_car/basic_detail/basic_detail_page.dart';
import 'pages/sell_car/basic_detail/basic_detail_page2.dart';
import 'pages/sell_car/book_inspection/book_inspection_page.dart';
import 'pages/sell_car/book_inspection/book_inspection_with_location_page.dart';
import 'pages/sell_car/contact_detail/contact_detail_page.dart';
import 'pages/sell_car/model_select/model_select_page.dart';
import 'pages/sell_car/sell_car.dart';
import 'splash_page.dart';
import 'utils/constant.dart';

// @pragma('vm:entry-point')
// Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
//   await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
// }

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations(
      [DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await LocalNotificationService().requestPermissions();
  // await NotificationService().requestNotificationPermission();
  // await CarCacheService.getCachedCarList();

  // FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
 // SharedPreferences prefs = await SharedPreferences.getInstance();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.setLocale(newLocale);
  }
}

class _MyAppState extends State<MyApp> {
  Locale? _locale;
  setLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

@override
void initState() {
  super.initState();

 // NotificationService().requestNotificationPermission();

  // Delay to ensure context is available
  // Future.delayed(Duration.zero, () {
  //   NotificationService().firebaseInit(context);
  //   NotificationService().setupInteractMessage(context);
  // });
}

  @override
  void didChangeDependencies() {
    getLocale().then((locale) => setLocale(locale));
    super.didChangeDependencies();
  }
  Route popInTransition(Widget child) {
    return PageRouteBuilder(
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
      pageBuilder: (context, animation, secondaryAnimation) =>  child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (BuildContext context, Orientation orientation,
              DeviceType deviceType) =>
          AnnotatedRegion(
        value: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.light,
          statusBarColor: primaryColor,
        ),
        child: MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => SearchProvider()),
            ChangeNotifierProvider(create: (_) => HomeProvider()),
            ChangeNotifierProvider(create: (_) => CompareProvider()),
            ChangeNotifierProvider(create: (_) => CarDetailProvider()),
            ChangeNotifierProvider(create: (_) => BottomNavProvider()),
            ChangeNotifierProvider(create: (_) => FilterSheetProvider()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'WowCar',
            initialRoute: '/SplashPage',
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: _locale,
            theme: ThemeData(
              scaffoldBackgroundColor: scaffoldColor,
              primarySwatch: Colors.blue,
            ),
            onGenerateRoute: (settings) {
              final arguments = settings.arguments;
              switch (settings.name) {
                case '/SplashPage':
                  return popInTransition(const SplashPage());
                case '/OnBoardingPage':
                  return popInTransition(const OnBoardingPage());
                case '/LoginPage':
                  return popInTransition(const LoginPage());
                case '/RegisterPage':
                  return popInTransition(const RegisterPage());
                case '/VerificationPage':
                  return popInTransition(const VerificationPage());
                case '/BottomNavigation':
                  return popInTransition(const BottomNavigation());
                case '/BuyCarPage':
                  return popInTransition(const BuyCar());
                case '/RecommendRecentlyAddedPage':
                  return popInTransition( arguments == 0
                      ? const RecommendRecentlyAddedPage(pageWithLogic: 0)
                      : const RecommendRecentlyAddedPage(pageWithLogic: 1),);
                case '/BrandPage':
                  return popInTransition(const BrandPage());
                case '/BrandRelatedCarsPage':
                  return popInTransition(const BrandRelatedCarsPage());
                // case '/CarDetailPage':
                //   return PageTransition(
                //       isIos: true,
                //       child: CarDetailPage(carId: arguments as String),
                //       type: PageTransitionType.rightToLeft);
                case '/OwnerDetailsPage':
                  return popInTransition(const OwnerDetailsPage());
                case '/BookTestDrivePage':
                  return popInTransition(const BookTestDrivePage());
                case '/CheckOutPage':
                  return popInTransition(const CheckOutPage());
                case '/PaymentPage':
                  return popInTransition(const PaymentPage());
                case '/PaymentSucessPage':
                  return popInTransition(arguments == 0
                      ? const PaymentSucessPage(pageFor: 0)
                      : arguments == 1
                      ? const PaymentSucessPage(pageFor: 1)
                      : const PaymentSucessPage(pageFor: 2));
                case '/ConfirmLocationPage':
                  return popInTransition(const ConfirmLocationPage());
                case '/SearchPage':
                  return popInTransition(const SearchPage());
                case '/NotificationPage':
                  return popInTransition(const NotificationPage());
                case '/ReviewsPage':
                  return popInTransition(const ReviewsPage());
                case '/SellCarPage':
                  return popInTransition(const SellCar());
                case '/TestDriveOrInspectionPage':
                  return popInTransition(arguments == 'testDrive'
                      ? const TestDriveOrInspectionPage(pageFor: 'Testdrive')
                      : const TestDriveOrInspectionPage(
                      pageFor: 'Book inspection'));
                case '/AddAddressPage':
                  return popInTransition( arguments == false
                      ? const AddAddressPage(navigateBack: false)
                      : const AddAddressPage(navigateBack: true),);
                case '/ModelSelectPage':
                  return popInTransition(const ModelSelectPage());
                case '/BasicDetailPage':
                  return popInTransition(const BasicDetailPage());
                case '/BasicDetailPage2':
                  return popInTransition(const BasicDetailPage2());
                case '/ContactDetailPage':
                  return popInTransition(const ContactDetailPage());
                case '/BookInspectionPage':
                  return popInTransition(const BookInspectionPage());
                case '/BookInspectionWithLocationPage':
                  return popInTransition(const BookInspectionWithLocationPage());
                case '/EditProfile':
                  return popInTransition(const EditProfile());
                case '/MyBookingPage':
                  return popInTransition(const MyBookingPage());
                case '/FavouritePage':
                  return popInTransition(const FavouritePage(showAppBar: true,));
                case '/HelpPage':
                  return popInTransition(const HelpPage());
                case '/TermsAndConditionPage':
                  return popInTransition(const TermsAndConditionPage());
                case '/LanguagePage':
                  return  popInTransition(const LanguagePage());
              }
              return null;
            },
          ),
        ),
      ),
    );
  }
}

class CarCacheService {
  static Future<List<CarListing>>? _cachedCarList;

  /// Get cached or fresh car list
  static Future<List<CarListing>> getCachedCarList({bool forceRefresh = false}) async {
    if (!forceRefresh && _cachedCarList != null) return _cachedCarList!;
    _cachedCarList = _fetchFromAPI();
    return await _cachedCarList!;
  }

  /// Fetch data from API
  static Future<List<CarListing>> _fetchFromAPI() async {
    String? apiLanguage = await getApiLanguage();
    final url = Uri.parse('https://www.wowcar.co.th/wp-json/listivo/v1/all-listings-with-guids?lang=$apiLanguage');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final jsonData = data["results"];

      if (jsonData is List) {
        final cars = jsonData
            .map((e) => CarListing.fromJson(e))
            .whereType<CarListing>()
            .toList();

        // Sort by post date DESC
        cars.sort((a, b) {
          final aDate = DateTime.tryParse(a.postDate ?? '') ?? DateTime(2000);
          final bDate = DateTime.tryParse(b.postDate ?? '') ?? DateTime(2000);
          return bDate.compareTo(aDate);
        });

        return cars;
      } else {
        throw Exception("Unexpected data format: 'results' is not a list");
      }
    } else {
      throw Exception("Failed to fetch cars: ${response.statusCode}");
    }
  }
}
