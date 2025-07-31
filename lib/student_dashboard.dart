import 'package:attendscan/attendance_page.dart';
import 'package:attendscan/services/QRScanner.dart';
import 'package:attendscan/services/auth_service.dart';
import 'package:attendscan/widgets/colored_safe_area.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final AuthController authController = Get.find();
  dynamic teachers = [];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return ColoredSafeArea(
      child: Scaffold(
          appBar: displayStudentInfo(),
          floatingActionButton: scanQR(),
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

  Widget manageSubjects(Size screenSize) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subjects', style: TextStyle(fontSize: 20)),
          SizedBox(height: screenSize.height * 0.01),
          FutureBuilder(
            future: loadTeachersAndSubjects(),
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
                    final teacherEmail = teachers.docs.firstWhere((element) => element.id == data['teacher']).data()['email'];
                    return ListTile(
                      title: Text(data['name']),
                      subtitle: Text(teacherEmail),
                      onTap: () {
                        Get.to(() => AttendancePage(subjectId: document.id, subjectName: data['name'], isStudent: true));
                      }
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

  Future<QuerySnapshot<Map<String, dynamic>>> loadTeachersAndSubjects () async {
    teachers = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Teacher').get();
    return await FirebaseFirestore.instance.collection('subjects').get();
  }

  scanQR() {
    return FloatingActionButton(
      onPressed: () {
        // Get.toNamed('/scan');
        Get.to(() => const QRScanner());
      },
      child: const Icon(Icons.qr_code_scanner),
    );
  }

  displayStudentInfo() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Student Dashboard'),
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
}
