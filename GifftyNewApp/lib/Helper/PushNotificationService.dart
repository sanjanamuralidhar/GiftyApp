import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter/cupertino.dart';
// import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
// import '../main.dart';
import 'Constant.dart';
import 'Session.dart';
import 'String.dart';


bool _isConfigured = false;

class PushNotificationService {
  final FirebaseMessaging _fcm;

  PushNotificationService(this._fcm);

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future initialise() async {
    if (Platform.isIOS) {
      iOSPermission();
    }

    _fcm.getToken().then((token) async {
      CUR_USERID = await getPrefrence(ID);
      if (CUR_USERID != null && CUR_USERID != "") _registerToken(token);
    });

    if (!_isConfigured) {
      _fcm.configure(
        onMessage: (message) async {
          print('onmessage $message');
          await myForgroundMessageHandler(message);
        },
        onBackgroundMessage: myForgroundMessageHandler,
        onResume: (message) async {
          print('onresume $message');
          await myForgroundMessageHandler(message);
        },
        onLaunch: (message) async {
          print('onlaunch $message');
          await myForgroundMessageHandler(message);
        },
      );
      _isConfigured = true;
    }
  }

  void iOSPermission() {
    _fcm.requestNotificationPermissions(
        IosNotificationSettings(sound: true, badge: true, alert: true));
    _fcm.onIosSettingsRegistered.listen((settings) {
      //  print("Settings registered: $settings");
    });
  }

  void _registerToken(String token) async {
    var parameter = {USER_ID: CUR_USERID, FCM_ID: token};

    Response response =
        await post("$updateFcmApi", body: parameter, headers: headers)
            .timeout(Duration(seconds: timeOut));

    var getdata = json.decode(response.body);
print(getdata);

  }


  static Future<dynamic> myForgroundMessageHandler(
      Map<String, dynamic> message) async {


    if (message.containsKey('notification')||message.containsKey('data')) {
      var data = message['notification'];


      var title = data['title'].toString();
      var body = data['body'].toString();
      var image = message['data']['image'];
      var type=message['data']['type'];
      var id=message['data']['type_id'];

      if (image != null && image !='null') {
        generateImageNotication(title, body, image,type,id);
      } else {
        generateSimpleNotication(title, body,type,id);
      }
    }
  }



  static Future<String> _downloadAndSaveImage(
      String url, String fileName) async {
    var directory = await getApplicationDocumentsDirectory();
    var filePath = '${directory.path}/$fileName';
    var response = await http.get(url);


    var file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  static Future<void> generateImageNotication(
      String title, String msg, String image,String type,String id) async {



    var largeIconPath = await _downloadAndSaveImage(image, 'largeIcon');
    var bigPicturePath = await _downloadAndSaveImage(image, 'bigPicture');
    var bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        hideExpandedLargeIcon: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: msg,
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'big text channel id',
        'big text channel name',
        'big text channel description',
        largeIcon: FilePathAndroidBitmap(largeIconPath),
        styleInformation: bigPictureStyleInformation);
    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, msg, platformChannelSpecifics,payload: type+","+id);
  }

  static Future<void> generateSimpleNotication(String title, String msg,String type,String id) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.max, priority: Priority.high, ticker: 'ticker');

    var platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin
        .show(0, title, msg, platformChannelSpecifics, payload:type+","+id );
  }
}
