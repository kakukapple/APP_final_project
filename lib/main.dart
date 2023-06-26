import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:final_project/firebase_options.dart';

class Todo {
  String? id;
  String? job;
  String? details;
  bool? done;

  Todo({this.id,
    this.job,
    this.details,
    this.done});

  Todo.fromDocumentSnapshot({DocumentSnapshot? documentSnapshot}) {
    if (documentSnapshot!.data()!=null) {
      id=documentSnapshot.id;
      job=(documentSnapshot.data() as Map<String, dynamic>)['job'] as String;
      details=(documentSnapshot.data() as Map<String, dynamic>)['details'] as String;
      done=(documentSnapshot.data() as Map<String, dynamic>)['done'] as bool;
    }
    else {
      id='';
      job='';
      details='';
      done=false;
    }
  }
}

class Auth {
  final FirebaseAuth auth;

  Auth({required this.auth});

  Stream<User?> get user => auth.authStateChanges();

  Future<String?> createAccount({String? email, String? password}) async {
    try {
      await auth.createUserWithEmailAndPassword(
          email: email!.trim(), password: password!.trim());
      return 'Success';
    }
    on FirebaseAuthException catch(e) {
      return e.message;
    }
    catch (e) {
      rethrow;
    }
  }

  Future<String?> signIn({String? email, String? password}) async {
    try {
      await auth.signInWithEmailAndPassword(
          email: email!.trim(), password: password!.trim());
      return 'Success';
    }
    on FirebaseAuthException catch(e) {
      return e.message;
    }
    catch (e) {
      rethrow;
    }
  }

  Future<String?> signOut() async {
    try {
      await auth.signOut();
      return 'Success';
    }
    on FirebaseAuthException catch(e) {
      return e.message;
    }
    catch (e) {
      rethrow;
    }
  }
}

class Database {
  final FirebaseFirestore firestore;

  Database({required this.firestore});

  Stream<List<Todo>> streamTodos({required String uid}) {
    try {
      return firestore
          .collection('todos')
          .doc(uid)
          .collection('todos')
          .where('done', isEqualTo: false)
          .snapshots()
          .map((QuerySnapshot q) {
        final List<Todo> retVal=<Todo>[];
        q.docs.forEach((doc) {
          retVal.add(Todo.fromDocumentSnapshot(documentSnapshot: doc));
        });
        return retVal;
      });
    }
    catch(e) {
      rethrow;
    }
  }
//儲存資料到資料庫
  Future<void> addTodo({String? uid, String? job, String? details}) async {
    try {
      firestore.collection('todos')
          .doc(uid)
          .collection('todos')
          .doc()
          .set({'job': job,
        'details': details,
        'done': false});
    }
    catch (e) {
      rethrow;
    }
  }

  Future<void> updateTodo({String? uid, String? id}) async {
    try {
      firestore.collection('todos')
          .doc(uid)
          .collection('todos')
          .doc(id)
          .update({//'job': job,
        //'details': details,
        'done': true});
    }
    catch (e) {
      rethrow;
    }
  }

  Future<void> deleteTodo({String? uid, String? id}) async {
    try {
      firestore.collection('todos')
          .doc(uid)
          .collection('todos')
          .doc(id)
          .delete();
    }
    catch (e) {
      rethrow;
    }
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();//options: DefaultFirebaseOptions.currentPlatform);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: FutureBuilder(
          future: Firebase.initializeApp(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(
                  child: Text('Error'),
                ),
              );
            }
            if (snapshot.connectionState==ConnectionState.done)
              return First();
            return Scaffold(
              body: Center(
                child: Text('Loading...'),
              ),
            );

          }),
    );
  }
}

class First extends StatefulWidget {
  const First({Key? key}) : super(key: key);
  @override
  State<First> createState() => _FirstState();
}

class _FirstState extends State<First> {
  final FirebaseAuth _auth=FirebaseAuth.instance;
  final FirebaseFirestore _firestore=FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: Auth(auth: _auth).user,
        builder: (context, snapshot) {
          if (snapshot.connectionState==ConnectionState.active) {
            if (snapshot.data?.uid==null)
              return Login(auth: _auth, firestore: _firestore);
            else
              return Home(auth: _auth, firestore: _firestore);
          }
          else {
            return Scaffold(
              body: Center(
                child: Text('Loading...'),
              ),
            );
          }
        });
  }
}

