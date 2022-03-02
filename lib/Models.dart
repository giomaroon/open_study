
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
  final String title;
  final String link;
  final String gradesUpdateTime;
  final int? userId;
  final String courseFid = 'userId';

  Course({
    this.id,
    required this.title,
    required this.link,
    required this.gradesUpdateTime,
    this.userId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'link': link,
      'gradesUpdateTime': gradesUpdateTime,
      'userId': userId
    };
  }
  factory Course.fromMap(Map<String, dynamic> map) => new Course(
      id: map['id'],
      title: map['title'],
      link: map['link'],
      gradesUpdateTime: map['gradesUpdateTime'],
      userId: map['userId']
  );
}

class Forum {
  final int? id;
  final String title;
  final String link;
  final String unread;
  final String discussionsUpdateTime;
  final int? courseId;

  Forum({
    this.id,
    required this.title,
    required this.link,
    required this.unread,
    required this.discussionsUpdateTime,
    this.courseId});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'link': link,
      'unread': unread,
      'discussionsUpdateTime': discussionsUpdateTime,
      'courseId': courseId
    };
  }
  factory Forum.fromMap(Map<String, dynamic> map) => new Forum(
    id: map['id'],
    title: map['title'],
    link: map['link'],
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
  final String link;
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
    required this.link,
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
      'link': link,
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
    link: map['link'],
    postsUpdateTime: map['postsUpdateTime'],
    forumId: map['forumId']
  );
}

class Post {
  final int? id;
  final String link;
  final String dateTime;
  final String author;
  final String title;
  final String content;
  final int? discussionId;

  Post({
    this.id,
    required this.link,
    required this.dateTime,
    required this.author,
    required this.title,
    required this.content,
    this.discussionId
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'link': link,
      'dateTime': dateTime,
      'author': author,
      'title': title,
      'content': content,
      'discussionId': discussionId
    };
  }
  factory Post.fromMap(Map<String, dynamic> map) => new Post(
    id: map['id'],
    link: map['link'],
    dateTime: map['dateTime'],
    author: map['author'],
    title: map['title'],
    content: map['content'],
    discussionId: map['discussionId']
  );
}

class Event {
  final int? id;
  final String link;
  final String title;
  final String dateTime;
  final String dateTimeParsed;
  final String webex;
  final int notificationId;
  final int? userId;

  Event({
    this.id,
    required this.link,
    required this.title,
    required this.dateTime,
    required this.dateTimeParsed,
    required this.webex,
    required this.notificationId,
    this.userId
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'link': link,
      'title': title,
      'dateTime': dateTime,
      'dateTimeParsed': dateTimeParsed,
      'webex': webex,
      'notificationId': notificationId,
      'userId': userId
    };
  }
  factory Event.fromMap(Map<String, dynamic> map) => new Event(
    id: map['id'],
    link: map['link'],
    title: map['title'],
    dateTime: map['dateTime'],
    dateTimeParsed: map['dateTimeParsed'],
    webex: map['webex'],
    notificationId: map['notificationId'],
    userId: map['userId']
  );
}

class Assign {
  final int? id;
  final String title;
  final String grade;
  final String link;
  final int? courseId;


  Assign({
    this.id,
    required this.title,
    required this.grade,
    required this.link,
    this.courseId
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'grade': grade,
      'link': link,
      'courseId': courseId
    };
  }
  factory Assign.fromMap(Map<String, dynamic> map) => new Assign(
    id: map['id'],
    title: map['title'],
    grade: map['grade'],
    link: map['link'],
    courseId: map['courseId']
  );
}
