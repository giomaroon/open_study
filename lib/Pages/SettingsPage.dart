import 'package:flutter/material.dart';
import 'package:gio_app/Services/BackgroundServices.dart';
import 'package:gio_app/Services/DataBaseServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models.dart';
import '../main.dart' show activeUserId;
import 'LoginPage.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({
    this.user,
    Key? key}) : super(key: key);

  final User? user;

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {

  bool eventNotification=false;
  bool postNotification=false;
  bool gradeNotification=false;
  //bool value = true;
  User? user;
  var db=DBServices.instance;

  Future<void> getUserSettings() async {

    user = await db.getUser(id: activeUserId);
  eventNotification=user!.eventNotification==1
      ? true
      : false;
  postNotification=user!.postNotification==1
      ? true
      : false;
  gradeNotification=user!.gradeNotification==1
      ? true
      : false;
  setState(() { });
  }

  @override
  void initState() {
    getUserSettings();
    super.initState();
  }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFFCF118C),
        title: Container(
          child: Text('Ρυθμίσεις',
            style: TextStyle(
                color: Colors.black,
                fontSize: 20),
          ),
        ),
      ),
      body: ListView(
        children: [
          //SizedBox(height: 10),
          Container(
            alignment: Alignment.centerLeft,
            color: Colors.white,
            height: 80,
            child: Row(
              children: [
                SizedBox(width: 14),
                Icon(
                  Icons.notifications,
                  color: Colors.grey[800],
                  size: 30,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 8, 8 ),
                  child: Text('Ειδοποιήσεις',
                    style: TextStyle(
                      fontSize: 20
                    ),
                  ),
                ),
              ],
            ),
          ),
          SwitchListTile(
            activeColor: Color(0xFFCF118C),
            tileColor: Colors.white,
            title: Row(
              children: [
                SizedBox(width: 6),
                Text('Επικείμενα γεγονότα',
                  style: TextStyle(
                      fontSize: 18
                  ),),
              ],
            ),
              value: eventNotification,
              onChanged: (val) async {
                setState (() { eventNotification = val; });
                await activateEventNotifications(val, user!.id!);
              }
          ),
          //SizedBox(height: 10),
          SwitchListTile(
              activeColor: Color(0xFFCF118C),
              tileColor: Colors.white,
              title: Row(
                children: [
                  SizedBox(width: 6),
                  Text('Νέες δημοσιεύσεις',
                    style: TextStyle(
                        fontSize: 18
                    ),),
                ],
              ),
              value: postNotification,
              onChanged: (val) async {
                setState (() { postNotification = val; });
                await activatePostNotifications(val, user!.id!);
              }
          ),
          SwitchListTile(
              activeColor: Color(0xFFCF118C),
              tileColor: Colors.white,
              title: Row(
                children: [
                  SizedBox(width: 6),
                  Text('Βαθμολογία',
                    style: TextStyle(
                        fontSize: 18
                    ),),
                ],
              ),
              value: gradeNotification,
              onChanged: (val) async {
                setState (() { gradeNotification = val; });
                await activateGradeNotifications(val, user!.id!);
              }
          ),
          Divider(height: 4),
          Container(
            //height: 100,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22,18,22,18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Flexible(
                      child: Text('Αποσύνδεση και διαγραφή λογαριασμού στη συσκευή',
                          style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[800]
                          )
                      ),
                    ),
                  ),
                  SizedBox(width: 60),
                  IconButton(
                    icon: Icon(Icons.delete, size: 38),
                    color: Colors.grey[800],
                    onPressed: () async {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) =>
                          AlertDialog(
                            //title: const Text('AlertDialog Title'),
                            content: Text('Είστε σίγουρος;',
                                style: TextStyle(
                                    color: Colors.grey[800],
                                    fontSize: 18
                                )
                            ),
                            actions: <Widget>[
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  TextButton(
                                    child: Text('Ναι',
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontSize: 20
                                      )
                                    ),
                                    onPressed: () async {
                                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder:
                                          (context) => LoginPage()), (route) => false);
                                      await activateEventNotifications(false, user!.id!);
                                      await activatePostNotifications(false, user!.id!);
                                      await activateGradeNotifications(false, user!.id!);
                                      await db.removeAllById('User', column: 'id', id: activeUserId);
                                      SharedPreferences prefs = await SharedPreferences.getInstance();
                                      await prefs.setInt('userId', 0);
                                    },
                                  ),
                                  TextButton(
                                    child: Text('Οχι',
                                        style: TextStyle(
                                            color: Colors.grey[800],
                                            fontSize: 20
                                        )
                                    ),
                                    onPressed: () => Navigator.pop(context),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      );
                    }
                  )
                ],
              ),
            ),
          ),
          Container(
            //height: 100,
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22,18,22,18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    child: Text('Αποσύνδεση',
                        style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[800]
                        )
                    ),
                  ),
                  SizedBox(width: 60),
                  IconButton(
                    icon: Icon(Icons.logout, size: 38),
                    color: Colors.grey[800],
                    onPressed: () async {
                      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder:
                          (context) => LoginPage()), (route) => false);
                      await activateEventNotifications(false, user!.id!);
                      await activatePostNotifications(false, user!.id!);
                      await activateGradeNotifications(false, user!.id!);
                      SharedPreferences prefs = await SharedPreferences.getInstance();
                      await prefs.setInt('userId', 0);
                    },
                  ),
                ],
              ),
            ),
          ),
        ]
      ),
    );
  }
}
