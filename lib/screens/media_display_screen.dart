import 'package:any_link_preview/any_link_preview.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cached_pdfview/flutter_cached_pdfview.dart';
import 'package:intl/intl.dart';
import 'package:photo_view/photo_view.dart';
// import 'package:sticky_grouped_list/sticky_grouped_list.dart';

class MediaDisplay extends StatefulWidget {
  List<dynamic>? listOfImage;
  List<dynamic>? listOfDocs;
  List<dynamic>? listOfLinks;
  String? name;
   MediaDisplay({Key? key,this.listOfDocs,this.listOfImage,this.listOfLinks,this.name}) : super(key: key);

  @override
  State<MediaDisplay> createState() => _MediaDisplayState();
}

class _MediaDisplayState extends State<MediaDisplay> {

  int index = 0;

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    debugPrint('in the build of media');
    List<Widget> tabs = [
      widget.listOfImage!.isEmpty ?  const Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Text('No Image'),
      ) :displayImageGrid(),
      widget.listOfDocs!.isEmpty ? const Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Text('No Documents'),
      ) :displayDocsList(),
      widget.listOfLinks!.isEmpty ? const Padding(
        padding: EdgeInsets.symmetric(vertical: 15),
        child: Text('No Links'),
      ) :displayLinksList(),
    ];
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            //const SizedBox(height: 20,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15,vertical: 10),
              child: Row(children: [
                InkWell(onTap: () => Navigator.of(context).pop(),child: const Icon(Icons.arrow_back,color: Colors.black,)),
                const SizedBox(width: 15,),
                SizedBox(width: size.width * 0.6,
                    child:  Text(widget.name!,style: const TextStyle(color: Colors.black,fontSize: 20),))
              ]),
            ),
            tapBar(),
            tabs[index]
          ],
        ),
      ),
    );
  }

  Widget tapBar()
  {
    return Row(
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
              decoration:  BoxDecoration(border: Border(bottom: index == 0 ? const BorderSide(color: Color(
                  0xff6d52c1),width: 5) : const BorderSide(width: 5,color: Colors.transparent))),
              child: const Text('Media',style: TextStyle(color: Colors.black,fontSize: 20))),
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
              decoration: BoxDecoration(border: Border(bottom: index == 1 ? const BorderSide(color: Color(0xff6d52c1),width: 5) : const BorderSide(width: 5,color: Colors.transparent))),
              child: const Text('Docs',style: TextStyle(color: Colors.black,fontSize: 20))),
        ),
      ),
        Expanded(
          child: InkWell(
            onTap: (){
              setState(() {
                index = 2;
              });
            },
            child: Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(border: Border(bottom: index == 2 ? const BorderSide(color: Color(0xff6d52c1),width: 5) : const BorderSide(width: 5,color: Colors.transparent))),
                child: const Text('Links',style: TextStyle(color: Colors.black,fontSize: 20))),
          ),
        ),

    ],);
  }

  Widget displayImageGrid()
  {

    return Flexible(
      child: Container(
        color: Colors.grey.shade50,
        child: GridView.builder(
          padding: const EdgeInsets.symmetric(vertical: 5),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3,crossAxisSpacing: 5,mainAxisSpacing: 5),
            itemCount: widget.listOfImage!.length,
            // shrinkWrap: true,
            itemBuilder: (context, index) {
          return Container(

            height: 100,width: 150,
            // color: Colors.green,
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
                                    '${widget.listOfImage![index]}',
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
                                      '${widget.listOfImage![index]}',
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
                  height: 50,
                  width: 100,
                  fit: BoxFit.cover,
                  imageUrl: widget.listOfImage![index],
                  placeholder: (context,
                      url) =>
                  const Icon(
                      Icons.image,
                      size: 50),
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
      ),
    );
  }

  Widget displayDocsList()
   {
    // Size size = MediaQuery.of(context).size;
    debugPrint('in display doc list');
    debugPrint(widget.listOfDocs![0].toString());
    return Flexible(
      child: Container(
        color: Colors.grey.shade50,
        child: ListView.builder(
          itemCount: widget.listOfDocs!.length,
          itemBuilder: (context, index) {

          return  GestureDetector(
            child: Card(
              child: Container(
                //color: selectedMessageList.contains(e.reference.id) ?Colors.white.withOpacity(0.4):Colors.transparent,
                padding: const EdgeInsets.only(
                    top: 10, right: 10, left: 10,bottom: 5),
                child:  InkWell(
                  onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(
                            builder: (context) {
                              return Scaffold(
                                body: const PDF()
                                    .cachedFromUrl(
                                  '${widget.listOfDocs![index]['message']}',
                                  placeholder: (double
                                  progress) =>
                                      Center(
                                          child: Text(
                                              '$progress %')),
                                  errorWidget: (dynamic
                                  error) =>
                                      Center(
                                          child: Text(error
                                              .toString())),
                                ),
                              );
                            },
                          ));
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    // mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                          Icons.file_copy,
                          size: 30,
                          color: Colors
                              .blueGrey),
                      const SizedBox(
                        width: 10,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: MediaQuery.of(context).size.width * 0.75,
                              child: Flexible(
                                child: Text(
                                  widget.listOfDocs![index]['message'].toString().split('/').last.split('?').first.split('F').last,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      color: Colors
                                          .black),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                                 const SizedBox(height: 5,),
                                 Row(
                                   mainAxisSize: MainAxisSize.max,
                                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                   children: [
                                     Row(
                                       children: [
                                         Text( '${widget.listOfDocs![index]['type']}',
                                           style: const TextStyle(
                                               fontSize: 15,
                                               color: Colors
                                                   .grey),),
                                         const SizedBox(width: 10,),
                                         Text('${widget.listOfDocs![index]['size'].toStringAsFixed(3)} Mb ',
                                           style: const TextStyle(
                                               fontSize: 15,
                                               color: Colors
                                                   .grey),),
                                         const SizedBox(width: 10),
                                       ],
                                     ),
                                   // const Spacer(),
                                   Text(formatDateTime(widget.listOfDocs![index]['time'].toDate()),style: const TextStyle(fontSize: 15, color: Colors.grey))
                                ],
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },),
      ),
    );
  }

  Widget displayLinksList()
  {

    return Flexible(
      child: Container(
        color: Colors.grey.shade50,
        child: ListView.builder(
          itemCount: widget.listOfLinks!.length,
          itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.all(5),
            child: AnyLinkPreview(
              link: widget.listOfLinks![index],
              displayDirection: UIDirection.uiDirectionHorizontal,
              showMultimedia: true,
              bodyMaxLines: 5,
              bodyTextOverflow: TextOverflow.ellipsis,
              titleStyle: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
              bodyStyle: const TextStyle(color: Colors.black, fontSize: 12),
              errorWidget: const Text('Error'),
              cache: const Duration(days: 7),
              backgroundColor: const Color(0xffebebeb),
              borderRadius: 12,
              removeElevation: true,
              // boxShadow: const [BoxShadow(blurRadius: 3, color: Colors.grey)],// This disables tap event
            ),
          );
        },),
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

}
