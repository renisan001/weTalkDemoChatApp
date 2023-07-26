import 'dart:typed_data';
import 'dart:ui';
import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dio/dio.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:we_talk/screens/other_user_profile_screen.dart';
import 'dart:convert';
import 'dart:io';
import '../methods.dart';

class ChatRoom extends StatefulWidget {
  final String? chatRoomId;
  final String? receiverName;
  final String? receiverProfile;
  final String? userRefId;
  final String? deviceToken;

  const ChatRoom({Key? key,
    this.chatRoomId,
    this.userRefId,
    this.receiverProfile,
    this.receiverName,
    this.deviceToken})
      : super(key: key);

  @override
  State<ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<ChatRoom> {
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;
  TextEditingController messageText = TextEditingController();
  XFile? imageFile;
  ImagePicker imagePicker = ImagePicker();
  String imageFilePath = '';
  bool sendButton = true;
  List<String?> selectedMessageList = [];
  bool? isReceiveMessageAdded = false;
  bool? isLastMessageSelectedForDelete = false;
  QueryDocumentSnapshot<Map<String, dynamic>>? lastMessage;
  List<Map<String, dynamic>>? listOfDownloadImages = [];
  List<Map<String, dynamic>>? listOfDownloadPdf = [];
  List<Map<String, dynamic>>? listOfDownloadDocs = [];
  List<Map<String, dynamic>>? listOfGroupImages = [];


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    debugPrint('this is got map --> ${widget.receiverName}');
    selectedMessageList = [];
  }


  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    var user = fireStore.collection('user').doc(widget.userRefId).snapshots();
    debugPrint('this is got map --> ${widget.receiverName}');
    return SafeArea(
      child: WillPopScope(
        onWillPop: () async {
          FocusManager.instance.primaryFocus?.unfocus();
          return true;
        },
        child: Scaffold(
          backgroundColor: Colors.black,
          body: Stack(children: [
            // const Spacer(),
            SizedBox(
                height: double.infinity,
                child: Image.asset('assets/night-sky.png', fit: BoxFit.cover)),
            Column(
              children: [
                StreamBuilder(
                  stream: user,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint('error in chatRoom appbar');
                    }
                    if (snapshot.data != null) {
                      debugPrint(snapshot.data!.data()!['status']);
                      return customAppBar(
                          name: widget.receiverName,
                          status: snapshot.data!.data()!['status'],
                          context: context);
                    }
                    return Container();
                  },
                ),

                StreamBuilder(
                    stream: fireStore
                        .collection('chatRoom')
                        .doc(widget.chatRoomId)
                        .collection('chats')
                        .orderBy('time', descending: true)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        debugPrint('---------- error -----------');
                        return const Text(
                            'Something went wrong chatRoom error');
                      }

                      if (snapshot.hasData) {
                        QueryDocumentSnapshot<Map<String, dynamic>>? lastData;
                        Map<DateTime,
                            List<Map<String, dynamic>>> groupedData = {};

                        List<QueryDocumentSnapshot<
                            Map<String, dynamic>>> dataList = snapshot.data!
                            .docs.toList();


                        // Grouping the data by days
                        for (var item in dataList) {
                          // debugPrint('--${item.data()}');
                          if (item['time'] != null) {
                            DateTime dateTime = item['time'].toDate();
                            DateTime dateOnly = DateTime(
                                dateTime.year, dateTime.month, dateTime.day);

                            if (groupedData.containsKey(dateOnly)) {
                              groupedData[dateOnly]!.add(item.data());
                            } else {
                              groupedData[dateOnly] = [item.data()];
                            }
                          }
                        }
                        // grouping image logic
                        List<List<QueryDocumentSnapshot<Map<String, dynamic>>?>> groupedImages = [];

                        int startIndex = -1;
                        int endIndex = -1;
                        String previousSender = '';

                        for (int i = 0; i < dataList.length; i++) {

                          debugPrint('${dataList[i].data()}');
                          final String sender = dataList[i].data()['sendBy'];

                          if (dataList[i].data()['type'] == 'img') {

                            if (startIndex == -1) {
                              startIndex = i;
                            }
                            if (previousSender.isEmpty) {
                              previousSender = sender;
                            }
                            if (sender != previousSender) {
                              debugPrint('======$sender');
                              // Check if there are 4 or more consecutive images with the same previous sender
                              if (endIndex - startIndex + 1 >= 4 && previousSender.isNotEmpty) {
                                List<QueryDocumentSnapshot<Map<String, dynamic>>?> imageGroup = dataList.sublist(startIndex, endIndex + 1);
                                groupedImages.add(imageGroup);
                              }
                              startIndex = i;
                              previousSender = sender;
                            }
                            endIndex = i;
                          } else {
                            // Check if there are 4 or more consecutive images with the same previous sender
                            if (endIndex - startIndex + 1 >= 4 && previousSender.isNotEmpty) {
                              List<QueryDocumentSnapshot<Map<String, dynamic>>?> imageGroup = dataList.sublist(startIndex, endIndex + 1);
                              groupedImages.add(imageGroup);
                            }

                            startIndex = -1;
                            endIndex = -1;
                            previousSender = '';
                          }
                        }

                        // Check if there are 4 or more consecutive images at the end of the list with the same previous sender
                        if (endIndex - startIndex + 1 >= 4 && previousSender.isNotEmpty) {
                          List<QueryDocumentSnapshot<Map<String, dynamic>>?> imageGroup = dataList.sublist(startIndex, endIndex + 1);
                          groupedImages.add(imageGroup);
                        }

                        debugPrint('Group: $groupedImages');


                        if (snapshot.data!.docs.isNotEmpty) {
                          lastData = snapshot.data!.docs.first;
                          // debugPrint(
                          //     '- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -');
                          // debugPrint(lastData.data().toString());
                        }

                        return Expanded(
                          child: ListView.builder(
                            reverse: true,
                            itemCount: groupedData.length,
                            padding: const EdgeInsets.only(bottom: 0),
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              DateTime date = groupedData.keys.elementAt(index);
                              List<Map<String,
                                  dynamic>> items = groupedData[date]!;

                              return Column(
                                // crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Header showing the date
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 5, horizontal: 8),
                                    decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12)
                                    ),
                                    child: Text(
                                      separateDate(date),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  // List of items for the date
                                  ListView.builder(
                                      shrinkWrap: true,
                                      reverse: true,
                                      physics: const NeverScrollableScrollPhysics(),
                                      itemCount: items.length,
                                      itemBuilder: (context, index) {
                                        Map<String,
                                            dynamic> data = items[index];
                                        String documentId = dataList
                                            .firstWhere((doc) =>
                                        doc.data().toString() == data.toString()).reference.id;
                                        //debugPrint('- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -');
                                        // read and unread message status change code
                                        if (auth.currentUser!.uid ==
                                            data['receiver'] &&
                                            data['opened'] == false) {
                                          Future.delayed(
                                              const Duration(seconds: 1))
                                              .then((value) {
                                            debugPrint(
                                                '--------------------- vale has been updated -------------------------');
                                            fireStore
                                                .collection('chatRoom')
                                                .doc(widget.chatRoomId)
                                                .collection('chats')
                                                .doc(documentId)
                                                .update({'opened': true});
                                            fireStore
                                                .collection('chatRoom')
                                                .doc(widget.chatRoomId)
                                                .update({
                                              'lastMessageCount': 0,
                                              'opened': true,
                                            });
                                          });
                                        }
                                        if (lastData!.data()['time'] ==
                                            data['time']) {
                                          Future.delayed(
                                              const Duration(seconds: 1))
                                              .then((value) {
                                            fireStore.collection('chatRoom')
                                                .doc(widget.chatRoomId).get()
                                                .then((value) {
                                              if (lastData != null) {
                                                if (value.data()!['opened'] !=
                                                    lastData.data()['opened']) {
                                                  // debugPrint(
                                                  //     'outer message -----------${value
                                                  //         .data().toString()}');
                                                  // debugPrint(
                                                  //     'outer message -----------${lastData
                                                  //         .data()}');
                                                  fireStore.collection(
                                                      'chatRoom').doc(
                                                      widget.chatRoomId).update(
                                                      {
                                                        'lastMessageCount': 0,
                                                        'opened': true,
                                                      });
                                                }
                                              }
                                            });
                                          });
                                        }

                                        String displayTime;
                                        if (data['time'] != null) {
                                          var stamp = data['time'];
                                          DateTime date = stamp.toDate();
                                          // debugPrint(' date ==>>$date');
                                          displayTime = formatDateTime(date);
                                        } else {
                                          debugPrint(
                                              '------------------time is empty');
                                          return Container();
                                        }
                                        var me = data['sendBy'] ==
                                            auth.currentUser!.uid;
                                        // checks if msg should be visible or not
                                        if (data['sendBy'] ==
                                            auth.currentUser!.uid &&
                                            data['isSenderMessageDeleted'] ==
                                                true) {
                                          return Container();
                                        } else
                                        if (data['isReceiverMessageDeleted'] ==
                                            true) {
                                          return Container();
                                        }
                                        else if (data['isPermanentlyDeleted'] ==
                                            true) {
                                          return GestureDetector(
                                            onLongPress: () {
                                              longPressedFunc(data: data,
                                                  document: documentId,
                                                  lastDataId: lastData!
                                                      .reference.id);
                                            },
                                            onTap: () =>
                                                onTapFunc(data: data,
                                                    document: documentId,
                                                    lastDataId: lastData!
                                                        .reference
                                                        .id),
                                            child: messageDisplay(
                                                isDeleted: true,
                                                selectedColor: selectedMessageList
                                                    .contains(documentId)
                                                    ? Colors.white.withOpacity(
                                                    0.4)
                                                    : Colors.transparent,
                                                me: me,
                                                open: data['opened'],
                                                message: me
                                                    ? 'You deleted this message'
                                                    : 'This message is deleted',
                                                time: displayTime,
                                                context: context),
                                          );
                                        }
                                        if (data['type'] == 'link') {
                                          return GestureDetector(
                                            onLongPress: () {
                                              longPressedFunc(data: data,
                                                  document: documentId,
                                                  lastDataId: lastData!
                                                      .reference.id);
                                            },
                                            onTap: () =>
                                                onTapFunc(data: data,
                                                    document: documentId,
                                                    lastDataId: lastData!
                                                        .reference
                                                        .id),
                                            child: Column(
                                              crossAxisAlignment:
                                              me
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  alignment: me ? Alignment
                                                      .centerRight : Alignment
                                                      .centerLeft,
                                                  // decoration: BoxDecoration(color: Colors.red),
                                                  // padding: EdgeInsets.only(left: me ? 30:0,right: me ?0:30),
                                                  color: selectedMessageList
                                                      .contains(documentId)
                                                      ? Colors.white
                                                      .withOpacity(0.4)
                                                      : Colors.transparent,
                                                  child: Container(
                                                    // foregroundDecoration: BoxDecoration(color: selectedColor),
                                                    constraints: BoxConstraints(
                                                        maxWidth: size.width *
                                                            0.8),
                                                    decoration: BoxDecoration(
                                                      borderRadius: borderRadius(me: me),
                                                      color: me
                                                          ? const Color(
                                                          0xffe0d5ff)
                                                          : const Color(
                                                          0xffebebeb),

                                                    ),
                                                    margin: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10,
                                                        vertical: 2),
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 5,
                                                        vertical: 8),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize
                                                          .min,
                                                      mainAxisAlignment: me
                                                          ? MainAxisAlignment
                                                          .end
                                                          : MainAxisAlignment
                                                          .start,
                                                      children: [
                                                        Container(),
                                                        Flexible(
                                                            child: AnyLinkPreview(
                                                              link: data['message'],
                                                              displayDirection: UIDirection
                                                                  .uiDirectionVertical,
                                                              showMultimedia: true,
                                                              bodyMaxLines: 5,
                                                              bodyTextOverflow: TextOverflow
                                                                  .ellipsis,
                                                              titleStyle: const TextStyle(
                                                                color: Colors
                                                                    .black,
                                                                fontWeight: FontWeight
                                                                    .bold,
                                                                fontSize: 15,
                                                              ),
                                                              bodyStyle: const TextStyle(
                                                                  color: Colors
                                                                      .black,
                                                                  fontSize: 12),
                                                              errorWidget: const Text(
                                                                  'Error'),
                                                              cache: const Duration(
                                                                  days: 7),
                                                              backgroundColor: me
                                                                  ? const Color(
                                                                  0xffe0d5ff)
                                                                  : const Color(
                                                                  0xffebebeb),
                                                              borderRadius: 12,
                                                              removeElevation: true,
                                                              // boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.grey)],// This disables tap event
                                                            )
                                                        ),
                                                        const SizedBox(
                                                          width: 5,)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                                // const SizedBox(height: 5,),
                                                Container(
                                                  alignment: me ? Alignment
                                                      .centerRight : Alignment
                                                      .centerLeft,
                                                  // color: Colors.green,
                                                  child: Container(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 10),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize
                                                          .min,
                                                      mainAxisAlignment: me
                                                          ? MainAxisAlignment
                                                          .end
                                                          : MainAxisAlignment
                                                          .start,
                                                      children: [
                                                        Text(displayTime,
                                                            style: const TextStyle(
                                                                fontSize: 10,
                                                                color: Colors
                                                                    .white),
                                                            textAlign: !me
                                                                ? TextAlign
                                                                .center
                                                                : TextAlign
                                                                .end),
                                                        me ? Icon(
                                                          Icons.check,
                                                          color: data['opened']
                                                              ? Colors.blue
                                                              : Colors.grey,
                                                          size: 18,
                                                        )
                                                            : const Icon(
                                                          Icons.check,
                                                          color: Colors
                                                              .transparent,
                                                          size: 18,)
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }

                                        if (data['type'] == 'text') {
                                          return GestureDetector(
                                            onLongPress: () {
                                              debugPrint(
                                                  'in long press of text');
                                              longPressedFunc(data: data,
                                                  document: documentId,
                                                  lastDataId: lastData!
                                                      .reference.id);
                                            },
                                            onTap: () =>
                                                onTapFunc(data: data,
                                                    document: documentId,
                                                    lastDataId: lastData!
                                                        .reference
                                                        .id),
                                            child: messageDisplay(
                                                selectedColor: selectedMessageList
                                                    .contains(documentId)
                                                    ? Colors.white.withOpacity(
                                                    0.4)
                                                    : Colors.transparent,
                                                me: me,
                                                open: data['opened'],
                                                message: data['message'],
                                                time: displayTime,
                                                context: context),
                                          );
                                        } else if (data['type'] == 'img' ) {
                                          if (data['receiverPath'] == 'none') {
                                            listOfDownloadImages?.add({
                                              'id': documentId.toString(),
                                              'showDownloading': false,
                                              'progress': 0.0
                                            });
                                          }
                                          // debugPrint(listOfDownloadImages.toString());
                                          int index = listOfDownloadImages!
                                              .indexWhere((item) =>
                                          item["id"] == documentId.toString());

                                          for (int i = 0; i < groupedImages.length; i++) {
                                            int index = groupedImages[i].indexWhere((image) => image!['time'] == data['time']);

                                            if (index != -1 )
                                              {
                                                // debugPrint('-----------$index ${groupedImages[i][index]!.data()} ');
                                              }
                                            if (index != -1 && index == 0) {
                                             // debugPrint('-----------$index ${groupedImages[i][index]!.data()['fileName']} ');
                                             return viewGridImages(imageList:groupedImages[i],me: me,
                                             onTap: (){
                                               Navigator.of(context).push(MaterialPageRoute(
                                                 builder: (context) => viewDetailsImage(imageList: groupedImages[i],
                                                   me: me,
                                                   displayTime: displayTime,
                                                   context: context,
                                                   updateState: (){
                                                   setState(() {
                                                   });
                                                   }
                                               ),));
                                             },
                                             );
                                            }
                                            if (index != -1 && index != 0 )
                                              {
                                                return Container();
                                              }
                                          }
                                          return GestureDetector(
                                            onLongPress: () {
                                              longPressedFunc(data: data,
                                                  document: documentId,
                                                  lastDataId: lastData!
                                                      .reference.id);
                                            },
                                            // onTap: ()=> onTapFunc(data: e),
                                            child: data['message'] != ''
                                                ? Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Align(
                                                  alignment: me
                                                      ? Alignment.centerRight
                                                      : Alignment.centerLeft,
                                                  child: Container(
                                                      alignment: me
                                                          ? Alignment
                                                          .centerRight
                                                          : Alignment
                                                          .centerLeft,
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 15,
                                                          vertical: 10),
                                                      width: double.infinity,
                                                      foregroundDecoration: BoxDecoration(
                                                        color: selectedMessageList
                                                            .contains(
                                                            documentId) ? Colors
                                                            .white.withOpacity(
                                                            0.4) : Colors
                                                            .transparent,
                                                      ),
                                                      decoration: BoxDecoration(
                                                          borderRadius: borderRadius(me: me)),
                                                      child: InkWell(
                                                        onTap: () async {
                                                          debugPrint(
                                                              'this is print');

                                                          // ProgressDialog name =  ProgressDialog(context: context);
                                                          // pdList.add(name);


                                                          if (data['receiverPath'] ==
                                                              'none') {
                                                            if(!me)
                                                              {
                                                                setState(() {
                                                                  listOfDownloadImages![index]["showDownloading"] =
                                                                  true;
                                                                });
                                                                String dir = (await getExternalStorageDirectory())
                                                                    !.path;
                                                                var dio = Dio();
                                                                await dio.download(
                                                                  data['message'],
                                                                  '$dir/${data['fileName']}',
                                                                  onReceiveProgress: (
                                                                      rec, total) {
                                                                    if (listOfDownloadImages![index]["progress"] !=
                                                                        (double
                                                                            .parse(
                                                                            (rec /
                                                                                total)
                                                                                .toStringAsFixed(
                                                                                1)))) {
                                                                      setState(() {
                                                                        listOfDownloadImages![index]["progress"] =
                                                                        (double
                                                                            .parse(
                                                                            (rec /
                                                                                total)
                                                                                .toStringAsFixed(
                                                                                1)));
                                                                        var progress = (double
                                                                            .parse(
                                                                            (rec /
                                                                                total)
                                                                                .toStringAsFixed(
                                                                                1)));
                                                                        debugPrint(
                                                                            progress
                                                                                .toString());
                                                                      });
                                                                    }
                                                                  },
                                                                );

                                                                await fireStore
                                                                    .collection(
                                                                    'chatRoom')
                                                                    .doc(widget
                                                                    .chatRoomId)
                                                                    .collection(
                                                                    'chats')
                                                                    .doc(documentId)
                                                                    .update({
                                                                  'receiverPath': '$dir/${data['fileName']}',
                                                                });
                                                              }
                                                          }

                                                            isLastMessageSelectedForDelete =
                                                            lastData!.reference
                                                                .id ==
                                                                documentId
                                                                ? true
                                                                : false;
                                                            if (selectedMessageList
                                                                .contains(
                                                                documentId)) {
                                                              debugPrint(
                                                                  'this is 1');
                                                              // Navigator.pop(context);
                                                              setState(() {
                                                                isReceiveMessageAdded =
                                                                data['receiver'] ==
                                                                    auth
                                                                        .currentUser!
                                                                        .uid
                                                                    ? true
                                                                    : isReceiveMessageAdded;
                                                                selectedMessageList
                                                                    .remove(
                                                                    documentId);
                                                              });
                                                              if (selectedMessageList
                                                                  .isEmpty) {
                                                                isReceiveMessageAdded =
                                                                false;
                                                              }
                                                            } else
                                                            if (selectedMessageList
                                                                .isNotEmpty &&
                                                                !selectedMessageList
                                                                    .contains(
                                                                    documentId)) {
                                                              debugPrint(
                                                                  'this is 2');

                                                              setState(() {
                                                                isReceiveMessageAdded =
                                                                data['receiver'] ==
                                                                    auth
                                                                        .currentUser!
                                                                        .uid
                                                                    ? true
                                                                    : isReceiveMessageAdded;
                                                                selectedMessageList
                                                                    .add(
                                                                    documentId);
                                                              });
                                                            }
                                                            else {
                                                              debugPrint(
                                                                  'this is 3');
                                                              
                                                              Navigator.push(context, MaterialPageRoute(
                                                                    builder: (
                                                                        context) {
                                                                      return displayOneImage(
                                                                        context: context,
                                                                        title:  me ? 'You' : '${widget.receiverName}',
                                                                        displayTime: displayTime,
                                                                        isTimeVisible: true,
                                                                        path:  me ? data['senderPath'] : data['receiverPath'],
                                                                        heroTag: data['message']
                                                                      );
                                                                    },
                                                                  ));
                                                            }

                                                        },
                                                        child: Stack(
                                                          children: [
                                                            Row(
                                                              // mainAxisSize: MainAxisSize.min,
                                                              mainAxisAlignment: me
                                                                  ? MainAxisAlignment
                                                                  .end
                                                                  : MainAxisAlignment
                                                                  .start,
                                                              children: [
                                                                Hero(
                                                                    tag:
                                                                    '${data['message']}',
                                                                    child: me ?
                                                                    Container(
                                                                      decoration: BoxDecoration(
                                                                          color: me
                                                                              ? const Color(
                                                                              0xffe0d5ff)
                                                                              : const Color(
                                                                              0xffebebeb),
                                                                          border: Border
                                                                              .all(
                                                                            width: 5,
                                                                            color: me
                                                                                ? const Color(
                                                                                0xffe0d5ff)
                                                                                : const Color(
                                                                                0xffebebeb),
                                                                          ),
                                                                          borderRadius: borderRadius(me: me)),
                                                                      child: ClipRRect(
                                                                        borderRadius: BorderRadius
                                                                            .circular(
                                                                            15),
                                                                        child: Image
                                                                            .file(
                                                                          File(
                                                                              data['senderPath']),
                                                                          errorBuilder: (
                                                                              context,
                                                                              error,
                                                                              stackTrace) {
                                                                            return const Icon(
                                                                              Icons
                                                                                  .error,
                                                                              color: Colors
                                                                                  .red,
                                                                              size: 25,);
                                                                          },
                                                                          height: 220,
                                                                          width: 220,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    )
                                                                        :
                                                                    data['receiverPath'] ==
                                                                        'none' ?
                                                                    Container(
                                                                      height: 220,
                                                                      width: 220,
                                                                      decoration: BoxDecoration(
                                                                          color: me
                                                                              ? const Color(
                                                                              0xffe0d5ff)
                                                                              : const Color(
                                                                              0xffebebeb),
                                                                          border: Border
                                                                              .all(
                                                                            width: 5,
                                                                            color: me
                                                                                ? const Color(
                                                                                0xffe0d5ff)
                                                                                : const Color(
                                                                                0xffebebeb),
                                                                          ),
                                                                          borderRadius: borderRadius(me: me)),
                                                                      child: ClipRRect(
                                                                        borderRadius: BorderRadius
                                                                            .circular(
                                                                            15),
                                                                        child: ImageFiltered(
                                                                          imageFilter: ImageFilter
                                                                              .blur(
                                                                              sigmaX: 3,
                                                                              sigmaY: 3),
                                                                          child: CachedNetworkImage(
                                                                            fit: BoxFit.cover,
                                                                            imageUrl: '${data['message']}',
                                                                            placeholder: (context,
                                                                                url) =>
                                                                            const Center(child: CircularProgressIndicator()),
                                                                            errorWidget: (context, url, error) =>
                                                                            const Icon(Icons.error),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    )
                                                                        :
                                                                    Container(
                                                                      decoration: BoxDecoration(
                                                                          color: me
                                                                              ? const Color(
                                                                              0xffe0d5ff)
                                                                              : const Color(
                                                                              0xffebebeb),
                                                                          border: Border
                                                                              .all(
                                                                            width: 5,
                                                                            color: me
                                                                                ? const Color(
                                                                                0xffe0d5ff)
                                                                                : const Color(
                                                                                0xffebebeb),
                                                                          ),
                                                                          borderRadius: borderRadius(me: me)),
                                                                      child: ClipRRect(
                                                                        borderRadius: BorderRadius
                                                                            .circular(
                                                                            15),
                                                                        child: Image
                                                                            .file(
                                                                          File(
                                                                              data['receiverPath']),
                                                                          height: 220,
                                                                          width: 220,
                                                                          fit: BoxFit
                                                                              .cover,
                                                                        ),
                                                                      ),
                                                                    )
                                                                ),
                                                              ],
                                                            ),
                                                            me ? Container()
                                                                : data['receiverPath'] !=
                                                                'none'
                                                                ? Container()
                                                                :
                                                            Align(
                                                              alignment: me
                                                                  ? Alignment
                                                                  .centerRight
                                                                  : Alignment
                                                                  .centerLeft,
                                                              child: Container(
                                                                alignment: Alignment
                                                                    .center,
                                                                height: 220,
                                                                width: 220,
                                                                decoration: BoxDecoration(
                                                                  // color: Colors.red,
                                                                    borderRadius: BorderRadius
                                                                        .circular(
                                                                        15)
                                                                ),
                                                                child: showProgressIndicator(
                                                                    value: listOfDownloadImages![index]["progress"],
                                                                    showDownloading: listOfDownloadImages![index]["showDownloading"]),
                                                              ),
                                                            )
                                                          ],
                                                        ),
                                                      )),
                                                ),
                                                Align(
                                                  alignment: me
                                                      ? Alignment.centerRight
                                                      : Alignment.centerLeft,
                                                  child: Padding(
                                                    padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 15,
                                                        vertical: 5),
                                                    child: Row(
                                                      mainAxisSize:
                                                      MainAxisSize.min,
                                                      crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                      children: [
                                                        Text(
                                                          displayTime,
                                                          style: const TextStyle(
                                                              fontSize: 10,
                                                              color: Colors
                                                                  .white),
                                                          textAlign: me
                                                              ? TextAlign.right
                                                              : TextAlign.left,
                                                        ),
                                                        me
                                                            ? Icon(
                                                          Icons.check,
                                                          color: data[
                                                          'opened']
                                                              ? Colors.blue
                                                              : Colors.grey,
                                                          size: 18,
                                                        )
                                                            : Container()
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            )
                                                : Container(
                                              alignment: me
                                                  ? Alignment.centerRight
                                                  : Alignment.centerLeft,
                                              child: Container(
                                                  height: 220,
                                                  width: 220,
                                                  decoration: BoxDecoration(
                                                    // color: Colors.red,
                                                      borderRadius: BorderRadius
                                                          .circular(15)
                                                  ),
                                                  child: const Center(
                                                      child: CircularProgressIndicator())
                                              ),
                                            ),
                                          );
                                        }
                                        else if (data['type'] == 'pdf') {
                                          if (data['receiverPath'] == 'none') {
                                            listOfDownloadPdf?.add({
                                              'id': documentId.toString(),
                                              'showDownloading': false,
                                              'progress': 0.0
                                            });
                                          }
                                          // debugPrint(listOfDownloadImages.toString());
                                          int index = listOfDownloadPdf!
                                              .indexWhere((item) =>
                                          item["id"] == documentId.toString());

                                          return GestureDetector(
                                            onLongPress: () {
                                              longPressedFunc(data: data,
                                                  document: documentId,
                                                  lastDataId: lastData!
                                                      .reference.id);
                                            },
                                            onTap: () =>
                                                onTapFunc(data: data,
                                                    document: documentId,
                                                    lastDataId: lastData!
                                                        .reference
                                                        .id),
                                            child: Column(
                                              children: [
                                                Container(
                                                  color: selectedMessageList
                                                      .contains(documentId)
                                                      ? Colors.white
                                                      .withOpacity(0.4)
                                                      : Colors.transparent,
                                                  padding: const EdgeInsets
                                                      .only(
                                                      top: 2,
                                                      right: 15,
                                                      left: 15,
                                                      bottom: 2),
                                                  alignment: me
                                                      ? Alignment.centerRight
                                                      : Alignment.centerLeft,
                                                  child: data['message'] == ''
                                                      ? me
                                                      ? const CircularProgressIndicator()
                                                      : Container()
                                                      : Container(
                                                      constraints: BoxConstraints(
                                                          maxWidth: size.width *
                                                              0.8),
                                                      width: size.width * 0.8,
                                                      decoration: BoxDecoration(
                                                          color: me
                                                              ? const Color(
                                                              0xffe0d5ff)
                                                              : const Color(
                                                              0xffebebeb),
                                                          border: Border.all(
                                                            width: 10,
                                                            color: me
                                                                ? const Color(
                                                                0xffe0d5ff)
                                                                : const Color(
                                                                0xffebebeb),
                                                          ),
                                                          borderRadius:borderRadius(me: me)),
                                                      child: InkWell(
                                                        onTap: () async {
                                                          debugPrint('print check ==> 1');
                                                          if (data['receiverPath'] ==
                                                              'none') {
                                                            debugPrint('print check ==> 2');
                                                           if(!me)
                                                             {
                                                               setState(() {
                                                                 listOfDownloadPdf![index]["showDownloading"] =
                                                                 true;
                                                               });

                                                               String dir = (await getExternalStorageDirectory())
                                                                   !.path;

                                                               var dio = Dio();
                                                               await dio.download(
                                                                 data['message'],
                                                                 '$dir/${data['fileName']}',
                                                                 onReceiveProgress: (
                                                                     rec, total) {
                                                                   if (listOfDownloadPdf![index]["progress"] !=
                                                                       (double
                                                                           .parse(
                                                                           (rec /
                                                                               total)
                                                                               .toStringAsFixed(
                                                                               1)))) {
                                                                     setState(() {
                                                                       listOfDownloadPdf![index]["progress"] =
                                                                       (double
                                                                           .parse(
                                                                           (rec /
                                                                               total)
                                                                               .toStringAsFixed(
                                                                               1)));
                                                                       var progress = (double
                                                                           .parse(
                                                                           (rec /
                                                                               total)
                                                                               .toStringAsFixed(
                                                                               1)));
                                                                       debugPrint(
                                                                           'ddddddddd ${progress
                                                                               .toString()}');
                                                                     });
                                                                   }
                                                                 },
                                                               );

                                                               await fireStore
                                                                   .collection(
                                                                   'chatRoom')
                                                                   .doc(widget
                                                                   .chatRoomId)
                                                                   .collection(
                                                                   'chats')
                                                                   .doc(documentId)
                                                                   .update({
                                                                 'receiverPath': '$dir/${data['fileName']}',
                                                               });
                                                             }
                                                          }

                                                            debugPrint('print check ==> 3');
                                                            if (selectedMessageList
                                                                .contains(
                                                                documentId)) {
                                                              // Navigator.pop(context);
                                                              setState(() {
                                                                isReceiveMessageAdded =
                                                                data['receiver'] ==
                                                                    auth
                                                                        .currentUser!
                                                                        .uid
                                                                    ? true
                                                                    : isReceiveMessageAdded;
                                                                selectedMessageList
                                                                    .remove(
                                                                    documentId);
                                                              });
                                                            }
                                                            else {
                                                              debugPrint('print check ==> 4');
                                                              debugPrint('this is path of other file => ${me
                                                                  ? data['senderPath']
                                                                  : data['receiverPath']}');
                                                              await OpenFilex
                                                                  .open(me
                                                                  ? data['senderPath']
                                                                  : data['receiverPath']);
                                                            }

                                                        },
                                                        child: Row(
                                                          mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .start,
                                                          mainAxisSize:
                                                          MainAxisSize.min,
                                                          children: [
                                                            me
                                                                ? const CircleAvatar(
                                                                radius: 23,
                                                                backgroundColor:
                                                                Colors.white,
                                                                child: Icon(
                                                                    FontAwesomeIcons
                                                                        .filePdf,
                                                                    size: 25,
                                                                    color: Colors
                                                                        .blueGrey))
                                                                : data['receiverPath'] !=
                                                                'none'
                                                                ? const CircleAvatar(
                                                                radius: 23,
                                                                backgroundColor:
                                                                Colors.white,
                                                                child: Icon(
                                                                    FontAwesomeIcons
                                                                        .filePdf,
                                                                    size: 25,
                                                                    color: Colors
                                                                        .blueGrey))
                                                                :
                                                            SizedBox(
                                                              height: 45,
                                                              width: 45,
                                                              child: showProgressIndicator(
                                                                  value: listOfDownloadPdf![index]["progress"],
                                                                  showDownloading: listOfDownloadPdf![index]["showDownloading"]),
                                                            ),
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            Column(
                                                              mainAxisSize:
                                                              MainAxisSize.min,
                                                              crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                              children: [
                                                                SizedBox(
                                                                  width: size
                                                                      .width *
                                                                      0.58,
                                                                  child: Text(
                                                                    '${data['fileName']}',
                                                                    overflow: TextOverflow
                                                                        .ellipsis,
                                                                    style:
                                                                    const TextStyle(
                                                                        fontSize: 15,
                                                                        color: Colors
                                                                            .black),
                                                                  ),
                                                                ),
                                                                Text(
                                                                  '${data['type']}',
                                                                  style:
                                                                  const TextStyle(
                                                                      fontSize: 15,
                                                                      color: Colors
                                                                          .black),
                                                                ),
                                                              ],
                                                            ),
                                                          ],
                                                        ),
                                                      )),
                                                ),
                                                 Align(
                                                  alignment: me
                                                      ? Alignment.centerRight
                                                      : Alignment.centerLeft,
                                                  child: Padding(
                                                    padding: const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 15,
                                                        vertical: 5),
                                                    child: Row(
                                                      mainAxisSize: MainAxisSize
                                                          .min,
                                                      children: [
                                                        Text(
                                                          displayTime,
                                                          style: const TextStyle(
                                                              fontSize: 10,
                                                              color: Colors
                                                                  .white),
                                                          textAlign: me
                                                              ? TextAlign.right
                                                              : TextAlign.left,
                                                        ),
                                                        me
                                                            ? Icon(
                                                          Icons.check,
                                                          color: data['opened']
                                                              ? Colors.blue
                                                              : Colors.grey,
                                                          size: 18,
                                                        )
                                                            : Container()
                                                      ],
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        } else {
                                          if (data['receiverPath'] == 'none') {
                                            listOfDownloadDocs?.add({
                                              'id': documentId.toString(),
                                              'showDownloading': false,
                                              'progress': 0.0
                                            });
                                          }

                                          int index = listOfDownloadDocs!
                                              .indexWhere((item) =>
                                          item["id"] == documentId.toString());

                                          return GestureDetector(
                                            onLongPress: () {
                                              longPressedFunc(data: data,
                                                  document: documentId,
                                                  lastDataId: lastData!
                                                      .reference.id);
                                            },
                                            onTap: () =>
                                                onTapFunc(data: data,
                                                    document: documentId,
                                                    lastDataId: lastData!
                                                        .reference
                                                        .id),
                                            child: Container(
                                              color: selectedMessageList
                                                  .contains(documentId)
                                                  ? Colors.white.withOpacity(
                                                  0.4)
                                                  : Colors.transparent,
                                              child: Column(
                                                children: [
                                                  Container(
                                                    padding: const EdgeInsets
                                                        .only(
                                                        top: 10,
                                                        left: 15,
                                                        right: 15,
                                                      bottom: 10
                                                    ),
                                                    alignment: me
                                                        ? Alignment.centerRight
                                                        : Alignment.centerLeft,
                                                    child: data['message'] == ''
                                                        ? me
                                                        ? const CircularProgressIndicator()
                                                        : Container()
                                                        : Container(
                                                        constraints: BoxConstraints(
                                                            maxWidth: size
                                                                .width * 0.8),
                                                        width: size.width * 0.8,
                                                        decoration: BoxDecoration(
                                                            color: me
                                                                ? const Color(
                                                                0xffe0d5ff)
                                                                : const Color(
                                                                0xffebebeb),
                                                            border: Border.all(
                                                              width: 10,
                                                              color: me
                                                                  ? const Color(
                                                                  0xffe0d5ff)
                                                                  : const Color(
                                                                  0xffebebeb),
                                                            ),
                                                            borderRadius: borderRadius(me: me)),
                                                        child: InkWell(
                                                          onTap: () async {
                                                            if (data['receiverPath'] ==
                                                                'none') {
                                                              if(!me)
                                                                {
                                                                  setState(() {
                                                                    listOfDownloadDocs![index]["showDownloading"] =
                                                                    true;
                                                                  });

                                                                  String dir = (await getExternalStorageDirectory())
                                                                      !.path;

                                                                  var dio = Dio();
                                                                  await dio
                                                                      .download(
                                                                    data['message'],
                                                                    '$dir/${data['fileName']}',
                                                                    onReceiveProgress: (
                                                                        rec,
                                                                        total) {
                                                                      if (listOfDownloadDocs![index]["progress"] !=
                                                                          (double
                                                                              .parse(
                                                                              (rec /
                                                                                  total)
                                                                                  .toStringAsFixed(
                                                                                  1)))) {
                                                                        setState(() {
                                                                          listOfDownloadDocs![index]["progress"] =
                                                                          (double
                                                                              .parse(
                                                                              (rec /
                                                                                  total)
                                                                                  .toStringAsFixed(
                                                                                  1)));
                                                                          var progress = (double
                                                                              .parse(
                                                                              (rec /
                                                                                  total)
                                                                                  .toStringAsFixed(
                                                                                  1)));
                                                                          debugPrint(
                                                                              'ddddddddd ${progress
                                                                                  .toString()}');
                                                                        });
                                                                      }
                                                                    },
                                                                  );

                                                                  await fireStore
                                                                      .collection(
                                                                      'chatRoom')
                                                                      .doc(widget
                                                                      .chatRoomId)
                                                                      .collection(
                                                                      'chats')
                                                                      .doc(
                                                                      documentId)
                                                                      .update({
                                                                    'receiverPath': '$dir/${data['fileName']}',
                                                                  });
                                                                }
                                                            }
                                                            else {
                                                              if (selectedMessageList
                                                                  .contains(
                                                                  documentId)) {
                                                                // Navigator.pop(context);
                                                                setState(() {
                                                                  isReceiveMessageAdded =
                                                                  data['receiver'] ==
                                                                      auth
                                                                          .currentUser!
                                                                          .uid
                                                                      ? true
                                                                      : isReceiveMessageAdded;
                                                                  selectedMessageList
                                                                      .remove(
                                                                      documentId);
                                                                });
                                                              }
                                                              else {
                                                                debugPrint('this is path of other file => ${me
                                                                    ? data['senderPath']
                                                                    : data['receiverPath']}');
                                                                await OpenFilex.open(me ? data['senderPath'] : data['receiverPath']);
                                                              }
                                                            }
                                                          },
                                                          child: Row(
                                                            mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                            mainAxisSize:
                                                            MainAxisSize.min,
                                                            children: [
                                                              me
                                                                  ? const CircleAvatar(
                                                                  radius: 23,
                                                                  backgroundColor:
                                                                  Colors.white,
                                                                  child: Icon(
                                                                      FontAwesomeIcons
                                                                          .file,
                                                                      size: 25,
                                                                      color: Colors
                                                                          .blueGrey))
                                                                  : data['receiverPath'] !=
                                                                  'none'
                                                                  ? const CircleAvatar(
                                                                  radius: 23,
                                                                  backgroundColor:
                                                                  Colors.white,
                                                                  child: Icon(
                                                                      FontAwesomeIcons
                                                                          .file,
                                                                      size: 25,
                                                                      color: Colors
                                                                          .blueGrey))
                                                                  :
                                                              SizedBox(
                                                                height: 45,
                                                                width: 45,
                                                                child: showProgressIndicator(
                                                                    value: listOfDownloadDocs![index]["progress"],
                                                                    showDownloading: listOfDownloadDocs![index]["showDownloading"]),
                                                              ),
                                                              const SizedBox(
                                                                width: 10,
                                                              ),
                                                              Column(
                                                                mainAxisSize:
                                                                MainAxisSize
                                                                    .min,
                                                                crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                                children: [
                                                                  SizedBox(
                                                                    width: size
                                                                        .width *
                                                                        0.58,
                                                                    child: Text(
                                                                      '${data['fileName']}',
                                                                      overflow: TextOverflow
                                                                          .ellipsis,
                                                                      style:
                                                                      const TextStyle(
                                                                          fontSize: 15,
                                                                          color: Colors
                                                                              .black),
                                                                    ),
                                                                  ),
                                                                  Text(
                                                                    '${data['type']}',
                                                                    style:
                                                                    const TextStyle(
                                                                        fontSize: 15,
                                                                        color: Colors
                                                                            .black),
                                                                  ),
                                                                ],
                                                              ),
                                                            ],
                                                          ),
                                                        )),
                                                  ),
                                                  Align(
                                                    alignment: me
                                                        ? Alignment.centerRight
                                                        : Alignment.centerLeft,
                                                    child: Padding(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                          horizontal: 15,
                                                          vertical: 5),
                                                      child: Row(
                                                        mainAxisSize: MainAxisSize
                                                            .min,
                                                        children: [
                                                          Text(
                                                            displayTime,
                                                            style: const TextStyle(
                                                                fontSize: 10,
                                                                color: Colors
                                                                    .white),
                                                            textAlign: me
                                                                ? TextAlign
                                                                .right
                                                                : TextAlign
                                                                .left,
                                                          ),
                                                          me
                                                              ? Icon(
                                                            Icons.check,
                                                            color: data['opened']
                                                                ? Colors.blue
                                                                : Colors.grey,
                                                            size: 18,
                                                          )
                                                              : Container()
                                                        ],
                                                      ),
                                                    ),
                                                  ) ,
                                                ],
                                              ),
                                            ),
                                          );
                                        }
                                      }
                                  ),
                                  // const Divider(),
                                  // const SizedBox(
                                  //   height: 60,
                                  // )
                                ],
                              );
                            },
                          ),
                        );
                      }
                      else {
                        return const Text('something went wrong!!');
                      }
                    }
                ),

                const SizedBox(
                  height: 60,
                )
              ],
            ),
            Align(
                alignment: Alignment.bottomCenter,
                child: bottomTextField(context)),
          ]),
        ),
      ),
    );
  }


  Widget viewGridImages({List<QueryDocumentSnapshot<Map<String, dynamic>>?>? imageList,me,onTap})
  {
    return Container(
      height: 250,
      width: 250,
      alignment: me
          ? Alignment.centerRight
          : Alignment.centerLeft,
      padding: const EdgeInsets
          .symmetric(
          horizontal: 15,
          vertical: 10),
      child: InkWell(
        onTap: onTap,
        child: Container(

          decoration: BoxDecoration(
              color: me
                  ? const Color(0xffe0d5ff)
                  : const Color(0xffebebeb),
              border: Border.all(
                width: 5,
                color: me
                    ? const Color(0xffe0d5ff)
                    : const Color(0xffebebeb),
              ),
              borderRadius: me
                  ? const BorderRadius.only(
                  topRight: Radius.circular(15),
                  topLeft: Radius.circular(15),
                  bottomLeft: Radius.circular(15))
                  : const BorderRadius.only(
                  topRight: Radius.circular(15),
                  topLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                smallImage(imageObject: imageList![0],me: me,),
                smallImage(imageObject: imageList[1],me: me,)
              ],),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                smallImage(imageObject: imageList[2],me: me,),
                  Stack(
                    children: [
                      smallImage(imageObject: imageList[3],me: me,),
                      imageList.length > 3 ?
                      Container(
                        alignment: Alignment.center,
                        width: 110,
                        height: 110,
                        child: Container(
                            alignment: Alignment.center,
                          width: 105,
                          height: 105,
                            decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Text('+${imageList.length - 3}',style: const TextStyle(color: Colors.white,fontSize: 40),)),
                      )
                          : Container()
                    ],
                  )
              ],),
            ],
          ),
        ),
      ),
    );
  }

  Widget smallImage({QueryDocumentSnapshot<Map<String, dynamic>>? imageObject,me})
  {
    // Size size = MediaQuery.of(context).size;
    return Container(
      width: 110,
      height: 110,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(15)),
      child:
      me ? ClipRRect(
        borderRadius: BorderRadius
            .circular(
            15),
        child: Image
            .file(
          File(imageObject!['senderPath']),
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.error,
              color: Colors.red,
              size: 25,);},
          height: 110,
          width: 110,
          fit: BoxFit.cover,
        ),
      ) : imageObject!['receiverPath'] == 'none' ?
      ClipRRect(
        borderRadius: BorderRadius.circular(
            15),
        child: ImageFiltered(
          imageFilter: ImageFilter.blur(
              sigmaX: 3,
              sigmaY: 3),
          child:
          CachedNetworkImage(
            height: 110,
            width: 110,
            fit: BoxFit.cover,
            imageUrl:
            imageObject['message'],
            placeholder: (context, url) => const Icon(Icons.image,size: 110),
            errorWidget: (context, url, error) => const Icon(Icons.error),
          ),
        ),
      )
          :
      ClipRRect(
        borderRadius: BorderRadius
            .circular(
            15),
        child: Image
            .file(
          File(imageObject['receiverPath']),
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.error,
              color: Colors.red,
              size: 25,);},
          height: 110,
          width: 110,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget viewDetailsImage({List<QueryDocumentSnapshot<Map<String, dynamic>>?>? imageList,me,displayTime,context,updateState})
  {
    List<QueryDocumentSnapshot<Map<String, dynamic>>?>? displayImgList = imageList;
    return SafeArea(
      child:  StatefulBuilder(
        builder: (context, setState)  {
          debugPrint('the length of displayImages => ${displayImgList!.length}');

          return Scaffold(
            body: Stack(
              children: [
                ListView.builder(
                  itemCount: displayImgList.length,
                  shrinkWrap: true,
                  itemBuilder: (context, index) {
                    int indexId = listOfDownloadImages!.indexWhere((item) =>
                    item["id"] == displayImgList[index]!.reference.id.toString());
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Stack(
                        children: [
                          Hero(
                              tag:
                              '${displayImgList[index]!['message']}',
                              child: me ?
                              InkWell(
                                onTap: (){
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (
                                        context) {
                                      return displayOneImage(
                                          context: context,
                                          title: 'You',
                                          displayTime: displayTime,
                                          isTimeVisible: true,
                                          path:  displayImgList[index]!['senderPath'],
                                          heroTag: displayImgList[index]!['message']
                                      );
                                    },
                                  ));
                                },
                                child: Image.file(
                                  File(displayImgList[index]!['senderPath']),
                                  errorBuilder: (context, error, stackTrace) {
                                    return const Icon(
                                      Icons.error,
                                      color: Colors.red,
                                      size: 25,);
                                  },
                                  width: MediaQuery.of(context).size.width,
                                  // width: double.infinity,
                                  fit: BoxFit.fitWidth,
                                ),
                              )
                                  :
                              displayImgList[index]!['receiverPath'] ==
                                  'none' ?
                              ImageFiltered(
                                imageFilter: ImageFilter
                                    .blur(
                                    sigmaX: 3,
                                    sigmaY: 3),
                                child:
                                CachedNetworkImage(
                                  // width: double.infinity,
                                  width: MediaQuery.of(context).size.width,
                                  fit: BoxFit.fitWidth,
                                  imageUrl: displayImgList[index]!['message'],
                                  placeholder: (context, url) =>  const Center(child: CircularProgressIndicator()),
                                  errorWidget: (context, url, error) => const Icon(Icons.error),
                                ),
                              )
                                  :
                              InkWell(
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (
                                        context) {
                                      return displayOneImage(
                                          context: context,
                                          title: '${widget.receiverName}',
                                          displayTime: displayTime,
                                          isTimeVisible: true,
                                          path:  displayImgList[index]!['receiverPath'],
                                          heroTag: displayImgList[index]!['message']
                                      );
                                    },
                                  ));
                                },
                                child: Image.file(File(
                                      displayImgList[index]!['receiverPath']),
                                  width: MediaQuery.of(context).size.width,
                                  // fit: BoxFit.cover,
                                  // width: double.infinity,
                                  fit: BoxFit.fitWidth,
                                ),
                              )
                          ),
                          me ? Container()
                              : displayImgList[index]!['receiverPath'] != 'none'
                              ? Container()
                              :
                          Positioned.fill(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                // color: Colors.red,
                                  borderRadius: BorderRadius
                                      .circular(
                                      15)
                              ),
                              child: InkWell(
                                onTap: () async {
                                  if (displayImgList[index]!['receiverPath'] ==
                                      'none') {
                                    setState(() {
                                      listOfDownloadImages![indexId]["showDownloading"] = true;
                                      // oldData = displayImgList[index]!;
                                    });
                                    String dir = (await getExternalStorageDirectory())!.path;
                                    var dio = Dio();
                                    await dio.download(
                                      displayImgList[index]!['message'],
                                      '$dir/${displayImgList[index]!['fileName']}',
                                      onReceiveProgress: (rec, total) {
                                        if (listOfDownloadImages![indexId]["progress"] !=
                                            (double.parse(
                                                (rec / total).toStringAsFixed(1)))) {
                                          setState(() {
                                            listOfDownloadImages![indexId]["progress"] =
                                            (double
                                                .parse(
                                                (rec / total).toStringAsFixed(1)));
                                            var progress = (double
                                                .parse(
                                                (rec / total).toStringAsFixed(1)));
                                            debugPrint(
                                                progress.toString());
                                          });
                                        }
                                      },
                                    );
                                    await fireStore.collection('chatRoom').doc(widget.chatRoomId)
                                        .collection(
                                        'chats')
                                        .doc(displayImgList[index]!.reference.id)
                                        .update({
                                      'receiverPath': '$dir/${displayImgList[index]!['fileName']}',
                                    });

                                    await fireStore.collection('chatRoom').doc(widget.chatRoomId).collection('chats').get().then((value) {

                                      for (var element in value.docs) {
                                        if(element.id == displayImgList[index]!.id)
                                          {
                                            setState((){
                                              displayImgList[index] = element;
                                            });
                                          }
                                      }
                                    });

                                    setState(() {
                                      debugPrint('new data => ${displayImgList[index]!['receiverPath']}');
                                      debugPrint('new data => ${displayImgList[index]!['message']}');

                                    });
                                  }
                                  // updateState();
                                },
                                child: showProgressIndicator(
                                    value: listOfDownloadImages![indexId]["progress"],
                                    showDownloading: listOfDownloadImages![indexId]["showDownloading"]),
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },),
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    color: Colors.black38,
                    padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 10),
                    child: Row(
                        children: [
                          InkWell(
                              onTap: () =>
                                  Navigator.of(context).pop(),
                              child: const Icon(
                                Icons.arrow_back,
                                color: Colors.white,
                              )),
                          const SizedBox(
                            width:
                            15,
                          ),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment
                                .start,
                            children: [
                              SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.8,
                                  child: Text(
                                    me ? 'You' : '${widget.receiverName}',
                                    style: const TextStyle(
                                        color: Colors
                                            .white,
                                        fontSize: 18),)),
                              Text(
                                displayTime,
                                style: const TextStyle(
                                    color: Colors
                                        .white,
                                    fontSize: 13),)
                            ],
                          )
                        ]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String formatDateTime(DateTime dateTime) {
    final formattedTime = DateFormat('h:mm a').format(dateTime);
    return formattedTime;
  }

  longPressedFunc({Map<String, dynamic>? data, document, lastDataId}) {
    isLastMessageSelectedForDelete = lastDataId == document ? true : false;
    setState(() {
      isReceiveMessageAdded =
      data!['receiver'] == auth.currentUser!.uid ? true : isReceiveMessageAdded;
      selectedMessageList.add(document);
    });
  }

  onTapFunc({Map<String, dynamic>? data, document, lastDataId}) {
    isLastMessageSelectedForDelete = lastDataId == document ? true : false;
    debugPrint('print check ==> 0 in on tap function');

    if (selectedMessageList.isNotEmpty &&
        !selectedMessageList.contains(document)) {
      setState(() {
        isReceiveMessageAdded = data!['receiver'] == auth.currentUser!.uid
            ? true
            : isReceiveMessageAdded;
        selectedMessageList.add(document);
      });
    }
    else {
      setState(() {
        isReceiveMessageAdded = data!['receiver'] == auth.currentUser!.uid
            ? true
            : isReceiveMessageAdded;
        selectedMessageList.remove(document);
        if (selectedMessageList.isEmpty) {
          isReceiveMessageAdded = false;
        }
      });
    }
  }

  Widget messageDisplay(
      {me, message, time, context, open, isDeleted = false, selectedColor}) {
    Size size = MediaQuery
        .of(context)
        .size;
    return Column(
      crossAxisAlignment:
      me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          alignment: me ? Alignment.centerRight : Alignment.centerLeft,
          // decoration: BoxDecoration(color: Colors.red),
          // padding: EdgeInsets.only(left: me ? 30:0,right: me ?0:30),
          color: selectedColor,
          child: Container(
            // foregroundDecoration: BoxDecoration(color: selectedColor),
            constraints: BoxConstraints(maxWidth: size.width * 0.8),
            decoration: BoxDecoration(
              borderRadius: borderRadius(me: me),
              color: me ? const Color(0xffe0d5ff) : const Color(0xffebebeb),

            ),
            margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment
                  .start,
              children: [
                isDeleted ?
                const Icon(Icons.not_interested, size: 20,)
                    : Container(),
                isDeleted ?
                const SizedBox(width: 8,)
                    : Container(),
                Flexible(
                  child: Text(
                    message,
                    style: const TextStyle(color: Colors.black, fontSize: 15),
                  ),
                ),
                const SizedBox(width: 5,)
              ],
            ),
          ),
        ),
        // const SizedBox(height: 5,),
        Container(
          alignment: me ? Alignment.centerRight : Alignment.centerLeft,
          // color: Colors.green,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: me ? MainAxisAlignment.end : MainAxisAlignment
                  .start,
              children: [
                Text(time,
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                    textAlign: !me ? TextAlign.center : TextAlign.end),
                me && isDeleted == false ? Icon(
                  Icons.check,
                  color: open ? Colors.blue : Colors.grey,
                  size: 18,
                )
                    : const Icon(
                  Icons.check, color: Colors.transparent, size: 18,)
              ],
            ),
          ),
        ),
      ],
    );
  }

  String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours < 1) {
        if (difference.inMinutes < 1) {
          return "Just now";
        } else {
          return "${difference.inMinutes} minutes ago";
        }
      } else {
        return "${difference.inHours} hours ago";
      }
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else {
      return DateFormat("MMMM d, h:mm a").format(dateTime);
    }
  }

  Widget showProgressIndicator({value, showDownloading}) {
    if (showDownloading) {
      return Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(radius: 22, backgroundColor: Colors.white,
              child: CircularProgressIndicator(
                value: value, color: Colors.green,)),
          Text('${value * 100} %', style: const TextStyle(fontSize: 11),)
        ],
      );
    }
    else {
      return const CircleAvatar(radius: 22,
          backgroundColor: Colors.white,
          child: Icon(Icons.download));
    }
  }

  Future<void> launchUrlNew(url) async {
    if (!await launchUrl(Uri.parse(url),
        mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }


  Widget bottomTextField(BuildContext context) {
    return Container(
        height: 60,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(15), topLeft: Radius.circular(15))),
        child: Row(
          children: [
            const SizedBox(
              width: 5,
            ),
            InkWell(
                onTap: () {
                  _getFromCamera();
                },
                child: const Icon(
                  Icons.camera_alt,
                  color: Colors.blueGrey,
                )),
            const SizedBox(
              width: 5,
            ),
            Expanded(
                child: TextFormField(
                  maxLines: 4,
                  minLines: 1,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  controller: messageText,
                  decoration: const InputDecoration(
                    hintText: 'Type something...',
                    border: InputBorder.none,
                  ),
                )),
            const SizedBox(
              width: 5,
            ),
            InkWell(
                onTap: () {
                  filePikerFunction();
                },
                child: const Icon(
                  Icons.attach_file,
                  color: Colors.blueGrey,
                )),
            const SizedBox(
              width: 10,
            ),
            InkWell(
                onTap: () => imageFromGallery(),
                child: const Icon(
                  Icons.image,
                  color: Colors.blueGrey,
                )),
            const SizedBox(
              width: 15,
            ),
            InkWell(
                onTap: () {
                  debugPrint('in click of send button');
                  debugPrint('selectedMessageList $selectedMessageList');
                  if (messageText.text.isNotEmpty) {
                    onMessageSend(context, messageText.text);
                  }
                },
                child: const Icon(
                  Icons.send,
                  color: Colors.blueGrey,
                ))
          ],
        ));
  }

  Future filePikerFunction() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();
    var fileRef = const Uuid().v1();
    if (result != null) {
      File file = File(result.files.single.path!);
      // debugPrint('files length ${file.length}');
      debugPrint('files length $file');
      var status = 1;
      String filename = file.path
          .split('/')
          .last;
      var extensionType = filename
          .split('.')
          .last;
      debugPrint(extensionType);
      var ref = FirebaseStorage.instance.ref().child('files').child(filename);

      await fireStore
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(fileRef)
          .set({
        'sendBy': auth.currentUser!.uid,
        'receiver': widget.userRefId,
        'senderName': auth.currentUser!.displayName,
        'receiverName': widget.receiverName,
        'message': '',
        'type': extensionType,
        'time': FieldValue.serverTimestamp(),
        'opened': false,
        'isSenderMessageDeleted': false,
        'isReceiverMessageDeleted': false,
        'isPermanentlyDeleted': false,
        'size': 'none',
        'path': 'none',
        'senderPath': 'none',
        'receiverPath': 'none',
        'fileName': 'none'
      });

      var uploadTask = await ref.putFile(file).catchError(() async {
        await fireStore
            .collection('chatRoom')
            .doc(widget.chatRoomId)
            .collection('chats')
            .doc(filename)
            .delete();

        status = 0;
        debugPrint('error in uploadTask');
      });

      if (status == 1) {
        int unreadMessage;
        var fileName = basename(file.path);
        var fileUrl = await uploadTask.ref.getDownloadURL();
        var metaData = await uploadTask.ref.getMetadata();
        debugPrint(fileUrl);

        String dir = (await getExternalStorageDirectory())!.path;
        File fileDef = File('$dir/$fileName');
        await fileDef.create(recursive: true);
        Uint8List bytes = await file.readAsBytes();
        await fileDef.writeAsBytes(bytes);

        await fireStore
            .collection('chatRoom')
            .doc(widget.chatRoomId)
            .collection('chats')
            .doc(fileRef)
            .update({
          'message': fileUrl,
          'size': metaData.size! / 1048576,
          'senderPath': '$dir/$fileName',
          'receiverPath': 'none',
          'fileName': fileName
        });
        fireStore
            .collection('chatRoom')
            .doc(widget.chatRoomId)
            .get()
            .then((value) {
          debugPrint('printing value ----');
          debugPrint(value.data().toString());
          if (value.data() != null) {
            unreadMessage = value.data()!['lastMessageCount'];
          } else {
            unreadMessage = 0;
          }
          unreadMessage++;
          debugPrint(fileUrl);
          fireStore.collection('chatRoom').doc(widget.chatRoomId).set({
            'sendBy': auth.currentUser!.uid,
            'receiver': widget.userRefId,
            'senderName': auth.currentUser!.displayName,
            'receiverName': widget.receiverName,
            'lastMessage': extensionType,
            'lastMessageCount': unreadMessage,
            'type': extensionType,
            'time': FieldValue.serverTimestamp(),
            'opened': false,
            'chatRoomId': widget.chatRoomId,
            'isSenderMessageDeleted': false,
            'isReceiverMessageDeleted': false,
            'isPermanentlyDeleted': false
          });
        });
        callOnFcmApiSendPushNotifications(
            deviceToken: widget.deviceToken,
            type: extensionType,
            message: extensionType);
      }
    } else {
      // User canceled the picker
      debugPrint('*** File picker was closed ***');
    }
  }

  // picking file after this create preview for and send button,
