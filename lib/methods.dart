import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:photo_view/photo_view.dart';
import 'package:uuid/uuid.dart';

Future createAccount({String? name, String? email, String? password,String? profile,String? phoneNum}) async {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  try {
    EasyLoading.show();
    var user = (await auth.createUserWithEmailAndPassword(
            email: email!, password: password!))
        .user;
    if (user != null) {
      await firestore.collection('user').doc(auth.currentUser!.uid).set({
        'name': name,
        'email':email,
        'status':'unavailable',
        'uid': auth.currentUser!.uid,
        'profile': profile,
        'phoneNumber': phoneNum,
        'bio':'available'
        // 'lastMessageTime': FieldValue.serverTimestamp()
      });
      auth.currentUser!.updateDisplayName(name);
      auth.currentUser!.updatePhotoURL(profile);
      debugPrint('Account created successfully');
      EasyLoading.dismiss();
      return user;
    } else {
      EasyLoading.dismiss();

      debugPrint('Fail to create account');
    }
  } catch (e) {
    EasyLoading.dismiss();
    debugPrint('this is e -> $e');
    return null;
  }
}

Future login({String? email, String? password}) async {
  FirebaseAuth auth = FirebaseAuth.instance;

  try {
    EasyLoading.show();
    var user = (await auth.signInWithEmailAndPassword(
            email: email!, password: password!))
        .user;
    if (user != null) {


      debugPrint('login successfully');
      EasyLoading.dismiss();
      return user;
    } else {
      EasyLoading.dismiss();
      debugPrint('login failed');
    }
  } catch (e) {
    EasyLoading.dismiss();
    debugPrint('this is e -> $e');
  }
}

Future logout() async {
  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  try {
    EasyLoading.show();
    fireStore.collection('user').doc(auth.currentUser!.uid).update({
      'deviceToken' : ''
    });
    await auth.signOut().then((value) { EasyLoading.dismiss();});
  } catch (e) {
    EasyLoading.dismiss();
    debugPrint('this is e -> $e');
  }
}

void showConfirmationDialog({BuildContext? context, Function? onConfirm,title,description}) {
  showDialog(
    context: context!,
    builder: (BuildContext context) {
      return AlertDialog(
        title:  Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children:  [
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text(
              'No',
              style: TextStyle(
                fontSize: 16,
                color: Colors.red,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              onConfirm!();
              // Navigator.pop(context);
            },
            child: const Text(
              'Yes',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue,
              ),
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        backgroundColor: Colors.white,
        elevation: 8,
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      );
    },
  );
}

Future<String?> deleteDialogBox({context,
  Size? size,
  title,
  isDeleteEveryoneVisible = false,
  deleteForMe,
  deleteForEveryOne,
  cancel
})
{
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(20.0)),
          child: Container(
            height: size!.height * 0.3,
            width: size.width * 0.4,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient:  LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: [
                  const Color(0xfff5f7fa).withOpacity(0.93),
                  const Color(0xffc3cfe2).withOpacity(0.93),
                ],
              ),
            ),
            // color: Colors.red,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20,horizontal: 15),
              child: Column(
                // mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 30,),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                    Row(
                      children: [
                        const Spacer(),
                        isDeleteEveryoneVisible ? deleteButton(title: 'Delete for every one',onTap: deleteForEveryOne) : Container(),
                      ],
                    ),
                      const SizedBox(height: 15,),
                    deleteButton(title: 'Delete for me',onTap: deleteForMe),
                      const SizedBox(height: 15,),
                    deleteButton(title: 'Cancel',onTap: cancel
                    ),
                  ],)

                ],
              ),
            ),
          ),
        );
      });
}

Widget deleteButton({title,onTap})
{
  return InkWell(
      onTap: onTap,
      child: Text(title,style: const TextStyle(fontSize: 16),));
}



Widget displayOneImage({context,
  title,
  isTimeVisible = false,
  displayTime,
  heroTag,
  path,
})
{
  Size size = MediaQuery.of(context).size;
  return SafeArea(
    child: Scaffold(
      backgroundColor:
      Colors
          .black,
      body: Column(
        mainAxisSize:
        MainAxisSize
            .max,
        mainAxisAlignment:
        MainAxisAlignment
            .center,
        children: [
          const SizedBox(
            height: 10,
          ),
          Padding(
            padding: const EdgeInsets
                .symmetric(
                horizontal:
                15),
            child: Row(
                children: [
                  InkWell(
                      onTap: () =>
                          Navigator
                              .of(
                              context)
                              .pop(),
                      child: const Icon(
                        Icons
                            .arrow_back,
                        color: Colors
                            .white,
                      )),
                  const SizedBox(
                    width:
                    15,
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .start,
                    children: [
                      SizedBox(
                          width: MediaQuery
                              .of(
                              context)
                              .size
                              .width *
                              0.8,
                          child: Text(

                            title,
                            style: const TextStyle(
                                color: Colors
                                    .white,
                                fontSize: 18),)),
                      isTimeVisible ? Text(displayTime,
                        style: const TextStyle(
                            color: Colors
                                .white,
                            fontSize: 13),) : Container()
                    ],
                  )
                ]),
          ),
          const SizedBox(
            height: 10,),
          Flexible(
            child: InkWell(
                onTap: () {
                  Navigator
                      .pop(
                      context);
                },
                child: Hero(
                    tag:
                    heroTag,
                    child:
                    SizedBox(
                      width: size
                          .width,
                      height: size
                          .height *
                          0.8,
                      child: PhotoView(
                        maxScale: 3.0,
                        minScale: 0.0,
                        imageProvider: FileImage(
                            File(
                              path,
                            )),
                        // child: Image.file(File(me ?data['senderPath'] :data['receiverPath']),
                        //   fit: BoxFit.cover,
                        // ),
                      ),
                    )
                )),
          ),
        ],
      ),
    ),
  );
}

BorderRadius borderRadius({me})
{
  return me
      ? const BorderRadius
      .only(
      topRight: Radius
          .circular(15),
      topLeft: Radius
          .circular(15),
      bottomLeft: Radius
          .circular(15))
      : const BorderRadius
      .only(
      topRight: Radius
          .circular(15),
      topLeft: Radius
          .circular(15),
      bottomRight: Radius
          .circular(
          15));
}


Future uploadDoc({documentPath,isImage = true,text}) async {

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;

  int status = 1;
  String filename = const Uuid().v1();

  var ref = FirebaseStorage.instance.ref().child('stories').child(filename);

  await fireStore
      .collection('stories')
      .doc(filename)
      .set({
    'userId': auth.currentUser!.uid,
    'story': 'none',
    'createdTime': FieldValue.serverTimestamp(),
    'viewerList' : 'none',
    'text':text == '' ? 'none' : text,
    'type': isImage! ? 'img' : 'video'
  });

  debugPrint(ref.toString());
  debugPrint('before upload');

  var uploadTask = await ref.putFile(File(documentPath))
      .catchError(() async {
    await fireStore
        .collection('stories')
        .doc(filename)
        .delete();

    status = 0;
  });

  debugPrint('after upload');
  if (status == 1) {

    var docUrl = await uploadTask.ref.getDownloadURL();

    debugPrint(docUrl);
    await fireStore
        .collection('stories')
        .doc(filename)
        .update({
      'story': docUrl,
    });

    debugPrint('succesfully stored ');
  }
  else
  {
    debugPrint('not succesfully stored ');
  }
}