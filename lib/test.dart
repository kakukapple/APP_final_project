import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    apiKey: FirebaseConfig.apiKey,
    appId: FirebaseConfig.appId,
    messagingSenderId: FirebaseConfig.messagingSenderId,
    projectId: FirebaseConfig.projectId,
  );
  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '記帳 App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AuthenticationScreen(),
    );
  }
}

class AuthenticationScreen extends StatefulWidget {
  @override
  _AuthenticationScreenState createState() => _AuthenticationScreenState();
}

class _AuthenticationScreenState extends State<AuthenticationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  void _registerUser() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('註冊中...'),
          content: CircularProgressIndicator(),
        );
      },
    );

    _auth
        .createUserWithEmailAndPassword(
      email: _emailController.text,
      password: _passwordController.text,
    )
        .then((userCredential) {
      Navigator.pop(context); // 關閉正在註冊的對話框

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('註冊成功'),
            content: Text('您已成功註冊帳號。'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ExpenseScreen()),
                  );
                },
                child: Text('開始使用'),
              ),
            ],
          );
        },
      );
    })
        .catchError((error) {
      Navigator.pop(context); // 關閉正在註冊的對話框

      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('註冊失敗'),
            content: Text('發生錯誤：${error.toString()}'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('確定'),
              ),
            ],
          );
        },
      );
    });
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('註冊和登入'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: '密碼',
              ),
              obscureText: true,
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _registerUser,
              child: Text('註冊'),
            ),
          ],
        ),
      ),
    );
  }
}

class ExpenseScreen extends StatelessWidget {
  final CollectionReference _expenseCollection =
  FirebaseFirestore.instance.collection('expenses');
  late BuildContext _scaffoldContext; // 新增成员变量

  Future<void> _addExpense(String time, double amount, String item) async {
    try {
      await _expenseCollection.add({
        'time': time,
        'amount': amount,
        'item': item,
      });

      showDialog(
        context: _scaffoldContext, // 使用成员变量 _scaffoldContext
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('记账成功'),
            content: Text('您的财务记录已成功记录。'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('确定'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      showDialog(
        context: _scaffoldContext, // 使用成员变量 _scaffoldContext
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('记账失败'),
            content: Text('发生错误：${e.toString()}'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('确定'),
              ),
            ],
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    _scaffoldContext = context; // 将 context 赋值给成员变量

    return Scaffold(
      appBar: AppBar(
        title: Text('记账'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '输入财务记录',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: '时间',
              ),
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: '金额',
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: '品项',
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () {
                // 获取输入的财务记录数据
                String time = '';
                double amount = 0.0;
                String item = '';

                // 调用 _addExpense 函数新增财务记录
                _addExpense(time, amount, item);
              },
              child: Text('新增财务记录'),
            ),
          ],
        ),
      ),
    );
  }
}
