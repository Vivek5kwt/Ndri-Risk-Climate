import 'package:flutter/material.dart';

import '../../data/models/question_model.dart';

class PreviewAnswersScreen extends StatelessWidget {
  final Map<String, String> allAnswers;
  final List<QuestionModel> allQuestions;
  final Function(String variableNumber) onEdit;

  const PreviewAnswersScreen({
    Key? key,
    required this.allAnswers,
    required this.allQuestions,
    required this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Answers'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: allQuestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final question = allQuestions[index];
          final answer = allAnswers[question.variableNumber] ?? 'Not Answered';

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                '${index + 1}. ${question.questionText}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Your Answer: $answer'),
              trailing: IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue),
                onPressed: () {
                  onEdit(question.variableNumber);
                  Navigator.pop(context);
                },
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Submit'),
                content: const Text('Are you sure you want to submit?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                    child: const Text('Submit'),
                  ),
                ],
              ),
            );
          },
          child: const Text('Submit All Answers'),
        ),
      ),
    );
  }
}
