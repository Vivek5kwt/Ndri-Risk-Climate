# Ndri Risk Climate App

This repository now includes a Flutter screen for previewing answers before submission.

The new screen is located at `mobile_app/lib/screens/preview_answers_screen.dart` and allows users to review and edit their responses.

## Accepted Values

Each question now stores a `finalValue`. An additional `acceptedValue` is derived
from this. If the `finalValue` is negative, `acceptedValue` defaults to `0`.
Both values are displayed on the preview screen.

## Question Calculations

The repository now includes utility functions for calculating the
`finalValue` of specific questions. These can be found in
`mobile_app/lib/data/question_formulas.dart`.

- **Question 34** represents the presence of water or land related conflicts.
  Provide `1` for "Yes" and `0` for "No". The result is capped between
  `0` and the question's weight (`1.592334687`).
- **Question 35** represents the number of years of membership in
  SHG/FIGs/FPOs/CIGs. The calculation uses a maximum of `50` years and
  returns a value capped at `3.87279524`.

These functions can be integrated wherever the application needs to
compute final values for these questions.
