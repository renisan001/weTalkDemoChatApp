import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

class ProfileScreen extends StatefulWidget {
  // String? uid;
   ProfileScreen({Key? key,}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  Map<String, dynamic>? user;
  TextEditingController nameCtrl = TextEditingController();

  String imageUrl = '';
  ImagePicker imagePicker = ImagePicker();
  bool isImagePicked = false;
  File? imageFile;
  String imageFilePath = '';
  bool noProfile = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserdata();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SafeArea(
      child:  Scaffold(
        //appBar: AppBar(title: const Text('Profile',style: TextStyle(color: Colors.white,fontSize: 18))),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                const Color(0xfff5f7fa).withOpacity(0.93),
                const Color(0xffc3cfe2).withOpacity(0.93),
              ],
            ),
          ),
          child: user == null ? const Center(child: CircularProgressIndicator()) : Column(
            // mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              // const SizedBox(height: 50,),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 10),
                child: Row(children: [
                  InkWell(onTap: () => Navigator.of(context).pop(),child: const Icon(Icons.arrow_back,color: Colors.black,)),
                  const SizedBox(width: 15,),
                  SizedBox(width: size.width * 0.6,
                      child: const Text('Profile',style: TextStyle(color: Colors.black,fontSize: 18),))
                ]),
              ),
              const SizedBox(height: 15,),
              Column(
                children: [
                  InkWell(
                      onTap: () {
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
                                        _getFromCamera().then(
                                              (value) {
                                            Navigator.of(context).pop();
                                          },
                                        );
                                      },
                                      child: Row(
                                        //mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.camera, size: 30),
                                          SizedBox(width: 15),
                                          Text('Take a photo')
                                        ],
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 5),
                                      child: Divider(),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        _getFromGallery().then(
                                              (value) {
                                            Navigator.of(context).pop();
                                          },
                                        );
                                      },
                                      child: Row(
                                        //mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.image, size: 30),
                                          SizedBox(width: 15),
                                          Text('Gallery')
                                        ],
                                      ),
                                    ),
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 5),
                                      child: Divider(),
                                    ),
                                    InkWell(
                                      onTap: () {
                                       noProfile = true;
                                       FirebaseStorage.instance.refFromURL(user!['profile']).delete().then((value) {
                                         fireStore.collection('user').doc(auth.currentUser!.uid).update({
                                           'profile':'none'
                                         });
                                       });

                                       setState(() {
                                       });
                                       Navigator.of(context).pop();
                                      },
                                      child: Row(
                                        //mainAxisSize: MainAxisSize.min,
                                        children: const [
                                          Icon(Icons.clear, size: 30),
                                          SizedBox(width: 15),
                                          Text('Remove profile')
                                        ],
                                      ),
                                    ),

                                  ],
                                ),
                              );
                            });
                      },
                      child: noProfile ? const Icon(Icons.account_circle, size: 110) :isImagePicked
                          ? ClipRRect (
                        borderRadius: BorderRadius.circular(60),
                        child: Image.file(
                          imageFile!,
                          fit: BoxFit.cover,
                          height: 110,
                          width: 110,
                        ),
                      )
                          : user!['profile'] == 'none' ? const Icon(Icons.account_circle, size: 110) : ClipRRect (
                        borderRadius: BorderRadius.circular(60),
                        child: CachedNetworkImage(
                          height: 110,
                          width: 110,
                          fit: BoxFit.cover,
                          imageUrl:
                          '${user!['profile']}',
                          placeholder: (context,
                              url) =>
                          const Icon(
                              Icons
                                  .account_circle,
                              size: 110),
                          errorWidget: (context, url,
                              error) {
                            debugPrint(error.toString());
                            return const Icon(Icons.error,size: 110,);
                          }
                          ,
                        ),
                      )),
                  //Text( isImagePicked ? 'Edit profile picture' : 'Add profile picture')
                ],
              ),
              const SizedBox(height: 15,),
              listIcons(leadIcon: Icons.person,title: 'Name',description: toBeginningOfSentenceCase(user?['name']),backIcon: Icons.edit,
                  thirdLine: 'This is not your username or pin. This name will be visible to your We Talk contacts',
              onTap: (){
                editBottomModalSheet(
                  limit: 20,
                  controller: nameCtrl,
                  field: 'name',
                  title: 'Enter your name',name: user?['name'],).then((value) {
                    getUserdata();
                });
              }
              ),
              const Divider(indent: 55),
              listIcons(leadIcon: Icons.info_outline,title: 'About',description: user?['bio'],backIcon: Icons.edit,
                  onTap: (){
                    editBottomModalSheet(
                      limit: 60,
                      controller: nameCtrl,
                      field: 'bio',
                      title: 'Enter about yourself',name: user?['bio'],).then((value) {
                        getUserdata();
                    });
                  }
              ),
              const Divider(indent: 55),
              listIcons(leadIcon: Icons.call,title: 'Phone',description: '+91 ${ user!['phoneNumber'].toString().substring(0,5)} ${ user!['phoneNumber'].toString().substring(5,10)}'),
            ],
          ),
        ),
      ),
    );
  }


 Widget listIcons({leadIcon,title,description,backIcon,thirdLine,onTap})
  {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Icon(leadIcon,color: Colors.grey),
          const SizedBox(width: 15,),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
            Text(title,style: const TextStyle(color: Colors.grey,fontSize: 16),),
            Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(description,style: const TextStyle(color: Colors.black,fontSize: 18),),
            ),
              thirdLine != null ? Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.70),
                  child: Text(thirdLine,style: const TextStyle(color: Colors.grey,fontSize: 15,),textAlign: TextAlign.justify,)):Container(),
          ],),
          const Spacer(),
            backIcon != null ? Icon(backIcon,color: Colors.black,) : Container()
        ],),
      ),
    );
  }
  Future<void> getUserdata() async {
    await fireStore.collection('user').doc(auth.currentUser!.uid).get().then((value) {
      // debugPrint(value.data().toString());
      if(mounted) {
        setState(() {
        user = value.data();
      });
      }
    });
  }

  Future editBottomModalSheet({title,name,TextEditingController? controller,field,limit})
  {
    return showModalBottomSheet(
        isScrollControlled: true,
        context: context,
        builder: (context) {
          controller!.text = name;
          var oldValue = name;
      return StatefulBuilder(builder: (context, setState) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20,vertical: 20),
          child: Container(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children:  [
                Text(title,style: const TextStyle(fontSize: 18)),
                SizedBox(
                  // width: MediaQuery.of(context).size.width * 0.8,
                  child: TextFormField(
                    // maxLength: 20,
                    onTap: ()=>controller.selection = TextSelection(baseOffset: 0, extentOffset: controller.value.text.length),
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(limit),
                    ],
                    onChanged: (value) {
                      setState(() {

                      },);
                    },
                    controller: controller,
                    decoration:  InputDecoration(
                      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black)),
                      isDense: true,
                        suffixText: '${ limit - controller.text.length}'),
                  ),
                ),
                Row(children: [
                  const Spacer(),
                  TextButton(
                      onPressed: () {
                        controller.clear();
                      }, child: const Text('Clear all',style: TextStyle(color: Colors.black),)),
                  TextButton(
                      onPressed: ()=> Navigator.of(context).pop(), child: const Text('Cancel',style: TextStyle(color: Colors.black),)),
                  TextButton(onPressed: () async {
                    if(controller.text != oldValue)
                    {
                      await fireStore.collection('user').doc(auth.currentUser!.uid).update({
                        '$field':controller.text
                      });
                      Navigator.pop(context);
                    }
                  }, child: const Text('Save',style: TextStyle(color: Colors.black),)),
                ],)
              ],
            ),
          ),
        );
      },
      );
  });
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
          debugPrint('printing piked img if not null ==> value');
          CroppedFile? croppedFile = await _cropImage(pickedFile: value);
          setState(() {
            imageFile = File(croppedFile!.path);
            imageFilePath = imageFile!.path.toString();
            isImagePicked = true;
            noProfile = false;
            uploadImage().then((value) {
              if(imageUrl != '')
                {
                  fireStore.collection('user').doc(auth.currentUser!.uid).update({
                    'profile':imageUrl
                  });
                }
              else
                {
                  debugPrint('in else because url is empty');
                }

            });
          });
        }
      },
    );
  }

  /// Get from Camera
  Future _getFromCamera() async {
    // XFile? pickedFile =
    await imagePicker
        .pickImage(
      source: ImageSource.camera,
      maxWidth: 1800,
      maxHeight: 1800,
    )
        .then(
          (value) async {
        if (value != null) {

          CroppedFile? croppedFile = await _cropImage(pickedFile: value);
          setState(() {
            imageFile = File(croppedFile!.path);
            imageFilePath = imageFile!.path.toString();
            isImagePicked = true;
            noProfile = false;
            uploadImage().then((value) {
              if(imageUrl != '')
              {
                fireStore.collection('user').doc(auth.currentUser!.uid).update({
                  'profile':imageUrl
                });
              }
              else
              {
                debugPrint('in else because url is empty');
              }

            });

          });
        }
      },
    );
  }

  Future<CroppedFile?> _cropImage({pickedFile}) async {
    debugPrint('=============== $pickedFile');
    if (pickedFile != null) {
      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile!.path,
        compressFormat: ImageCompressFormat.jpg,
        compressQuality: 100,
        uiSettings: [
          AndroidUiSettings(
              toolbarTitle: 'Cropper',
              toolbarColor: Colors.deepOrange,
              toolbarWidgetColor: Colors.white,
              initAspectRatio: CropAspectRatioPreset.original,
              lockAspectRatio: true),
          IOSUiSettings(
            title: 'Cropper',
          ),
        ],
      );
      if (croppedFile != null) {
        return croppedFile;
      }
    }
    return null;
  }

  Future uploadImage()
  async {

    int status  = 1;
    String filename = const Uuid().v1();

    var ref = FirebaseStorage.instance.ref().child('userProfileImg').child('$filename.jpg');

    debugPrint(ref.toString());
    debugPrint('before upload');

    var uploadTask = await ref.putFile(imageFile!).catchError(() async {
      debugPrint('Error in putting image on fire storage');
      status = 0;
    });

    debugPrint('after upload');
    if(status == 1)
    {
      imageUrl = await uploadTask.ref.getDownloadURL();
      debugPrint(imageUrl);

    }
  }

}
