import 'dart:convert';


import 'package:gio_app/main.dart';
import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models.dart';
import 'DatabaseServices.dart';


class HttpServices {

  final String loginLink = 'https://study.eap.gr/login/index.php';
  final String noConnection='no connection';

  //....  http methods
  Future<String> loginStudy(String username, String password) async {
    Document? html;
    Map<String, String> cookie={};
    String moodleSession='';
    String? logintoken;
    // (1)...GET: Study/login , moodleSession1, logintoken..............
    var url=Uri.parse(loginLink);

    try {
      print('start login... get: '+loginLink);
      var response = await get(url);//.timeout(Duration(seconds: 10));
      print(response.statusCode);
      moodleSession=response.headers['set-cookie'].toString().split(';')[0];
      html = parse(response.body);
      logintoken=html.getElementsByClassName('modal-body')[0].children[0].children[6].attributes['value'];
    } catch(err) {
      print(err);
      return noConnection;
    }


    // (2)...POST: Study/login with cookie - moodleSession1 , Get MoodleSession2...
    cookie = { 'cookie' : '$moodleSession; '};
    //print(cookie);
    try {
      print('login... post: '+url.toString());
      var request = Request('POST', url)
        ..headers.addAll(cookie)
        ..headers.addAll({'origin': 'https://study.eap.gr', 'referer': loginLink})
        ..bodyFields = {'username': username, 'password' : password,
          'anchor' : '', 'logintoken' : logintoken??''}
        ..followRedirects = false;

      var responseStream = await request.send();
      print(responseStream.statusCode);

      if (responseStream.headers['location'] == loginLink) {
        print('no user');
        return 'auth error';
      }
      moodleSession=responseStream.headers['set-cookie'].toString().split(';')[0];
      //moodleSession=responseStream.headers['set-cookie'].toString().substring(0,49);
      print('login... ok!  got: '+moodleSession);
    } catch(err) {
      print(err);
      return noConnection;
    }

    // store moodleSession to SherdPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('moodleSession', moodleSession);

    return moodleSession;
  }

  Future<Document?> httpGetHtml(String link, {String? moodleSession}) async {
    Document? html;

    var url=Uri.parse(link);
    if (moodleSession==null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      moodleSession = prefs.getString('moodleSession') ?? '';
    }
    var cookie = { 'Cookie' : ' $moodleSession; '};
    var response;
    // try get html with stored moodlSession
    try {
      print('get html...  from: '+ link);
      response = await get(url, headers: cookie);
      // if moodleSession is old, throws exception: Redirect loop detected
      print(response.statusCode);
      if (response.statusCode!=200) {

        print('connection error, retruning null html');
        return html;
      }
      html = parse(response.body);
      print('html got');
      return html;
    } catch(err) {
      //print('getHtml fail');
      print(err);
    }
    // if response is null or redirected to login page then
    // reconnect, get new moodleSession and get html
    if (response==null || response.headers['location'] == loginLink) {
      print('error on getting html (bad moodleSession)');
      if (activeUserId==0 || activeUserId==null) {
        var prefs = await SharedPreferences.getInstance();
        activeUserId = prefs.getInt('userId');
        //print(activeUserId);
      }
      try {
        var user = await DatabaseServices.instance.getUser(id: activeUserId);
        moodleSession=await loginStudy(user.username, user.password);
        //print(moodleSession);
        if (moodleSession!='no connection' && moodleSession!='auth error') {
          cookie = { 'Cookie' : ' $moodleSession; '};
          print('get html of '+link);
          response = await get(url, headers: cookie);
          if (response.headers['location'] == loginLink) {
            //print('error');
            print('redirecting to study/login, returnign null html');
            return html;
          } else {
            html = parse(response.body);
            print('html got');
            return html;
          }
        } else {
          return html;
        }
      } catch(err) {
        print('reconnect fail');
        print(err);
        return html;
      }
    } else {
      return html;
    }
  }

  //... methods for collecting data from parsed html

