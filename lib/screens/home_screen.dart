import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:story_view/controller/story_controller.dart';
import 'package:story_view/utils.dart';
import 'package:story_view/widgets/story_view.dart';
import 'package:uuid/uuid.dart';
import 'package:we_talk/methods.dart';
import 'package:we_talk/screens/chatroom_screen.dart';
import 'package:we_talk/screens/login_screen.dart';
import 'package:we_talk/screens/profile_screen.dart';
import 'package:we_talk/screens/story_more_options_screen.dart';
import 'package:we_talk/screens/upload_story_screen.dart';
import '../notification_service.dart';


@pragma("vm:entry-point")
Future<void> backgroundMessageHandler(RemoteMessage remoteMessage) {
  debugPrint('backgroundHandler');
  debugPrint(remoteMessage.data['message']);
  debugPrint(remoteMessage.data.toString());
  String? body;
  if(remoteMessage.data['type'] == 'img')
    {
      body = 'image';
    }
  else if(remoteMessage.data['type'] == 'text')
    {
      body = remoteMessage.data['message'];
    }
  else
    {
      body = remoteMessage.data['type'];
    }
  debugPrint('this is body $body');

  NotificationService.showNotification(
      data: remoteMessage.data,
      body: body,
      title: remoteMessage.data['senderName']);
  return Future(() => null);
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;

  var userChatList = [];
  var myChatList = [];
  var userList = [];
  var totalChatRooms = [];
  var displayUserList = [];
  var menuItems = ['Setting'];
  int index = 0;
  ImagePicker imagePicker = ImagePicker();
  File? mediaFile;
  String? myProfile;
  final controller = StoryController();

  List<QueryDocumentSnapshot<Map<String, dynamic>>?> storyList = [];
  // Map<String, List<Map<String, dynamic>>> groupedStoryData = {};
  List<Map<String,dynamic>> groupedStoryData = [];


  @override
  void initState() {
    NotificationService.initializeNotification();
    // TODO: implement initState
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    debugPrint('in init');
    debugPrint('-------- ${auth.currentUser!.uid}');
    getUserChatList();
    getStoryList();
    setStatus(status: 'Online');
    FirebaseMessaging.instance.getInitialMessage().then(
          (value) {},
        );
    FirebaseMessaging.onMessage.listen((remoteMessage) {
      debugPrint('openAPP');
      debugPrint(remoteMessage.data['message']);
      debugPrint(remoteMessage.data['senderName']);

      String? body;
      if(remoteMessage.data['type'] == 'img')
      {
        body = 'image';
      }
      else if(remoteMessage.data['type'] == 'text')
      {
        body = remoteMessage.data['message'];
      }
      else
      {
        body = remoteMessage.data['type'];
      }

      NotificationService.showNotification(
          data: remoteMessage.data,
          body: body,
          title: remoteMessage.data['senderName']);
    });

    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);

    fireStore.collection('user').snapshots().listen((event) {
      getUserChatList();
    });

    fireStore.collection('user').get().then(
          (value) {
        //userList.clear();
        for (var element in value.docs) {
          if(element.data()['uid'] == auth.currentUser!.uid)
          {
            myProfile = element.data()['profile'];
          }
        }
      },
    );

  }

  setStatus({status}) async {
    await fireStore
        .collection('user')
        .doc(auth.currentUser!.uid)
        .update({'status': status});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // TODO: implement didChangeAppLifecycleState
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.resumed) {
      debugPrint('===================resume');
      setStatus(status: 'Online');
    } else {
      debugPrint('===================pause');
      setStatus(status: 'Offline');
    }
  }

  @override
  Widget build(BuildContext context) {

    String chatroomId({String? user1, String? user2}) {
      if (user1.hashCode > user2.hashCode) {
        return '$user1$user2';
      } else {
        return '$user2$user1';
      }
    }
    Size size = MediaQuery.of(context).size;
    debugPrint('in build of home page');

    var widgetList = [
      chatsWidget(size: size,chatroomId: chatroomId),
      storiesWidget()
    ];


    return SafeArea(
      child: Scaffold(
          body: Stack(
            children: [
              SizedBox(
                  height: double.infinity,
                  child: Image.asset('assets/night-sky.png', fit: BoxFit.cover)),
              Column(
                children: [
                  const SizedBox(
                    height: 15,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Row(children: [
                      const Text('We Talk',
                          style: TextStyle(fontSize: 26, color: Colors.white)),
                      const Spacer(),
                      const SizedBox(
                        width: 5,
                      ),
                      DropdownButtonHideUnderline(
                        child: DropdownButton2(
                          customButton: const Icon(
                            Icons.more_vert,
                            size: 30,
                            color: Colors.white,
                          ),
                          items: [
                            DropdownMenuItem(
                              value: 'one',
                               child: InkWell(
                                 onTap: () {
                                   debugPrint('in log out');
                                   showConfirmationDialog(
                                       context: context,
                                       onConfirm: () async {
                                         logout().then(
                                               (value)  {
                                             debugPrint('logout success');
                                             Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) =>
                                                 const LoginScreen()), (Route<dynamic> route) => false);
                                           },
                                         );
                                       },
                                       title: 'We Chat',
                                       description: 'Are you sure you want to logout?'
                                   );
                                 },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5),
                                  decoration: const BoxDecoration(
                                    // color: Colors.red,
                                    border: Border(bottom: BorderSide(color: Colors.grey,style: BorderStyle.solid,width: 0.5))
                                  ),
                                    height: 50,
                                    width: size.width * 0.35,
                                    alignment: Alignment.centerLeft,
                                    child: const Text('Log Out',style: TextStyle(fontWeight: FontWeight.w400,),)),
                              )
                            ),
                            DropdownMenuItem(
                              value: 'two',
                                child: InkWell(
                                  onTap: () {
                                    debugPrint('in log out');
                                    Navigator.push(context, MaterialPageRoute(builder: (context) =>  ProfileScreen(),));
                                  },
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5),
                                      height: 50,
                                      width: size.width * 0.35,
                                      decoration: const BoxDecoration(
                                        // color: Colors.red,
                                          border: Border(top: BorderSide(color: Colors.grey,style: BorderStyle.solid,width: 0.5))
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: const Text('Settings',style: TextStyle(fontWeight: FontWeight.w400,),)),
                                )
                            ),
                          ],
                          onChanged: (value) {
                            debugPrint(value.toString());
                          },
                          dropdownStyleData: DropdownStyleData(
                            width: size.width * 0.35,
                            // maxHeight: 45,
                            // padding: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color:  const Color(0xfff5f7fa),
                              borderRadius: BorderRadius.circular(4),
                              // color: Colors.grey,
                            ),
                            offset: const Offset(0, 8),
                          ),
                        ),
                      ),

                    ]),
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                  tapBar(),
                  // const SizedBox(
                  //   height: 15,
                  // ),
                  widgetList[index]

                ],
              ),
            ],
          )
          ),
    );
  }

  String formatDateTime(DateTime dateTime) {
    final now = DateTime.now();

    // If the dateTime is today, format it as '05:23 AM'
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      final formattedTime = DateFormat('hh:mm a').format(dateTime);
      return formattedTime;
    }

    // If the dateTime is yesterday, return 'Yesterday'
    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      return 'Yesterday';
    }

    // For any other date, format it as '05/12/2023'
    final formattedDate = DateFormat('MM/dd/yyyy').format(dateTime);
    return formattedDate;
  }

  Future getUserList() async {
    await fireStore.collection('user').get().then(
      (value) {
        userList.clear();
        for (var element in value.docs) {
          userList.add(element.data());
        }
      },
    );
  }

  void getUserChatList() async {
    await fireStore.collection('chatRoom').get().then((value) {
      debugPrint('this is ------------------------ ${value.docs.length}');
      // add last msg to userChatList if not present
      for (var element in value.docs) {
        debugPrint('this is chat room element ${element.data()}');
        if (!(userChatList
            .any((map) => map['chatRoomId'] == element.data()['chatRoomId']))) {
          userChatList.add(element.data());
        }
      }
      debugPrint('this is userChatList list 1 ---> ${myChatList.length}');
      getUserList().then((value) {
        debugPrint('printing user chat list ');
        debugPrint('this is user list -> $userList');
        // to make total room of current user
        for (var e in userList) {
          String? tempId;
          if (auth.currentUser!.uid != e['uid']) {
            if (auth.currentUser!.uid.toString().hashCode >
                e['uid'].toString().hashCode) {
              tempId = '${auth.currentUser!.uid}${e['uid']}';
            } else {
              tempId = '${e['uid']}${auth.currentUser!.uid}';
            }
            totalChatRooms.add(tempId);
          }
        }
        // get all my chat rooms
        for (var e in userChatList) {
          if (totalChatRooms.any((map) => map == e['chatRoomId'])) {
            if (!myChatList.any((map) => map == e)) {
              myChatList.add(e);
            }
          }
        }
        debugPrint(
            'this is new chat list my -=----------------------> ${myChatList.length}');
        for (var e in userList) {
          if (myChatList.isEmpty) {
            if (!(displayUserList.any((map) => map['uid'] == e['uid']))) {
              debugPrint('in 2');
              displayUserList.add({
                'name': e['name'],
                'profile': e['profile'],
                'uid': e['uid'],
                'lastMessage': 'none',
                'lastMessageCount': 'none',
                'time': DateTime.now(),
                'chatRoomId': 'none',
                'lastMsgSender': true,
                'type':'none',
                'isSenderMessageDeleted':false,
                'isReceiverMessageDeleted':false,
                'isPermanentlyDeleted':false
              });
            }
          } else {
            for (var element in myChatList) {
              if ( element != null &&(e['uid'] == element['receiver'] ||
                  e['uid'] == element['sendBy']) ) {
                if (!(displayUserList.any((map) => map['uid'] == e['uid'])) && element != null) {
                  debugPrint('in 3');
                  // debugPrint('this is for existing user -> ${e['uid']}');
                  // debugPrint('this is for existing user -> ${e['name']}');
                  displayUserList.add({
                    'name': e['name'],
                    'profile': e['profile'],
                    'uid': e['uid'],
                    'lastMessage': element['lastMessage'],
                    'lastMessageCount': element['lastMessageCount'],
                    'time': element['time'].toDate(),
                    'chatRoomId': element['chatRoomId'],
                    'lastMsgSender': element['sendBy'] == auth.currentUser!.uid,
                    'deviceToken': e['deviceToken'],
                    'type':element['type'],
                    'isSenderMessageDeleted':element['isSenderMessageDeleted'],
                    'isReceiverMessageDeleted':element['isReceiverMessageDeleted'],
                    'isPermanentlyDeleted':element['isPermanentlyDeleted']
                  });
                }
              } else {
                debugPrint('in 1');
                // debugPrint('this is for not existing user -> ${e['name']}');
                // debugPrint('this is for not existing user -> ${e['uid']}');
                if (!(displayUserList.any((map) => map['uid'] == e['uid']))) {
                  displayUserList.add({
                    'name': e['name'],
                    'profile': e['profile'],
                    'uid': e['uid'],
                    'lastMessage': 'none',
                    'lastMessageCount': 'none',
                    'time': DateTime(1900),
                    'chatRoomId': 'none',
                    'lastMsgSender': true,
                    'deviceToken': e['deviceToken'],
                    'type':'none',
                    'isSenderMessageDeleted':false,
                    'isReceiverMessageDeleted':false,
                    'isPermanentlyDeleted':false
                  });
                }
              }
            }
          }
        }
        displayUserList
            .removeWhere((element) => element['uid'] == auth.currentUser!.uid);
        debugPrint('this is displayUser list --> $displayUserList');
        debugPrint(
            'this is displayUser list --> ${displayUserList.toSet().toList().length}');
        debugPrint('this is userList list -----> ${userList.length}');
        debugPrint('this is myChatList list -> ${myChatList.length}');
        debugPrint('this is userChatList list -> $userChatList');

        setState(() {});
      });
    });
  }

  Widget lastMessage({type,lstMsg,Size? size,person})
  {
    // debugPrint('this is type -> $type');
    if(person['lastMsgSender'] && person['isSenderMessageDeleted'] == true)
      {
        debugPrint('this is type receiver');
        return Container();
      }
    else if(person['isReceiverMessageDeleted'] == true)
      {
        debugPrint('this is sender');
        return Container();
      }
    else if(person['isPermanentlyDeleted'] == true){
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.not_interested,color: Colors.grey,size: 20),
          SizedBox(width: 8,),
          Text(
            'This message is deleted',
            style: TextStyle(color: Colors.grey, fontWeight:
            FontWeight
                .w700),
          ),
        ],
      );
    }
    else if(type == 'text' || type == 'link')
      {
        debugPrint('this is type msg 1');
        return SizedBox(
            width: size!.width * 0.50,
            // height: 18,
            child: Text(
              maxLines: 1,
             ' $lstMsg',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color:
                  Colors.grey,
                  fontWeight:
                  FontWeight
                      .w700),
            ));
      }
    else if(type == 'img')
      {
        debugPrint('this is type msg 2');
        return SizedBox(
          width: size!.width * 0.50,
          child: Row(children:  const [
            Icon(Icons.image,size: 18,color: Colors.black54),
            Text(
              ' Image',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color:
                  Colors.grey,
                  fontWeight:
                  FontWeight
                      .w700),)
          ],),
        );
      }
    else
      {
        debugPrint('this is type msg 3');
        return SizedBox(
          width: size!.width * 0.50,
          child: Row(children:   [
            const Icon(Icons.file_copy,size: 18,color: Colors.black54),
            Text(
              ' ${toBeginningOfSentenceCase(lstMsg)!}',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color:
                  Colors.grey,
                  fontWeight:
                  FontWeight
                      .w700),
            )
          ],),
        );
      }

  }

  Widget lastMessageTime({person})
  {
    if(person['uid'] != auth.currentUser!.uid && person['isReceiverMessageDeleted'] == true)
    {
      debugPrint('this is type receiver');
      return Container();
    }
    else if(person['isSenderMessageDeleted'] == true)
    {
      debugPrint('this is sender');
      return Container();
    }
    else
      {
        return Text(
          formatDateTime(
              person['time']),
          style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight:
              FontWeight
                  .w700),
        );
      }
  }

  Widget chatsWidget({chatroomId,Size? size})
  {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
            gradient:  LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xfff5f7fa).withOpacity(0.93),
                const Color(0xffc3cfe2).withOpacity(0.93),
              ],
            ),
            // color: Colors.white.withOpacity(0.93),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20))
        ),
        child: StreamBuilder(
          stream: fireStore
              .collection('chatRoom')
              .orderBy('time', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Text('There is error in snap shot');
            }
            if (snapshot.data != null) {
              for (var element in snapshot.data!.docs) {
                if ((totalChatRooms.any(
                        (map) => map == element.data()['chatRoomId']))) {
                  if (displayUserList.isEmpty) {
                    return Container(
                      color: Colors.white,
                      width: double.infinity,
                      height: double.infinity,
                    );
                  } else {
                    var index = -1;
                    // debugPrint(
                    //     '---------this is for loop of snapshots ${element.data()['chatRoomId']}------------');
                    // debugPrint(
                    //     'this is current user id -> ${auth.currentUser!.uid}');

                    if (auth.currentUser!.uid !=
                        element.data()['sendBy']) {
                      // debugPrint('this is send by user id -> ${element.data()['sendBy']}');
                      index = displayUserList.indexWhere((data) =>
                      data['uid'] == element.data()['sendBy']);
                    } else {
                      // debugPrint(
                      //     'this is receiver user id -> ${element.data()['receiver']}');
                      index = displayUserList.indexWhere((data) =>
                      data['uid'] == element.data()['receiver']);
                    }

                    // debugPrint(
                    //     'this is index for data -=-=-=-=-=--========> $index');
                    if (index < 0) {
                      debugPrint('index is less then 1 ==> $index');
                    } else  {
                      var oldData = displayUserList[index];
                      // debugPrint(
                      //     'printing the data that is going to change --> ${displayUserList[index]}');
                      if (element.data()['time'] == null ) {
                        debugPrint('this is null in time ${element.data()}');
                      }
                      else
                      {
                        displayUserList[index] = {
                          'name': oldData['name'],
                          'profile': oldData['profile'],
                          'uid': oldData['uid'],
                          'deviceToken': oldData['deviceToken'],
                          'lastMessage': element.data()['lastMessage'],
                          'lastMessageCount':
                          element.data()['lastMessageCount'],
                          'time': element.data()['time'].toDate(),
                          'chatRoomId': element.data()['chatRoomId'],
                          'lastMsgSender': element.data()['sendBy'] ==
                              auth.currentUser!.uid,
                          'type':element.data()['type'],
                          'isSenderMessageDeleted':element.data()['isSenderMessageDeleted'],
                          'isReceiverMessageDeleted':element.data()['isReceiverMessageDeleted'],
                          'isPermanentlyDeleted':element.data()['isPermanentlyDeleted']
                        };
                      }
                    }
                  }
                }
              }
              displayUserList.sort((a, b) => b['time']
                  .toString()
                  .compareTo(a['time'].toString()));
              return ListView(
                padding: const EdgeInsets.symmetric(vertical: 10),
                children: [

                  ...displayUserList.map((person) {
                    // debugPrint(
                    //     'this is  person ===---=--=-==-=---> $person');
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 0, horizontal: 20),
                      child: InkWell(
                        onTap: () {
                          debugPrint('omn tap start');
                          var chatRoomId = chatroomId(
                              user1: auth.currentUser!.uid,
                              user2: person['uid']);
                          debugPrint('-==-==-=-> $chatRoomId');
                          Navigator.of(context)
                              .push(MaterialPageRoute(
                            builder: (context) => ChatRoom(
                              chatRoomId: chatRoomId,
                              receiverName: person['name'],
                              receiverProfile: person['profile'],
                              userRefId: person['uid'],
                              deviceToken: person['deviceToken'],
                            ),
                          ));
                          debugPrint('omn tap end');
                        },
                        child: Column(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  vertical: 5),
                              child: Row(
                                children: [
                                  InkWell(
                                    onTap: () {

                                      Navigator.push(context,
                                          MaterialPageRoute(
                                            builder: (context) {
                                              return Scaffold(
                                                backgroundColor:
                                                Colors.black,
                                                body: Column(
                                                  mainAxisSize: MainAxisSize.max,
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    const SizedBox(height: 20,),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 15),
                                                      child: Row(children: [
                                                        InkWell(onTap: () => Navigator.of(context).pop(),child: const Icon(Icons.arrow_back,color: Colors.white,)),
                                                        const SizedBox(width: 15,),
                                                        SizedBox(width: size!.width * 0.6,
                                                            child: Text('${person['name']}',style: const TextStyle(color: Colors.white,fontSize: 18),))
                                                      ]),
                                                    ),
                                                    InkWell(
                                                      onTap: () {
                                                        Navigator.pop(
                                                            context);
                                                      },
                                                      child: Center(
                                                        child: Hero(
                                                          tag:
                                                          '${person['uid']}',
                                                          child:
                                                          CachedNetworkImage(
                                                            imageBuilder:
                                                                (context, imageProvider) =>
                                                                SizedBox(width: size.width,
                                                                    height: size.height * 0.8,
                                                                    child: PhotoView(
                                                                      imageProvider: imageProvider,
                                                                      maxScale: 3.0,
                                                                      minScale: 0.6,
                                                                    )
                                                                ),
                                                            imageUrl:
                                                            '${person['profile']}',
                                                            placeholder: (context,
                                                                url) =>
                                                            const CircularProgressIndicator(),
                                                            errorWidget: (context, url, error) =>
                                                            const Icon(Icons.error),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            },
                                          ));
                                    },
                                    child: person!['profile'] == 'none' ? const Icon(Icons.account_circle, size: 60) : ClipRRect(
                                      borderRadius:
                                      BorderRadius.circular(30),
                                      child: Hero(
                                        tag: '${person['uid']}',
                                        child: CachedNetworkImage(
                                            height: 60,
                                            width: 60,
                                            fit: BoxFit.cover,
                                            imageUrl:
                                            '${person['profile']}',
                                            placeholder: (context,
                                                url) =>
                                            const Icon(
                                                Icons
                                                    .account_circle,
                                                size: 60),
                                            errorWidget: (context, url,
                                                error) {
                                              debugPrint(error.toString());
                                              return const Icon(Icons.error);
                                            }
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 15,
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        width: size!.width * 0.45,
                                        child: Text(
                                          toBeginningOfSentenceCase(
                                              person!['name']
                                                  .toString())!,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 18,
                                          fontWeight: FontWeight.w500
                                          ),
                                        ),
                                      ),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      person['lastMessage'] == 'none'
                                          ? Container()
                                          : lastMessage(
                                          type: person['type'],
                                          lstMsg: person['lastMessage'],
                                          size: size,
                                          person: person
                                      )
                                    ],
                                  ),
                                  const Spacer(),
                                  Column(
                                    mainAxisAlignment:
                                    MainAxisAlignment.end,
                                    children: [
                                      person['lastMessage'] == 'none'
                                          ? Container()
                                          :  lastMessageTime(person: person),
                                      const SizedBox(
                                        height: 5,
                                      ),
                                      person['lastMsgSender']
                                          ? Container(
                                        height: 15,
                                      )
                                          : person['lastMessageCount'] ==
                                          0
                                          ?  const CircleAvatar(
                                        // radius: 10,
                                        // maxRadius: 15,
                                          minRadius: 10,
                                          backgroundColor:
                                          Colors
                                              .transparent)
                                          : CircleAvatar(
                                          backgroundColor: Colors
                                              .deepPurpleAccent,
                                          // radius: 10,
                                          // maxRadius: 15,
                                          minRadius: 10,
                                          child: Text(
                                            '${person['lastMessageCount']}',
                                            style: const TextStyle(
                                                fontWeight:
                                                FontWeight
                                                    .bold,
                                                fontSize: 12,
                                                color: Colors
                                                    .white),
                                          )),
                                    ],
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                ],
                              ),
                            ),
                            Divider(
                              color: Colors.grey.withOpacity(0.3),
                              thickness: 1,
                            )
                          ],
                        ),
                      ),
                    );
                  }).toList()
                ],
              );
            }
            return Container(
              color: Colors.transparent,
              height: double.infinity,
              width: double.infinity,
            );
          },
        ),
      ),
    );
  }

  Widget tapBar()
  {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Row(
        // mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: (){
                setState(() {
                  index = 0;
                });
              },
              child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration:  BoxDecoration(
                      color: index == 0 ? Colors.white10 : Colors.transparent,
                      border: Border(bottom: index == 0 ? const BorderSide(color: Color(
                      0xff6d52c1),width: 5) : const BorderSide(width: 5,color: Colors.transparent))),
                  child: const Text('Chats',style: TextStyle(color: Colors.white,fontSize: 20))),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: (){
                setState(() {
                  index = 1;
                });
              },
              child: Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                      color: index == 1 ? Colors.white10 : Colors.transparent,
                      border: Border(bottom: index == 1 ? const BorderSide(color: Color(0xff6d52c1),width: 5) : const BorderSide(width: 5,color: Colors.transparent))),
                  child: const Text('Stories',style: TextStyle(color: Colors.white,fontSize: 20))),
            ),
          ),
        ],),
    );
  }

  Future getStoryList()
  async {
    await fireStore.collection('stories').orderBy('createdTime', descending: true).get().then((value) {
      debugPrint('this is data => ${value.docs.length}');
      storyList.clear();
      for (var element in value.docs)  {
        debugPrint('this is data => ${element.data()}');
        var stamp = element.data()['createdTime'];
        DateTime date = stamp.toDate();
        Duration difference = DateTime.now().difference(date);
        if(difference.inHours < 24)
        {
          storyList.add(element);
        }
        else
          {
            debugPrint('this is deleted ${element.data()}');
            fireStore.collection('stories').doc(element.reference.id).delete();
          }
      }
      debugPrint('this is storyList one => ${storyList.isEmpty ? 'empty' :storyList[0]!.data()}');
      debugPrint('this is storyList one => ${storyList.isEmpty ? 'empty' :storyList.length}');
      debugPrint('this is userList one => ${userList.isEmpty ? 'empty' :userList}');


      groupedStoryData.clear();
      for (var user in userList) {
        for (var story in storyList) {
          if(user['uid'] == story!['userId'])
            {
              groupedStoryData.add({
                'userId': user['uid'],
                'profile': user['profile'],
                'name': user['name'],
                'createdTime': story['createdTime'],
                'text': story['text'],
                'viewerList': story['viewerList'],
                'type': story['type'],
                'story': story['story'],
                'refId': story.reference.id
              });
            }
        }
      }

      // debugPrint('this is userList one => ${userList.isEmpty ? 'empty' :userList[0]}');
      debugPrint('this is userList one => ${userList.isEmpty ? 'empty' :userList.length}');
      debugPrint('this is groupedStoryData one => ${groupedStoryData.isEmpty ? 'empty' : groupedStoryData.length}');
      debugPrint('this is storyList one => ${storyList.isEmpty ? 'empty' :storyList.length}');
      debugPrint('this is groupedStoryData => ${groupedStoryData.isEmpty ? 'empty' : groupedStoryData}');

    });
  }

  storiesWidget()
   {
     getStoryList();
     bool isMyStoryPresent = false;
     List<StoryItem> storyItems = [];
     var alreadyDisplayUser = [];
     // Map<String, dynamic> myStory = {};
     DateTime myDate = DateTime.now();
     List<Map<String,List<StoryItem?>>> storyItemsNew = [];
     Map<String,List<StoryItem?>> myStoryItems = {};
     for (var story in groupedStoryData) {
       if(story['userId'] == auth.currentUser!.uid)
           {
             isMyStoryPresent = true;
             storyItems.add(story['type'] == 'img' ?
             StoryItem.pageImage(controller: controller,url: story['story'],
                 caption: story['text'] == 'none' ? null : story['text'])
                 : StoryItem.pageVideo(story['story'],
               caption: story['text'] == 'none' ? null : story['text'], controller: controller,
             ),);
             var stamp = story['createdTime'];
             myDate = stamp.toDate();
           }
     }

     for (var story in groupedStoryData) {
       debugPrint('flag -> $story');
       if(story['userId'] != auth.currentUser!.uid)
       {

         bool isKeyPresent = false;
         for (var item in storyItemsNew) {
           if (item.containsKey(story['userId'])) {
             storyItemsNew[storyItemsNew.indexOf(item)][story['userId']]!.add(story['type'] == 'img' ?
             StoryItem.pageImage(controller: controller,url: story['story'],
                 caption: story['text'] == 'none' ? null : story['text'])
                 : StoryItem.pageVideo(story['story'],
               caption: story['text'] == 'none' ? null : story['text'], controller: controller,));
             isKeyPresent = true;
             break;
           }
         }

         if (!isKeyPresent) {
           storyItemsNew.add({story['userId'] : [story['type'] == 'img' ?
           StoryItem.pageImage(controller: controller,url: story['story'],
               caption: story['text'] == 'none' ? null : story['text'])
               : StoryItem.pageVideo(story['story'],
             caption: story['text'] == 'none' ? null : story['text'], controller: controller,)]});
         }

       }
       else
         {
           debugPrint('flag');
           if(myStoryItems.containsKey(story['userId']))
           {
             debugPrint('flag 0');
             myStoryItems[story['userId']]!.add(
                 story['type'] == 'img' ?
                 StoryItem.pageImage(controller: controller,url: story['story'],
                     caption: story['text'] == 'none' ? null : story['text'])
                     : StoryItem.pageVideo(story['story'],
                   caption: story['text'] == 'none' ? null : story['text'], controller: controller,));
           }
           else
           {
             debugPrint('flag 1');
             myStoryItems = {
               story['userId'] : [story['type'] == 'img' ?
               StoryItem.pageImage(controller: controller,url: story['story'],
                   caption: story['text'] == 'none' ? null : story['text'])
                   : StoryItem.pageVideo(story['story'],
                 caption: story['text'] == 'none' ? null : story['text'], controller: controller,)]
             };
           }
         }
     }
     debugPrint('storyItemsNew --> $storyItemsNew');
     debugPrint('storyItemsNew --> $myStoryItems');

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
            gradient:  LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xfff5f7fa).withOpacity(0.93),
                const Color(0xffc3cfe2).withOpacity(0.93),
              ],
            ),
            // color: Colors.white.withOpacity(0.93),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20))
        ),
        padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 5),
        child:SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Text(groupedStoryData.toString(),style: const TextStyle(fontSize: 16)),
              const SizedBox(width: double.infinity,),
              const SizedBox(height: 10,),
              InkWell(
                  onTap: (){
                    if(isMyStoryPresent)
                      {
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                          // debugPrint('in story view navigate');
                          return StoryView(
                            controller: controller, // pass controller here too
                            repeat: false, // should the stories be slid forever
                            //onStoryShow: (s) {notifyServer(s)},
                            onComplete: () {
                              Navigator.pop(context);
                            },
                            onVerticalSwipeComplete: (direction) {
                              if (direction == Direction.down) {
                                Navigator.pop(context);
                              }
                            }, storyItems: myStoryItems[auth.currentUser!.uid]!, // To disable vertical swipe gestures, ignore this parameter.
                            // Preferably for inline story view.
                          );
                        } ,));
                      }
                    else
                      {
                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 15, vertical: 15),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        _getVideoFromGallery().then((value) {
                                          if(mediaFile != null)
                                          {
                                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => UploadStoryScreen(document:  mediaFile,isImage: false),)).then((value) {
                                              getStoryList().then((value) {
                                                setState(() {

                                                });
                                              });
                                              Navigator.pop(context);
                                            });
                                          }
                                        });
                                      },
                                      child: Row(
                                        //mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.video_collection, size: 30),
                                          SizedBox(width: 15),
                                          Text('Video')
                                        ],
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 5),
                                      child: Divider(),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        _getFromGallery().then((value) {
                                          if(mediaFile != null)
                                          {
                                            debugPrint('this is true for image pick');
                                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => UploadStoryScreen(document:  mediaFile,isImage: true),)).then((value) {
                                              getStoryList().then((value) {
                                                setState(() {

                                                });
                                              });
                                              Navigator.pop(context);
                                            });
                                          }
                                        });
                                      },
                                      child: Row(
                                        //mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.image, size: 30),
                                          SizedBox(width: 15),
                                          Text('Image')
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            });
                      }
                  },
                  child: storyItem(
                      url: myProfile,
                      title:  'My status' ,
                      subtitle: isMyStoryPresent ? formatDateTime(myDate) :'Tap to add status update'  ,
                      isPlusIconVisible: true,
                      isMyStoryPresent: isMyStoryPresent,
                      me: true
                  )),
              ...groupedStoryData.map((story) {
                var stamp = story['createdTime'];
                DateTime date = stamp.toDate();
                List<StoryItem?>? storyItems;
                for (var item in storyItemsNew) {
                  if (item.containsKey(story['userId'])) {
                    // print(item[story['userId']]);
                    // isKeyPresent = true;
                    storyItems = item[story['userId']]!;
                    break;
                  }
                }

                if(!alreadyDisplayUser.contains(story['userId']))
                {
                  alreadyDisplayUser.add(story['userId']);
                }
                else
                {
                  return Container();
                }
                if(story['userId'] == auth.currentUser!.uid)
                  {
                    return Container();
                  }
                return Column(
                  children: [
                    const Divider(),
                    InkWell(
                      onTap: (){
                        fireStore.collection('stories').doc(story['refId']).update(
                            {'viewerList': FieldValue.arrayUnion([auth.currentUser!.uid])}
                        );
                        Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                          // debugPrint('in story view navigate');
                          return StoryView(
                            controller: controller, // pass controller here too
                            repeat: false, // should the stories be slid forever
                            //onStoryShow: (s) {notifyServer(s)},
                            onComplete: () {
                              Navigator.pop(context);
                            },
                            onVerticalSwipeComplete: (direction) {
                              if (direction == Direction.down) {
                                Navigator.pop(context);
                              }
                            }, storyItems:storyItems!, // To disable vertical swipe gestures, ignore this parameter.
                            // Preferably for inline story view.
                          );
                        }));
                      },
                      child: storyItem(
                        title: story['name'],
                        subtitle: formatDateTime(date),
                        url: story['story'],
                        isMyStoryPresent: true,
                      ),
                    ),
                  ],
                );
              }).toList()
              // Row(
              //   children: const [
              //     Padding(
              //       padding: EdgeInsets.symmetric(vertical: 10,horizontal: 0),
              //       child: Text('Recent updates',style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500)),
              //     ),
              //     Spacer()
              //   ],
              // ),
              // ListView.builder(
              //   itemCount: 3,
              //   shrinkWrap: true,
              //   physics: const ScrollPhysics(),
              //   itemBuilder: (context, index) {
              //     return storyItem(
              //         url: 'none',
              //         title: 'My status',subtitle: 'Tap to add status update',isPlusIconVisible: false);
              //   },
              // ),
              // Row(
              //   children: const [
              //     Padding(
              //       padding: EdgeInsets.symmetric(vertical: 10,horizontal: 0),
              //       child: Text('Viewed updates',style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500)),
              //     ),
              //     Spacer()
              //   ],
              // ),
              // ListView.builder(
              //   itemCount: 3,
              //   shrinkWrap: true,
              //   physics: const ScrollPhysics(),
              //   itemBuilder: (context, index) {
              //     return storyItem(
              //       url: 'none',
              //         title: 'My status',subtitle: 'Tap to add status update',isPlusIconVisible: false);
              //   },
              // ),
            ],
          ),
        )
      ),
    );
  }

  Widget storyItem({
  title,
  subtitle,
  isPlusIconVisible = false,
  url,
  isMyStoryPresent = false,
  me = false
})
  {
    return Row(children: [
      Stack(
        alignment: Alignment.center,
        children: [
           CircleAvatar(radius: 33,
          backgroundColor: isMyStoryPresent ? Colors.deepPurple : Colors.transparent,),
          const CircleAvatar(radius: 30,
            backgroundColor: Colors.white,
          ),
          InkWell(
            onTap: (){},
            child: url == 'none' ? const Icon(Icons.account_circle, size: 60) : ClipRRect(
              borderRadius:
              BorderRadius.circular(30),
              child: Container(
                color: Colors.white,
                child: CachedNetworkImage(
                    height: 60,
                    width: 60,
                    fit: BoxFit.cover,
                    imageUrl:
                    '$url',
                    placeholder: (context,
                        url) => const Center(child: CircularProgressIndicator()),
                    // const Icon(
                    //     Icons.account_circle,
                    //     size: 60),
                    errorWidget: (context, url,
                        error) {
                      debugPrint(error.toString());
                      return const Icon(Icons.error);
                    }
                ),
              ),
            ),
          ),
          isPlusIconVisible && !isMyStoryPresent ? const Positioned.fill(
            child: Align(alignment: Alignment.bottomRight,
         child: Padding(
           padding: EdgeInsets.only(top: 5,left: 5),
           child: CircleAvatar(
             radius: 11,
             backgroundColor: Colors.white,
             child: CircleAvatar(
                 radius: 10,
                   backgroundColor: Colors.green,
                   child: Padding(
                     padding: EdgeInsets.only(left: 2.0),
                     child: Icon(FontAwesomeIcons.plus,color: Colors.white,size: 15),
                   )),
           ),
         ),
            ),
          ) : Container(),

        ],
      ),
      const SizedBox(
        width: 15,
      ),
      Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children:  [
          SizedBox(
            // width: size!.width * 0.45,
            child: Text(
              '$title',
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 18,
              fontWeight: FontWeight.w400
              ),
            ),
          ),
          const SizedBox(
            height: 5,
          ),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontWeight:
            FontWeight.w700),
          ),
        ],
      ),
      const Spacer(),
       Visibility(
         visible: me && isMyStoryPresent,
         child: InkWell(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context) => const StoryMoreOptionsScreen(),)).then((value) {
                getStoryList();
                setState(() {

                });
              });
            },
            child: const Icon(Icons.more_horiz)),
       )
    ],);
  }

  /// Get from gallery
  Future _getFromGallery() async {
    await imagePicker
        .pickImage(
      source: ImageSource.gallery,
      maxWidth: 1800,
      maxHeight: 1800,
    )
        .then(
          (value) async {
        if (value != null) {
          debugPrint('printing piked img if not null ==> $value');
            mediaFile = File(value.path);
        }
      },
    );
  }

  /// Get from gallery
  Future _getVideoFromGallery() async {
    await imagePicker
        .pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 30)
    ).then(
          (value) async {
        if (value != null) {
          debugPrint('printing piked img if not null ==> $value');
          mediaFile = File(value.path);
        }
      },
    );
  }


}
