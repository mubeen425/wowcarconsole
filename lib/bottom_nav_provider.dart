

import 'dart:convert';

import 'package:fl_carmax/helper/language_constant.dart';
import 'package:fl_carmax/pages/account/account.dart';
import 'package:fl_carmax/pages/buy_car/notification/model/notification_model.dart';
import 'package:fl_carmax/sell_car_screen.dart';
import 'package:fl_carmax/utils/constant.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'bindings/pages_lib.dart';

class BottomNavProvider extends ChangeNotifier {
  int _currentIndex = 0;
  List<MessageDatum>? messagesList = [];
  Set<int> deletedMessageIds = {};

  int get currentIndx => _currentIndex;

  final List<Widget> widgetOptions = <Widget>[
    const BuyCar(),
    const SellCarScreen(),
    // const ComparePage(
    //   showBackButton: false,
    // ),
    const FavouritePage(showAppBar: false,),
    const Account(),
  ];

  void setCurrentIndex(int index) {
    _currentIndex = index;
    notifyListeners();
  }

  goToFirstTab(){
    _currentIndex = 0;
    notifyListeners();
  }
  String? userName;
  Future<void> getUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
      userName = prefs.getString('username');
      notifyListeners();
  }

  DateTime? currentBackPressTime;
  bool onWillPopAction(BuildContext context) {
    DateTime now = DateTime.now();
    if (currentBackPressTime == null ||
        now.difference(currentBackPressTime!) > const Duration(seconds: 2)) {
      currentBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: primaryColor,
        content:
        Text(translation(context).pressBackAgain, style: whiteMedium14),
        duration: const Duration(seconds: 1),
      ));
      return false;
    } else {
      return true;
    }
  }
  int? userId;
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
  String selectedLanguage = 'hi';
  Future<void> loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLangCode = prefs.getString(laguageCode) ?? 'en';

    // Reverse lookup: get the key (visible name) by value (lang code)
    final matchingEntry = languages.entries.firstWhere(
          (entry) => entry.value == savedLangCode,
      orElse: () => const MapEntry('Thai', 'hi'),
    );

    selectedLanguage = matchingEntry.value;
    notifyListeners();
  }
  //get the notification message
  Future<void> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt('user_id');

    // Load the deleted message IDs from SharedPreferences
    final deletedIds = prefs.getStringList('deleted_messages') ?? [];
    deletedMessageIds = deletedIds.map((e) => int.tryParse(e) ?? -1).toSet(); // Ensures proper parsing
  }
//get the notification message
  Future<void> getNotificationMessage() async {
    await loadSavedLanguage();
    await getUserId(); // Ensure the user and deleted message IDs are loaded

    try {
      if (userId != null) {
        final response = await http.get(
          Uri.parse("https://wowcar.co.th/wp-json/app-announcement-v2/v1/messages?user_id=$userId&lang=$selectedLanguage"),
        );

        if (response.statusCode == 200) {
          var messageData = notificationModelFromJson(response.body);
          final prefs = await SharedPreferences.getInstance();

          // Filter out deleted messages
          messagesList = messageData.messages?.where(
                  (message) => !deletedMessageIds.contains(int.tryParse(message.id ?? '') ?? -1)
          ).toList();

          // Save messages to local storage
          await prefs.setString('saved_messages', json.encode(messageData.toJson()));
          notifyListeners();
        } else {
          throw Exception('Failed to load notifications');
        }
      }
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    }
  }

  // Add this method to BottomNavProvider class
  String getTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';

    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '${weeks}w ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '${months}mo ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '${years}y ago';
    }
  }


  Future<bool> deleteMessage(int messageId) async {
  final success = await deleteNotificationFromServer(messageId);
  return success; // ✅ Must return this to avoid the 'void' error

  if (success) {
    final prefs = await SharedPreferences.getInstance();

    // Add the deleted message ID to the set
    deletedMessageIds.add(messageId);

    // Save the updated set of deleted message IDs to SharedPreferences
    await prefs.setStringList(
      'deleted_messages',
      deletedMessageIds.map((id) => id.toString()).toList()
    );

    // Filter out the deleted messages from the message list
    messagesList = messagesList?.where(
      (message) => int.tryParse(message.id ?? '') != messageId
    ).toList();

    notifyListeners();
  }
}

  Future<bool> deleteNotificationFromServer(int notificationId) async {
    try {
      if (userId == null) await getUserId();

      final response = await http.post(
        Uri.parse('https://www.wowcar.co.th/wp-json/app-announcement-v2/v1/delete_notification'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'notification_id': notificationId,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        // Update the local state
        messagesList?.removeWhere(
          (message) => int.tryParse(message.id ?? '') == notificationId
        );

        // Add to deleted messages set
        deletedMessageIds.add(notificationId);

        // Save to SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setStringList(
          'deleted_messages',
          deletedMessageIds.map((id) => id.toString()).toList()
        );

        notifyListeners();
        return true;
      } else {
        debugPrint('Failed to delete notification: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }


}