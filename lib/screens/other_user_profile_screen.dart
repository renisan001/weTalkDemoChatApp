import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
import 'package:system_settings/system_settings.dart';
import 'package:we_talk/screens/media_display_screen.dart';

import '../methods.dart';

class WhatsappProfilePage extends StatefulWidget {
  String? uid;
  String? chatId;
   WhatsappProfilePage({Key? key,this.uid,this.chatId}) : super(key: key);

  @override
  State<WhatsappProfilePage> createState() => _WhatsappProfilePageState();
}

class _WhatsappProfilePageState extends State<WhatsappProfilePage> {

  FirebaseAuth auth = FirebaseAuth.instance;
  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  Map<String, dynamic>? user;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserdata(widget.uid);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        // backgroundColor: Colors.grey.shade100,
        body: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              delegate: WhatsappAppbar(MediaQuery.of(context).size.width,user!['profile'],'${user!['name']}'),
              pinned: true,
            ),
            SliverToBoxAdapter(
              child: Column(
                children:  [PhoneAndName(user: user),
                  // ProfileIconButtons()
                ],
              ),
            ),
             WhatsappProfileBody(chatRoomId: widget.chatId,user: user,)
          ],
        ),
      ),
    );
  }

  Future<void> getUserdata(uid) async {
    await fireStore.collection('user').doc(uid).get().then((value) {
      debugPrint(value.data().toString());
      setState(() {
        user = value.data();
      });
    });
  }
}

class WhatsappAppbar extends SliverPersistentHeaderDelegate {
  double screenWidth;
  Tween<double>? profilePicTranslateTween;
  String? profile;
  String? number;

  WhatsappAppbar(this.screenWidth,this.profile,this.number) {
    profilePicTranslateTween =
        Tween<double>(begin: screenWidth / 2 - 45 - 25 + 15, end: 40.0);
  }
  static final appBarColorTween = ColorTween(
      begin: Colors.white, end: const Color.fromARGB(255, 5, 31, 46));

  static final appbarIconColorTween =
  ColorTween(begin: Colors.grey[800], end: Colors.white);

  static final phoneNumberTranslateTween = Tween<double>(begin: 20.0, end: 0.0);

  static final phoneNumberFontSizeTween = Tween<double>(begin: 20.0, end: 16.0);

  static final profileImageRadiusTween = Tween<double>(begin: 3.5, end: 1.0);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final relativeScroll = min(shrinkOffset, 45) / 45;
    final relativeScroll70px = min(shrinkOffset, 70) / 70;

