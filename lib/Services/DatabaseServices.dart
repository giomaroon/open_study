
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gio_app/Services/BackgroundServices.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';

import '../Models.dart';

class DatabaseServices {

  DatabaseServices._privateConstructor();
  static final DatabaseServices instance = DatabaseServices._privateConstructor();

  static Database? _database;

  Future<Database> get database async => _database ??= await _initDatabase();

  Future<Database> _initDatabase() async {

    var storage=FlutterSecureStorage();
    var dbpass=await storage.read(key: 'dbpass');
    print('dbpass: $dbpass');

    var databasesPath = await getDatabasesPath();
    String path=join(databasesPath, 'studyAppDB.db');

    return await openDatabase(
        path,
        version: 2,
        password: dbpass,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade
    );
  }

  Future _onCreate(Database db, int version) async {
    print('onCreate');
    print(version);
    await db.execute('''
      CREATE TABLE User(
          id INTEGER PRIMARY KEY,
          username TEXT,
          password TEXT,          
          studentName TEXT,
          eventNotification INTEGER,
          postNotification INTEGER,
          messageNotification INTEGER,
          gradeNotification INTEGER,
          eventsUpdateTime TEXT,
          messengerUpdateTime TEXT                   
      )
      ''');
    await db.execute('''
      CREATE TABLE Course(
          id INTEGER PRIMARY KEY,          
          title TEXT,
          link TEXT,
          gradesUpdateTime text,
          userId INTEGER REFERENCES User (id)
          ON DELETE CASCADE
      )
      ''');
    await db.execute('''
      CREATE TABLE Event(
          id INTEGER PRIMARY KEY,
          link TEXT,
          title TEXT,         
          dateTime TEXT,
          dateTimeParsed TEXT,
          webex TEXT,
          notificationId INTEGER,
          userId INTEGER,
          FOREIGN KEY (userId) REFERENCES User (id)
          ON DELETE CASCADE               
      )
      ''');
    await db.execute('''
      CREATE TABLE Forum(
          id INTEGER PRIMARY KEY,          
          title TEXT,
          link TEXT,
          unread TEXT,
          discussionsUpdateTime TEXT,
          courseId INTEGER,
          FOREIGN KEY (courseId) REFERENCES Course (id)
          ON DELETE CASCADE
      )
      ''');
    await db.execute('''
      CREATE TABLE Discussion(
          id INTEGER PRIMARY KEY,
          title  TEXT,
          authorFirst TEXT,
          authorLast TEXT,
          dateTime TEXT,
          dateTimeParsed TEXT,
          replies INTEGER,
          repliesUnread INTEGER,
          link TEXT,
          postsUpdateTime TEXT,
          forumId INTEGER,
          FOREIGN KEY (forumId) REFERENCES Forum (id)
          ON DELETE CASCADE
      )
      ''');
    await db.execute('''
      CREATE TABLE Post(
          id INTEGER PRIMARY KEY,
          link TEXT,
          dateTime TEXT,
          author TEXT,          
          title  TEXT,
          content TEXT,
          discussionId INTEGER,
          FOREIGN KEY (discussionId) REFERENCES Discussion (id)
          ON DELETE CASCADE          
      )
      ''');
    await db.execute('''
      CREATE TABLE Assign(
          id INTEGER PRIMARY KEY,
          title TEXT,
          grade TEXT,
          link TEXT,
          courseId INTEGER,
          FOREIGN KEY (courseId) REFERENCES Course (id)
          ON DELETE CASCADE               
      )
      ''');
    await db.execute('''
      CREATE TABLE Contact(
          id INTEGER PRIMARY KEY,
          link INTEGER,
          name TEXT,
          lastMessage TEXT,
          chatUpdateTime TEXT,
          position INTEGER,
          userId INTEGER REFERENCES User (id)
          ON DELETE CASCADE
      )
      ''');
    await db.execute('''
      CREATE TABLE Message(
          id INTEGER PRIMARY KEY,
          link INTEGER,
          position TEXT,
          text TEXT,
          timesent TEXT,
          blocktime TEXT,
          contactId INTEGER REFERENCES Contact (id)
          ON DELETE CASCADE          
      )
      ''');
  }

