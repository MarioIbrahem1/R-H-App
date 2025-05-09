import 'package:flutter/material.dart';
import 'package:road_helperr/ui/public_details/validation_form.dart';
// الدارك/لايت الجديد

class SignupScreen extends StatefulWidget {
  static const String routeName = "signupscreen";
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  @override
  Widget build(BuildContext context) {
    // تقدر تستخدم ألوان الثيم الديناميك من AppColors مباشرة بدل شرط كل مرة
    final bool isLight = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      backgroundColor: isLight
          ? const Color(0xFF86A5D9)
          : const Color(0xFF1F3551),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.33,
              decoration: BoxDecoration(
                color: isLight
                    ? const Color(0xFF86A5D9)
                    : const Color(0xFF1F3551),
                image: const DecorationImage(
                  image: AssetImage("assets/images/rafiki.png"),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.33,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: isLight
                    ? Colors.white
                    : const Color(0xFF01122A),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(35),
                  topRight: Radius.circular(35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: const SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ValidationForm(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
