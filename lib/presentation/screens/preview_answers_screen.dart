
import 'package:flutter/material.dart';
import '../../data/models/question_model.dart';

class PreviewAnswersScreen extends StatelessWidget {
  final Map<String, String> allAnswers;
  final List<QuestionModel> allQuestions;
  final VoidCallback onEditFirstQuestion;
  final VoidCallback onSubmit;

  // Questions that expect yes/no answers stored as 1 or 0.
  static const Set<String> yesNoVars = {
    '34',
    '46.1',
    '46.2',
    '46.3',
    '46.4',
    '46.5',
    '46.6',
    '46.7',
    '46.8',
    '46.9',
    '46.10',
    '46.11',
    '46.12',
    '46.13',
    '46.14',
    '46.15',
    '46.16',
  };

  const PreviewAnswersScreen({
    super.key,
    required this.allAnswers,
    required this.allQuestions,
    required this.onEditFirstQuestion,
    required this.onSubmit,
  });

  // Robust variable number sorting
  List<QuestionModel> getSortedQuestions() {
    List<QuestionModel> sorted = List<QuestionModel>.from(allQuestions);
    sorted.sort((a, b) {
      List<String> aParts = a.variableNumber.split('.');
      List<String> bParts = b.variableNumber.split('.');
      int aMain = int.tryParse(aParts[0]) ?? 0;
      int bMain = int.tryParse(bParts[0]) ?? 0;
      if (aMain != bMain) return aMain.compareTo(bMain);
      // Now compare sub-parts (handles e.g. 13.10 > 13.2)
      if (aParts.length > 1 && bParts.length > 1) {
        int aSub = int.tryParse(aParts[1]) ?? 0;
        int bSub = int.tryParse(bParts[1]) ?? 0;
        return aSub.compareTo(bSub);
      }
      if (aParts.length > 1) return 1;
      if (bParts.length > 1) return -1;
      return 0;
    });
    return sorted;
  }