  List<Event> getEvents(Document html, int userId) {
    List<Event> eventList=[];

    //...get webexLinks...
    var htmlWebex= html.getElementsByClassName('oss-info-container');
    var webexLinks={};
    if (htmlWebex.isNotEmpty) {
      try {
        for (int i=0; i<htmlWebex.length; ++i) {
          var id=htmlWebex[i].attributes['id']!.split('-')[3];
          var link=htmlWebex[i].getElementsByTagName('a')[2].attributes['href'];
          webexLinks[id]=link;
        }
      } catch(err) {
        print(err);
      }
    }

    var htmlEvents=html.getElementsByClassName('event');
    if (htmlEvents.isNotEmpty) {
      try {
        for (int i=0; i<htmlEvents.length; i=i+1) {
          //print(htmlEvents[i]);
          var htmlId = htmlEvents[i].children[1].attributes['data-event-id'];
          eventList.add(Event(
              link: htmlEvents[i].children[1].attributes['data-event-id']!,
              title: htmlEvents[i].children[1].text,
              dateTime: htmlEvents[i].children[2].text,
              dateTimeParsed: getEventDateTime(htmlEvents[i].children[2].text).toString(),
              webex: webexLinks[htmlId]??'',
              notificationId: 0,
              userId: userId
          ));
        }
      } catch(err) {
        print(err);
      }
    }
    return eventList;
  }

  List<Course> getCourses(Document html, int userId) {
    List<Course> courseList=[];
    var htmlCourses=html.getElementsByClassName('card-block course-info-container');
    try {
      for (int i=0; i<htmlCourses.length; i=i+1) {
        courseList.add(Course(
            title: htmlCourses[i].getElementsByClassName('h5')[0].text,
            link: htmlCourses[i].getElementsByClassName('h5')[0].firstChild!.attributes['href']!,
            gradesUpdateTime: '',
            userId: userId
        ));
      }
    } catch(err) {
      print(err);
    }
    return courseList;
  }

  List<Assign> getAssigns(Document html, int courseId) {
    List<Assign> assignList = [];
    var htmlAssign=html.getElementsByClassName('activity assign modtype_assign');
    try {
      for (int i=0; i<htmlAssign.length; ++i) {
        //check if assign link exists
        if (htmlAssign[i].getElementsByTagName('a').isNotEmpty) {
          assignList.add(Assign(
              title: htmlAssign[i].getElementsByClassName('instancename')[0].text,
              grade: '',
              link: htmlAssign[i].getElementsByTagName('a')[0].attributes['href']!,
              courseId: courseId
          ));
        }
      }
    } catch(err) {
      print(err);
    }
    return assignList;
  }

  String getGrade(Document html) {

    var htmlGrade=html.getElementsByTagName('tbody');
    //print(htmlGrade);
    if (htmlGrade.length>=2) {
      try {
        var grade=htmlGrade[1].children[0].children[1].text;
        print(grade);
        return grade;
      } catch(err) {
        print(err);
      }
    }
    return '';
  }

  List<Forum> getForums(Document html, int courseId) {
    List<Forum> forumList = [];
    var htmlForums=html.getElementsByClassName('activity forum modtype_forum');
    try {
      for (int i=0; i<htmlForums.length; ++i) {
        //var rr=htmlForums[i].getElementsByClassName('instancename');
        //print(rr);
        var unreadHtml=htmlForums[i].getElementsByClassName('unread');
        //print('new forum: '+unreadHtml.length.toString());
        var unread='';
        if (unreadHtml.isNotEmpty) {
          print(unreadHtml[0].getElementsByTagName('a')[0].text);
          //unread=unreadHtml[0].text;
          unread='- new';
          //print('unread forum');
          //print(unread);
        } //else {unread='';}
        forumList.add(Forum(
            title: htmlForums[i].getElementsByClassName('instancename')[0].text.split('Φόρουμ')[0],
            link: htmlForums[i].getElementsByTagName('a')[0].attributes['href']!,
            unread: unread,
            discussionsUpdateTime: '',
            courseId: courseId
        ));
      }
      //print(forumList.map((e) => e.toMap()));
    } catch(err) {
      print(err);
    }
    return forumList;
  }

