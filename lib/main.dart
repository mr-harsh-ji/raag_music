import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:raag_music/services/audio_handler.dart';

import 'My App Themes/theme_provider.dart';
import 'screens/bottom_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Permission.notification.request();
  GetIt.instance.registerSingleton<AudioHandler>(await initAudioService());
  runApp(ChangeNotifierProvider(
    create: (_) => ThemeProvider(),
    child: const MyApp(),
  ),);
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
        builder: (context, theme, _) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Raag Music',
            theme: theme.themeData,
            home: const BottomNavigationScreen(),
          );
        }
    );
  }
}
