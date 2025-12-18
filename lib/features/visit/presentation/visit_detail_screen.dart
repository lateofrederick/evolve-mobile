import 'package:evolve/features/visit/domain/visit.dart';
import 'package:evolve/features/visit/presentation/visit_notifier.dart';
import 'package:evolve/features/visit/service/location_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../../core/theme/app_theme.dart';
import 'qr_scanner_screen.dart';
import '../widgets/medication_sheet.dart'; // We will build this next

class VisitDetailScreen extends ConsumerWidget {
  final String visitId;
  const VisitDetailScreen({required this.visitId, super.key});

  void _handleScanIn(BuildContext context, WidgetRef ref) async {
    // 1. Check Location FIRST (Don't open camera if GPS fails)
    final locationService = LocationService();

    try {
      // Show loading indicator or toast?
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Acquiring GPS Signal..."), duration: Duration(seconds: 1)),
      );

      final position = await locationService.getCurrentLocation();

      if (!context.mounted) return;

      // 2. Open Scanner
      final scannedCode = await Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const QrScannerScreen()),
      );

      if (scannedCode != null) {
        if (scannedCode.toString().contains("CAREFLOW")) {
          // 3. Send Payload + GPS to Provider
          ref.read(visitProvider(visitId).notifier).scanIn(
            scannedCode.toString(),
            position.latitude,
            position.longitude
          );

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Check-in Successful!"), backgroundColor: AppTheme.secondary),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Invalid QR Code"), backgroundColor: AppTheme.error),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  void _handleScanOut(BuildContext context, WidgetRef ref) async {
    ref.read(visitProvider(visitId).notifier).scanOut();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Visit Completed"), backgroundColor: AppTheme.secondary),
      );
      context.pop();
    }
  }

  void _openMedicationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => MedicationSheet(visitId: visitId),
    );
  }

  void _openNoteSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VisitNoteSheet(
        onSubmit: (text, severity) async {
          await ref.read(visitProvider(visitId).notifier).saveNote(text, severity);
          if (context.mounted) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Note Saved"), backgroundColor: Colors.green),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visitAsync = ref.watch(visitProvider(visitId));

    return visitAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(appBar: AppBar(), body: Center(child: Text("Error: $err"))),
      data: (visit) {
        final isScannedIn = visit.status != VisitStatus.scheduled;
        final isCompleted = visit.status == VisitStatus.completed;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: _buildAppBar(context, isScannedIn, isCompleted),
          // Floating Action Button for Notes
          floatingActionButton: isScannedIn && !isCompleted
            ? FloatingActionButton.extended(
                onPressed: () => _openNoteSheet(context, ref),
                label: const Text("Add Note"),
                icon: const Icon(LucideIcons.penTool),
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              )
            : null,
          body: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildClientHeader(visit),
                    const SizedBox(height: 32),
                    _buildCriticalAlert(),
                    const SizedBox(height: 24),
                    _buildTasksSection(context, isScannedIn, visit, ref), // Pass required params
                  ],
                ),
              ),
              _buildBottomAction(context, ref, visit.status),
            ],
          ),
        );
      },
    );
  }

  // ... (Keep existing _buildAppBar, _buildClientHeader, _buildCriticalAlert) ...
  AppBar _buildAppBar(BuildContext context, bool isScannedIn, bool isCompleted) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        onPressed: () => context.pop(),
        icon: const Icon(LucideIcons.arrowLeft, color: Colors.black),
      ),
      title: const Text("Visit Details", style: TextStyle(color: Colors.black)),
      actions: [
        if (isScannedIn && !isCompleted)
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Chip(
              label: const Text("In Progress"),
              backgroundColor: Colors.green.shade100,
              labelStyle: TextStyle(color: Colors.green.shade900),
            ),
          )
      ],
    );
  }

  Widget _buildClientHeader(Visit visit) {
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.grey.shade200,
            child: Text(
              visit.clientName.isNotEmpty ? visit.clientName.split(' ').last.substring(0, 1) : "?",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Text(visit.clientName, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const Text("12 Oak Avenue, Derby • Key Safe: 4590", style: TextStyle(color: AppTheme.textSub)),
        ],
      ),
    );
  }

  Widget _buildCriticalAlert() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertTriangle, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "Alert: Client has severe allergy to Penicillin. DNACPR in place.",
              style: TextStyle(color: Colors.red.shade900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection(BuildContext context, bool isScannedIn, Visit visit, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Visit Tasks", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        // Example dynamic task
        _buildTaskItem("Personal Care", "task_1", isScannedIn, false, ref),
        // Medication
        GestureDetector(
          onTap: isScannedIn ? () => _openMedicationSheet(context) : null,
          child: _buildTaskItem("Medication", "meds", isScannedIn, false, ref),
        ),
      ],
    );
  }

  Widget _buildTaskItem(String title, String taskId, bool isUnlocked, bool isChecked, WidgetRef ref) {
    return Opacity(
      opacity: isUnlocked ? 1.0 : 0.5,
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Icon(LucideIcons.clipboardCheck, color: AppTheme.primary),
          ),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          trailing: isUnlocked
              ? Checkbox(
                  value: isChecked,
                  onChanged: (val) {
                     // Trigger provider update logic here
                  }
                )
              : const Icon(LucideIcons.lock, size: 16, color: Colors.grey),
        ),
      ),
    );
  }


  Widget _buildBottomAction(BuildContext context, WidgetRef ref, VisitStatus status) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
        ),
        child: SafeArea(
          child: _actionButtonContent(context, ref, status),
        ),
      ),
    );
  }

  Widget _actionButtonContent(BuildContext context, WidgetRef ref, VisitStatus status) {
    switch (status) {
      case VisitStatus.scheduled:
        return ElevatedButton.icon(
          onPressed: () => _handleScanIn(context, ref),
          icon: const Icon(LucideIcons.qrCode),
          label: const Text("SCAN QR TO START VISIT"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            minimumSize: const Size(double.infinity, 56),
          ),
        );
      case VisitStatus.inProgress:
        return ElevatedButton.icon(
          onPressed: () => _handleScanOut(context, ref),
          icon: const Icon(LucideIcons.logOut),
          label: const Text("COMPLETE & SCAN OUT"),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondary,
            minimumSize: const Size(double.infinity, 56),
          ),
        );
      case VisitStatus.completed:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.green.shade50, borderRadius: BorderRadius.circular(12)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(LucideIcons.checkCircle2, color: Colors.green),
              const SizedBox(width: 8),
              Text("Visit Completed",
                  style: TextStyle(color: Colors.green.shade900, fontWeight: FontWeight.bold)),
            ],
          ),
        );
    }
  }

}

