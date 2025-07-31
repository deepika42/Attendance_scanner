import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';

import '../services/auth_service.dart';

class SignUpPage extends StatefulWidget {

  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final AuthController authController = Get.find();
  final passwordObscureText = true.obs;
  final confirmPasswordObscureText = true.obs;
  final isLoading = false.obs;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  RxString selectedRole = 'Student'.obs;
  final _roles = ['Student', 'Teacher', 'Admin'];

  void togglePasswordVisibility() {
    passwordObscureText.value = !passwordObscureText.value;
  }

  void toggleConfirmPasswordVisibility() {
    confirmPasswordObscureText.value = !confirmPasswordObscureText.value;
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
                    padding: EdgeInsets.symmetric(
                        horizontal: screenSize.width * 0.07),
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
                            const Text(
                              'Sign up',
                              style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold
                              ),
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
                                hintStyle: TextStyle(
                                    color: Theme.of(context).hintColor, fontSize: 15.0
                                ),
                                fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                filled: true,
                              ),
                            ),
                            SizedBox(height: screenSize.height * 0.02),
                            // enter role teacher or student

                            Obx (() => Container(
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                border: Border.all(
                                  color: Colors.black,
                                ),
                                borderRadius: BorderRadius.circular(35.0),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: DropdownButton(
                                  underline: const SizedBox(),
                                  hint: const Text('Select role'),
                                  value: selectedRole.value,
                                  onChanged: (value) {
                                    selectedRole.value = value as String;
                                    // setState(() {
                                    //   _selectedRole = value as String;
                                    // });
                                  },
                                  items: _roles.map((role) {
                                    return DropdownMenuItem(
                                      value: role,
                                      child: Text(role),
                                    );
                                  }).toList(),
                                ),
                              ),
                            )),
                            // TextField(
                            //   controller: _usernameController,
                            //   keyboardType: TextInputType.emailAddress,
                            //   autocorrect: false,
                            //   decoration: InputDecoration(
                            //     border: OutlineInputBorder(
                            //       borderRadius: BorderRadius.circular(35.0),
                            //     ),
                            //     hintText: 'Enter username',
                            //     hintStyle: TextStyle(
                            //         color: Theme.of(context).hintColor,
                            //         fontSize: 15.0
                            //     ),
                            //     fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            //     filled: true,
                            //   ),
                            // ),
                            SizedBox(height: screenSize.height * 0.02),
                            Obx(() => TextField(
                              controller: _passwordController,
                              obscureText: passwordObscureText.value,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(35.0),
                                ),
                                hintText: 'Enter password',
                                hintStyle: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: 15.0
                                ),
                                fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                filled: true,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    passwordObscureText.value ? Icons.visibility : Icons
                                        .visibility_off,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  onPressed: togglePasswordVisibility,
                                ),
                              ),
                            )),
                            SizedBox(height: screenSize.height * 0.02),
                            Obx(() => TextField(
                              controller: _confirmPasswordController,
                              obscureText: confirmPasswordObscureText.value,
                              decoration: InputDecoration(
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(35.0),
                                ),
                                hintText: 'Confirm password',
                                hintStyle: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: 15.0
                                ),
                                fillColor: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                                filled: true,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    confirmPasswordObscureText.value ? Icons.visibility : Icons
                                        .visibility_off,
                                    color: Theme.of(context).colorScheme.secondary,
                                  ),
                                  onPressed: toggleConfirmPasswordVisibility,
                                ),
                              ),
                            )),
                            SizedBox(height: screenSize.height * 0.04),
                            SizedBox(
                              height: screenSize.height * 0.06,
                              child: ElevatedButton(
                                onPressed: createAccount,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                ),
                                child: const Text(
                                    'Create account',
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
                                      text: 'Already have an account? ',
                                      style: TextStyle(
                                        fontSize: 14.0,
                                        color: Theme.of(context).colorScheme.secondary,
                                      ),
                                      children: <TextSpan>[
                                        TextSpan(
                                            text: 'Login',
                                            style: const TextStyle(
                                                fontSize: 15.0,
                                                color: Colors.blue,
                                                fontWeight: FontWeight.w600
                                            ),
                                            recognizer: TapGestureRecognizer()
                                              ..onTap = () {
                                                Get.back();
                                              }
                                        )
                                      ]
                                  ),
                                  textAlign: TextAlign.center
                              ),
                              onTap: () {
                                Get.back();
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
              ),
            );
          }
          else {
            return const SizedBox.shrink();
          }
        })
      ],
    );
  }

  createAccount() async {
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    if (email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      Fluttertoast.showToast(
        msg: 'Please fill all fields',
      );
    } else if (password != confirmPassword) {
      Fluttertoast.showToast(
        msg: 'Passwords do not match',
      );
    } else {
      isLoading.value = true;
      bool isFirstUser = await authController.isFirstUser();
      print('isFirstUser: $isFirstUser');

      await authController.registerWithEmailPassword(email, password).then((user) async {
        if (user != null) {
          final currentUser = authController.getCurrentUser();
          if (currentUser != null && !currentUser.emailVerified) {
            currentUser.sendEmailVerification();
          }
          if (isFirstUser) {
            await authController.setUserRole('Admin');
            await authController.setVerifiedUser();
          } else {
            await authController.setUserRole(selectedRole.value);
            await authController.setUnverifiedUser();
          }
          Fluttertoast.showToast(
            msg: 'Account created successfully, you need to verify your email before you can login',
          );
          isLoading.value = false;
          Get.back();
        }
      });
    }
    isLoading.value = false;
  }
}