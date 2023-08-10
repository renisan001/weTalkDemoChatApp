import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_thumbnail_imageview/video_thumbnail_imageview.dart';
import 'package:we_talk/screens/upload_story_screen.dart';

class StoryMoreOptionsScreen extends StatefulWidget {
  const StoryMoreOptionsScreen({Key? key}) : super(key: key);

  @override
  State<StoryMoreOptionsScreen> createState() => _StoryMoreOptionsScreenState();
}

class _StoryMoreOptionsScreenState extends State<StoryMoreOptionsScreen> {

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  File? mediaFile;
  ImagePicker imagePicker = ImagePicker();
  // List<QueryDocumentSnapshot<Map<String, dynamic>>?> storyList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body:
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                child: Row(children: [
                  InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      )),
                  const SizedBox(
                    width: 15,
                  ),
                  const Text(
                    'Your Story',
                    style: TextStyle(
                        color: Colors.white, fontSize: 16),
                  ),
                  const Spacer(),
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
                                        _getVideoFromGallery().then((value) {
                                          if(mediaFile != null)
                                          {
                                            Navigator.of(context).push(MaterialPageRoute(builder: (context) => UploadStoryScreen(document:  mediaFile,isImage: false),)).then((value) {
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
                      },
                      child: const Icon(Icons.add, color: Colors.white, size: 30))
                ]),
              ),
              const SizedBox(
                height: 10,
              ),
              StreamBuilder(
                stream: fireStore.collection('stories').orderBy('createdTime', descending: true).snapshots(),
                builder: (context, snapshot) {
                if(snapshot.data == null)
                  {
                    return const Text(
                      'Data is null',
                      style: TextStyle(
                          color: Colors.white, fontSize: 16),
                    );
                  }
                if(snapshot.hasError)
                  {
                    return const Text(
                      'There is some error',
                      style: TextStyle(
                          color: Colors.red, fontSize: 16),
                    );
                  }
                if(snapshot.hasData)
                  {
                    List<QueryDocumentSnapshot<Map<String, dynamic>>> storyData = [];
                    for (var story in snapshot.data!.docs)  {
                      debugPrint('this is data => ${story.data()}');

                      var stamp = story.data()['createdTime'];
                      DateTime date = stamp.toDate();
                      Duration difference = DateTime.now().difference(date);
                      if(difference.inHours < 24 && story['userId'] == auth.currentUser!.uid)
                      {
                        storyData.add(story);
                      }
                    }
                    if(storyData.isEmpty)
                      {
                        Navigator.pop(context);
                      }
                   return Expanded(
                     child: ListView(children: [
                       ...storyData.map((story) {
                         var stamp = story['createdTime'];
                         DateTime date = stamp.toDate();
                         debugPrint('viewer list -->${story['viewerList']}');
                         return Padding(
                           padding: const EdgeInsets.symmetric(vertical: 5,horizontal: 5),
                           child: Container(
                             color: Colors.white10,
                             child: Row(children: [
                               Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 10),
                                 child: ClipRRect(
                                   borderRadius: BorderRadius.circular(40),
                                   child:  story['type'] == 'img' ? CachedNetworkImage(
                                     height: 70,
                                     width: 70,
                                     fit: BoxFit.cover,
                                     imageUrl: '${story['story']}',
                                     placeholder: (context, url) =>
                                     const Icon(
                                         Icons.image, size: 70),
                                     errorWidget: (context, url, error) {
                                       debugPrint(error.toString());
                                       return const Icon(Icons.error,size: 70,);
                                     },
                                   ) : FutureBuilder(
                                     future: videoThumbnail(story['story']),
                                     builder: (context, snapshot) {
                                     if(snapshot.hasError)
                                       {
                                         return const Icon(Icons.error,size: 70,);
                                       }
                                     if(snapshot.hasData)
                                       {
                                         debugPrint('data thumbnail  -> ${snapshot.data}');
                                         return Image.file(snapshot.data as File,width: 70,height: 70,fit: BoxFit.cover,);
                                       }
                                     return const Center(child: CircularProgressIndicator());
                                   },),
                                 ),
                               ),
                               Column(children: [
                                 Text(
                                   story['viewerList'] == 'none' ? '0 Views' : '${(story['viewerList'] as List<dynamic>).length} Views',
                                   style: const TextStyle(
                                       color: Colors.white, fontSize: 16),
                                 ),
                                 Text(
                                   formatDateTime(date),
                                   style: const TextStyle(
                                       color: Colors.white, fontSize: 14),
                                 )
                               ],),
                               const Spacer(),
                               InkWell(
                                   onTap: () {
                                     fireStore.collection('stories').doc(story.reference.id).delete().then((value) {
                                       setState(() {

                                       });
                                     });
                                   },
                                   child: const Icon(Icons.delete, color: Colors.white, size: 30))
                             ],),
                           ),
                         );
                       },).toList(),
                     ],),
                   );
                  }
                return const Text(
                  'something is wrong',
                  style: TextStyle(
                      color: Colors.white, fontSize: 14),
                );
              },),
            ],
          ),
        ),
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

  videoThumbnail(String path)
  async {
    final fileName = await VideoThumbnail.thumbnailFile(
        video: path,
        thumbnailPath: (await getTemporaryDirectory()).path,
    imageFormat: ImageFormat.WEBP,
    maxHeight: 64, // specify the height of the thumbnail, let the width auto-scaled to keep the source aspect ratio
    quality: 75,
    );
    return File(fileName!);
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
