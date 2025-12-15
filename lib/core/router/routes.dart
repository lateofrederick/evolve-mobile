import 'package:evolve/core/presentation/main_scaffold.dart';
import 'package:evolve/features/auth/presentation/login_screen.dart';
import 'package:evolve/features/home/presentation/home_screen.dart';
import 'package:evolve/features/visit/presentation/visit_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';


import '../../main.dart'; // Imports MainScaffold (or move MainScaffold to home/presentation)

// We move MainScaffold to a shared layout file or keep in main for now
// For this Clean Architecture split, let's assume MainScaffold is imported from main.dart
// Note: In a real app, MainScaffold would likely be in `features/home/presentation/widgets/`

final router = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainScaffold(child: HomeScreen()),
    ),
    // We can add /rota here similarly
    GoRoute(
      path: '/visit/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return VisitDetailScreen(visitId: id);
      },
    ),
  ],
);