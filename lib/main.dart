import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:date_time_picker/date_time_picker.dart';
import 'package:final_project/firebase_options.dart';

class Item {
  String? id;
  String? date;
  String? name;
  int? amount;
  String? details;

  Item({this.id,
    this.date,
    this.name,
    this.amount,
    this.details,
  });

  Item.fromDocumentSnapshot({DocumentSnapshot? documentSnapshot}) {
    if (documentSnapshot!.data()!=null) {
      id=documentSnapshot.id;
      date=(documentSnapshot.data() as Map<String, dynamic>)['date'] as String;
      name=(documentSnapshot.data() as Map<String, dynamic>)['name'] as String;
      amount=(documentSnapshot.data() as Map<String, dynamic>)['amount'] as int;
      details=(documentSnapshot.data() as Map<String, dynamic>)['details'] as String;
    }
    else {
      id='';
      date='';
      name='';
      amount=0;
      details='';
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
//登入
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
//登出
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

  Stream<List<Item>> streamItem({required String uid}) {
    try {
      return firestore
          .collection('items')
          .doc(uid)
          .collection('items')
          .snapshots()
          .map((QuerySnapshot q) {
        final List<Item> retVal=<Item>[];
        q.docs.forEach((doc) {
          retVal.add(Item.fromDocumentSnapshot(documentSnapshot: doc));
        });
        return retVal;
      });
    }
    catch(e) {
      rethrow;
    }
  }
//新增資料到資料庫
  Future<void> addTodo({String? uid, String? date, String? name, int? amount, String? details}) async {
    try {
      firestore.collection('items')
          .doc(uid)
          .collection('items')
          .doc()
          .set({'date': date,
        'name': name,
        'amount': amount,
        'details': details});
    }
    catch (e) {
      rethrow;
    }
  }
//更新資料到資料庫
  Future<void> updateItem({String? uid, String? id, String? date, String? name, int? amount, String? details}) async {
    try {
      firestore.collection('items')
          .doc(uid)
          .collection('items')
          .doc(id)
          .update({'date': date,
        'name': name,
        'amount': amount,
        'details': details,
        });
    }
    catch (e) {
      rethrow;
    }
  }
//刪除資料
  Future<void> deleteItem({String? uid, String? id}) async {
    try {
      firestore.collection('items')
          .doc(uid)
          .collection('items')
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
  final todoController1 = TextEditingController();
  final todoController2 = TextEditingController();
  final todoController3 = TextEditingController();
  final todoController4 = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('簡易記帳本 v1'),
        actions: [
          IconButton(
            onPressed: () {
              Auth(auth: widget.auth).signOut();
            },
            icon: Icon(Icons.exit_to_app),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 20),
            Text('新增帳款', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            //*日期
            Card(
              margin: EdgeInsets.all(20),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: DateTimePicker(
                        controller: todoController1,
                        decoration: InputDecoration(
                          labelText: '日期',
                        ),
                        type: DateTimePickerType.date,
                        dateMask: 'yyyy/MM/dd',
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        icon: Icon(Icons.calendar_today),
                        dateLabelText: '選擇日期',
                        onChanged: (val) => print(val),
                        validator: (val) {
                          // 添加邏輯驗證（可選）
                          if (val == null || val.isEmpty) {
                            return '請選擇日期';
                          }
                          return null;
                        },
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.calendar_today),
                      onPressed: () {
                        // 按下按鈕後的處理
                        if (todoController1.text.isNotEmpty) {
                          setState(() {
                            //按下加號按鈕後跳到addTodo
                            Database(firestore: widget.firestore).addTodo(
                              uid: widget.auth.currentUser!.uid,
                              date: todoController1.text.trim(),
                              name: todoController2.text.trim(),
                              amount: int.tryParse(todoController3.text.trim()),
                              details: todoController4.text.trim(),
                            );
                            todoController1.clear();
                            todoController2.clear();
                            todoController3.clear();
                            todoController4.clear();
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),

            //*品項
            Card(
              margin: EdgeInsets.all(20),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: todoController2,
                            decoration: InputDecoration(
                              labelText: '品項',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.local_mall_outlined),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            //*金額
            Card(
              margin: EdgeInsets.all(20),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: todoController3,
                        decoration: InputDecoration(
                          labelText: '金額',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.local_atm),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),

            //*備註
            Card(
              margin: EdgeInsets.all(20),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: todoController4,
                            decoration: InputDecoration(
                              labelText: '備註',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit_note),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Text('目前帳款', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            //顯示未完成的工作
            StreamBuilder(
              stream: widget.firestore
                  .collection('items')
                  .doc(widget.auth.currentUser!.uid)
                  .collection('items')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.active) {
                  if (snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Text("您目前尚未有任何帳款"),
                    );
                  }
                  final List<Item> retVal = <Item>[];
                  snapshot.data!.docs.forEach((doc) {
                    retVal.add(Item.fromDocumentSnapshot(documentSnapshot: doc));
                  });
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      return ItemCard(
                        firestore: widget.firestore,
                        uid: widget.auth.currentUser!.uid,
                        item: retVal[index],
                      );
                    },
                  );
                } else {
                  return Center(
                    child: Text('Loading...'),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}


class ItemCard extends StatefulWidget {
  final FirebaseFirestore firestore;
  final String uid;
  final Item item;

  const ItemCard({Key? key,
    required this.firestore,
    required this.uid,
    required this.item}) : super(key: key);

  @override
  State<ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<ItemCard> {
  TextEditingController dateController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController detailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Set the initial values of the controllers
    dateController.text = widget.item.date!;
    nameController.text = widget.item.name!;
    amountController.text = widget.item.amount.toString();
    detailsController.text = widget.item.details!;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: ListTile(
          title: Text(
            widget.item.date!,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text(
                '品項: ' + widget.item.name!,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '金額: ' + widget.item.amount.toString(),
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '備註: ' + widget.item.details!,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditDialog(context);
                  },
                ),
              ),
              Align(
                alignment: Alignment.center,
                child: IconButton(
                  icon: Icon(Icons.delete_outline),
                  onPressed: () {
                    // 刪除
                    Database(firestore: widget.firestore).deleteItem(
                      uid: widget.uid,
                      id: widget.item.id,
                    );
                    setState(() {
                      // 更新UI
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('編輯'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                DateTimePicker(
                  controller: dateController,
                  decoration: InputDecoration(labelText: '日期'),
                  type: DateTimePickerType.date,
                  dateMask: 'yyyy/MM/dd',
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                  onChanged: (val) {
                    setState(() {
                      dateController.text = val ?? '';
                    });
                  },
                ),
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: '品項'),
                ),
                TextField(
                  controller: amountController,
                  decoration: InputDecoration(labelText: '金額'),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                ),
                TextField(
                  controller: detailsController,
                  decoration: InputDecoration(labelText: '備註'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                _updateItem();
                Navigator.of(context).pop(); // Close the dialog
              },
              child: Text('儲存'),
            ),
          ],
        );
      },
    );
  }


  void _updateItem() {
    String updatedDate = dateController.text.trim();
    String updatedName = nameController.text.trim();
    int updatedAmount = int.tryParse(amountController.text.trim()) ?? 0;
    String updatedDetails = detailsController.text.trim();

    // Update the item in the database using the provided Firestore instance
    Database(firestore: widget.firestore).updateItem(
      uid: widget.uid,
      id: widget.item.id,
      date: updatedDate,
      name: updatedName,
      amount: updatedAmount,
      details: updatedDetails,
    );

    setState(() {
      // Update the widget with the new values
      widget.item.date = updatedDate;
      widget.item.name = updatedName;
      widget.item.amount = updatedAmount;
      widget.item.details = updatedDetails;
    });
  }
}

