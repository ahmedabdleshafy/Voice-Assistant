import 'package:intl/intl.dart';
import '../database_helper.dart';
import '../models/intent_result.dart';
import '../models/conversation_context.dart';
import 'ai_service.dart';

/// Processes voice commands and executes corresponding database operations
class CommandProcessor {
  static final CommandProcessor _instance = CommandProcessor._internal();
  factory CommandProcessor() => _instance;
  CommandProcessor._internal();

  final DatabaseHelper _dbHelper = DatabaseHelper();
  final AIService _aiService = AIService();

  /// Process a voice command and execute the appropriate action
  Future<String> processCommand(String voiceText) async {
    try {
      // Get intent from AI service
      final intentResult = await _aiService.processVoiceInput(voiceText);
      
      if (intentResult.isError) {
        return intentResult.errorMessage ?? 'حدث خطأ في معالجة الأمر';
      }

      // Process based on intent
      switch (intentResult.intent) {
        case 'add_appointment':
          return await _handleAddAppointment(intentResult);
        case 'add_reminder':
          return await _handleAddReminder(intentResult);
        case 'add_expense':
          return await _handleAddExpense(intentResult);
        case 'show_appointments':
          return await _handleShowAppointments(intentResult);
        case 'show_reminders':
          return await _handleShowReminders(intentResult);
        case 'show_expenses':
          return await _handleShowExpenses(intentResult);
        case 'delete_appointment':
          return await _handleDeleteAppointment(intentResult);
        case 'weather':
          return await _handleWeatherRequest(intentResult);
        case 'time':
          return _handleTimeRequest();
        case 'date':
          return _handleDateRequest();
        case 'calculate':
          return await _handleCalculation(intentResult);
        default:
          return _handleUnknownCommand(intentResult);
      }
    } catch (e) {
      return 'عذراً، حدث خطأ في معالجة طلبك: $e';
    }
  }

  /// Handle adding a new appointment
  Future<String> _handleAddAppointment(IntentResult intent) async {
    final entities = intent.entities;
    
    // Check if we have all required information
    final title = entities['description'] ?? entities['title'];
    final dateStr = entities['date'];
    final timeStr = entities['time'];
    
    if (title == null) {
      return 'ما هو عنوان الموعد؟';
    }
    
    if (dateStr == null) {
      return 'في أي تاريخ تريد الموعد؟';
    }
    
    if (timeStr == null) {
      return 'في أي وقت تريد الموعد؟';
    }
    
    try {
      // Parse date and time
      final date = _parseDate(dateStr);
      final time = _parseTime(timeStr);
      
      // Insert appointment into database
      await _dbHelper.insertAppointment({
        'title': title,
        'date': date,
        'time': time,
      });
      
      return 'تم إضافة الموعد بنجاح: $title في $date الساعة $time';
    } catch (e) {
      return 'عذراً، لم أتمكن من إضافة الموعد. تأكد من صحة التاريخ والوقت.';
    }
  }

  /// Handle adding a new reminder
  Future<String> _handleAddReminder(IntentResult intent) async {
    final entities = intent.entities;
    
    final title = entities['description'] ?? entities['title'];
    final remindAt = entities['remindAt'] ?? _combineDateTime(entities['date'], entities['time']);
    
    if (title == null) {
      return 'ما هو التذكير؟';
    }
    
    if (remindAt == null) {
      return 'متى تريد التذكير؟';
    }
    
    try {
      await _dbHelper.insertReminder({
        'title': title,
        'remindAt': remindAt,
      });
      
      return 'تم إضافة التذكير بنجاح: $title';
    } catch (e) {
      return 'عذراً، لم أتمكن من إضافة التذكير.';
    }
  }

