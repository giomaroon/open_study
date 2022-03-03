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

  bool eventNotif=false;
  bool gradeNotif=false;
  int postNotifTime=0;
  User? user;
  var db=DBServices.instance;
  Map<int,int> valueFromTime={0:0,4:1,8:2,12:3,24:4};

  Future<void> getUserSettings() async {
    user = await db.getUser(id: activeUserId);
    eventNotif=user!.eventNotification==1
        ? true
        : false;
    postNotifTime=user!.postNotification;
    gradeNotif=user!.gradeNotification==1
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
            padding: EdgeInsets.all(4),
            alignment: Alignment.centerLeft,
            color: Colors.white,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SizedBox(width: 10),
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
                Divider(
                  color: Colors.grey[200],
                  thickness: 1.5,
                  indent: 20,
                  endIndent: 20,
                ),
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      SizedBox(height: 8),
                      Row(
                        children: [
                          SizedBox(width: 22),
                          Text('Νέες δημοσιεύσεις ανά:  ',
                            style: TextStyle(
                                fontSize: 18
                            ),
                          ),
                          Text(postNotifTime==0
                              ? '-'
                              : postNotifTime.toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold
                            ),
                          ),
                          Text('  ώρες',
                            style: TextStyle(
                                fontSize: 18
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.fromLTRB(14,4,14,0),
                        child: SliderTheme(
                          data: SliderThemeData(
                            activeTrackColor: Color(0xFFCF118C),
                            inactiveTrackColor: Colors.grey[400],
                            thumbColor: postNotifTime==0
                                ? Colors.white
                                : Color(0xFFCF118C),
                            trackHeight: 10,
                            activeTickMarkColor: Color(0xFFCF118C),
                            inactiveTickMarkColor: Colors.grey[400],
                          ),
                          child: Slider(
                            min: 0,
                            max: 4,
                            divisions: 4,
                            value: valueFromTime[postNotifTime]!.toDouble(),
                            onChanged: (a) {
                              setState(() {
                                postNotifTime=(4*a+a*(a-1)*(a-2)*(a-3)/3).toInt();
                              });
                            },
                            onChangeEnd: (a) async {
                              print('postnotiftime');
                              print(postNotifTime);
                              await activatePostNotifications(time: postNotifTime);
                              var dbase= await db.database;
                              await dbase.update('User',
                                  {'postNotification': postNotifTime,},
                                  where: 'id=?',
                                  whereArgs: [user!.id!]);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  color: Colors.grey[200],
                  thickness: 1.5,
                  indent: 20,
                  endIndent: 20,
                ),
                SwitchListTile(
                    activeColor: Color(0xFFCF118C),
                    tileColor: Colors.white,
                    title: Row(
                      children: [
                        SizedBox(width: 6),
                        Text('Επικείμενα γεγονότα',
                          //textAlign: TextAlign.start,
                          style: TextStyle(
                              fontSize: 18
                          ),),
                      ],
                    ),
                    value: eventNotif,
                    onChanged: (val) async {
                      setState (() { eventNotif = val; });
                      await activateEventNotifications(val, user!.id!);
                      var dbase= await db.database;
                      await dbase.update('User',
                          {'eventNotification': val? 1: 0},
                          where: 'id=?',
                          whereArgs: [user!.id!]);
                    }
                ),
                Divider(
                  color: Colors.grey[200],
                  thickness: 1.5,
                  indent: 20,
                  endIndent: 20,
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
                    value: gradeNotif,
                    onChanged: (val) async {
                      setState (() { gradeNotif = val; });
                      await activateGradeNotifications(val);
                      var dbase= await db.database;
                      await dbase.update('User',
                          {'gradeNotification': val? 1: 0},
                          where: 'id=?',
                          whereArgs: [user!.id!]);
                    }
                ),
              ],
            ),
          ),
          Divider(height: 6),
          Container(
            color: Colors.white,
            child: Column(
              children: [
                Container(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22,18,22,18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          child: Flexible(
                            child: Text('Αποσύνδεση και διαγραφή λογαριασμού από τη συσκευή',
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
                                                await activatePostNotifications(time: 0);
                                                await activateGradeNotifications(false);
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
                Divider(
                  color: Colors.grey[200],
                  thickness: 1.5,
                  indent: 20,
                  endIndent: 20,
                ),
                Container(
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
                            await activatePostNotifications(time: 0);
                            await activateGradeNotifications(false);
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            await prefs.setInt('userId', 0);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ]
      ),
    );
  }
}
