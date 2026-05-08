import 'package:go_router/go_router.dart';
import 'package:docsathi/features/home/presentation/home_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/document_dashboard_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/select_reorder_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/edit_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/pdf_settings_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/preview_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/photo-to-pdf',
      builder: (context, state) => const DocumentDashboardScreen(),
      routes: [
        GoRoute(
          path: 'select',
          builder: (context, state) => const SelectReorderScreen(),
        ),
        GoRoute(
          path: 'edit',
          builder: (context, state) => const EditScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const PdfSettingsScreen(),
        ),
        GoRoute(
          path: 'preview',
          builder: (context, state) {
            final pdfPath = state.extra as String;
            return PreviewScreen(pdfPath: pdfPath);
          },
        ),
      ],
    ),
  ],
);
