import 'dart:convert';

import 'package:awesome_notification/main.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:awesome_notifications_fcm/awesome_notifications_fcm.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;

///  *********************************************
///     NOTIFICATION CONTROLLER
///  *********************************************
///
class NotificationController {
  static ReceivedAction? initialAction;

  /// *********************************************
  ///   INITIALIZATION METHODS
  /// *********************************************

  static Future<void> initializeLocalNotifications(
      {required bool debug}) async {
    final buzzerNotificationChannel = NotificationChannel(
      channelKey: 'buzzer_channel', // id
      channelName: 'Buzzer', // channel title
      channelDescription:
          'This channel is used for notifications Buzzer.', // description
      channelShowBadge: true,
      importance: NotificationImportance.High,
      soundSource: "resource://raw/warning",
      defaultPrivacy: NotificationPrivacy.Private,
      defaultColor: Colors.deepPurple,
      ledColor: Colors.deepPurple,
    );

    await AwesomeNotifications().initialize(
        null, //'resource://drawable/res_app_icon',//
        [
          buzzerNotificationChannel,
          NotificationChannel(
            channelKey: 'alerts',
            channelName: 'Alerts',
            channelDescription: 'Notification tests as alerts',
            playSound: true,
            importance: NotificationImportance.High,
            defaultPrivacy: NotificationPrivacy.Private,
            defaultColor: Colors.deepPurple,
            ledColor: Colors.deepPurple,
          )
        ],
        debug: debug);

    // Get initial notification action is optional
    initialAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: false);
  }

  static Future<void> initializeRemoteNotifications(
      {required bool debug}) async {
    await AwesomeNotificationsFcm().initialize(
      onFcmSilentDataHandle: NotificationController.mySilentDataHandle,
      onFcmTokenHandle: NotificationController.myFcmTokenHandle,
      onNativeTokenHandle: NotificationController.myNativeTokenHandle,
      licenseKeys:
          // On this example app, the app ID / Bundle Id are different
          // for each platform, so i used the main Bundle ID + 1 variation
          [
        // me.carda.awesomeNotificationsFcmExample
        'B3J3yxQbzzyz0KmkQR6rDlWB5N68sTWTEMV7k9HcPBroUh4RZ/Og2Fv6Wc/lE'
            '2YaKuVY4FUERlDaSN4WJ0lMiiVoYIRtrwJBX6/fpPCbGNkSGuhrx0Rekk'
            '+yUTQU3C3WCVf2D534rNF3OnYKUjshNgQN8do0KAihTK7n83eUD60=',

        // me.carda.awesome_notifications_fcm_example
        'UzRlt+SJ7XyVgmD1WV+7dDMaRitmKCKOivKaVsNkfAQfQfechRveuKblFnCp4'
            'zifTPgRUGdFmJDiw1R/rfEtTIlZCBgK3Wa8MzUV4dypZZc5wQIIVsiqi0Zhaq'
            'YtTevjLl3/wKvK8fWaEmUxdOJfFihY8FnlrSA48FW94XWIcFY=',
      ],
      debug: debug,
    );
  }

  ///  *********************************************
  ///     LOCAL NOTIFICATION EVENTS
  ///  *********************************************

  static Future<void> getInitialNotificationAction() async {
    ReceivedAction? receivedAction = await AwesomeNotifications()
        .getInitialNotificationAction(removeFromActionEvents: true);
    if (receivedAction == null) return;

    Fluttertoast.showToast(
      msg: 'Notification action launched app: $receivedAction',
      backgroundColor: Colors.deepPurple,
    );
    print('Notification action launched app: $receivedAction');
  }

  ///  *********************************************
  ///     REMOTE NOTIFICATION EVENTS
  ///  *********************************************

  /// Use this method to execute on background when a silent data arrives
  /// (even while terminated)
  @pragma("vm:entry-point")
  static Future<void> mySilentDataHandle(FcmSilentData silentData) async {
    late String serviceType;
    if (silentData.createdLifeCycle != NotificationLifeCycle.Foreground) {
      serviceType = 'BACKGROUND';
    } else {
      serviceType = 'FOREGROUND';
    }

    Fluttertoast.showToast(
      msg: '$serviceType Silent data received',
      backgroundColor: Colors.blueAccent,
      textColor: Colors.white,
      fontSize: 16,
    );

    if (silentData.data != null) {
      if (silentData.data!['payload'] != null) {
        final payloadJson = jsonDecode(silentData.data!['payload']!);
        if (payloadJson['show_notification'] == '1') {
          final notificationData = silentData.data!;

          await _showNotification(
            notificationContent:
                // notificationContent
                NotificationContent(
              id: -1,
              channelKey: notificationData['android_channel_id'] ?? "alerts",
              title: notificationData['title'],
              body: notificationData['body'],
            ),
          );
        }
      } else {
        // Your code to handle the notification when 'show_notification' is true

        await executeLongTaskInBackground();
      }
    }
  }

  /// Use this method to detect when a new fcm token is received
  @pragma("vm:entry-point")
  static Future<void> myFcmTokenHandle(String token) async {
    print("*******myFcmTokenHandle******");
    print(token);
    Fluttertoast.showToast(
        msg: 'Fcm token received',
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16);
    debugPrint('Firebase Token:"$token"');
  }

  /// Use this method to detect when a new native token is received
  @pragma("vm:entry-point")
  static Future<void> myNativeTokenHandle(String token) async {
    Fluttertoast.showToast(
        msg: 'Native token received',
        backgroundColor: Colors.blueAccent,
        textColor: Colors.white,
        fontSize: 16);
    debugPrint('Native Token:"$token"');
  }

  static Future<void> resetBadge() async {
    await AwesomeNotifications().resetGlobalBadge();
  }

  ///  *********************************************
  ///     REMOTE TOKEN REQUESTS
  ///  *********************************************

  static Future<String> requestFirebaseToken() async {
    if (await AwesomeNotificationsFcm().isFirebaseAvailable) {
      try {
        return await AwesomeNotificationsFcm().requestFirebaseAppToken();
      } catch (exception) {
        debugPrint('$exception');
      }
    } else {
      debugPrint('Firebase is not available on this project');
    }
    return '';
  }

  ///  *********************************************
  ///     NOTIFICATION EVENTS LISTENER
  ///  *********************************************
  ///  Notifications events are only delivered after call this method
  static Future<void> startListeningNotificationEvents() async {
    AwesomeNotifications()
        .setListeners(onActionReceivedMethod: onActionReceivedMethod);
  }

  ///  *********************************************
  ///     NOTIFICATION EVENTS
  ///  *********************************************
  ///
  @pragma('vm:entry-point')
  static Future<void> onActionReceivedMethod(
      ReceivedAction receivedAction) async {
    print("*******************onActionReceivedMethod**********************");
    print(receivedAction.toMap());
    if (receivedAction.actionType == ActionType.SilentAction ||
        receivedAction.actionType == ActionType.SilentBackgroundAction) {
      // if (receivedAction.payload != null &&
      //     receivedAction.payload!['show_notification'] == "1") {
      //   print("*******************show_notification**********************");

      //   // Your code to handle the notification when 'show_notification' is true
      // } else {
      // }
      // For background actions, you must hold the execution until the end
      print(
          'Message sent via notification input: "${receivedAction.buttonKeyInput}"');
      await executeLongTaskInBackground();
    } else {
      MyApp.navigatorKey.currentState?.pushNamedAndRemoveUntil(
          '/notification-page',
          (route) =>
              (route.settings.name != '/notification-page') || route.isFirst,
          arguments: receivedAction);
    }
  }

  ///  *********************************************
  ///     REQUESTING NOTIFICATION PERMISSIONS
  ///  *********************************************
  ///
  static Future<bool> displayNotificationRationale() async {
    bool userAuthorized = false;
    BuildContext context = MyApp.navigatorKey.currentContext!;
    await showDialog(
        context: context,
        builder: (BuildContext ctx) {
          return AlertDialog(
            title: Text('Get Notified!',
                style: Theme.of(context).textTheme.titleLarge),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Image.asset(
                        'assets/animated-bell.gif',
                        height: MediaQuery.of(context).size.height * 0.3,
                        fit: BoxFit.fitWidth,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Text(
                    'Allow Awesome Notifications to send you beautiful notifications!'),
              ],
            ),
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Deny',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.red),
                  )),
              TextButton(
                  onPressed: () async {
                    userAuthorized = true;
                    Navigator.of(ctx).pop();
                  },
                  child: Text(
                    'Allow',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(color: Colors.deepPurple),
                  )),
            ],
          );
        });
    return userAuthorized &&
        await AwesomeNotifications().requestPermissionToSendNotifications();
  }

  ///  *********************************************
  ///     BACKGROUND TASKS TEST
  ///  *********************************************
  static Future<void> executeLongTaskInBackground() async {
    print("starting long task");
    await Future.delayed(const Duration(seconds: 4));
    final url = Uri.parse("http://google.com");
    final re = await http.get(url);
    print(re.body);
    print("long task done");
  }

  static Future<void> _showNotification({
    required NotificationContent notificationContent,
    List<NotificationActionButton>? actionButtons,
    NotificationSchedule? schedule,
  }) async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) isAllowed = await displayNotificationRationale();
    if (!isAllowed) return;
    await AwesomeNotifications().createNotification(
      content: notificationContent,
      actionButtons: actionButtons,
      schedule: schedule,
    );
  }

  ///  *********************************************
  ///     NOTIFICATION CREATION METHODS
  ///  *********************************************
  ///
  static Future<void> createNewNotification() async {
    final notificationContent = NotificationContent(
      id: -1, // -1 is replaced by a random number
      // channelKey: 'alerts',
      channelKey: 'buzzer_channel',
      title: 'Huston! The eagle has landed!',
      body: "A small step for a man, but a giant leap to Flutter's community!",
      bigPicture:
          'https://storage.googleapis.com/cms-storage-bucket/d406c736e7c4c57f5f61.png',
      largeIcon:
          'https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png',
      //'asset://assets/images/balloons-in-sky.jpg',
      notificationLayout: NotificationLayout.BigPicture,
      payload: {'notificationId': '1234567890'},
    );
    final actionButtons = [
      NotificationActionButton(key: 'REDIRECT', label: 'Redirect'),
      NotificationActionButton(
          key: 'REPLY',
          label: 'Reply Message',
          requireInputText: true,
          actionType: ActionType.SilentAction),
      NotificationActionButton(
          key: 'DISMISS',
          label: 'Dismiss',
          actionType: ActionType.DismissAction,
          isDangerousOption: true)
    ];

    await _showNotification(
      notificationContent: notificationContent,
      actionButtons: actionButtons,
    );
  }

  static Future<void> scheduleNewNotification() async {
    bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
    if (!isAllowed) isAllowed = await displayNotificationRationale();
    if (!isAllowed) return;

    final notificationContent = NotificationContent(
      id: -1, // -1 is replaced by a random number
      channelKey: 'alerts',
      title: "Huston! The eagle has landed!",
      body: "A small step for a man, but a giant leap to Flutter's community!",
      bigPicture:
          'https://storage.googleapis.com/cms-storage-bucket/d406c736e7c4c57f5f61.png',
      largeIcon:
          'https://storage.googleapis.com/cms-storage-bucket/0dbfcc7a59cd1cf16282.png',
      //'asset://assets/images/balloons-in-sky.jpg',
      notificationLayout: NotificationLayout.BigPicture,
      payload: {'notificationId': '1234567890'},
    );

    final actionButtons = [
      NotificationActionButton(key: 'REDIRECT', label: 'Redirect'),
      NotificationActionButton(
        key: 'DISMISS',
        label: 'Dismiss',
        actionType: ActionType.DismissAction,
        isDangerousOption: true,
      )
    ];

    final schedule = NotificationCalendar.fromDate(
        date: DateTime.now().add(const Duration(seconds: 10)));

    await _showNotification(
      notificationContent: notificationContent,
      actionButtons: actionButtons,
      schedule: schedule,
    );
  }

  static Future<void> resetBadgeCounter() async {
    await AwesomeNotifications().resetGlobalBadge();
  }

  static Future<void> cancelNotifications() async {
    await AwesomeNotifications().cancelAll();
  }
}
