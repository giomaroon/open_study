
class User {
  final int? id;
  final String username;
  final String password;
  final String studentName;
  final int eventNotification;
  final int postNotification;
  final int gradeNotification;
  final String eventsUpdateTime;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.studentName,
    required this.eventNotification,
    required this.postNotification,
    required this.gradeNotification,
    required this.eventsUpdateTime
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'studentName': studentName,
      'eventNotification': eventNotification,
      'postNotification': postNotification,
      'gradeNotification': gradeNotification,
      'eventsUpdateTime': eventsUpdateTime
    };
  }
  factory User.fromMap(Map<String, dynamic> map) => new User(
      id: map['id'],
      username: map['username'],
      password: map['password'],
      studentName: map['studentName'],
      eventNotification: map['eventNotification'],
      postNotification: map['postNotification'],
      gradeNotification: map['gradeNotification'],
      eventsUpdateTime: map['eventsUpdateTime']
  );
}


class Course {
  final int? id;
  final String name;
  final String linkId;
  final String gradesUpdateTime;
  final int? userId;
  final String courseFid = 'userId';

  Course({
    this.id,
    required this.name,
    required this.linkId,
    required this.gradesUpdateTime,
    this.userId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'linkId': linkId,
      'gradesUpdateTime': gradesUpdateTime,
      'userId': userId
    };
  }
  factory Course.fromMap(Map<String, dynamic> map) => new Course(
      id: map['id'],
      name: map['name'],
      linkId: map['linkId'],
      gradesUpdateTime: map['gradesUpdateTime'],
      userId: map['userId']
  );
}

class Forum {
  final int? id;
  final String name;
  final String linkId;
  final String unread;
  final String discussionsUpdateTime;
  final int? courseId;

  Forum({
    this.id,
    required this.name,
    required this.linkId,
    required this.unread,
    required this.discussionsUpdateTime,
    this.courseId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'linkId': linkId,
      'unread': unread,
      'discussionsUpdateTime': discussionsUpdateTime,
      'courseId': courseId
    };
  }
  factory Forum.fromMap(Map<String, dynamic> map) => new Forum(
    id: map['id'],
    name: map['name'],
    linkId: map['linkId'],
    unread: map['unread'],
    discussionsUpdateTime: map['discussionsUpdateTime'],
    courseId: map['courseId']
  );
}

class Discussion {
  final int? id;
  final String title;
  final String authorFirst;
  final String authorLast;
  final String dateTime;
  final String dateTimeParsed;
  final int replies;
  final int repliesUnread;
  final String linkId;
  final String postsUpdateTime;
  final int? forumId;

  Discussion({
    this.id,
    required this.title,
    required this.authorFirst,
    required this.authorLast,
    required this.dateTime,
    required this.dateTimeParsed,
    required this.replies,
    required this.repliesUnread,
    required this.linkId,
    required this.postsUpdateTime,
    this.forumId
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'authorFirst': authorFirst,
      'authorLast': authorLast,
      'dateTime': dateTime,
      'dateTimeParsed': dateTimeParsed,
      'replies': replies,
      'repliesUnread': repliesUnread,
      'linkId': linkId,
      'postsUpdateTime': postsUpdateTime,
      'forumId': forumId
    };
  }
  factory Discussion.fromMap(Map<String, dynamic> map) => new Discussion(
    id: map['id'],
    title: map['title'],
    authorFirst: map['authorFirst'],
    authorLast: map['authorLast'],
    dateTime: map['dateTime'],
    dateTimeParsed: map['dateTimeParsed'],
    replies: map['replies'],
    repliesUnread: map['repliesUnread'],
    linkId: map['linkId'],
    postsUpdateTime: map['postsUpdateTime'],
    forumId: map['forumId']
  );
}

class Post {
  final int? id;
  final String linkId;
  final String dateTime;
  final String author;
  final String title;
  final String content;
  final int? discussionId;

  Post({
    this.id,
    required this.linkId,
    required this.dateTime,
    required this.author,
    required this.title,
    required this.content,
    this.discussionId
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'linkId': linkId,
      'dateTime': dateTime,
      'author': author,
      'title': title,
      'content': content,
      'discussionId': discussionId
    };
  }
  factory Post.fromMap(Map<String, dynamic> map) => new Post(
    id: map['id'],
    linkId: map['linkId'],
    dateTime: map['dateTime'],
    author: map['author'],
    title: map['title'],
    content: map['content'],
    discussionId: map['discussionId']
  );
}

class Event {
  final int? id;
  final String linkId;
  final String type;
  final String dateTime;
  final String dateTimeParsed;
  final String webex;
  final int notificationId;
  final int? userId;

  Event({
    this.id,
    required this.linkId,
    required this.type,
    required this.dateTime,
    required this.dateTimeParsed,
    required this.webex,
    required this.notificationId,
    this.userId
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'linkId': linkId,
      'type': type,
      'dateTime': dateTime,
      'dateTimeParsed': dateTimeParsed,
      'webex': webex,
      'notificationId': notificationId,
      'userId': userId
    };
  }
  factory Event.fromMap(Map<String, dynamic> map) => new Event(
    id: map['id'],
    linkId: map['linkId'],
    type: map['type'],
    dateTime: map['dateTime'],
    dateTimeParsed: map['dateTimeParsed'],
    webex: map['webex'],
    notificationId: map['notificationId'],
    userId: map['userId']
  );
}

class Grade {
  final int? id;
  final String assign;
  final String grade;
  final String linkId;
  final int? courseId;


  Grade({
    this.id,
    required this.assign,
    required this.grade,
    required this.linkId,
    this.courseId
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'assign': assign,
      'grade': grade,
      'linkId': linkId,
      'courseId': courseId
    };
  }
  factory Grade.fromMap(Map<String, dynamic> map) => new Grade(
    id: map['id'],
    assign: map['assign'],
    grade: map['grade'],
    linkId: map['linkId'],
    courseId: map['courseId']
  );
}
