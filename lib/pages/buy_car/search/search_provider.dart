import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:fl_carmax/models/car_brand_with_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helper/filter_sheet.dart';
import '../../../helper/language_constant.dart';
import '../../../helper/short_by_sheet.dart';
import '../../../models/car_listing_model.dart';
import '../../../utils/constant.dart';
import '../../auth/login_page_email.dart';
import '../compare_page/compare_controller.dart';

enum ViewState { normal, loading, error }

class SearchProvider extends ChangeNotifier {
  // SearchProvider() {
  //   loadFilterOptions();
  // }
  void initializeBrandFilter() {
    print("you have selected the brand $_filterBrandSlug");

    // Ensure the _filterBrandSlug is not null or empty
    if (_filterBrandSlug != null && _filterBrandSlug!.isNotEmpty) {
      final matchingMake = makesList.firstWhere(
            (make) => make.slug != null && make.slug!.toLowerCase() == _filterBrandSlug!.toLowerCase(),
        orElse: () => CarMakeModel(name: '', children: []), // Default if no match
      );

      if (matchingMake.name != null && matchingMake.name!.isNotEmpty) {
        selectedMakes = [matchingMake.name!];
        _selectedBrand = [matchingMake];
      } else {
        // Fallback to 'Any' if no match found
        selectedMakes = ['Any'];
        _selectedBrand = []; // Empty list as fallback
      }
    } else {
      // Fallback to 'Any' if no brand slug provided
      selectedMakes = ['Any'];
      _selectedBrand = []; // Empty list as fallback
    }

    // Reset selected models
    selectedModels = ['Any'];
  }

  String searchUrl = "https://www.wowcar.co.th/wp-json/listivo/v1/all-listings-with-guids?per_page=14&page=1&search=";
// Make getSearchUrl async to use await
  Future<String> getSearchUrl(String query, {int page = 1}) async {
    // Ensure the apiLanguage is fetched
    String? apiLanguage = await getApiLanguage();

    // Construct the search URL with the language parameter
    return "https://www.wowcar.co.th/wp-json/listivo/v1/all-listings-with-guids?per_page=14&page=$page&search=$query&lang=$apiLanguage${selectedSortIndex == 0 ? '&relevance=' : ''}";
  }

  List<CarListing> apiCarList = [];
  List<CarListing> searchCarList = [];
  List<CarListing> originalCarList = [];
  List<CarListing> featuredCarList = [];
  static List<CarListing>? cachedCarList;
  List<CarListing> forFilterData = [];
  List<CarListing> forFilterDataTemp = [];
  bool isLoadingFilter = false;   // <-- Ye yahan banega

  bool isLoading = false;
  bool isFilterApplied = false;
  bool isFiltersLoaded = false;
  bool isLoadingMore = false;
  bool hasMoreData = true;
  String? _filterBrandSlug;
  String? _lastFetchLanguage;
  List<CarListing>? _cachedOriginalForFilter; // cached base list used for filtering
  // --- context trackers to know when to refetch working data (but NOT overwrite cache) ---

  // --- cache only updated on language change for filter options ---
  Map<String, dynamic>? _cachedFilterTaxonomies;
  String? _lastFilterLanguage;

// --- context trackers (other context changes trigger refetch but do NOT overwrite cache) ---
  bool? _lastFilterMoreFromThisCarDetail;
  bool? _lastFilterMightFromThisSeller;
  String? _lastFilterAuthorId;
  String? _lastFilterListingId;
  String? _lastBrandSlug;
  String? _lastFetchBrandSlug;
  Timer? _debounceTimerforPrice;
  Timer? _yearDebounceTimer;
  Timer? _kmDebounceTimer;

  Map<String, dynamic>? filterSheet;
  Set<int> favouriteIds = {};

  ViewState _state = ViewState.normal;
  ViewState get state => _state;
  void setState(ViewState newState) {
    _state = newState;
    notifyListeners();
  }

  int selectedSortIndex = 0;
  int _currentPage = 1;
  String? brandSlugSelected;
  void getBrandSlug(String? slg) {
    brandSlugSelected = slg;
    _filterBrandSlug = slg;
  }

  bool? moreFromThisCarDetail;
  void moreFromThisSellerMethod(bool? carDetail){
    moreFromThisCarDetail = carDetail;
    notifyListeners();
  }
  bool? mightFromThisCarDetail;
  void mightFromThisSellerMethod(bool? carDetail){
    mightFromThisCarDetail = carDetail;
    notifyListeners();
  }
  String? authorId,listingId;
  void getCarDAuthorListingId(String? authorId,String? listingId) {
    this.authorId = authorId;
    this.listingId = listingId;
    notifyListeners();
  }
  void resetForSearchPage({bool clearList = true}) {
    if (clearList) {
      searchController.text = "";
      showMap = false;
      pageNum = 1;
      apiCarList.clear();
      originalCarList.clear();
      featuredCarList.clear();
      searchCarList.clear();
      cachedCarList?.clear();
      searchPage = 1;
      hasMoreSearchResults = true;
      isLoading = true;
    }else {
      isLoading = false;
    }
  }

  int pageNum = 1;
  String? apiLanguage;
  int currentPage = 1;
  int totalPages = 1;
  Map<int, List<CarListing>> _pageCache = {};

