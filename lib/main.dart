import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'services/ai_service.dart';
import 'services/command_processor.dart';

void main() {
  runApp(const RafiqApp());
}

class RafiqApp extends StatelessWidget {
  const RafiqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'رفيق',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.black,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.system, // Automatically switch based on system settings
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  final AIService _aiService = AIService();
  final CommandProcessor _commandProcessor = CommandProcessor();
  
  bool _speechEnabled = false;
  String _lastWords = '';
  String _statusText = ''; // To display status and error messages
  String _responseText = ''; // AI response text
  bool _isProcessing = false; // Show processing indicator

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initAIService();
  }

  /// Initialize AI service
  void _initAIService() async {
    try {
      await _aiService.initialize();
      setState(() {
        _statusText = 'AI service initialized';
      });
    } catch (e) {
      setState(() {
        _statusText = 'AI service failed to initialize: $e';
      });
    }
  }

  /// This has to happen only once per app
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => setState(() {
        _statusText = 'Error: ${error.errorMsg}';
      }),
      onStatus: (status) => setState(() {
        _statusText = 'Status: $status';
      }),
    );
    setState(() {});
  }

  /// Each time to start a speech recognition session
  void _startListening() async {
    await _speechToText.listen(onResult: _onSpeechResult, localeId: 'ar_SA');
    setState(() {});
  }

  /// Manually stop the active speech recognition session
  void _stopListening() async {
    await _speechToText.stop();
    setState(() {});
  }

  /// This is the callback that the SpeechToText plugin calls when
  /// the platform returns recognized words.
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
    });

    // After recognition, process with AI and execute command
    if (result.finalResult && _lastWords.isNotEmpty) {
      _processVoiceCommand(_lastWords);
    }
  }

  /// Process voice command using AI service and command processor
  void _processVoiceCommand(String voiceText) async {
    setState(() {
      _isProcessing = true;
      _statusText = 'معالجة الأمر...';
      _responseText = '';
    });

    try {
      // Process command and get response
      final response = await _commandProcessor.processCommand(voiceText);
      
      setState(() {
        _responseText = response;
        _statusText = 'تم تنفيذ الأمر';
        _isProcessing = false;
      });

      // Speak the response
      await _speak(response);
      
    } catch (e) {
      setState(() {
        _responseText = 'عذراً، حدث خطأ في معالجة طلبك';
        _statusText = 'خطأ: $e';
        _isProcessing = false;
      });
      
      await _speak('عذراً، حدث خطأ في معالجة طلبك');
    }
  }

  Future<void> _speak(String text) async {
    await _flutterTts.setLanguage("ar-SA");
    await _flutterTts.speak(text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رفيق', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // TODO: Show conversation history
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Spacer(),
            
            // Voice input display
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Text(
                    'ما قلته:',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _speechToText.isListening
                        ? (_lastWords.isEmpty ? 'استمع...' : _lastWords)
                        : _speechEnabled
                            ? (_lastWords.isEmpty ? 'اضغط على الميكروفون للبدء' : _lastWords)
                            : 'الميكروفون غير متاح. $_statusText',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // AI Response display
            if (_responseText.isNotEmpty || _isProcessing)
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.smart_toy,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'رفيق يجيب:',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_isProcessing)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'معالجة...',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        _responseText,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                            ),
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            
            const SizedBox(height: 30),
            // This will be our main interaction button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                // Change color when listening
                color: _speechToText.isNotListening
                    ? Theme.of(context).colorScheme.primary
                    : Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: (_speechToText.isNotListening
                            ? Theme.of(context).colorScheme.primary
                            : Colors.red)
                        .withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: IconButton(
                // Start or stop listening when the button is pressed
                onPressed: _speechToText.isNotListening ? _startListening : _stopListening,
                icon: const Icon(Icons.mic, color: Colors.white, size: 48),
                iconSize: 72,
                padding: const EdgeInsets.all(24),
              ),
            ),
            const Spacer(),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}
