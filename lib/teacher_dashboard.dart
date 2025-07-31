import 'package:attendscan/services/auth_service.dart';
import 'package:attendscan/widgets/colored_safe_area.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'attendance_page.dart';

class TeacherDashboard extends StatefulWidget {
  const TeacherDashboard({super.key});

  @override
  State<TeacherDashboard> createState() => _TeacherDashboardState();
}

class _TeacherDashboardState extends State<TeacherDashboard> {
  final AuthController authController = Get.find();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return ColoredSafeArea(
      child: Scaffold(
          appBar: displayTeacherInfo(),
          body: Padding(
            padding: EdgeInsets.only(left: screenSize.width * 0.05, right: screenSize.width * 0.05, top: screenSize.height * 0.02),
            child: Column(
              children: [
                manageSubjects(screenSize),
                // displayAttendanceOverview(), // Overall attendance records
                // displayUserList(), // List of all users (students and lecturers)
                // displayAttendance(),
              ],
            ),
          )
      ),
    );
  }

  displayTeacherInfo() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Teacher Dashboard'),
          Text(
            authController.getCurrentUser()?.email ?? '',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            authController.logout();
          },
        ),
      ],
    );
  }

  Widget manageSubjects(Size screenSize) {
    final teacherId = authController.getCurrentUser()?.uid;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subjects', style: TextStyle(fontSize: 20)),
          SizedBox(height: screenSize.height * 0.01),
          FutureBuilder(
            future: FirebaseFirestore.instance.collection('subjects').where('teacher', isEqualTo: teacherId) .get(),
            builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.hasError) {
                return const Expanded(child: Text('Something went wrong'));
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(child: Center(child: CircularProgressIndicator()));
              }

              if (snapshot.data!.docs.isEmpty) {
                return const Expanded(child: Center(child: Text('No subjects')));
              }

              return Expanded(
                child: ListView(
                  children: snapshot.data!.docs.map((DocumentSnapshot document) {
                    Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                    return ListTile(
                        title: Text(data['name']),
                        onTap: () {
                          generateAttendanceQRCode(data['name'], document.id);
                        },
                      trailing: ElevatedButton(
                        onPressed: () {
                          Get.to(() => AttendancePage(subjectId: document.id, subjectName: data['name'], isStudent: false));
                        },
                        child: const Text('View Attendance'),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void generateAttendanceQRCode(String subjectName, String subjectId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final dialogSize = MediaQuery.of(context).size;
        final todayDate = DateFormat('dd MMM yyyy').format(DateTime.now());
        final encodedDate = DateFormat('yyyyMMdd').format(DateTime.now());
        final qrCodeData = '$subjectId+$encodedDate';
        return AlertDialog(
          title: Text('$subjectName Attendance QR Code for $todayDate'),
          content: SizedBox(
            height: dialogSize.height * 0.3,
            width: dialogSize.width * 0.5,
            child: QrImageView(
              data: qrCodeData,
              size: 200,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
