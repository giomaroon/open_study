import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gio_app/Pages/ChatPage.dart';
import 'package:gio_app/Services/DatabaseServices.dart';
import 'package:gio_app/Services/HttpServices.dart';
import '../main.dart' show activeUserId, server;
import '../Models.dart';

class MessengerPage extends StatefulWidget {
  const MessengerPage({
    this.sesskey,
    this.userStudyId,
    Key? key}) : super(key: key);

  final String? sesskey;
  final int? userStudyId;

  @override
  _MessengerPageState createState() => _MessengerPageState();
}

class _MessengerPageState extends State<MessengerPage> {
  List<Contact> contactList = [];
  bool loading = true;
  bool connected = true;
  String updateTime='';
  String sesskey='';
  int? userStudyId;
  Timer? timerperiodic;
  Timer? timerfinal;
  var unreadContacts=[];

  String url = 'https://study.eap.gr/message/index.php';

  var study=HttpServices();

  Future<void> getContacts() async {
    var db = DatabaseServices.instance;
    contactList = await db.getObjectsById(object: Contact, id: activeUserId)
    as List<Contact>;
    //print(contactList.map((e) => e.toMap()));
    if (contactList.isNotEmpty && mounted) {
      setState(() {});
    }

    bool isConnected=false;

    // ...A...   get sesskey, userStudyId from widget or http
    if (widget.sesskey != null && widget.userStudyId != null) {
      sesskey=widget.sesskey!;
      userStudyId=widget.userStudyId!;
      isConnected=true;
    } else {
      var html = await study.httpGetHtml('https://$server/my/');
      if (html!=null) {
        try {
          sesskey =html.getElementsByClassName('usermenu')[0].getElementsByTagName(
              'li')[9].children[0].attributes['href']!.split('?')[1];
          var getStudyUserId = html.getElementsByClassName('usermenu')[0]
              .getElementsByTagName('li')[3].children[0].attributes['href']!
              .split('=')[1];
          userStudyId = int.tryParse(getStudyUserId.toString())!;
          isConnected=true;
        } catch (err) { print(err);   }
      }
    }

    //...B... if sesskey, userStudy got, get json
    if (isConnected==true) {
      var jsonMessagesPreview = await study.httpGetJsonMessagesPreview(
          sesskey: widget.sesskey,
          userStudyId: widget.userStudyId.toString(),
          server: server
      );
      //debugPrint(jsonMessagesPreview.toString());
      if (jsonMessagesPreview.isNotEmpty &&
          jsonMessagesPreview['error'] == false) {
        unreadContacts = [];
        for (var e in jsonMessagesPreview['data']['contacts']) {
          if (e['isread'] == false) {
            unreadContacts.add(e['userid']);
          }
        }
        contactList =
            study.getContactsFromJson(jsonMessagesPreview, activeUserId);

        await db.updateDB(
            newData: contactList, whereId: 'userId', id: activeUserId);
        contactList = await db.getObjectsById(object: Contact, id: activeUserId)
        as List<Contact>;
        await db.setUpdateTime(object: 'contacts', foreignId: activeUserId);
        if (mounted) {
          setState(() {
            loading = false;
            connected = true;
          });
        }
      } else {
        print('y?');
        isConnected=false;
      }
    }

    //...C... if not connected get old from DB
    if (isConnected==false) { //... not connected
      print('not connected');
      updateTime =
      await db.getUpdateTime(object: 'contacts', foreignId: activeUserId);
      if (updateTime
          .split(':')
          .length > 1) {
        updateTime = 'Τελευταία ενημέρωση: ' + updateTime.split(':')[0] + ':' +
            updateTime.split(':')[1];
      }
      if (mounted) {
        setState(() {
          loading = false;
          connected = false;
        });
      }
    }
  }


  void setTimer() {
    print('contacts timer starts');
    timerperiodic=Timer.periodic(const Duration(seconds: 20), (timer) {
      print('contacts timer tick: ${timer.tick}');
      getContacts();
    });
  }

  void setTimerFinal() {
    timerfinal=Timer(const Duration(minutes: 10), () {
      print('timerfinal');
      timerperiodic?.cancel();
    });
  }


  @override
  initState() {
    getContacts();
    setTimer();
    setTimerFinal();
    super.initState();
  }

  @override
  void dispose() {
    timerperiodic?.cancel();
    timerfinal?.cancel();
    print('Cancel contact timer');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8E8E8), //Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFFCF118C),
        title: Center(
          child: Text(
            'Μηνύματα    ',
            style: TextStyle(
                color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
          ),
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
              await getContacts();
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
                ))
              : connected
                  ? SizedBox()
                  : Container(
                      child: Column(
                        children: [
                          Text(
                            'εκτός σύνδεσης',
                            style: TextStyle(color: Colors.red),
                          ),
                          Text(updateTime)
                        ],
                      ),
                    ),
          Expanded(
            child: contactList.isEmpty
                ? Container(
                    child: Center(
                      child: Text(
                        loading ? 'σύνδεση...' : 'Δεν υπάρχουν δεδομένα',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  )
                : ListView(
                    children: contactList.map((e) =>
                        Card(
                              color: Colors.white,
                              child: InkWell(
                                child: Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.person,
                                            size: 18,
                                            color: Colors.grey[700],
                                          ),
                                          SizedBox(width: 4),
                                          Text(
                                            e.name,
                                            style: TextStyle(
                                                fontSize: 16,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.bold),
                                            textAlign: TextAlign.left,
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 8,
                                      ),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.start,
                                        children: [
                                          // Icon(
                                          //   Icons.reply,
                                          //   textDirection:
                                          //       TextDirection.rtl,
                                          //   size: 16,
                                          //   color: Colors.grey[700],
                                          // ),
                                          SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              e.lastMessage,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: unreadContacts.contains(e.link)
                                                    ? FontWeight.bold
                                                    : FontWeight.normal
                                                //color: Colors.grey[700],
                                              ),
                                              textAlign: TextAlign.left,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                onTap: () async {
                                  timerperiodic?.cancel();
                                  timerfinal?.cancel();
                                  print('Cancel contact timer');
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              ChatPage(
                                                sesskey: widget.sesskey,
                                                userStudyId: widget.userStudyId,
                                                contact: e,)))
                                      .then((value) async {
                                    //loading=true;
                                    await getContacts();
                                    setTimer();
                                    setTimerFinal();
                                    // if (mounted) {
                                    //   setState(() {});
                                    // }
                                  }
                                  );

                                },
                              )),
                        )
                        .toList()),
          ),
        ],
      ),
    );
  }
}
