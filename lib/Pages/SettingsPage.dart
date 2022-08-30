import 'package:flutter/material.dart';
import 'package:gio_app/Services/BackgroundServices.dart';
import 'package:gio_app/Services/DatabaseServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models.dart';
import '../main.dart' show activeUserId, server;
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
  int messageNotifTime=0;
  User? user;
  var db=DatabaseServices.instance;
  Map<int,int> timeToValue={0: 0, 1: 1, 2: 2, 3: 3, 4:4, 8: 5, 12: 6, 24: 7};
  Map<int,int> valueToTime={0: 0, 1: 1, 2: 2, 3: 3, 4: 4, 5: 8, 6: 12, 7: 24};

  Future<void> getUserSettings() async {
    user = await db.getUser(id: activeUserId);
    eventNotif=user!.eventNotification==1? true: false;
    postNotifTime=user!.postNotification;
    messageNotifTime=user!.messageNotification;
    gradeNotif=user!.gradeNotification==1? true: false;
    setState(() { });
  }

  Future<dynamic> aboutNotifications(BuildContext loginPageContext) async {
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          AlertDialog(
            content: Text('Η λειτουργία των ειδοποιήσεων πραγματοποιείται μέσω '
                'background services. Προκειμένου να είναι αποτελεσματική, '
                'πρέπει στη συσκευή να είναι απενεργοποιημένη η εξοικονόμηση μπαταρίας '
                'για τη συγκεκριμένη εφαρμογή. '
                'Η επιλογή αυτή βρίσκεται στις ρυθμίσεις της συσκευής για την εξοικονόμηση '
                'ενέργειας (battery performance-optimization).' ,
                style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 18
                )
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK',
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 20
                    )
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }


  @override
  void initState() {
    getUserSettings();
    super.initState();
  }  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8E8E8), //Colors.grey[200],
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      Spacer(),
                      IconButton(
                          onPressed: () {aboutNotifications(context);},
                          icon: Icon(Icons.info_outline_rounded,
                            size: 36,
                            color: Color(0xFFA50D70),
                          )
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
                          Text('Νέα μηνύματα ανά:  ',
                            style: TextStyle(
                                fontSize: 18
                            ),
                          ),
                          Text(messageNotifTime==0
                              ? '-'
                              : messageNotifTime.toString(),
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
                            thumbColor: messageNotifTime==0
                                ? Colors.white
                                : Color(0xFFCF118C),
                            trackHeight: 10,
                            activeTickMarkColor: Color(0xFFCF118C),
                            inactiveTickMarkColor: Colors.grey[400],
                          ),
                          child: Slider(
                            min: 0,
                            max: 7,
                            divisions: 7,
                            value: timeToValue[messageNotifTime]!.toDouble(),
                            onChanged: (a) {
                              setState(() {
                                messageNotifTime = valueToTime[a]!;
                                //postNotifTime=(4*a+a*(a-1)*(a-2)*(a-3)/3).toInt();
                              });
                            },
                            onChangeEnd: (a) async {
                              print(messageNotifTime);
                              await activateMessageNotifications(time: messageNotifTime);
                              var dbase= await db.database;
                              await dbase.update('User',
                                  {'messageNotification': messageNotifTime,},
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
                            max: 7,
                            divisions: 7,
                            value: timeToValue[postNotifTime]!.toDouble(),
                            onChanged: (a) {
                              setState(() {
                                postNotifTime = valueToTime[a]!;
                                //postNotifTime=(4*a+a*(a-1)*(a-2)*(a-3)/3).toInt();
                              });
                            },
                            onChangeEnd: (a) async {
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
                                                server='';
                                                Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder:
                                                    (context) => LoginPage()), (route) => false);
                                                SharedPreferences prefs = await SharedPreferences.getInstance();
                                                await prefs.setInt('userId', 0);
                                                await activateEventNotifications(false, user!.id!);
                                                await activatePostNotifications(time: 0);
                                                await activateMessageNotifications(time: 0);
                                                await activateGradeNotifications(false);
                                                await db.removeAllById('User', column: 'id', id: activeUserId);

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
                            server='';
                            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder:
                                (context) => LoginPage()), (route) => false);
                            SharedPreferences prefs = await SharedPreferences.getInstance();
                            await prefs.setInt('userId', 0);
                            await activateEventNotifications(false, user!.id!);
                            await activatePostNotifications(time: 0);
                            await activateMessageNotifications(time: 0);
                            await activateGradeNotifications(false);

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
