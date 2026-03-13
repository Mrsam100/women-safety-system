import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:saferide/app.dart';
import 'package:saferide/core/services/local_storage_service.dart';
import 'package:saferide/core/utils/logger.dart';
import 'package:saferide/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive local storage
  final localStorage = LocalStorageService();
  await localStorage.initialize();

  AppLogger.info('App initialized', tag: 'Main');

  runApp(
    const ProviderScope(
      child: SafeRideApp(),
    ),
  );
}