  Future _onUpgrade(Database db, int oldVersion, int newVersion) async {
    print('onUpgrade');
    print('old'); print(oldVersion);
    print('new'); print(newVersion);
    if (oldVersion == 1) {
      await db.execute('ALTER TABLE User ADD messageNotification INTEGER DEFAULT 8');
      await db.execute('ALTER TABLE User ADD messengerUpdateTime TEXT');
      await db.execute('''
      CREATE TABLE Contact(
          id INTEGER PRIMARY KEY,
          link INTEGER,
          name TEXT,
          lastMessage TEXT,
          chatUpdateTime TEXT,
          position INTEGER,
          userId INTEGER REFERENCES User (id)
          ON DELETE CASCADE
      )
      ''');
      await db.execute('''
      CREATE TABLE Message(
          id INTEGER PRIMARY KEY,
          link INTEGER,
          position TEXT,
          text TEXT,
          timesent TEXT,
          blocktime TEXT,
          contactId INTEGER REFERENCES Contact (id)
          ON DELETE CASCADE
      )
      ''');
    }


  }

  Future<void> setUpdateTime({required String object, required int foreignId}) async {
    var now=DateTime.now();
    Database db = await instance.database;
    switch (object) {
      case 'events':
        await db.update('User', {'eventsUpdateTime':now.toString()}, where: 'id=?',
            whereArgs: [foreignId]);
        break;
      case 'contacts':
        await db.update('User', {'messengerUpdateTime':now.toString()}, where: 'id=?',
            whereArgs: [foreignId]);
        break;
      case 'messages':
        await db.update('Contact', {'chatUpdateTime':now.toString()}, where: 'id=?',
            whereArgs: [foreignId]);
        break;
      case 'assigns':
        await db.update('Course', {'gradesUpdateTime':now.toString()}, where: 'id=?',
            whereArgs: [foreignId]);
        break;
      case 'discussions':
        await db.update('Forum', {'discussionsUpdateTime':now.toString()}, where: 'id=?',
            whereArgs: [foreignId]);
        break;
      case 'posts':
        await db.update('Discussion', {'postsUpdateTime':now.toString()}, where: 'id=?',
            whereArgs: [foreignId]);
        break;
      default:
        print('error on setUpdateTime');
        break;
    }
  }

  Future<String> getUpdateTime({required String object, required int foreignId}) async {
    Database db = await instance.database;
    String updateTime='';
    switch (object) {
      case 'events':
        var updateTimeDB = await db.query('User', columns: ['eventsUpdateTime'], where: 'id=?',
            whereArgs: [foreignId]);
        if (updateTimeDB.isNotEmpty) {
          updateTime=updateTimeDB[0]['eventsUpdateTime'] as String;
        }
        return updateTime;
      case 'contacts':
        var updateTimeDB = await db.query('User', columns: ['messengerUpdateTime'], where: 'id=?',
            whereArgs: [foreignId]);
        if (updateTimeDB.isNotEmpty) {
          updateTime=updateTimeDB[0]['messengerUpdateTime'] as String;
        }
        return updateTime;
      case 'messages':
        var updateTimeDB = await db.query('Contact', columns: ['chatUpdateTime'], where: 'id=?',
            whereArgs: [foreignId]);
        if (updateTimeDB.isNotEmpty) {
          updateTime=updateTimeDB[0]['chatUpdateTime'] as String;
        }
        return updateTime;
      case 'assigns':
        var updateTimeDB = await db.query('Course', columns: ['gradesUpdateTime'], where: 'id=?',
            whereArgs: [foreignId]);
        if (updateTimeDB.isNotEmpty) {
          updateTime=updateTimeDB[0]['gradesUpdateTime'] as String;
        }
        return updateTime;
      case 'discussions':
        var updateTimeDB = await db.query('Forum', columns: ['discussionsUpdateTime'], where: 'id=?',
            whereArgs: [foreignId]);
        if (updateTimeDB.isNotEmpty) {
          updateTime=updateTimeDB[0]['discussionsUpdateTime'] as String;
        }
        return updateTime;
      case 'posts':
        var updateTimeDB = await db.query('Discussion', columns: ['postsUpdateTime'], where: 'id=?',
            whereArgs: [foreignId]);
        if (updateTimeDB.isNotEmpty) {
          updateTime=updateTimeDB[0]['postsUpdateTime'] as String;
        }
        return updateTime;
      default:
        print('error on getUpdateTime');
        return updateTime;
    }
  }

