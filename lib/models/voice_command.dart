/// Represents a voice command from the user
class VoiceCommand {
  final String id;
  final String text;
  final DateTime timestamp;
  final String language;
  final double? confidence;
  final bool isProcessed;

  VoiceCommand({
    required this.id,
    required this.text,
    required this.timestamp,
    required this.language,
    this.confidence,
    this.isProcessed = false,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'language': language,
      'confidence': confidence,
      'isProcessed': isProcessed,
    };
  }

  /// Create from JSON
  factory VoiceCommand.fromJson(Map<String, dynamic> json) {
    return VoiceCommand(
      id: json['id'] ?? '',
      text: json['text'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      language: json['language'] ?? 'ar',
      confidence: json['confidence']?.toDouble(),
      isProcessed: json['isProcessed'] ?? false,
    );
  }

  /// Create a copy with updated fields
  VoiceCommand copyWith({
    String? id,
    String? text,
    DateTime? timestamp,
    String? language,
    double? confidence,
    bool? isProcessed,
  }) {
    return VoiceCommand(
      id: id ?? this.id,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      language: language ?? this.language,
      confidence: confidence ?? this.confidence,
      isProcessed: isProcessed ?? this.isProcessed,
    );
  }

  @override
  String toString() {
    return 'VoiceCommand(id: $id, text: $text, timestamp: $timestamp)';
  }
}
