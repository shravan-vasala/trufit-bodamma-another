import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_providers.dart';

class PhysiquePicturesScreen extends ConsumerStatefulWidget {
  const PhysiquePicturesScreen({super.key});

  @override
  ConsumerState<PhysiquePicturesScreen> createState() =>
      _PhysiquePicturesScreenState();
}

class _PhysiquePicturesScreenState
    extends ConsumerState<PhysiquePicturesScreen> {
  final _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final mediaRepo = ref.watch(mediaRepoProvider);
    final allPhotos = mediaRepo.getAllProgressPhotos();

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Physique Pictures'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addPhoto,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_a_photo_rounded, color: AppColors.white),
      ),
      body: allPhotos.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.photo_library_outlined,
                    size: 64,
                    color: AppColors.textLight.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No progress photos yet',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMedium,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap the + button to add your first photo',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: allPhotos.length,
              itemBuilder: (context, index) {
                final entry = allPhotos[index];
                final date = entry.key;
                final photos = entry.value;
                final formattedDate = _formatDate(date);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        formattedDate,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: photos.length,
                      itemBuilder: (context, i) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(photos[i]),
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, s) => Container(
                              color: AppColors.lavender,
                              child: const Icon(
                                Icons.broken_image_rounded,
                                color: AppColors.textLight,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEEE, dd MMM yyyy').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  Future<void> _addPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add Progress Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: AppColors.primary),
              title: const Text('Take Photo'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: AppColors.primary),
              title: const Text('Choose from Gallery'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null) return;

    final image = await _picker.pickImage(source: source, maxWidth: 1920);
    if (image == null) return;

    final date = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await ref.read(mediaRepoProvider).saveProgressPhoto(date, image.path);
    setState(() {}); // refresh
  }
}
