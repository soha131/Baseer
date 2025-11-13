import 'package:equatable/equatable.dart';
import 'drug_detect_model.dart';

abstract class OcrDetectState extends Equatable {
  @override
  List<Object?> get props => [];
}

class OcrDetectInitial extends OcrDetectState {}

class OcrDetectLoading extends OcrDetectState {}

class OcrDetectSuccess extends OcrDetectState {
  final DrugDetectionResponse result;

  OcrDetectSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

class OcrDetectError extends OcrDetectState {
  final String message;

  OcrDetectError(this.message);

  @override
  List<Object?> get props => [message];
}
