import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

import 'auth_service.dart';

class QRScanner extends StatefulWidget {
  const QRScanner({super.key});

  @override
  State<StatefulWidget> createState() => QRScannerState();
}

class QRScannerState extends State<QRScanner> {
  static Barcode? result;
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');

  void _onQRViewCreated(QRViewController controller) {
    setState(() => this.controller = controller);
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
      });
      if (result != null) {
        controller.pauseCamera();
        recordAttendance();
      }
    });
  }

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(flex: 4, child: QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
              borderColor: Colors.orange,
              borderRadius: 10,
              borderLength: 30,
              borderWidth: 10,
              cutOutSize: 250,
            ),
          ),
          ),

          Expanded(
            flex: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  // if (result != null)
                  //   Text(
                  //       'Barcode Type: ${describeEnum(result!.format)}   Data: ${result!.code}')
                  // else
                  //   const Text('Scan the QR Code on the tag'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.toggleFlash();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getFlashStatus(),
                              builder: (context, snapshot) {
                                if (snapshot.data != null) {
                                  return Text('Turn flash ${snapshot.data! ? 'off' : 'on'}');
                                } else {
                                  return const Text('loading');
                                }
                                // return Text('Turn flash ${snapshot.data! ? 'off' : 'on'}');
                              },
                            )),
                      ),
                      Container(
                        margin: const EdgeInsets.all(8),
                        child: ElevatedButton(
                            onPressed: () async {
                              await controller?.flipCamera();
                              setState(() {});
                            },
                            child: FutureBuilder(
                              future: controller?.getCameraInfo(),
                              builder: (context, snapshot) {
                                if (snapshot.data != null) {
                                  if (snapshot.data! == CameraFacing.back) {
                                    return const Text('Switch to front camera');
                                  } else {
                                    return const Text('Switch to back camera');
                                  }
                                  // return Text(
                                  //     'Switch from ${describeEnum(snapshot.data!)} camera');
                                } else {
                                  return const Text('loading');
                                }
                              },
                            )),
                      )
                    ],
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  recordAttendance() async {
    final authController = Get.find<AuthController>();
    final studentId = authController.getCurrentUser()?.uid;
    final qrResult = result!.code;
    final subjectId = qrResult?.split('+')[0];
    final date = qrResult?.split('+')[1];
    // check if student is already marked present
    // check if the same day present has been marked already
    await FirebaseFirestore.instance.collection('attendance').where('studentId', isEqualTo: studentId).where('subjectId', isEqualTo: subjectId).where('date', isEqualTo: date).get().then((QuerySnapshot querySnapshot) {
      if (querySnapshot.docs.isNotEmpty) {
        Fluttertoast.showToast(
          msg: 'Attendance already marked for today',
        );
        Get.back();
        return;
      } else {
        final attendance = {
          'studentId': studentId,
          'subjectId': subjectId,
          'date': date,
          'timestamp': DateTime.now(),
        };
        FirebaseFirestore.instance.collection('attendance').add(attendance);
        Fluttertoast.showToast(
          msg: 'Attendance recorded',
        );
        Get.back();
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}