import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsathi/app/router.dart';
import 'package:docsathi/app/theme/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: DocSathiApp()));
}

class DocSathiApp extends StatelessWidget {
  const DocSathiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'DocSathi',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
    );
  }
}
