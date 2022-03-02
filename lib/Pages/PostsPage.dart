import 'package:flutter/material.dart';
import 'package:gio_app/Services/HttpServices.dart';
import '../Services/DataBaseServices.dart';
import '../Models.dart';


class PostsPage extends StatefulWidget {
  const PostsPage({
    this.discussion,
    this.payloadDiscussionId,
    Key? key}) : super(key: key);

  final Discussion? discussion;
  final String? payloadDiscussionId;

  @override
  _PostsPageState createState() => _PostsPageState();
}

class _PostsPageState extends State<PostsPage> {

  List<Post> postList=[];
  bool loading = true;
  bool connected = true;
  Discussion? discussion;
  String updateTime='';

  Future<void> getPosts() async {
    List<Post> _postList=[];
    var db=DBServices.instance;
    if (widget.discussion!=null) {
      print('widget.discussion not null');
      _postList=await db.getObjectsById(object: Post, id: widget.discussion!.id!)
                as List<Post>;
      setState(() {
        postList=_postList;
      });
      var study = HttpServices();
      var html = await study.getHtml(widget.discussion!.link);
      if (html!=null) {
        _postList=study.getPosts(html, widget.discussion!.id!);
        await db.updateDB(newData: _postList, whereId: 'discussionId', id: widget.discussion!.id!);
        await db.setUpdateTime(object: 'posts', foreignId: widget.discussion!.id!);
        _postList=await db.getObjectsById(object: Post, id: widget.discussion!.id!)
                  as List<Post>;
        if (mounted) {
          setState(() {
            postList=_postList;
            loading=false;
          });
        }
      } else {
        updateTime=await db.getUpdateTime(object: 'posts', foreignId: widget.discussion!.id!);
        if (updateTime.split(':').length>1) {
          updateTime='Τελευταία ενημέρωση: '+updateTime.split(':')[0]+':'+updateTime.split(':')[1];
        }
        if (mounted) {
          setState(() {
            loading=false;
            connected=false;
          });
        }
      }
    } else if (widget.payloadDiscussionId != null) {
      print('widget.discussion is null, get discussionId from payload');
      var discussionId = int.tryParse(widget.payloadDiscussionId!);
      if (discussionId != null) {
        var dbase=await db.database;
        var discussionMap = await dbase.query('Discussion', where: 'id=?',
            whereArgs: [discussionId]);
        _postList = await db.getObjectsById(object: Post, id: discussionId)
                         as List<Post>;
        setState(() {
          postList=_postList;
          if (discussionMap.isNotEmpty) {
            discussion=Discussion.fromMap(discussionMap[0]);
          }
          loading = false;
        });
      }
    } else {
      print('payload is null');
      setState(() {
        loading=false;
      });
    }
  }

  @override
  initState() {
    print('postpage init');
    getPosts();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    print('postspage');
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFFCF118C),
        title: RichText(
            text: TextSpan(
                text: widget.discussion?.title?? discussion?.title??'',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold
                )
            )
        ),
        actions: [
          connected
          ? SizedBox()
          : IconButton(
            icon: Icon(Icons.refresh, size: 30),
            onPressed: () async{
              setState(() {
                loading=true;
                connected=true;
              });
              await Future.delayed(Duration(seconds: 1));
              await getPosts();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          loading
            ? Container(
              child: Column(
                children: [
                  SizedBox(height: 2,),
                  LinearProgressIndicator(
                    minHeight: 4,
                    color: Color(0xFFCF118C),
                    backgroundColor: Colors.grey,
                  )
                ],
              )
              )
            : connected
              ? SizedBox()
              : Container(
                child: Column(
                  children: [
                    Text('εκτός σύνδεσης', style: TextStyle(color: Colors.red),),
                    Text(updateTime)
                  ],
                ),
              ),
           Expanded(
              child: postList.isEmpty
                ? Container(
                    child: Center(
                      child: Text(loading? 'σύνδεση...':'Δεν υπάρχουν δεδομένα',
                        style: TextStyle(
                          fontSize: 16
                        ),
                      ),
                    ),
                  )
                : ListView(
                 children: postList.map((e) =>
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.person,
                                  size: 16,
                                  color: Colors.grey[700],
                                ),
                                SizedBox(width: 4,),
                                Text(e.author,
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold
                                  ),
                                ),
                              ],
                            ),
                            Text(e.dateTime,
                              style: TextStyle(
                                color: Colors.grey[700]
                              ),
                            ),
                            Divider(
                              indent: 4,
                              endIndent: 20,
                              color: Colors.grey[300],
                              thickness: 1,
                            ),
                            SizedBox(height: 4,),
                            Text(e.title,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold
                              ),
                              textAlign: TextAlign.left,
                            ),
                            SizedBox(height: 6,),
                            Text(e.content,
                              style: TextStyle(
                                fontSize: 16
                              ),
                            )
                          ],
                        ),
                      ),
                    )
                ).toList()
              ),
            ),
        ],
      ),
    );
  }
}
