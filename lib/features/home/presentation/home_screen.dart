import 'package:evolve/features/home/presentation/providers/home_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../features/visit/domain/visit.dart' as entity; // Alias to avoid conflict if needed

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleState = ref.watch(homeScheduleProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Good Morning", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            Text("Here is your schedule today", style: TextStyle(fontSize: 14, color: Colors.grey)),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(backgroundColor: Color(0xFFDBEAFE), child: Text("SJ")),
          ),
        ],
      ),
      body: scheduleState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text("Error loading schedule: $err")),
        data: (visits) {
          if (visits.isEmpty) {
            return const Center(child: Text("No visits scheduled for today."));
          }

          // Find next visit (first one not completed)
          final nextVisit = visits.firstWhere(
            (v) => v.status != entity.VisitStatus.completed,
            orElse: () => visits.last
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildNextVisitCard(context, nextVisit),
                const SizedBox(height: 24),
                const Text("Today's Timeline", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...visits.map((visit) => _buildTimelineItem(context, visit)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNextVisitCard(BuildContext context, entity.Visit visit) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white24, borderRadius: BorderRadius.circular(20)),
                child: const Text("UP NEXT",
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
              const Icon(LucideIcons.mapPin, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 16),
          Text(visit.clientName,
              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text("Tap for details", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/visit/${visit.id}'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white, foregroundColor: AppTheme.primary),
              child: const Text("View Details"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, entity.Visit visit) {
    // Mock time for display since our entity might not have it parsed yet
    final timeStr = "09:00";

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(timeStr, style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textMain)),
              const SizedBox(height: 8),
              Container(width: 2, height: 40, color: Colors.grey.shade300),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/visit/${visit.id}'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(visit.clientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(LucideIcons.clipboardList, size: 14, color: AppTheme.textSub),
                            const SizedBox(width: 4),
                            // Show status as task for now
                            Text(visit.status.name.toUpperCase(), style: const TextStyle(color: AppTheme.textSub, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                    if (visit.status == entity.VisitStatus.completed)
                      const Icon(LucideIcons.checkCircle2, color: AppTheme.secondary),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}