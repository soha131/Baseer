class DrugDescription {
  final String drugName;
  final String description;

  DrugDescription({
    required this.drugName,
    required this.description,
  });

  factory DrugDescription.fromJson(Map<String, dynamic> json) {
    return DrugDescription(
      drugName: json['drug_name'] ?? '',
      description: json['description'] ?? '',
    );
  }
}

class DrugDetectionResponse {
  final String extractedText;
  final List<String> detectedDrugs;
  final List<DrugDescription> drugDescriptions;

  DrugDetectionResponse({
    required this.extractedText,
    required this.detectedDrugs,
    required this.drugDescriptions,
  });

  factory DrugDetectionResponse.fromJson(Map<String, dynamic> json) {
    return DrugDetectionResponse(
      extractedText: json['extracted_text'] ?? '',
      detectedDrugs: List<String>.from(json['detected_drugs'] ?? []),
      drugDescriptions: (json['drug_descriptions'] as List<dynamic>? ?? [])
          .map((item) => DrugDescription.fromJson(item))
          .toList(),
    );
  }
}
