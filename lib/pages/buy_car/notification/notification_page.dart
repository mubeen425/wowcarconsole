// import 'package:fl_carmax/helper/column_builder.dart';
// import 'package:fl_carmax/utils/constant.dart';
// import 'package:flutter/material.dart';
// import 'package:sizer/sizer.dart';

// import '../../../helper/language_constant.dart';
// import '../../../utils/widgets.dart';

// class NotificationPage extends StatefulWidget {
//   const NotificationPage({Key? key}) : super(key: key);

//   @override
//   State<NotificationPage> createState() => _NotificationPageState();
// }

// List _notificationList = [
//   {
//     'type': 'Today',
//     'data': [
//       {
//         'title':
//             'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Libero mattis a netus morbi egestas ultrices ultrices sed.',
//         'subtitle': '2 min ago'
//       },
//       {
//         'title':
//             'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Libero mattis a netus morbi egestas ultrices ultrices sed.',
//         'subtitle': '5 min ago'
//       },
//     ]
//   },
//   {
//     'type': 'Yesterday',
//     'data': [
//       {
//         'title':
//             'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Libero mattis a netus morbi egestas ultrices ultrices sed. ',
//         'subtitle': 'Yesterday'
//       },
//       {
//         'title':
//             'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Libero mattis a netus morbi egestas ultrices ultrices sed.  ',
//         'subtitle': 'Yesterday'
//       },
//       {
//         'title':
//             'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Libero mattis a netus morbi egestas ultrices ultrices sed.   ',
//         'subtitle': 'Yesterday'
//       },
//     ]
//   },
// ];

// class _NotificationPageState extends State<NotificationPage> {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: appBarMethod(context),
//       body: _notificationList.isNotEmpty
//           ? filledNotificationScreen()
//           : emptyNotificationScreen(),
//     );
//   }