  /// Handle adding a new expense
  Future<String> _handleAddExpense(IntentResult intent) async {
    final entities = intent.entities;
    
    final description = entities['description'];
    final amount = entities['amount'];
    final category = entities['category'];
    
    if (description == null) {
      return 'ما هو وصف المصروف؟';
    }
    
    if (amount == null) {
      return 'كم المبلغ؟';
    }
    
    try {
      final amountValue = double.parse(amount.toString());
      final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
      
      await _dbHelper.insertExpense({
        'description': description,
        'amount': amountValue,
        'category': category ?? 'عام',
        'date': today,
      });
      
      return 'تم إضافة المصروف بنجاح: $description - $amountValue ريال';
    } catch (e) {
      return 'عذراً، لم أتمكن من إضافة المصروف. تأكد من صحة المبلغ.';
    }
  }

  /// Handle showing appointments
  Future<String> _handleShowAppointments(IntentResult intent) async {
    try {
      final appointments = await _dbHelper.queryAllAppointments();
      
      if (appointments.isEmpty) {
        return 'لا توجد مواعيد مسجلة.';
      }
      
      final buffer = StringBuffer('مواعيدك:\n');
      for (final appointment in appointments) {
        buffer.writeln('• ${appointment['title']} - ${appointment['date']} الساعة ${appointment['time']}');
      }
      
      return buffer.toString();
    } catch (e) {
      return 'عذراً، لم أتمكن من عرض المواعيد.';
    }
  }

  /// Handle showing reminders
  Future<String> _handleShowReminders(IntentResult intent) async {
    try {
      final reminders = await _dbHelper.queryAllReminders();
      
      if (reminders.isEmpty) {
        return 'لا توجد تذكيرات مسجلة.';
      }
      
      final buffer = StringBuffer('تذكيراتك:\n');
      for (final reminder in reminders) {
        buffer.writeln('• ${reminder['title']} - ${reminder['remindAt']}');
      }
      
      return buffer.toString();
    } catch (e) {
      return 'عذراً، لم أتمكن من عرض التذكيرات.';
    }
  }

  /// Handle showing expenses
  Future<String> _handleShowExpenses(IntentResult intent) async {
    try {
      final expenses = await _dbHelper.queryAllExpenses();
      
      if (expenses.isEmpty) {
        return 'لا توجد مصاريف مسجلة.';
      }
      
      final buffer = StringBuffer('مصاريفك:\n');
      double total = 0;
      
      for (final expense in expenses) {
        final amount = expense['amount'] as double;
        total += amount;
        buffer.writeln('• ${expense['description']} - $amount ريال (${expense['date']})');
      }
      
      buffer.writeln('\nإجمالي المصاريف: $total ريال');
      
      return buffer.toString();
    } catch (e) {
      return 'عذراً، لم أتمكن من عرض المصاريف.';
    }
  }

  /// Handle deleting an appointment
  Future<String> _handleDeleteAppointment(IntentResult intent) async {
    // This would require more sophisticated entity extraction to identify which appointment to delete
    return 'ميزة حذف المواعيد ستكون متاحة قريباً. يمكنك حذف المواعيد من القائمة.';
  }

  /// Handle weather request
  Future<String> _handleWeatherRequest(IntentResult intent) async {
    // This would integrate with a weather API
    return 'ميزة الطقس ستكون متاحة قريباً. سأتمكن من إخبارك عن حالة الطقس في منطقتك.';
  }

  /// Handle time request
  String _handleTimeRequest() {
    final now = DateTime.now();
    final timeFormat = DateFormat('HH:mm');
    return 'الوقت الآن ${timeFormat.format(now)}';
  }

  /// Handle date request
  String _handleDateRequest() {
    final now = DateTime.now();
    final dateFormat = DateFormat('EEEE، dd MMMM yyyy', 'ar');
    return 'اليوم هو ${dateFormat.format(now)}';
  }

