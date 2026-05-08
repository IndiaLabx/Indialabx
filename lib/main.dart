import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsathi/app/router.dart';
import 'package:docsathi/app/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:docsathi/features/photo_to_pdf/data/models/document_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences sharedPreferences;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DocumentModelAdapter());
  await Hive.openBox<DocumentModel>('documents');

  sharedPreferences = await SharedPreferences.getInstance();

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
