import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:docsathi/app/router.dart';
import 'package:docsathi/app/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:docsathi/features/photo_to_pdf/data/models/document_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

late SharedPreferences sharedPreferences;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(DocumentModelAdapter());
  await Hive.openBox<DocumentModel>('documents');

  sharedPreferences = await SharedPreferences.getInstance();

  runApp(const ProviderScope(child: DocSathiApp()));
}

class DocSathiApp extends StatefulWidget {
  const DocSathiApp({super.key});

  @override
  State<DocSathiApp> createState() => _DocSathiAppState();
}

class _DocSathiAppState extends State<DocSathiApp> {
  late StreamSubscription _intentDataStreamSubscription;

  @override
  void initState() {
    super.initState();
    _handleIncomingIntents();
  }

  void _handleIncomingIntents() {
    // For sharing or opening media coming from outside the app while the app is in the memory
    _intentDataStreamSubscription = ReceiveSharingIntent.instance.getMediaStream().listen((List<SharedMediaFile> value) {
      _processIncomingFiles(value);
    }, onError: (err) {
      debugPrint("getMediaStream error: $err");
    });

    // For sharing or opening media coming from outside the app while the app is closed
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> value) {
      _processIncomingFiles(value);
      ReceiveSharingIntent.instance.reset(); // clear the intent after handling
    });
  }

  void _processIncomingFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    // Check if there is a PDF file
    for (var file in files) {
      if (file.path.toLowerCase().endsWith('.pdf')) {
        // We found a PDF. Use the router to navigate to the external viewer.
        // Wait until the build is complete to use context
        WidgetsBinding.instance.addPostFrameCallback((_) {
          appRouter.push('/external-pdf-preview', extra: file.path);
        });
        break; // Just handle the first PDF found for now
      }
    }
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

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
