import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finsquare_mobile_app/app.dart';
import 'package:finsquare_mobile_app/core/services/notification_service.dart';
import 'package:finsquare_mobile_app/core/services/app_startup_service.dart';
import 'package:finsquare_mobile_app/core/services/deep_link_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize notification service
  await NotificationService.instance.initialize();

  // Initialize deep link service
  final deepLinkService = DeepLinkService();
  await deepLinkService.initialize();

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        deepLinkServiceProvider.overrideWithValue(deepLinkService),
      ],
      child: const FinSquareApp(),
    ),
  );
}
