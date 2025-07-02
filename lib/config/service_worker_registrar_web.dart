import 'dart:html' as html;

import 'package:flutter/foundation.dart';

Future<void> registerServiceWorker() async {
  try {
    await html.window.navigator.serviceWorker?.register('firebase-messaging-sw.js');
    if (kDebugMode) {
      print('✅ Service worker registered');
    }
  } catch (e) {
    if (kDebugMode) {
      print('⚠️ Service worker registration failed: $e');
    }
  }
}
