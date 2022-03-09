import 'package:flutter/material.dart';
import 'package:gio_app/Services/HttpServices.dart';
import 'dart:async';
import '../Services/DatabaseServices.dart';
import '../Models.dart';
import 'DiscussionsPage.dart';
import 'AssignsPage.dart';

class CoursePage extends StatefulWidget {
  const CoursePage({
    this.course,
    this.payloadCourseId,
    Key? key}) : super(key: key);

  final Course? course;
  final String? payloadCourseId;


  @override
  _CoursePageState createState() => _CoursePageState();
}

class _CoursePageState extends State<CoursePage> {

  Course? course;
  List<Forum> forumList=[];
  //List<Grade> gradeLinks=[];
  String unread='';
  bool loading=true;
  bool connected=true;
  bool assignsExist=false;

  Future<void> getForumsAssigns(BuildContext context) async {
    List<Forum> _forumList = [];
    List<Assign> _assignList = [];
    var db = DatabaseServices.instance;
    if (widget.course != null) {
      _forumList=await db.getObjectsById(object: Forum, id: widget.course!.id!)
                 as List<Forum>;
      _assignList=await db.getObjectsById(object: Assign, id: widget.course!.id!)
                   as List<Assign>;
      setState(() {
        assignsExist=_assignList.isNotEmpty;
        forumList=_forumList;
      });
      var study = HttpServices();
      var html = await study.getHtml(widget.course!.link);
      if (html != null) {
        _forumList = study.getForums(html, widget.course!.id!);
        //print(_forumList.map((e) => e.toMap()));
        _assignList = study.getAssigns(html, widget.course!.id!);
        await db.updateDB(newData: _forumList, whereId: 'courseId', id: widget.course!.id!);
        await db.updateDB(newData: _assignList, whereId: 'courseId', id: widget.course!.id!);
        assignsExist = true;
        _forumList =await db.getObjectsById(object: Forum, id: widget.course!.id!)
                    as List<Forum>;
        //print(_forumList.map((e) => e.toMap()));
        _assignList=await db.getObjectsById(object: Assign, id: widget.course!.id!)
                     as List<Assign>;
        if (mounted) {
          setState(() {
            forumList=_forumList;
            assignsExist=_assignList.isNotEmpty;
            loading = false;
          });
        }
      } else {
        print('http error');
        if (mounted) {
          setState(() {
            loading = false;
            connected=false;
          });
        }
      }
    } else {
      print('cannot get Forums, assignLinks: widget.course is null');
      setState(() {
        loading = false;
      });
    }
  }

  @override
  initState() {
    getForumsAssigns(this.context);
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
            text: widget.course?.title?? '',
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
              await getForumsAssigns(context);
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
              ],
            )
          )
          : connected
            ? SizedBox()
            : Container(
              child: Text('εκτός σύνδεσης', style: TextStyle(color: Colors.red),),
          ),
          assignsExist
          ? Card(
              child: ListTile(
                leading: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 20),
                  child: Icon(Icons.assignment_outlined,
                    size: 26,
                    color: Colors.grey[800],
                  ),
                ),
                tileColor: Colors.white,
                title: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                  child: Text(
                    'Βαθμολογία',
                    style: TextStyle(fontSize: 18, fontFamily: 'Arial'),
                    textAlign: TextAlign.left,
                  ),
                ),
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder:
                          (context) => AssignsPage(course: widget.course, )));
                },
                onLongPress: () {},
              )
          )
          : SizedBox(),
          Container(
            //alignment: Alignment.centerLeft,
            padding: EdgeInsets.all(10),
            //height: 30,
            child: Text(
              'Ομάδες Συζητήσεων',
              style: TextStyle(
                  fontSize: 16, fontFamily: 'Arial', fontWeight: FontWeight.bold),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: forumList.isEmpty
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
                children: forumList.map((e) =>
                  Card(
                    child: ListTile(
                      tileColor: Colors.white,
                      leading: Padding(
                        padding: const EdgeInsets.fromLTRB(0, 16, 0, 20),
                        child: Icon(Icons.forum_rounded,
                          size: 26,
                          color: Colors.grey[800],
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                              child: Text(e.title,
                                style: TextStyle(
                                    fontSize: 18,
                                    fontFamily: 'Arial'
                                ),
                                textAlign: TextAlign.left,
                              ),
                            ),
                          ),
                          SizedBox(width: 12,),
                          e.unread!=''
                          ? Text('νέες \n αναρτήσεις',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.bold
                            ),
                          )
                          : SizedBox()
                        ],
                      ),
                      //leading: Text(e.id==null ? 'id' : '${e.id}' ),
                      onTap: () async {
                        Navigator.push(context, MaterialPageRoute(builder:
                            (context) => DiscussionsPage(forum: e)))
                              .then((value) async {
                                //loading=true;
                                await getForumsAssigns(this.context);
                                if (mounted) {
                                  setState(() {}); // TODO loading = true
                                }
                              }
                            );
                        // if (e.unread!='') {
                        //   var db=await DBServices.instance.database;
                        // await db.update('Forum', {'unread':''}, where: 'id=?', whereArgs: [e.id]);
                        // }
                      },
                      onLongPress: () {},
                    )
                  )
              ).toList()
            ),
          )
        ]
      )
    );
  }
}