  List<Discussion> getDiscussions(Document html, int forumId) {
    List<Discussion> discussionList=[];
    var htmlDiscussions=html.getElementsByTagName('tbody').isNotEmpty
        ? html.getElementsByTagName('tbody')[0].children
        : [];
    try {
      for (int i=0; i<htmlDiscussions.length; ++i) {
        //print('start getting discuss');
        discussionList.add(Discussion(
            title: htmlDiscussions[i].getElementsByClassName('topic starter')[0].text,
            link: htmlDiscussions[i].getElementsByClassName('topic starter')[0].getElementsByTagName('a')[0].attributes['href']!,
            authorFirst: htmlDiscussions[i].getElementsByClassName('author')[0].text,
            replies: int.parse(htmlDiscussions[i].getElementsByClassName('replies')[0].text),
            repliesUnread: int.parse(htmlDiscussions[i].getElementsByClassName('replies')[1].text),
            authorLast: htmlDiscussions[i].getElementsByClassName('lastpost')[0].children[0].text,
            dateTime: htmlDiscussions[i].getElementsByClassName('lastpost')[0].children[2].text,
            dateTimeParsed: getDiscussDateTime(htmlDiscussions[i].getElementsByClassName('lastpost')[0].children[2].text).toString(),
            postsUpdateTime: '',
            forumId: forumId
        ));
        //print(discussionList.map((e) => e.toMap()));
      }
    } catch(err) {
      print(err);
    }
    return discussionList;
  }

  List<Post> getPosts(Document html, int discussionId) {
    List<Post> postList=[];
    var htmlPosts=html.getElementsByClassName('forumpost');
    for (int i = 0; i < htmlPosts.length; ++i) {
      try {
        var htmlContent = htmlPosts[i].getElementsByClassName('posting fullpost')[0]
            .getElementsByTagName('p');
        //print(htmlContent);
        var content='';
        if (htmlContent.isNotEmpty) {
          for (var p in htmlContent) {
            p.text;
            content=content+'\n'+p.text+'\n';
          }
        } else {
          content=htmlPosts[i].getElementsByClassName('posting fullpost')[0].text;
        }
        //print(content);
        postList.add(Post(
            link: htmlPosts[i].previousElementSibling!.attributes['id']!,
            title: htmlPosts[i].children[0].children[1].children[0].text,
            author: htmlPosts[i].children[0].children[1].children[1].children[0]
                .text,
            dateTime: htmlPosts[i].children[0].children[1].children[1].text
                .split('-')[1],
            content: content, //htmlPosts[i].children[1].text,
            discussionId: discussionId
        ));
      } catch (err) {
        print(err);
      }
    }
    return postList;
  }

  Future<Map> httpGetJsonMessagesPreview({String? sesskey, String? userStudyId}) async {
    Map jsonMessages={};

    // .... POST MESSAGE REQUEST ..........
    String link='https://study.eap.gr/lib/ajax/service.php?$sesskey&info=core_message_data_for_messagearea_conversations';
    var url=Uri.parse(link);

    var payload=[{"index":0,"methodname":"core_message_data_for_messagearea_conversations",
      "args":{"userid":userStudyId,"limitfrom":0,"limitnum":30}}];
    var body = json.encode(payload);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var moodleSession = prefs.getString('moodleSession') ?? '';
    Map<String,String> headers = {
      'Content-type' : 'application/json',
      'Cookie' : ' $moodleSession; ',
      'origin': 'https://study.eap.gr',
      'referer': 'https://study.eap.gr/message/index.php',
      'X-Requested-With': 'XMLHttpRequest'
    };

    var jsonList=[];
    try {
      print('get jsonmessagespreview from http');
      var response = await post(url, headers: headers, body: body); //, encoding: Encoding.getByName("utf-8"));
      jsonList=json.decode(response.body);
      //print(vvv[0]['data']['messages'][0]);
      if (jsonList.isNotEmpty) {
        jsonMessages= jsonList[0];
      }
      return jsonMessages;
    } catch(err) {
      print(err);
      return {};
    }
  }

