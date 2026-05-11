import 'package:go_router/go_router.dart';
import 'package:docsathi/features/home/presentation/home_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/document_dashboard_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/workspace_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/preview_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/photo-to-pdf',
      builder: (context, state) => const DocumentDashboardScreen(),
      routes: [
        GoRoute(
          path: 'workspace',
          builder: (context, state) => const WorkspaceScreen(),
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
