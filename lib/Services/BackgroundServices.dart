import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../Models.dart';
import '../main.dart';
import 'DatabaseServices.dart';
import 'HttpServices.dart';

void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    switch (task) {
      case 'messages':
        print('background: messages 4');
        HttpOverrides.global = new MyHttpOverrides();
        print('111');
        SharedPreferences prefs = await SharedPreferences.getInstance();
        print('22');
        var activeUserId=prefs.getInt('userId')?? 0;
        print('activeUserId: $activeUserId');
        print('a');
        if (activeUserId==0) { print('b'); break; }
        var server=prefs.getString('server')??'';
        var study = HttpServices();
        var html = await study.httpGetHtml('https://$server/my/');
        print('c');

        if (html!=null
            && html.getElementsByClassName('count-container').isNotEmpty
            && html.getElementsByClassName('count-container')[0].text!='0') {

          try {
            var sesskey=html.getElementsByClassName('usermenu')[0].getElementsByTagName('li')[9]
                .children[0].attributes['href']!.split('?')[1];
            var userStudyId=html.getElementsByClassName('usermenu')[0].getElementsByTagName('li')[3]
                .children[0].attributes['href']!.split('=')[1];
            print(sesskey+' - '+userStudyId);

            var jsonMessagesPreview = await study.httpGetJsonMessagesPreview(
              sesskey: sesskey,
              userStudyId: userStudyId,
              server: server
            );

            if (jsonMessagesPreview.isNotEmpty) {
              print('json not empty');
              var notifId=200;
              for (var e in jsonMessagesPreview['data']['contacts']) {
              //for (var e in mm) {
                if (e['isread']==false) {
                  print('isread=false');
                  print(e);
                  print(e['userid']);
                  print('type is: ${e['userid'].runtimeType}');
                  var db = await DatabaseServices.instance.database;
                  var contactListDB = await db.query('Contact',
                      columns: ['id'],
                      where: 'link=? AND userId=?',
                      whereArgs: [e['userid'],activeUserId]);
                  var contactId;
                  if (contactListDB.isNotEmpty) {
                    print('contact is already in DB');
                    contactId=contactListDB[0]['id'];
                  } else {
                    print('new contact, insert DB');
                    contactId= await db.insert('Contact',
                      {'link': e['userid'],
                       'name': e['fullname'],
                       'lastMessage': e['lastmessage'],
                       'chatUpdateTime': '',
                       'position':0,
                       'userId': activeUserId});
                  }
                  print('contact Id: $contactId');
                  await notificationServices.showNotification(
                      id: notifId,
                      title: e['fullname'],
                      body: e['lastmessage'],
                      payload: '$sesskey-$userStudyId-${e['userid']}-$contactId /MessengerPage/ChatPage'
                  );
                  print('$sesskey-$userStudyId-${e['userid']}-$contactId /MessengerPage/ChatPage');
                  ++notifId;
                }
              }
            }
          } catch (err, st) {
            print('err'); print(err);
            print('stack'); print(st);
          }
        }
        break;
      case 'event':
        HttpOverrides.global = new MyHttpOverrides();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var activeUserId=prefs.getInt('userId')?? 0;
        if (activeUserId==0) { break; }
        var server=prefs.getString('server')??'';
        var study = HttpServices();
        var html = await study.httpGetHtml('https://$server/my/');
        if (html!=null) {
          var eventList = study.getEvents(html, activeUserId);
          var db = DatabaseServices.instance;
          if (eventList.isNotEmpty) {
            await db.updateDB(
                newData: eventList,
                whereId: 'userId',
                id: activeUserId);
            eventList = await db.getObjectsById(object: Event, id: activeUserId)
                              as List<Event>;
            for (var event in eventList) {
              if (event.notificationId==0 && event.dateTimeParsed!='null') {
                var eventDateTime=DateTime.parse(event.dateTimeParsed);
                eventDateTime=eventDateTime.subtract(Duration(hours: 2));
                var now=DateTime.now();
                if (now.isBefore(eventDateTime) &&
                    now.isAfter(eventDateTime.subtract(Duration(days: 2)))) {
                  var notifId=now.millisecond+1;
                  await notificationServices.showNotificationScheduled(
                      id: notifId+300,
                      title: event.dateTime,
                      body: event.title,
                      dateTime: eventDateTime,
                      payload: ' /EventsPage'
                  );
                  var dbase = await db.database;
                  await dbase.update('Event', {'notificationId': notifId},
                      where: 'link=? AND userId=?',
                      whereArgs: [event.link, activeUserId]);
                }
              }
            }
          }
          await db.setUpdateTime(object: 'events', foreignId: activeUserId);
        }
        break;
      case 'post':
        HttpOverrides.global = new MyHttpOverrides();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var activeUserId=prefs.getInt('userId')?? 0;
        if (activeUserId==0) { break; }
        var server=prefs.getString('server')??'';
        var study = HttpServices();
        var html = await study.httpGetHtml('https://$server/my/');
        if (html!=null) {
          var courseList = study.getCourses(html, activeUserId);
          //print('courses');
          if (courseList.isNotEmpty) {
            var db = DatabaseServices.instance;
            await db.updateDB(
                newData: courseList,
                whereId: 'userId',
                id: activeUserId);
            courseList = await db.getObjectsById(object: Course, id: activeUserId)
            as List<Course>;
            int notifId=0;
            for (var course in courseList) {
              html=await study.httpGetHtml(course.link);
              if (html!=null) {
                var forumList = study.getForums(html,course.id!);
                //print('forums');
                await db.updateDB(newData: forumList, whereId: 'courseId', id: course.id!);
                forumList = await db.getObjectsById(object: Forum, id: course.id!)
                            as List<Forum>;
                for (var forum in forumList) {
                  if (forum.unread=='- new') {
                    //print('unread - new');
                    html = await study.httpGetHtml(forum.link);
                    if (html!=null) {
                      var discussionList = study.getDiscussions(html, forum.id!);
                      //print('discussion');
                      await db.updateDB(
                          newData: discussionList,
                          whereId: 'forumId',
                          id: forum.id!);
                      discussionList = await db.getObjectsById(
                          object: Discussion,
                          id: forum.id!) as List<Discussion>;
                      //print('b');
                      for (var discussion in discussionList) {
                        //print('c');
                        if (discussion.repliesUnread!=0) {
                          //print('d');
                          html = await study.httpGetHtml(discussion.link);
                          if (html!=null) {
                            var postList = study.getPosts(html, discussion.id!);
                            //print('post');
                            await db.updateDB(
                                newData: postList,
                                whereId: 'discussionId',
                                id: discussion.id!);
                            //print('a');
                            postList = await db.getObjectsById(
                                object: Post,
                                id: discussion.id!) as List<Post>;
                            //print(postList.last.toMap());
                            await notificationServices.showNotification(
                                id: notifId,
                                title: discussion.title+' - '+postList.last.author,
                                body: postList.last.content,
                                payload: discussion.id.toString()+' '+'/PostsPage'
                            );
                            //print('notification with id: '+notifId.toString());
                            ++notifId;
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
        break;
      case 'grade':
        HttpOverrides.global = new MyHttpOverrides();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var activeUserId=prefs.getInt('userId')?? 0;
        if (activeUserId==0) { break; }
        var server=prefs.getString('server')??'';
        var study = HttpServices();
        var html = await study.httpGetHtml('https://$server/my/');
        if (html!=null) {
          var courseList = study.getCourses(html, activeUserId);
          if (courseList.isNotEmpty) {
            var db = DatabaseServices.instance;
            await db.updateDB(
                newData: courseList,
                whereId: 'userId',
                id: activeUserId);
            courseList = await db.getObjectsById(
                object: Course,
                id: activeUserId) as List<Course>;
            int notifId = 100;
            for (var course in courseList) {
              html = await study.httpGetHtml(course.link);
              if (html != null) {
                var emptyGradeAssignList = study.getAssigns(html, course.id!);
                var existedAssigns=await db.getObjectsById(object: Assign, id: course.id);
                //...  update DB if new assign exists...
                await db.updateDB(
                    newData: emptyGradeAssignList,
                    whereId: 'courseId',
                    id: course.id!);
                var dbase = await db.database;
                var emptyGradeLinksRows = await dbase.query('Assign',
                    where: 'grade=? AND courseId=?',
                    whereArgs: ['', course.id]);
                emptyGradeAssignList = emptyGradeLinksRows.isNotEmpty
                    ? emptyGradeLinksRows.map((c) => Assign.fromMap(c)).toList()
                    : [];
                for (var e in emptyGradeAssignList) {
                  var html = await study.httpGetHtml(e.link);
                  if (html != null) {
                    var grade = study.getGrade(html);
                    if (grade != '') {
                      await dbase.update('Assign', {'grade': grade},
                          where: 'link=? AND courseId=?',
                          whereArgs: [e.link, course.id]);
                      if (existedAssigns.isNotEmpty) {
                        await notificationServices.showNotification(
                            id: notifId,
                            title: course.title,
                            body: e.title + ': ' + grade,
                            payload: course.id.toString() + ' ' + '/AssignsPage'
                        );
                        ++notifId;
                      }
                    } else if (grade == '') {
                      break;
                    }
                  } else {
                    break;
                  }
                }
                await db.setUpdateTime(object: 'assigns', foreignId: course.id!);
              }
            }
          }
        }
        break;
    }
    return Future.value(true);
  });
}

Future<void> activateEventNotifications(bool on, int userId) async {
  var dbase= await DatabaseServices.instance.database;
  if (on==true) {
    await Workmanager().registerPeriodicTask(
      '1',
      'event',
      initialDelay: Duration(minutes: 5),
      frequency: Duration(hours: 8),
      existingWorkPolicy: ExistingWorkPolicy.append
    );
  } else {
    await Workmanager().cancelByUniqueName('1');
    await notificationServices.notifications.cancelAll();
    var notificationIdsListMap = await dbase.query('Event',
        columns: ['notificationId', 'id'],
        where: 'userId=?',
        whereArgs: [userId]);
    for (var el in notificationIdsListMap) {
      if (el['notificationId']!=0) {
        await dbase.update('Event',
            {'notificationId':0},
            where: 'id=?',
            whereArgs: [el['id']]);
      }
    }
  }
}

Future<void> activatePostNotifications({required int time}) async {
  await Workmanager().cancelByUniqueName('2');
  if (time!=0) {
    await Workmanager().registerPeriodicTask(
      '2',
      'post',
      initialDelay: Duration(minutes: 10),
      frequency: Duration(hours: time),
      existingWorkPolicy: ExistingWorkPolicy.append
    );
  }
}

Future<void> activateMessageNotifications({required int time}) async {
  await Workmanager().cancelByUniqueName('4');
  if (time!=0) {
    await Workmanager().registerPeriodicTask(
        '4',
        'messages',
        initialDelay: Duration(minutes: 15),
        frequency: Duration(hours: time),
        existingWorkPolicy: ExistingWorkPolicy.append
    );
  }
}

Future<void> activateGradeNotifications(bool on) async {
  if (on==true) {
    await Workmanager().registerPeriodicTask(
      '3',
      'grade',
      initialDelay: Duration(minutes: 20),
      frequency: Duration(hours: 12),
      existingWorkPolicy: ExistingWorkPolicy.append
    );
  } else {
    await Workmanager().cancelByUniqueName('3');
  }
}

