import 'package:flutter/material.dart';
import 'package:gio_app/Services/HttpServices.dart';
import '../Services/DatabaseServices.dart';
import '../Models.dart';
import 'PostsPage.dart';


class DiscussionsPage extends StatefulWidget {
  const DiscussionsPage({
    this.forum,
    Key? key}) : super(key: key);

  final Forum? forum;

  @override
  _DiscussionsPageState createState() => _DiscussionsPageState();
}

class _DiscussionsPageState extends State<DiscussionsPage> {

  List<Discussion> discussionList=[];
  bool loading = true;
  bool connected = true;
  String updateTime='';

  Future<void> getDiscussions() async {
    List<Discussion> _discussionList=[];
    if (widget.forum!=null) {
      var db=DatabaseServices.instance;
      _discussionList=await db.getObjectsById(object: Discussion, id: widget.forum!.id!)
                            as List<Discussion>;
      setState(() {
        discussionList=_discussionList;
      });
      var study = HttpServices();
      var html = await study.getHtml(widget.forum!.link);
      if (html!=null) {
        _discussionList=study.getDiscussions(html, widget.forum!.id!);
        await db.updateDB(newData: _discussionList, whereId: 'forumId', id: widget.forum!.id!);
        await db.setUpdateTime(object: 'discussions', foreignId: widget.forum!.id!);
        _discussionList = await db.getObjectsById(object: Discussion,
                               id: widget.forum!.id!) as List<Discussion>;
        if (mounted) {
          setState(() {
            discussionList=_discussionList;
            loading=false;
          });
        }
      } else {
        updateTime=await db.getUpdateTime(object: 'discussions', foreignId: widget.forum!.id!);
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
    } else {
      print('cannot get Discussions: widget.forum is null');
      setState(() {
        loading=false;
      });
    }
  }

  @override
  initState() {
    getDiscussions();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFFCF118C),
        title: RichText(
            text: TextSpan(
                text: widget.forum?.title?? '',
                style: TextStyle(
                    fontSize: 18,
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
              await getDiscussions();
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
                  SizedBox(height: 2),
                  LinearProgressIndicator(
                    minHeight: 4,
                    color: Color(0xFFCF118C),
                    backgroundColor: Colors.grey,
                  )
                  //SpinKitWave(color: Color(0xFFCF118C), size: 30,),
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
            child:
              discussionList.isEmpty
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
                  children: discussionList.map((e) =>
                    Card(
                      color: Colors.white,
                      child: InkWell(
                        child: Padding(
                          padding: const EdgeInsets.all(10.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(e.title,
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold
                                      ),
                                      textAlign: TextAlign.left,
                                    ),
                                  ),
                                  SizedBox(width: 4,),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('απαντήσεις: '+'${e.replies}',
                                        style: TextStyle(
                                          color: Colors.grey[600]
                                        ),
                                      ),
                                      Text('μη αναγνωσμένα: '+'${e.repliesUnread}',
                                        style: TextStyle(
                                          color: e.repliesUnread==0
                                                 ? Colors.grey[600]
                                                 : Colors.red[600],
                                          fontWeight: e.repliesUnread==0
                                              ? FontWeight.normal
                                              : FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 12,),
                              Row(
                                children: [
                                  Icon(Icons.person,
                                    size: 16,
                                    color: Colors.grey[700],
                                  ),
                                  SizedBox(width: 4),
                                  Text(e.authorFirst,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.bold
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ],
                              ),
                              SizedBox(height: 8,),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  //SizedBox(width: 4),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.start,
                                        children: [
                                          Icon(Icons.reply,
                                            textDirection: TextDirection.rtl,
                                            size: 16,
                                            color: Colors.grey[700],
                                          ),
                                          SizedBox(width: 4),
                                          Text(e.authorLast,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[700],
                                            ),
                                            textAlign: TextAlign.left,
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          SizedBox(width: 22,),
                                          Text(e.dateTime,
                                            textAlign: TextAlign.left,
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        onTap: () async {
                          Navigator.push(context, MaterialPageRoute(builder:
                              (context) => PostsPage(discussion: e)));
                          var db=DatabaseServices.instance;
                          var dbase=await db.database;
                          await dbase.update('Discussion', {'repliesUnread': 0},
                              where: 'id=?', whereArgs: [e.id]);
                          var _discussionList=await db.getObjectsById(object: Discussion,
                              id: widget.forum!.id!) as List<Discussion>;
                          if (mounted) {
                            setState(() {
                              discussionList=_discussionList;
                            });
                          }
                        },
                      )
                   ),
                ).toList()
              ),
            ),
        ],
      )
    );
  }
}
