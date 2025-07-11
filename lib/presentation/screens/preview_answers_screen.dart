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
        title: const Text("Preview Answers"),
      ),
      body: ListView.separated(
        itemCount: allQuestions.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final question = allQuestions[index];
          final answer = allAnswers[question.variableNumber] ?? "Not Answered";

          return ListTile(
            title: Text(
              "${index + 1}. ${question.questionText}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text("Your Answer: $answer"),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                // Call back to main screen to jump to that question
                onEdit(question.variableNumber);
                Navigator.pop(context); // Go back to the question screen
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ElevatedButton(
          onPressed: () {
            // Submit or confirm
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Submit"),
                content: const Text("Are you sure you want to submit?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Cancel"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context); // Close dialog
                      Navigator.pop(context); // Back to question screen
                      // You can trigger submit here
                    },
                    child: const Text("Submit"),
                  ),
                ],
              ),
            );
          },
          child: const Text("Submit All Answers"),
        ),
      ),
    );
  }
}
