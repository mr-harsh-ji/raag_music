import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late SharedPreferences _prefs;
  bool _gestureVolume = true;
  bool _stopOnClose = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _gestureVolume = _prefs.getBool('gestureVolume') ?? true;
      _stopOnClose = _prefs.getBool('stopOnClose') ?? true;
    });
  }

  Future<void> _setGestureVolume(bool value) async {
    await _prefs.setBool('gestureVolume', value);
    setState(() {
      _gestureVolume = value;
    });
  }

  Future<void> _setStopOnClose(bool value) async {
    await _prefs.setBool('stopOnClose', value);
    setState(() {
      _stopOnClose = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Gesture Volume'),
            value: _gestureVolume,
            onChanged: _setGestureVolume,
          ),
          SwitchListTile(
            title: const Text('Stop Music on App Close'),
            value: _stopOnClose,
            onChanged: _setStopOnClose,
          ),
        ],
      ),
    );
  }
}
