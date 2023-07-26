import 'dart:convert';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:we_talk/screens/chatroom_screen.dart';
import 'main.dart';
import 'package:http/http.dart' as http;

class NotificationService {

  static FirebaseAuth auth = FirebaseAuth.instance;

  static initializeNotification()
  async {

    await AwesomeNotifications().initialize(
        null,
    [
      NotificationChannel(channelKey: 'high_importance_channel',
          channelName: 'high_importance_channel',
          channelDescription: 'high_importance_channel',
      importance: NotificationImportance.Max,
      )
    ],
      channelGroups: [
        NotificationChannelGroup(channelGroupKey: 'high_importance_channel_group',
            channelGroupName: 'Group 1'),
      ],
      debug: true,
    );

    await AwesomeNotifications().isNotificationAllowed().then((value) async {
      if(!value)
        {
          await AwesomeNotifications().requestPermissionToSendNotifications();
        }
    });
    // final PermissionStatus status = await Permission.notification.request();
    // if (status.isGranted) {
    //   // Notification permissions granted
    // } else if (status.isDenied) {
    //   // Notification permissions denied
    // } else if (status.isPermanentlyDenied) {
    //   // Notification permissions permanently denied, open app settings
    //   await openAppSettings();
    // }

    AwesomeNotifications().setListeners(
        onActionReceivedMethod:  onActionReceivedMethod,
        onNotificationCreatedMethod: onNotificationCreatedMethod,
        onNotificationDisplayedMethod: onNotificationDisplayedMethod,
        onDismissActionReceivedMethod: onDismissActionReceivedMethod
    );
  }

  @pragma("vm:entry-point")
  static Future<void> onNotificationCreatedMethod( ReceivedNotification receivedNotification)
  {

    debugPrint('this is in onNotificationCreatedMethods');
    return Future.delayed(const Duration(seconds: 1));
  }

  @pragma("vm:entry-point")
  static  Future<void> onActionReceivedMethod(ReceivedAction action)
  async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    FirebaseAuth auth = FirebaseAuth.instance;
    debugPrint('this is in onActionReceivedMethod -> ${action.actionType}');
    debugPrint('this is in onActionReceivedMethod -> ${action.payload}');

    if(action.actionType == ActionType.Default)
      {
        var data1 = json.decode(action.groupKey!);
        // debugPrint('this is payload -> $data1');
        // debugPrint('in true of action silent');
        firestore.collection('user').doc(data1['sendBy']).get().then((value) {
          // debugPrint('==================');
          // debugPrint(value.data().toString());
          // debugPrint('this is after launch app');

          MyApp.navigatorKeyNew.currentState?.push(MaterialPageRoute(builder: (context) =>
              ChatRoom(
                userRefId: data1['receiver'],
                receiverName: data1['receiverName'],
                receiverProfile: data1['profile'],
                chatRoomId: data1['chatRoomId'],
                deviceToken: value.data()!['deviceToken'],
              )
          ));

        });

      }
    if(action.actionType == ActionType.SilentAction)
      {
        var data = json.decode(action.buttonKeyPressed);
        var inputData = action.buttonKeyInput;

        debugPrint('this is in 1');
        debugPrint('this is in 2');

         firestore.collection('chatRoom').doc(data['chatRoomId']).collection('chats').get().then((value) async {

          for (var e in value.docs) {

            debugPrint(
                '---------------- vale has been updated ------------------------- ${e.data()}');
            if (auth.currentUser!.uid ==
                e.data()['receiver']
                && e.data()['opened'] == false
            ) {
              debugPrint(
                  '---------------- vale has been updated -------------------------');

               firestore.collection('chatRoom').doc(
                  data['chatRoomId']).collection('chats').doc(
                  e.reference.id).update(
                  {
                    'opened': true
                  }
              );

               firestore.collection('chatRoom').doc(
                  data['chatRoomId']).update(
                  {
                    'lastMessageCount': 0,
                    'opened': true,
                  }
              );
            }
          }

        });

        int unreadMessage;

         firestore.collection('chatRoom').doc(data['chatRoomId']).get().then((
            value) async {
          debugPrint('printing value ----');
          debugPrint(value.data().toString());

          debugPrint('this is in 3');

          if (value.data() != null) {
            unreadMessage = value.data()!['lastMessageCount'];
            // unreadMessage = 0;
            unreadMessage++;

            debugPrint('in click of if 2 in then');
             firestore.collection('chatRoom').doc(data['chatRoomId']).set(
                {
                  'sendBy': data['receiver'],
                  'receiver': data['sendBy'],
                  'senderName': data['receiverName'],
                  'receiverName': data['senderName'],
                  'lastMessage': inputData,
                  'lastMessageCount': unreadMessage,
                  'type': 'text',
                  'time': FieldValue.serverTimestamp(),
                  'opened': false,
                  'chatRoomId': data['chatRoomId']
                });
          }
          else {
            debugPrint('this is in 4');
            unreadMessage = 0;
            unreadMessage++;
            debugPrint('in click of if 2 in then');
            await firestore.collection('chatRoom').doc(data['chatRoomId']).set(
                {
                  'sendBy': data['receiver'],
                  'receiver': data['sendBy'],
                  'senderName': data['receiverName'],
                  'receiverName': data['senderName'],
                  'lastMessage': inputData,
                  'lastMessageCount': unreadMessage,
                  'type': 'text',
                  'time': FieldValue.serverTimestamp(),
                  'opened': false,
                  'chatRoomId': data['chatRoomId']
                });
          }
        });
         firestore.collection('chatRoom').doc(data['chatRoomId']).collection(
            'chats').add(
            {
              'sendBy': data['receiver'],
              'receiver': data['sendBy'],
              'senderName': data['receiverName'],
              'receiverName': data['senderName'],
              'message': inputData,
              'type': 'text',
              'time': FieldValue.serverTimestamp(),
              'opened': false,
              'isSenderMessageDeleted':false,
              'isReceiverMessageDeleted':false,
            });
        await firestore.collection('user').doc(data['sendBy']).get().then((value) {
          callOnFcmApiSendPushNotifications(message: inputData,type: 'text',deviceToken: value.data()!['deviceToken']
          ,chatRoomId: data['chatRoomId'],receiver: data['sendBy'],receiverName: data['senderName']
          );

        });

      }
    // debugPrint('this is in onActionReceivedMethod -> ${action.payload}');
    // debugPrint('this is in onActionReceivedMethod -> ${receivedNotification.actionType}');
    // debugPrint('this is in onActionReceivedMethod -> ${receivedNotification.actionType}');
    // debugPrint('this is in  -> ${receivedNotification.body}');
    // debugPrint('this is in  -> ${receivedNotification.payload}');
    // debugPrint('this is in  -> ${receivedNotification.actionType}');
    // debugPrint('this is in  -> ${receivedNotification.actionType}');

