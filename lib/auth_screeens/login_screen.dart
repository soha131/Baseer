import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import '../routes.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  final LocalAuthentication auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _isAuthenticating = false;

  // ✅ Secure Storage
  final _secureStorage = const FlutterSecureStorage();

  // 🎤 Voice + TTS
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _checkBiometricSupport();
    _tryBiometricAutoLogin();
  }

  Future<void> _checkBiometricSupport() async {
    try {
      bool canCheck = await auth.canCheckBiometrics;
      setState(() {
        _canCheckBiometrics = canCheck;
      });
    } on PlatformException catch (e) {
      debugPrint("Error checking biometrics: $e");
    }
  }

  Future<void> _tryBiometricAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool("biometricEnabled") ?? false;

    if (enabled && _canCheckBiometrics) {
      _authenticateWithBiometrics();
    }
  }

  Future<void> _authenticateWithBiometrics() async {
    if (_isAuthenticating) return;

    try {
      _isAuthenticating = true;

      bool authenticated = await auth.authenticate(
        localizedReason: 'ضع بصمتك لتسجيل الدخول',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );

      if (authenticated) {
        final email = await _secureStorage.read(key: "email");
        final password = await _secureStorage.read(key: "password");

        if (email != null && password != null) {
          final credential =
          await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          _navigateByRole(credential.user!.uid);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("لا يوجد بيانات محفوظة للبصمة ❌")),
          );
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Error using biometrics: $e");
    } finally {
      _isAuthenticating = false;
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        // حفظ البيانات محليًا
        await _secureStorage.write(key: "email", value: _emailController.text.trim());
        await _secureStorage.write(key: "password", value: _passwordController.text.trim());

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool("biometricEnabled", true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم تسجيل الدخول بنجاح 🎉"),
            backgroundColor: Colors.green,
          ),
        );

        final uid = credential.user!.uid;

        // طلب الإذن بالإشعارات
        await FirebaseMessaging.instance.requestPermission();

        // 🔁 محاولة الحصول على FCM Token مع retry
        String? fcmToken;
        const maxRetry = 2;
        for (int i = 0; i < maxRetry; i++) {
          try {
            fcmToken = await FirebaseMessaging.instance.getToken();
            if (fcmToken != null) break;
          } catch (e) {
            await Future.delayed(const Duration(seconds: 5));
          }
        }

        if (fcmToken != null) {
          await FirebaseFirestore.instance.collection('users').doc(uid).update({
            'fcmToken': fcmToken,
          });
        } else {
          if (kDebugMode) {
            print("❌ Could not get FCM token after $maxRetry attempts.");
          }
        }

        // متابعة التنقل حسب الدور
        _navigateByRole(uid);
      } on FirebaseAuthException catch (e) {
        String errorMessage;
        switch (e.code) {
          case "user-not-found":
            errorMessage = "لا يوجد حساب مسجل بهذا البريد الإلكتروني.";
            break;
          case "wrong-password":
            errorMessage = "كلمة المرور غير صحيحة.";
            break;
          case "invalid-email":
            errorMessage = "صيغة البريد الإلكتروني غير صحيحة.";
            break;
          case "user-disabled":
            errorMessage = "تم تعطيل هذا الحساب.";
            break;
          default:
            errorMessage = "حدث خطأ غير متوقع. حاول مرة أخرى.";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateByRole(String uid) async {
    try {
      final userDoc =
      await FirebaseFirestore.instance.collection("users").doc(uid).get();

      if (!userDoc.exists || userDoc.data() == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("بيانات المستخدم غير موجودة. الرجاء التواصل مع الدعم."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final data = userDoc.data()!;
      final role = data["role"] as String?;
      final status = data["status"] as String?;

      if (role == null) {
        throw Exception("Role not found");
      }

      if (role == "Admin") {
        Navigator.pushReplacementNamed(context, AppRoutes.admin);
      } else if (role == "User") {
        Navigator.pushReplacementNamed(context, AppRoutes.userHome);
      } else if (role == "Pharmacist") {
        if (status == "approved") {
          Navigator.pushReplacementNamed(context, AppRoutes.pharmacistHome);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("حالة الحساب: ${status ?? 'غير معروف'}")),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("دور المستخدم غير معروف."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("خطأ أثناء التحقق من دور المستخدم: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // 🎤 Voice Input Logic
  Future<void> _startVoiceProcess() async {
    _currentStep = 0;
    await _askForField(
      "من فضلك قل البريد الإلكتروني الخاص بك",
      _emailController,
      isEmail: true,
    );  }

  Future<void> _askForField(
      String question,
      TextEditingController controller, {
        bool isEmail = false,
        bool isNumber = false,
      }) async {
    try {
      await _flutterTts.speak(question);
      await _flutterTts.awaitSpeakCompletion(true);

      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);

        _speech.listen(onResult: (result) async {
          if (result.finalResult) {
            String text = result.recognizedWords.trim();

            await _speech.stop();
            setState(() => _isListening = false);

            if (isEmail) {
              text = text
                  .toLowerCase()
                  .replaceAll(" at ", "@")
                  .replaceAll(" dot ", ".")
                  .replaceAll(" underscore ", "_")
                  .replaceAll(" dash ", "-")
                  .replaceAll(" ", "");
            }

            if (isNumber) {
              text = _wordsToNumbers(text);
            }

            controller.text = text;

            await _flutterTts.speak("تم تسجيل: $text");
            await _flutterTts.awaitSpeakCompletion(true);

            if (_currentStep == 0) {
              _currentStep = 1;
              await _askForField("من فضلك قل كلمة المرور", _passwordController);
            } else if (_currentStep == 1) {
              _currentStep = 2;
              await _flutterTts.speak("تم إدخال البيانات. اضغط تسجيل الدخول");
            }
          }
        });
      } else {
        throw Exception("Speech initialization failed");
      }
    } catch (e) {
      await _speech.stop();
      await _flutterTts.stop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("خطأ في التسجيل الصوتي: $e")),
      );
    } finally {
      setState(() => _isListening = false);
    }
  }
// دالة تحويل كلمات الأرقام لأرقام
  String _wordsToNumbers(String text) {
    Map<String, String> numbersMap = {
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

    numbersMap.forEach((word, digit) {
      text = text.replaceAll(word, digit);
    });

    return text.replaceAll(RegExp(r'\s+'), "");
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Hello!",
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
              const Text(
                "Welcome",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xff2260FF),
                ),
              ),
              const SizedBox(height: 30),

              // 📧 Email
              _buildTextField(
                controller: _emailController,
                label: "Email",
                hint: "example@example.com",
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return "Email is required";
                  }
                  final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                  if (!emailRegex.hasMatch(value)) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 🔑 Password
              _buildTextField(
                controller: _passwordController,
                label: "Password",
                hint: "********",
                obscure: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Password is required";
                  }
                  if (value.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.forgetPassword),
                  child: const Text(
                    "Forgot password?",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff2260FF),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // 🔘 Login Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff2260FF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _isLoading ? null : _handleLogin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                    "Login",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sign up link
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.register,
                    );
                  },
                  child: Text.rich(
                    TextSpan(
                      text: "Don’t have an account? ",
                      style: TextStyle(color: Colors.grey.shade700),
                      children: const [
                        TextSpan(
                          text: "Sign Up",
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

              if (_canCheckBiometrics)
                Center(
                  child: GestureDetector(
                    onTap: _authenticateWithBiometrics,
                    child: const Icon(
                      Icons.fingerprint,
                      size: 80,
                      color: Color(0xff2260FF),
                    ),
                  ),
                ),
              const SizedBox(height: 15),

              // 🎤 زر المايك
              Center(
                child: GestureDetector(
                  onTap: _isLoading || _isListening ? null : _startVoiceProcess,
                  child: Icon(
                    Icons.mic,
                    size: 60,
                    color: _isListening ? Colors.red : Color(0xff2260FF),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label),
        TextFormField(
          cursorColor: const Color(0xff2260FF),
          controller: controller,
          validator: validator,
          obscureText: obscure,
          decoration: _inputDecoration(hint).copyWith(suffixIcon: suffixIcon),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xff2260FF)),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
  void deactivate() {
    _speech.stop();
    _flutterTts.stop();
    super.deactivate();
  }
}