  @override
  Widget build(BuildContext context) {
    final List<QuestionModel> sortedQuestions = getSortedQuestions();

    return Scaffold(
      backgroundColor: const Color(0xfff8f6f1),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.brown.shade700,
        elevation: 0,
        title: const Text(
          'Preview Answers',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          Positioned(
            bottom: -40,
            right: -30,
            child: Opacity(
              opacity: 0.07,
              child: Image.asset(
                'assets/images/ndri_cow.png',
                height: 220,
                fit: BoxFit.contain,
              ),
            ),
          ),
          ListView.separated(
            padding: const EdgeInsets.fromLTRB(14, 130, 14, 110),
            itemCount: sortedQuestions.length,
            separatorBuilder: (_, __) => const SizedBox(height: 15),
            itemBuilder: (context, index) {
              final question = sortedQuestions[index];
              // --- This is the fix: always get answer using variableNumber! ---
              final rawAnswer = allAnswers[question.variableNumber]?.toString() ?? 'Not Answered';
              // For yes/no questions convert stored 1/0 values into
              // human readable "Yes"/"No". Other questions may legitimately
              // use numeric answers like 0 or 1 (e.g. rating scale), so
              // we leave those values untouched.
              final answer = yesNoVars.contains(question.variableNumber)
                  ? (rawAnswer == '1'
                      ? 'Yes'
                      : rawAnswer == '0'
                          ? 'No'
                          : rawAnswer)
                  : rawAnswer;

              final Color cardColor = (index % 2 == 0)
                  ? Colors.yellow.shade50
                  : Colors.green.shade50.withOpacity(0.97);
              final Color leftBarColor = (index % 2 == 0)
                  ? Colors.green.shade700
                  : Colors.orange.shade700;
              final Color answerBoxColor = answer == 'Not Answered'
                  ? Colors.red.shade50
                  : Colors.green.shade50.withOpacity(0.97);

              final bool isSubQuestion = question.variableNumber.contains('.');
              return AnimatedContainer(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                margin: EdgeInsets.only(left: isSubQuestion ? 25 : 0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cardColor,
                      cardColor.withOpacity(0.75),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: leftBarColor.withOpacity(0.19),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: leftBarColor.withOpacity(0.07),
                      blurRadius: 15,
                      offset: const Offset(0, 7),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Left vertical color bar
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 31,
                        decoration: BoxDecoration(
                          color: leftBarColor,
                          borderRadius: BorderRadius.circular(17),
                        ),
                        child: Center(
                          child: CircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 13,
                            child: Text(
                              question.variableNumber,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: leftBarColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 36, right: 16, top: 16, bottom: 13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question
                          Text(
                            '${question.variableNumber}. ${question.questionText}',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15.6,
                              color: leftBarColor,
                              height: 1.22,
                              letterSpacing: 0.04,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Answer row
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInCubic,
                            decoration: BoxDecoration(
                              color: answerBoxColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: answer == 'Not Answered'
                                    ? Colors.red.shade200
                                    : leftBarColor.withOpacity(0.23),
                                width: 1.15,
                              ),
                              boxShadow: answer == 'Not Answered'
                                  ? [
                                BoxShadow(
                                  color: Colors.red.shade100.withOpacity(0.19),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                                  : [
                                BoxShadow(
                                  color: leftBarColor.withOpacity(0.12),
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7.5),
                            child: Row(
                              children: [
                                Icon(
                                  answer == 'Not Answered'
                                      ? Icons.error_outline_rounded
                                      : Icons.check_circle_rounded,
                                  color: answer == 'Not Answered'
                                      ? Colors.red.shade400
                                      : leftBarColor,
                                  size: 19,
                                ),
                                const SizedBox(width: 7),
                                Expanded(
                                  child: Text(
                                    answer,
                                    style: TextStyle(
                                      color: answer == 'Not Answered'
                                          ? Colors.red.shade700
                                          : Colors.brown.shade800,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14.8,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.brown.shade100.withOpacity(0.32),
              blurRadius: 14,
              offset: const Offset(0, -3),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Row(
          children: [
            Expanded(
              child: AnimatedButton(
                label: "Edit Answers",
                icon: Icons.edit_rounded,
                onPressed: onEditFirstQuestion,
                gradient: const LinearGradient(
                  colors: [Color(0xfff8f6f1), Colors.white],
                ),
                borderColor: Colors.brown,
                textColor: Colors.brown,
                iconColor: Colors.brown,
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: AnimatedButton(
                label: "Submit",
                icon: Icons.check_rounded,
                onPressed: () async {
                  await _showSubmitResultDialog(context);
                  onSubmit();
                },
                gradient: const LinearGradient(
                  colors: [
                    Color(0xff9b664a),
                    Color(0xffa6741b),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderColor: Colors.brown,
                textColor: Colors.white,
                iconColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Animated gradient button widget for creative touch ---
class AnimatedButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Gradient gradient;
  final Color borderColor;
  final Color textColor;
  final Color iconColor;

  const AnimatedButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    required this.gradient,
    required this.borderColor,
    required this.textColor,
    required this.iconColor,
  });

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton>
    with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _scale = 0.97),
      onPointerUp: (_) => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 80),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: widget.borderColor, width: 2),
            boxShadow: [
              BoxShadow(
                color: widget.borderColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 13),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(widget.icon, color: widget.iconColor, size: 21),
                    const SizedBox(width: 8),
                    Text(
                      widget.label,
                      style: TextStyle(
                        color: widget.textColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 15.2,
                        letterSpacing: 0.08,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- Submit dialog logic ---
Future<void> _showSubmitResultDialog(BuildContext context) async {
  final shouldSubmit = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline_rounded,
                size: 60, color: Colors.amber),
            const SizedBox(height: 16),
            const Text(
              'Are you sure to submit?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Once submitted, you cannot make changes.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  label: const Text("Cancel"),
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle),
                  label: const Text("Yes"),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ),
  );
  if (shouldSubmit != true) return;
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.white,
      elevation: 14,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 34),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedScale(
                  scale: 1,
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.elasticOut,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Colors.green, Colors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.verified_rounded,
                        color: Colors.white, size: 58),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "Thank you for your submission!",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.orange.shade800,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 14),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: "Your answers have been securely submitted.\n\n",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                          fontSize: 15.2,
                        ),
                      ),
                      TextSpan(
                        text: "Please note:\n",
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const TextSpan(
                        text:
                        "• Your responses are final and cannot be edited.\n"
                            "• Your socio-climatic risk result has been calculated based on your answers.",
                        style: TextStyle(
                          color: Colors.black87,
                          fontSize: 15,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    if (context.mounted) {
                      (context as Element).markNeedsBuild();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepOrange,
                    padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 8,
            top: 8,
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                splashColor: Colors.red.withOpacity(0.15),
                onTap: () {
                  Navigator.of(ctx).pop();
                },
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child:
                  Icon(Icons.close_rounded, color: Colors.red, size: 28),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
