import 'package:flutter/material.dart';

import 'data/models/question_model.dart';
import 'screens/preview_answers_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preview Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<QuestionModel> _questions = [
    QuestionModel(variableNumber: 'q1', questionText: 'What is your name?'),
    QuestionModel(variableNumber: 'q2', questionText: 'Where do you live?'),
  ];

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, FocusNode> _focusNodes = {};
  final ScrollController _scrollController = ScrollController();

  static const double _itemExtent = 100;

  @override
  void initState() {
    super.initState();
    for (final q in _questions) {
      _controllers[q.variableNumber] = TextEditingController();
      _focusNodes[q.variableNumber] = FocusNode();
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    for (final node in _focusNodes.values) {
      node.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _jumpToQuestion(String variableNumber) {
    final index = _questions.indexWhere((q) => q.variableNumber == variableNumber);
    if (index >= 0) {
      _scrollController.animateTo(
        index * _itemExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      _focusNodes[variableNumber]!.requestFocus();
    }
  }

  void _openPreview() {
    final answers = <String, String>{};
    for (final q in _questions) {
      answers[q.variableNumber] = _controllers[q.variableNumber]!.text;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PreviewAnswersScreen(
          allAnswers: answers,
          allQuestions: _questions,
          onEdit: _jumpToQuestion,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Answer Questions')),
      body: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        itemCount: _questions.length,
        itemExtent: _itemExtent,
        itemBuilder: (context, index) {
          final q = _questions[index];
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              controller: _controllers[q.variableNumber],
              focusNode: _focusNodes[q.variableNumber],
              decoration: InputDecoration(
                labelText: '${index + 1}. ${q.questionText}',
                border: const OutlineInputBorder(),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: _openPreview,
          child: const Text('Preview'),
        ),
      ),
    );
  }
}