    return Container(
      color: appBarColorTween.transform(relativeScroll),
      child: Stack(
        children: [
          Stack(
            children: [
              Positioned(
                left: 0,
                child: IconButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.arrow_back, size: 25),
                  color: appbarIconColorTween.transform(relativeScroll),
                ),
              ),
              Positioned(
                right: 0,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.more_vert, size: 25),
                  color: appbarIconColorTween.transform(relativeScroll),
                ),
              ),
              Positioned(
                  top: 15,
                  left: 90,
                  child: displayPhoneNumber(relativeScroll70px)),
              Positioned(
                  top: 10,
                  left: profilePicTranslateTween!.transform(relativeScroll70px) ,
                  child: displayProfilePicture(relativeScroll70px,profile,number)),
            ],
          ),
        ],
      ),
    );
  }

  Widget displayProfilePicture(double relativeFullScrollOffset,profile,number) {
    debugPrint(profile);
    return Transform(
      transform: Matrix4.identity()
        ..scale(
          profileImageRadiusTween.transform(relativeFullScrollOffset),
        ),
      // child: CircleAvatar(
      //   maxRadius: 16,
      //   backgroundImage: NetworkImage(profile),
      // ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: CachedNetworkImage(
            height: 33,
            width: 33,
            fit: BoxFit.cover,
            imageUrl: profile,
            placeholder: (context,
                url) =>
            const Icon(
                Icons.account_circle,
                size: 33),
            errorWidget: (context, url,
                error) {
              debugPrint(error.toString());
              return const Icon(Icons.error);
            }
        ),
      ),
    );
  }

  Widget displayPhoneNumber(double relativeFullScrollOffset) {
    if (relativeFullScrollOffset >= 0.8) {
      return Transform(
        transform: Matrix4.identity()
          ..translate(
            0.0,
            phoneNumberTranslateTween
                .transform((relativeFullScrollOffset - 0.8) * 5),
          ),
        child: Text(
          number!,
          style: TextStyle(
            fontSize: phoneNumberFontSizeTween
                .transform((relativeFullScrollOffset - 0.8) * 5),
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  double get maxExtent => 120;

  @override
  double get minExtent => 50;

  @override
  bool shouldRebuild(WhatsappAppbar oldDelegate) {
    return true;
  }
}

class WhatsappProfileBody extends StatefulWidget {
  String? chatRoomId;
  Map<String, dynamic>? user;
   WhatsappProfileBody({
    Key? key,
     this.chatRoomId,
     this.user
  }) : super(key: key);

  @override
  State<WhatsappProfileBody> createState() => _WhatsappProfileBodyState();
}

class _WhatsappProfileBodyState extends State<WhatsappProfileBody> {

  FirebaseFirestore fireStore = FirebaseFirestore.instance;
  var listOfImages = [];
  var listOfDocs = [];
  var listOfLinks = [];
  bool displayListImg = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    debugPrint('in whtsp profile init');
    getNewData().then((value) {
     setState(() {
       displayListImg = true;
     });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SliverList(
        delegate: SliverChildListDelegate( [
          // const SizedBox(height: 10),
          // const ListTile(
          //   title: Text("Custom Notifications"),
          //   leading: Icon(Icons.notification_add),
          // ),
          // const ListTile(
          //   title: Text("Disappearing messages"),
          //   leading: Icon(Icons.message),
          // ),

          displayListImg ?
              listOfImages.isEmpty ? Container(): displayImagePreview(name: widget.user!['name']):
          const Center(child: CircularProgressIndicator()),

          listOfImages.isEmpty ? Container(): Container(
            decoration: const BoxDecoration(
              color: Color(0xfff2f2f2),
            ),
            width: double.infinity,
            height: 12,
          ),
          const SizedBox(height: 10,),
          InkWell(
            onTap: (){
              SystemSettings.appNotifications();
            },
            child: const ListTile(
              title: Text("Mute Notifications"),
              leading: Icon(Icons.mic_off),
            ),
          ),
          const Divider(),
          const ListTile(
            title: Text("Media visibility"),
            leading: Icon(Icons.save),
          ),
          // to fill up the rest of the space to enable scrolling
          const SizedBox(
            height: 550,
          ),
          // Container(
          //   decoration: BoxDecoration(
          //       color: Colors.grey.shade200,
          //       boxShadow: [
          //         BoxShadow(color: Colors.white.withOpacity(0.3),blurStyle: BlurStyle.outer,blurRadius: 4)
          //       ]
          //   ),
          //   width: double.infinity,
          //   height: 500,
          // ),
        ]));
  }

  Future getNewData()
  async {
    await fireStore.collection('chatRoom').doc(widget.chatRoomId).collection('chats').get().then((value) {

      debugPrint(value.docs.length.toString());
      for (var element in value.docs) {
        var data = element.data();
        // debugPrint('new info print');
        // debugPrint(data.toString());
        if(data['type'] == 'img' && !data['isPermanentlyDeleted'])
          {
          // && widget.user!['uid'] ==  data['sendBy'] && data['receiverPath'].toString().isNotEmpty
            listOfImages.add(data['message']);
          }
        else if(data['type'] == 'link' && !data['isPermanentlyDeleted'])
          {
            listOfLinks.add(data['message']);
          }
        else if(data['type'] != 'img' && data['type'] != 'text' && !data['isPermanentlyDeleted'])
          {
            listOfDocs.add(data);
          }
        else
          {
            debugPrint('not image or doc but it\'s text');
          }
      }
      debugPrint('=== ${listOfImages.length}');
      debugPrint('---- ${listOfDocs.length}');
      debugPrint('---- ${listOfLinks.length}');

    });
  }

  Widget displayImagePreview({name})
  {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
        InkWell(
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) =>  MediaDisplay(listOfDocs: listOfDocs,listOfImage: listOfImages,listOfLinks: listOfLinks,name: widget.user!['name']),));
          },
          child: Row(children: [
            const Text('Media,docs, and links',style: TextStyle(color:
            Colors.black54,fontSize: 14,fontWeight: FontWeight.w500),),
            const Spacer(),
            Text('${listOfImages.length + listOfDocs.length + listOfLinks.length}',style: const TextStyle(fontSize: 16,color: Colors.black54),),
             const Icon(Icons.chevron_right,color: Colors.black54,size: 18,)
          ],),
        ),
        const SizedBox(height: 5,),
        SizedBox(
          height: 90,
          child: ListView.builder(
            itemCount: listOfImages.length,
            scrollDirection: Axis.horizontal,
            shrinkWrap: true,
            itemBuilder: (context, index) {
              // print('this is url ${listOfImages[index]}');
            return Padding(
              padding: const EdgeInsets.only(right: 5),
              child: InkWell(
                onTap: (){

                  Navigator.push(context,
                      MaterialPageRoute(
                        builder: (context) {
                          return Scaffold(
                            backgroundColor:
                            Colors.black,
                            body: Column(
                              mainAxisSize:
                              MainAxisSize
                                  .max,
                              mainAxisAlignment:
                              MainAxisAlignment
                                  .center,
                              children: [
                                const SizedBox(
                                  height: 50,
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
                                                Navigator.of(context).pop(),
                                            child: const Icon(
                                              Icons.arrow_back,
                                              color: Colors.white,
                                            )),
                                        const SizedBox(
                                          width:
                                          15,
                                        ),
                                        // SizedBox(width: MediaQuery.of(context).size.width * 0.6,
                                        //     child: Text('${data['message']}',style: const TextStyle(color: Colors.white,fontSize: 18),))
                                      ]),
                                ),
                                const SizedBox(height: 15,),
                                Flexible(
                                  child: InkWell(
                                      onTap: () {
                                        Navigator.pop(
                                            context);
                                      },
                                      child: Hero(
                                        tag:
                                        '${listOfImages[index]}',
                                        child:
                                        CachedNetworkImage(
                                          fit: BoxFit
                                              .contain,
                                          imageBuilder: (context, imageProvider) => SizedBox(
                                            // width: size.width,
                                            // height: size.height * 0.9,
                                              child: PhotoView(
                                                imageProvider:
                                                imageProvider,
                                                maxScale:
                                                3.0,
                                                minScale:
                                                0.0,
                                              )),
                                          imageUrl:
                                          '${listOfImages[index]}',
                                          placeholder: (context, url) =>
                                          const CircularProgressIndicator(),
                                          errorWidget: (context, url, error) =>
                                          const Icon(Icons.error),
                                        ),
                                      )),
                                ),
                              ],
                            ),
                          );
                        },
                      ));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: CachedNetworkImage(
                      width: 90,
                      fit: BoxFit.cover,
                      imageUrl: listOfImages[index],
                      placeholder: (context,
                          url) =>
                      const Icon(
                          Icons.image,
                          size: 60),
                      errorWidget: (context, url,
                          error) {
                        debugPrint(error.toString());
                        return const Icon(Icons.error);
                      }
                  ),
                ),
              ),
            );
          },),
        )
      ],),
    );
  }
}


