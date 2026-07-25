import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';

class BackupRestoreScreen extends ConsumerStatefulWidget {
  const BackupRestoreScreen({super.key});

  @override
  ConsumerState<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends ConsumerState<BackupRestoreScreen> {
  bool _isLoading = false;
  String _lastBackupDate = 'Never';
  String _lastBackupSize = '';
  String _lastAutoBackupDate = 'Never';

  @override
  void initState() {
    super.initState();
    _loadMetadata();
  }

  Future<void> _loadMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _lastBackupDate = prefs.getString('last_backup_date') ?? 'Never';
      _lastBackupSize = prefs.getString('last_backup_size') ?? '';
      _lastAutoBackupDate = prefs.getString('last_auto_backup_display') ?? 'Never';
    });
  }

  Future<void> _saveMetadata(int sizeBytes) async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = DateFormat('MMM dd, yyyy · HH:mm').format(DateTime.now());
    
    final sizeKb = sizeBytes / 1024;
    String sizeStr;
    if (sizeKb > 1024) {
      sizeStr = '${(sizeKb / 1024).toStringAsFixed(1)} MB';
    } else {
      sizeStr = '${sizeKb.toStringAsFixed(0)} KB';
    }

    await prefs.setString('last_backup_date', dateStr);
    await prefs.setString('last_backup_size', sizeStr);
    
    setState(() {
      _lastBackupDate = dateStr;
      _lastBackupSize = sizeStr;
    });
  }

  Future<void> _handleCreateBackup() async {
    setState(() => _isLoading = true);
    final backupService = ref.read(backupServiceProvider);
    
    final zipPath = await backupService.createBackup();
    
    if (zipPath != null && mounted) {
      final String? outputFile = await FilePicker.saveFile(
        dialogTitle: 'Save Backup',
        fileName: 'trufit_backup_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}.zip',
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (outputFile != null) {
        try {
          final file = await File(zipPath).copy(outputFile);
          await _saveMetadata(await file.length());
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Backup created successfully! 📦'), backgroundColor: AppColors.green),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error saving backup: $e'), backgroundColor: AppColors.red),
            );
          }
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to create backup'), backgroundColor: AppColors.red),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _handleVerifyBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() => _isLoading = true);
      final backupService = ref.read(backupServiceProvider);
      final verify = await backupService.verifyBackup(result.files.single.path!);
      setState(() => _isLoading = false);

      if (!mounted) return;

      if (verify.isValid) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Backup Verified ✨', style: TextStyle(color: AppColors.green)),
            content: Text('Backup OK — ${verify.totalEntries} entries, ${verify.photoCount} photos.\n\nYour current data was not touched.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Awesome')),
            ],
          ),
        );
      } else {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Verification Failed', style: TextStyle(color: AppColors.red)),
            content: Text(verify.errorMessage ?? 'Invalid backup file.'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }

  Future<void> _handleRestoreBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      setState(() => _isLoading = true);
      final backupService = ref.read(backupServiceProvider);
      final verify = await backupService.verifyBackup(path);
      setState(() => _isLoading = false);
      
      if (!mounted) return;

      if (!verify.isValid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid backup file.'), backgroundColor: AppColors.red),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Restore Backup?'),
          content: Text(
            'This backup contains ${verify.totalEntries} entries and ${verify.photoCount} photos.\n\n'
            'WARNING: Restoring will completely overwrite all your current data. This cannot be undone.'
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() => _isLoading = true);
                final success = await backupService.restoreBackup(path);
                
                if (!mounted) return;
                setState(() => _isLoading = false);

                if (success) {
                  ref.read(refreshTriggerProvider.notifier).state++;
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const AlertDialog(
                      title: Text('Restore Complete 🎉', style: TextStyle(color: AppColors.green)),
                      content: Text('Restore complete — please restart the app.'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to restore backup.'), backgroundColor: AppColors.red),
                  );
                }
              },
              child: const Text('Restore', style: TextStyle(color: AppColors.red)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Backup & Restore'),
        backgroundColor: AppColors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.lavender,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Last Backup',
                          style: TextStyle(fontSize: 14, color: AppColors.textMedium),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _lastBackupDate,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                        if (_lastBackupSize.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            _lastBackupSize,
                            style: const TextStyle(fontSize: 12, color: AppColors.textMedium),
                          ),
                        ],
                        const SizedBox(height: 12),
                        const Divider(color: AppColors.border),
                        const SizedBox(height: 8),
                        const Text(
                          'Last Auto-Backup (Weekly)',
                          style: TextStyle(fontSize: 14, color: AppColors.textMedium),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _lastAutoBackupDate,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _ActionCard(
                    title: 'Create Backup',
                    subtitle: 'Export a copy of all your data',
                    icon: Icons.upload_file_rounded,
                    onTap: _handleCreateBackup,
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    title: 'Restore from Backup',
                    subtitle: 'Overwrite current data with a backup',
                    icon: Icons.restore_page_rounded,
                    iconColor: AppColors.pinkIcon,
                    onTap: _handleRestoreBackup,
                  ),
                  const SizedBox(height: 16),
                  _ActionCard(
                    title: 'Verify Backup',
                    subtitle: 'Test a backup file without restoring',
                    icon: Icons.fact_check_rounded,
                    iconColor: AppColors.mintIcon,
                    onTap: _handleVerifyBackup,
                  ),
                ],
              ),
            ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.iconColor = AppColors.primary,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textLight),
          ],
        ),
      ),
    );
  }
}
