class CarDetailModel {
  final String id;
  final String title;
  final String? postDate;
  String sellerName;
  final String? videoUrl;
  final String content;
  final List<String> imageUrls;
  final List<CarDetailModel> relatedProducts;
  final String price;
  final String mileage;
  final String year;
  final String location;

  final String fuelType;
  final String transmission;
  final String engineCapacity;
  final String bodyType;
  final String drive;
  final String color;

  final List<String> offerTags;
  final String carTag;  // Declared carTag here
  final List<String> safetyFeatures;
  final List<String> comfortFeatures;

  final String referenceCode;
  final String make;
  final String modelGroup;
  final String modelVariant;
  final String doors;
  final List<CarDetailModel> relatedCategoryProducts;
  final String? sellerPhone;
  final String? sellerLinePage;
  final String? authorId;

  final String sellerDescription;
  final Map<String, dynamic>? metaD;
  final String? reviewTh;
  final String? reviewEn;
  final String? reviewZh;
  final String? reviewAr;

  CarDetailModel({
    required this.id,
    this.authorId,
    required this.title,
    required this.postDate,
    required this.content,
    required this.imageUrls,
    required this.relatedProducts,
    required this.price,
    required this.sellerName,
    required this.mileage,
    required this.year,
    required this.location,
    required this.fuelType,
    required this.transmission,
    required this.engineCapacity,
    required this.bodyType,
    required this.drive,
    required this.color,
    required this.carTag,  // Included carTag in the constructor
    required this.offerTags,
    required this.safetyFeatures,
    required this.comfortFeatures,
    required this.referenceCode,
    required this.make,
    required this.modelGroup,
    required this.modelVariant,
    required this.doors,
    required this.relatedCategoryProducts,
    this.sellerPhone,
    this.sellerLinePage,
    required this.sellerDescription,
    this.metaD,
    this.reviewTh,
    this.reviewEn,
    this.reviewZh,
    this.reviewAr,
    this.videoUrl,
  });

  factory CarDetailModel.fromJson(Map<String, dynamic> json) {
    final post = json['post'] ?? {};
    final meta = json['meta'] ?? {};
    final images = json['related_guids'] as List? ?? [];
    final taxonomies = json['taxonomies'] as Map<String, dynamic>? ?? {};

    // Helper function to extract taxonomy name
    String getTaxName(String key) {
      final list = taxonomies[key] as List?;
      if (list != null && list.isNotEmpty) {
        return list.first['name']?.toString() ?? '';
      }
      return '';
    }

    // Helper function to remove HTML tags
    String _parseHtmlString(String htmlString) {
      final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
      return htmlString.replaceAll(exp, '').trim();
    }

    // Extract related products from JSON
    List<CarDetailModel> extractRelatedProducts() {
      final list = json['related_products'] as List?;
      if (list != null) {
        return list.map((e) => CarDetailModel.fromJson(e)).toList();
      }
      return [];
    }

    // Extract related category products
    List<CarDetailModel> extractCategoryRelatedProducts() {
      final list = json['related_category_products'] as List?;
      if (list != null) {
        return list.map((e) => CarDetailModel.fromJson(e)).toList();
      }
      return [];
    }

    // Extract tags from JSON
    List<String> getTagList(String key) {
      final list = taxonomies[key] as List?;
      if (list != null) {
        return list.map((e) => e['name'].toString()).toList();
      }
      return [];
    }

    // Extract tags (carTag) from the taxonomies
    final tagList = taxonomies['listivo_12624'] as List?;
    final carTag = tagList != null && tagList.isNotEmpty
        ? tagList.first['name'] ?? ''
        : '';
    // Extract video URL from meta['listivo_345']
    String? videoUrl;
    if (meta['listivo_345'] != null && meta['listivo_345'] is Map) {
      videoUrl = meta['listivo_345']['url']?.toString();
    }


    return CarDetailModel(
      id: post['ID']?.toString() ?? '',
      authorId: post["post_author"] ?? '',
      postDate: post['post_date']?.toString() ?? '',
      sellerDescription: _parseHtmlString(post['post_content']?.toString() ?? ''),
      title: post['post_title']?.toString() ?? '',
      content: post['post_content']?.toString() ?? '',
      imageUrls: images.map((e) => e['guid']?.toString() ?? '').where((e) => e.isNotEmpty).toList(),
      relatedProducts: extractRelatedProducts(),
      price: meta['listivo_130_listivo_13']?.toString() ?? '',
      mileage: meta['listivo_4686']?.toString() ?? '',
      year: meta['listivo_4316']?.toString() ?? '',
      sellerName: meta['listivo_14049']?.toString() ?? '',
      location: meta['listivo_153_address']?.toString() ?? '',
      fuelType: getTaxName('listivo_5667'),
      transmission: getTaxName('listivo_5666'),
      engineCapacity: getTaxName('listivo_8733'),
      bodyType: getTaxName('listivo_9312'),
      drive: getTaxName('listivo_8731'),
      color: getTaxName('listivo_8638'),
      offerTags: getTagList('listivo_5664'),
      safetyFeatures: getTagList('listivo_4318'),
      comfortFeatures: getTagList('listivo_8755'),
      referenceCode: meta['listivo_8671']?.toString() ?? '',
      make: getTaxName('listivo_945'),
      modelGroup: getTaxName('listivo_946'),
      modelVariant: meta['listivo_13698']?.toString() ?? '',
      doors: getTaxName('listivo_9311'),
      relatedCategoryProducts: extractCategoryRelatedProducts(),
      sellerPhone: (json['author_contact']?['phone'] ?? '') as String?,
      sellerLinePage: meta['listivo_8739'] as String?,
      videoUrl: videoUrl,
      metaD: meta,
      reviewTh: meta['listivo_26901'] as String?,
      reviewEn: meta['listivo_26904'] as String?,
      reviewZh: meta['listivo_26910'] as String?,
      reviewAr: meta['listivo_26909'] as String?,
      carTag: carTag,  // Added carTag here

    );
  }
}
