import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gio_app/Services/HttpServices.dart';
import 'package:gio_app/Services/DatabaseServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart' show activeUserId;

import '../Models.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({
    this.sesskey,
    this.userStudyId,
    this.contact,
    this.payload,
    Key? key})
      : super(key: key);

  final String? sesskey;
  final int? userStudyId;
  final Contact? contact;
  final String? payload;

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool loading = true;
  bool connected = true;
  List<Message> messageList = [];
  String text='';
  String updateTime='';
  final _formKey=GlobalKey<FormState>();
  final TextEditingController controller=TextEditingController();
  Timer? timerperiodic;
  Timer? timerfinal;



  Future<void> getChat() async {

    // get old contacts from DB
    var db=DatabaseServices.instance;
    if (widget.contact!=null) {
      messageList = await db.getObjectsById(object: Message, id: widget.contact!.id)
      as List<Message>;
      if (mounted) {
        setState(() {});
      }

      // get new contacts from http
      bool isConnected = false;
      if (widget.sesskey != null && widget.userStudyId != null) {
        var study = HttpServices();
        await study.httpSetMessagesRead(
          sesskey: widget.sesskey!,
          userStudyId: widget.userStudyId!,
          contactStudyId: widget.contact!.link);

        var jsonMessages = await study.httpGetJsonMessages(
            sesskey: widget.sesskey!,
            userStudyId: widget.userStudyId!,
            contactStudyId: widget.contact!.link);
        //print(jsonMessages);

        if (jsonMessages.isNotEmpty && jsonMessages['error']==false) {
          isConnected=true;
          messageList = await study.getMessagesFromJson(
              jsonMessages: jsonMessages,
              contactId: widget.contact!.id);
          await db.updateDB(newData: messageList,
              whereId: 'contactId',
              id: widget.contact!.id);
          await db.setUpdateTime(object: 'messages', foreignId: widget.contact!.id!);
          messageList = await db.getObjectsById(object: Message, id: widget.contact!.id)
          as List<Message>;
          if (mounted) {
            setState(() {
              print('set state');
              loading = false;
              connected=true;
            });
          }
        }
      }
      if (!isConnected) {
        updateTime=await db.getUpdateTime(object: 'messages', foreignId: widget.contact!.id!);
        if (updateTime.split(':').length>1) {
          updateTime='Τελευταία ενημέρωση: '+updateTime.split(':')[0]+':'+updateTime.split(':')[1];
        }
        if (mounted) {
          setState(() {
            loading=false;
            connected=false;
          });
        }
      }
    } else if (widget.payload!=null) {
      print('chatpage payload!=null');
      var listoFromPayload=widget.payload!.split('-');
      String sesskey = listoFromPayload[0];
      int userStudyId = int.parse(listoFromPayload[1]);
      int contactStudyId = int.parse(listoFromPayload[2]);
      int contactId = int.parse(listoFromPayload[3]);
      messageList = await db.getObjectsById(object: Message, id: contactId)
                    as List<Message>;
      setState(() {});
      var study = HttpServices();
      var jsonMessages = await study.httpGetJsonMessages(
          sesskey: sesskey,
          userStudyId: userStudyId,
          contactStudyId: contactStudyId);
      if (jsonMessages.isNotEmpty) {
        if (jsonMessages['error']==true) {
          print('sesskey: bad');
          var study = HttpServices();
          var html = await study.httpGetHtml('https://study.eap.gr/message/index.php');
          if (html != null) { //... connected
            try {
              sesskey=html.getElementsByClassName('usermenu')[0].getElementsByTagName('li')[9].children[0].attributes['href']!.split('?')[1];
            } catch (err) {
              print(err);
            }
            jsonMessages = await study.httpGetJsonMessages(
                sesskey: sesskey,
                userStudyId: userStudyId,
                contactStudyId: contactStudyId);
          }
        }
        print('sesskey: good');
        messageList = await study.getMessagesFromJson(
            jsonMessages: jsonMessages,
            contactId: contactId);
        await db.updateDB(newData: messageList,
            whereId: 'contactId',
            id: contactId);
        await db.setUpdateTime(object: 'messages', foreignId: contactId);
        messageList = await db.getObjectsById(object: Message, id: contactId)
            as List<Message>;
        if (mounted) {
          setState(() {
            loading = false;
          });
        }

      } else {
        messageList = await db.getObjectsById(object: Message, id: contactId)
        as List<Message>;
        updateTime=await db.getUpdateTime(object: 'messages', foreignId: contactId);
        if (updateTime.split(':').length>1) {
          updateTime='Τελευταία ενημέρωση: '+updateTime.split(':')[0]+':'+updateTime.split(':')[1];
        }
        if (mounted) {
          setState(() {
            loading=false;
            connected=false;
          });
        }
      }
    } else {
      print('payload is null');
      setState(() {
        loading=false;
      });
    }
  }

  void setTimer() {
    print('chat timer starts');
    timerperiodic=Timer.periodic(const Duration(seconds: 15), (timer) {
      print('chat timer tick: ${timer.tick}');
      getChat();
    });
  }

  void setTimerFinal() {
    timerfinal=Timer(const Duration(minutes: 15), () {
      print('timerfinal');
      timerperiodic?.cancel();
    });
  }

  @override
  initState() {
    getChat();
    setTimer();
    setTimerFinal();
    super.initState();
  }

  @override
  void dispose() {
    timerperiodic?.cancel();
    timerfinal?.cancel();
    print('Cancel timer');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFFCF118C),
        title: RichText(
            text: TextSpan(
                text: widget.contact?.name ?? '',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
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
              await getChat();
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
                    SizedBox(
                      height: 2,
                    ),
                    LinearProgressIndicator(
                      minHeight: 4,
                      color: Color(0xFFCF118C),
                      backgroundColor: Colors.grey,
                    )
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
              child: messageList.isEmpty
                  ? Container(
                      child: Center(
                        child: Text(
                          loading ? 'σύνδεση...' : 'Δεν υπάρχουν δεδομένα',
                          style: TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                  : ListView.builder(
                      //controller: controller,
                      reverse: true,
                      itemCount: messageList.length,
                      itemBuilder: (context, index) {
                        var i = messageList.length - 1 - index;
                        return Column(
                          crossAxisAlignment: messageList[i].position == 'left'
                              ? CrossAxisAlignment.start
                              : CrossAxisAlignment.end,
                          children: [
                            messageList[i].blocktime == ''
                                ? SizedBox(
                                    height: 0,
                                  )
                                : Center(
                                    heightFactor: 2,
                                    child: Text(messageList[i].blocktime)),
                            Padding(
                              padding: messageList[i].position == 'left'
                                  ? EdgeInsets.fromLTRB(2, 5, 70, 5)
                                  : EdgeInsets.fromLTRB(70, 5, 2, 5),
                              child: Card(
                                elevation: 2,
                                color: messageList[i].position == 'left'
                                    ? Colors.grey[400]
                                    : Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        messageList[i].text,
                                        style: TextStyle(fontSize: 16),
                                      ),
                                      SizedBox(
                                        height: 4,
                                      ),
                                      Container(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          messageList[i].timesent,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[700]
                                              //fontWeight: FontWeight.bold
                                              ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    )
          ),
          Container(
            color: Colors.white,
            //height: 60,
            child: Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Form(
                      key: _formKey,
                      child: TextFormField(
                        keyboardType: TextInputType.multiline,
                        maxLines: null,
                        controller: controller,
                        onChanged: (val) {
                          setState(() {
                            text=val;
                          });
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'γράψτε ένα μήνυμα';
                          } else {
                            return null;
                          }
                        },
                        decoration: InputDecoration(
                            labelText: '  γράψτε ένα μήνυμα',
                            floatingLabelStyle: TextStyle(color: Colors.grey[700]),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey)
                            )
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        var study = HttpServices();
                        var isSent = await study.httpSendMessage(
                            text: text,
                            sesskey: widget.sesskey,
                            //studyUserId: widget.userStudyId,
                            contactId: widget.contact!.link
                        );
                        if (isSent) {
                          controller.clear();
                          getChat();
                        }
                      }
                      // if (text!='') {
                      //
                      // }
                    },
                    icon: Icon(Icons.send, size: 30, color: Color(0xFFCF118C),))
              ],
            ),
          )
        ],
      ),
    );
  }
}
