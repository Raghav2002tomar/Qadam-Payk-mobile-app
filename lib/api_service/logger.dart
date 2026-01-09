import 'package:flutter/foundation.dart';

void appLog(Object? message) {
  if (!kReleaseMode) {
    print("🔍 LOG: $message");
  }
}

void initAppLogger() {
  // Override debugPrint globally
  debugPrint = (String? message, {int? wrapWidth}) => appLog(message);

  // Override print() globally
  FlutterError.onError = (FlutterErrorDetails details) {
    appLog(details.exceptionAsString());
  };
}