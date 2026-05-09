import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

class GatewayScreen extends StatefulWidget {
  const GatewayScreen({super.key});

  @override
  State<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends State<GatewayScreen> {
  @override
  void initState() {
    super.initState();
    // Simulate brief animation delay before going to workspace
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        context.go('/photo-to-pdf/workspace');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://lottie.host/8c14d9b4-b2b9-4d69-a1fc-2216513b6ebf/JpB3M1f2T3.json', // Placeholder high-quality URL
              width: 200,
              height: 200,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.folder_shared, size: 100),
            ),
            const SizedBox(height: 24),
            const Text(
              'Accessing Gallery...',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
