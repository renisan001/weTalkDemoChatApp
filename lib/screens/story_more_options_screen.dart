import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class StoryMoreOptionsScreen extends StatefulWidget {
  const StoryMoreOptionsScreen({Key? key}) : super(key: key);

  @override
  State<StoryMoreOptionsScreen> createState() => _StoryMoreOptionsScreenState();
}

class _StoryMoreOptionsScreenState extends State<StoryMoreOptionsScreen> {

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  List<QueryDocumentSnapshot<Map<String, dynamic>>?> storyList = [];

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getStoryList();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        body: storyList.isEmpty ? const Center(child: CircularProgressIndicator(),):
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(
                height: 10,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
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
                  )
                ]),
              ),
              const SizedBox(
                height: 10,
              ),
              ...storyList.map((story) {
                var stamp = story!['createdTime'];
                DateTime date = stamp.toDate();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(40),
                        child: CachedNetworkImage(
                          height: 70,
                          width: 70,
                          fit: BoxFit.cover,
                          imageUrl: '${story!['story']}',
                          placeholder: (context, url) =>
                          const Icon(
                              Icons.account_circle, size: 110),
                          errorWidget: (context, url, error) {
                            debugPrint(error.toString());
                            return const Icon(Icons.error,size: 110,);
                          },
                        ),
                      ),
                    ),
                    Column(children: [
                      Text(
                        '${story['viewerList'] == 'none' ? 0 : story['viewerList']}',
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
                    const Icon(Icons.delete, color: Colors.white, size: 30)

                  ],),
                );
              },).toList()
            ],
          ),
        ),
      ),
    );
  }

  getStoryList()
  async {
    await fireStore.collection('stories').orderBy('createdTime', descending: true).get().then((value) {
      debugPrint('this is data => ${value.docs.length}');
      storyList.clear();
      for (var story in value.docs)  {
        debugPrint('this is data => ${story.data()}');
        var stamp = story.data()['createdTime'];
        DateTime date = stamp.toDate();
        Duration difference = DateTime.now().difference(date);
        if(difference.inHours < 24 && story['userId'] != auth.currentUser!.uid)
        {
          storyList.add(story);
        }
        else
        {
          fireStore.collection('stories').doc(story.reference.id).delete();
        }
      }
      debugPrint('this is storyList two => ${storyList.isEmpty ? 'empty' :storyList[0]!.data()}');
      debugPrint('this is storyList two => ${storyList.isEmpty ? 'empty' :storyList.length}');
    });
    setState(() {

    });
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
}
