/// Represents the result of intent classification from AI/NLP processing
class IntentResult {
  final String intent;
  final double confidence;
  final Map<String, dynamic> entities;
  final String originalText;
  final bool isError;
  final String? errorMessage;

  IntentResult({
    required this.intent,
    required this.confidence,
    required this.entities,
    required this.originalText,
    this.isError = false,
    this.errorMessage,
  });

  /// Create an error result
  IntentResult.error(String message)
      : intent = 'error',
        confidence = 0.0,
        entities = {},
        originalText = '',
        isError = true,
        errorMessage = message;

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'intent': intent,
      'confidence': confidence,
      'entities': entities,
      'originalText': originalText,
      'isError': isError,
      'errorMessage': errorMessage,
    };
  }

  /// Create from JSON
  factory IntentResult.fromJson(Map<String, dynamic> json) {
    return IntentResult(
      intent: json['intent'] ?? '',
      confidence: (json['confidence'] ?? 0.0).toDouble(),
      entities: Map<String, dynamic>.from(json['entities'] ?? {}),
      originalText: json['originalText'] ?? '',
      isError: json['isError'] ?? false,
      errorMessage: json['errorMessage'],
    );
  }

  /// Check if this is a database operation intent
  bool get isDatabaseIntent {
    return [
      'add_appointment',
      'add_reminder',
      'add_expense',
      'show_appointments',
      'show_reminders',
      'show_expenses',
      'delete_appointment',
      'delete_reminder',
      'delete_expense',
      'edit_appointment',
      'edit_reminder',
      'edit_expense',
    ].contains(intent);
  }

  /// Check if this is an information request intent
  bool get isInformationIntent {
    return [
      'weather',
      'news',
      'time',
      'date',
      'calculate',
      'translate',
    ].contains(intent);
  }

  /// Get a user-friendly description of the intent
  String get description {
    switch (intent) {
      case 'add_appointment':
        return 'إضافة موعد جديد';
      case 'add_reminder':
        return 'إضافة تذكير جديد';
      case 'add_expense':
        return 'إضافة مصروف جديد';
      case 'show_appointments':
        return 'عرض المواعيد';
      case 'show_reminders':
        return 'عرض التذكيرات';
      case 'show_expenses':
        return 'عرض المصاريف';
      case 'weather':
        return 'الاستعلام عن الطقس';
      case 'news':
        return 'الاستعلام عن الأخبار';
      case 'time':
        return 'الاستعلام عن الوقت';
      case 'date':
        return 'الاستعلام عن التاريخ';
      case 'calculate':
        return 'إجراء حساب';
      case 'translate':
        return 'ترجمة نص';
      case 'unknown':
        return 'أمر غير مفهوم';
      case 'error':
        return 'خطأ في المعالجة';
      default:
        return intent;
    }
  }

  @override
  String toString() {
    return 'IntentResult(intent: $intent, confidence: $confidence, entities: $entities)';
  }
}
