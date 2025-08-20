import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String laguageCode = 'languageCode';

//languages code
const String english = 'en';
const String hindi = 'hi';
const String indonesian = 'id';
const String chinese = 'zh';
const String arabic = 'ar';
const String thai = 'hi';

Future<Locale> setLocale(String languageCode) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.setString(laguageCode, languageCode);
  return locale(languageCode);
}

Future<Locale> getLocale() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String languageCode = prefs.getString(laguageCode) ?? hindi;
  return locale(languageCode);
}
Future<String?> getApiLanguage() async {
  final prefs = await SharedPreferences.getInstance();
  String? languageCode = prefs.getString('languageCode') ?? "hi";
  debugPrint('------------------------- language code id $languageCode');
  String? apiLanguage;
  switch (languageCode) {
    case english:
      apiLanguage = 'english';
      break;
    case chinese:
      apiLanguage = 'chinese';
      break;
    case arabic:
      apiLanguage = 'arabic';
      break;
      case thai:
      apiLanguage = 'hi';
      break;
    default:
      apiLanguage = null;
  }
  print('------------------------- mapped api language $apiLanguage');
  return apiLanguage;
}

Locale locale(String languageCode) {
  switch (languageCode) {
    case english:
      return const Locale(english, "");
    case hindi:
      return const Locale(hindi, "");
    case indonesian:
      return const Locale(indonesian, "");
    case chinese:
      return const Locale(chinese, "");
    case arabic:
      return const Locale(arabic, "");
    case thai:
      return const Locale(thai, "");
    default:
      return const Locale(english, "");
  }
}

AppLocalizations translation(BuildContext context) =>
    AppLocalizations.of(context)!;