  Future<int> updateUserAndNotifSettings(User user) async {
    var userId;
    bool eventNotifOn=true;
    int postNotifTime=8;
    int messageNotifTime=8;
    bool gradeNotifOn=true;
    bool userExists=false;
    Database db = await instance.database;
    var usersDBListMap = await db.query('User');
    if (usersDBListMap.isNotEmpty) {
      for (var userDB in usersDBListMap) {
        // check if user exists....
        if (userDB['username'] == user.username) {
          userExists=true;
          print('user exists');
          // update password and student rname in case they have changed
          await db.update('User',
              {'password': user.password,
                'studentName': user.studentName},
              where: 'id=?',
              whereArgs: [userDB['id']]);

          eventNotifOn=userDB['eventNotification']==1? true: false;
          postNotifTime=userDB['postNotification'] as int;
          messageNotifTime=userDB['messageNotification'] as int;
          gradeNotifOn=userDB['gradeNotification']==1? true: false;
          userId = userDB['id'];
          break;
        }
      }
    }
    if (!userExists) {
      print('inserting user to db');
      userId = await db.insert('User', user.toMap());
    }
    await activateEventNotifications(eventNotifOn, userId);
    await activatePostNotifications(time: postNotifTime);
    await activateMessageNotifications(time: messageNotifTime);
    await activateGradeNotifications(gradeNotifOn);
    //var dbase= await db.database;
    await db.update('User',
        {'eventNotification': eventNotifOn? 1: 0,
          'postNotification': postNotifTime,
          'messageNotification': messageNotifTime,
          'gradeNotification': gradeNotifOn? 1: 0},
        where: 'id=?',
        whereArgs: [userId]);
    return userId;
  }

  Future<List<User>> getUsers() async {
    Database db = await instance.database;
    var rows = await db.query('User');
    //print(rows);
    List<User> list = rows.isNotEmpty
        ? rows.map((c) => User.fromMap(c)).toList()
        : [];
    return list;
  }

  Future<User> getUser({int? id}) async {
    Database db = await instance.database;
    var rows = await db.query('User', where: 'id = ?', whereArgs: [id]);
    var user = User.fromMap(rows[0]);
    return user;
  }

  Future<int> updateDB({List? newData, String? whereId, int? id}) async {
    List _newData=[...newData??[]];
    var rows=0;
    Database db = await instance.database;
    if (_newData.isEmpty || id==null) {
      return 0;
    } else {
      var table = _newData[0].runtimeType.toString();

      try {
        // get links from oldData and newData
        var oldDataLinks = await db.query(
            table, columns: ['link'], where: '$whereId = ?', whereArgs: [id]
        );
        var newDataLinks = [];
        _newData.forEach((e) => newDataLinks.add(e.link));

        for (var el in oldDataLinks) {
          //  if newData not contain el of oldData then remove el from DB
          //  else (if newData = Forum or Discussion then update them)
          //  remove el from newData
          if (!newDataLinks.contains(el['link'])) {
            db.execute('PRAGMA foreign_keys=ON');
            await db.delete(
                table, where: 'link=? AND $whereId=?', whereArgs: [el['link'], id]);
          } else {
            if (table=='Forum') {
              var newDataItemList=_newData.where(
                      (element) => element.link==el['link']).toList();
              if (newDataItemList.isNotEmpty) {
                await db.update(
                    table, {'unread': newDataItemList[0].unread},
                    where: 'link=? AND courseId=?',
                    whereArgs: [newDataItemList[0].link, id]);
              }
            } else if (table=='Discussion') {
              var newDataItemList=_newData.where(
                      (element) => element.link==el['link']).toList();
              if (newDataItemList.isNotEmpty) {
                await db.update(
                    table,
                    {
                      'authorLast': newDataItemList[0].authorLast,
                      'dateTime': newDataItemList[0].dateTime,
                      'dateTimeParsed': newDataItemList[0].dateTimeParsed,
                      'replies': newDataItemList[0].replies,
                      'repliesUnread':newDataItemList[0].repliesUnread,
                    },
                    where: 'link=? AND forumId=?',
                    whereArgs: [newDataItemList[0].link, id]
                );
              }
            } else if (table=='Contact') {
              var newDataItemList=_newData.where(
                      (element) => element.link==el['link']).toList();
              if (newDataItemList.isNotEmpty) {
                await db.update(
                    table, {'lastMessage': newDataItemList[0].lastMessage,
                            'position': newDataItemList[0].position},
                    where: 'link=? AND userId=?',
                    whereArgs: [newDataItemList[0].link, id]);
              }
            }
            _newData.removeWhere((item) => item.link == el['link']);
          }
        }
        if (_newData.isNotEmpty) {
          for (int i = 0; i < _newData.length; i++) {
            rows=await db.insert(table, _newData[i].toMap());
          }
        }
      } catch (err) {
        //print('ERROR...:');
        print(err);
      }
    }
    //print('DB updated');
    return rows;
  }


