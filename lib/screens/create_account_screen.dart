import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:we_talk/screens/login_screen.dart';
import '../methods.dart';

class CreateAccount extends StatefulWidget {
  const CreateAccount({Key? key}) : super(key: key);

  @override
  State<CreateAccount> createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  TextEditingController nameCtrl = TextEditingController();
  TextEditingController phoneNumberCtrl = TextEditingController();
  TextEditingController emailCtrl = TextEditingController();
  TextEditingController passwordCtrl = TextEditingController();
  var isLoading = false;

  String imageFilePath = '';
  String imageUrl = '';
  ImagePicker imagePicker = ImagePicker();
  bool isImagePicked = false;
  File? imageFile;

  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  FirebaseAuth auth = FirebaseAuth.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey.shade50,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [

            const SizedBox(height: 70,),
            const Text('Create New Account', style: TextStyle(fontSize: 24)),
            const SizedBox(
              height: 20,
            ),
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
                                ],
                              ),
                            );
                          });
                    },
                    child: isImagePicked
                        ? ClipRRect (
                      borderRadius: BorderRadius.circular(50),
                          child: Image.file(
                              imageFile!,
                              fit: BoxFit.cover,
                      height: 100,
                      width: 100,
                            ),
                        )
                        : const Icon(Icons.account_circle, size: 100)),
                 Text( isImagePicked ? 'Edit profile picture' : 'Add profile picture')
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            TextFormField(
              controller: nameCtrl,
              decoration:  InputDecoration(hintText: 'Enter Name',border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none
                  ),
                  focusedBorder:  OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none
                  ),
                  filled: true,
                  fillColor: Colors.white),
            ),
            const SizedBox(
              height: 20,
            ),
            TextFormField(
              inputFormatters: [
                LengthLimitingTextInputFormatter(10)
              ],
              controller: phoneNumberCtrl,
              decoration:  InputDecoration(hintText: 'Enter Phone Number',border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none
                  ),
                  focusedBorder:  OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none
                  ),
                  filled: true,
                  fillColor: Colors.white),
            ),
            const SizedBox(
              height: 20,
            ),
            TextFormField(
              controller: emailCtrl,
              decoration:  InputDecoration(hintText: 'Enter Email',border: InputBorder.none,
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none
                  ),
                  focusedBorder:  OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none
                  ),
                  filled: true,
                  fillColor: Colors.white),
            ),
            const SizedBox(
              height: 20,
            ),
            TextFormField(
              controller: passwordCtrl,
              decoration:  InputDecoration(hintText: 'Enter Password',border: InputBorder.none,
                  focusedBorder:  OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none
                  ),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(7),
                      borderSide: BorderSide.none
                  ),
                  filled: true,
                  fillColor: Colors.white),
            ),
            const SizedBox(
              height: 20,
            ),
            SizedBox(
              height: 50,
              width: double.infinity,
              child: ElevatedButton(
                  onPressed: () {
                    if (emailCtrl.text == '' &&
                        passwordCtrl.text == '' &&
                        nameCtrl.text == '' &&
                        phoneNumberCtrl.text == ''
                    ) {
                      debugPrint('one field is empty');
                    } else if(imageUrl == '')
                      {
                        debugPrint('image url is empty ');
                      }
                    else if(imageUrl == '')
                    {
                      debugPrint('image url is empty ');
                    }
                      else {
                      setState(() {
                        isLoading = true;
                      });
                      createAccount(
                              name: nameCtrl.text,
                              email: emailCtrl.text,
                              password: passwordCtrl.text,
                      profile: imageUrl,
                      phoneNum: phoneNumberCtrl.text
                      )
                          .then(
                        (value) {
                          if (value != null) {
                            setState(() {
                              isLoading = false;
                            });
                            debugPrint('account creation success');
                            nameCtrl.text = '';
                            emailCtrl.text = '';
                            passwordCtrl.text = '';
                            Navigator.of(context).pushReplacement(MaterialPageRoute(
                              builder: (context) => const LoginScreen(),
                            ));
                          } else {
                            debugPrint('account creation failed');
                          }
                        },
                      );
                    }
                  },
                  child: const Text('Create Account',style: TextStyle(fontSize: 16),)),
            ),
            const SizedBox(height: 10,),
            InkWell(
                onTap: () {
                  Navigator.of(context).pushReplacement(MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ));
                },
                child: const Text('Already have account? Login', style: TextStyle(fontSize: 16))),
          ]),
        ),
      ),
    );
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
            uploadImage();
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
            uploadImage();

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


  uploadImage()
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
