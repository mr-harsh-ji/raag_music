import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:raag_music/screens/splash.dart';
import 'package:raag_music/services/audio_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'App Themes/theme_provider.dart';
import 'locals/language_provider.dart';
import 'screens/bottom_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set memory cache limits to prevent OOM
  PaintingBinding.instance.imageCache.maximumSizeBytes = 50 * 1024 * 1024; // 50 MB

  await Permission.notification.request();

  final languageProvider = LanguageProvider();
  GetIt.instance.registerSingleton<LanguageProvider>(languageProvider);
  
  final audioHandler = await initAudioService();
  GetIt.instance.registerSingleton<AudioHandler>(audioHandler);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider.value(value: languageProvider),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString('languageCode') ?? 'en';
    GetIt.instance<LanguageProvider>().changeLanguage(Locale(languageCode));
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, theme, language, _) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Raag Music',
        theme: theme.themeData,
        locale: language.appLocale,
        supportedLocales: const [
          Locale('en', ''),
          Locale('hi', ''),
          Locale('ur', ''),
        ],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: const Splash(),
      );
    });
  }
}
