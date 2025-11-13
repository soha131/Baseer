
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../notifications/notification_service.dart';
import '../routes.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;

  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _mobileController = TextEditingController();
  final _dobController = TextEditingController();

  DateTime? _selectedDob;
  String _selectedRole = "User";

  // Speech + TTS
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  int _currentStep = 0;
  bool _isListening = false;

  // ======= تحويل الكلام العربي لأرقام =========
  String convertArabicNumbers(String text) {
    const arabicNumbers = {
      '٠': '0',
      '١': '1',
      '٢': '2',
      '٣': '3',
      '٤': '4',
      '٥': '5',
      '٦': '6',
      '٧': '7',
      '٨': '8',
      '٩': '9',
    };
    arabicNumbers.forEach((k, v) {
      text = text.replaceAll(k, v);
    });
    return text;
  }

  String wordsToNumbers(String text) {
    final map = {
      "zero": "0",
      "one": "1",
      "two": "2",
      "three": "3",
      "four": "4",
      "five": "5",
      "six": "6",
      "seven": "7",
      "eight": "8",
      "nine": "9",
    };
    map.forEach((k, v) => text = text.replaceAll(k, v));
    text = convertArabicNumbers(text);
    text = text.replaceAll(RegExp(r'[^0-9/]'), '');
    return text;
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDob = picked;
        _dobController.text = "${picked.day}/${picked.month}/${picked.year}";
      });
    }
  }

  Future<void> _signUp() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text.trim(),
            );

        String status = _selectedRole == "Pharmacist" ? "pending" : "approved";

        await FirebaseFirestore.instance
            .collection("users")
            .doc(userCredential.user!.uid)
            .set({
          "fullName": _fullNameController.text.trim(),
          "email": _emailController.text.trim(),
          "mobile": _mobileController.text.trim(),
          "dob": _selectedDob != null ? Timestamp.fromDate(_selectedDob!) : null,
          "role": _selectedRole,
          "status": status,
          "createdAt": FieldValue.serverTimestamp(),
        });

