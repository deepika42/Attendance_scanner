import 'package:attendscan/admin_dashboard.dart';
import 'package:attendscan/signup.dart';
import 'package:attendscan/student_dashboard.dart';
import 'package:attendscan/teacher_dashboard.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../services/auth_service.dart';

class LoginPage extends StatelessWidget {

  LoginPage({super.key});

  final AuthController authController = Get.put(AuthController());
  final _obscureText = true.obs;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final isLoading = false.obs;

  void _toggleVisibility() {
    _obscureText.toggle();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Stack(
      children: [
        Scaffold(
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Stack(
                children: <Widget>[
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: screenSize.width * 0.07),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Text(
                              'AttendScan',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: screenSize.height * 0.03),
                            Text(
                              'Login',
                              style: TextStyle(fontSize: 20, color: Colors.black, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              autocorrect: false,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(35.0),
                                ),
                                hintText: 'Enter your email',
                                hintStyle: TextStyle(color: Theme.of(context).hintColor, fontSize: 15.0),
                                fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                filled: true,
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            Obx(() => TextField(
                              controller: _passwordController,
                              obscureText: _obscureText.value,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(35.0),
                                ),
                                hintText: 'Enter password',
                                hintStyle: TextStyle(color: Theme.of(context).hintColor, fontSize: 15.0),
                                fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                filled: true,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscureText.value ? Icons.visibility : Icons.visibility_off,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  onPressed: _toggleVisibility,
                                ),
                              ),
                            )),
                            SizedBox(height: screenSize.height * 0.02),
                            SizedBox(
                              height: screenSize.height * 0.06,
                              child: ElevatedButton(
                                onPressed: login,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text(
                                    'Login',
                                    style: TextStyle(
                                        fontSize: 18.0,
                                        color: Colors.white
                                    )
                                ),
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            InkWell(
                              child: Text.rich(
                                  TextSpan(
                                      text: 'Not register yet? ',
                                      style: TextStyle(fontSize: 14.0, color: Theme.of(context).colorScheme.secondary),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: 'Create Account',
                                            style: const TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w600
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                Get.to(() => SignUpPage());
                                              }
                                        )
                                      ]
                                  ),
                                  textAlign: TextAlign.center
                              ),
                              onTap: () {
                                Get.to(() => SignUpPage());
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Obx(() {
          if (isLoading.value) {
            return Container(
                color: Colors.black.withOpacity(0.5),
                child: const Center(
                  child: CircularProgressIndicator(),
                )
            );
          } else {
            return const SizedBox.shrink();
          }
        }
        )
      ],
    );
  }

  login() async {
    isLoading.value = true;
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please fill in all fields',
        backgroundColor: Colors.red,
      );
      isLoading.value = false;
      return;
    }

    final User? user = await authController.signInWithEmailPassword(email, password);
    _passwordController.clear();

    await authController.loadUserData();
    print(authController.userStatus.value);

    if (user != null) {
      if (!user.emailVerified) {
        Fluttertoast.showToast(
          msg: 'Please verify your email from the link sent to your email address',
        );
        isLoading.value = false;
        return;
      } else if (authController.userStatus.value == 'unverified') {
        Fluttertoast.showToast(
          msg: 'Your account is not verified yet. Please wait for the admin to verify your account',
        );
        isLoading.value = false;
        return;
      }
      switch (authController.userRole.value) {
        case 'Admin':
          Get.offAll(() => const AdminDashboard());
          break;
        case 'Student':
          Get.offAll(() => const StudentDashboard());
          break;
        case 'Teacher':
          Get.offAll(() => const TeacherDashboard());
        default:
          break;
      }
      Fluttertoast.showToast(
        msg: 'Logged in',
      );
    }
    isLoading.value = false;
  }
}