import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'main.dart'; // تأكد من استيراد ProfilePage

class QRLoginPage extends StatefulWidget {
  @override
  State<QRLoginPage> createState() => _QRLoginPageState();
}

class _QRLoginPageState extends State<QRLoginPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool scanned = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  void _requestCameraPermission() async {
    var status = await Permission.camera.status;
    if (!status.isGranted) {
      status = await Permission.camera.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("الكاميرا مطلوبة لمسح QR Code")));
      }
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;

    controller.scannedDataStream.listen((scanData) async {
      if (scanned) return;
      scanned = true;

      try {
        final data = Map<String, dynamic>.from(
          scanData.code != null
              ? (scanData.code!.isNotEmpty ? jsonDecode(scanData.code!) : {})
              : {},
        );

        final username = data['username'];
        final token = data['token'];

        if (username == null || token == null) {
          _showError("QR Code غير صالح");
          return;
        }

        final doc = await FirebaseFirestore.instance
            .collection('students')
            .doc(username)
            .get();

        if (!doc.exists || doc['token'] != token) {
          _showError("اسم المستخدم أو QR Token غير صحيح");
          return;
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                ProfilePage(studentDocId: username, studentData: doc.data()!),
          ),
        );
      } catch (e) {
        _showError("حدث خطأ أثناء المسح: $e");
      }
    });
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    scanned = false;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("مسح QR Code")),
      body: QRView(key: qrKey, onQRViewCreated: _onQRViewCreated),
    );
  }
}