  Future<void> httpSetMessagesRead ({String? sesskey, int? userStudyId, int? contactStudyId}) async {
    String link='https://study.eap.gr/lib/ajax/service.php?$sesskey&info=core_message_mark_all_messages_as_read';
    var url=Uri.parse(link);

    var payload=[{"index":0,"methodname":"core_message_mark_all_messages_as_read",
      "args":{"useridto":userStudyId,"useridfrom":contactStudyId}}];
    var body = json.encode(payload);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var moodleSession = prefs.getString('moodleSession') ?? '';
    Map<String,String> headers = {
      'Content-type' : 'application/json',
      'Cookie' : ' $moodleSession; ',
      'origin': 'https://study.eap.gr',
      'referer': 'https://study.eap.gr/message/index.php',
      'X-Requested-With': 'XMLHttpRequest'
    };

    try {
      print('set messages read');
      await post(url, headers: headers, body: body);
    } catch(err) {
      print(err);
    }
  }

  Future<Map> httpGetJsonMessages({String? sesskey, int? userStudyId, int? contactStudyId}) async {
    Map jsonMessages={};

    // .... POST MESSAGE REQUEST ..........
    String link='https://study.eap.gr/lib/ajax/service.php?$sesskey&info=core_message_data_for_messagearea_messages';
    var url=Uri.parse(link);

    var payload=[{"index":0,"methodname":"core_message_data_for_messagearea_messages",
      "args":{"currentuserid":userStudyId,"otheruserid":contactStudyId,"limitfrom":0,"limitnum":30,"newest":true}}];
    var body = json.encode(payload);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var moodleSession = prefs.getString('moodleSession') ?? '';
    Map<String,String> headers = {
      'Content-type' : 'application/json',
      'Cookie' : ' $moodleSession; ',
      'origin': 'https://study.eap.gr',
      'referer': 'https://study.eap.gr/message/index.php',
      'X-Requested-With': 'XMLHttpRequest'
    };

    var jsonList=[];
    try {
      print('get jsonmessages from http');
      var response = await post(url, headers: headers, body: body); //, encoding: Encoding.getByName("utf-8"));
      jsonList=json.decode(response.body);
      //print(vvv[0]['data']['messages'][0]);
      if (jsonList.isNotEmpty) {
        jsonMessages= jsonList[0];
      }
      return jsonMessages;
    } catch(err) {
      print(err);
      return {};
    }
  }

  Future<bool> httpSendMessage({String? text, String? sesskey, int? contactId}) async {

    // .... POST MESSAGE REQUEST ..........
    String link='https://study.eap.gr/lib/ajax/service.php?$sesskey&info=core_message_send_instant_messages';
    var url=Uri.parse(link);

    // var payload=[{"index":0,"methodname":"core_message_data_for_messagearea_messages",
    //   "args":{"currentuserid":studyUserId,"otheruserid":contactId,"limitfrom":0,"limitnum":20,"newest":true}}];

    var payload=[{"index":0,"methodname":"core_message_send_instant_messages",
      "args":{"messages":[{"touserid":contactId,"text":text}]}}];
    var body = json.encode(payload);

    SharedPreferences prefs = await SharedPreferences.getInstance();
    var moodleSession = prefs.getString('moodleSession') ?? '';
    Map<String,String> headers = {
      'Content-type' : 'application/json',
      'Cookie' : ' $moodleSession; ',
      'origin': 'https://study.eap.gr',
      'referer': 'https://study.eap.gr/message/index.php',
      'X-Requested-With': 'XMLHttpRequest'
    };

    //var jsonList=[];
    try {
      await post(url, headers: headers, body: body); //, encoding: Encoding.getByName("utf-8"));
      //jsonList=json.decode(response.body);
      //print(vvv[0]['data']['messages'][0]);
      return true;
    } catch(err) {
      print(err);
      return false;
    }
  }

