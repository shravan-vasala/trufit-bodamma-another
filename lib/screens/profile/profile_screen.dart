import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:path_provider/path_provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _appVersion = '';

  @override
  void initState() {
    super.initState();
    _initPackageInfo();
  }

  Future<void> _initPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = 'v${info.version}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);

    return Scaffold(
      backgroundColor: context.colors.scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 8),
              // Profile header
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: context.colors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: context.colors.primary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.white.withValues(alpha: 0.2),
                        border: Border.all(
                          color: context.colors.white.withValues(alpha: 0.5),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: profile.photoPath != null && File(profile.photoPath!).existsSync()
                            ? Image.file(
                                File(profile.photoPath!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: profile.name.isNotEmpty
                                    ? Text(
                                        profile.name[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: context.colors.white,
                                        ),
                                      )
                                    : Icon(Icons.person, size: 40, color: context.colors.white),
                              ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: context.colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Height: ${profile.height.toStringAsFixed(0)} cm',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    if (profile.targetWeight != null) ...[
                      SizedBox(height: 2),
                      Text(
                        'Target: ${profile.targetWeight!.toStringAsFixed(1)} ${profile.weightUnit}',
                        style: TextStyle(
                          fontSize: 14,
                          color: context.colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Menu items
              _MenuCard(
                icon: Icons.edit_rounded,
                title: 'Edit Profile',
                subtitle: 'Name, height, target weight',
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => _EditProfileSheet(),
                  );
                },
              ),
              _MenuCard(
                icon: Icons.auto_awesome_rounded,
                title: 'AI Settings',
                subtitle: 'Gemini API Key for accurate food scan',
                onTap: () => _showGeminiKeyDialog(context, ref, profile),
              ),
              _MenuCard(
                icon: Icons.fitness_center_rounded,
                title: 'Manage Plans',
                subtitle: 'Edit workout & meal JSON',
                onTap: () => context.go('/profile/manage-plans'),
              ),
              _MenuCard(
                icon: Icons.notifications_rounded,
                title: 'Reminders',
                subtitle: 'Daily habits, workouts, and backups',
                onTap: () => context.go('/profile/reminders'),
              ),
              _MenuCard(
                icon: Icons.swap_horiz_rounded,
                title: 'Unit Preference',
                subtitle: 'Currently: ${profile.useKg ? 'Kilograms (kg)' : 'Pounds (lb)'}',
                onTap: () {
                  ref.read(profileProvider.notifier).toggleUnit();
                },
              ),
              _MenuCard(
                icon: Icons.dark_mode_rounded,
                title: 'Theme',
                subtitle: 'Currently: ${ref.watch(themeModeProvider).name}',
                onTap: () => _showThemeDialog(context, ref),
              ),
              _SettingsSwitch(
                icon: Icons.volume_up_rounded,
                title: 'Rest Timer Sound',
                subtitle: 'Play alert sound when rest finishes',
                value: profile.restTimerSound,
                onChanged: (val) {
                  ref.read(profileProvider.notifier).updateProfile(
                        profile.copyWith(restTimerSound: val),
                      );
                },
              ),
              _SettingsSwitch(
                icon: Icons.vibration_rounded,
                title: 'Rest Timer Vibration',
                subtitle: 'Vibrate when rest finishes',
                value: profile.restTimerVibration,
                onChanged: (val) {
                  ref.read(profileProvider.notifier).updateProfile(
                        profile.copyWith(restTimerVibration: val),
                      );
                },
              ),
              _MenuCard(
                icon: Icons.backup_rounded,
                title: 'Backup & Restore',
                subtitle: 'Export or restore all data & photos',
                onTap: () {
                  context.go('/profile/backup-restore');
                },
              ),
              SizedBox(height: 16),
              Text(
                'Made with ❤️ for Bodamma',
                style: TextStyle(
                  fontSize: 12,
                  color: context.colors.textLight,
                ),
              ),
              if (_appVersion.isNotEmpty) ...[
                SizedBox(height: 4),
                Text(
                  _appVersion,
                  style: TextStyle(
                    fontSize: 10,
                    color: context.colors.textLight.withValues(alpha: 0.6),
                  ),
                ),
              ],
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: context.colors.white,
          title: Text('Select Theme', style: TextStyle(color: context.colors.textDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                title: Text(mode.name, style: TextStyle(color: context.colors.textDark)),
                value: mode,
                groupValue: ref.watch(themeModeProvider),
                activeColor: context.colors.primary,
                onChanged: (val) {
                  if (val != null) {
                    ref.read(themeModeProvider.notifier).setThemeMode(val);
                    Navigator.pop(ctx);
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showGeminiKeyDialog(
      BuildContext context, WidgetRef ref, dynamic profile) {
    final keyController = TextEditingController(text: profile.geminiApiKey ?? '');
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: context.colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: context.colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Gemini AI Settings',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: context.colors.textDark,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Enter your Gemini API key to enable highly accurate AI food tracking and calorie estimation.',
                style: TextStyle(
                  fontSize: 14,
                  color: context.colors.textMedium,
                ),
              ),
              SizedBox(height: 20),
              TextField(
                controller: keyController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Gemini API Key',
                  prefixIcon: Icon(Icons.key_rounded),
                ),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final key = keyController.text.trim();
                    ref.read(profileProvider.notifier).updateGeminiKey(key);
                    Navigator.of(ctx).pop();
                  },
                  child: Text('Save API Key'),
                ),
              ),
              SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }


}

class _MenuCard extends StatelessWidget {
  const _MenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: context.colors.primary.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: context.colors.lavender,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: context.colors.primary, size: 22),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textDark,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: context.colors.textLight,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSwitch extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingsSwitch({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: context.colors.primary.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: context.colors.primary,
        secondary: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: context.colors.lavender,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: context.colors.primary, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.colors.textDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 13,
            color: context.colors.textMedium,
          ),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

class _EditProfileSheet extends ConsumerStatefulWidget {
  const _EditProfileSheet();

  @override
  ConsumerState<_EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends ConsumerState<_EditProfileSheet> {
  late TextEditingController nameController;
  late TextEditingController heightController;
  late TextEditingController targetController;
  late TextEditingController caloriesController;
  late TextEditingController proteinController;
  late TextEditingController carbsController;
  late TextEditingController fatController;
  
  String? _localPhotoPath;
  bool _clearPhoto = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider);
    nameController = TextEditingController(text: profile.name);
    heightController = TextEditingController(text: profile.height.toStringAsFixed(0));
    targetController = TextEditingController(text: profile.targetWeight?.toStringAsFixed(1) ?? '');
    caloriesController = TextEditingController(text: profile.targetCalories.toString());
    proteinController = TextEditingController(text: profile.targetProteinG.toString());
    carbsController = TextEditingController(text: profile.targetCarbsG.toString());
    fatController = TextEditingController(text: profile.targetFatG.toString());
    _localPhotoPath = profile.photoPath;
  }

  @override
  void dispose() {
    nameController.dispose();
    heightController.dispose();
    targetController.dispose();
    caloriesController.dispose();
    proteinController.dispose();
    carbsController.dispose();
    fatController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile == null) return;

      final croppedFile = await ImageCropper().cropImage(
        sourcePath: pickedFile.path,
        aspectRatio: CropAspectRatio(ratioX: 1, ratioY: 1),
        compressQuality: 70,
        maxWidth: 512,
        maxHeight: 512,
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Crop Photo',
            toolbarColor: context.colors.primary,
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: true,
          ),
          IOSUiSettings(
            title: 'Crop Photo',
            aspectRatioLockEnabled: true,
            resetAspectRatioEnabled: false,
          ),
        ],
      );

      if (croppedFile != null) {
        final appDir = await getApplicationDocumentsDirectory();
        final fileName = 'profile_pic_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await File(croppedFile.path).copy('${appDir.path}/$fileName');
        
        setState(() {
          _localPhotoPath = savedImage.path;
          _clearPhoto = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e'), backgroundColor: context.colors.red),
        );
      }
    }
  }

  void _showPickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Profile Photo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.colors.textDark),
            ),
            SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.camera_alt, color: context.colors.primary),
              title: Text('Take a picture'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: context.colors.primary),
              title: Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_localPhotoPath != null && !_clearPhoto)
              ListTile(
                leading: Icon(Icons.delete, color: context.colors.red),
                title: Text('Remove photo', style: TextStyle(color: context.colors.red)),
                onTap: () async {
                  Navigator.pop(ctx);
                  if (_localPhotoPath != null) {
                    final f = File(_localPhotoPath!);
                    if (await f.exists()) await f.delete();
                  }
                  setState(() {
                    _localPhotoPath = null;
                    _clearPhoto = true;
                  });
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileProvider);
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: context.colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Edit Profile',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: context.colors.textDark,
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _showPickerOptions,
                child: Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.colors.lavender,
                      ),
                      child: ClipOval(
                        child: _localPhotoPath != null && !_clearPhoto
                            ? Image.file(
                                File(_localPhotoPath!),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: nameController.text.isNotEmpty
                                    ? Text(
                                        nameController.text[0].toUpperCase(),
                                        style: TextStyle(
                                          fontSize: 32,
                                          fontWeight: FontWeight.w800,
                                          color: context.colors.primary,
                                        ),
                                      )
                                    : Icon(Icons.person, size: 40, color: context.colors.primary),
                              ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: context.colors.primary,
                          shape: BoxShape.circle,
                          border: Border.all(color: context.colors.white, width: 2),
                        ),
                        child: Icon(Icons.camera_alt, color: context.colors.white, size: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              onChanged: (v) => setState(() {}),
            ),
            SizedBox(height: 12),
            TextField(
              controller: heightController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Height (cm)',
                prefixIcon: Icon(Icons.height_rounded),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: targetController,
              keyboardType:
                  TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target Weight (kg)',
                prefixIcon: Icon(Icons.flag_rounded),
              ),
            ),
            SizedBox(height: 12),
            TextField(
              controller: caloriesController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Target Daily Calories',
                prefixIcon: Icon(Icons.restaurant_rounded),
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: proteinController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Protein (g)',
                      prefixIcon: Icon(Icons.fitness_center_rounded, size: 18),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: carbsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Carbs (g)',
                      prefixIcon: Icon(Icons.breakfast_dining_rounded, size: 18),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: fatController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Fat (g)',
                      prefixIcon: Icon(Icons.water_drop_rounded, size: 18),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  final updated = profile.copyWith(
                    name: nameController.text,
                    height: double.tryParse(heightController.text) ??
                        profile.height,
                    targetWeight: double.tryParse(targetController.text),
                    targetCalories: int.tryParse(caloriesController.text) ?? 
                        profile.targetCalories,
                    targetProteinG: int.tryParse(proteinController.text) ?? profile.targetProteinG,
                    targetCarbsG: int.tryParse(carbsController.text) ?? profile.targetCarbsG,
                    targetFatG: int.tryParse(fatController.text) ?? profile.targetFatG,
                    photoPath: _localPhotoPath,
                    clearPhoto: _clearPhoto,
                  );
                  ref.read(profileProvider.notifier).updateProfile(updated);
                  Navigator.of(context).pop();
                },
                child: Text('Save'),
              ),
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
