import 'package:daralmethak/qrcode.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dar Al Methaq',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
    );
  }
}

// ----------------- Login Page -----------------
class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? error;

  void login() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text.trim();

    final doc = await FirebaseFirestore.instance
        .collection('students')
        .doc(username)
        .get();

    if (!doc.exists) {
      setState(() => error = "اسم المستخدم غير موجود");
      return;
    }

    // التحقق من كلمة المرور فقط إذا كانت مخزنة
    final studentData = doc.data()!;
    if (studentData.containsKey('password') && studentData['password'] != password) {
      setState(() => error = "كلمة المرور غير صحيحة");
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ProfilePage(studentDocId: username, studentData: studentData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("تسجيل الدخول")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _usernameController,
              decoration: InputDecoration(labelText: "اسم المستخدم"),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: "كلمة المرور"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: Text("دخول")),
            if (error != null) SizedBox(height: 20),
            if (error != null)
              Text(error!, style: TextStyle(color: Colors.red)),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => QRLoginPage()),
                );
              },
              child: Text("تسجيل الدخول بالـ QR"),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- Profile Page -----------------
class ProfilePage extends StatelessWidget {
  final String studentDocId;
  final Map<String, dynamic> studentData;

  ProfilePage({required this.studentDocId, required this.studentData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("ملف الطالب")),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("اسم المستخدم: $studentDocId", style: TextStyle(fontSize: 18)),
            Text(
              "رقم الهاتف: ${studentData['phone'] ?? 'غير متوفر'}",
              style: TextStyle(fontSize: 18),
            ),
            Text(
              "نوع الاشتراك: ${studentData['subscription_type'] ?? 'غير محدد'}",
              style: TextStyle(fontSize: 18),
            ),
            Text(
              "Token: ${studentData['token'] ?? 'غير متوفر'}",
              style: TextStyle(fontSize: 16, color: Colors.blueAccent),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NotesPage(studentDocId: studentDocId),
                  ),
                );
              },
              child: Text("عرض الملاحظات"),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- Notes Page -----------------
class NotesPage extends StatelessWidget {
  final String studentDocId;

  NotesPage({required this.studentDocId});

  @override
  Widget build(BuildContext context) {
    final notesCollection = FirebaseFirestore.instance
        .collection('students')
        .doc(studentDocId)
        .collection('notes')
        .orderBy('date', descending: true);

    return Scaffold(
      appBar: AppBar(title: Text("ملاحظات الطالب")),
      body: StreamBuilder<QuerySnapshot>(
        stream: notesCollection.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return Center(child: CircularProgressIndicator());

          final notes = snapshot.data!.docs;

          if (notes.isEmpty) {
            return Center(child: Text("لا توجد ملاحظات حتى الآن"));
          }

          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              final date = note['date'] ?? '';
              final teacher = note['teacher'] ?? '';
              final content = note['content'] ?? '';

              return Card(
                margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(content),
                  subtitle: Text("المعلم: $teacher\nالتاريخ: $date"),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