  Future<void> fetchCarListings({
    bool forceRefresh = false,
    String? brandSlug,
    Map<String, dynamic>? filters,
    bool loadMore = false,
    bool runAPI = true,
    int? page,
  }) async {
    if (page != null) _currentPage = page;


    apiLanguage = await getApiLanguage();
    loadMore ? isLoadingMore = true : isLoading = true;
    notifyListeners();


    try {
      final sortBy = _getSortByParam(selectedSortIndex);


      final url = await _buildUrl(
        brandSlug: brandSlug ?? brandSlugSelected,
        filters: filters,
        sortBy: sortBy,
        page: _currentPage,
        loadMore: loadMore,
        lang: apiLanguage ?? "th",
      );


      log('🌐 Fetching car listings: $url');


      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        log('❌ Failed to fetch car listings: Status ${response.statusCode}');
        apiCarList = [];
        return;
      }


      final data = jsonDecode(response.body);
      final results = (data['results'] ?? [])
          .map<CarListing>((e) => CarListing.fromJson(e))
          .toList();


      if (loadMore) {
        apiCarList.addAll(results);
      } else {
        apiCarList = results;
      }


      currentPage = data['pagination']['current_page'] ?? 1;
      totalPages = data['pagination']['total_pages'] ?? 1;
      hasMoreData = currentPage < totalPages;


    } finally {
      isLoading = false;
      isLoadingMore = false;
      notifyListeners();
    }
  }


  void previousPage(String? brandSlug, {Map<String, dynamic>? filters}) {
    if (_currentPage > 1) {
      _currentPage--;
      fetchCarListings(
        page: _currentPage,
        brandSlug: brandSlug,
        filters: filters,
        runAPI: true,
      );
    }
  }



  void nextPage(String? brandSlug, {Map<String, dynamic>? filters}) {
    if (_currentPage < totalPages) {
      _currentPage++;
      fetchCarListings(
        page: _currentPage,
        brandSlug: brandSlug,
        filters: filters,
        runAPI: true,
      );
    }
  }

  void goToPage(int pageNum, String? brandSlug, {Map<String, dynamic>? filters}) {
    _currentPage = pageNum;       // 👈 update immediately
    notifyListeners();            // 👈 refresh UI instantly

    fetchCarListings(
      page: pageNum,
      brandSlug: brandSlug,
      filters: filters,
      runAPI: true,
    );
  }

  void resetPage() {
    _currentPage = 1;
    currentPage = 1;
  }



  //filter by search
  TextEditingController searchController = TextEditingController();

  Timer? _searchDebounceTimer;
  bool isSearching = false;
  int searchPage = 1;
  bool hasMoreSearchResults = true;

  // This method debounces the search and calls the API
  Future<void> searchFilter(String query, {bool loadMore = false}) async {
    // Cancel previous timer if it exists
    _searchDebounceTimer?.cancel();

    if (query.isEmpty) {
      searchCarList = [];
      hasMoreSearchResults = true;
      searchPage = 1;
      notifyListeners();
      return fetchCarListings(forceRefresh: true);
    }

    // Set a new timer for 2 seconds
    _searchDebounceTimer = Timer(const Duration(seconds: 2), () async {
      try {
        if (!loadMore) {
          isSearching = true;
          searchPage = 1;
          searchCarList.clear();
          hasMoreSearchResults = true;
          notifyListeners();
        } else {
          isLoadingMore = true;
          notifyListeners();
        }

        final url = await getSearchUrl(query, page: searchPage); // Pass _searchPage
        log('🔍 Searching with URL: $url');

        final response = await http.get(Uri.parse(url));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> results = data['results'] ?? [];

          if (loadMore) {
            final newResults = results.map((e) => CarListing.fromJson(e)).toList();
            searchCarList.addAll(newResults);
          } else {
            searchCarList = results.map((e) => CarListing.fromJson(e)).toList();
          }

          // Handle pagination if available in the response
          if (data['pagination'] != null) {
            final currentPage = data['pagination']['current_page'] ?? 1;
            final totalPages = data['pagination']['total_pages'] ?? 1;

            hasMoreSearchResults = currentPage < totalPages;
            if (hasMoreSearchResults) {
              searchPage = currentPage + 1;
            }
          }
          else{
            hasMoreSearchResults = false;
          }
          notifyListeners();

        } else {
          log('❌ Failed to fetch search results: Status ${response.statusCode}');
          if (!loadMore) searchCarList = [];
          hasMoreSearchResults = false; // Stop further loading on errorAdd commentMore actions
          ScaffoldMessenger.of(Get.context!).showSnackBar(
            const SnackBar(content: Text('Failed to load search results')),
          );
        }
      } catch (e) {
        log('❌ Error during search: $e');
        if (!loadMore) searchCarList = [];
        hasMoreSearchResults = false; // Stop further loading on errorAdd commentMore actions
        ScaffoldMessenger.of(Get.context!).showSnackBar(
          const SnackBar(content: Text('An error occurred while searching')),
        );
      } finally {
        isSearching = false;
        isLoadingMore = false;
        notifyListeners();
      }
    });
  }

  // Updated filterBySearch to use the new searchFilter method
  void filterBySearch(
      String query,
      ) async {
    searchController.text = query;
    await searchFilter(query);
  }

  // Method to load more search results when scrolling
  Future<void> loadMoreSearchResults() async {
    if (!isLoadingMore && hasMoreSearchResults && searchController.text.isNotEmpty) {
      isLoadingMore = true;  // Set loading state to true
      notifyListeners();
      await searchFilter(searchController.text, loadMore: true);
      isLoadingMore = false;  // Set loading state to false once the data is loaded
      notifyListeners();
    }
  }

  // In SearchProvider
  String? carMaker;
  String? bodyType;

  void setCarMakerAndBodyType(String? carMaker) {
    this.carMaker = carMaker;
    notifyListeners();
  }

  bool? fromHomeFeature;

  void getFeaturedStatusHome(bool? status) {
    fromHomeFeature = status;
    print("fromHomeFeature set to: $fromHomeFeature");

    // Check if fromHomeFeature is false, retain selectedSortIndex as 1, else reset it to 0
    if (fromHomeFeature == false) {
      selectedSortIndex = 1;  // Keep selectedSortIndex as 1 if fromHomeFeature is false
      print("selectedSortIndex set to: $selectedSortIndex");
      sortCarList(selectedSortIndex);  // Apply sorting
    } else {
      selectedSortIndex = 0;  // Reset to 0 if fromHomeFeature is not false
      print("selectedSortIndex set to: $selectedSortIndex");
    }

    notifyListeners();  // Notify listeners to update UI
  }
  // Build URL
  Future<String> _buildUrl({
    String? brandSlug,
    Map<String, dynamic>? filters,
    String? sortBy,
    int? page,
    String perPage = '10',
    bool loadMore = false,
    String? lang,

  })async {
    final apiLanguage = await getApiLanguage();
    debugPrint("Building URL with Language: $apiLanguage");
    final Map<String, dynamic> queryParams = {
      'per_page': perPage,
      'page': page?.toString() ?? '1',
      'lang': lang ?? apiLanguage ?? 'th',  // Use 'th' as default if no language is set
    };
    brandSlug = brandSlugSelected;
    // Add brandSlug if provided
    if (brandSlug != null) {
      queryParams['car_maker[]'] = brandSlug;
    }

    if (bodyType != null && bodyType!.isNotEmpty) {
      queryParams['body_type[0]'] = bodyType;  // No need to encode manually
    }
    if (carMaker != null && carMaker!.isNotEmpty) {
      queryParams['car_maker[]'] = carMaker; // Use [] to signify an array
    }

    if (fromHomeFeature != null) {
      queryParams['is_featured'] = fromHomeFeature! ? '1' : '0';
    }
// If fromHomeFeature is null, do nothing.
// If selectedSortIndex is 0 (for relevance), add relevance to queryParams
    if (selectedSortIndex == 0) {
      queryParams['relevance'] = '';  // This can be used to signal relevance sorting
    }
    // Handle filters
    if (filters != null) {
      final List<String>? bodyTypes = (filters['bodyType'] as Set<dynamic>?)
          ?.where((e) => e != 'Any')
          .map((e) => e.toString()) // Make sure to call toString if necessary
          .toList();

      // For transmissions: Check if it is a List<dynamic> and cast it to List<String>
      final List<String>? transmissions =
      filters['transmission'] is List<dynamic>
          ? (filters['transmission'] as List<dynamic>)
          .map((e) => e.toString())
          .toList()
          : null;

      // For fuels: Convert Set<dynamic> to List<String>
      final List<String>? fuels = (filters['fuelType'] as Set<dynamic>?)
          ?.where((e) => e != 'Any')
          .map((e) => e.toString()) // Ensure the type is String
          .toList();

      // For colors: Cast to List<String> if not null
      final List<String>? colors = (filters['colors'] as List<dynamic>?)
          ?.map((e) => e.toString()) // Convert to String if necessary
          .toList();

      // For makes and models: Safely cast if not null
      final List<String>? make = (filters['makes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();
      final List<String>? model = (filters['model'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList();

      final double? minPrice = (filters['minPrice'] as num?)?.toDouble();
      final double? maxPrice = (filters['maxPrice'] as num?)?.toDouble();
      final int? minKmInput = filters['minKmInput'];
      final int? maxKmInput = filters['maxKmInput'];
      final int? minYear = filters['minYear'];
      final int? maxYear = filters['maxYear'];
      final String? location = filters['location'];
      if (minPrice != null && maxPrice != null) {
        queryParams['price'] = '${minPrice.toInt()}-${maxPrice.toInt()}';
      }
      if (minYear != null && maxYear != null) {
        queryParams['car_modal'] = '$minYear-$maxYear';
      }
      if (minKmInput != null) {
        queryParams['mileage_min'] = minKmInput.toString();
      }
      if (maxKmInput != null) {
        queryParams['mileage_max'] = maxKmInput.toString();
      }
      if (colors != null && colors.isNotEmpty) {
        for (var i = 0; i < colors.length; i++) {
          log("color:${colors[i]}");
          queryParams['color[$i]'] = colors[i];
        }
      }
      if (transmissions != null && transmissions.isNotEmpty) {
        for (var i = 0; i < transmissions.length; i++) {
          queryParams['transmission[$i]'] = transmissions[i];
        }
      }
      if (fuels != null && fuels.isNotEmpty) {
        for (var i = 0; i < fuels.length; i++) {
          queryParams['fuel_type[$i]'] = fuels[i];
        }
      }
      if (bodyTypes != null && bodyTypes.isNotEmpty) {
        for (var i = 0; i < bodyTypes.length; i++) {
          queryParams['body_type[$i]'] = bodyTypes[i];
        }
      }
      if (make != null && make.isNotEmpty) {
        for (var i = 0; i < make.length; i++) {
          queryParams['car_maker[$i]'] = make[i];
        }
      }
      if (model != null && model.isNotEmpty) {
        for (var i = 0; i < model.length; i++) {
          queryParams['car_model[$i]'] = model[i];
        }
      }
      // if (location != null && location.isNotEmpty) {
      //   queryParams['location'] = location;
      // }
    }

    // Add sortBy if provided
    if (sortBy != null) {
      queryParams.addAll(Uri.splitQueryString(sortBy));
    }

    // final uri = Uri.https('www.wowcar.co.th',
    //     '/wp-json/listivo/v1/all-listings-with-guids?lang=${apiLanguage??'en'}', queryParams);

    ///old ak
    // final uri = Uri.https('www.wowcar.co.th',
    //     '/wp-json/listivo/v1/all-listings-with-guids', queryParams);
    ///old ak-1
    /*  final uri = Uri.https('www.wowcar.co.th',
        '/wp-json/listivo/v1/all-listings-with-guids', {
          ...queryParams,
          if (moreFromThisCarDetail == true) ...{
            if (authorId != null) 'author': authorId!,
            if (listingId != null) 'listing_id': listingId!,
          },
          if (mightFromThisCarDetail == true) ...{
            if (_brandSlug != null) 'car_maker': _brandSlug!,
            if (bodyType != null) 'body_type': bodyType!,
            if (listingId != null) 'listing_id': listingId!,
          },
          if (selectedSortIndex == 0) 'relevance': '',
        });*/
    final uri = Uri.https('www.wowcar.co.th',
        '/wp-json/listivo/v1/all-listings-with-guids', {
          ...Map.from(queryParams),
          if (brandSlug != null) 'car_maker[0]': brandSlug,
          if (moreFromThisCarDetail == true) ...(
              authorId != null ? {
                'author_id': authorId,
                if (listingId != null) 'listing_id': listingId,
              } : {}
          ),
          if (mightFromThisCarDetail == true) ...(
              listingId != null ? {
                'listing_id': listingId,
              } : {}
          ),
          if (selectedSortIndex == 0) 'relevance': '',
        });

    return "$uri";
  }

  // Helper to map sort index to sortBy param
  String? _getSortByParam(int index) {
    switch (index) {
      case 2:
        return "price_sort=asc"; // Price Low to High
      case 3:
        return "price_sort=desc"; // Price High to Low
      case 4:
        return "mileage_sort=asc"; // KM driven Low to High
      case 5:
        return "mileage_sort=desc"; // KM driven High to Low
      case 6:
        return "year_sort=desc"; // Year New to Old
      case 7:
        return "year_sort=asc"; // Year Old to New
      default:
        return null;
    }
  }

// Fetching cars with applied filters
  Future<void> fetchCarsForFilter({bool forceRefresh = false}) async {
    final currentLang = await getApiLanguage();
    final currentMoreFrom = moreFromThisCarDetail;
    final currentMightFrom = mightFromThisCarDetail;
    final currentCarMaker = carMaker;
    final currentAuthorId = authorId;
    final currentListingId = listingId;
    final String? currentBrandSlug = brandSlugSelected;

    final bool languageChanged = _lastFetchLanguage != currentLang;
    final bool baseCacheMissing = _cachedOriginalForFilter == null;

    // 1. Base cache fetch/update: only when forced, missing, or language changed.
    if (forceRefresh || baseCacheMissing || languageChanged) {
      final String langParam = currentLang ?? 'th';
      final String url =
          "https://www.wowcar.co.th/wp-json/listivo/v1/all-listings-with-guids?per_page=1000&page=1&lang=$langParam";
      debugPrint("Fetching base cars for filter (cache update) with URL: $url");

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> results = data['results'] ?? [];
          final parsed = results.map((e) => CarListing.fromJson(e)).toList();

          // Update working lists
          forFilterData = parsed;
          forFilterDataTemp = List.from(parsed);

          // Update base cache & language marker
          _cachedOriginalForFilter = List.from(parsed);
          _lastFetchLanguage = currentLang;

          // Sync context snapshots (for completeness)
          _lastFetchBrandSlug = currentBrandSlug;

          notifyListeners();
        } else {
          debugPrint("Failed to fetch base cars for filter. Status: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("Exception during fetchCarsForFilter (base): $e");
      }
      return;
    }

    // 2. If any context param is active, always refetch working data (do not touch base cache).
    final bool hasAnyContext = (currentBrandSlug != null && currentBrandSlug.isNotEmpty) ||
        (currentMoreFrom == true) ||
        (currentMightFrom == true) ||
        (currentCarMaker != null && currentCarMaker.isNotEmpty) ||
        (currentAuthorId != null && currentAuthorId.isNotEmpty) ||
        (currentListingId != null && currentListingId.isNotEmpty);

    if (hasAnyContext) {
      final String url = await _buildUrl(
        perPage: '1000',
        sortBy: _getSortByParam(selectedSortIndex),
        page: 1,
        brandSlug: currentBrandSlug,
      );
      debugPrint("Fetching cars for filter due to active context with URL: $url");

      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> results = data['results'] ?? [];
          final parsed = results.map((e) => CarListing.fromJson(e)).toList();

          forFilterData = parsed;
          forFilterDataTemp = List.from(parsed);

          // Update context trackers (but do NOT update base cache or language)
          _lastFetchBrandSlug = currentBrandSlug;

          notifyListeners();
        } else {
          debugPrint("Failed to fetch cars for filter (context). Status: ${response.statusCode}");
        }
      } catch (e) {
        debugPrint("Exception during fetchCarsForFilter (context): $e");
      }
      return;
    }

    // 3. No relevant context: reuse cached base list.
    if (_cachedOriginalForFilter != null) {
      forFilterData = List.from(_cachedOriginalForFilter!);
      forFilterDataTemp = List.from(_cachedOriginalForFilter!);
      debugPrint("Reusing cached original forFilterData (no context active)");
    }
  }

  Future<void> fetchCarsForSearch() async {
    // Dynamically get the language (assuming you have a method to fetch the language)
    String apiLanguage = await getApiLanguage() ?? 'english'; // Default to 'english' if null

    // Use the static URL to fetch unfiltered cars (no filters applied)
    final String url = "https://www.wowcar.co.th/wp-json/listivo/v1/all-listings-with-guids?per_page=1000&page=1&lang=$apiLanguage";
    debugPrint("Generated URL for Original Cars (Search) with dynamic lang: $url");

    // Make the HTTP request
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? [];

      debugPrint("Original Cars Length: ${results.length}");

      // Save the original data without modifying filtered data
      originalCarList = results.map((e) => CarListing.fromJson(e)).toList();
      debugPrint("Original Car List saved with ${originalCarList.length} cars");

      // Debugging and verifying the added data
      for (var car in originalCarList) {
        debugPrint("Saved Original Car: ${car.title}");
      }

      // Notify listeners to update the UI after data is loaded
      notifyListeners();
    } else {
      debugPrint("Failed to fetch original cars. Status code: ${response.statusCode}");
    }
  }

// Fetching cars without any applied filters (original data)
  Future<void> fetchFeaturedCars({String? brandSlug}) async {
    final apiLanguage = await getApiLanguage();

    final uri = brandSlug != null
        ? Uri.https(
      'www.wowcar.co.th',
      '/wp-json/listivo/v1/all-listings-with-guids',
      {
        'is_featured': '1',
        'car_maker[]': brandSlug,
        'lang': apiLanguage ?? 'th',
      },
    )
        : Uri.https(
      'www.wowcar.co.th',
      '/wp-json/listivo/v1/all-listings-with-guids',
      {
        'is_featured': '1',
        'lang': apiLanguage ?? 'th',
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final List<dynamic> results = data['results'] ?? [];
      featuredCarList = results.map((e) => CarListing.fromJson(e)).toList();
      notifyListeners();

    }
  }

  // Sort car list
  void sortCarList(int index, ) {

    if (index != selectedSortIndex) {
      print("Updating selectedSortIndex from $selectedSortIndex to $index");
      selectedSortIndex = index; // This will save to SharedPreferences
    }

    switch (index) {
      case 1: // Recently Added (newest first)
        log("WORKING");
        apiCarList.sort((a, b) {
          final dateA = DateTime.tryParse(a.postDate ?? '');
          final dateB = DateTime.tryParse(b.postDate ?? '');
          log(dateA.toString());
          log(dateB.toString());
          if (dateA == null && dateB == null) return 0;
          if (dateA == null) return 1;
          if (dateB == null) return -1;
          return dateB.compareTo(dateA);
        });
        break;
    }
    //notifyListeners();
  }

  // Show sort options
  void showSortBySheet(BuildContext context) async {
    print("Opening SortBySheet with current selectedSortIndex: $selectedSortIndex");
    final selectedIndex = await showModalBottomSheet<int>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      context: context,
      builder: (context) => SortBySheet(initialIndex: selectedSortIndex),
    );

    if (selectedIndex != null && selectedIndex != selectedSortIndex) {
      print("SortBySheet returned index: $selectedIndex");
      selectedSortIndex = selectedIndex;
      notifyListeners();
      if ([0, 1, 2, 3, 4, 5, 6, 7].contains(selectedIndex)) {
        fetchCarListings(
          filters: {
            'minPrice': (lowerValue == 200000) ? 0 : lowerValue,
            'maxPrice': upperValue,
            'fuelType': selectedFuelTypes.toSet(),
            'transmission': selectedTransmissions.contains('Any')
                ? ['Any']
                : selectedTransmissions.toList(),
            'colors': selectedColors.contains('Any')
                ? ['Any']
                : selectedColors.toList(),
            'bodyType': selectedBodyTypes.toSet(),
            'makes': brandSlugSelected != null && brandSlugSelected!.isNotEmpty
                ? [brandSlugSelected]
                : (selectedMakes.contains('Any') ? ['Any'] : selectedMakes),
            'model': selectedModels.contains('Any') ? ['Any'] : selectedModels,
            'minKmInput': minKm,
            'maxKmInput': maxKm,
            'location': locationController.text.trim(),
              'minYear': minYear,
              'maxYear': maxYear,
          },
          forceRefresh: true,
          runAPI: selectedIndex == 1 ? false : true,
        );
      } else {
        isLoading = true;
        isLoadingMore = true;
        notifyListeners();
        await fetchFeaturedCars(brandSlug: brandSlugSelected);
        isLoading = false;
        isLoadingMore = false;
        notifyListeners();
        sortCarList(selectedIndex);
        print("fetchCarListings called with selectedSortIndex: $selectedSortIndex at: ${StackTrace.current}");
      }
    } else {
      print("SortBySheet dismissed or same index selected, retaining selectedSortIndex: $selectedSortIndex");
    }
  }
  // Show filter options
  void showFilterSheet(BuildContext context) async {
    // loadFilterOptions();
    filterSheet = await showModalBottomSheet<Map<String, dynamic>>(
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      context: context,
      builder: (context) => const FilterSheet(),
    );

    debugPrint("Filter Data $filterSheet");
    if (filterSheet != null) {
      if (filterSheet?["clear"] == true) {
        isFilterApplied = false;
        notifyListeners();
        featuredCarList.clear();
        fetchCarListings(forceRefresh: true);
      } else {
        isFilterApplied = true;
        notifyListeners();
        await applyFiltersFromApi(filterSheet!);
      }
    }
  }

  Future<void> applyFiltersFromApi(
      Map<String, dynamic> filters, {
        bool forceRefresh = true,
        bool loadMore = false,
      }) async {
    print("Filters $filters");
    if(showMap){
      searchController.text ="";
    }
    await fetchCarListings(
        forceRefresh: forceRefresh,
        filters: filters,
        loadMore: loadMore,
        runAPI: false);
  }

  Future<void> fetchWishlist() async {
    favouriteIds.clear();
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    final response = await http.post(
      Uri.parse('https://www.wowcar.co.th/wp-json/custom/v1/wishlist'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': userId}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      final List<dynamic> data = body is List ? body : (body['wishlist'] ?? []);
      favouriteIds = data
          .map<int>(
              (e) => int.tryParse(e['post']?['ID']?.toString() ?? '0') ?? 0)
          .where((id) => id != 0)
          .toSet();
      notifyListeners();
    }
  }
  //old filter search
  // void filterBySearch(String query, SearchProvider provider) {
  //   if (query.isEmpty) {
  //     provider.fetchCarListings(); // Reload full list if cleared
  //   } else {
  //     provider.apiCarList = provider.apiCarList.where((car) {
  //       return car.title.toLowerCase().contains(query.toLowerCase());
  //     }).toList();
  //   }
  //   notifyListeners();
  // }

  void toggleCompare(context, CarListing car) {
    CompareProvider provider =
    Provider.of<CompareProvider>(context, listen: false);

    provider.toggleCar(car);
  }

  void handleFavouriteToggle(
      CarListing item,
      BuildContext context,
      bool mounted,
      BuildContext ctx,
      ) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');

    if (userId == null || userId == 0) {
      // User is not logged in
      if (ctx.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(translation(context).loginreq, style: blackMedium18),
            content: Text(translation(context).loginfav,
                style: blackMedium14),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(translation(context).cancel, style: primaryMedium14),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginPageEmail()));
                },
                child: Text(translation(context).login, style: whiteMedium14),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (ctx.mounted) {
      toggleFavouriteOptimistic(item, context, mounted, userId);
    }
  }

  Future<void> toggleFavouriteOptimistic(
      CarListing item,
      BuildContext context,
      bool mounted,
      int userId,
      ) async {
    final listingId = int.tryParse(item.id.toString()) ?? 0;
    final isAdding = !favouriteIds.contains(listingId);

    if (isAdding) {
      favouriteIds.add(listingId);
    } else {
      favouriteIds.remove(listingId);
    }
    notifyListeners();

    // Prepare the API
    final url = Uri.parse(
      isAdding
          ? 'https://www.wowcar.co.th/wp-json/custom/v1/wishlist/add'
          : 'https://www.wowcar.co.th/wp-json/custom/v1/wishlist/remove',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'listing_id': item.id,
        }),
      );

      if (response.statusCode != 200) {
        // ❗ Revert if server failed
        if (isAdding) {
          favouriteIds.remove(listingId);
        } else {
          favouriteIds.add(listingId);
        }
        notifyListeners();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to update favourite")),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: primaryColor,
              duration: const Duration(seconds: 4),
              content: Text(
                isAdding
                    ? '${item.title} ${translation(context).addedFav}'
                    : '${item.title} ${translation(context).removedFav}',
                style: whiteMedium14,
              ),
            ),
          );
        }
      }
    } catch (e) {
      // ❗ Handle network error
      if (isAdding) {
        favouriteIds.remove(listingId);
      } else {
        favouriteIds.add(listingId);
      }
      notifyListeners();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Network error occurred")),
        );
      }
    }
  }