//   ListView filledNotificationScreen() {
//     return ListView.builder(
//       physics: const BouncingScrollPhysics(),
//       padding: EdgeInsets.zero,
//       itemCount: _notificationList.length,
//       itemBuilder: (BuildContext context, int index) {
//         final item = _notificationList[index];
//         return Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Padding(
//               padding: item['data'].isNotEmpty
//                   ? const EdgeInsets.symmetric(horizontal: 20)
//                       .copyWith(top: 20, bottom: 15)
//                   : EdgeInsets.zero,
//               child: _notificationList[index]['data'].isNotEmpty
//                   ? Text(
//                       item['type'] == 'Today'
//                           ? translation(context).today
//                           : translation(context).yesterDay,
//                       style: blackSemiBold16)
//                   : null,
//             ),
//             ColumnBuilder(
//               itemCount: item['data'].length,
//               itemBuilder: (context, index) {
//                 final dataItem = item['data'][index];
//                 return Dismissible(
//                   key: Key('$dataItem'),
//                   background: Container(
//                     margin: const EdgeInsets.only(bottom: 20),
//                     //color: Colors.red,
//                     color: Color(0xff212121),
//                   ),
//                   onDismissed: (direction) {
//                     setState(() {
//                       item['data'].removeAt(index);
//                     });
//                     if (_notificationList[0]['data'].isEmpty &&
//                         _notificationList[1]['data'].isEmpty) {
//                       setState(() {
//                         _notificationList.clear();
//                       });
//                     }
//                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//                         backgroundColor: primaryColor,
//                         duration: const Duration(seconds: 1),
//                         content: Text(
//                           translation(context).notificationRemoved,
//                           style: whiteMedium14,
//                         )));
//                   },
//                   child: PrimaryContainer(
//                     margin: const EdgeInsets.symmetric(horizontal: 20)
//                         .copyWith(bottom: 20),
//                     padding: const EdgeInsets.fromLTRB(14, 11, 13, 11),
//                     child: Row(children: [
//                       Container(
//                         padding: const EdgeInsets.all(10),
//                         height: 5.h,
//                         width: 5.h,
//                         decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: primaryColor,
//                             boxShadow: [myBoxShadow]),
//                         child: Image.asset(notificationLable),
//                       ),
//                       widthSpace10,
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Text(
//                                 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Libero mattis a netus morbi egestas ultrices ultrices sed.',
//                                 style: blackRegular14),
//                             heightSpace3,
//                             Text('2 min ago', style: colorA6Regular14)
//                           ],
//                         ),
//                       )
//                     ]),
//                   ),
//                 );
//               },
//             )
//           ],
//         );
//       },
//     );
//   }

//   PreferredSize appBarMethod(BuildContext context) {
//     return PreferredSize(
//       preferredSize: const Size.fromHeight(56),
//       child: CustomAppBar(
//         title: translation(context).notification,
//       ),
//     );
//   }

import 'package:fl_carmax/bottom_nav_provider.dart';
import 'package:fl_carmax/pages/buy_car/notification/model/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:sizer/sizer.dart';

import '../../../helper/column_builder.dart';
import '../../../helper/language_constant.dart';
import '../../../utils/constant.dart';
import '../../../utils/widgets.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({Key? key}) : super(key: key);

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<Map<String, dynamic>> _notificationList = [];

  @override
  void initState() {
    super.initState();
    // loadNotifications();
  }
  Future<void>getLocalNotification()async{}

/*  Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getStringList('notifications') ?? [];

    final List<Map<String, dynamic>> todayList = [];
    final List<Map<String, dynamic>> yesterdayList = [];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var jsonStr in data) {
      final item = jsonDecode(jsonStr);
      final timestamp = DateTime.parse(item['timestamp']);
      final notificationDate = DateTime(timestamp.year, timestamp.month, timestamp.day);
      final diff = today.difference(notificationDate).inDays;

      final formattedTime = diff == 0
          ? '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}'
          : 'Yesterday';

      final map = {
        'title': item['title'],
        'subtitle': formattedTime,
      };

      if (diff == 0) {
        todayList.add(map);
      } else if (diff == 1) {
        yesterdayList.add(map);
      }
    }

    setState(() {
      _notificationList = [
        if (todayList.isNotEmpty) {'type': 'Today', 'data': todayList},
        if (yesterdayList.isNotEmpty) {'type': 'Yesterday', 'data': yesterdayList},
      ];
    });
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBarMethod(context),
      body: Consumer<BottomNavProvider>(
          builder: (context, provider, child) {
            return provider.messagesList?.isEmpty == true
                ? emptyNotificationScreen()
                : filledNotificationScreen(provider);
          },
        ));
  }
  // emptyNotificationScreen():

  ListView filledNotificationScreen(BottomNavProvider prov) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: 1,
      // itemCount: _notificationList.length,
      itemBuilder: (BuildContext context, int index) {
        // final item = _notificationList[index];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

           const SizedBox(height: 20,),
            ColumnBuilder(
              itemCount: prov.messagesList?.length,
              // itemCount: item['data'].length,
              itemBuilder: (context, index) {
               MessageDatum item = prov.messagesList![index];
                return item.is_deleted == 1 ? const SizedBox.shrink() : PrimaryContainer(
                  margin: const EdgeInsets.symmetric(horizontal: 20).copyWith(bottom: 20),
                  padding: const EdgeInsets.fromLTRB(14, 16, 13, 16),
                  child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      height: 5.h,
                      width: 5.h,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                        boxShadow: [myBoxShadow],
                      ),
                      child: Image.asset(notificationLable),
                    ),
                    widthSpace10,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Flexible(
                                  fit: FlexFit.loose,
                                  child: Text(item.message??"", style: blackRegular14,)),
                              //delete Icon
                            IconButton(
                              icon:  Icon(Icons.delete, color: colorD8, size: 20),
                              style: IconButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                              ),
                              padding: EdgeInsets.zero,
                              alignment: Alignment.topRight,
                              onPressed: () async {
                                final messageId = int.tryParse(item.id ?? '') ?? -1;
                                if (messageId == -1) return;

                                // Show loading snackbar
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: primaryColor,
                                      duration: const Duration(seconds: 2),
                                      content: Row(
                                        children: [
                                          const SizedBox(
                                            height: 18,
                                            width: 18,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(translation(context).deletingNotification),
                                        ],
                                      ),
                                    ),
                                  );
                                }

                                // Perform deletion
                                final success = await Provider.of<BottomNavProvider>(context, listen: false)
                                    .deleteMessage(messageId);

                                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                                if (success && context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: primaryColor,
                                      content: Text(
                                        translation(context).notificationRemoved,
                                        style: whiteMedium14,
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );

                                  setState(() {}); // Refresh UI
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: Colors.red,
                                      content: Text(
                                        translation(context).deletionFailed,
                                        style: whiteMedium14,
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                            ),
                            ],
                          ),

                        Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              _formatDate(item.createdDate?.toString() ?? ""), // Ensure it's a string before passing
                              style: primaryMedium12,
                            ),

                          ),
                        ),
                        ],
                      ),
                    )
                  ]),
                );

              },
            )
          ],
        );
      },
    );
  }
// Method to format the date and time
  String _formatDate(String dateStr) {
    try {
      // Parse the date string into a DateTime object
      DateTime date = DateTime.parse(dateStr);

      // Format the date and time using intl package
      return DateFormat('yyyy-MM-dd HH:mm').format(date); // Adjust format as needed
    } catch (e) {
      return 'Invalid date';
    }
  }

  PreferredSize appBarMethod(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(56),
      child: CustomAppBar(
        title: translation(context).notification,
      ),
    );
  }

  Widget emptyNotificationScreen() {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              emptyNotification,
              height: 4.2.h,
            ),
            heightSpace10,
            Text(translation(context).emptyNotificationMsg, style: colorA6SemiBold16),
          ],
        ),
      ),
    );
  }
}