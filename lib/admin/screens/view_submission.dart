import 'package:flutter/material.dart';

import '../../data/models/question_model.dart';
import '../../data/repositories/question_repository.dart';
import '../models/survey_submission.dart';

class ViewSubmissionPage extends StatefulWidget {
  final SurveySubmission submission;

  const ViewSubmissionPage({super.key, required this.submission});

  @override
  State<ViewSubmissionPage> createState() => _ViewSubmissionPageState();
}

class _ViewSubmissionPageState extends State<ViewSubmissionPage> {
  late final List<QuestionModel> _questions;
  late final ScrollController _scrollCtrl;
  late final Map<String, dynamic> _flatAns;
  bool _showFab = false;

  @override
  void initState() {
    super.initState();
    _questions = QuestionRepository.getQuestions();

    /* flatten answers {vulnerability|exposure} → single map */
    _flatAns = {};
    widget.submission.answers.forEach((k, v) {
      if (v is Map) {
        v.forEach((kk, vv) => _flatAns[kk.toString()] = vv);
      } else {
        _flatAns[k.toString()] = v;
      }
    });

    _scrollCtrl = ScrollController()
      ..addListener(() {
        if (_scrollCtrl.offset > 300 && !_showFab) {
          setState(() => _showFab = true);
        } else if (_scrollCtrl.offset <= 300 && _showFab) {
          setState(() => _showFab = false);
        }
      });
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _downloadReport() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Download')),
    );
  }

  /* ───────────── BASIC INFO + ADDRESS CARD ───────────── */
  Widget _basicInfoCard() {
    final theme = Theme.of(context);
    String v(String key) => _flatAns[key]?.toString() ?? '—';
    final s = widget.submission;

    Widget row(String label, String value, IconData ic) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(ic, size: 18, color: const Color(0xFF0e86d4)),
            const SizedBox(width: 6),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: Colors.grey.shade800),
                  children: [
                    TextSpan(
                        text: '$label: ',
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(text: value),
                  ],
                ),
              ),
            ),
          ],
        );

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Basic Information',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0e86d4))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      row('Name', v('1'), Icons.person),
                      const SizedBox(height: 10),
                      row('Gender', v('2'), Icons.wc),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      row('Age', v('3'), Icons.cake_outlined),
                      const SizedBox(height: 10),
                      row('Education', v('4'), Icons.school),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 28),
            Text('Address',
                style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0e86d4))),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      row('Village', s.village, Icons.home_work_outlined),
                      const SizedBox(height: 10),
                      row('Block', s.block, Icons.location_city),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      row('District', s.district, Icons.map_outlined),
                      const SizedBox(height: 10),
                      row('State', s.state, Icons.public),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /* ───────────── build ───────────── */
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Stack(
          children: [
            ClipPath(
              clipper: _CurvedClipper(),
              child: Container(
                height: 120,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF0e86d4), Color(0xFF01949a)],
                  ),
                ),
              ),
            ),
            Container(height: 120, color: Colors.white.withOpacity(0.06)),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon:
                            const Icon(Icons.arrow_back, color: Colors.white)),
                    const SizedBox(width: 4),
                    const Text('View Submission',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    IconButton(
                        tooltip: 'Download report',
                        onPressed: _downloadReport,
                        icon: const Icon(Icons.download_rounded,
                            color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton.extended(
              heroTag: 'toTop',
              backgroundColor: const Color(0xFF0e86d4),
              foregroundColor: Colors.white,
              onPressed: () => _scrollCtrl.animateTo(0,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut),
              icon: const Icon(Icons.arrow_upward),
              label: const Text('Top'),
            )
          : null,

      /* LIST */
      body: ListView.separated(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        itemCount: _questions.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, index) {
          if (index == 0) return _basicInfoCard();

          final q = _questions[index - 1];
          final ans = _flatAns[q.variableNumber] ?? '—';

          return Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Color(0xFF0e86d4), Color(0xFF01949a)],
                          ),
                        ),
                        child: Text(q.variableNumber,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(q.questionText,
                            style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.grey.shade800)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  /* Answer label */
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline,
                          size: 16, color: Color(0xFF0e86d4)),
                      const SizedBox(width: 4),
                      Text('Answer',
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0e86d4))),
                    ],
                  ),
                  const SizedBox(height: 6),

                  /* answer value */
                  Text('$ans',
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.black87, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 18),

                  /* footer */
                  Row(
                    children: [
                      Chip(
                        label: Text(q.category.toString()),
                        backgroundColor: const Color(0xFFE8F3FF),
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                      const Spacer(),
                      Text(q.questionType!.name.toUpperCase(),
                          style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/* curved bottom clipper */
class _CurvedClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path()
      ..lineTo(0, size.height - 30)
      ..quadraticBezierTo(
          size.width * 0.5, size.height, size.width, size.height - 30)
      ..lineTo(size.width, 0)
      ..close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
