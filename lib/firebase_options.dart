// File generated by FlutterFire CLI.
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAROqBSVeckNtmmobT6OPIGLMnAtnZvgfY',
    appId: '1:373265416191:web:f6da9324cfb14b998b71ca',
    messagingSenderId: '373265416191',
    projectId: 'hijos-de-fluttarkia',
    authDomain: 'hijos-de-fluttarkia.firebaseapp.com',
    storageBucket: 'hijos-de-fluttarkia.firebasestorage.app',
    measurementId: 'G-FC5YKXJXMJ',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCngQCPohzmnj3BMslR_dfk3P-6OHVD5xE',
    appId: '1:373265416191:android:f1be60df1af557518b71ca',
    messagingSenderId: '373265416191',
    projectId: 'hijos-de-fluttarkia',
    storageBucket: 'hijos-de-fluttarkia.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB4jRfN4hbJTQDUy3YH81UGTx9WZMUnHXM',
    appId: '1:373265416191:ios:1742845ccaaea4028b71ca',
    messagingSenderId: '373265416191',
    projectId: 'hijos-de-fluttarkia',
    storageBucket: 'hijos-de-fluttarkia.firebasestorage.app',
    iosBundleId: 'com.example.fluttarkia.hijosDeFluttarkia',
  );

}