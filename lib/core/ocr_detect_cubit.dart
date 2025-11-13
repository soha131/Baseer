import 'dart:convert';
import 'dart:io';
import 'package:bloc/bloc.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart'; // عشان نستخدم MediaType
import 'drug_detect_model.dart';
import 'ocr_detect_state.dart';
import 'package:image/image.dart' as img;

class OcrDetectCubit extends Cubit<OcrDetectState> {
  OcrDetectCubit() : super(OcrDetectInitial());

  final String baseUrl = "http://192.168.100.6:8000";
  //final String baseUrl = "http://10.0.2.2:8000";

  Future<void> detectDrugsFromImage(File imageFile) async {
    emit(OcrDetectLoading());

    try {
      final originalBytes = await imageFile.readAsBytes();
      final originalImage = img.decodeImage(originalBytes)!;

      final resizedImage = img.copyResize(originalImage, width: 1024);

      final compressedBytes = img.encodeJpg(resizedImage, quality: 70);

      final uri = Uri.parse("$baseUrl/ocr-detect-drugs");


      final multipartFile = http.MultipartFile.fromBytes(
        'file',
        compressedBytes,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );

      final request = http.MultipartRequest('POST', uri)..files.add(multipartFile);
      final streamedResponse = await request.send().timeout(Duration(seconds: 90));
      final response = await http.Response.fromStream(streamedResponse);

      print("Response body: ${response.body}");

      if (response.statusCode == 200) {
        try {
          final data = jsonDecode(response.body);
          final result = DrugDetectionResponse.fromJson(data);
          emit(OcrDetectSuccess(result));
        } catch (jsonError) {
          emit(OcrDetectError("Failed to parse server response."));
        }
      } else {
        emit(OcrDetectError(
            "Server error: ${response.statusCode} - ${response.reasonPhrase}"));
      }
    } catch (e) {
      emit(OcrDetectError("Failed to send request: $e"));
    }
  }}
