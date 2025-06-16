class ReceiptMetadata {
  final DateTime processedAt;
  final String ocrEngine;
  final String version;
  final double confidence;

  ReceiptMetadata({
    required this.processedAt,
    required this.ocrEngine,
    required this.version,
    required this.confidence,
  });

  factory ReceiptMetadata.fromJson(Map<String, dynamic> json) {
    return ReceiptMetadata(
      processedAt: DateTime.parse(json['processedAt'] as String),
      ocrEngine: json['ocrEngine'] as String,
      version: json['version'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'processedAt': processedAt.toIso8601String(),
      'ocrEngine': ocrEngine,
      'version': version,
      'confidence': confidence,
    };
  }
} 