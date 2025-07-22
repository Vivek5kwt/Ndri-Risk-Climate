// Functions to compute final values for specific questions.

/// Calculates the capped final value for question 34.
///
/// [input] should be `1` if conflicts are present and `0` otherwise.
/// The calculation multiplies the input by the question weight (1.592334687)
/// and caps the result between 0 and the weight.
double calculateQuestion34(int input) {
  const double weight = 1.592334687;
  final double calcValue = input * weight;
  if (calcValue > weight) return weight;
  if (calcValue < 0) return 0;
  return calcValue;
}

/// Calculates the capped final value for question 35.
///
/// [years] is the number of years of membership in SHG/FIGs/FPOs/CIGs.
/// The calculation uses the maximum value of 50 and caps the result
/// between 0 and the question weight (3.87279524).
double calculateQuestion35(int years) {
  const double maxYears = 50;
  const double minYears = 0;
  const double weight = 3.87279524;

  final double ratio = (maxYears - years) / (maxYears - minYears);
  final double calcValue = ratio;

  if (calcValue > weight) return weight;
  if (calcValue < 0) return 0;
  return calcValue;
}
