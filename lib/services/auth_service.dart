import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../login.dart';

class AuthController extends GetxController{
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final userRole = ''.obs;
  final userStatus = ''.obs;

  @override
  Future<void> onInit() async {
    super.onInit();
    await loadUserData();
  }

  Future<void> setUserRole(String role) async {
    userRole.value = role;
    await _db.collection('users').doc(_auth.currentUser!.uid).set(
        {
          'role': role,
        },
        SetOptions(merge: true)
    );
  }

  Future<void> setUnverifiedUser() async {
    await _db.collection('users').doc(_auth.currentUser!.uid).set(
        {
          'email': _auth.currentUser!.email,
          'status': 'unverified',
        },
        SetOptions(merge: true)
    );
  }

  Future<void> setVerifiedUser() async {
    await _db.collection('users').doc(_auth.currentUser!.uid).set(
        {
          'email': _auth.currentUser!.email,
          'status': 'verified',
        },
        SetOptions(merge: true)
    );
  }

  Future<void> loadUserData() async {
    if (_auth.currentUser == null) {
      return;
    }
    final doc = await _db
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .get();

    if (doc.exists) {
      userRole.value = doc['role'];
      userStatus.value = doc['status'];
    }
  }

  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        return user;
      }
    }
    catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'user-not-found') {
          Fluttertoast.showToast(
            msg: 'No user found for that email.',
          );
        }
        else if (e.code == 'too-many-requests') {
          Fluttertoast.showToast(
            msg: 'Too many requests. Try again later.',
          );
        }
        else if (e.code == 'invalid-email') {
          Fluttertoast.showToast(
            msg: 'Invalid email. Try again.',
          );
        }
        else if (e.code == 'wrong-password') {
          Fluttertoast.showToast(
            msg: 'Wrong password. Try again.',
          );
        }
        else if (e.code == 'user-disabled') {
          Fluttertoast.showToast(
            msg: 'User disabled. Contact support.',
          );
        }
        else if (e.code == 'invalid-credential') {
          Fluttertoast.showToast(
            msg: 'Invalid credentials. Try again.',
          );
        }
        else {
          Fluttertoast.showToast(
            msg: 'Error: $e',
          );
        }
      }
    }
    return null;
  }

  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      final UserCredential userCredential = await _auth
          .createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final User? user = userCredential.user;

      if (user != null) {
        return user;
      }
    } catch (e) {
      if (e is FirebaseAuthException) {
        if (e.code == 'email-already-in-use') {
          Fluttertoast.showToast(
            msg: 'Email already in use. Try again.',
          );
        }
        else if (e.code == 'invalid-email') {
          Fluttertoast.showToast(
            msg: 'Invalid email. Try again.',
          );
        }
        else if (e.code == 'weak-password') {
          Fluttertoast.showToast(
            msg: 'Weak password. Try again.',
          );
        }
        else {
          Fluttertoast.showToast(
            msg: 'Error: $e',
          );
        }
      }
    }
    return null;
  }

  Future<bool> isFirstUser() async {
    // check if the user is the first user
    return await _db.collection('users').get().then((QuerySnapshot querySnapshot) {
      return querySnapshot.docs.isEmpty;
    });
  }

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> logout() async {
    await _auth.signOut();
    Get.offAll(() => LoginPage());
  }
}