  /// Handle calculation request
  Future<String> _handleCalculation(IntentResult intent) async {
    final text = intent.originalText;
    
    // Simple calculation parser
    final numberRegex = RegExp(r'\d+\.?\d*');
    final numbers = numberRegex.allMatches(text).map((m) => double.parse(m.group(0)!)).toList();
    
    if (numbers.length < 2) {
      return 'أحتاج رقمين على الأقل للحساب.';
    }
    
    if (text.contains('+') || text.contains('زائد') || text.contains('جمع')) {
      final result = numbers.reduce((a, b) => a + b);
      return 'النتيجة: $result';
    } else if (text.contains('-') || text.contains('ناقص') || text.contains('طرح')) {
      final result = numbers.reduce((a, b) => a - b);
      return 'النتيجة: $result';
    } else if (text.contains('*') || text.contains('×') || text.contains('ضرب')) {
      final result = numbers.reduce((a, b) => a * b);
      return 'النتيجة: $result';
    } else if (text.contains('/') || text.contains('÷') || text.contains('قسمة')) {
      if (numbers.any((n) => n == 0)) {
        return 'لا يمكن القسمة على صفر.';
      }
      final result = numbers.reduce((a, b) => a / b);
      return 'النتيجة: $result';
    }
    
    return 'لم أتمكن من فهم العملية الحسابية. جرب قول "احسب 5 زائد 3" مثلاً.';
  }

  /// Handle unknown command
  String _handleUnknownCommand(IntentResult intent) {
    return 'عذراً، لم أفهم طلبك. يمكنك قول أشياء مثل:\n'
           '• "أضف موعد غداً الساعة 3"\n'
           '• "ذكرني بالاجتماع غداً"\n'
           '• "أضف مصروف 50 ريال للبنزين"\n'
           '• "اعرض مواعيدي"\n'
           '• "كم الساعة؟"';
  }

  /// Parse date string to standard format
  String _parseDate(dynamic dateInput) {
    final dateStr = dateInput.toString().toLowerCase();
    final now = DateTime.now();
    
    if (dateStr.contains('اليوم')) {
      return DateFormat('yyyy-MM-dd').format(now);
    } else if (dateStr.contains('غد') || dateStr == 'tomorrow') {
      return DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));
    } else if (dateStr.contains('بعد غد') || dateStr == 'day_after_tomorrow') {
      return DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 2)));
    }
    
    // Try to parse as date
    try {
      // Handle various date formats
      final dateRegex = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-]?(\d{2,4})?');
      final match = dateRegex.firstMatch(dateStr);
      
      if (match != null) {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final year = match.group(3) != null ? int.parse(match.group(3)!) : now.year;
        
        final date = DateTime(year, month, day);
        return DateFormat('yyyy-MM-dd').format(date);
      }
    } catch (e) {
      // Fall back to today if parsing fails
    }
    
    return DateFormat('yyyy-MM-dd').format(now);
  }

  /// Parse time string to standard format
  String _parseTime(dynamic timeInput) {
    final timeStr = timeInput.toString().toLowerCase();
    
    // Handle Arabic time expressions
    if (timeStr.contains('صباح') || timeStr.contains('ص')) {
      final numberMatch = RegExp(r'\d+').firstMatch(timeStr);
      if (numberMatch != null) {
        final hour = int.parse(numberMatch.group(0)!);
        return '${hour.toString().padLeft(2, '0')}:00';
      }
    } else if (timeStr.contains('مساء') || timeStr.contains('م')) {
      final numberMatch = RegExp(r'\d+').firstMatch(timeStr);
      if (numberMatch != null) {
        final hour = int.parse(numberMatch.group(0)!);
        final adjustedHour = hour < 12 ? hour + 12 : hour;
        return '${adjustedHour.toString().padLeft(2, '0')}:00';
      }
    }
    
    // Handle 24-hour format
    final timeRegex = RegExp(r'(\d{1,2}):?(\d{2})?');
    final match = timeRegex.firstMatch(timeStr);
    
    if (match != null) {
      final hour = int.parse(match.group(1)!);
      final minute = match.group(2) != null ? int.parse(match.group(2)!) : 0;
      return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
    }
    
    // Default to current time
    return DateFormat('HH:mm').format(DateTime.now());
  }

  /// Combine date and time strings
  String? _combineDateTime(dynamic date, dynamic time) {
    if (date == null || time == null) return null;
    
    try {
      final dateStr = _parseDate(date);
      final timeStr = _parseTime(time);
      return '$dateStr $timeStr';
    } catch (e) {
      return null;
    }
  }
}
