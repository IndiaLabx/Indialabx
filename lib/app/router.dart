import 'package:go_router/go_router.dart';
import 'package:docsathi/features/home/presentation/home_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/document_dashboard_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/workspace_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/preview_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/screens/external_pdf_viewer_screen.dart';
import 'package:docsathi/features/image_resize/presentation/screens/image_resize_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  // ignore deep links that are content:// or file://
  // since they are handled by receive_sharing_intent
  errorBuilder: (context, state) {
    return const HomeScreen();
  },
  redirect: (context, state) {
    final location = state.uri.toString();
    if (location.startsWith('content://') || location.startsWith('file://')) {
      return '/';
    }
    return null;
  },
  routes: [
    GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
    GoRoute(
      path: '/external-pdf-preview',
      builder: (context, state) {
        final pdfPath = state.extra as String;
        return ExternalPdfViewerScreen(pdfPath: pdfPath);
      },
    ),
    GoRoute(
      path: '/resize',
      builder: (context, state) => const ImageResizeScreen(),
    ),
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