// show in chat document download option
  onMessageSend(BuildContext context, message) {
    messageText.clear();
    int unreadMessage;
    debugPrint('in function call');
    if (message.trim() != '' && message.trim() != ' ') {
      debugPrint('in click of if ');
      fireStore
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .get()
          .then((value) {
        debugPrint('printing value ----');
        debugPrint(value.data().toString());
        if (value.data() != null) {
          unreadMessage = value.data()!['lastMessageCount'];
          unreadMessage++;
          debugPrint('in click of if 2 in then');
          fireStore.collection('chatRoom').doc(widget.chatRoomId).set({
            'sendBy': auth.currentUser!.uid,
            'receiver': widget.userRefId,
            'senderName': auth.currentUser!.displayName,
            'receiverName': widget.receiverName,
            // 'lastMessage': messageText.text.trim(),
            'lastMessage': message.trim(),
            'lastMessageCount': unreadMessage,
            'type': AnyLinkPreview.isValidLink(
              message.trim(), protocols: ['http', 'https'],) ? 'link' : 'text',
            'time': FieldValue.serverTimestamp(),
            'opened': false,
            'chatRoomId': widget.chatRoomId,
            'isSenderMessageDeleted': false,
            'isReceiverMessageDeleted': false,
            'isPermanentlyDeleted': false
          });
          callOnFcmApiSendPushNotifications(
              deviceToken: widget.deviceToken, type: 'text', message: message);
          messageText.clear();
        } else {
          unreadMessage = 0;
          unreadMessage++;
          debugPrint('in click of if 2 in then');
          fireStore.collection('chatRoom').doc(widget.chatRoomId).set({
            'sendBy': auth.currentUser!.uid,
            'receiver': widget.userRefId,
            'senderName': auth.currentUser!.displayName,
            'receiverName': widget.receiverName,
            // 'lastMessage': messageText.text.trim(),
            'lastMessage': message.trim(),
            'lastMessageCount': unreadMessage,
            'type': AnyLinkPreview.isValidLink(
              message.trim(), protocols: ['http', 'https'],) ? 'link' : 'text',
            'time': FieldValue.serverTimestamp(),
            'opened': false,
            'chatRoomId': widget.chatRoomId,
            'isSenderMessageDeleted': false,
            'isReceiverMessageDeleted': false,
            'isPermanentlyDeleted': false
          });
          callOnFcmApiSendPushNotifications(
              deviceToken: widget.deviceToken, type: 'text', message: message);
          messageText.clear();
        }
      });

      debugPrint('in click of if 1');
      fireStore
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .add({
        'sendBy': auth.currentUser!.uid,
        'receiver': widget.userRefId,
        'senderName': auth.currentUser!.displayName,
        'receiverName': widget.receiverName,
        // 'message': messageText.text.trim(),
        'message': message.trim(),
        'type': AnyLinkPreview.isValidLink(
          message.trim(), protocols: ['http', 'https'],) ? 'link' : 'text',
        'time': FieldValue.serverTimestamp(),
        'opened': false,
        'isSenderMessageDeleted': false,
        'isReceiverMessageDeleted': false,
        'isPermanentlyDeleted': false
      }).then((value) {
        // sendButton = true;
        messageText.clear();
      });
    } else {
      debugPrint('in click of else');
      //ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter something first')));
    }

    //return Future(() => null);
  }

  imageFromGallery() async {
    ImagePicker imgPicker = ImagePicker();
    await imgPicker.pickImage(source: ImageSource.gallery).then(
          (value) {
        if (value != null) {
          imageFile = value;
          uploadImage();
        }
      },
    );
  }

  uploadImage() async {
    int status = 1;
    String filename = const Uuid().v1();

    var ref = FirebaseStorage.instance.ref().child('images').child(
        '$filename.jpg');

    await fireStore
        .collection('chatRoom')
        .doc(widget.chatRoomId)
        .collection('chats')
        .doc(filename)
        .set({
      'sendBy': auth.currentUser!.uid,
      'receiver': widget.userRefId,
      'senderName': auth.currentUser!.displayName,
      'receiverName': widget.receiverName,
      'message': '',
      'type': 'img',
      'time': FieldValue.serverTimestamp(),
      'opened': false,
      'isSenderMessageDeleted': false,
      'isReceiverMessageDeleted': false,
      'isPermanentlyDeleted': false,
      'senderPath': 'none',
      'receiverPath': 'none',
      'fileName': 'none'
    });

    debugPrint(ref.toString());
    debugPrint('before upload');

    var uploadTask = await ref.putFile(File(imageFile!.path))
        .catchError(() async {
      await fireStore
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(filename)
          .delete();

      status = 0;
    });

    debugPrint('after upload');
    if (status == 1) {
      // Step 3: Get directory where we can duplicate selected file.
      String dir = (await getExternalStorageDirectory())!.path;
      debugPrint('this is dir 0 $dir');
      var fileName = basename(imageFile!.path);
      String savePath = '$dir/$fileName';
      await imageFile!.saveTo(savePath);

      int unreadMessage;
      var imageUrl = await uploadTask.ref.getDownloadURL();
      debugPrint(imageUrl);
      await fireStore
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .collection('chats')
          .doc(filename)
          .update({
        'message': imageUrl,
        'senderPath': savePath,
        'fileName': fileName
      });
      fireStore
          .collection('chatRoom')
          .doc(widget.chatRoomId)
          .get()
          .then((value) {
        debugPrint('printing value ----');
        debugPrint(value.data().toString());

        unreadMessage = value.data()!['lastMessageCount'];
        unreadMessage++;

        debugPrint(imageUrl);
        fireStore.collection('chatRoom').doc(widget.chatRoomId).set({
          'sendBy': auth.currentUser!.uid,
          'receiver': widget.userRefId,
          'senderName': auth.currentUser!.displayName,
          'receiverName': widget.receiverName,
          'lastMessage': 'Image',
          'lastMessageCount': unreadMessage,
          'type': 'img',
          'time': FieldValue.serverTimestamp(),
          'opened': false,
          'chatRoomId': widget.chatRoomId,
          'isSenderMessageDeleted': false,
          'isReceiverMessageDeleted': false,
          'isPermanentlyDeleted': false,
          'size': 'none',
        });

        callOnFcmApiSendPushNotifications(
            deviceToken: widget.deviceToken, type: 'img', message: 'Image');
      });
    }
  }

  Widget customAppBar({name, status, context}) {
    Size size = MediaQuery
        .of(context)
        .size;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
      child: InkWell(
        onTap: () {
          debugPrint('in log out');
          Navigator.push(context, MaterialPageRoute(builder: (context) =>
              WhatsappProfilePage(
                  uid: widget.userRefId, chatId: widget.chatRoomId),));
        },
        child: Row(
          children: [
            InkWell(
                onTap: () {
                  // Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (context) =>
                  //    const HomePage()), (Route<dynamic> route) => false);
                  Navigator.of(context).pop();
                },
                child:
                const Icon(Icons.arrow_back, color: Colors.white, size: 25)),
            const SizedBox(
              width: 10,
            ),
            InkWell(
              child: widget.receiverProfile == 'none' ? const Icon(
                  Icons.account_circle, size: 50) : ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: CachedNetworkImage(
                  height: 50,
                  width: 50,
                  fit: BoxFit.cover,
                  imageUrl: '${widget.receiverProfile}',
                  placeholder: (context, url) =>
                  const Icon(Icons.account_circle, size: 50),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                ),
              ),
            ),

            const SizedBox(
              width: 15,
            ),
            SizedBox(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 16)),
                  Text(status,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: status == 'Online'
                              ? const Color(0xffe0d5ff)
                              : Colors.grey,
                          fontWeight: FontWeight.w700,
                          fontSize: 12)),
                ],
              ),
            ),
            const Spacer(),
            const SizedBox(
              width: 15,
            ),
            selectedMessageList.isNotEmpty
                ? InkWell(
                onTap: () {
                  deleteDialogBox(context: context,
                      size: MediaQuery
                          .of(context)
                          .size,
                      title: 'Delete message?',
                      isDeleteEveryoneVisible: !isReceiveMessageAdded!,
                      cancel: () {
                        setState(() {
                          selectedMessageList = [];
                        });
                        Navigator.of(context).pop();
                      },
                      deleteForMe: () async {
                        await fireStore.collection('chatRoom').doc(
                            widget.chatRoomId).collection('chats').get().then((
                            value) async {
                          for (var element in value.docs) {
                            for (var e in selectedMessageList) {
                              if (element.reference.id == e) {
                                await fireStore.collection('chatRoom').doc(
                                    widget.chatRoomId).collection('chats').doc(
                                    e).update(
                                    {
                                      'isSenderMessageDeleted': auth
                                          .currentUser!.uid ==
                                          element.data()['sendBy']
                                          ? true
                                          : false,
                                      'isReceiverMessageDeleted': auth
                                          .currentUser!.uid ==
                                          element.data()['sendBy']
                                          ? false
                                          : true,
                                    }
                                );
                              }
                            }
                          }
                        });
                        if (isLastMessageSelectedForDelete == true) {
                          debugPrint(
                              'this is in last msg selected -------------------------');
                          await fireStore.collection('chatRoom').doc(widget
                              .chatRoomId).get().then((value) async {
                            await fireStore.collection('chatRoom').doc(
                                widget.chatRoomId).update(
                                {
                                  'isSenderMessageDeleted': value
                                      .data()!['sendBy'] ==
                                      auth.currentUser!.uid ? true : false,
                                  'isReceiverMessageDeleted': value
                                      .data()!['sendBy'] ==
                                      auth.currentUser!.uid ? false : true,
                                }
                            );
                          });
                        }


                        setState(() {
                          selectedMessageList = [];
                        });
                        Navigator.of(context).pop();
                      },
                      deleteForEveryOne: () async {
                        await fireStore.collection('chatRoom').doc(
                            widget.chatRoomId).collection('chats').get().then((
                            value) async {
                          for (var element in value.docs) {
                            for (var e in selectedMessageList) {
                              if (element.reference.id == e) {
                                await fireStore.collection('chatRoom').doc(
                                    widget.chatRoomId).collection('chats').doc(
                                    e).update(
                                    {
                                      'isPermanentlyDeleted': true
                                    }
                                );
                              }
                            }
                          }
                        });
                        if (isLastMessageSelectedForDelete == true) {
                          debugPrint(
                              'this is in last msg selected -------------------------');
                          await fireStore.collection('chatRoom').doc(widget
                              .chatRoomId).get().then((value) async {
                            await fireStore.collection('chatRoom').doc(
                                widget.chatRoomId).update(
                                {
                                  'isPermanentlyDeleted': true
                                }
                            );
                          });
                        }

                        setState(() {
                          selectedMessageList = [];
                        });
                        Navigator.of(context).pop();
                      }
                  );
                },
                child: const Icon(Icons.delete, color: Colors.white, size: 30))
                : Container(),
            const SizedBox(
              width: 15,
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
                        onTap: () =>
                            showConfirmationDialog(
                                context: context,
                                onConfirm:
                                    () async {
                                  Navigator.pop(context);
                                  fireStore.collection('chatRoom').doc(
                                      widget.chatRoomId)
                                      .collection('chats')
                                      .get()
                                      .then((value) async {
                                    for (var e in value.docs) {
                                      // debugPrint(
                                      //     '---------------- vale has been updated ------------------------- ${e.data()}');
                                      fireStore.collection('chatRoom').doc(
                                          widget.chatRoomId)
                                          .collection('chats')
                                          .doc(
                                          e.reference.id)
                                          .update(
                                          {
                                            'isSenderMessageDeleted': auth
                                                .currentUser!.uid ==
                                                e.data()['sendBy']
                                                ? true
                                                : false,
                                            'isReceiverMessageDeleted': auth
                                                .currentUser!.uid ==
                                                e.data()['sendBy']
                                                ? false
                                                : true,
                                          }
                                      );
                                    }
                                  });

                                  fireStore.collection('chatRoom').doc(
                                      widget.chatRoomId).get().then((value) {
                                    fireStore.collection('chatRoom').doc(
                                        widget.chatRoomId).update(
                                        {
                                          'isSenderMessageDeleted': value
                                              .data()!['sendBy'] ==
                                              auth.currentUser!.uid
                                              ? true
                                              : false,
                                          'isReceiverMessageDeleted': value
                                              .data()!['sendBy'] ==
                                              auth.currentUser!.uid
                                              ? false
                                              : true,
                                        }
                                    );
                                  });

                                  setState(() {

                                  });
                                },
                                title: 'Clear all chat',
                                description: 'Are you sure you want to clear all chat?'
                            ),
                        child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            decoration: const BoxDecoration(
                              // color: Colors.red,
                              //   border: Border(bottom: BorderSide(color: Colors.grey,style: BorderStyle.solid,width: 0.5))
                            ),
                            height: 50,
                            width: size.width * 0.35,
                            alignment: Alignment.centerLeft,
                            child: const Text(
                              'Clear All Chat', style: TextStyle(
                              fontWeight: FontWeight.w400,),)),
                      )
                  ),
                ],
                onChanged: (value) {
                  debugPrint(value);
                },
                dropdownStyleData: DropdownStyleData(
                  width: size.width * 0.4,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xfff5f7fa),
                    // gradient:  LinearGradient(
                    //   // begin: Alignment.topRight,
                    //   // end: Alignment.bottomLeft,
                    //   colors: [
                    //     const Color(0xfff5f7fa).withOpacity(0.93),
                    //     const Color(0xffc3cfe2).withOpacity(0.53),
                    //     // Colors.red,
                    //     // Colors.red
                    //   ],
                    // ),
                    borderRadius: BorderRadius.circular(4),
                    // color: Colors.grey,
                  ),
                  offset: const Offset(0, 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void openAnyFile({link}) async {
    debugPrint('in open any file');
    var url = link;
    final baseFileName = basename(url);
    final filename = baseFileName
        .split('?')
        .first;
    debugPrint('this is file base name -> $filename');

    String dir = (await getExternalStorageDirectory())!.path;
    debugPrint('this is dir 0 $dir');
    String savePath = '$dir/$filename';

//for a directory: await Directory(savePath).exists();
    if (await File(savePath).exists()) {
      debugPrint("File exists");
      debugPrint('this is save path -> $savePath');
      var file = File(savePath);
      file.open();
      debugPrint("File exists success");
    } else {
      // debugPrint("File don't exists");
      await http.get(Uri.parse(url!)).then((value) async {
        debugPrint('this is response -> ${value.statusCode}');
        final bytes = value.bodyBytes;
        // final dir = await getExternalStorageDirectory();
        final dir = await getExternalStorageDirectory();
        debugPrint('this is dir 1 $dir');
        var file = File('${dir!.path}/$filename');
        await file.writeAsBytes(bytes, flush: true).then((value) async {
          debugPrint('this is file not exists path -> ${file.path}');
          file.open();
          debugPrint("File not exists success");
        });
      });
    }
  }

  /// Get from Camera
  Future _getFromCamera() async {
    ImagePicker imgPicker = ImagePicker();
    await imgPicker.pickImage(source: ImageSource.camera).then(
          (value) {
        if (value != null) {
          imageFile = value;
          uploadImage();
        }
      },
    );
  }

  Future<bool> callOnFcmApiSendPushNotifications(
      {deviceToken, type, message}) async {
    debugPrint('in notification send');

    const postUrl = 'https://fcm.googleapis.com/fcm/send';
    final data = {
      "registration_ids": [deviceToken],
      "collapse_key": "type_a",
      "data": {
        'sendBy': auth.currentUser!.uid,
        'receiver': widget.userRefId,
        'senderName': auth.currentUser!.displayName,
        'receiverName': widget.receiverName,
        'message': message,
        'type': type,
        'opened': false,
        'chatRoomId': widget.chatRoomId,
        'profile': widget.receiverProfile,
      },
    };

    final headers = {
      'content-type': 'application/json',
      'Authorization':
      'key=AAAA3mnfjYc:APA91bEMMjnfHV0y2m2AflN9lbylIAS4A13JUqLeOHtTLg3le-WwSdgM-TbHsgdGZKf3WGtju_29XFrxnbgqy122EMQP4A5lzC5wBlwDuTlcADisDqcJQT5Pk0M3hbi03fBX9c5ACN1g'
      // 'key=YOUR_SERVER_KEY'
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

  DateTime parseTimestamp(String timestamp) {
    final seconds = int.parse(timestamp.split(":")[0]);
    final nanoseconds = int.parse(timestamp.split(":")[1]);

    return DateTime.fromMillisecondsSinceEpoch(
      (seconds * 1000 + nanoseconds / 1000000).toInt(),
      // 1689326110 is the Unix timestamp of 2023-07-14 05:40:10 UTC.
      // The nanoseconds are not important in this case, so we just set them to 0.
      // TimeZone.utc is used to ensure that the timestamp is parsed in UTC.
    ).toLocal();
  }


  String separateDate(DateTime dateTime) {
    final now = DateTime.now();

    // If the dateTime is today, format it as '05:23 AM'
    if (dateTime.year == now.year &&
        dateTime.month == now.month &&
        dateTime.day == now.day) {
      const formattedTime = 'Today';
      return formattedTime;
    }

    // If the dateTime is yesterday, return 'Yesterday'
    final yesterday = now.subtract(const Duration(days: 1));
    if (dateTime.year == yesterday.year &&
        dateTime.month == yesterday.month &&
        dateTime.day == yesterday.day) {
      return 'Yesterday';
    }

    // For any other date, format it as 'july 5 2023'
    final formattedDate = DateFormat('MMMM d, y').format(dateTime);
    return formattedDate;
  }

}

