import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:video_trimmer/video_trimmer.dart';

import '../methods.dart';

class UploadStoryScreen extends StatefulWidget {
  File? document;
  bool? isImage;
  UploadStoryScreen({Key? key,this.document,this.isImage}) : super(key: key);

  @override
  State<UploadStoryScreen> createState() => _UploadStoryScreenState();
}

class _UploadStoryScreenState extends State<UploadStoryScreen> {


  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  bool ignore = false;


  TextEditingController messageText = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    debugPrint('in UploadStoryScreen');
  }

  @override
  Widget build(BuildContext context) {
    return  SafeArea(
        child: Scaffold(
          body: widget.isImage! ? imageViewer() :  TrimmerView(file: widget.document!,)
        ));
  }

  imageViewer()
  {
    return Scaffold(
      backgroundColor: Colors.black,
        body: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Column(children: [
            const SizedBox(height: 10,),
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
                            child: const Text(
                              'Image',
                              style: TextStyle(
                                  color: Colors
                                      .white,
                                  fontSize: 18),)),
                      ],
                    )
                  ]),
            ),
            Expanded(child: Image.file(widget.document!,fit: BoxFit.contain)),
            const SizedBox(height: 60,)
          ],),
          bottomTextField(context)
        ],
      ),
    );
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
              width: 15,
            ),
            InkWell(
                onTap: ignore ? null: () async {
                  debugPrint('in click of send button');
                 setState(() {
                   ignore = true;
                 });
                  EasyLoading.show();
                  debugPrint('this is ignore flag -> $ignore');
                    // onMessageSend(context, messageText.text);
                     await uploadDoc(documentPath: widget.document!.path,isImage: true,text: messageText.text);
                  EasyLoading.dismiss();
                     Navigator.pop(context);
                },
                child: const Icon(
                  Icons.send,
                  color: Colors.blueGrey,
                ))
          ],
        ));
  }
}


class TrimmerView extends StatefulWidget {
  final File file;

  const TrimmerView({required this.file, super.key});

  @override
  TrimmerViewState createState() => TrimmerViewState();
}

class TrimmerViewState extends State<TrimmerView> {
  final Trimmer _trimmer = Trimmer();

  bool ignore = false;

  double _startValue = 0.0;
  double _endValue = 0.0;

  bool _isPlaying = false;
  bool _progressVisibility = false;

  String? valueNew;

  TextEditingController messageText = TextEditingController();


  void _loadVideo() {
    _trimmer.loadVideo(videoFile: widget.file);
  }

  @override
  void initState() {
    super.initState();

    _loadVideo();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Builder(
        builder: (context) => Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              padding: const EdgeInsets.only(bottom: 60.0),
              color: Colors.black,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: <Widget>[
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
                              child: const Text(
                                'Video Trim',
                                style: TextStyle(
                                    color: Colors
                                        .white,
                                    fontSize: 18),)),
                        ],
                      )
                    ]),
              ),
                  Visibility(
                    visible: _progressVisibility,
                    child: const LinearProgressIndicator(
                      backgroundColor: Colors.deepPurple,
                    ),
                  ),
                  Expanded(
                    child: VideoViewer(trimmer: _trimmer),
                  ),
                  Center(
                    child: TrimViewer(
                      trimmer: _trimmer,
                      viewerHeight: 50.0,
                      viewerWidth: MediaQuery.of(context).size.width,
                      maxVideoLength: const Duration(seconds: 10),
                      onChangeStart: (value) => _startValue = value,
                      onChangeEnd: (value) => _endValue = value,
                      onChangePlaybackState: (value) =>
                          setState(() => _isPlaying = value),
                    ),
                  ),
                  TextButton(
                    child: _isPlaying
                        ? const Icon(
                      Icons.pause,
                      size: 80.0,
                      color: Colors.white,
                    )
                        : const Icon(
                      Icons.play_arrow,
                      size: 80.0,
                      color: Colors.white,
                    ),
                    onPressed: () async {
                      bool playbackState = await _trimmer.videoPlaybackControl(
                        startValue: _startValue,
                        endValue: _endValue,
                      );
                      setState(() {
                        _isPlaying = playbackState;
                      });
                    },
                  )
                ],
              ),
            ),
            bottomTextField(context)
          ],
        ),
      ),
    );
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
              width: 15,
            ),
            InkWell(
                onTap: _progressVisibility
                    ? null
                    : ignore ? null: () async {
                  debugPrint('in click of send button');
                    setState(() {
                      ignore = true;
                      _progressVisibility = true;
                    });
                    EasyLoading.show();
                    await _trimmer.saveTrimmedVideo(startValue: _startValue, endValue: _endValue,onSave:(outputPath) async {
                      debugPrint('in onn save of trim video => $outputPath');
                      await uploadDoc(documentPath: outputPath,isImage: false,text: messageText.text);
                      setState(() {
                        _progressVisibility = false;
                        Navigator.pop(context);
                      });
                    },);
                    debugPrint('code ending...');
                  EasyLoading.dismiss();
                },
                child: const Icon(
                  Icons.send,
                  color: Colors.blueGrey,
                ))
          ],
        ));
  }
}