class PhoneAndName extends StatelessWidget {

  Map<String, dynamic>? user;
   PhoneAndName({Key? key,this.user}) : super(key: key);

  @override
  Widget build(BuildContext context) {

    if(user == null)
      {
        return const CircularProgressIndicator();
      }
    else
      {
        return Column(
          children:  [
            const SizedBox(height: 10),
             Text(
               toBeginningOfSentenceCase(user!['name'])!  ,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              alignment: Alignment.center,
              width: double.infinity,
              height: 25,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
              child: Text(
               '+91 ${ user!['phoneNumber'].toString().substring(0,5)} ${ user!['phoneNumber'].toString().substring(5,10)}',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black45
                ),
              ),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(5)
              ),

              child: Text(
                toBeginningOfSentenceCase(user!['status'])!,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w300,
                  color: Colors.black54
                ),
              ),
            ),
            const SizedBox(height: 15),
            Container(
              decoration:  const BoxDecoration(
                  color: Color(0xfff2f2f2),
              ),
              width: double.infinity,
              height: 12,
            ),
             Container(
               alignment: Alignment.centerLeft,
               padding: const EdgeInsets.symmetric(horizontal: 10,vertical: 5),
               decoration: BoxDecoration(
                 color: Colors.white,
                   boxShadow: [
                 BoxShadow(color: Colors.grey.withOpacity(0.5),blurStyle: BlurStyle.outer,blurRadius: 5,)
               ]
               ),
               width: double.infinity,
               height: 60,
               child: Text(
                 user!['bio'],
                // textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                ),
            ),
             ),
            Container(
              decoration: const BoxDecoration(
                  color: Color(0xfff2f2f2),
              ),
              width: double.infinity,
              height: 12,
            ),
          ],
        );
      }

  }
}