    return Future(() => null);
  }

  @pragma("vm:entry-point")
  static  Future<void> onNotificationDisplayedMethod( ReceivedNotification receivedNotification)
  {
    debugPrint('this is in onNotificationDisplayedMethod');
    debugPrint('this is in onNotificationDisplayedMethod-> ${receivedNotification.body}');


    return Future.delayed(const Duration(seconds: 1));
  }


  @pragma("vm:entry-point")
  static  Future<void> onDismissActionReceivedMethod( ReceivedNotification receivedNotification)
  {
    debugPrint('this is in onDismissActionReceivedMethod');
    return Future.delayed(const Duration(seconds: 1));
  }

  static showNotification({
    title,
    body,
    data
})
  async {
    debugPrint('show notification');
    debugPrint('show notification --> $data');
    await AwesomeNotifications().createNotification(
        content:
    NotificationContent(
      id: 1,
      channelKey: 'high_importance_channel',
    title: title,
    body: body,
    actionType: ActionType.Default,
    groupKey: json.encode(data),
    // bigPicture: ,
    displayOnForeground: true,
      displayOnBackground: true,

    ), actionButtons: [
          // NotificationActionButton(key: 'REDIRECT', label: 'Redirect'),
        NotificationActionButton(
              key: json.encode(data),
              label: 'Reply Message',
              requireInputText: true,
              actionType: ActionType.SilentAction,
          ),

        ]
    );
  }
  static Future<bool> callOnFcmApiSendPushNotifications(
      {deviceToken,
        type,
        message,
        chatRoomId,
        receiver,
        receiverName
      }
      ) async {

    debugPrint('in notification send');

    const postUrl = 'https://fcm.googleapis.com/fcm/send';
    final data = {
      "registration_ids": [deviceToken],
      "collapse_key": "type_a",
      "data": {
        'sendBy': auth.currentUser!.uid,
        'receiver': receiver,
        'senderName': auth.currentUser!.displayName,
        'receiverName': receiverName,
        'message': message,
        'type': type,
        'opened': false,
        'chatRoomId': chatRoomId,
        'profile':'none',
      },
    };

    final headers = {
      'content-type': 'application/json',
      'Authorization': 'key=AAAA3mnfjYc:APA91bEMMjnfHV0y2m2AflN9lbylIAS4A13JUqLeOHtTLg3le-WwSdgM-TbHsgdGZKf3WGtju_29XFrxnbgqy122EMQP4A5lzC5wBlwDuTlcADisDqcJQT5Pk0M3hbi03fBX9c5ACN1g' // 'key=YOUR_SERVER_KEY'
    };
    final response = await http.post(Uri.parse(postUrl),
        body: json.encode(data),
        encoding: Encoding.getByName('utf-8'),
        headers: headers);
    debugPrint(response.statusCode.toString());
    if (response.statusCode == 200) {

      debugPrint("notification sent !!!");
      return true;
    } else {
      return false;
    }
  }

}













