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
      case 'event':
        HttpOverrides.global = new MyHttpOverrides();
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var activeUserId=prefs.getInt('userId')?? 0;
        if (activeUserId==0) { break; }
        var study = HttpServices();
        var html = await study.getHtml('https://study.eap.gr/my/');
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
                      id: notifId+200,
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
        var study = HttpServices();
        var html = await study.getHtml('https://study.eap.gr/my/');
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
              html=await study.getHtml(course.link);
              if (html!=null) {
                var forumList = study.getForums(html,course.id!);
                //print('forums');
                await db.updateDB(newData: forumList, whereId: 'courseId', id: course.id!);
                forumList = await db.getObjectsById(object: Forum, id: course.id!)
                            as List<Forum>;
                for (var forum in forumList) {
                  if (forum.unread=='- new') {
                    //print('unread - new');
                    html = await study.getHtml(forum.link);
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
                          html = await study.getHtml(discussion.link);
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
        var study = HttpServices();
        var html = await study.getHtml('https://study.eap.gr/my/');
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
              html = await study.getHtml(course.link);
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
                  var html = await study.getHtml(e.link);
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
      frequency: Duration(hours: 12)
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
  //print('cancel post notif');
  if (time!=0) {
    //print('post notif is on: '+time.toString());
    await Workmanager().registerPeriodicTask(
        '2',
        'post',
        initialDelay: Duration( minutes: 10),
        frequency: Duration(hours: time)
    );
  }
}

Future<void> activateGradeNotifications(bool on) async {
  if (on==true) {
    await Workmanager().registerPeriodicTask(
      '3',
      'grade',
      initialDelay: Duration(minutes: 15),
      frequency: Duration(hours: 24)
    );
  } else {
    await Workmanager().cancelByUniqueName('3');
  }
}