  List<Contact> getContactsFromJson(Map json, int activeUserid) {
    List<Contact> contactsList=[];
    //var htmlMessenger=html.getElementsByClassName('contact');

    try {
      var num=0;
      for (var e in json['data']['contacts']) {
        contactsList.add(Contact(
          //link = contactStudyId
            link: e['userid'],
            name: e['fullname'],
            lastMessage: e['lastmessage'],
            chatUpdateTime: '',
            position: num++,
            userId: activeUserid
        ));
      }
    } catch(err) {
      print(err);
    }
    return contactsList;
  }

  // List<Contact> getContacts(Document html, int activeUserid) {
  //   List<Contact> contactsList=[];
  //   var htmlMessenger=html.getElementsByClassName('contact');
  //
  //   try {
  //     var num=0;
  //     for (var el in htmlMessenger) {
  //       contactsList.add(Contact(
  //         //link = contactStudyId
  //         link: int.tryParse(el.attributes['data-userid'].toString())!,
  //         name: el.getElementsByClassName('name')[0].text.trim(),
  //         lastMessage: el.getElementsByClassName('lastmessage')[0].children[1].text.trim(),
  //         chatUpdateTime: '',
  //         position: num++,
  //         userId: activeUserid
  //       ));
  //     }
  //   } catch(err) {
  //     print(err);
  //   }
  //   return contactsList;
  // }

  Future<List<Message>> getMessagesFromJson({required Map jsonMessages, int? contactId}) async {

    List<Message> messageList=[];
    print('get messages from Json');

    try {
      for (var e in jsonMessages['data']['messages']) {
        var blocktime='';
        //print(e['text']);
        if (e['displayblocktime']) {
          blocktime=e['blocktime'];
        }
        messageList.add(Message(
          link: e['id'],
          position: e['position'],
          text: e['text'].toString().replaceAll('<p>', '').replaceAll('</p>', '').replaceAll('<br>', ''),
          timesent: e['timesent'],
          blocktime: blocktime,
          contactId: contactId,
          //userId: userId,
        ));
      }
      return messageList;
    } catch(err) {
      print(err);
      return messageList;
    }
  }

  // Future<bool> httpSendMessageDemo({String? text, String? sesskey, int? contactId}) async {
  //
  //   // .... POST MESSAGE REQUEST ..........
  //   String link='https://study.eap.gr/lib/ajax/service.php?$sesskey&info=core_message_send_instant_messages';
  //   var url=Uri.parse(link);
  //
  //   // var payload=[{"index":0,"methodname":"core_message_data_for_messagearea_messages",
  //   //   "args":{"currentuserid":studyUserId,"otheruserid":contactId,"limitfrom":0,"limitnum":20,"newest":true}}];
  //
  //   var payload=[{"index":0,"methodname":"core_message_send_instant_messages",
  //     "args":{"messages":[{"touserid":contactId,"text":text}]}}];
  //   var body = json.encode(payload);
  //
  //   SharedPreferences prefs = await SharedPreferences.getInstance();
  //   var moodleSession = prefs.getString('moodleSession') ?? '';
  //   Map<String,String> headers = {
  //     'Content-type' : 'application/json',
  //     'Cookie' : ' $moodleSession; ',
  //     'origin': 'https://study.eap.gr',
  //     'referer': 'https://study.eap.gr/message/index.php',
  //     'X-Requested-With': 'XMLHttpRequest'
  //   };
  //
  //   //var jsonList=[];
  //   try {
  //     var response = await post(url, headers: headers, body: body); //, encoding: Encoding.getByName("utf-8"));
  //     //jsonList=json.decode(response.body);
  //     //print(vvv[0]['data']['messages'][0]);
  //     return true;
  //   } catch(err) {
  //     print(err);
  //     return false;
  //   }
  // }

  // ... methods for parsing datetime string and return DateTime

