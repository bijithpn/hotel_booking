import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/check_in_screen.dart';
import '../screens/check_out_screen.dart';
import '../screens/dashboard_screen.dart';

abstract class AppRoutes {
  static const String dashboard = '/';
  static const String dashboardName = 'dashboard';

  static const String checkIn = '/check-in';
  static const String checkInName = 'check-in';

  static const String checkOut = '/check-out';
  static const String checkOutName = 'check-out';
}

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  routes: [
    GoRoute(
      path: AppRoutes.dashboard,
      name: AppRoutes.dashboardName,
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: AppRoutes.checkIn,
      name: AppRoutes.checkInName,
      builder: (context, state) => const CheckInScreen(),
    ),
    GoRoute(
      path: AppRoutes.checkOut,
      name: AppRoutes.checkOutName,
      builder: (context, state) => const CheckOutScreen(),
    ),
  ],
  errorBuilder: (context, state) => Scaffold(
    appBar: AppBar(
      title: const Text('Page Not Found'),
    ),
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              'No route defined for "${state.uri}"',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go(AppRoutes.dashboard),
              icon: const Icon(Icons.home),
              label: const Text('Go to Dashboard'),
            ),
          ],
        ),
      ),
    ),
  ),
);