/*  Future<void> toggleFavourite(
      CarListing item, BuildContext context, mounted) async {
    final listingId = int.tryParse(item.id.toString()) ?? 0;
    final isAdding = !favouriteIds.contains(listingId);

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id') ?? 0;

    final url = Uri.parse(
      isAdding
          ? 'https://www.wowcar.co.th/wp-json/custom/v1/wishlist/add'
          : 'https://www.wowcar.co.th/wp-json/custom/v1/wishlist/remove',
    );

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'user_id': userId,
        'listing_id': item.id,
      }),
    );

    if (response.statusCode == 200) {
      if (isAdding) {
        favouriteIds.add(listingId);
      } else {
        favouriteIds.remove(listingId);
      }
      notifyListeners();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: primaryColor,
        duration: const Duration(seconds: 1),
        content: Text(
          isAdding
              ? '${item.title} Added to Favourites'
              : '${item.title} Removed from Favourites',
          style: whiteMedium14,
        ),
      ));
    }
  }*/

  ///FilterSheet Functions
  List<String> _extractNames(List? items) {
    return items?.map((e) => e['name'].toString()).toList() ?? [];
  }

  List<CarMakeModel> _extractMakeData(List? items) {
    return items?.map((e) => CarMakeModel.fromJson(e)).toList() ?? [];
  }

  List<String> fuelTypeList = ['Any'];
  List<String> transmissionList = ['Any'];
  List<String> bodyTypeList = ['Any'];
  List<String> modelsList = ['Any'];
  List<CarMakeModel> makesList = [];
  Map<String, Color> colors = {};
  List<String> availableColors = ['Any'];
  List<String> availableBodyTypes = ['Any'];
  List<String> availableTransmissions = ['Any'];
  List<String> availableFuelTypes = ['Any'];
  List<CarMakeModel> availableMakes = [];
  List<String> availableModels = ['Any'];
  Set<String> selectedColors = {'Any'};
  Set<String> selectedFuelTypes = {};
  Set<String> selectedTransmissions = {'Any'};
  Set<String> selectedBodyTypes = {};
  double lowerValue = 200000;
  double upperValue = 25000000;
  int minYear = 1980;
  int maxYear = 2025;
  final TextEditingController locationController = TextEditingController();
  String? selectedMake;
  String? selectedModel;

  List<String> selectedMakes = [];
  List<String> selectedModels = ['Any'];

  int minKm = 0;
  int maxKm = 500000;
  Future<void> loadFilterOptions({bool forceRefresh = false}) async {
    final currentLang = await getApiLanguage();
    final currentMoreFrom = moreFromThisCarDetail;
    final currentMightFrom = mightFromThisCarDetail;
    final currentAuthor = authorId;
    final currentListing = listingId;

    final bool languageChanged = _lastFilterLanguage != currentLang;
    final bool cacheMissing = _cachedFilterTaxonomies == null;

    // If language changed / no cache / forced ⇒ fetch and update cache
    if (forceRefresh || cacheMissing || languageChanged) {
      debugPrint("Fetching filter options (cache update) for lang: $currentLang");
      isLoadingFilter = true;
      notifyListeners();

      final response = await getFilterOptionsFromApi(lang: currentLang);
      final taxonomies = response['taxonomies'] ?? {};

      // Cache result (only on language change or forced)
      _cachedFilterTaxonomies = {'taxonomies': taxonomies};
      _lastFilterLanguage = currentLang;

      // Sync context trackers so future identical contexts don't unnecessarily refetch
      _lastFilterMoreFromThisCarDetail = currentMoreFrom;
      _lastFilterMightFromThisSeller = currentMightFrom;
      _lastFilterAuthorId = currentAuthor;
      _lastFilterListingId = currentListing;

      // Populate from taxonomies
      fuelTypeList = ['Any', ..._extractNames(taxonomies['listivo_5667'])];
      transmissionList = ['Any', ..._extractNames(taxonomies['listivo_5666'])];
      bodyTypeList = ['Any', ..._extractNames(taxonomies['listivo_9312'])];
      modelsList = ['Any', ..._extractNames(taxonomies['listivo_946'])];
      makesList = [
        CarMakeModel(name: "Any", children: [CarBrandModel(name: 'Any')]),
        ..._extractMakeData(taxonomies['listivo_945'])
      ];
      colors = {
        for (var e in (taxonomies['listivo_8638'] ?? []))
          e['name']: mapThaiColorToColor(e['name']),
      };

      // defaults if not set
      if (fuelTypeList.isNotEmpty && selectedFuelTypes.isEmpty) {
        selectedFuelTypes.add('Any');
      }
      if (bodyTypeList.isNotEmpty && selectedBodyTypes.isEmpty) {
        selectedBodyTypes.add('Any');
      }
      if (selectedMakes.isEmpty) {
        selectedMakes.add('Any');
      }

      isFiltersLoaded = true;
      isLoadingFilter = false;
      notifyListeners();
      return;
    }

    // If other context changed (but language same) ⇒ refetch working filter options only, do NOT overwrite cache
    final bool otherContextChanged =
        _lastFilterMoreFromThisCarDetail != currentMoreFrom ||
            _lastFilterMightFromThisSeller != currentMightFrom ||
            _lastFilterAuthorId != currentAuthor ||
            _lastFilterListingId != currentListing;

    if (otherContextChanged) {
      debugPrint("Refetching filter options due to context change (no cache update).");
      isLoadingFilter = true;
      notifyListeners();

      final response = await getFilterOptionsFromApi(
        authorId: currentAuthor,
        listingId: currentListing,
        lang: currentLang,
      );
      final taxonomies = response['taxonomies'] ?? {};

      // Update context trackers only
      _lastFilterMoreFromThisCarDetail = currentMoreFrom;
      _lastFilterMightFromThisSeller = currentMightFrom;
      _lastFilterAuthorId = currentAuthor;
      _lastFilterListingId = currentListing;

      // Populate from fetched (but do NOT cache it)
      fuelTypeList = ['Any', ..._extractNames(taxonomies['listivo_5667'])];
      transmissionList = ['Any', ..._extractNames(taxonomies['listivo_5666'])];
      bodyTypeList = ['Any', ..._extractNames(taxonomies['listivo_9312'])];
      modelsList = ['Any', ..._extractNames(taxonomies['listivo_946'])];
      makesList = [
        CarMakeModel(name: "Any", children: [CarBrandModel(name: 'Any')]),
        ..._extractMakeData(taxonomies['listivo_945'])
      ];
      colors = {
        for (var e in (taxonomies['listivo_8638'] ?? []))
          e['name']: mapThaiColorToColor(e['name']),
      };

      // defaults if not set
      if (fuelTypeList.isNotEmpty && selectedFuelTypes.isEmpty) {
        selectedFuelTypes.add('Any');
      }
      if (bodyTypeList.isNotEmpty && selectedBodyTypes.isEmpty) {
        selectedBodyTypes.add('Any');
      }
      if (selectedMakes.isEmpty) {
        selectedMakes.add('Any');
      }

      isFiltersLoaded = true;
      isLoadingFilter = false;
      notifyListeners();
      return;
    }

    // Nothing changed: reuse cached taxonomies if needed to ensure lists are populated
    if (!isFiltersLoaded && _cachedFilterTaxonomies != null) {
      debugPrint("Reusing cached filter options.");
      final taxonomies = _cachedFilterTaxonomies?['taxonomies'] ?? {};

      fuelTypeList = ['Any', ..._extractNames(taxonomies['listivo_5667'])];
      transmissionList = ['Any', ..._extractNames(taxonomies['listivo_5666'])];
      bodyTypeList = ['Any', ..._extractNames(taxonomies['listivo_9312'])];
      modelsList = ['Any', ..._extractNames(taxonomies['listivo_946'])];
      makesList = [
        CarMakeModel(name: "Any", children: [CarBrandModel(name: 'Any')]),
        ..._extractMakeData(taxonomies['listivo_945'])
      ];
      colors = {
        for (var e in (taxonomies['listivo_8638'] ?? []))
          e['name']: mapThaiColorToColor(e['name']),
      };

      if (fuelTypeList.isNotEmpty && selectedFuelTypes.isEmpty) {
        selectedFuelTypes.add('Any');
      }
      if (bodyTypeList.isNotEmpty && selectedBodyTypes.isEmpty) {
        selectedBodyTypes.add('Any');
      }
      if (selectedMakes.isEmpty) {
        selectedMakes.add('Any');
      }

      isFiltersLoaded = true;
      notifyListeners();
    }
  }

  Color mapThaiColorToColor(String name) {
    switch (name) {
    // Thai colors
      case 'สีขาว':
      // English colors
      case 'White':
      // Arabic colors
      case 'أبيض':
      // Chinese colors
      case '白色':
        return const Color(0xFFFFFFFF);

    // Thai colors
      case 'สีดำ':
      // English colors
      case 'Black':
      // Arabic colors
      case 'أسود':
      // Chinese colors
      case '黑色':
        return const Color(0xFF000000);

    // Thai colors
      case 'สีเงิน':
      // English colors
      case 'Silver':
      // Arabic colors
      case 'فضي':
      // Chinese colors
      case '银色':
        return const Color(0xFFC0C0C0);

    // Thai colors
      case 'สีชาร์โคล':
      // English colors
      case 'Charcoal':
      // Arabic colors
      case 'فحمي':
      // Chinese colors
      case '炭灰色':
        return const Color(0xFF36454F);

    // Thai colors
      case 'สีน้ำเงิน':
      // English colors
      case 'Blue':
      // Arabic colors
      case 'أزرق':
      // Chinese colors
      case '蓝色':
        return const Color(0xFF0000FF);

    // Thai colors
      case 'สีแดง':
      // English colors
      case 'Red':
      // Arabic colors
      case 'أحمر':
      // Chinese colors
      case '红色':
        return const Color(0xFFFF0000);

    // Thai colors
      case 'สีเทา':
      // English colors
      case 'Grey':
      case 'Gray':
      // Arabic colors
      case 'رمادي':
      // Chinese colors
      case '灰色':
        return const Color(0xFF808080);

    // Thai colors
      case 'สีบรอนซ์':
      // English colors
      case 'Bronze':
      // Arabic colors
      case 'برونزي':
      // Chinese colors
      case '青铜色':
        return const Color(0xFFCD7F32);

    // Thai colors
      case 'สีทอง':
      // English colors
      case 'Gold':
      // Arabic colors
      case 'ذهبي':
      // Chinese colors
      case '金色':
        return const Color(0xFFFFD700);
      case 'สีน้ำตาล':
      case 'Brown':
      case 'بني':
      case '棕色':
        return const Color(0xFFA5552A); // Brown
      case 'สีเหลือง':
      case 'Yellow':
      case 'أصفر':
      case '黄色':
        return const Color(0xFFFFFF00); // Yellow
    // Thai colors
      case 'สีเขียว':
      // English colors
      case 'Green':
      // Arabic colors
      case 'أخضر':
      // Chinese colors
      case '绿色':
        return const Color(0xFF008000); // Green

    // Thai colors
      case 'สีส้ม':
      // English colors
      case 'Orange':
      // Arabic colors
      case 'برتقالي':
      // Chinese colors
      case '橙色':
        return const Color(0xFFFFA500); // Orange

    // Thai colors
      case 'สีม่วง':
// English colors
      case 'Purple':
// Arabic colors
      case 'أرجواني':
// Chinese colors
      case '紫色':
        return const Color(0xFF800080); // Purple

// Thai colors
      case 'สีมารูน':
// English colors
      case 'Maroon':
// Arabic colors
      case 'مارون':
// Chinese colors
      case '栗色':
        return const Color(0xFF800000); // Maroon

// Thai colors
      case 'สีเทอร์ควอยซ์':
// English colors
      case 'Turquoise':
// Arabic colors
      case 'تركواز':
// Chinese colors
      case '绿松石':
        return const Color(0xFF40E0D0); // Turquoise

// Thai colors
      case 'สีเบจ':
// English colors
      case 'Beige':
// Arabic colors
      case 'بيج':
// Chinese colors
      case '米色':
        return const Color(0xFFF5F5DC); // Beige

// Thai colors
      case 'สีเบอร์กันดี':
// English colors
      case 'Burgundy':
// Arabic colors
      case 'برغندي':
// Chinese colors
      case '酒红色':
        return const Color(0xFF800020); // Burgundy



      default:
        return const Color(0xFF000000); // Default to black if not found
    }
  }
