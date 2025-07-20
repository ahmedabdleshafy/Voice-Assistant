import 'voice_command.dart';
import 'intent_result.dart';

/// Represents the current conversation context and history
class ConversationContext {
  final String sessionId;
  final VoiceCommand? lastCommand;
  final IntentResult? lastIntent;
  final List<VoiceCommand> conversationHistory;
  final DateTime timestamp;
  final Map<String, dynamic> userPreferences;
  final Map<String, dynamic> sessionData;

  ConversationContext({
    required this.sessionId,
    this.lastCommand,
    this.lastIntent,
    required this.conversationHistory,
    required this.timestamp,
    this.userPreferences = const {},
    this.sessionData = const {},
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'lastCommand': lastCommand?.toJson(),
      'lastIntent': lastIntent?.toJson(),
      'conversationHistory': conversationHistory.map((cmd) => cmd.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'userPreferences': userPreferences,
      'sessionData': sessionData,
    };
  }

  /// Create from JSON
  factory ConversationContext.fromJson(Map<String, dynamic> json) {
    return ConversationContext(
      sessionId: json['sessionId'] ?? '',
      lastCommand: json['lastCommand'] != null 
          ? VoiceCommand.fromJson(json['lastCommand'])
          : null,
      lastIntent: json['lastIntent'] != null
          ? IntentResult.fromJson(json['lastIntent'])
          : null,
      conversationHistory: (json['conversationHistory'] as List<dynamic>?)
          ?.map((cmd) => VoiceCommand.fromJson(cmd))
          .toList() ?? [],
      timestamp: DateTime.parse(json['timestamp']),
      userPreferences: Map<String, dynamic>.from(json['userPreferences'] ?? {}),
      sessionData: Map<String, dynamic>.from(json['sessionData'] ?? {}),
    );
  }

  /// Create a copy with updated fields
  ConversationContext copyWith({
    String? sessionId,
    VoiceCommand? lastCommand,
    IntentResult? lastIntent,
    List<VoiceCommand>? conversationHistory,
    DateTime? timestamp,
    Map<String, dynamic>? userPreferences,
    Map<String, dynamic>? sessionData,
  }) {
    return ConversationContext(
      sessionId: sessionId ?? this.sessionId,
      lastCommand: lastCommand ?? this.lastCommand,
      lastIntent: lastIntent ?? this.lastIntent,
      conversationHistory: conversationHistory ?? this.conversationHistory,
      timestamp: timestamp ?? this.timestamp,
      userPreferences: userPreferences ?? this.userPreferences,
      sessionData: sessionData ?? this.sessionData,
    );
  }

  /// Get the last N commands from history
  List<VoiceCommand> getRecentCommands(int count) {
    if (conversationHistory.length <= count) {
      return List.from(conversationHistory);
    }
    return conversationHistory.sublist(conversationHistory.length - count);
  }

  /// Check if user is in the middle of a multi-step operation
  bool get isInMultiStepOperation {
    if (lastIntent == null) return false;
    
    // Check if the last intent requires follow-up information
    return [
      'add_appointment_partial',
      'add_reminder_partial',
      'add_expense_partial',
      'edit_appointment_partial',
    ].contains(lastIntent!.intent);
  }

  /// Get missing information for current operation
  List<String> get missingInformation {
    if (!isInMultiStepOperation || lastIntent == null) return [];
    
    final entities = lastIntent!.entities;
    final missing = <String>[];
    
    switch (lastIntent!.intent) {
      case 'add_appointment_partial':
        if (!entities.containsKey('title')) missing.add('title');
        if (!entities.containsKey('date')) missing.add('date');
        if (!entities.containsKey('time')) missing.add('time');
        break;
      case 'add_reminder_partial':
        if (!entities.containsKey('title')) missing.add('title');
        if (!entities.containsKey('remindAt')) missing.add('remindAt');
        break;
      case 'add_expense_partial':
        if (!entities.containsKey('description')) missing.add('description');
        if (!entities.containsKey('amount')) missing.add('amount');
        break;
    }
    
    return missing;
  }

  @override
  String toString() {
    return 'ConversationContext(sessionId: $sessionId, commandCount: ${conversationHistory.length})';
  }
}
