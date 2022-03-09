import 'package:flutter/material.dart';
import 'package:gio_app/Services/HttpServices.dart';
import '../Services/DatabaseServices.dart';
import '../Models.dart';

class AssignsPage extends StatefulWidget {
  const AssignsPage({
    this.course,
    this.payloadCourseId,
    Key? key}) : super(key: key);

  final Course? course;
  final String? payloadCourseId;

  @override
  _AssignsPageState createState() => _AssignsPageState();
}

class _AssignsPageState extends State<AssignsPage> {

  List<Assign> assignList = [];
  bool loading = true;
  bool connected=true;
  bool newGrade=false;
  String updateTime='';

  Future<void> getGrades() async {
    List<Assign> _assignList=[];
    if (widget.course?.id !=null) {
      var courseId = widget.course!.id;
      var db= DatabaseServices.instance;
      _assignList=await db.getObjectsById(object: Assign, id: courseId)
                     as List<Assign>;
      setState(() {
        assignList=_assignList;
      });
      var dbase = await db.database;
      var emptyGradeLinks = await dbase.query('Assign', columns: ['link'], where: 'grade=? AND courseId=?',
                                      whereArgs: ['', courseId]);
      if (emptyGradeLinks.isNotEmpty) {
        var study=HttpServices();
        for (var e in emptyGradeLinks) {
          var html = await study.getHtml(e['link'].toString());
          if (html!=null) {
            var grade=study.getGrade(html);
            if (grade != '') {
              newGrade=true;
              await dbase.update('Assign', {'grade': grade}, where: 'link=? AND courseId=?',
                               whereArgs: [e['link'], courseId]);
            } else if (grade == '') {
              break;
            }
            await db.setUpdateTime(object: 'assigns', foreignId: courseId!);
          } else {
            updateTime=await db.getUpdateTime(object: 'assigns', foreignId: courseId!);
            if (updateTime.split(':').length>1) {
              updateTime='Τελευταία ενημέρωση: '+updateTime.split(':')[0]+':'+updateTime.split(':')[1];
            }
            if (mounted) {
              setState(() {
                loading=false;
                connected=false;
              });
            }
            break;
          }
        }
        if (newGrade) {
          _assignList = await db.getObjectsById(object: Assign, id: courseId) as List<Assign>;
          if (mounted) {
            setState(() {
              assignList=_assignList;
              loading=false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              loading=false;
            });
          }
        }
      }
    } else if (widget.payloadCourseId != null) {
      print('widget.course is null, get courseId from payload');
      var courseId = int.tryParse(widget.payloadCourseId!);
      if (courseId != null) {
        var db = DatabaseServices.instance;
        _assignList = await db.getObjectsById(object: Assign, id: courseId) as List<Assign>;
        setState(() {
          assignList=_assignList;
          loading = false;
        });
      }
    } else {
      print('payload is null');
      setState(() {
        loading = false;
      });
    }
  }

  @override
  initState() {
    getGrades();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFFCF118C),
        title: Text('Βαθμολογία'),
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
              await getGrades();
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
                child: assignList.isEmpty
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
                      children: assignList.map((e) =>
                        Card(
                        child: ListTile(
                        tileColor: Colors.white,
                        title: Text(e.title+' :  '+e.grade,
                          style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Arial'
                          ),
                          textAlign: TextAlign.left,
                        ),
                        //leading: Text(e.id==null ? 'id' : '${e.id}' ),
                        onTap: () { },
                        onLongPress: () {},
                        )
                      )
                    ).toList()
                 ),
              ),
        ],
      )
    );
  }
}