class _VisitNoteSheet extends StatefulWidget {
  final Function(String, String) onSubmit;
  const _VisitNoteSheet({required this.onSubmit});

  @override
  State<_VisitNoteSheet> createState() => _VisitNoteSheetState();
}

class _VisitNoteSheetState extends State<_VisitNoteSheet> {
  final _controller = TextEditingController();
  String _severity = 'routine'; // routine, concern, incident

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Add Visit Note", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          // Severity Selector
          Row(
            children: [
              _buildSeverityChip('Routine', 'routine', Colors.blue),
              const SizedBox(width: 8),
              _buildSeverityChip('Concern', 'concern', Colors.orange),
              const SizedBox(width: 8),
              _buildSeverityChip('Incident', 'incident', Colors.red),
            ],
          ),
          const SizedBox(height: 16),

          TextField(
            controller: _controller,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: "Enter details (e.g., Client mood, issues found...)",
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_controller.text.isNotEmpty) {
                  widget.onSubmit(_controller.text, _severity);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _getSeverityColor(_severity),
              ),
              child: const Text("Save Log"),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSeverityChip(String label, String value, Color color) {
    final isSelected = _severity == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (v) => setState(() => _severity = value),
      selectedColor: color.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : Colors.grey,
        fontWeight: FontWeight.bold,
      ),
      backgroundColor: Colors.white,
      side: BorderSide(color: isSelected ? color : Colors.grey.shade300),
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'incident': return Colors.red;
      case 'concern': return Colors.orange;
      default: return AppTheme.primary;
    }
  }
}