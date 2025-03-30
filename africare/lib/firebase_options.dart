import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR-WEB-API-KEY',
    appId: 'YOUR-WEB-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'africare-health',
    authDomain: 'africare-health.firebaseapp.com',
    storageBucket: 'africare-health.appspot.com',
    measurementId: 'YOUR-MEASUREMENT-ID',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR-ANDROID-API-KEY',
    appId: 'YOUR-ANDROID-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'africare-health',
    storageBucket: 'africare-health.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR-IOS-API-KEY',
    appId: 'YOUR-IOS-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'africare-health',
    storageBucket: 'africare-health.appspot.com',
    iosClientId: 'YOUR-IOS-CLIENT-ID',
    iosBundleId: 'com.example.africare',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'YOUR-MACOS-API-KEY',
    appId: 'YOUR-MACOS-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'africare-health',
    storageBucket: 'africare-health.appspot.com',
    iosClientId: 'YOUR-MACOS-CLIENT-ID',
    iosBundleId: 'com.example.africare',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'YOUR-WINDOWS-API-KEY',
    appId: 'YOUR-WINDOWS-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'africare-health',
    storageBucket: 'africare-health.appspot.com',
  );

  static const FirebaseOptions linux = FirebaseOptions(
    apiKey: 'YOUR-LINUX-API-KEY',
    appId: 'YOUR-LINUX-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'africare-health',
    storageBucket: 'africare-health.appspot.com',
  );
}