  DateTime? getEventDateTime(String datetime) {
    DateTime? dt;
    var now = DateTime.now();
    Map monthNum = {'Ιανουάριος': 1, 'Φεβρουάριος': 2, 'Μάρτιος': 3, 'Απρίλιος': 4,
      'Μάιος': 5, 'Ιούνιος': 6, 'Ιούλιος': 7, 'Αύγουστος': 8, 'Σεπτέμβριος': 9,
      'Οκτώβριος': 10, 'Νοέμβριος': 11, 'Δεκέμβριος': 12, 'Ιανουαρίου': 1,
      'Φεβρουαρίου': 2, 'Μαρτίου': 3, 'Απριλίου': 4, 'Μαΐου': 5, 'Ιουνίου': 6,
      'Ιουλίου': 7, 'Αυγούστου': 8, 'Σεπτεμβρίου': 9, 'Οκτωβρίου': 10,
      'Νοεμβρίου': 11, 'Δεκεμβρίου': 12};
    var datetimeList = datetime.split(', ');
    try {
      if (datetimeList[0]=='Αύριο') {
        var time = datetimeList[1].split(' » ')[0].split(':');
        var hour = int.tryParse(time[0])?? 0;
        var min = int.tryParse(time[1])?? 0;
        //var now = DateTime.now();
        dt = DateTime(now.year, now.month, now.day, hour, min);
        dt = dt.add(const Duration(days: 1));
        return dt;
      } else if (datetimeList[0]=='Σήμερα'){
        //print('a');
        var time = datetimeList[1].split(' » ')[0].split(':');
        var hour = int.tryParse(time[0])?? 0;
        var min = int.tryParse(time[1])?? 0;
        //var now = DateTime.now();
        dt = DateTime(now.year, now.month, now.day, hour, min);
        return dt;
      } else {
        //print('a');
        var day = int.tryParse(datetimeList[1].split(' ')[0])?? 0;
        var monthString = datetimeList[1].split(' ')[1];
        //print(monthString);
        var month = monthNum[monthString];
        //print(month);
        var time = datetimeList[2].split(' » ')[0].split(':');
        var hour = int.tryParse(time[0])?? 0;
        var min = int.tryParse(time[1])?? 0;
        //var now = DateTime.now();
        var year = month >= now.month? now.year : now.year+1;
        //print(year);
        dt = DateTime(year, month, day, hour, min);
        return dt;
      }
    } catch (err) {
      print(err);
      return dt;
    }
  }

  DateTime getDiscussDateTime(String datetime) {
    var dt=DateTime.now();
    Map monthNum = {'Ιαν': 1, 'Φεβ': 2, 'Μάρ': 3, 'Απρ': 4, 'Μάι': 5, 'Ιού': 6,
      'Αύγ': 8, 'Σεπ': 9, 'Οκτ': 10, 'Νοέ': 11, 'Δεκ': 12, 'Μαρ': 3, 'Μαΐ': 5,
      'Ιούν': 6, 'Ιουν': 6, 'Ιου': 6, 'Ιούλ': 7, 'Ιουλ':7, 'Αυγ': 8, 'Νοε': 11, };
    //print(datetime);
    try {
      // parsing datetime   e.g:  Κυρ, 13 Φεβ 2022, 8:20 μμ
      var dateList = datetime.split(', ')[1].split(' ');
      var day = int.tryParse(dateList[0])??0;
      var monthString = dateList[1];
      //print(monthString);
      var month = monthNum[monthString];
      var year = int.tryParse(dateList[2])??0;
      var timeList = datetime.split(', ')[2].split(' ');
      var time = timeList[0].split(':');
      var hour = int.tryParse(time[0])?? 0;
      if (timeList[1]=='μμ' && hour!=12) {
        hour=hour+12;
      }
      var min = int.tryParse(time[1])?? 0;
      dt = DateTime(year, month, day, hour, min);
    } catch (err) {
      print('error parsing discuss dateTime');
    }
    //print(dt);
    return dt;
  }

}