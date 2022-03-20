import 'package:flutter/material.dart';
import 'package:gio_app/Services/HttpServices.dart';
import 'package:gio_app/main.dart';
import 'package:html/dom.dart' show Document;
import '../Services/DatabaseServices.dart';
import '../Models.dart';
import 'CoursePage.dart';

class CoursesListPage extends StatefulWidget {
  const CoursesListPage({
    this.html,
    Key? key}) : super(key: key);

  final Document? html;

  @override
  _CoursesListPageState createState() => _CoursesListPageState();
}

class _CoursesListPageState extends State<CoursesListPage> {
  List<Course> courseList = [];
  bool loading = true;
  bool connected = true;

  Future<void> getCourses() async {
    List<Course> _courseList = [];
    var db = DatabaseServices.instance;
    _courseList = await db.getObjectsById(object: Course, id: activeUserId)
        as List<Course>;
    setState(() {
      courseList = _courseList;
    });
    // get data from study.gr and check if are new............
    var study = HttpServices();
    if (widget.html != null) {
      _courseList = study.getCourses(widget.html!, activeUserId);

    } else  {
      print('widget.html is null');
      var html = await study.getHtml('https://study.eap.gr/my/');
      if (html != null) {
        _courseList = study.getCourses(html, activeUserId);
      } else {
        connected = false;
      }
    }
    if (connected) {
      await db.updateDB(newData: _courseList, whereId: 'userId', id: activeUserId);
      _courseList = await db.getObjectsById(object: Course, id: activeUserId)
      as List<Course>;
      setState(() {
        courseList=_courseList;
        loading = false;
      });
    } else {
      if (mounted) {
        setState(() {
          connected=false;
          loading = false;
        });
      }
    }
  }

  @override
  initState() {
    getCourses();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: Colors.grey[200],
        appBar: AppBar(
          backgroundColor: Color(0xFFCF118C),
          title: Text('Μαθήματα'),
          // actions: [
          //   connected
          //       ? SizedBox()
          //       : IconButton(
          //         icon: Icon(Icons.refresh, size: 30),
          //         onPressed: () async{
          //           setState(() {
          //             loading=true;
          //             connected=true;
          //           });
          //           await Future.delayed(Duration(seconds: 1));
          //           await getCourses();
          //         },
          //       ),
          // ],
        ),
        body: Column(
          children: [
            // loading
            //     ? Container(
            //         child: Column(
            //         children: [
            //           // Container(
            //           //   child: Text('σύνδεση...'),
            //           // ),
            //           SizedBox(
            //             height: 2,
            //           ),
            //           LinearProgressIndicator(
            //             minHeight: 4,
            //             color: Color(0xFFCF118C),
            //             backgroundColor: Colors.grey,
            //           )
            //         ],
            //       ))
            //     : connected
            //         ? SizedBox()
            //         : Container(
            //             child: Text(
            //               'εκτός σύνδεσης',
            //               style: TextStyle(color: Colors.red),
            //             ),
            //           ),
            Expanded(
                child: courseList.isEmpty
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
                        children: courseList.map((course) =>
                            Card(
                              child: ListTile(
                                leading: Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 16, 0, 20),
                                  child: Icon(Icons.library_books,
                                    size: 28,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                tileColor: Colors.white,
                                title: Padding(
                                  padding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
                                  child: Text(
                                    course.title,
                                    style: TextStyle(
                                        fontSize: 18, fontFamily: 'Arial'),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                                onTap: () {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              CoursePage(course: course)));
                                },
                                )
                            )
                        ).toList()
                )
            ),
          ],
        )
    );
  }
}
