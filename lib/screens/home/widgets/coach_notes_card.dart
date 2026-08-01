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
          decoration: BoxDecoration(
            color: context.colors.scaffoldBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coach History',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: context.colors.textDark),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: context.colors.textMedium),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              SizedBox(height: 16),
              if (history.isEmpty)
                Expanded(
                  child: Center(
                    child: Text('No history yet. Check back tomorrow!', style: TextStyle(color: context.colors.textLight)),
                  ),
                )
              else
                Expanded(
                  child: ListView.separated(
                    itemCount: history.length,
                    separatorBuilder: (_, _) => SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final h = history[index];
                      final dt = DateTime.tryParse(h.date) ?? DateTime.now();
                      return Container(
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: context.colors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormat('MMM d, yyyy').format(dt),
                                  style: TextStyle(fontWeight: FontWeight.w600, color: context.colors.primary, fontSize: 13),
                                ),
                                if (h.isAi)
                                  Icon(Icons.auto_awesome, size: 12, color: context.colors.primary.withValues(alpha: 0.6)),
                              ],
                            ),
                            SizedBox(height: 8),
                            Text(
                              h.note,
                              style: TextStyle(fontSize: 14, color: context.colors.textDark, height: 1.4),
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
        margin: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.colors.lavender,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: Offset(0, 4),
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
                    color: context.colors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.sports_rounded, color: context.colors.white, size: 18),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Coach Bodamma',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: context.colors.primary,
                    ),
                  ),
                ),
                if (!noteAsync.isLoading)
                  IconButton(
                    icon: Icon(Icons.refresh_rounded, color: context.colors.primary, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(),
                    onPressed: () {
                      ref.read(coachNoteProvider.notifier).fetchNote(forceRefresh: true);
                    },
                  ),
              ],
            ),
            SizedBox(height: 16),
            noteAsync.when(
              data: (note) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note.note,
                    style: TextStyle(
                      fontSize: 14,
                      color: context.colors.textDark,
                      fontWeight: FontWeight.w500,
                      height: 1.4,
                    ),
                  ),
                  if (note.isAi) ...[
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.auto_awesome, size: 12, color: context.colors.primary.withValues(alpha: 0.6)),
                        SizedBox(width: 4),
                        Text(
                          'Generated by AI',
                          style: TextStyle(
                            fontSize: 10,
                            color: context.colors.textMedium.withValues(alpha: 0.8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
              loading: () => Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: context.colors.primary),
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
