import 'package:gio_app/main.dart';
import 'package:html/dom.dart' show Document;
import 'package:html/parser.dart';
import 'package:http/http.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Models.dart';
import 'DataBaseServices.dart';

class HttpServices {

  final String loginLink = 'https://study.eap.gr/login/index.php';
  final String noConnection='no connection';

  //... parse datetimeString to DateTime
  DateTime getEventDateTime(String datetime) {
    Map monthNum = {'Ιανουάριος': 1, 'Φεβρουάριος': 2, 'Μάρτιος': 3, 'Απρίλιος': 4,
      'Μάιος': 5, 'Ιούνιος': 6, 'Ιούλιος': 7, 'Αύγουστος': 8, 'Σεπτέμβριος': 9,
      'Οκτώβριος': 10, 'Νοέμβριος': 11, 'Δεκέμβριος': 12, 'Ιανουαρίου': 1,
      'Φεβρουαρίου': 2, 'Μαρτίου': 3, 'Απριλίου': 4, 'Μαΐου': 5, 'Ιουνίου': 6,
      'Ιουλίου': 7, 'Αυγούστου': 8, 'Σεπτεμβρίου': 9, 'Οκτωβρίου': 10,
      'Νοεμβρίου': 11, 'Δεκεμβρίου': 12};
    var datetimeList = datetime.split(', ');
    print(datetime);
    //check if is 'Αύριο' or 'Σήμερα'....
    // TODO try catch
    if (datetimeList[0]=='Αύριο') {
      var time = datetimeList[1].split(' » ')[0].split(':');
      var hour = int.tryParse(time[0])?? 0;
      var min = int.tryParse(time[1])?? 0;
      var now = DateTime.now();
      var dt = DateTime(now.year, now.month, now.day, hour, min);
      dt = dt.add(const Duration(days: 1));
      return dt;
    } else if (datetimeList[0]=='Σήμερα'){
      print('a');
      var time = datetimeList[1].split(' » ')[0].split(':');
      var hour = int.tryParse(time[0])?? 0;
      var min = int.tryParse(time[1])?? 0;
      var now = DateTime.now();
      var dt = DateTime(now.year, now.month, now.day, hour, min);
      return dt;
    } else {
      print('a');
      var day = int.tryParse(datetimeList[1].split(' ')[0])?? 0;
      var monthString = datetimeList[1].split(' ')[1];
      print(monthString);
      var month = monthNum[monthString];
      print(month);
      var time = datetimeList[2].split(' » ')[0].split(':');
      var hour = int.tryParse(time[0])?? 0;
      var min = int.tryParse(time[1])?? 0;
      var now = DateTime.now();
      var year = month >= now.month? now.year : now.year+1;
      print(year);
      var dt = DateTime(year, month, day, hour, min);
      return dt;
    }
  }

