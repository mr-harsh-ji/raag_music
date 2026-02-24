import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../locals/string_extension.dart';
import 'theme_provider.dart';

class ThemePage extends StatelessWidget {
  const ThemePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text("theme_settings".tr)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            colorTile(
              title: "primary_color".tr,
              color: theme.primaryColor,
              onTap: () => theme.changePrimary(Colors.blue),
            ),
            colorTile(
              title: "accent_color".tr,
              color: theme.accentColor,
              onTap: () => theme.changeAccent(Colors.green),
            ),
            colorTile(
              title: "text_color".tr,
              color: theme.textColor,
              onTap: () => theme.changeText(Colors.orange),
            ),
          ],
        ),
      ),
    );
  }

  Widget colorTile({
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      title: Text(title),
      trailing: CircleAvatar(backgroundColor: color),
      onTap: onTap,
    );
  }
}
