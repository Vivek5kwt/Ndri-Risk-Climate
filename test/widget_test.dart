import 'package:flutter_test/flutter_test.dart';
import 'package:ndri_dairy_risk/logic/score_calculate/question_weight.dart';

void main() {
  test('exposure input produces a bounded nonnegative score', () {
    final score = computeFinalValueForInput('2', '20');
    expect(score, isNotNull);
    expect(score!, greaterThanOrEqualTo(0));
  });
}
