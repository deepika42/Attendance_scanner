import 'package:attendscan/services/auth_service.dart';
import 'package:attendscan/widgets/colored_safe_area.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import 'attendance_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

enum BottomNavTab { home, teachers, approvals }

class _AdminDashboardState extends State<AdminDashboard> {
  final AuthController authController = Get.find();
  final selectedTab = BottomNavTab.home.obs;
  final selectedTeacher = ''.obs;
  final subjectNameController = TextEditingController();
  dynamic teachers = [];

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final pages = <Widget>[
      overview(screenSize),
      manageSubjects(screenSize),
      approvalsList(screenSize),
    ];
    return ColoredSafeArea(
      child: Scaffold(
          appBar: displayAdminInfo(),
          bottomNavigationBar: bottomNavigationBar(),
          floatingActionButton: selectedTab.value == BottomNavTab.teachers ?
          FloatingActionButton(
            onPressed: () {
              displayAddSubjectModal(screenSize);
            },
            child: const Icon(Icons.add),
          ) : null,

          body: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(left: screenSize.width * 0.05, right: screenSize.width * 0.05, top: screenSize.height * 0.02),
                  child: pages[BottomNavTab.values.indexOf(selectedTab.value)],
                ),
              ),
            ],
          )
      ),
    );
  }

  displayAdminInfo() {
    return AppBar(
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Admin Dashboard'),
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

  Widget approvalsList(Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Approvals', style: TextStyle(fontSize: 20)),
        SizedBox(height: screenSize.height * 0.01),
        FutureBuilder<QuerySnapshot>(
          future: FirebaseFirestore.instance.collection('users').get(),
          builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.hasError) {
              return Expanded(child: const Text('Something went wrong'));
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return Expanded(child: const Center(child: CircularProgressIndicator()));
            }

            // Check if all users are verified
            bool allUsersVerified = snapshot.data!.docs.every((document) {
              Map<String, dynamic> data = document.data() as Map<String, dynamic>;
              return data['status'] == 'verified';
            });

            if (allUsersVerified) {
              return Expanded(child: const Center(child: Text('No unverified users')));
            }

            return Expanded(
              child: ListView(
                children: snapshot.data!.docs.map((DocumentSnapshot document) {
                  Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                  if (data['status'] == 'verified') {
                    return const SizedBox.shrink();
                  }
                  return ListTile(
                    title: Text(data['email']),
                    subtitle: Text(data['role']),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.check),
                          onPressed: () {
                            document.reference.update({'status': 'verified'});
                            setState(() {

                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            document.reference.delete();
                            setState(() {

                            });
                          },
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget overview(Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Overview', style: TextStyle(fontSize: 20)),
        SizedBox(height: screenSize.height * 0.01),
        // show different infomation in grid view like number of students, teachers, subjects in a card view
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            children: [
              Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Number of Students'),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Student').get(),
                      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Something went wrong');
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        return Text(snapshot.data!.docs.length.toString());
                      },
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Number of Teachers'),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Teacher').get(),
                      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Something went wrong');
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        return Text(snapshot.data!.docs.length.toString());
                      },
                    ),
                  ],
                ),
              ),
              Card(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Number of Subjects'),
                    FutureBuilder<QuerySnapshot>(
                      future: FirebaseFirestore.instance.collection('subjects').get(),
                      builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (snapshot.hasError) {
                          return const Text('Something went wrong');
                        }

                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        }

                        return Text(snapshot.data!.docs.length.toString());
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget manageSubjects(Size screenSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Manage Subjects', style: TextStyle(fontSize: 20)),
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
                  final teacherName = teachers.docs.firstWhere((element) => element.id == data['teacher']).data()['email'];
                  return ListTile(
                    title: Text(data['name']),
                    subtitle: Text(teacherName),
                    onTap: () {
                      Get.to(() => AttendancePage(subjectId: document.id, subjectName: data['name'], isStudent: false));
                    },
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        document.reference.delete();
                        setState(() {

                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<QuerySnapshot<Map<String, dynamic>>> loadTeachersAndSubjects () async {
    teachers = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Teacher').get();
    return await FirebaseFirestore.instance.collection('subjects').get();
  }

  displayAddSubjectModal(Size screenSize) {
    selectedTeacher.value = '';
    subjectNameController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add Subject'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectNameController,
                decoration: const InputDecoration(
                  labelText: 'Subject Name',
                ),
              ),
              SizedBox(height: screenSize.height * 0.03),
              Center(
                child: FutureBuilder(
                  future: FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'Teacher').where('status', isEqualTo: 'verified').get(),
                  builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (snapshot.hasError) {
                      return const Text('Something went wrong');
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Obx (() => PopupMenuButton<String>(
                      onSelected: (value) {
                        selectedTeacher.value = value;
                      },
                      child: Align(alignment: Alignment.centerLeft, child: (selectedTeacher.value == '' ) ? Text('Select Teacher', style: TextStyle(color: Colors.black.withOpacity(0.7)),) : Text(selectedTeacher.value)), // This will be the button text
                      itemBuilder: (context) {
                        return snapshot.data!.docs.map((DocumentSnapshot document) {
                          Map<String, dynamic> data = document.data() as Map<String, dynamic>;
                          return PopupMenuItem<String>(
                            value: data['email'],
                            child: Text(data['email']),
                          );
                        }).toList();
                      },
                    ));
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                if (selectedTeacher.value == '' || subjectNameController.text.trim() == '') {
                  Fluttertoast.showToast(msg: 'Please fill in all fields');
                  return;
                }
                // get teacher uid from email
                final teacherUid = await FirebaseFirestore.instance.collection('users').where('email', isEqualTo: selectedTeacher.value).get().then((value) {
                  return value.docs[0].id;
                });
                // add subject to database
                FirebaseFirestore.instance.collection('subjects').add({
                  'name': subjectNameController.text.trim(),
                  'teacher': teacherUid
                });
                Fluttertoast.showToast(msg: 'Subject added');
                Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  bottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: BottomNavTab.values.indexOf(selectedTab.value),
      onTap: (index) {
        setState(() {
          selectedTab.value = BottomNavTab.values[index];
        });
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Subjects',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.approval),
          label: 'Approvals',
        ),
      ],
    );
  }
}
