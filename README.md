# ndri_dairy_risk

## Android Play release handoff

The Android app ID is `com.ndri.dairyrisk`. The current `pubspec.yaml`
version is `1.0.0+8`; confirm that build number 8 has never been uploaded to
Play Console before using it. Raise the build number if it has.

On the build computer, install a compatible Flutter SDK, Android SDK/NDK, and
JDK 17. Supply the **existing Play upload keystore**, not a new or debug key.
Create the ignored `android/key.properties` locally with `keyAlias`,
`keyPassword`, `storeFile`, and `storePassword` pointing to that keystore.
Never commit the keystore or this file. Release builds now fail if signing is
missing. Then run:

```sh
flutter pub get
flutter test
flutter build appbundle --release
```

Before submission, verify the generated bundle is signed by the correct upload
certificate and inspect its merged manifest for restricted permissions. The
app uses Android's document picker (`ACTION_CREATE_DOCUMENT`) to save a PDF,
and does not require `MANAGE_EXTERNAL_STORAGE`. Test report saving and opening
on a physical Android device. The Android configuration uses NDK 28 and a
16 KB-compatible bundle alignment; check the **newly built** AAB in Play
Console's App Bundle Explorer too.

## Play Console / website actions outside this repository

- Update the public `https://ndrics.in/privacy-policy` page so it explicitly
  identifies **Socio-Climatic Risk Calculator** and the exact developer/legal
  entity shown in Play Console. Describe the actual survey, Firebase, report,
  retention, sharing, and contact practices; remove generic claims that do not
  apply. The website is not hosted from this repository.
- Recheck the Play Console Data Safety and All Files Access declarations so
  they match the newly built AAB and the updated privacy policy.
- Check the new release's 16 KB page-size result and test it on a compatible
  device or emulator where available. Only Google can determine final policy
  approval.

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
