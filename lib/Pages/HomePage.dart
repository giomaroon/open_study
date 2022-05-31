import 'package:flutter/material.dart';
import 'package:gio_app/Models.dart';
import 'package:gio_app/Pages/SettingsPage.dart';
import 'package:gio_app/Services/HttpServices.dart';
import 'package:gio_app/Pages/CoursesListPage.dart';
import '../main.dart' show activeUserId, notificationServices;
import 'EventsPage.dart';
import 'package:html/dom.dart' show Document;
import '../Services/DatabaseServices.dart';

class HomePage extends StatefulWidget {
  const HomePage(
      {this.html,
        Key? key}) : super(key: key);

  final Document? html;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  String? studentName;
  Document? html;
  User? user;
  bool loading=true;
  bool connected=true;

  Future<void> getUserStudyHtml() async {
    user = await DatabaseServices.instance.getUser(id: activeUserId);
    setState(() {
      studentName=user?.studentName;
    });
    if (widget.html==null) {
      print('homepage connecting...');
      var study=HttpServices();
      html = await study.getHtml('https://study.eap.gr/my/');
      if (html==null) {
        print('no connection');
        connected=false;
      } else {
        print('connected');
        studentName = html!.getElementsByClassName('usertext mr-1').isNotEmpty
            ? html!.getElementsByClassName('usertext mr-1')[0].text
            :'';
      }
    } else {
      html = widget.html;
    }
    setState(() {
      loading=false;
    });
  }

  @override
  void initState() {
    //print('homepage init');
    getUserStudyHtml();
    //notificationServices.initializeNotifications();
    notificationServices.requestIOSPermissions();
    notificationServices.onClickNotification(context);
    //onClickNotification();
    notificationServices.onClickNotificationIOS(context);
    //onClickNotificationIOS();
    super.initState();
  }

