import 'package:go_router/go_router.dart';
import 'package:docsathi/features/home/presentation/home_screen.dart';
import 'package:docsathi/features/photo_to_pdf/presentation/photo_to_pdf_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/photo-to-pdf',
      builder: (context, state) => const PhotoToPdfScreen(),
    ),
  ],
);
