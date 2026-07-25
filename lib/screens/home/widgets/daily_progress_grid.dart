import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../weight_entry_dialog.dart';
import '../steps_entry_dialog.dart';
import 'sync_status_sheet.dart';

class DailyProgressGrid extends ConsumerWidget {
  const DailyProgressGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyLog = ref.watch(dailyLogProvider);
    
    final selectedDateStr = ref.watch(dateStringProvider);
    final selectedDate = DateTime.parse(selectedDateStr);
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final isFuture = selectedDate.isAfter(today);
    final isToday = selectedDate.isAtSameMomentAs(today);
    
    final mediaRepo = ref.watch(mediaRepoProvider);
    final allPhotos = mediaRepo.getAllProgressPhotos();
    final flattenedPhotos = allPhotos.expand((e) => e.value).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ProgressCard(
                    title: 'Body Stats',
                    icon: Icons.straighten_rounded,
                    color: AppColors.pink,
                    iconColor: AppColors.pinkIcon,
                    subtitle: 'Tap to view',
                    onTap: () => context.go('/home/body-stats'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ProgressCard(
                    title: 'Physique\nPictures',
                    icon: Icons.camera_alt_rounded,
                    color: AppColors.pink,
                    iconColor: AppColors.pinkIcon,
                    subtitle: 'Progress photos',
                    thumbnails: flattenedPhotos,
                    onTap: () => context.go('/home/physique-pictures'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ProgressCard(
                    title: 'Body Weight',
                    icon: Icons.monitor_weight_rounded,
                    color: AppColors.lavenderCard,
                    iconColor: AppColors.primary,
                    subtitle: dailyLog.weight != null
                        ? '${dailyLog.weight!.toStringAsFixed(1)} kg'
                        : (isFuture ? 'No data' : 'Tap to log'),
                    onTap: isFuture
                        ? () {}
                        : () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => const WeightEntryDialog(),
                            );
                          },
                    onChartTap: () => context.push('/progress?metric=weight'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StepsCard(
                    isFuture: isFuture,
                    isToday: isToday,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Special Steps card that handles the Health Connect first-run CTA.
class _StepsCard extends ConsumerStatefulWidget {
  const _StepsCard({
    required this.isFuture,
    required this.isToday,
  });

  final bool isFuture;
  final bool isToday;

  @override
  ConsumerState<_StepsCard> createState() => _StepsCardState();
}

class _StepsCardState extends ConsumerState<_StepsCard> {
  bool _showSyncCta = false;
  bool _checkingPermission = true;
  bool _isAuth = false;

  @override
  void initState() {
    super.initState();
    _checkHealthConnectStatus();
  }

  Future<void> _checkHealthConnectStatus() async {
    final hcService = ref.read(healthConnectServiceProvider);
    final isAuth = await hcService.isAuthorized();
    if (mounted) {
      setState(() {
        _isAuth = isAuth;
        _showSyncCta = !isAuth && widget.isToday;
        _checkingPermission = false;
      });
    }
  }

  Future<void> _handleSyncTap() async {
    final hcService = ref.read(healthConnectServiceProvider);
    
    // Check if Health Connect is installed
    final available = await hcService.isAvailable();
    if (!available) {
      // Deep link to Play Store
      final uri = Uri.parse('https://play.google.com/store/apps/details?id=com.google.android.apps.healthdata');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    // Request permission
    final granted = await hcService.requestPermission();
    if (granted) {
      setState(() => _showSyncCta = false);
      
      // Trigger sync
      final dailyLogRepo = ref.read(dailyLogRepoProvider);
      final habitRepo = ref.read(habitRepoProvider);
      await hcService.syncTodayAndAutoCompleteHabit(dailyLogRepo, habitRepo);
      await hcService.syncLast7Days(dailyLogRepo, habitRepo);
      
      // Backfill in background
      if (!hcService.isBackfillDone) {
        hcService.backfillLast90Days(dailyLogRepo, habitRepo).then((_) {
          ref.read(refreshTriggerProvider.notifier).state++;
        });
      }
      
      ref.read(refreshTriggerProvider.notifier).state++;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show the sync CTA card if permission not granted (today only)
    if (_showSyncCta && !_checkingPermission) {
      return GestureDetector(
        onTap: _handleSyncTap,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.sync_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sync Steps',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'from Samsung Health',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Normal steps card
    final dailyLog = ref.watch(dailyLogProvider);

    // Determine subtitle
    String stepsSubtitle;
    String? sourceHint;

    if (dailyLog.steps != null) {
      stepsSubtitle = '${dailyLog.steps!} steps';
      if (dailyLog.stepsSource == 'healthConnect') {
        sourceHint = 'Synced via Samsung Health';
      } else if (dailyLog.stepsSource == 'manual') {
        sourceHint = 'manual';
      }
    } else {
      stepsSubtitle = '0 steps';
      if (_isAuth) {
        sourceHint = 'Synced';
      } else {
        sourceHint = widget.isToday ? 'Tap to log' : null;
      }
    }

    return GestureDetector(
      onTap: widget.isFuture
          ? () {}
          : () {
              if (_isAuth) {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const SyncStatusSheet(),
                );
              } else {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => const StepsEntryDialog(),
                );
              }
            },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.mint,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.mintIcon.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.directions_walk_rounded, color: AppColors.mintIcon, size: 22),
                ),
                GestureDetector(
                  onTap: () => context.push('/progress?metric=steps'),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.show_chart_rounded, color: AppColors.mintIcon, size: 18),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Text(
              'Steps',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stepsSubtitle,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textMedium,
              ),
            ),
            if (sourceHint != null) ...[
              const SizedBox(height: 2),
              Text(
                sourceHint,
                style: TextStyle(
                  fontSize: 10,
                  color: sourceHint == 'Synced via Samsung Health' || sourceHint == 'Synced'
                      ? AppColors.green
                      : AppColors.textLight,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.subtitle,
    required this.onTap,
    this.thumbnails,
    this.onChartTap,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String subtitle;
  final VoidCallback onTap;
  final List<String>? thumbnails;
  final VoidCallback? onChartTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 22),
                ),
                if (onChartTap != null)
                  GestureDetector(
                    onTap: onChartTap,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.show_chart_rounded, color: iconColor, size: 18),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textDark,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 4),
            if (thumbnails != null && thumbnails!.isNotEmpty)
              Row(
                children: [
                  ...thumbnails!.take(3).map((path) => Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: kIsWeb
                              ? Image.network(
                                  path,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                )
                              : Image.file(
                                  File(path),
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  cacheWidth: 96,
                                  cacheHeight: 96,
                                ),
                        ),
                      )),
                  if (thumbnails!.length > 3)
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.lavender,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '+${thumbnails!.length - 3}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                ],
              )
            else
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textMedium,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
