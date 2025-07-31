import 'package:attendscan/services/auth_service.dart';
import 'package:attendscan/widgets/colored_safe_area.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class AttendancePage extends StatelessWidget {
  final String subjectId;
  final String subjectName;
  final bool isStudent;
  AttendancePage({super.key, required this.subjectId, required this.subjectName, required this.isStudent});
  final authController = Get.find<AuthController>();

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return ColoredSafeArea(
      child: Scaffold(
          appBar: attendanceAppBar(),
          body: Padding(
            padding: EdgeInsets.only(left: screenSize.width * 0.05, right: screenSize.width * 0.05, top: screenSize.height * 0.02),
            child: Column(
              children: [
                attendanceOverview(screenSize),
              ],
            ),
          )
      ),
    );
  }

  attendanceOverview(Size screenSize) {
    if (isStudent) {
      final studentId = authController
          .getCurrentUser()
          ?.uid;
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$subjectName Attendance Overview',
                style: const TextStyle(fontSize: 20)),
            SizedBox(height: screenSize.height * 0.01),
            FutureBuilder(
              future: FirebaseFirestore.instance.collection('attendance').where(
                  'subjectId', isEqualTo: subjectId).where(
                  'studentId', isEqualTo: studentId).orderBy(
                  'date', descending: true).get(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return const Expanded(
                      child: Center(child: Text('Something went wrong')));
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Expanded(
                      child: Center(child: CircularProgressIndicator()));
                }

                if (snapshot.data!.docs.isEmpty) {
                  return const Expanded(child: Center(
                      child: Text('No attendance records found')));
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      final doc = snapshot.data!.docs[index];
                      return ListTile(
                        title: Text(DateFormat("dd MMM yyyy").format(
                            DateTime.parse(doc['date'].toString()))),
                        subtitle: const Text("Present"),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      );
    } else {
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$subjectName Attendance Overview',
                style: const TextStyle(fontSize: 20)),
            SizedBox(height: screenSize.height * 0.01),
            FutureBuilder(
              future: FirebaseFirestore.instance.collection('users').where(
                  'role', isEqualTo: 'Student').get(),
              builder: (BuildContext context,
                  AsyncSnapshot<QuerySnapshot> studentSnapshot) {
                if (studentSnapshot.hasError) {
                  return const Expanded(
                      child: Center(child: Text('Something went wrong')));
                }

                if (studentSnapshot.connectionState == ConnectionState.waiting) {
                  return const Expanded(
                      child: Center(child: CircularProgressIndicator()));
                }

                if (studentSnapshot.data!.docs.isEmpty) {
                  return const Expanded(child: Center(
                      child: Text('No students found')));
                }

                return Expanded(
                  child: ListView.builder(
                    itemCount: studentSnapshot.data!.docs.length,
                    itemBuilder: (BuildContext context, int index) {
                      final studentDoc = studentSnapshot.data!.docs[index];
                      return ExpansionTile(
                        title: Text(studentDoc['email']),
                        children: [
                          FutureBuilder(
                            future: FirebaseFirestore.instance.collection('attendance').where(
                                'subjectId', isEqualTo: subjectId).where(
                                'studentId', isEqualTo: studentDoc.id).orderBy(
                                'date', descending: true).get(),
                            builder: (BuildContext context,
                                AsyncSnapshot<QuerySnapshot> attendanceSnapshot) {
                              if (attendanceSnapshot.hasError) {
                                return const SizedBox(height: 70, child: Center(child: Text('Something went wrong')));
                              }

                              if (attendanceSnapshot.connectionState == ConnectionState.waiting) {
                                return const SizedBox(height: 70, child: Center(child: CircularProgressIndicator()));
                              }

                              if (attendanceSnapshot.data!.docs.isEmpty) {
                                return const SizedBox(height: 70, child: Center(child: Text('No attendance records found')));
                              }

                              return ListView.builder(
                                shrinkWrap: true,
                                itemCount: attendanceSnapshot.data!.docs.length,
                                itemBuilder: (BuildContext context, int index) {
                                  final doc = attendanceSnapshot.data!.docs[index];
                                  return ListTile(
                                    title: Text(DateFormat("dd MMM yyyy").format(
                                        DateTime.parse(doc['date'].toString()))),
                                    subtitle: const Text("Present"),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      );
    }
  }

  attendanceAppBar() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Attendance'),
          Text(
            authController.getCurrentUser()?.email ?? '',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