// 📢 إشعار للأدمن لو Pharmacist جديد
        if (_selectedRole == "Pharmacist") {
          final admins = await FirebaseFirestore.instance
              .collection("users")
              .where("role", isEqualTo: "Admin")
              .get();

          for (var admin in admins.docs) {
            // 1️⃣ أضف الإشعار داخل Firestore
            await FirebaseFirestore.instance.collection("notifications").add({
              "to": admin.id,
              "title": "New Pharmacist Awaiting Approval",
              "body":
              "Pharmacist ${_fullNameController.text.trim()} has registered and requires approval.",
              "createdAt": FieldValue.serverTimestamp(),
              "isRead": false,
              "type": "new_pharmacist",
            });

            // 2️⃣ إرسال إشعار فوري عبر FCM (لو عنده token)
            final fcmToken = admin.data()["fcmToken"];
            if (fcmToken != null && fcmToken.isNotEmpty) {
              await NotificationService.sendToSpecificUser(
                title: "New Pharmacist Awaiting Approval",
                body:
                "Pharmacist ${_fullNameController.text.trim()} has registered and requires approval.",
                fcmToken: fcmToken,
              );
            }
          }
        }



        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("biometricEnabled", false);

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("تم إنشاء الحساب بنجاح")));

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  // ====== 🎤 التحكم في المايك والـ TTS ======


  Future<void> _startVoiceInput({int retryCount = 0}) async {
    List<String> steps = [
      "من فضلك قول اسمك بالكامل  بوضوح",
      "قول البريد الإلكتروني ",
      "قول كلمة المرور ببطء",
      "قول رقم الموبايل رقمًا رقمًا",
      "قول تاريخ الميلاد  بصيغة يوم شهر سنة",
    ];

    // نهاية الخطوات
    if (_currentStep >= steps.length) {
      await _flutterTts.speak(
        "تم إدخال البيانات كالتالي: "
            "الاسم ${_fullNameController.text}, "
            "البريد الإلكتروني ${_emailController.text}, "
            "رقم الموبايل ${_mobileController.text}, "
      );
      await _flutterTts.awaitSpeakCompletion(true);
      if (mounted) setState(() => _currentStep = 0);
      return;
    }

    // تعليمات قبل السؤال مع فاصل صوتي
    await _flutterTts.speak(" ${steps[_currentStep]} ...");
    await _flutterTts.awaitSpeakCompletion(true);
    await Future.delayed(const Duration(seconds: 1));

    // تهيئة المايك
    bool available = await _speech.initialize(
      onError: (error) async {
        print("خطأ في المايك: $error");
        await _flutterTts.speak("لم أتمكن من التعرف على الصوت.");
        await _flutterTts.awaitSpeakCompletion(true);
        if (mounted) setState(() => _isListening = false);
      },
      debugLogging: true,
    );

    if (!available || !mounted) return;

    if (mounted) setState(() => _isListening = true);

    // بدء الاستماع
    _speech.listen(
      localeId: 'en-US', // المستخدم يتكلم إنجليزي
      onResult: (result) async {
        if (!result.finalResult) return;

        String recognizedText = result.recognizedWords.trim();
        await _speech.stop();
        if (mounted) setState(() => _isListening = false);

        if (recognizedText.isEmpty) {
          await _flutterTts.speak("معذرةً، لم أسمع بوضوح.");
          await _flutterTts.awaitSpeakCompletion(true);
          // لا نعيد السؤال تلقائيًا، المستخدم سيبدأ تاني بنفسه
          return;
        }

        // تخزين النص حسب الخطوة
        switch (_currentStep) {
          case 0: _fullNameController.text = recognizedText; break;
          case 1: _emailController.text = recognizedText.replaceAll(' ', ''); break;
          case 2: _passwordController.text = recognizedText; break;
          case 3: _mobileController.text = wordsToNumbers(recognizedText); break;
          case 4: _dobController.text = wordsToNumbers(recognizedText); break;
        }

        await _flutterTts.speak("تم تسجيل: $recognizedText");
        await _flutterTts.awaitSpeakCompletion(true);

        _currentStep++;
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _startVoiceInput();
        });
      },
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
      partialResults: false,
    );
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "New Account",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xff2260FF),
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xff2260FF)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLabel("Full Name"),
              TextFormField(
                controller: _fullNameController,
                validator: (v) => v!.isEmpty ? "Full name is required" : null,
                decoration: _inputDecoration("example"),
              ),
              const SizedBox(height: 16),
              _buildLabel("Email"),
              TextFormField(
                controller: _emailController,
                validator: (v) {
                  if (v == null || v.isEmpty) return "Email is required";
                  if (!v.contains("@")) return "Enter a valid email";
                  return null;
                },
                decoration: _inputDecoration("example@example.com"),
              ),
              const SizedBox(height: 16),
              _buildLabel("Password"),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: _inputDecoration("*********").copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                    onPressed:
                        () => setState(
                          () => _isPasswordVisible = !_isPasswordVisible,
                        ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return "Password required";
                  if (v.length < 6) return "Password must be at least 6 chars";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildLabel("Mobile Number"),
              TextFormField(
                controller: _mobileController,
                validator: (v) => v!.isEmpty ? "Mobile number required" : null,
                decoration: _inputDecoration("0533024544"),
              ),
              const SizedBox(height: 16),
              _buildLabel("Date of Birth"),
              TextFormField(
                controller: _dobController,
                readOnly: true,
                onTap: _pickDate,
                decoration: _inputDecoration("DD / MM / YYYY"),
                validator: (v) => v!.isEmpty ? "Date of Birth required" : null,
              ),
              const SizedBox(height: 16),
              _buildLabel("Role"),
              DropdownButtonFormField<String>(
                value: _selectedRole,
                items: const [
                  DropdownMenuItem(
                    value: "User",
                    child: Text(
                      "User",
                      style: TextStyle(color: Color(0xff2260FF)),
                    ),
                  ),
                  DropdownMenuItem(
                    value: "Pharmacist",
                    child: Text(
                      "Pharmacist",
                      style: TextStyle(color: Color(0xff2260FF)),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _selectedRole = v!),
                decoration: _inputDecoration("Select Role"),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _signUp,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Color(0xff2260FF),
                ),
                child: const Text(
                  "Sign Up",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                  child: Text.rich(
                    TextSpan(
                      text: "Already have an account? ",
                      style: const TextStyle(color: Colors.grey),
                      children: [
                        TextSpan(
                          text: "Log In",
                          style: TextStyle(
                            color: Color(0xff2260FF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: IconButton(
                  icon: Icon(
                    Icons.mic,
                    size: 60,
                    color: _isListening ? Colors.red : Color(0xff2260FF),
                  ),
                  onPressed: _startVoiceInput,
                ),
              ),
/*
              IconButton(
                icon: Icon(
                  Icons.stop,
                  size: 60,
                  color: Colors.red,
                ),
                onPressed: () async {
                  await _speech.stop();
                  await _flutterTts.stop();
                  if (mounted) {
                    setState(() {
                      _isListening = false;
                      _currentStep = 0;
                    });
                  }
                },
              ),
*/
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xff2260FF)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xffECF1FF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xffECF1FF)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Colors.blue, width: 2),
      ),
      filled: true,
      fillColor: const Color(0xffECF1FF),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
    );
  }
  @override
  void dispose() {
    // وقف المايك
    _speech.stop();
    // وقف الـ TTS
    _flutterTts.stop();
    _isListening = false;
    _currentStep = 0;

    super.dispose();
  }

  @override
  void deactivate() {
    _speech.stop();
    _flutterTts.stop();
    super.deactivate();
  }

}
