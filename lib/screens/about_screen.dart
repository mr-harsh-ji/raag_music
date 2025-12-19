import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    setState(() {
      _version = info.version; // e.g. 1.0.0, 1.1.0, 2.0.0
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Image.asset(
                    "assets/images/raag_logo.png",
                    width: 120,
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Welcome to\nRaag Music',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    '''
Raag Music ek fast, simple aur powerful offline music player hai, jo aapko smooth aur distraction-free music experience deta hai.

Is app ko performance aur simplicity ko dhyaan me rakhkar design kiya gaya hai, taaki aap apne favorite songs bina kisi rukawat ke enjoy kar saken.

Features:
• High-quality offline music playback
• Smooth seek bar & playback controls
• Shuffle & repeat modes
• Favorite songs support
• Playback speed control
• Clean & modern user interface  

Raag Music un music lovers ke liye banaya gaya hai jo speed, simplicity aur apne music par full control chahte hain.

👨‍💻 Developer
Harsh Kumar
''',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _version.isEmpty ? 'Loading version...' : 'Version $_version',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),

          /// Back Button
          Positioned(
            top: 40,
            left: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}
