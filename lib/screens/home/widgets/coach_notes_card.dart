import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../widgets/async_error_card.dart';

class CoachNotesCard extends ConsumerWidget {
  const CoachNotesCard({super.key});

  void _showHistory(BuildContext context, WidgetRef ref) {
    final repo = ref.read(coachNoteRepoProvider);
    final history = repo.getRecentNotes(7);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: AppColors.scaffoldBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Coach History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMedium),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (history.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('No history yet. Check back tomorrow!', style: TextStyle(color: AppColors.textLight)),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final h = history[index];
                      final dt = DateTime.tryParse(h.date) ?? DateTime.now();
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM d, yyyy').format(dt),
                                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary, fontSize: 13),
                                ),
                                if (h.isAi)
                                  Icon(Icons.auto_awesome, size: 12, color: AppColors.primary.withValues(alpha: 0.6)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              h.note,
                              style: const TextStyle(fontSize: 14, color: AppColors.textDark, height: 1.4),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final noteAsync = ref.watch(coachNoteProvider);
    final profile = ref.watch(profileProvider);

    return GestureDetector(
      onTap: () => _showHistory(context, ref),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.lavender,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sports_rounded, color: AppColors.white, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Coach Bodamma',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                if (!noteAsync.isLoading)
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.primary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      ref.read(coachNoteProvider.notifier).fetchNote(forceRefresh: true);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 16),
            noteAsync.when(
              data: (note) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.note,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  if (note.isAi) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: AppColors.primary.withValues(alpha: 0.6)),
                        const SizedBox(width: 4),
                        Text(
                          'Generated by AI',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppColors.textMedium.withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              ),
              error: (err, stack) => AsyncErrorCard(
                title: 'Coach is offline',
                message: 'Couldn\'t connect to AI coach. Keep up the great work today!',
                actionText: 'Retry',
                onRetry: () {
                  ref.read(coachNoteProvider.notifier).fetchNote(forceRefresh: true);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
