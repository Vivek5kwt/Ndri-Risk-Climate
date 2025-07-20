# Ndri Risk Climate App

This repository now includes a Flutter screen for previewing answers before submission.

The new screen is located at `mobile_app/lib/screens/preview_answers_screen.dart` and allows users to review and edit their responses.

## Accepted Values

Each question now stores a `finalValue`. An additional `acceptedValue` is derived
from this. If the `finalValue` is negative, `acceptedValue` defaults to `0`.
Both values are displayed on the preview screen.