/*  Color mapThaiColorToColor(String name) {
    switch (name) {
      case 'สีขาว':
        return const Color(0xFFFFFFFF);
      case 'สีดำ':
        return const Color(0xFF000000);
      case 'สีเงิน':
        return const Color(0xFFC0C0C0);
      case 'สีชาร์โคล':
        return const Color(0xFF36454F);
      case 'สีน้ำเงิน':
        return const Color(0xFF0000FF);
      case 'สีแดง':
        return const Color(0xFFFF0000);
      case 'สีเทา':
        return const Color(0xFF808080);
      case 'สีบรอนซ์':
        return const Color(0xFFCD7F32);
      case 'สีทอง':
        return const Color(0xFFFFD700);
      default:
        return const Color(0xFF000000); // Default to black if not found
    }
  }*/

  Future<Map<String, dynamic>> getFilterOptionsFromApi({
    String? authorId,
    String? listingId,
    String? lang, // ✅ lang passable
  }) async {
    // Construct the base URL
    String url = 'https://www.wowcar.co.th/wp-json/listivo/v1/all-listings-with-guids';

    List<String> params = [];

    if (authorId != null && listingId != null) {
      params.add("author_id=$authorId");
      params.add("listing_id=$listingId");
    }

    if (lang != null) {
      params.add("lang=$lang"); // ✅ Add lang here
    }

    if (params.isNotEmpty) {
      url += "?${params.join("&")}";
    }
    // Make the HTTP GET request
    final response = await http.get(Uri.parse(url));

    // Check if the response status code is 200 (OK)
    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      // Ensure the response contains the expected structure
      if (responseData is Map && responseData['results'] is List) {
        final List<dynamic> listings = responseData['results'];

        if (listings.isNotEmpty) {
          final Map<String, List<Map<String, dynamic>>> mergedTaxonomies = {};

          // Process each listing to extract and merge taxonomies
          for (final listing in listings) {
            final taxonomies = listing['taxonomies'] as Map<String, dynamic>?;

            if (taxonomies != null) {
              taxonomies.forEach((key, value) {
                final terms = value as List<dynamic>;
                if (!mergedTaxonomies.containsKey(key)) {
                  mergedTaxonomies[key] = [];
                }

                // Merge taxonomies, ensuring no duplicates
                for (final term in terms) {
                  final existingIndex = mergedTaxonomies[key]!
                      .indexWhere((t) => t['term_id'] == term['term_id']);

                  if (existingIndex == -1) {
                    // Add new term if it doesn't exist
                    mergedTaxonomies[key]!.add(term);
                  } else {
                    // Merge children uniquely if term exists
                    final existingMake = mergedTaxonomies[key]![existingIndex];
                    List existingChildren = (existingMake['children'] as List<dynamic>?) ?? [];
                    List newChildren = (term['children'] as List<dynamic>?) ?? [];

                    for (var newChild in newChildren) {
                      final exists = existingChildren.any(
                              (child) => child['term_id'] == newChild['term_id']);
                      if (!exists) {
                        existingChildren.add(newChild);
                      }
                    }

                    existingMake['children'] = existingChildren;
                    mergedTaxonomies[key]![existingIndex] = existingMake;
                  }
                }
              });
            }
          }

          // Return merged taxonomies
          return {'taxonomies': mergedTaxonomies};
        }
      }
    }

    // Return an empty taxonomies map if the API call fails or no results
    return {'taxonomies': {}};
  }

  void setFuelType(bool isSelected, String value) {
    if (value == 'Any') {
      // If "Any" tapped, select only "Any"
      selectedFuelTypes.clear();
      selectedFuelTypes.add('Any');
    } else {
      // Tapping a specific fuel type
      if (selectedFuelTypes.contains('Any')) {
        selectedFuelTypes.remove('Any');
      }
      if (isSelected) {
        // User is deselecting the fuel type (was previously selected)
        selectedFuelTypes.remove(value);
        // If nothing left, revert to "Any"
        if (selectedFuelTypes.isEmpty) {
          selectedFuelTypes.add('Any');
        }
      } else {
        // User is selecting this fuel type
        selectedFuelTypes.add(value);
      }
    }

    applyAllFilters();
    notifyListeners();
  }

  void setDraggingValue(lower, upper) {
    lowerValue = lower;
    upperValue = upper;
    notifyListeners();
    debugPrint("Price filter changed: lower=$lowerValue, upper=$upperValue");

    /* _debounceTimerforPrice?.cancel();
    _debounceTimerforPrice = Timer(const Duration(milliseconds: 200), () {
      applyAllFilters();
      notifyListeners();
    });*/
  }

  void onCompleteApplyFilters() {
    // Cancel any pending filter operations to avoid multiple calls
    _filterDebounceTimer?.cancel();

    // Start a new timer to apply filters after a short delay
    _filterDebounceTimer = Timer(const Duration(milliseconds: 400), () {
      applyAllFilters();
      notifyListeners();
    });
  }

  void setDraggingValueForYears(min, max) {
    minYear = min;
    maxYear = max;
    notifyListeners();
    debugPrint("Year filter changed: min=$minYear, max=$maxYear");

    /*_yearDebounceTimer?.cancel();
    _yearDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      applyAllFilters();
      notifyListeners();
    });*/
  }

  void setDraggingValueForKMRange(min, max) {
    minKm = min.toInt();
    maxKm = max.toInt();
    debugPrint("filter $minKm");
    debugPrint("filter $maxKm");
    notifyListeners();

    /*_kmDebounceTimer?.cancel();
    _kmDebounceTimer = Timer(const Duration(milliseconds: 200), () {
      applyAllFilters();
      notifyListeners();
    });*/
  }

  setSelectedColor(isSelected, colorName) {
    if (colorName == 'Any') {
      selectedColors.clear();
      selectedColors.add('Any');
    } else {
      selectedColors.remove('Any');
      if (isSelected) {
        // _selectedBrand = [carMake];
        // availableMakes = [carMake];
        selectedColors.remove(colorName);
      } else {
        selectedColors.add(colorName);
      }
    }
    applyAllFilters();
    notifyListeners();
  }

  void setTransmission(bool isSelected, String value) {
    if (value == 'Any') {
      selectedTransmissions.clear();
      selectedTransmissions.add('Any');
    } else {
      if (selectedTransmissions.contains('Any')) {
        selectedTransmissions.remove('Any');
      }
      if (isSelected) {
        // Deselecting the transmission
        selectedTransmissions.remove(value);
        if (selectedTransmissions.isEmpty) {
          selectedTransmissions.add('Any');
        }
      } else {
        // Selecting transmission
        selectedTransmissions.add(value);
      }
    }

    applyAllFilters();
    notifyListeners();
  }

  void setBodyTypes(bool isSelected, String value) {
    if (value == 'Any') {
      selectedBodyTypes.clear();
      selectedBodyTypes.add('Any');

      // Reset dependent selections when "Any" is selected
      availableMakes = [carMake];
      selectedMakes = ['Any'];
      availableModels = ['Any'];
      selectedModels = ['Any'];
    } else {
      if (selectedBodyTypes.contains('Any')) {
        selectedBodyTypes.remove('Any');
      }

      if (isSelected) {
        // Deselect specific body type
        selectedBodyTypes.remove(value);
        if (selectedBodyTypes.isEmpty) {
          selectedBodyTypes.add('Any');
        }
      } else {
        // Select specific body type
        selectedBodyTypes.add(value);
      }

      // Reset dependent models & selectedModels when specific body types are selected
      availableModels = ['Any'];
      selectedModels = ['Any'];
      _selectedBrand = [
        CarMakeModel(name: 'Any', children: [CarBrandModel(name: 'Any')])
      ];
      notifyListeners();
    }
    notifyListeners();
    applyAllFilters();
  }

  List<CarMakeModel> _selectedBrand = [
    CarMakeModel(name: 'Any', children: [CarBrandModel(name: 'Any')])
  ];
  List<CarMakeModel> get selectedBrand => _selectedBrand;

  Timer? _filterDebounceTimer;

  bool _isLoadingMakeModels = false;

  bool get isLoadingMakeModels => _isLoadingMakeModels;


  bool loadingMake =false;
  void setCarMakes(bool isSelected, CarMakeModel value, int index) {
    debugPrint('🔧 setCarMakes(): tapped ${value.name}, isSelected=$isSelected');
    _filterDebounceTimer?.cancel();
    loadingMake = true; // Start loading state
    // If "Any" is selected, reset all selections
    if (value.name == 'Any') {
      _selectedBrand = [carMake];
      selectedMakes = ['Any'];
      availableColors = ['Any'];
      selectedColors = {'Any'};
      selectedModels = ['Any'];

      // Reset models and colors based on the selected body type and price range
      final uniqueColors = <String>{};
      for (var car in forFilterData) {
        final matchBodyType = selectedBodyTypes.contains('Any') ||
            (car.bodyType != null && selectedBodyTypes.contains(car.bodyType));

        final isPriceInRange = int.tryParse(formatter(car.price)) != null &&
            int.parse(formatter(car.price)) >= lowerValue &&
            int.parse(formatter(car.price)) <= upperValue;

        final isYearInRange = int.tryParse(formatter(car.year)) != null &&
            int.parse(formatter(car.year)) >= minYear &&
            int.parse(formatter(car.year)) <= maxYear;

        final isKmInRange = double.tryParse(formatter(car.mileage)) != null &&
            double.parse(formatter(car.mileage)) >= minKm &&
            double.parse(formatter(car.mileage)) <= maxKm;

        if (matchBodyType && isPriceInRange && isYearInRange && isKmInRange) {
          if (car.color?.isNotEmpty == true) {
            uniqueColors.add(car.color!);
          }
        }
      }

      availableColors.addAll(uniqueColors.toList());
    } else {
      // If the make is selected, remove it from selected makes
      if (isSelected) {
        _selectedBrand.remove(value);
        selectedMakes.remove(value.name);

        // Rebuild available colors based on the selected makes
        final uniqueColors = <String>{};
        for (var car in forFilterData) {
          final carMakes = _extractMakeData(car.makesList ?? []).map((e) => e.name).toSet();
          final matchMake = carMakes.any(selectedMakes.contains);

          final matchBodyType = selectedBodyTypes.contains('Any') ||
              (car.bodyType != null && selectedBodyTypes.contains(car.bodyType));

          final isPriceInRange = int.tryParse(formatter(car.price)) != null &&
              int.parse(formatter(car.price)) >= lowerValue &&
              int.parse(formatter(car.price)) <= upperValue;

          final isYearInRange = int.tryParse(formatter(car.year)) != null &&
              int.parse(formatter(car.year)) >= minYear &&
              int.parse(formatter(car.year)) <= maxYear;

          final isKmInRange = double.tryParse(formatter(car.mileage)) != null &&
              double.parse(formatter(car.mileage)) >= minKm &&
              double.parse(formatter(car.mileage)) <= maxKm;

          if (matchBodyType && matchMake && isPriceInRange && isYearInRange && isKmInRange) {
            if (car.color?.isNotEmpty == true) {
              uniqueColors.add(car.color!);
            }
          }
        }

        availableColors = ['Any', ...uniqueColors];
      } else {
        // If the make is deselected, add it back and update models
        selectedMakes.remove('Any');
        _selectedBrand.add(value);
        selectedModels = ['Any'];
        selectedMakes.add(value.name ?? 'Any');
      }
    }

    // Only sort available makes once, not on every change
    if (availableMakes.isEmpty || availableMakes.length == 1) {
      availableMakes.sort((a, b) => a.name!.compareTo(b.name!));
    }

    // debugPrint('🔧 setCarMakes(): selectedBrand = ${_selectedBrand.map((b) => b.name).toList()}');
    // debugPrint('🔧 setCarMakes(): availableModels = $availableModels');

    Future.microtask(() {
      notifyListeners();
    });
    _filterDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      applyAllFilters();
      // loadingMake = false; // End loading state
      notifyListeners();
    });
  }
  void updateData(){
    notifyListeners();
  }

  void setCarModels(bool isSelected, String model) {
    // filterModel(model);
    if (model == "Any") {
      selectedModels = ["Any"]; // Use List here, not Set
    } else {
      selectedModels.remove("Any");
      if (isSelected) {
        selectedModels.remove(model);
      } else {
        selectedModels.add(model);
      }
    }

    selectedModels = selectedModels.isEmpty ? ['Any'] : selectedModels;
    debugPrint("selected modelllll $selectedModels");

    _filterDebounceTimer = Timer(const Duration(seconds: 1), () {
      applyAllFilters();
      notifyListeners();
    });
  }



  // void applyAllFilters() {
  //    debugPrint("Applying filters: price=$lowerValue-$upperValue, year=$minYear-$maxYear, km=$minKm-$maxKm");
  //
  //   // Step 1: Apply all filters at once
  //   Future.delayed(Duration.zero,(){
  //     final filteredCars = forFilterData.where((car) {
  //       final carPrice = int.tryParse(formatter(car.price)) ?? 0;
  //       final carYear = int.tryParse(car.year) ?? 0;
  //       final carKm =
  //           int.tryParse(car.mileage.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
  //       final carFuel = car.fuelType.toLowerCase();
  //       final carTrans = car.transmission.toLowerCase() ?? '';
  //       final carColor = car.color?.toLowerCase() ?? '';
  //       final carBody = car.bodyType.toLowerCase() ?? '';
  //
  //       final makeNames = car.makesList
  //           ?.map((e) => (e as Map)['name']?.toString().toLowerCase())
  //           .whereType<String>()
  //           .toList() ??
  //           [];
  //
  //       final modelNames =
  //           car.modelsListD?.map((e) => e.toString().toLowerCase()).toList() ??
  //               [];
  //
  //       return (carPrice >= lowerValue && carPrice <= upperValue) &&
  //           (carYear >= minYear && carYear <= maxYear) &&
  //           (carKm >= minKm && carKm <= maxKm) &&
  //           (selectedFuelTypes.isEmpty ||
  //               selectedFuelTypes.contains('Any') ||
  //               selectedFuelTypes
  //                   .map((f) => f.toLowerCase())
  //                   .contains(carFuel)) &&
  //           (selectedTransmissions.isEmpty ||
  //               selectedTransmissions.contains('Any') ||
  //               selectedTransmissions
  //                   .map((t) => t.toLowerCase())
  //                   .contains(carTrans)) &&
  //           (selectedColors.isEmpty ||
  //               selectedColors.contains('Any') ||
  //               selectedColors.map((c) => c.toLowerCase()).contains(carColor)) &&
  //           (selectedBodyTypes.isEmpty ||
  //               selectedBodyTypes.contains('Any') ||
  //               selectedBodyTypes
  //                   .map((b) => b.toLowerCase())
  //                   .contains(carBody)) &&
  //           (selectedMakes.isEmpty ||
  //               selectedMakes.contains('Any') ||
  //               selectedMakes
  //                   .map((m) => m.toLowerCase())
  //                   .any((make) => makeNames.contains(make))) &&
  //           (selectedModels.isEmpty ||
  //               selectedModels.contains('Any') ||
  //               selectedModels
  //                   .map((m) => m.toLowerCase())
  //                   .any((model) => modelNames.contains(model)));
  //     }).toList();
  //     sortCarList(selectedSortIndex);
  //     apiCarList = filteredCars;
  //    // debugPrint("Filtered cars: ${filteredCars.length}");
  //
  //     updateAvailableOptions(
  //       filteredCars: filteredCars,
  //     );
  //   });
  //   notifyListeners();
  // }

  bool hasResultsForSelectedYear = true;

  void applyAllFilters() {
    Future.delayed(Duration.zero, () {
      selectedColors = normalizeSelectionSet(selectedColors);
      selectedMakes = normalizeSelection(selectedMakes);
      selectedModels = normalizeSelection(selectedModels);

      final List<CarListing> filteredCars = <CarListing>[];
      final Set<String> addedIds = {}; // Track already added car IDs

      final availableBodySet = <String>{};
      final availableMakeSet = <String>{};
      final availableModelSet = <String>{};
      final availableFuelSet = <String>{};
      final availableColorSet = <String>{};
      final availableTransSet = <String>{};

      for (final car in forFilterData) {
        // Skip if we've already added this car (using ID to check uniqueness)
        if (car.id != null && !addedIds.add(car.id.toString())) {
          continue;
        }

        final carPrice = int.tryParse(formatter(car.price)) ?? 0;
        final carYear = int.tryParse(car.year) ?? 0;
        final carKm = int.tryParse(car.mileage.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

        if (carPrice < lowerValue || carPrice > upperValue) continue;
        if (carYear < minYear || carYear > maxYear) continue;
        if (carKm < minKm || carKm > maxKm) continue;

        final carFuel = car.fuelType.trim();
        final carBody = car.bodyType.trim();
        final carTrans = car.transmission.trim();
        final carColor = car.color?.trim() ?? '';

        final makeNames = (car.makesList ?? [])
            .map((e) => ((e as Map)['name']?.toString() ?? ''))
            .toSet();

        final modelNames = (car.modelsListD ?? [])
            .map((e) {
          if (e is Map && e['name'] != null) {
            return e['name'].toString();
          }
          return '';
        }).where((name) => name.isNotEmpty).toSet();

        final passesBody = selectedBodyTypes.isEmpty || selectedBodyTypes.contains('Any') || selectedBodyTypes.contains(carBody);
        final passesMake = selectedMakes.isEmpty || selectedMakes.contains('Any') || selectedMakes.any((m) => makeNames.contains(m));
        final passesModel = selectedModels.isEmpty || selectedModels.contains('Any') || selectedModels.any((m) => modelNames.contains(m));
        final passesFuel = selectedFuelTypes.isEmpty || selectedFuelTypes.contains('Any') || selectedFuelTypes.contains(carFuel);
        final passesColor = selectedColors.isEmpty || selectedColors.contains('Any') || selectedColors.contains(carColor);
        final passesTrans = selectedTransmissions.isEmpty || selectedTransmissions.contains('Any') || selectedTransmissions.contains(carTrans);

        final passesAll = passesBody && passesMake && passesModel && passesFuel && passesColor && passesTrans;

        if (passesAll) filteredCars.add(car);

        // remainder of the code stays the same
        if (passesMake && passesModel && passesFuel && passesColor && passesTrans) availableBodySet.add(carBody);
        if (passesBody && passesModel && passesFuel && passesColor && passesTrans) makeNames.forEach(availableMakeSet.add);
        if (passesBody && passesMake && passesFuel && passesColor && passesTrans) modelNames.forEach(availableModelSet.add);
        if (passesBody && passesMake && passesModel && passesColor && passesTrans) availableFuelSet.add(carFuel);
        if (passesBody && passesMake && passesModel && passesFuel && passesTrans) availableColorSet.add(carColor);
        if (passesBody && passesMake && passesModel && passesFuel && passesColor) availableTransSet.add(carTrans);
      }

      apiCarList = filteredCars;
      hasResultsForSelectedYear = filteredCars.isNotEmpty;
      sortCarList(selectedSortIndex);

      // Update available options
      availableBodyTypes = ['Any', ...availableBodySet.toList()..sort()];
      availableFuelTypes = ['Any', ...availableFuelSet.toList()..sort()];
      availableTransmissions = ['Any', ...availableTransSet.toList()..sort()];
      availableColors = ['Any', ...availableColorSet.toList()..sort()];
      availableMakes = [
        CarMakeModel(name: 'Any', children: []),
        ...makesList.where((m) => availableMakeSet.contains(m.name)).toList()
          ..sort((a, b) => a.name!.compareTo(b.name!))
      ];
      availableModels = ['Any', ...availableModelSet.toList()..sort()];

      notifyListeners();
    });
  }

  List<String> normalizeSelection(List<String> list) {
    return list.isEmpty ? ['Any'] : list;
  }

  Set<String> normalizeSelectionSet(Set<String> set) {
    return set.isEmpty ? {'Any'} : set;
  }

  Future<void> updateAvailableOptions({List<CarListing>? filteredCars, price, year, mileage})async {
    selectedColors = normalizeSelectionSet(selectedColors);
    selectedMakes = normalizeSelection(selectedMakes);
    selectedModels = normalizeSelection(selectedModels);

    final fuelTypes = <String>{};
    final bodyTypes = <String>{};
    final transmissions = <String>{};
    final colorsSet = <String>{};

    for (var car in forFilterData) {
      final carPrice = int.tryParse(formatter(car.price)) ?? 0;
      final carYear = int.tryParse(car.year) ?? 0;
      final carKm = int.tryParse(car.mileage.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      final isWithinRange = carPrice >= lowerValue &&
          carPrice <= upperValue &&
          carYear >= minYear &&
          carYear <= maxYear &&
          carKm >= minKm &&
          carKm <= maxKm;

      final matchesColor = selectedColors.contains('Any') || selectedColors.contains(car.color);
      final matchesTransmission = selectedTransmissions.contains('Any') || selectedTransmissions.contains(car.transmission);
      final matchesFuel = selectedFuelTypes.contains('Any') || selectedFuelTypes.contains(car.fuelType);
      final matchesBodyType = selectedBodyTypes.contains('Any') || selectedBodyTypes.contains(car.bodyType);
      final matchesMake = selectedMakes.contains('Any') || carHasSelectedMake(car);
      final matchesModel = selectedModels.contains('Any') || carHasSelectedModel(car);

      if (isWithinRange && matchesColor && matchesTransmission && matchesFuel && matchesBodyType && matchesMake && matchesModel) {
        if (car.fuelType.trim().isNotEmpty) fuelTypes.add(car.fuelType.trim());
        if (car.bodyType.trim().isNotEmpty) bodyTypes.add(car.bodyType.trim());
        if (car.transmission.trim().isNotEmpty) transmissions.add(car.transmission.trim());
        if ((car.color ?? '').trim().isNotEmpty) colorsSet.add(car.color!.trim());
      }
    }

    // Update dropdowns
    availableFuelTypes = ['Any', ...fuelTypes.toList()..sort()];
    availableBodyTypes = ['Any', ...bodyTypes.toList()..sort()];
    availableTransmissions = ['Any', ...transmissions.toList()..sort()];
    availableColors = ['Any', ...colorsSet.toList()..sort()];

    // Update make/model once (not repeatedly during filtering)
    updateCarMake();
  }

  bool updateCarMake() {
    final uniqueMakeNames = <String>{};
    final uniqueModelNames = <String>{};

    final selectedMakeLower = selectedMakes
        .where((m) => m != 'Any')
        .map((m) => m.toLowerCase())
        .toSet();

    // Apply all filters except make/model
    final filteredCars = forFilterData.where((car) {
      final carPrice = int.tryParse(formatter(car.price)) ?? 0;
      final carYear = int.tryParse(car.year) ?? 0;
      final carKm =
          int.tryParse(car.mileage.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;

      return (carPrice >= lowerValue && carPrice <= upperValue) &&
          (carYear >= minYear && carYear <= maxYear) &&
          (carKm >= minKm && carKm <= maxKm) &&
          (selectedColors.contains('Any') ||
              selectedColors.contains(car.color)) &&
          (selectedTransmissions.contains('Any') ||
              selectedTransmissions.contains(car.transmission)) &&
          (selectedFuelTypes.contains('Any') ||
              selectedFuelTypes.contains(car.fuelType)) &&
          (selectedBodyTypes.contains('Any') ||
              selectedBodyTypes.contains(car.bodyType));
    });

    for (var car in filteredCars) {
      if (car.makesList != null) {
        for (var make in car.makesList!) {
          final makeMap = make as Map<String, dynamic>;
          final makeName = makeMap['name']?.toString();
          final makeNameLower = makeName?.toLowerCase();

          if (makeName != null && makeName.isNotEmpty) {
            uniqueMakeNames.add(makeName);
          }

          final isSelectedMake = selectedMakeLower.isEmpty ||
              selectedMakeLower.contains(makeNameLower);

          if (isSelectedMake && makeMap['children'] is List) {
            for (var model in makeMap['children']) {
              final modelName = model['name']?.toString();
              if (modelName != null && modelName.isNotEmpty) {
                uniqueModelNames.add(modelName);
              }
            }
          }
        }
      }

      if (car.modelsListD != null && selectedMakeLower.isEmpty) {
        for (var model in car.modelsListD!) {
          final modelName = model.toString();
          if (modelName.isNotEmpty) {
            uniqueModelNames.add(modelName);
          }
        }
      }
    }

    availableMakes = [
      CarMakeModel(name: 'Any', children: []),
      ...makesList.where((m) => uniqueMakeNames.contains(m.name)).toList()
        ..sort((a, b) => a.name!.compareTo(b.name!))
    ];

    availableModels = ['Any', ...uniqueModelNames.toList()..sort()];

    final hasValidMakes = availableMakes.length > 1;
    final hasValidModels = availableModels.length > 1;
    // print("hasValidModels $hasValidModels");

    return hasValidMakes || hasValidModels;
  }

  bool carHasSelectedMake(CarListing car) {
    if (selectedMakes.contains('Any')) return true;
    if (car.makesList != null) {
      for (var make in car.makesList!) {
        final makeMap = make as Map<String, dynamic>;
        final makeName = makeMap['name']?.toString()?.toLowerCase();
        if (makeName != null &&
            selectedMakes.map((m) => m.toLowerCase()).contains(makeName)) {
          return true;
        }
      }
    }
    return false;
  }

  bool carHasSelectedModel(CarListing car) {
    // if (selectedModels.contains('Any')) return true;
    final selectedModelLower =
    selectedModels.map((m) => m.toLowerCase()).toSet();

    if (car.makesList != null) {
      for (var make in car.makesList!) {
        final makeMap = make as Map<String, dynamic>;
        if (makeMap['children'] is List) {
          for (var model in makeMap['children']) {
            final modelName = model['name']?.toString()?.toLowerCase();
            if (modelName != null && selectedModelLower.contains(modelName)) {
              return true;
            }
          }
        }
      }
    }

    if (car.modelsListD != null) {
      for (var model in car.modelsListD!) {
        if (model.toString().isNotEmpty &&
            selectedModelLower.contains(model.toString().toLowerCase())) {
          return true;
        }
      }
    }

    return false;
  }

  Future<void> resetFilters({bool fromBackBtn = false, int fromBack = 0}) async {
    debugPrint("Reset Filters started.");

    // 1. Quick synchronous state reset so UI reflects immediately
    isLoadingFilter = true;

    selectedBodyTypes = {'Any'};
    selectedFuelTypes = {'Any'};
    selectedColors = {'Any'};
    selectedMakes = ['Any'];
    selectedModels = ['Any'];
    _selectedBrand = [carMake];
    selectedTransmissions = {'Any'};

    availableBodyTypes.clear();
    availableFuelTypes.clear();
    availableColors.clear();
    availableMakes = [carMake];
    availableModels.clear();
    selectedMake = null;
    selectedModel = null;

    lowerValue = 200000;
    upperValue = 25000000;
    minKm = 0;
    maxKm = 500000;
    minYear = 1980;
    maxYear = 2025;

    _filterBrandSlug = null;
    brandSlugSelected = null;
    authorId = null;
    listingId = null;
    moreFromThisCarDetail = null;
    mightFromThisCarDetail = null;

    // Reflect cleared state immediately
    notifyListeners();

    // 2. Yield to UI before doing heavier restoration
    await Future.delayed(Duration.zero);

    // Restore base filtered data from cache if available (cheap reference if immutability not required)
    if (_cachedOriginalForFilter != null) {
      // If you need isolation later, you can clone; otherwise direct reference is faster.
      forFilterData = List.from(_cachedOriginalForFilter!);
      forFilterDataTemp = List.from(_cachedOriginalForFilter!);
      debugPrint("forFilterData restored from cache.");
    }

    // Restore filter taxonomy options from cache if available (no network)
    if (_cachedFilterTaxonomies != null) {
      final taxonomies = _cachedFilterTaxonomies!['taxonomies'] ?? {};
      fuelTypeList = ['Any', ..._extractNames(taxonomies['listivo_5667'])];
      transmissionList = ['Any', ..._extractNames(taxonomies['listivo_5666'])];
      bodyTypeList = ['Any', ..._extractNames(taxonomies['listivo_9312'])];
      modelsList = ['Any', ..._extractNames(taxonomies['listivo_946'])];
      makesList = [
        CarMakeModel(name: "Any", children: [CarBrandModel(name: 'Any')]),
        ..._extractMakeData(taxonomies['listivo_945'])
      ];
      colors = {
        for (var e in (taxonomies['listivo_8638'] ?? []))
          e['name']: mapThaiColorToColor(e['name']),
      };
      isFiltersLoaded = true;
      debugPrint("Filter options restored from cache.");
    }

    await Future.delayed(Duration.zero);
    // 3. Recompute dependent derived options once (non-blocking since already yielded)
    await updateAvailableOptions(filteredCars: forFilterData);

    // 4. Optionally fetch fresh car listings (preserving previous behavior)
    if (!fromBackBtn && fromBack != 0) {
      await fetchCarListings(forceRefresh: true);
    }

    // Finalize
    isLoadingFilter = false;
    notifyListeners();
    debugPrint("Reset Filters completed.");
  }

  CarMakeModel carMake =
  CarMakeModel(name: 'Any', children: [CarBrandModel(name: 'Any')]);

  String formatter(String value) {
    return value.replaceAll(RegExp(r'[^0-9]'), '');
  }

  checkUpperRange(List<CarListing> filteredCars) {
    availableMakes.sort((a, b) => a.name!.compareTo(b.name!));
    availableModels.sort((a, b) => a.compareTo(b));
    if (lowerValue == 50000 && upperValue == 25000000) {
      final prices = filteredCars
          .map((car) => double.parse(
          car.price.toString().replaceAll('฿', '').replaceAll(',', '')))
          .toList();
      final minP = prices.reduce((a, b) => a < b ? a : b);
      final maxP = prices.reduce((a, b) => a > b ? a : b);

      // lowerValue = minP;
      // upperValue = maxP;
    }
    if (minKm == 0 && maxKm == 1000000) {
      final mileages = filteredCars.map((car) {
        final mileageStr =
        car.mileage.toString().replaceAll(RegExp(r'[^0-9]'), '');
        return int.tryParse(mileageStr) ?? 0;
      }).toList();

      // minKm = mileages.reduce((a, b) => a < b ? a : b);
      // maxKm = mileages.reduce((a, b) => a > b ? a : b);
    }
    if (minYear == 1988 && maxYear == DateTime.now().year) {
      final years = filteredCars.map((car) => int.parse(car.year)).toList();
      // minYear = years.reduce((a, b) => a < b ? a : b);
      // maxYear = years.reduce((a, b) => a > b ? a : b);
    }
    notifyListeners();
  }
  ////------------------ Google map code
  bool showMap = false;
  void toggleMapVisibility() {
    showMap = !showMap;
    notifyListeners();
  }
/*GoogleMapController? mapController;
  Set<Marker> markers = {};
  bool isMapReady = false;

  // Initial camera position
  final CameraPosition initialPosition = const CameraPosition(
    target: LatLng(13.7563, 100.5018), // Bangkok coordinates
    zoom: 11,
  );

  void onMapCreated(GoogleMapController controller) {
    mapController = controller;
    isMapReady = true;
    notifyListeners();
  }*/
}
