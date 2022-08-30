import 'package:flutter/material.dart';
import 'package:gio_app/Models.dart';
import 'package:gio_app/Pages/SettingsPage.dart';
import 'package:gio_app/Services/HttpServices.dart';
import 'package:gio_app/Pages/CoursesListPage.dart';
import '../main.dart' show activeUserId, notificationServices, server;
import 'EventsPage.dart';
import 'package:html/dom.dart' show Document;
import '../Services/DatabaseServices.dart';
import 'MessengerPage.dart';
import 'package:badges/badges.dart';

class HomePage extends StatefulWidget {
  const HomePage(
      {this.messageCounter,
        this.html,
        Key? key}) : super(key: key);

  final Document? html;
  final String? messageCounter;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  String? studentName;
  Document? html;
  User? user;
  bool loading=true;
  bool connected=true;
  String messageCounter='0';
  String sesskey='';
  int? userStudyId;

  Future<void> getUserStudyHtml() async {

    user = await DatabaseServices.instance.getUser(id: activeUserId);
    setState(() {
      studentName=user?.studentName;
    });

    if (widget.html==null) {
      print('homepage: connecting...');
      var study=HttpServices();
      html = await study.httpGetHtml('https://$server/my/');
      if (html==null) {
        print('no connection');
        connected=false;
      } else {
        //print('connected');
        if (html!.getElementsByClassName('usertext mr-1').isEmpty) {
          print('didnt got study/my, didnt got studentname');
        } else {
          studentName = html!.getElementsByClassName('usertext mr-1')[0].text;
          if (html!.getElementsByClassName('count-container').isNotEmpty) {
            messageCounter=html!.getElementsByClassName('count-container')[0].text;
            print('messc count: $messageCounter');
          }
        }
      }
    } else {
      html = widget.html;
      messageCounter=widget.messageCounter!;
    }
    try {
      sesskey=html!.getElementsByClassName('usermenu')[0].getElementsByTagName('li')[9].children[0].attributes['href']!.split('?')[1];
      //print(sesskey);
      var getStudyUserId=html!.getElementsByClassName('usermenu')[0].getElementsByTagName('li')[3].children[0].attributes['href']!.split('=')[1];
      //print(getStudyUserId);
      userStudyId=int.tryParse(getStudyUserId.toString())!;
    } catch (err) {
      print('err');
    }

    setState(() {
      loading=false;
    });
  }

  @override
  void initState() {
    getUserStudyHtml();
    notificationServices.requestIOSPermissions();
    notificationServices.onClickNotification(context);
    notificationServices.onClickNotificationIOS(context);
    super.initState();
  }

  @override
  void dispose() {
    notificationServices.streamNotification.close();
    notificationServices.streamNotificationIOS.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8E8E8), //Colors.grey[300],
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
          Badge(
            showBadge:  messageCounter!='0',
            badgeContent: Text(messageCounter),
            position: BadgePosition.topEnd(top: 2, end: 2),
            child: IconButton(
              icon: Icon(Icons.messenger, size: 34),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder:
                    (context) => MessengerPage(sesskey: sesskey,
                        userStudyId: userStudyId)))
                    .then((value) {
                  //loading=true;
                  getUserStudyHtml();

                }
                );
              },
            ),
          ),
          SizedBox(width: 6,)
          // IconButton(
          //   icon: Icon(Icons.settings, size: 30),
          //   onPressed: () {
          //     Navigator.push(context, MaterialPageRoute(builder:
          //         (context) => SettingsPage(user: user)));
          //   },
          // ),
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
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder:
                          (context) => SettingsPage(user: user)));
                    },
                    child: CircleAvatar(
                      radius: 26,
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.grey[500],
                      child: Icon(Icons.person, size: 36,),
                    ),
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
            //   child: Text('SP'),
            //   onPressed: () async {
            //     var prefs = await SharedPreferences.getInstance();
            //     //var payload = prefs.getString('payload');
            //     //var initialRoute=prefs.getString('initialRoute');
            //     var tick=prefs.getString('tick');
            //     //print('payload: $payload');
            //     //print('initialRoute: $initialRoute');
            //     print('tick: $tick');
            //
            //   },
            // ),
            // TextButton(
            //   child: Text('DB'),
            //   onPressed: () async {
            //     var db = DatabaseServices.instance;
            //     var udb = await db.getUsers();
            //     var cdb = await db.getCourses();
            //     var edb = await db.getEvents();
            //     var fdb = await db.getForums();
            //     var ddb = await db.getDiscuccions();
            //     var pdb = await db.getPosts();
            //     var gdb = await db.getAssigns();
            //     print('users: '+udb.length.toString());
            //     print(udb.map((e) => e.toMap()));
            //     print('courses: '+cdb.length.toString());
            //     print(cdb.map((e) => e.toMap()));
            //     print('events: '+edb.length.toString());
            //     // edb.forEach((element) {print(element.linkId);});
            //     print(edb.map((e) => e.toMap()));
            //     print('forums: '+fdb.length.toString());
            //     print(fdb.map((e) => e.toMap()));
            //     print('discussions : '+ddb.length.toString());
            //     print(ddb.map((e) => e.toMap()));
            //     print('posts: '+pdb.length.toString());
            //     print(pdb.map((e) => e.toMap()));
            //     print('grades: '+gdb.length.toString());
            //     print(gdb.map((e) => e.toMap()));
            //   },
            // ),
            // TextButton(
            //   child: Text('DB2'),
            //   onPressed: () async {
            //     var db = DatabaseServices.instance;
            //     var udb = await db.getUsers();
            //     var cdb = await db.getCourses();
            //     var edb = await db.getEvents();
            //     var fdb = await db.getForums();
            //     var ddb = await db.getDiscuccions();
            //     var pdb = await db.getPosts();
            //     var gdb = await db.getAssigns();
            //     var contdb= await db.getContacts();
            //     var messdb= await db.getMessages();
            //     print('users: '+udb.length.toString());
            //     print(udb.map((e) => e.toMap()));
            //     print('courses: '+cdb.length.toString());
            //     print(cdb.map((e) => e.toMap()));
            //     print('events: '+edb.length.toString());
            //     // edb.forEach((element) {print(element.linkId);});
            //     print(edb.map((e) => e.toMap()));
            //     print('forums: '+fdb.length.toString());
            //     print(fdb.map((e) => e.toMap()));
            //     print('discussions : '+ddb.length.toString());
            //     print(ddb.map((e) => e.toMap()));
            //     print('posts: '+pdb.length.toString());
            //     print(pdb.map((e) => e.toMap()));
            //     print('grades: '+gdb.length.toString());
            //     print(gdb.map((e) => e.toMap()));
            //     print('contacts: '+contdb.length.toString());
            //     print(contdb.map((e) => e.toMap()));
            //     print('messages: '+messdb.length.toString());
            //     print(messdb.map((e) => e.toMap()));
            //   },
            // )
          ],
        ),
      ),
      // floatingActionButton: Badge(
      //   showBadge:  messageCounter!='0',
      //   badgeContent: Text(messageCounter),
      //   position: BadgePosition.topEnd(top: 20, end: 2),
      //   child: IconButton(
      //     padding: EdgeInsets.all(30),
      //     icon: Icon(Icons.message, size: 50, color: Colors.white,),
      //     onPressed: () {
      //       Navigator.push(context, MaterialPageRoute(builder:
      //           (context) => MessengerPage(sesskey: sesskey, userStudyId: userStudyId,)));
      //     },
      //   ),
      // ),
    );
  }
}