  DateTime getDiscussDateTime(String datetime) {
    var dt=DateTime.now();
    Map monthNum = {'Ιαν': 1, 'Φεβ': 2, 'Μάρ': 3, 'Απρ': 4, 'Μάι': 5, 'Ιού': 6,
      'Αύγ': 8, 'Σεπ': 9, 'Οκτ': 10, 'Νοέ': 11, 'Δεκ': 12};
    try {
      // parsing datetime   e.g:  Κυρ, 13 Φεβ 2022, 8:20 μμ
      var dateList = datetime.split(', ')[1].split(' ');
      var day = int.tryParse(dateList[0])??0;
      var monthString = dateList[1];
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
    return dt;
  }

  // ... login, get cookie, get html
  Future<dynamic> httpLogin(String username, String password) async {
    Document? html;
    Map<String, String> cookie={};
    String moodleSession='';
    String? logintoken;
    // (1)...GET: Study/login , moodleSession1, logintoken..............
    var url=Uri.parse(loginLink);
    try {
      var response = await get(url);//.timeout(Duration(seconds: 10));
      print(response.statusCode);
      moodleSession=response.headers['set-cookie'].toString().substring(0,49);
      print(moodleSession);
      html = parse(response.body);
      logintoken=html.getElementsByClassName('modal-body')[0].children[0].children[6].attributes['value'];
      print(logintoken);
    } catch(err) {
      print(err);
      return noConnection;
    }

    // (2)...POST: Study/login with cookie - moodleSession1 , Get MoodleSession2...
    cookie = { 'Cookie' : '$moodleSession; '};
    print(cookie);
    try {
      var request = Request('POST', url)
        ..headers.addAll(cookie)
        ..bodyFields = {'username': username, 'password' : password,
                         'anchor' : '', 'logintoken' : logintoken??''}
        ..followRedirects = false;
      var responseStream = await request.send();
      //print(responseStream.statusCode);
      //print(responseStream.headers);
      //print(responseStream.headers['location']);
      if (responseStream.headers['location'] == loginLink) {
        print('no user');
        return 'no user';
      }
      moodleSession=responseStream.headers['set-cookie'].toString().substring(0,49);
      //print(moodleSession);
    } catch(err) {
      print(err);
      return noConnection;
    }

    // (3)....Make new cookie with moodleSession2 and
    // get everything while statusCode == 200
    cookie = { 'Cookie' : ' $moodleSession; '};
    print(cookie);
    url=Uri.parse('https://study.eap.gr/my/');
    try {
      var response = await get(url, headers: cookie);    //
      print(response.statusCode);
      //print(response.headers['location']);
      if (response.headers['location'] == loginLink) {
        return noConnection;
      }
      html = parse(response.body);
    } catch(err) {
      print('error');
      return noConnection;
    }

    // store moodleSession to SherdPreferences
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('moodleSession', moodleSession);

    return html;
  }

  Future<String> reConnect(int? userId) async {
    Map<String, String> cookie={};
    String moodleSession='';
    String? logintoken;
    // (1)...GET: Study/login , moodleSession1, logintoken..............
    var url=Uri.parse(loginLink);
    try {
      print('get study/login');
      var response = await get(url);//.timeout(Duration(seconds: 10));
      print(response.statusCode);
      moodleSession=response.headers['set-cookie'].toString().substring(0,49);
      print(moodleSession);
      var html = parse(response.body);
      logintoken=html.getElementsByClassName('modal-body')[0].children[0].children[6].attributes['value'];
      //print(logintoken);
    } catch(err) {
      print(err);
      print(noConnection);
      return noConnection;
    }
    // (2)...POST: Study/login with cookie - moodleSession1 , Get MoodleSession2...
    cookie = { 'Cookie' : '$moodleSession; '};
    //print(cookie);
    if (userId==null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      userId=prefs.getInt('userId');
    }
    var user = await DBServices.instance.getUser(id: userId);
    try {
      var request = Request('POST', url)
        ..headers.addAll(cookie)
        ..bodyFields = {'username': user.username, 'password' : user.password,
                         'anchor' : '', 'logintoken' : logintoken??''}
        ..followRedirects = false;
      var responseStream = await request.send();
      print(responseStream.statusCode);
      //print(responseStream.headers);
      print(responseStream.headers['location']);
      if (responseStream.headers['location'] == loginLink) {
        return 'no user';
      }
      moodleSession=responseStream.headers['set-cookie'].toString().substring(0,49);
      print(moodleSession);
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('moodleSession', moodleSession);
      return moodleSession;
    } catch(err) {
      print(err);
      return noConnection;
    }
  }

  Future<Document?> getHtml(String link, {String? moodleSession}) async {
    Document? html;
    print('getting html....');
    var url=Uri.parse(link);
    if (moodleSession==null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      moodleSession = prefs.getString('moodleSession') ?? '';
    }
    var cookie = { 'Cookie' : ' $moodleSession; '};
    var response;
    // try get html with storef moodlSession
    try {
      response = await get(url, headers: cookie);
      // if moodleSession is old, throws exception: loop redirect
      html = parse(response.body);
      //print('getHtml success');
      return html;
    } catch(err) {
      print('getHtml fail');
      print(err);
    }
    // if response is null or redirected to login page then
    // reconnect, get new moodleSession and get html
    if (response==null || response.headers['location'] == loginLink) {
      print('reconnecting...');
      try {
        moodleSession=await reConnect(activeUserId);
        if (moodleSession!='no connection' && moodleSession!='no user') {
          cookie = { 'Cookie' : ' $moodleSession; '};
          response = await get(url, headers: cookie);
          if (response.headers['location'] == loginLink) {
            //print('error');
            return html;
          } else {
            html = parse(response.body);
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
    }
  }

  List<Event> getEvents(Document html, int userId) {
    List<Event> eventList=[];
    var htmlWebex= html.getElementsByClassName('oss-info-container');
    var webexLinks={};
    //...get webexLinks...
    try {
      for (int i=0; i<htmlWebex.length; ++i) {
        var id=htmlWebex[i].attributes['id']!.split('-')[3];
        var link=htmlWebex[i].getElementsByTagName('a')[2].attributes['href'];
        webexLinks[id]=link;
      }
    } catch(err) {
      print(err);
    }
    var htmlEvents=html.getElementsByClassName('event');

    try {
      for (int i=0; i<htmlEvents.length; i=i+1) {
        print(htmlEvents[i]);
        var htmlId = htmlEvents[i].children[1].attributes['data-event-id'];
        eventList.add(Event(
            linkId: htmlEvents[i].children[1].attributes['data-event-id']!,
            type: htmlEvents[i].children[1].text,
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
    return eventList;
  }

  List<Course> getCourses(Document html, int userId) {
    List<Course> courseList=[];
    var htmlCourses=html.getElementsByClassName('card-block course-info-container');
    try {
      for (int i=0; i<htmlCourses.length; i=i+1) {
        courseList.add(Course(
            name: htmlCourses[i].getElementsByClassName('h5')[0].text,
            linkId: htmlCourses[i].getElementsByClassName('h5')[0].firstChild!.attributes['href']!,
            gradesUpdateTime: '',
            userId: userId
        ));
      }
    } catch(err) {
      print(err);
    }
    return courseList;
  }

  List<Grade> getEmptyGrades(Document html, int courseId) {
    List<Grade> gradeList = [];
    var htmlGrades=html.getElementsByClassName('activity assign modtype_assign');
    try {
      for (int i=0; i<htmlGrades.length; ++i) {
        //check if assign link exists
        if (htmlGrades[i].getElementsByTagName('a').isNotEmpty) {
          gradeList.add(Grade(
              assign: htmlGrades[i].getElementsByClassName('instancename')[0].text,
              grade: '',
              linkId: htmlGrades[i].getElementsByTagName('a')[0].attributes['href']!,
              courseId: courseId
          ));
        }
      }
    } catch(err) {
      print(err);
    }
    return gradeList;
  }

  String getGrade(Document html) {
    var htmlGrade=html.getElementsByTagName('tbody');
    if (htmlGrade.length==2) {
      try {
        var grade=htmlGrade[1].children[0].children[1].text; //TODO check if is number
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
            name: htmlForums[i].getElementsByClassName('instancename')[0].text.split('Φόρουμ')[0],
            linkId: htmlForums[i].getElementsByTagName('a')[0].attributes['href']!,
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
        discussionList.add(Discussion(
            title: htmlDiscussions[i].getElementsByClassName('topic starter')[0].text,
            linkId: htmlDiscussions[i].getElementsByClassName('topic starter')[0].getElementsByTagName('a')[0].attributes['href']!,
            authorFirst: htmlDiscussions[i].getElementsByClassName('author')[0].text,
            replies: int.parse(htmlDiscussions[i].getElementsByClassName('replies')[0].text),
            repliesUnread: int.parse(htmlDiscussions[i].getElementsByClassName('replies')[1].text),
            authorLast: htmlDiscussions[i].getElementsByClassName('lastpost')[0].children[0].text,
            dateTime: htmlDiscussions[i].getElementsByClassName('lastpost')[0].children[2].text,
            dateTimeParsed: getDiscussDateTime(htmlDiscussions[i].getElementsByClassName('lastpost')[0].children[2].text).toString(),
            postsUpdateTime: '',
            forumId: forumId
        ));
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
        var content='';
        for (var p in htmlContent) {
          content=content+'\n'+p.text+'\n';
        }
        //print(content);
        postList.add(Post(
            linkId: htmlPosts[i].previousElementSibling!.attributes['id']!,
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



}