class Login extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const Login({Key? key, required this.auth, required this.firestore}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController=TextEditingController();
  final passwordController=TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Builder(builder: (context) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                //輸入Email
                TextFormField(
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(hintText: 'Email'),
                  controller: emailController,
                ),
                //輸入密碼
                TextFormField(
                  textAlign: TextAlign.center,
                  decoration: InputDecoration(hintText: 'Password'),
                  controller: passwordController,
                ),
                SizedBox(height: 20,),
                //登入
                ElevatedButton(
                    onPressed: () async {
                      final String? retVal=await Auth(auth: widget.auth).signIn(email: emailController.text,
                          password: passwordController.text);
                      if (retVal=='Success') {
                        emailController.clear();
                        passwordController.clear();
                      }
                      else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(retVal!)));
                      }
                    },
                    child: Text('Sign In')),
                //註冊
                ElevatedButton(
                    onPressed: () async {
                      final String? retVal=await Auth(auth: widget.auth).createAccount(email: emailController.text,
                          password: passwordController.text);
                      if (retVal=='Success') {
                        emailController.clear();
                        passwordController.clear();
                      }
                      else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(retVal!)));
                      }
                    },
                    child: Text('Create Account')),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class Home extends StatefulWidget {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;

  const Home({Key? key, required this.auth, required this.firestore}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final todoController1=TextEditingController();
  final todoController2=TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Todo App v1'),
        actions: [
          IconButton(
              onPressed: () {
                Auth(auth: widget.auth).signOut();
              },
              icon: Icon(Icons.exit_to_app)),
        ],),
      body: Column(
        children: [
          SizedBox(height: 20),
          Text('Add Todo Here', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          //*日期
          Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Row(children: [
                Expanded(child: TextFormField(controller: todoController1,)),
                IconButton(icon: Icon(Icons.add),
                    onPressed: () {
                      if (todoController1.text.isNotEmpty) {
                        setState(() {
                          //按下加號按鈕後跳到addTodo
                          Database(firestore: widget.firestore).addTodo(uid: widget.auth.currentUser!.uid,
                              job: todoController1.text.trim(),
                              details: todoController2.text.trim());
                          todoController1.clear();
                          todoController2.clear();
                        });
                      }

                    }),
              ],),
            ),
          ),
          //*品項
          Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Row(children: [
                Expanded(child: TextFormField(controller: todoController2,
                                              keyboardType: TextInputType.number,
                                              inputFormatters: [
                                                FilteringTextInputFormatter.digitsOnly,
                                              ],)),
                IconButton(icon: Icon(Icons.blinds_sharp),
                    onPressed: () {}),
              ],),
            ),
          ),
          //*金額(限制只能輸入數字)
          Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Row(children: [
                Expanded(child: TextFormField(controller: todoController2,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],)),
                IconButton(icon: Icon(Icons.blinds_sharp),
                    onPressed: () {}),
              ],),
            ),
          ),
          //*備註
          Card(
            margin: EdgeInsets.all(20),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Row(children: [
                Expanded(child: TextFormField(controller: todoController2,)),
                IconButton(icon: Icon(Icons.blinds_sharp),
                    onPressed: () {}),
              ],),
            ),
          ),
          SizedBox(height: 20),
          Text('Your Todos', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          //顯示未完成的工作
          Expanded(child: StreamBuilder(
            stream: widget.firestore.collection('todos')
                .doc(widget.auth.currentUser!.uid).collection('todos')
                .where('done', isEqualTo: false)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState==ConnectionState.active) {
                if (snapshot.data!.docs.isEmpty) {
                  return Center(child:
                  Text("You don't have any unfinished jobs"),
                  );
                }
                final List<Todo> retVal=<Todo>[];
                snapshot.data!.docs.forEach((doc) {
                  retVal.add(Todo.fromDocumentSnapshot(documentSnapshot: doc));
                });
                return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      return TodoCard(
                        firestore: widget.firestore,
                        uid: widget.auth.currentUser!.uid,
                        todo: retVal[index],
                      );
                    });
              }
              else {
                return Center(
                  child: Text('Loading...'),
                );
              }
            },
          ),),
        ],
      ),
    );
  }
}

class TodoCard extends StatefulWidget {
  final FirebaseFirestore firestore;
  final String uid;
  final Todo todo;

  const TodoCard({Key? key,
    required this.firestore,
    required this.uid,
    required this.todo}) : super(key: key);

  @override
  State<TodoCard> createState() => _TodoCardState();
}

class _TodoCardState extends State<TodoCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: ListTile(
          title: Text(widget.todo.job!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),),
          subtitle: Text(widget.todo.details!, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),),
          trailing: IconButton(icon: Icon(Icons.update),
            onPressed: () {
              Database(firestore: widget.firestore).updateTodo(uid: widget.uid,
                  id: widget.todo.id);
              setState(() {});
            },),
        ),
      ),
    );
  }
}