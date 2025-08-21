import 'package:fl_carmax/pages/buy_car/search/search_provider.dart';
import 'package:fl_carmax/pages/sell_car/mapScreeen/map_screen.dart';
import 'package:fl_carmax/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../helper/language_constant.dart';
import '../../../models/car_listing_model.dart';
import '../../../utils/constant.dart';
import '../compare_page/compare_controller.dart';
import '../compare_page/compare_page.dart';
import 'car_card_shimmer.dart';

class SearchPage extends StatefulWidget {
  final String? brandSlug;
  final bool? fromHomeFeatured;
  final String? listingId, authorId;
  final bool? moreFromSellerDetailPage;
  final bool? mightLikeThisDetailPage;
  final String? carMaker;
  final bool isMapScreen;
  final List<CarListing>? carsListFromMap;

  const SearchPage({
    Key? key,
    this.brandSlug,
    this.fromHomeFeatured,
    this.listingId,
    this.authorId,
    this.moreFromSellerDetailPage,
    this.mightLikeThisDetailPage,
    this.carMaker,
    this.isMapScreen=false,
    this.carsListFromMap,
  }) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final ScrollController _pageScrollController = ScrollController();
  late SearchProvider provider;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<SearchProvider>(context, listen: false);
    if (widget.isMapScreen == false) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _initializeSearch());
    } else {
      provider.showMap = false;
    }
  }

  Future<void> _initializeSearch() async {
    provider.resetForSearchPage();
    provider.setCarMakerAndBodyType(widget.carMaker);
    provider.getFeaturedStatusHome(widget.fromHomeFeatured);
    provider.moreFromThisSellerMethod(widget.moreFromSellerDetailPage ?? false);
    provider.mightFromThisSellerMethod(widget.mightLikeThisDetailPage ?? false);
    provider.getCarDAuthorListingId(widget.authorId ?? "0", widget.listingId ?? "0");
    if (widget.brandSlug != null) provider.getBrandSlug(widget.brandSlug);
    await provider.fetchCarListings(forceRefresh: true, brandSlug: widget.brandSlug);
  }

  void _scrollToSelectedPage(int pageNum) {
    double itemWidth = 40;
    double screenWidth = MediaQuery.of(context).size.width;
    double scrollPosition = (pageNum - 1) * itemWidth - (screenWidth / 2) + (itemWidth / 2);
    _pageScrollController.animateTo(
      scrollPosition.clamp(
        _pageScrollController.position.minScrollExtent,
        _pageScrollController.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Locale currentLocale = Localizations.localeOf(context);
    bool isArabic = currentLocale == const Locale('ar');

    return Consumer2<SearchProvider, CompareProvider>(
      builder: (context, provider, compareProvider, child) {
        return WillPopScope(
          onWillPop: () async {
            if(widget.isMapScreen == false) {
              provider.resetPage();
              provider.searchController.clear();
              await provider.resetFilters(fromBack: 0);
            }
            return true;
          },
          child: SafeArea(
            child: Scaffold(
              appBar: widget.isMapScreen == false ? _buildAppBar(isArabic, provider, compareProvider) : null,
              floatingActionButton: Visibility(
                visible: widget.isMapScreen == false,
                child: FloatingActionButton(
                  onPressed: provider.toggleMapVisibility,
                  backgroundColor: primaryColor,
                  child: Image.asset('assets/images/map_icon.png', height: 24, width: 24, color: Colors.white),
                ),
              ),
              floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
              body: provider.showMap
                  ? CarMapScreen(searchProvider: provider)
                  : RefreshIndicator(
                onRefresh: () => provider.isFilterApplied
                    ? provider.applyFiltersFromApi(provider.filterSheet ?? {}, forceRefresh: true)
                    : provider.fetchCarListings(forceRefresh: true, brandSlug: widget.brandSlug),
                child: Column(
                  children: [
                    if(widget.isMapScreen == false)
                      _buildPagination(provider),
                    Expanded(
                      child: provider.isLoading || provider.isSearching
                          ? ListView.builder(
                        itemCount: 6,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15).copyWith(bottom: 20),
                        itemBuilder: (_, __) => const CarCardShimmer(),
                      )
                          : _buildBody(provider, compareProvider),
                    ),
                  ],
                ),
              ),
              bottomNavigationBar: compareProvider.compareList.isNotEmpty ? _buildCompareBar(compareProvider) : null,
            ),
          ),
        );
      },
    );
  }

  PreferredSize _buildAppBar(bool isArabic, SearchProvider provider, CompareProvider compareProvider) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(120),
      child: AppBar(
        elevation: 3,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.light,
          statusBarColor: primaryColor,
        ),
        automaticallyImplyLeading: false,
        shadowColor: colorForShadow.withOpacity(.25),
        backgroundColor: white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: black),
          onPressed: () async {
            Navigator.pop(context);
            provider.resetPage();
            provider.searchController.clear();
            await provider.resetFilters(fromBack: 0);
          },
        ),
        title: Text(translation(context).search, style: blackSemiBold16),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onTap: () => provider.showSortBySheet(context),
              child: Row(
                children: [
                  Text(translation(context).sortBy1, style: primaryMedium14),
                  Image.asset(sortBy, height: 18, color: primaryColor),
                ],
              ),
            ),
          ),
        ],
        flexibleSpace: Align(
          alignment: Alignment.bottomLeft,
          child: Padding(
            padding: isArabic
                ? const EdgeInsets.only(right: 20,left: 20, bottom: 10)
                : const EdgeInsets.only(left: 20,right: 20, bottom: 10),
            child: _buildSearchField(provider),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField(SearchProvider provider) {
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 9.5),
            decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(8), boxShadow: [myBoxShadow]),
            child: Row(
              children: [
                Icon(Icons.search, color: colorA6),
                widthSpace10,
                Expanded(
                  child: TextField(
                    controller: provider.searchController,
                    onChanged: provider.filterBySearch,
                    cursorColor: primaryColor,
                    style: colorA6SemiBold14,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: translation(context).searchYourCar,
                      hintStyle: colorA6SemiBold14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        widthSpace10,
        PrimaryContainer(
          onTap: () => provider.showFilterSheet(context),
          borderRadius: BorderRadius.circular(5),
          border: Border.all(color: primaryColor),
          padding: const EdgeInsets.all(10),
          width: MediaQuery.of(context).size.width * 0.30,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(filter, height: 22, color: primaryColor),
              SizedBox(width: MediaQuery.of(context).size.width * 0.02),
              const Text("Filter",style: TextStyle(color: primaryColor)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompareBar(CompareProvider compareProvider) {
    return Container(
      color: white,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              "${compareProvider.compareList.length} ${compareProvider.compareList.length == 1 ? "car" : "cars"} selected for comparison",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ComparePage())),
            icon: const Icon(Icons.compare_arrows, color: Colors.white),
            label: Text("Compare", style: whiteMedium14),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SearchProvider provider, CompareProvider compareProvider) {
    final usingSearch = provider.searchController.text.isNotEmpty;
    final currentList = usingSearch ? provider.searchCarList : provider.apiCarList;

    if (currentList.isEmpty) return _buildNoResultWidget();

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: widget.isMapScreen?widget.carsListFromMap?.length:currentList.length + ((provider.isLoadingMore || provider.hasMoreData) ? 1 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            itemBuilder: (context, index) {
              if (index >= currentList.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Center(
                    child: provider.isLoadingMore
                        ? const CircularProgressIndicator(color: Colors.orange)
                        : const Text(""),
                  ),
                );
              }
              final item = widget.isMapScreen ? widget.carsListFromMap![index] : currentList[index];
              return CarCardWidget(
                id: item.id,
                imageUrls: (item.imageUrls ?? []).cast<String>().take(5).toList(),
                title: item.title,
                price: item.price,
                year: item.year,
                mileage: "${item.mileage} km",
                fuelType: item.fuelType,
                transmission: item.transmission,
                bodyType: item.bodyType,
                engineCapacity: item.engineCapacity,
                views: "${item.metaD?["views"] ?? "153"}",
                isFavourite: provider.favouriteIds.contains(int.parse(item.id)),
                onCompareTap: () => provider.toggleCompare(context, item),
                isInCompareList: compareProvider.isInCompare(item),
                onFavouriteToggle: () async => provider.handleFavouriteToggle(item, context, mounted, context),
                isFeatured: item.isFeatured,
                carTag: item.carTag,
                modeListD: const [],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPagination(SearchProvider provider) {
    return SizedBox(
      height: 60,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: primaryColor),
            onPressed: () {
              if (provider.currentPage > 1)   provider.previousPage(widget.brandSlug, filters: provider.filterSheet);
              _scrollToSelectedPage(provider.currentPage);
            },
          ),
          Expanded(
            child: Center( // 👈 key change
            child: ListView.builder(
              controller: _pageScrollController,
              scrollDirection: Axis.horizontal,
              shrinkWrap: true, // 👈 ensures list takes only needed space
              itemCount: provider.totalPages,
              itemBuilder: (context, index) {
                final pageNum = index + 1;
                final isSelected = pageNum == provider.currentPage;
                return GestureDetector(
                  onTap: () => provider.goToPage(pageNum, widget.brandSlug, filters: provider.filterSheet),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? primaryColor : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(pageNum.toString(),
                        style: TextStyle(color: isSelected ? Colors.white : primaryColor, fontWeight: FontWeight.bold)),
                  ),
                );
              },
            ),
          ),
    ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: primaryColor),
            onPressed: () {
              if (provider.currentPage < provider.totalPages) provider.nextPage(widget.brandSlug, filters: provider.filterSheet);
              _scrollToSelectedPage(provider.currentPage);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultWidget() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.car_repair_outlined, size: 80, color: Colors.grey),
            SizedBox(height: 20),
            Text('No cars found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
            SizedBox(height: 8),
            Text('Try adjusting your filters', style: TextStyle(fontSize: 14, color: Colors.grey), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}


