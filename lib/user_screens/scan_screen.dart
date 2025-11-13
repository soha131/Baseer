import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dotted_border/dotted_border.dart'; // ستحتاج لإضافة هذه الحزمة
import '../core/drug_detect_model.dart';
import '../core/ocr_detect_cubit.dart';
import '../core/ocr_detect_state.dart';
import 'medication_reminder_screen.dart';

class ScanMedicineScreen extends StatefulWidget {
  const ScanMedicineScreen({super.key});

  @override
  State<ScanMedicineScreen> createState() => _ScanMedicineScreenState();
}

class _ScanMedicineScreenState extends State<ScanMedicineScreen> {
  File? _selectedImage;
  final picker = ImagePicker();
  final FlutterTts _flutterTts = FlutterTts();
  String _currentTtsText = "";
  bool _isSpeaking = false;    // حالة إذا كان الصوت شغال

  @override
  void initState() {
    super.initState();
    _selectedImage = null;
    context.read<OcrDetectCubit>().emit(OcrDetectInitial());
    _flutterTts.setStartHandler(() {
      setState(() {
        _isSpeaking = true;
      });
    });

    _flutterTts.setCompletionHandler(() {
      setState(() {
        _isSpeaking = false;
        _currentTtsText = "";
      });
    });

    _flutterTts.setCancelHandler(() {
      setState(() {
        _isSpeaking = false;
        _currentTtsText = "";
      });
    });
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("en-US"); // لو عايزة عربي خليه "ar-SA"
    await _flutterTts.setPitch(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.speak(text);
  }
  Future<void> _toggleSpeak(String text) async {
    if (_isSpeaking && _currentTtsText == text) {
      await _flutterTts.stop(); // هيوقف الصوت فوراً
      return;
    }

    // لو صوت شغال لنص مختلف، نوقفه أولاً
    if (_isSpeaking) {
      await _flutterTts.stop();
    }

    _currentTtsText = text;
    await _speak(text);
  }

  /*Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
      // بعد اختيار الصورة، يتم استدعاء الـ Cubit للتعرف عليها
      context.read<OcrDetectCubit>().detectDrugsFromImage(_selectedImage!);
    }
  }*/
  Future<void> _pickImage() async {
    final picked = await showDialog<XFile?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select Image Source"),
        content: const Text("Choose the source of the image"),
        actions: [
          TextButton(
            onPressed: () async {
              final pickedFile = await picker.pickImage(source: ImageSource.camera);
              Navigator.of(ctx).pop(pickedFile);
            },
            child: const Text("Camera"),
          ),
          TextButton(
            onPressed: () async {
              final pickedFile = await picker.pickImage(source: ImageSource.gallery);
              Navigator.of(ctx).pop(pickedFile);
            },
            child: const Text("Gallery"),
          ),
        ],
      ),
    );

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
      // بعد اختيار الصورة، يتم استدعاء الـ Cubit للتعرف عليها
      context.read<OcrDetectCubit>().detectDrugsFromImage(_selectedImage!);
    }
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0), // لون الخلفية رمادي فاتح
      appBar: AppBar(
        backgroundColor: Colors.transparent, // شفاف
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: EdgeInsets.only(top: size.height * 0.1),
              child: GestureDetector(
                onTap: _pickImage,
                child: DottedBorder(
                  options:  RoundedRectDottedBorderOptions(
                  radius: const Radius.circular(24),
                  color: Colors.grey,
                  strokeWidth: 2,
                  dashPattern: const [12, 8],),
                  child: Container(
                    height: size.height * 0.4,
                    width: size.width * 0.75,
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: _selectedImage == null
                        ? Center(
                      child: Text(
                        'Tap to Scan',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                        : ClipRRect(
                      borderRadius: BorderRadius.circular(22),
                      child: Image.file(
                        _selectedImage!,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: BlocBuilder<OcrDetectCubit, OcrDetectState>(
              builder: (context, state) {
                if (state is OcrDetectInitial) {
                  return const SizedBox.shrink(); // لا تعرض شيئاً في البداية
                }
                return _buildInfoCard(state, size);
              },
            ),
          ),
        ],
      ),
    );
  }

  // ويدجت لعرض كارت المعلومات
  Widget _buildInfoCard(OcrDetectState state, Size size) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
              onPressed: () {
                if (state is OcrDetectSuccess && state.result.drugDescriptions.isNotEmpty) {
                  final info = state.result.drugDescriptions.first;
                  final textToRead =
                      "Medicine Name: ${info.drugName}. Description: ${info.description}.";

                  _toggleSpeak(textToRead);
                }
              },
              icon: const Icon(Icons.volume_up_rounded, size: 40, color: Colors.black54)),
          const SizedBox(width: 16),
          // النصوص والمعلومات
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min, // ليأخذ الكارت أقل ارتفاع ممكن
              children: [
                const Text(
                  "Medicine Information:",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),

                // عرض المحتوى حسب حالة الـ Bloc
                if (state is OcrDetectLoading)
                  const Center(child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: CircularProgressIndicator(),
                  )),
                if (state is OcrDetectSuccess)
                  _buildSuccessContent(state.result),
                if (state is OcrDetectError)
                  Text("Error: ${state.message}", style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          const SizedBox(width: 16),
          // زر الإضافة الأزرق
          GestureDetector(
            onTap: ()async {
              if (_isSpeaking) {
                await _flutterTts.stop();
                _isSpeaking = false;
                _currentTtsText = "";
              }
              // خذ اسم الدواء من الـ Bloc
              String medicineName = "";
              final state = context.read<OcrDetectCubit>().state;
              if (state is OcrDetectSuccess && state.result.drugDescriptions.isNotEmpty) {
                medicineName = state.result.drugDescriptions.first.drugName;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MedicationReminderScreen(medicineName: medicineName),
                ),
              );
            },
            child: Container(
              height: 80,
              width: 55,
              decoration: BoxDecoration(
                color: const Color(0xFF4A6CFF),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 30),
            ),
          )
        ],
      ),
    );
  }

  // ويدجت لعرض محتوى النجاح
  Widget _buildSuccessContent(DrugDetectionResponse result) {
    final info = result.drugDescriptions.isNotEmpty
        ? result.drugDescriptions.first
        : null;

    if (info == null) {
      return const Text(
        "No medicine detected.",
        style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
      );
    }

    return Text.rich(
      TextSpan(
        style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
        children: [
          const TextSpan(text: "Medicine Name: ", style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: "${info.drugName}\n"),
          const TextSpan(text: "Description: ", style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: info.description),
        ],
      ),
    );
  }
  @override
  void deactivate() {
    _flutterTts.stop();
    super.deactivate();
  }
}
