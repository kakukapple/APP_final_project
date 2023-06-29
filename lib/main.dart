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
  String? amount;
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
      amount=(documentSnapshot.data() as Map<String, dynamic>)['amount'] as String;
      details=(documentSnapshot.data() as Map<String, dynamic>)['details'] as String;
    }
    else {
      id='';
      date='';
      name='';
      amount='';
      details='';
    }
  }

  // 計算結餘
  int calculateBalance() {
    // 假設已支出的金額為 spentAmount，amount 為款項金額（String?）
    int spentAmount = 0;
    int? parsedAmount = int.tryParse(amount ?? '');
    int actualAmount = parsedAmount ?? 55;  // 預設款項金額為 55

    if (amount?.isNotEmpty == true && amount?[0] != '+') {
      actualAmount = -actualAmount;
    }

    return actualAmount - spentAmount;
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
  Future<void> addItem({String? uid, String? date, String? name, String? amount, String? details}) async {
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
  Future<void> updateItem({String? uid, String? id, String? date, String? name, String? amount, String? details}) async {
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
  final itemController1 = TextEditingController();
  final itemController2 = TextEditingController();
  final itemController3 = TextEditingController();
  final itemController4 = TextEditingController();

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
                        controller: itemController1,
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
                      onPressed: () {},
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
                            controller: itemController2,
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

            //*金額(只能輸入數字及+-)
            Card(
              margin: EdgeInsets.all(20),
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: itemController3,
                        decoration: InputDecoration(
                          labelText: '金額 (若為收入請在最前面打一個+)',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9+-]')),
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
                            controller: itemController4,
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
            ElevatedButton(
              onPressed: () {
                if (itemController1.text.isNotEmpty && itemController2.text.isNotEmpty && itemController3.text.isNotEmpty) {
                  setState(() {
                    //按下新增按鈕後跳到addItem
                    Database(firestore: widget.firestore).addItem(
                      uid: widget.auth.currentUser!.uid,
                      date: itemController1.text.trim(),
                      name: itemController2.text.trim(),
                      amount: itemController3.text.trim(),
                      details: itemController4.text.trim(),
                    );
                    itemController1.clear();
                    itemController2.clear();
                    itemController3.clear();
                    itemController4.clear();
                  });
                }
                else {
                    // 除了備註以外的欄位沒填就跳出訊息
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('請填寫【備註】以外的欄位'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                }
              },
              child: Text('新增'),
            ),

            SizedBox(height: 20),
            Text('目前款項', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
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
                      child: Text("您目前尚未有任何款項"),
                    );
                  }
                  final List<Item> retVal = <Item>[];
                  snapshot.data!.docs.forEach((doc) {
                    retVal.add(Item.fromDocumentSnapshot(documentSnapshot: doc));
                  });
                  //計算結餘
                  int totalBalance = 0;
                  retVal.forEach((item) {
                    totalBalance += item.calculateBalance();
                  });
                  return Column(
                    children: [
                      ListView.builder(
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
                      ),
                      SizedBox(height: 20),
                      Text('目前結餘: $totalBalance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  );
                } else {
                  return Center(
                    child: Text('Loading...'),
                  );
                }
              },
            ),
            SizedBox(height: 20),
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

  @override
  Widget build(BuildContext context) {
    final int balance = item.calculateBalance();
    // ...

    return ListTile(
      // ...
      trailing: Text(
        '結餘: $balance',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ItemCardState extends State<ItemCard> {
  TextEditingController dateController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController amountController = TextEditingController();
  TextEditingController detailsController = TextEditingController();
  String str = '支出';

  @override
  void initState() {
    super.initState();
    // Set the initial values of the controllers
    dateController.text = widget.item.date!;
    nameController.text = widget.item.name!;
    amountController.text = widget.item.amount!.replaceAll(RegExp(r'[^0-9]'), '');
    detailsController.text = widget.item.details!;
    if (widget.item.amount!.isNotEmpty) {
      if(widget.item.amount!.substring(0, 1) == '+'){
        str = "收入";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Padding(
        padding: EdgeInsets.all(10),
        child: ListTile(
          title: Text(
            dateController.text + ' ' + str,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              Text(
                '品項: ' + nameController.text,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '金額: ' + amountController.text,
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                '備註: ' + detailsController.text,
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
                  onPressed: _showDeleteConfirmationDialog,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('確認刪除'),
          content: Text('您確定要刪除此項目嗎？'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // 关闭对话框
              },
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                // 删除操作
                Database(firestore: widget.firestore).deleteItem(
                  uid: widget.uid,
                  id: widget.item.id,
                );
                setState(() {
                  // 更新UI
                });
                Navigator.of(context).pop(); // 關閉對話框
              },
              child: Text('刪除'),
            ),
          ],
        );
      },
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
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9+-]')),
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
    String updatedAmount = amountController.text.trim();
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

