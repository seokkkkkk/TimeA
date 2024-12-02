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
        return macos;
      case TargetPlatform.windows:
        return windows;
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
    apiKey: 'AIzaSyCBtKMX9ao_LFiNeynlg4fkgfmUZRDoncQ',
    appId: '1:307660930243:web:303b424650a0637ae7f676',
    messagingSenderId: '307660930243',
    projectId: 'time-a-42e3d',
    authDomain: 'time-a-42e3d.firebaseapp.com',
    storageBucket: 'time-a-42e3d.firebasestorage.app',
    measurementId: 'G-T1BK7294MB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCndtSHXGbIlUnTU-ZGg7T_scUI527h0e8',
    appId: '1:307660930243:android:38462c11363f396ce7f676',
    messagingSenderId: '307660930243',
    projectId: 'time-a-42e3d',
    storageBucket: 'time-a-42e3d.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCoDlJZXsas6D1zQCyGgto-Ag-4zByuCGY',
    appId: '1:307660930243:ios:9e402da6e9686fcfe7f676',
    messagingSenderId: '307660930243',
    projectId: 'time-a-42e3d',
    storageBucket: 'time-a-42e3d.firebasestorage.app',
    iosBundleId: 'com.timea.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCoDlJZXsas6D1zQCyGgto-Ag-4zByuCGY',
    appId: '1:307660930243:ios:9e402da6e9686fcfe7f676',
    messagingSenderId: '307660930243',
    projectId: 'time-a-42e3d',
    storageBucket: 'time-a-42e3d.firebasestorage.app',
    iosBundleId: 'com.timea.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCBtKMX9ao_LFiNeynlg4fkgfmUZRDoncQ',
    appId: '1:307660930243:web:9ac34829a389eabde7f676',
    messagingSenderId: '307660930243',
    projectId: 'time-a-42e3d',
    authDomain: 'time-a-42e3d.firebaseapp.com',
    storageBucket: 'time-a-42e3d.firebasestorage.app',
    measurementId: 'G-J8NRN4NB6D',
  );

}