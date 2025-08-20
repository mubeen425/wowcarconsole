

import 'dart:convert';

import 'package:fl_carmax/bottom_nav_provider.dart'; // Import the BottomNavProvider
import 'package:fl_carmax/bottom_navigation.dart';
import 'package:fl_carmax/pages/auth/register_page.dart';
import 'package:fl_carmax/utils/constant.dart';
import 'package:fl_carmax/utils/widgets.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart'; // ✅ added
import 'package:sizer/sizer.dart';

import '../../helper/language_constant.dart';

class LoginPageEmail extends StatefulWidget {
  const LoginPageEmail({Key? key}) : super(key: key);

  @override
  State<LoginPageEmail> createState() => _LoginPageEmailState();
}

class _LoginPageEmailState extends State<LoginPageEmail> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  String accountType = 'Private Seller';
  Future<void> loginUser() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email and password are required')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final url = Uri.parse('https://www.wowcar.co.th/wp-json/listivo/v1/login/');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': email,
          'password': password,
        }),
      );

      debugPrint("STATUS CODE: ${response.statusCode}");
     // debugPrint("RESPONSE: ${response.body}");

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        final user = responseData['user'];
        final meta = user['meta'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('user_id', user['ID']);
        await prefs.setString('username', user['username'] ?? '');
        await prefs.setString('email', user['email'] ?? '');
        await prefs.setString('display_name', user['display_name'] ?? '');
        await prefs.setString('first_name', meta['first_name'] ?? '');
        await prefs.setString('last_name', meta['last_name'] ?? '');
        await prefs.setString('nickname', meta['nickname'] ?? '');
        await prefs.setString('phone', meta['phone'] ?? '');
        await prefs.setString('phone_country_code', meta['phone_country_code'] ?? '');
        await prefs.setString('account_type', meta['account_type'] ?? '');
// After a successful login, reload the notifications
        await Provider.of<BottomNavProvider>(context, listen: false).getNotificationMessage();

       /* if(context.mounted){
          notificationService.initialize(context);
        }
        await notificationService.showWelcomeNotification();*/
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    translation(context).onBoardTitle1,  // Translate the "Welcome to WowCar"
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    translation(context).thankYouMessage,  // Translate the "Thank you for logging into WowCar."
                  ),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: primaryColor,
              duration: Duration(seconds: 3),
            ),

          );
        }
        if(context.mounted){
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const BottomNavigation()),
          );

        }

        // NotificationService notificationService = NotificationService();
        //       final deviceToken = await notificationService.getDeviceToken();
        //       debugPrint('Device Token: $deviceToken');

        // List<String> notifications = prefs.getStringList('notifications') ?? [];
        //       // Send welcome notification
        //       await SendNotificationService.sendNotificationUsingApi(
        //         token: deviceToken,
        //         title: 'Welcome to WowCar',
        //         body: 'Thank you for logging into WowCar.',
        //         data: {},
        //       );
        //         notifications.add(jsonEncode({
        //           'title': 'Welcome to WowCar',
        //           'body': 'Thanks for logging on WowCar!',
        //           'timestamp': DateTime.now().toIso8601String(),
        //         }));

               // await prefs.setStringList('notifications', notifications);
              //await saveNotificationLocally('Welcome to WowCar', 'Thank you for logging into WowCar.');
                // Navigate to bottom navigation screen

      } else {
        if(context.mounted){
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(responseData['message'] ?? 'Login failed')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }
Future<void> saveNotificationLocally(String title, String body) async {
  final prefs = await SharedPreferences.getInstance();
  final String key = 'notifications';
  final List<String> existing = prefs.getStringList(key) ?? [];

  final newNotification = jsonEncode({
    'title': title,
    'body': body,
    'timestamp': DateTime.now().toIso8601String(),
  });

  existing.add(newNotification);
  await prefs.setStringList(key, existing);
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    Center(
                      child: Column(
                        children: [
                          Image.asset(appLogo, height: 13.h),
                          heightSpace20,
                          heightSpace3,
                          Text(
                            translation(context).login,
                            style: primarySemiBold20,
                            textAlign: TextAlign.center,
                          ),
                          heightSpace10,
                          heightSpace2,
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 50),
                            child: Text(
                              translation(context).loginSubtitle,
                              style: color94Medium14,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          heightSpace40,
                          PrimaryTextField(
                            controller: emailController,
                            prefixIcon: mailIcon,
                            hintText: translation(context).enterYourEmailId,
                            keyboardType: TextInputType.emailAddress,
                          ),
                          heightSpace30,
                          PrimaryTextField(
                            controller: passwordController,
                            prefixIcon: 'assets/images/pass.png',
                            hintText: translation(context).enterpassword,
                            obscureText: true,
                          ),
                          heightSpace40,
                          PrimaryButton(
                            title: isLoading ? translation(context).loggingin : translation(context).login,
                            onTap: isLoading ? null : loginUser,
                          ),
                        ],
                      ),
                    ),
                    heightSpace20,
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                         Text(
                          translation(context).noaccount,
                          style: TextStyle(color: Colors.black),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => const RegisterPage()),
                            );
                          },
                          child: Text(translation(context).register,
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
