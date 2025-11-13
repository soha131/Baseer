import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Timer(const Duration(seconds: 3), _navigateNext);
  }

  Future<void> _navigateNext() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(user.uid)
          .get();

      if (!doc.exists) {
        Navigator.pushReplacementNamed(context, AppRoutes.welcome);
        return;
      }

      final data = doc.data()!;
      final role = data["role"];
      final status = data["status"];

      if (role == "User") {
        Navigator.pushReplacementNamed(context, AppRoutes.userHome);
      } else if (role == "Pharmacist") {
        if (status == "approved") {
          Navigator.pushReplacementNamed(context, AppRoutes.pharmacistHome);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("حالة الحساب: $status")),
          );
          Navigator.pushReplacementNamed(context, AppRoutes.welcome);
        }
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.welcome);
      }
    } catch (e) {
      Navigator.pushReplacementNamed(context, AppRoutes.welcome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Semantics(
              label: "شعار التطبيق",
              child: Image.asset(
                "assets/logo/logo.png",
                width: 220,
                height: 220,
              ),
            ),
            const SizedBox(height: 15),
             Semantics(
              label: "اسم التطبيق: بصير",
              child: Text(
                "Baseer",
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
