import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import '../Models.dart';
import '../main.dart';
import 'DataBaseServices.dart';
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
        //var moodleSession = await study.reConnect(activeUserId);
        //if (moodleSession=='no connection') {break;}
        var html = await study.getHtml('https://study.eap.gr/my/');
        if (html!=null) {
          var eventList = study.getEvents(html, activeUserId);
          var db = DBServices.instance;
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
                //print(eventDateTime);
                var now=DateTime.now();
                if (now.isBefore(eventDateTime) &&
                    now.isAfter(eventDateTime.subtract(Duration(days: 2)))) {
                  var notifId=now.millisecond!=0
                      ? now.millisecond
                      : now.millisecond+1;
                  await notificationServices.showNotificationScheduled(
                      id: notifId+200,
                      title: event.dateTime,
                      body: event.type,
                      dateTime: eventDateTime,
                      payload: ' /EventsPage'
                  );
                  var dbase = await db.database;
                  await dbase.update('Event', {'notificationId': notifId},
                      where: 'linkId=? AND userId=?',
                      whereArgs: [event.linkId, activeUserId]);
                  //print('notification with id: '+notificationId.toString());
                } //else { print('dateTime too ealy for notification');}
              }
            }
          }
          await db.setUpdateTime(object: 'events', foreignId: activeUserId);
        }
        break;
      case 'post':
        HttpOverrides.global = new MyHttpOverrides();
        //print('start');
        SharedPreferences prefs = await SharedPreferences.getInstance();
        var activeUserId=prefs.getInt('userId')?? 0;
        if (activeUserId==0) { break; }
        var study = HttpServices();
        //var moodleSession = await study.reConnect(activeUserId);
        //if (moodleSession=='no connection') {break;}
        var html = await study.getHtml('https://study.eap.gr/my/');
        if (html!=null) {
          var courseList = study.getCourses(html, activeUserId);
          print('courses');
          if (courseList.isNotEmpty) {
            var db = DBServices.instance;
            await db.updateDB(
                newData: courseList,
                whereId: 'userId',
                id: activeUserId);
            courseList = await db.getObjectsById(object: Course, id: activeUserId)
            as List<Course>;
            int notifId=0;
            for (var course in courseList) {
              html=await study.getHtml(course.linkId);
              if (html!=null) {
                var forumList = study.getForums(html,course.id!);
                print('forums');
                await db.updateDB(newData: forumList, whereId: 'courseId', id: course.id!);
                forumList = await db.getObjectsById(object: Forum, id: course.id!)
                            as List<Forum>;
                for (var forum in forumList) {
                  if (forum.unread=='- new') {
                    print('unread - new');
                    html = await study.getHtml(forum.linkId);
                    if (html!=null) {
                      var discussionList = study.getDiscussions(html, forum.id!);
                      print('discussion');
                      await db.updateDB(
                          newData: discussionList,
                          whereId: 'forumId',
                          id: forum.id!);
                      discussionList = await db.getObjectsById(
                          object: Discussion,
                          id: forum.id!) as List<Discussion>;
                      for (var discussion in discussionList) {
                        if (discussion.repliesUnread!=0) {
                          html = await study.getHtml(discussion.linkId);
                          if (html!=null) {
                            var postList = study.getPosts(html, discussion.id!);
                            await db.updateDB(
                                newData: postList,
                                whereId: 'discussionId',
                                id: discussion.id!);
                            postList = await db.getObjectsById(
                                object: Post,
                                id: discussion.id!) as List<Post>;
                            await notificationServices.showNotification(
                                id: notifId,
                                title: discussion.title+' - '+postList.last.author,
                                body: postList.last.content,
                                payload: discussion.id.toString()+' '+'/PostsPage'
                            );
                            print('notification with id: '+notifId.toString());
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
        //var moodleSession = await study.reConnect(activeUserId);
        //if (moodleSession=='no connection') {break;}
        var html = await study.getHtml('https://study.eap.gr/my/');
        if (html!=null) {
          var courseList = study.getCourses(html, activeUserId);
          if (courseList.isNotEmpty) {
            var db = DBServices.instance;
            await db.updateDB(
                newData: courseList,
                whereId: 'userId',
                id: activeUserId);
            courseList = await db.getObjectsById(
                object: Course,
                id: activeUserId) as List<Course>;
            int notifId = 100;
            for (var course in courseList) {
              html = await study.getHtml(course.linkId);
              if (html != null) {
                var emptyGradeList = study.getEmptyGrades(html, course.id!);
                var existedGrades=await db.getObjectsById(object: Grade, id: course.id);
                //...  update DB if new assign exists...
                await db.updateDB(
                    newData: emptyGradeList,
                    whereId: 'courseId',
                    id: course.id!);
                var dbase = await db.database;
                var emptyGradeLinksRows = await dbase.query('Grade',
                    where: 'grade=? AND courseId=?',
                    whereArgs: ['', course.id]);
                emptyGradeList = emptyGradeLinksRows.isNotEmpty
                    ? emptyGradeLinksRows.map((c) => Grade.fromMap(c)).toList()
                    : [];
                for (var e in emptyGradeList) {
                  var html = await study.getHtml(e.linkId);
                  if (html != null) {
                    var grade = study.getGrade(html);
                    if (grade != '') {
                      //print('new grade: '+grade);
                      await dbase.update('Grade', {'grade': grade},
                          where: 'linkId=? AND courseId=?',
                          whereArgs: [e.linkId, course.id]);
                      if (existedGrades.isNotEmpty) {
                        await notificationServices.showNotification(
                            id: notifId,
                            title: course.name,
                            body: e.assign + ': ' + grade,
                            payload: course.id.toString() + ' ' + '/GradesPage'
                        );
                        //print('notification with id: '+notifId.toString());
                        ++notifId;
                      }
                    } else if (grade == '') {
                      //print('no grade left, break');
                      break;
                    }
                  } else {
                    //print('http error, break');
                    break;
                  }
                }
                await db.setUpdateTime(object: 'grades', foreignId: course.id!);
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
  var dbase= await DBServices.instance.database;
  if (on==true) {
    await Workmanager().registerPeriodicTask(
      '1',
      'event',
      initialDelay: Duration(minutes: 10),
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
        //await notificationServices.notifications.cancel(el['notificationId']??0);
        await dbase.update('Event',
            {'notificationId':0},
            where: 'id=?',
            whereArgs: [el['id']]);
      }
    }
  }
  await dbase.update('User',
      {'eventNotification': on? 1: 0},
      where: 'id=?',
      whereArgs: [userId]);
  //var newuser=await DBServices.instance.getUser(id: userId);
  //print(newuser.toMap());
}

Future<void> activatePostNotifications(bool on, int userId,{int? hours}) async {
  if (on==true) {
    // await notificationServices.showNotification(
    //     id: 3,
    //     title: 'λαλα',
    //     body: 'μπλα',
    //     payload: '1'+' '+'/PostsPage'
    // );
    // await Future.delayed(Duration(seconds: 2));
    // await notificationServices.showNotification(
    //     id: 4,
    //     title: 'λαλα2',
    //     body: 'μπλα2',
    //     payload: '2'+' '+'/PostsPage'
    // );
    await Workmanager().registerPeriodicTask(
      '2',
      'post',
      initialDelay: Duration(minutes: 5),
      frequency: Duration(hours: hours??4)
    );
  } else {
    await Workmanager().cancelByUniqueName('2');
  }
  var dbase= await DBServices.instance.database;
  await dbase.update('User',
      {'postNotification': on? 1: 0},
      where: 'id=?',
      whereArgs: [userId]);
}

Future<void> activateGradeNotifications(bool on, int userId) async {
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
  var dbase= await DBServices.instance.database;
  await dbase.update('User',
      {'gradeNotification': on? 1: 0},
      where: 'id=?',
      whereArgs: [userId]);
}

