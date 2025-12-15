import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';

// Mock Data for Meds
final meds = [
  {"id": 1, "name": "Paracetamol", "dose": "500mg (2 Tablets)", "notes": "Take with water"},
  {"id": 2, "name": "Amlodipine", "dose": "5mg (1 Tablet)", "notes": "Blood pressure"},
];

class MedicationSheet extends ConsumerStatefulWidget {
  final String visitId;
  const MedicationSheet({required this.visitId, super.key});

  @override
  ConsumerState<MedicationSheet> createState() => _MedicationSheetState();
}

class _MedicationSheetState extends ConsumerState<MedicationSheet> {
  // Track status of each med: 0=Pending, 1=Given, 2=Refused
  final Map<int, int> _medStatus = {};

  void _setStatus(int id, int status) {
    setState(() {
      _medStatus[id] = status;
    });
  }

  void _submitLog() {
    // Check if all meds handled
    if (_medStatus.length < meds.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please record an outcome for all medications.")),
      );
      return;
    }

    // In real app: call API here via Provider
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("eMAR Updated Successfully"), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Medication (eMAR)", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(LucideIcons.x)),
            ],
          ),
          const SizedBox(height: 8),
          const Text("Please record the outcome for each medication below.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),

          Expanded(
            child: ListView.separated(
              itemCount: meds.length,
              separatorBuilder: (ctx, i) => const Divider(height: 32),
              itemBuilder: (context, index) {
                final med = meds[index];
                final id = med['id'] as int;
                final status = _medStatus[id] ?? 0;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)),
                          child: const Icon(LucideIcons.pill, color: AppTheme.primary),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(med['name'] as String, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                            Text(med['dose'] as String, style: const TextStyle(color: AppTheme.textSub)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _StatusButton(
                            label: "Given",
                            icon: LucideIcons.check,
                            color: Colors.green,
                            isSelected: status == 1,
                            onTap: () => _setStatus(id, 1),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatusButton(
                            label: "Refused",
                            icon: LucideIcons.ban,
                            color: Colors.red,
                            isSelected: status == 2,
                            onTap: () => _setStatus(id, 2),
                          ),
                        ),
                      ],
                    )
                  ],
                );
              },
            ),
          ),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitLog,
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
              child: const Text("Confirm & Save Log"),
            ),
          )
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}