  Future<List<dynamic>> getObjectsById({Object? object, int? id}) async {
    Database db = await instance.database;
    switch (object) {
      case Course : {
        var objectsDB = await db.query('Course', where: 'userId = ?', whereArgs: [id]);
        List<Course> list = objectsDB.isNotEmpty
            ? objectsDB.map((c) => Course.fromMap(c)).toList()
            : [];
        return list;
      }
      case Event : {
        var objectsDB = await db.query('Event', where: 'userId = ?', whereArgs: [id],
            orderBy: 'dateTimeParsed');
        List<Event> list = objectsDB.isNotEmpty
            ? objectsDB.map((c) => Event.fromMap(c)).toList()
            : [];
        return list;
      }
      case Forum : {
        var objectsDB = await db.query('Forum', where: 'courseId = ?', whereArgs: [id]);
        List<Forum> list = objectsDB.isNotEmpty
            ? objectsDB.map((c) => Forum.fromMap(c)).toList()
            : [];
        return list;
      }
      case Assign : {
        var objectsDB = await db.query('Assign', where: 'courseId = ?', whereArgs: [id]);
        List<Assign> list = objectsDB.isNotEmpty
            ? objectsDB.map((c) => Assign.fromMap(c)).toList()
            : [];
        return list;
      }
      case Discussion : {
        var objectsDB = await db.query('Discussion', where: 'forumId = ?', whereArgs: [id],
            orderBy: 'dateTimeParsed DESC');
        List<Discussion> list = objectsDB.isNotEmpty
            ? objectsDB.map((c) => Discussion.fromMap(c)).toList()
            : [];
        return list;
      }
      case Post : {
        var objectsDB = await db.query('Post', where: 'discussionId = ?', whereArgs: [id]);
        List<Post> list = objectsDB.isNotEmpty
            ? objectsDB.map((c) => Post.fromMap(c)).toList()
            : [];
        return list;
      }
      case Contact : {
        var objectsDB = await db.query('Contact', where: 'userId = ?', whereArgs: [id],
            orderBy: 'position'
        );
        List<Contact> list = objectsDB.isNotEmpty
            ? objectsDB.map((c) => Contact.fromMap(c)).toList()
            : [];
        return list;
      }
      case Message : {
        var objectsDB = await db.query('Message', where: 'contactId = ?', whereArgs: [id]);
        List<Message> list = objectsDB.isNotEmpty
            ? objectsDB.map((c) => Message.fromMap(c)).toList()
            : [];
        return list;
      }
      default: {
        return [];
      }
    }
  }

  Future<int> removeAllById(String table,{String? column, int? id}) async {
    Database db = await instance.database;
    db.execute('PRAGMA foreign_keys=ON');
    return await db.delete(table, where: '$column = ?', whereArgs: [id]);
  }

  Future<int> removeAll(String table) async {
    Database db = await instance.database;
    return await db.delete(table);
  }

  Future<List<Course>> getCourses() async {
    Database db = await instance.database;
    var courses = await db.query('Course');
    List<Course> coursesList = courses.isNotEmpty
        ? courses.map((c) => Course.fromMap(c)).toList()
        : [];
    return coursesList;
  }

  Future<List<Forum>> getForums() async {
    Database db = await instance.database;
    var forums = await db.query('Forum');
    List<Forum> forumsList = forums.isNotEmpty
        ? forums.map((c) => Forum.fromMap(c)).toList()
        : [];
    return forumsList;
  }

  Future<List<Discussion>> getDiscuccions() async {
    Database db = await instance.database;
    var rows = await db.query('Discussion');
    List<Discussion> list = rows.isNotEmpty
        ? rows.map((c) => Discussion.fromMap(c)).toList()
        : [];
    return list;
  }

  Future<List<Post>> getPosts() async {
    Database db = await instance.database;
    var rows = await db.query('Post');
    List<Post> list = rows.isNotEmpty
        ? rows.map((c) => Post.fromMap(c)).toList()
        : [];
    return list;
  }

  Future<List<Event>> getEvents() async {
    Database db = await instance.database;
    var rows = await db.query('Event');
    List<Event> list = rows.isNotEmpty
        ? rows.map((c) => Event.fromMap(c)).toList()
        : [];
    return list;
  }

  Future<List<Assign>> getAssigns() async {
    Database db = await instance.database;
    var rows = await db.query('Assign');
    List<Assign> list = rows.isNotEmpty
        ? rows.map((c) => Assign.fromMap(c)).toList()
        : [];
    return list;
  }

  Future<List<Contact>> getContacts() async {
    Database db = await instance.database;
    var rows = await db.query('Contact');
    List<Contact> list = rows.isNotEmpty
        ? rows.map((c) => Contact.fromMap(c)).toList()
        : [];
    return list;
  }

  Future<List<Message>> getMessages() async {
    Database db = await instance.database;
    var rows = await db.query('Message');
    List<Message> list = rows.isNotEmpty
        ? rows.map((c) => Message.fromMap(c)).toList()
        : [];
    return list;
  }

}