  @override
  void dispose() {
    //print('homepage dispose');
    notificationServices.streamNotification.close();
    notificationServices.streamNotificationIOS.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //print('homepage');
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFFCF118C),
        title: Center(
          child:
          Text(
            'STUDY',
            style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold
            ),
          ),
        ),
        //centerTitle: true,
        actions: [
          // connected
          //     ? SizedBox()
          //     : IconButton(
          //       icon: Icon(Icons.refresh, size: 30),
          //       onPressed: () async{
          //         setState(() {
          //           loading=true;
          //           connected=true;
          //         });
          //         await Future.delayed(Duration(seconds: 1));
          //         await getUserStudyHtml();
          //       },
          //     ),
          IconButton(
            icon: Icon(Icons.settings, size: 30),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder:
                  (context) => SettingsPage(user: user)));
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // loading
            // ? Container(
            //   child: Column(
            //     children: [
            //       SizedBox(height: 2),
            //       LinearProgressIndicator(
            //         minHeight: 4,
            //         color: Color(0xFFCF118C),
            //         backgroundColor: Colors.grey,
            //       ),
            //       SizedBox(height: 14)
            //     ],
            //   )
            // )
            // : connected
            //   ? SizedBox(height: 20,)
            //   : Container(
            //     height: 20,
            //     child: Text('εκτός σύνδεσης', style: TextStyle(color: Colors.red),),
            //   ),
            SizedBox(height: 24),
            Container(
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                  ),
                  //Image.network('https://study.eap.gr/pluginfile.php/170693/user/icon/lambda/f1.jpg'),
                  CircleAvatar(
                    radius: 26,
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.grey[500],
                    child: Icon(Icons.person, size: 36,),
                    //Image.network('https://study.eap.gr/pluginfile.php/170693/user/icon/lambda/f1?rev=16938601')
                  ),
                  SizedBox(
                    width: 20,
                  ),
                  Expanded(
                    child: RichText(
                        textAlign: TextAlign.start,
                        text: TextSpan(
                          text: studentName??'',
                          style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontWeight: FontWeight.bold
                          ),
                        )
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30,),
            Container(
              height: 200,
              width: 200,
              child: Card(
                color: Colors.white,
                child: InkWell(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.library_books, size: 36),
                        Text('Μαθήματα',
                            style: TextStyle(
                                color: Colors.black,fontSize: 30)
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder:
                        (context) => CoursesListPage(html: html,)));
                  },
                ),
              ),
            ),
            SizedBox(height: 30,),
            Container(
              height: 200,
              width: 200,

              child: Card(
                color: Colors.white,
                child: InkWell(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Icon(Icons.calendar_today, size: 36),
                        Text('Επικείμενα \n Γεγονότα',
                            style: TextStyle(
                                color: Colors.black,fontSize: 26)
                        ),
                      ],
                    ),
                  ),
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder:
                        (context) => EventsPage(html: html)));
                  },
                ),
              ),
            ),
            // TextButton(
            //   child: Text('Μαθήματα', style: TextStyle(color: Colors.black,fontSize: 18)),
            //   onPressed: () {
            //       Navigator.push(context, MaterialPageRoute(builder:
            //           (context) => CoursesListPage(html: html,)));
            //     }
            // ),
            // ElevatedButton(
            //   child: Text('Επικείμενα Γεγονότα', style: TextStyle(color: Colors.black,fontSize: 18)),
            //   style: ButtonStyle(
            //     backgroundColor:
            //     MaterialStateProperty.resolveWith((states) => Colors.white)
            //     ),
            //     onPressed: () {
            //       Navigator.push(context, MaterialPageRoute(builder:
            //           (context) => EventsPage(html: html)));
            //     }
            // ),

            // TextButton(
            //     child: Text('notification 1', style: TextStyle(color: Colors.black,fontSize: 18)),
            //     onPressed: () async {
            //       var db = DBServices.instance;
            //       var posts= await db.getObjectsById(object: Post, id: 6) as List<Post>;
            //       print(posts.map((e) => e.toMap()));
            //       print(posts.last.toMap());
            //       await notificationServices.showNotification(
            //           id: 14,
            //           title: 'Δεν υπάρχει εκφώνηση 2ης εργασιάς'+' : '+posts.last.author,
            //           body: posts.last.content,
            //           payload: 6.toString() + ' ' + '/PostsPage'
            //       );
            //
            //       // await notificationServices.showNotification(
            //       //   title: 'title 1',
            //       //   body: 'body 1',
            //       //   payload: '1 /CoursesListPage/CoursePage'
            //       // );
            //     }
            // ),
            // TextButton(
            //     child: Text('notification scheduled', style: TextStyle(color: Colors.black,fontSize: 18)),
            //     onPressed: () async {
            //       await notificationServices.showNotificationScheduled(
            //           title: 'title 1',
            //           body: 'body 1',
            //           payload: '1 /CoursesListPage/CoursePage'
            //       );
            //     }
            // ),
            // TextButton(
            //     child: Text('workmanager 1', style: TextStyle(color: Colors.black,fontSize: 18)),
            //     onPressed: () {
            //       // Workmanager().registerPeriodicTask(
            //       //     '1',
            //       //     'time',
            //       //     frequency: Duration(minutes: 15),
            //       //     initialDelay: Duration(seconds: 10)
            //       // );
            //       Workmanager().registerOneOffTask(
            //           '1',
            //           'event',
            //           initialDelay: Duration(seconds: 12));
            //     }
            // ),
            // TextButton(
            //     child: Text('workmanager 2', style: TextStyle(color: Colors.black,fontSize: 18)),
            //     onPressed: () {
            //       Workmanager().registerOneOffTask(
            //           '2',
            //           'post',
            //           initialDelay: Duration(seconds: 12)
            //       );
            //     }
            // ),
            // TextButton(
            //     child: Text('workmanager 3', style: TextStyle(color: Colors.black,fontSize: 18)),
            //     onPressed: () {
            //       Workmanager().registerOneOffTask(
            //           '3',
            //           'grade',
            //           initialDelay: Duration(seconds: 12)
            //       );
            //     }
            // ),
            // TextButton(
            //     child: Text('workmanager 4', style: TextStyle(color: Colors.black,fontSize: 18)),
            //     onPressed: () {
            //       Workmanager().registerOneOffTask(
            //           '4',
            //           'time',
            //           initialDelay: Duration(seconds: 5)
            //       );
            //     }
            // ),
            // TextButton(
            //     child: Text('workmanager cancel', style: TextStyle(color: Colors.black,fontSize: 18)),
            //     onPressed: () {
            //       // Workmanager().registerPeriodicTask(
            //       //     '1',
            //       //     'time',
            //       //     frequency: Duration(minutes: 15),
            //       //     initialDelay: Duration(seconds: 10)
            //       // );
            //       Workmanager().cancelAll();
            //       //Workmanager().cancelByUniqueName('1');
            //     }
            // ),
            // TextButton(
            //     child: Text('notification cancel', style: TextStyle(color: Colors.black,fontSize: 18)),
            //     onPressed: () {
            //       Workmanager().cancelAll();
            //       notificationServices.notifications.cancelAll();
            //       notificationServices.notifications.cancel(0);
            //     }
            // ),
          ],
        ),
      ),
    );
  }
}


