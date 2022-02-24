import 'package:flutter/material.dart';
import 'package:gio_app/Services/HttpServices.dart';
import '../Services/DataBaseServices.dart';
import '../Models.dart';

class GradesPage extends StatefulWidget {
  const GradesPage({
    this.course,
    this.payloadCourseId,
    Key? key}) : super(key: key);

  final Course? course;
  final String? payloadCourseId;

  @override
  _GradesPageState createState() => _GradesPageState();
}

class _GradesPageState extends State<GradesPage> {

  List<Grade> gradeList = [];
  bool loading = true;
  bool connected=true;
  bool newGrade=false;
  String updateTime='';

  Future<void> getGrades() async {
    List<Grade> _gradeList=[];
    if (widget.course?.id !=null) {
      var courseId = widget.course!.id;
      var db= DBServices.instance;
      _gradeList=await db.getObjectsById(object: Grade, id: courseId)
                     as List<Grade>;
      setState(() {
        gradeList=_gradeList;
      });
      var dbase = await db.database;
      var emptyGradeLinks = await dbase.query('Grade', columns: ['linkId'], where: 'grade=? AND courseId=?',
                                      whereArgs: ['', courseId]);
      if (emptyGradeLinks.isNotEmpty) {
        var study=HttpServices();
        for (var e in emptyGradeLinks) {
          var html = await study.getHtml(e['linkId'].toString());
          if (html!=null) {
            var grade=study.getGrade(html);
            if (grade != '') {
              newGrade=true;
              await dbase.update('Grade', {'grade': grade}, where: 'linkId=? AND courseId=?',
                               whereArgs: [e['linkId'], courseId]);
            } else if (grade == '') {
              break;
            }
            await db.setUpdateTime(object: 'grades', foreignId: courseId!);
          } else {
            updateTime=await db.getUpdateTime(object: 'grades', foreignId: courseId!);
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
          _gradeList = await db.getObjectsById(object: Grade, id: courseId) as List<Grade>;
          if (mounted) {
            setState(() {
              gradeList=_gradeList;
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
        var db = DBServices.instance;
        _gradeList = await db.getObjectsById(object: Grade, id: courseId) as List<Grade>;
        setState(() {
          gradeList=_gradeList;
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
                child: gradeList.isEmpty
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
                      children: gradeList.map((e) =>
                        Card(
                        child: ListTile(
                        tileColor: Colors.white,
                        title: Text(e.assign+' :  '+e.grade,
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