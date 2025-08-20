import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../utils/constant.dart'; // for primaryColor, white, myBoxShadow, etc.
import '../../../helper/language_constant.dart';
import '../utils/constant.dart';

class SortBySheet extends StatefulWidget {
  final int initialIndex;
  const SortBySheet({Key? key, required this.initialIndex}) : super(key: key);

  @override
  State<SortBySheet> createState() => _SortBySheetState();
}

class _SortBySheetState extends State<SortBySheet> {
  late int _selectedSortBy;

  final List<String> _sortByItems = [
    'relevance',
    'recentlyAdded',
    'priceLowToHigh',
    'priceHighToLow',
    'kmDrivenLowToHigh',
    'kmDrivenHighToLow',
    'yearNewToOld',
    'yearOldToNew',
  ];

  @override
  void initState() {
    super.initState();
    _selectedSortBy = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant SortBySheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ensure the selected index updates when `initialIndex` changes
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _selectedSortBy = widget.initialIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Fetch translations dynamically based on context
    List<String> sortByItemsTranslated = _sortByItems.map((key) {
      switch (key) {
        case 'relevance':
          return translation(context).relevance;  // "Relevance"
        case 'recentlyAdded':
          return translation(context).recentlyAdded;  // "Recently Added"
        case 'priceLowToHigh':
          return translation(context).priceLowToHigh;  // "Price - Low to High"
        case 'priceHighToLow':
          return translation(context).priceHighToLow;  // "Price - High to Low"
        case 'kmDrivenLowToHigh':
          return translation(context).kmDrivenLowToHigh;  // "Km driven - Low to High"
        case 'kmDrivenHighToLow':
          return translation(context).kmDrivenHighToLow;  // "Km driven - High to Low"
        case 'yearNewToOld':
          return translation(context).yearNewToOld;  // "Year - New to Old"
        case 'yearOldToNew':
          return translation(context).yearOldToNew;  // "Year - Old to New"
        default:
          return ''; // Default case
      }
    }).toList();

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Title
          Container(
            padding: const EdgeInsets.symmetric(vertical: 23.5),
            decoration: BoxDecoration(
              color: white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              boxShadow: [myBoxShadow],
            ),
            child: Center(
              child: Text(
                translation(context).sortBy1, // "Sort By"
                style: blackMedium18,
              ),
            ),
          ),

          // Sort Options
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: List.generate(sortByItemsTranslated.length, (index) {
                    return ListTile(
                      onTap: () {
                        setState(() => _selectedSortBy = index);
                        Navigator.pop(context, index);
                      },
                      leading: Text(sortByItemsTranslated[index], style: blackRegular16),
                      trailing: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            height: 2.3.h,
                            width: 2.3.h,
                            decoration: BoxDecoration(
                              color: _selectedSortBy == index
                                  ? primaryColor
                                  : white,
                              shape: BoxShape.circle,
                              boxShadow: _selectedSortBy == index
                                  ? [myPrimaryShadow]
                                  : [myBoxShadow],
                            ),
                          ),
                          if (_selectedSortBy == index)
                            const CircleAvatar(
                              backgroundColor: white,
                              radius: 3,
                            )
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
