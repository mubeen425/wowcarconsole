import 'package:fl_carmax/utils/constant.dart';
import 'package:fl_carmax/utils/widgets.dart';

import '../../../common_libs.dart';
import '../../../helper/language_constant.dart';
import '../../../main.dart';
import '../../../models/language.dart';
import '../../buy_car/provider/home_provider.dart';

class LanguagePage extends StatefulWidget {
  const LanguagePage({Key? key}) : super(key: key);

  @override
  State<LanguagePage> createState() => _LanguagePageState();
}

List<Language> languageList() {
  return <Language>[
    //   Language('English', 'en'),
    //  Language('Thai', 'hi'),
    //   Language('Bahasa', 'id'),
    //   Language('Chinese', 'zh'),
    //   Language('Arabic', 'ar'),
    Language('English', 'en'),
    Language('Arabic', 'ar'),
  //  Language('Bahasa', 'id'),
    Language('Chinese', 'zh'),
    Language('Thai', 'hi'),
   // Language('Turkish', 'tr')
  ];
}

class _LanguagePageState extends State<LanguagePage> {
  var selectedIndex = 4;
  late Language selectedLanguage = Language('Thai', 'hi');

  @override
  void initState() {
    _asyncMethod();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarMethod(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Column(
                  children: languageList()
                      .map((e) => PrimaryContainer(
                            onTap: () async {
                              setState(() {
                                selectedLanguage = e;
                              });
                            },
                            margin: const EdgeInsets.only(bottom: 20),
                            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 19),
                            child: Row(
                              children: [
                                Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 2.4.h,
                                      width: 2.4.h,
                                      decoration: BoxDecoration(
                                        color: selectedLanguage.name == e.name
                                            ? primaryColor
                                            : white,
                                        shape: BoxShape.circle,
                                        boxShadow:
                                            selectedLanguage.name == e.name
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
                                Text(e.name, style: blackMedium16),
                              ],
                            ),
                          ))
                      .toList()),
              heightSpace60,
              PrimaryButton(
                title: translation(context).update,
                onTap: () async {
                  // Step 1: Save the selected language to SharedPreferences
                  SharedPreferences prefs = await SharedPreferences.getInstance();
                  await prefs.setString(laguageCode, selectedLanguage.languageCode);  // Save selected language code to SharedPreferences

                  // Step 2: Set the new Locale for the app
                  Locale locale = await setLocale(selectedLanguage.languageCode);  // Get Locale based on selected language
                  if (!mounted) return;
                  MyApp.setLocale(context, locale);  // Update the app's locale globally

                  // Step 3: Notify HomeProvider to reload the saved language
                  context.read<HomeProvider>().loadSavedLanguage();  // Reload language from SharedPreferences in HomeProvider

                  // Step 4: Close the language selection page
                  Navigator.pop(context);  // Close the language selection dialog/page
                },
              )

            ],
          ),
        ),
      ),
    );
  }

  PreferredSize appBarMethod() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: CustomAppBar(title: translation(context).profileItem4),
    );
  }

  Future _asyncMethod() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String languageCode = prefs.getString(laguageCode) ?? hindi;
    setState(() {

      selectedLanguage = languageList().firstWhere(
            (lang) => lang.languageCode == languageCode,
        orElse: () => Language('hindi', 'hi'),
      );

    });
  }
}
