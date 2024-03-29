import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gio_app/Pages/LoadingPage.dart';
import 'package:gio_app/Services/HttpServices.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Services/DatabaseServices.dart';
import '../Models.dart';
import '../main.dart';
import 'HomePage.dart';
import 'package:html/dom.dart' show Document;


class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  String username='';
  String password='';
  String studentName='';
  String authResultMessage='';
  var userId;
  bool loading = false;
  bool passwordObscure=true;
  bool userExists=false;

  var serverList=['courses.eap.gr', 'study.eap.gr'];
  bool showSelectServerMessage=false;

  final _formKey=GlobalKey<FormState>();

  Future<void> chekcIfUserExists() async {
    var storage=FlutterSecureStorage();
    if (await storage.read(key: 'dbpassGenerated') != 'yes') {
      print('dbpass not generated');
      await storage.write(key: 'dbpass', value: username+password);
      await storage.write(key: 'dbpassGenerated', value: 'yes');
    }
    var db = await DatabaseServices.instance.database;
    var userExistsDB = await db.query('User', columns: ['id'],
        where: 'username=? AND password=?',
        whereArgs: [username,password]
    );
    if (userExistsDB.isNotEmpty) {
      userId=userExistsDB[0]['id'];
      userExists=true;
    }
  }

  Future<void> loginProcedure(BuildContext context) async {
    Document? html;
    setState(() {
      loading=true;
    });

    // ......call httpLogin and return auth result and html of study.gr/my
    var study=HttpServices();
    var loginResult = await study.loginStudy(username, password);
    print('login result: '+loginResult);
    if (loginResult=='auth error'){
      setState(() {
        authResultMessage = 'αποτυχία σύνδεσης';
        print(authResultMessage);
        loading = false;
      });
    } else if (loginResult=='no connection') {
      if (userExists){ // update username, password and set notification settings
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', userId);
        activeUserId=userId;
        var db=DatabaseServices.instance;
        var user = await db.getUser(id: activeUserId);
        await db.updateUserAndNotifSettings(user); //TODO if no connection, why update user?
        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => HomePage(
                html: html)));
      } else {
        setState(() {
          authResultMessage = 'εκτός σύνδεσης';
          loading = false;
        });
      }
    } else {
      html = await study.httpGetHtml('https://$server/my/', moodleSession: loginResult);

      if (html!=null) {
        //...... get student name, messages counter, create User, update DB, store activeUserId and push HomePage(html)
        String studentName='';
        String messageCounter='0';
        if (html.getElementsByClassName('usertext mr-1').isNotEmpty) {
          studentName = html.getElementsByClassName('usertext mr-1')[0].text;
          if (html.getElementsByClassName('count-container hidden').isNotEmpty) {
            messageCounter=html.getElementsByClassName('count-container hidden')[0].text;
          }
        }
        var user=User(
          username: username,
          password: password,
          studentName: studentName,
          eventNotification: 1,
          postNotification: 8,
          messageNotification: 8,
          gradeNotification: 1,
          eventsUpdateTime: '',
          messengerUpdateTime: ''
        );

        var db=DatabaseServices.instance;
        userId = await db.updateUserAndNotifSettings(user);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setInt('userId', userId);
        activeUserId=userId;

        Navigator.pushReplacement(context, MaterialPageRoute(
            builder: (context) => HomePage(html: html, messageCounter: messageCounter)
        ));
      }
    }
  }

  Future<bool> serviceTerms(BuildContext loginPageContext) async {
    bool agree=true;
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          AlertDialog(
            title: Text( 'Όροι χρήσης της εφαρμογής'),
            content: Text('Επιλέγοντας \"Συμφωνώ\", δίνεται στην εφαρμογή η '
                'δυνατότητα να διατηρεί στη συσκευή τα δεδομένα του χρήστη '
                'συμπεριλαμβανομένων των στοιχείων μητρώου: όνομα χρήστη και '
                'κωδικός πρόσβασης, που απαιτούνται για τη '
                'σύνδεση στους ψηφιακούς χώρους εκπαίδευσης του ΕΑΠ. Τα δεδομένα '
                'αυτά παραμένουν μόνο στη συσκευή και σε αποκρυπτογραφημένη μορφή '
                'έτσι, ώστε να είναι ασφαλής η χρήση τους. '
                'Στις ρυθμίσεις της εφαρμογής δίνεται η δυνατότητα '
                'της αποσύνδεσης του χρήστη και της διαγραφής των δεδομένων του '
                'από τη συσκεύη.',
                style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 18
                )
            ),
            actions: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    child: Text('Συμφωνώ',
                        style: TextStyle(
                            color: Colors.grey[800],
                            fontSize: 20
                        )
                    ),
                    onPressed: () async {
                      Navigator.pop(context);
                      await loginProcedure(loginPageContext);
                    },
                  ),
                  TextButton(
                      child: Text('Διαφωνώ',
                          style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 20
                          )
                      ),
                      onPressed: () {
                        agree=false;
                        Navigator.pop(context);
                      }
                  ),
                ],
              ),
            ],
          ),
    );
    return agree;
  }

  Future<dynamic> aboutApp(BuildContext loginPageContext) async {
    showDialog(
      context: context,
      builder: (BuildContext context) =>
          AlertDialog(
            content: Text('Η εφαρμογή αυτή έχει στόχο την ενημέρωση των '
                'σπουδαστών του Ελληνικού Ανοικτού Πανεπιστημίου (ΕΑΠ) σχετικά '
                'με τα μαθήματα που παρακολουθούν και πιο συγκεκριμένα:\n τα '
                'επικείμενα γεγονότα (υποβολή εργασιών, ομαδικές '
                'συμβουλευτικές συναντήσεις), τις αναρτήσεις στις ομάδες συζητήσεων '
                '(forums), τα μηνύματα (επισκόπηση μηνυμάτων, αποστολή νέων)'
                ' και τη βαθμολογία των εργασιών και των εξετάσεων.\n '
                'Η ανάπτυξη της εφαρμογής έγινε στα πλαίσια διπλωματικής εργασιάς '
                'και δεν αποτελεί επίσιμη υλοποίηση του ΕΑΠ.',
                style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 18
                )
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK',
                    style: TextStyle(
                        color: Colors.grey[800],
                        fontSize: 20
                    )
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return loading? Loading() : Scaffold(
      backgroundColor: Colors.grey[200],
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: 40,
              ),
              IconButton(
                  onPressed: () {aboutApp(context);},
                  icon: Icon(Icons.info_outline_rounded,
                    size: 36,
                    color: Color(0xFFA50D70),
                  )
              ),
              SizedBox(height: 20,),
              Image(
                image: AssetImage('assets/openStudyLogo3.png'),
                width: 110,
                height: 110,
              ),
              SizedBox(height: 30),
              Container(
                color: Color(0xFFCF118C),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 6),
                  child: Text(
                      'Είσοδος με στοιχεία μητρώου',
                      style: TextStyle(color: Colors.white,fontSize: 14)
                  ),
                ),
              ),
              SizedBox(height: 40),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    Card(
                      child: TextFormField(
                        decoration: InputDecoration(
                            labelText: '  όνομα χρήστη',
                            floatingLabelStyle: TextStyle(color: Colors.grey[700]),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey)
                            )
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'εισάγετε όνομα χρήστη';
                          } else {
                            return null;
                          }
                        },
                        onChanged: (val) {
                          setState(() {
                            username=val;
                          });
                        },
                      ),
                    ),
                    SizedBox(height: 14),
                    Card(
                        child: TextFormField(
                          obscureText: passwordObscure,
                          decoration: InputDecoration(
                            labelText: '  κωδικός πρόσβασης',
                            floatingLabelStyle: TextStyle(color: Colors.grey[700]),
                            focusedBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.grey)
                            ),
                            suffixIcon: IconButton(
                              color: Colors.grey[600],
                              icon: Icon(
                                passwordObscure
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  passwordObscure = !passwordObscure;
                                });
                              },
                            ),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'εισάγετε κωδικό πρόσβασης';
                            } else {
                              return null;
                            }
                          },
                          onChanged: (val) {
                            setState(() {
                              password=val;
                            });
                          },
                        )
                    ),
                  ],
                ),
              ),
              Container(
                margin: EdgeInsets.fromLTRB(4, 14, 4, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: ExpansionTile(
                  key: ValueKey(server),
                  textColor: Colors.grey[700],
                  initiallyExpanded: false,
                  iconColor: Colors.grey[700],
                  title: Text(
                    showSelectServerMessage
                    ? 'Πρέπει να επιλέξετε ψηφιακό χώρο εκπαίδευσης'
                    : server==''
                      ? 'Επιλέξτε ψηφιακό χώρο εκπαίδευσης'
                      : server,
                    style: TextStyle(
                      color:  showSelectServerMessage
                          ? Colors.red
                          : Colors.grey[700],
                    ),
                  ),
                  children: [
                    ListTile(
                      title: Text(
                          'Με εξαμηνιαία διάρθρωση'
                      ),
                      subtitle: Text(
                        'courses.eap.gr'
                      ),
                      onTap: () {
                        setState(() {
                          server=serverList[0];
                          showSelectServerMessage=false;
                        });
                      },
                    ),
                    ListTile(
                      title: Text(
                          'Με ετήσια διάρθρωση'
                      ),
                      subtitle: Text(
                          'study.eap.gr'
                      ),
                      onTap: () {
                        setState(() {
                          server=serverList[1];
                          showSelectServerMessage=false;
                        });
                      },
                    )
                  ],
                ),
              ),
              Container(
                height: 40,
                child: Center(
                  child: Text(
                      authResultMessage,
                      style: TextStyle(fontSize: 18, color: Colors.red)),
                ),
              ),
              ElevatedButton(
                child: Text('Σύνδεση',
                    style: TextStyle(color: Colors.white,fontSize: 20)
                ),
                style: ButtonStyle(
                    backgroundColor:
                    MaterialStateProperty.resolveWith((states) => Color(0xFFCF118C))
                ),
                onPressed: () async {
                  if (server!='') {
                    showSelectServerMessage=false;
                    if (_formKey.currentState!.validate()) {
                      var prefs = await SharedPreferences.getInstance();
                      await prefs.setString('server', server);
                      await chekcIfUserExists();
                      if (userExists) {
                        print('user exists: $userId');
                        await loginProcedure(context);
                      } else {
                        await serviceTerms(context);
                      }
                    }
                  } else {
                    setState(() {
                      showSelectServerMessage=true;
                    });
                  }

                },
              ),
              SizedBox(height: 40,),
              // TextButton(
              //   child: Text('DB1'),
              //   onPressed: () async {
              //     var db = DatabaseServices.instance;
              //     var udb = await db.getUsers();
              //     var cdb = await db.getCourses();
              //     var edb = await db.getEvents();
              //     var fdb = await db.getForums();
              //     var ddb = await db.getDiscuccions();
              //     var pdb = await db.getPosts();
              //     var gdb = await db.getAssigns();
              //     print('users: '+udb.length.toString());
              //     print(udb.map((e) => e.toMap()));
              //     print('courses: '+cdb.length.toString());
              //     print(cdb.map((e) => e.toMap()));
              //     print('events: '+edb.length.toString());
              //     // edb.forEach((element) {print(element.linkId);});
              //     print(edb.map((e) => e.toMap()));
              //     print('forums: '+fdb.length.toString());
              //     print(fdb.map((e) => e.toMap()));
              //     print('discussions : '+ddb.length.toString());
              //     print(ddb.map((e) => e.toMap()));
              //     print('posts: '+pdb.length.toString());
              //     print(pdb.map((e) => e.toMap()));
              //     print('grades: '+gdb.length.toString());
              //     print(gdb.map((e) => e.toMap()));
              //   },
              // ),
              // TextButton(
              //   child: Text('DB2'),
              //   onPressed: () async {
              //     var db = DatabaseServices.instance;
              //     var udb = await db.getUsers();
              //     var cdb = await db.getCourses();
              //     var edb = await db.getEvents();
              //     var fdb = await db.getForums();
              //     var ddb = await db.getDiscuccions();
              //     var pdb = await db.getPosts();
              //     var gdb = await db.getAssigns();
              //     var contdb= await db.getContacts();
              //     var messdb= await db.getMessages();
              //     print('users: '+udb.length.toString());
              //     print(udb.map((e) => e.toMap()));
              //     print('courses: '+cdb.length.toString());
              //     print(cdb.map((e) => e.toMap()));
              //     print('events: '+edb.length.toString());
              //     // edb.forEach((element) {print(element.linkId);});
              //     print(edb.map((e) => e.toMap()));
              //     print('forums: '+fdb.length.toString());
              //     print(fdb.map((e) => e.toMap()));
              //     print('discussions : '+ddb.length.toString());
              //     print(ddb.map((e) => e.toMap()));
              //     print('posts: '+pdb.length.toString());
              //     print(pdb.map((e) => e.toMap()));
              //     print('grades: '+gdb.length.toString());
              //     print(gdb.map((e) => e.toMap()));
              //     print('contacts: '+contdb.length.toString());
              //     print(contdb.map((e) => e.toMap()));
              //     print('messages: '+messdb.length.toString());
              //     print(messdb.map((e) => e.toMap()));
              //   },
              // ),
              // TextButton(
              //   child: Text('close DB'),
              //   onPressed: () async {
              //     var db = await DatabaseServices.instance.database;
              //     await db.close();
              //
              //   },
              // )
            ],
          ),
        ),
      ),
      // floatingActionButton: IconButton(
      //   icon: Icon(Icons.account_circle),
      //   onPressed: () async {
      //     // Get a location using getDatabasesPath
      //     // var db = await DatabaseServices.instance.database;
      //     // await db.close();
      //
      //     var databasesPath = await getDatabasesPath();
      //     String path = sss.join(databasesPath, 'studyAppDB.db');
      //     // Delete the database
      //     await deleteDatabase(path);
      //     print('db deleted');
      //
      //   },
      // ),
    );
  }
}
