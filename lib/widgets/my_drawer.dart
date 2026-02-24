import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:raag_music/screens/bottom_navigation_screen.dart';
import 'package:raag_music/screens/Library%20Screen/my_music_screen.dart';
import 'package:raag_music/screens/Library%20Screen/playlists_screen.dart';
import 'package:raag_music/screens/settings_screen.dart';
import 'package:raag_music/services/audio_handler.dart';

import '../locals/string_extension.dart';
import '../screens/about_screen.dart';

class MyDrawer extends StatelessWidget {
  const MyDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final audioHandler = GetIt.instance<AudioHandler>() as MyAudioHandler;
    return Drawer(
      child: Container(
        decoration: BoxDecoration(
          gradient: Theme.of(context).brightness == Brightness.dark
              ? const LinearGradient(
                  colors: [Color(0xFF282828), Color(0xFF000000)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [Color(0xFFFFFFFF), Color(0xFFF2F2F2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: ListView(
          children: [
            DrawerHeader(
              child: Column(
                children: [
                  Image.asset(
                    "assets/images/raag_logo.png",
                    width: 80,
                    height: 80,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Raag Music",
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text('home'.tr),
              onTap: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const BottomNavigationScreen()),
                  (route) => false,
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.music_note),
              title: Text('my_music'.tr),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const MyMusicScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.playlist_play),
              title: Text('playlists'.tr),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PlaylistsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text('settings'.tr),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.scanner),
              title: Text('scan_media'.tr),
              onTap: () async {
                Navigator.pop(context);
                await audioHandler.scan();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('media_scan_complete'.tr)),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info),
              title: Text('about'.tr),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AboutScreen(),));
              },
            ),
          ],
        ),
      ),
    );
  }
}
