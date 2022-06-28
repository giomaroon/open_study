import 'package:flutter/material.dart';
import 'package:gio_app/Services/HttpServices.dart';
import '../Services/DatabaseServices.dart';
import '../Models.dart';
import '../main.dart' show activeUserId;
import 'package:html/dom.dart' show Document;
import 'package:url_launcher/url_launcher.dart';

class EventsPage extends StatefulWidget {
  const EventsPage({
    this.html,
    Key? key}) : super(key: key);

  final Document? html;

  @override
  _EventsPageState createState() => _EventsPageState();
}

class _EventsPageState extends State<EventsPage> {
  List<Event> eventList = [];
  bool loading = true;
  bool connected = true;
  String updateTime='';

  Future<void> getEvents() async {
    List<Event> _eventList = [];
    // first get old events from DB
    var db=DatabaseServices.instance;
    _eventList = await db.getObjectsById(object: Event, id: activeUserId)
                 as List<Event>;
    setState(() {
      eventList=_eventList;
    });
    // then check for new events in widgets html or reconnect and get html
    var study=HttpServices();
    if (widget.html!=null) {
      _eventList=study.getEvents(widget.html!, activeUserId);
      await db.updateDB(newData: _eventList, whereId: 'userId', id: activeUserId);
      await db.setUpdateTime(object: 'events', foreignId: activeUserId);
      setState(() {
        eventList=_eventList;
        loading=false;
      });
    } else { // connect to get new events
      var html= await study.httpGetHtml('https://study.eap.gr/my/');
      if (html!=null) { //connected
          _eventList=study.getEvents(html, activeUserId);
          await db.updateDB(newData: _eventList, whereId: 'userId', id: activeUserId);
          await db.setUpdateTime(object: 'events', foreignId: activeUserId);
          setState(() {
            eventList=_eventList;
            loading=false;
          });
      } else { // not connected
        updateTime=await db.getUpdateTime(object: 'events', foreignId: activeUserId);
        if (updateTime.split(':').length>1) {
          updateTime='Τελευταία ενημέρωση: '+updateTime.split(':')[0]+':'+updateTime.split(':')[1];
        }
        setState(() {
          eventList=_eventList;
          loading=false;
          connected=false;
        });
      }
    }
  }

  @override
  initState() {
    getEvents();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFE8E8E8), //Colors.grey[200],
      appBar: AppBar(
        backgroundColor: Color(0xFFCF118C),
        title: Text('Επικείμενα Γεγονότα'),
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
              await getEvents();
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
            child: eventList.isEmpty
                ? Container(
                  child: Center(
                    child: Text(loading? 'σύνδεση...':'Δεν υπάρχουν δεδομένα',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                )
                : ListView(
                  children: eventList.map((e) =>
                    Card(
                      color: Colors.white,
                      child: Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  e.title.substring(0,3)=='ΟΣΣ'
                                  ? Icons.school
                                  : Icons.assignment_outlined,
                                  color: Colors.grey[800],
                                ),
                                SizedBox(width: 8,),
                                Expanded(
                                  child: Text(e.title,
                                    style: TextStyle(
                                      color: Colors.grey[800],
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold
                                    ),
                                    textAlign: TextAlign.left,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6,),
                            Text(e.dateTime,
                              style: TextStyle(
                                  fontSize: 16,
                              ),
                              textAlign: TextAlign.left,
                            ),
                            e.webex!=''
                            ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Divider(
                                color: Colors.grey[400],
                                ),
                                TextButton(
                                  child: Text(e.webex,
                                    style: TextStyle(
                                      color: Colors.pink[700],
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold
                                      ),
                                    textAlign: TextAlign.left,
                                    ),
                                  onPressed: () async {
                                    if (!await launchUrl(Uri.parse(e.webex))) {
                                      throw 'could not launch ${e.webex}';
                                    }
                                  },
                                ),
                              ],
                            )
                            : SizedBox()
                          ],
                        ),
                      )
                    )
              ).toList()
            ),
          ),
        ],
      ),
    );
  }
}
