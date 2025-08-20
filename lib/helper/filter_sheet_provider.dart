

import 'dart:convert';

import 'package:fl_carmax/models/car_brand_with_model.dart';
import 'package:fl_carmax/models/car_listing_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FilterSheetProvider extends ChangeNotifier{
  FilterSheetProvider() {
    loadFilterOptions();
  }
  //price slider
  double priceSliderLowerValue = 400000;
  double priceSliderUpperValue = 2000000;
  //year
  int minYear = 2010;
  int maxYear = 2025;
  //millage
  int minKm = 50000;
  int maxKm = 150000;
  //body type
  List<String> availableBodyTypes = ['Any'];
  Set<String> selectedBodyTypes = {};
  List<String> bodyTypeList = ['Any'];

 setDraggingValue(dynamic lower, dynamic upper) {
   priceSliderLowerValue = lower.toDouble();
   priceSliderUpperValue = upper.toDouble();
   debugPrint("$priceSliderLowerValue");
   debugPrint("$priceSliderUpperValue");
   Future.delayed(const Duration(milliseconds: 200), () {
     filterPrice();
   });
   notifyListeners();
 }
 //year dragging values
  setDraggingValueForYears(min, max) {
    minYear = min;
    maxYear = max;
    notifyListeners();
  }
  //millage dragging values
  setDraggingValueForKMRange(min, max) {
    minKm = min.toInt();
    maxKm = max.toInt();
    debugPrint("filter minValue: $minKm");
    debugPrint("filter maxValue: $maxKm");

    notifyListeners();
  }
  List<CarMakeModel> availableMakes = [];
  CarMakeModel carMake = CarMakeModel(name: 'Any', children: [CarBrandModel(name: 'Any')]);
  List<String> selectedMakes = [];
  List<String> selectedModels = ['Any'];
  List<String> availableModels = ['Any'];
  List<CarMakeModel> _selectedBrand = [
    CarMakeModel(name: 'Any', children: [CarBrandModel(name: 'Any')])
  ];
  //body type
  void setBodyTypes(bool isSelected, String value) {
    if (value == 'Any') {
      selectedBodyTypes.clear();
      selectedBodyTypes.add('Any');

      // Reset available makes to ['Any'] when 'Any' is selected
      availableMakes = [carMake];
      selectedMakes = ['Any'];
      availableModels = ['Any'];
      selectedModels = ['Any'];
    } else {
      availableModels = ['Any'];
      selectedModels = ['Any'];
      _selectedBrand = [
        CarMakeModel(name: 'Any', children: [CarBrandModel(name: 'Any')])
      ];
      selectedBodyTypes.remove('Any');
      if (isSelected) {
        selectedBodyTypes.remove(value);
      } else {
        selectedBodyTypes.add(value);
      }
    }
    notifyListeners();
  }



  List<CarListing> forFilterData = [];
  filterPrice(){
    final filteredCars = forFilterData.where((car) {
      final priceStr =
      car.price.toString().replaceAll('฿', '').replaceAll(',', '');
      debugPrint("priceStr${car.title}$priceStr");
      final price = int.tryParse(priceStr) ?? 0;
      final year = int.tryParse(car.year) ?? 0;
      final mileageStr =
      car.mileage.toString().replaceAll(RegExp(r'[^0-9]'), '');
      final mileage = int.tryParse(mileageStr) ?? 0;
      debugPrint("IsMatch Price${price >= priceSliderLowerValue && price <= priceSliderUpperValue}${car.title}${car.mileage}Year${year >= minYear && year <= maxYear}KM${mileage >= minKm && mileage <= maxKm} ${car.carmodels} ${car.modelsType}");
      debugPrint(priceStr);

      return price >= priceSliderLowerValue &&
          price <= priceSliderUpperValue &&
          year >= minYear &&
          year <= maxYear &&
          mileage >= minKm &&
          mileage <= maxKm;
    }).toList();

    debugPrint("Filtered cars count: ${filteredCars.length}");
  }
  List<String> fuelTypeList = ['Any'];
  ///FilterSheet Functions
  List<String> _extractNames(List? items) {
    return items?.map((e) => e['name'].toString()).toList() ?? [];
  }

  List<CarMakeModel> _extractMakeData(List? items) {
    return items?.map((e) => CarMakeModel.fromJson(e)).toList() ?? [];
  }

  List<String> transmissionList = ['Any'];
  List<String> modelsList = ['Any'];
  List<CarMakeModel> makesList = [];
  Map<String, Color> colors = {};
  Set<String> selectedFuelTypes = {};
  //load the filters from the api
  void loadFilterOptions() async {
    final response =
    await getFilterOptionsFromApi(); // simulate or call real API
    final taxonomies = response['taxonomies'];

    fuelTypeList = ['Any', ..._extractNames(taxonomies['listivo_5667'])];
    transmissionList = ['Any', ..._extractNames(taxonomies['listivo_5666'])];
    bodyTypeList = ['Any', ..._extractNames(taxonomies['listivo_9312'])];
    debugPrint('Loaded bodyTypeList: $bodyTypeList');

    modelsList = ['Any', ..._extractNames(taxonomies['listivo_946'])];
    debugPrint(
        "Texonmie ++++++++++++++ ${taxonomies['listivo_945'].where((e) => e['name'] == 'Haval').toList()}");

    makesList = [
      CarMakeModel(name: "Any", children: [CarBrandModel(name: 'Any')]),
      ..._extractMakeData(taxonomies['listivo_945'])
    ];

    debugPrint("Update Make List$taxonomies");

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

    notifyListeners();
  }

  Color mapThaiColorToColor(String name) {
    switch (name) {
      case 'สีขาว':
        return Color(0xFFFFFFFF);
      case 'สีดำ':
        return Color(0xFF000000);
      case 'สีเงิน':
        return Color(0xFFC0C0C0);
      case 'สีชาร์โคล':
        return Color(0xFF36454F);
      case 'สีน้ำเงิน':
        return Color(0xFF0000FF);
      case 'สีแดง':
        return Color(0xFFFF0000);
      case 'สีเทา':
        return Color(0xFF808080);
      case 'สีบรอนซ์':
        return Color(0xFFCD7F32);
      case 'สีทอง':
        return Color(0xFFFFD700);
      default:
        return Color(0xFF000000); // Default to black if not found
    }
  }

  Future<Map<String, dynamic>> getFilterOptionsFromApi() async {
    final url = Uri.parse(
        'https://www.wowcar.co.th/wp-json/listivo/v1/all-listings-with-guids');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      if (responseData is Map && responseData['results'] is List) {
        final List<dynamic> listings = responseData['results'];

        if (listings.isNotEmpty) {
          final Map<String, List<Map<String, dynamic>>> mergedTaxonomies = {};

          for (final listing in listings) {
            final taxonomies = listing['taxonomies'] as Map<String, dynamic>?;

            if (taxonomies != null) {
              taxonomies.forEach((key, value) {
                final terms = value as List<dynamic>;
                if (!mergedTaxonomies.containsKey(key)) {
                  mergedTaxonomies[key] = [];
                }

                for (final term in terms) {
                  final existingIndex = mergedTaxonomies[key]!
                      .indexWhere((t) => t['term_id'] == term['term_id']);

                  if (existingIndex == -1) {
                    // No existing make, add new
                    mergedTaxonomies[key]!.add(term);
                  } else {
                    // Make exists, merge children uniquely
                    final existingMake = mergedTaxonomies[key]![existingIndex];

                    List existingChildren =
                        (existingMake['children'] as List<dynamic>?) ?? [];
                    List newChildren =
                        (term['children'] as List<dynamic>?) ?? [];

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

          return {'taxonomies': mergedTaxonomies};
        }
      }
    }

    return {'taxonomies': {}};
  }

  ///fetching thhe initial data

}
