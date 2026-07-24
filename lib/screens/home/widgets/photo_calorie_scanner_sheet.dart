import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../services/gemini_food_service.dart';
import '../../../models/daily_meal_log.dart';

class PhotoCalorieScannerSheet extends ConsumerStatefulWidget {
  final String slotId;
  final String slotDisplayName;
  final bool isManualEntry;

  const PhotoCalorieScannerSheet({super.key, required this.slotId, required this.slotDisplayName, this.isManualEntry = false});

  @override
  ConsumerState<PhotoCalorieScannerSheet> createState() =>
      _PhotoCalorieScannerSheetState();
}

class _PhotoCalorieScannerSheetState
    extends ConsumerState<PhotoCalorieScannerSheet> {
  final _picker = ImagePicker();
  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _analysisComplete = false;
  String? _confidence;

  List<MealItemLog> _items = [];
  int _totalCalories = 0;
  double _totalProtein = 0.0;
  double _totalCarbs = 0.0;
  double _totalFat = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.isManualEntry) {
      _analysisComplete = true;
      _items = [];
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1200);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _isAnalyzing = true;
      _analysisComplete = false;
      _items = [];
    });

    try {
      final imageBytes = await picked.readAsBytes();
      String mimeType = picked.mimeType ?? 'image/jpeg';
      if (picked.path.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (picked.path.toLowerCase().endsWith('.webp')) {
        mimeType = 'image/webp';
      }

      final geminiService = ref.read(geminiFoodServiceProvider);
      final result = await geminiService.analyzeFoodImage(imageBytes, mimeType);

      if (result != null) {
        final itemsData = result['items'] as List?;
        final totalData = result['total'] as Map<String, dynamic>?;

        final newItems = (itemsData ?? []).map((i) {
          final m = i as Map<String, dynamic>;
          return MealItemLog(
            name: m['name']?.toString() ?? 'Unknown',
            portion: m['portion']?.toString() ?? '1 serving',
            calories: (m['calories'] as num?)?.toInt() ?? 0,
            proteinG: (m['protein_g'] as num?)?.toDouble() ?? 0.0,
            carbsG: (m['carbs_g'] as num?)?.toDouble() ?? 0.0,
            fatG: (m['fat_g'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        setState(() {
          _items = newItems;
          _totalCalories = (totalData?['calories'] as num?)?.toInt() ?? 0;
          _totalProtein = (totalData?['protein_g'] as num?)?.toDouble() ?? 0.0;
          _totalCarbs = (totalData?['carbs_g'] as num?)?.toDouble() ?? 0.0;
          _totalFat = (totalData?['fat_g'] as num?)?.toDouble() ?? 0.0;
          _confidence = result['confidence']?.toString();
          
          _isAnalyzing = false;
          _analysisComplete = true;
        });
      } else {
        _showError('AI could not analyze the image.');
      }
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void _showError(String message) {
    setState(() {
      _isAnalyzing = false;
      _selectedImage = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _recalculateTotals();
    });
  }

  void _editItem(int index) {
    final item = _items[index];
    final nameCtrl = TextEditingController(text: item.name);
    final portionCtrl = TextEditingController(text: item.portion);
    final calsCtrl = TextEditingController(text: item.calories.toString());
    final pCtrl = TextEditingController(text: item.proteinG.toString());
    final cCtrl = TextEditingController(text: item.carbsG.toString());
    final fCtrl = TextEditingController(text: item.fatG.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: portionCtrl, decoration: const InputDecoration(labelText: 'Portion')),
              TextField(controller: calsCtrl, decoration: const InputDecoration(labelText: 'Calories'), keyboardType: TextInputType.number),
              Row(
                children: [
                  Expanded(child: TextField(controller: pCtrl, decoration: const InputDecoration(labelText: 'Protein (g)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: cCtrl, decoration: const InputDecoration(labelText: 'Carbs (g)'), keyboardType: TextInputType.number)),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: fCtrl, decoration: const InputDecoration(labelText: 'Fat (g)'), keyboardType: TextInputType.number)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _items[index] = MealItemLog(
                  name: nameCtrl.text,
                  portion: portionCtrl.text,
                  calories: int.tryParse(calsCtrl.text) ?? 0,
                  proteinG: double.tryParse(pCtrl.text) ?? 0.0,
                  carbsG: double.tryParse(cCtrl.text) ?? 0.0,
                  fatG: double.tryParse(fCtrl.text) ?? 0.0,
                );
                _recalculateTotals();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    _items.add(MealItemLog(name: 'New Item', portion: '1 serving', calories: 0, proteinG: 0, carbsG: 0, fatG: 0));
    _editItem(_items.length - 1);
  }

  void _recalculateTotals() {
    int c = 0; double p = 0; double carbs = 0; double f = 0;
    for (final i in _items) {
      c += i.calories;
      p += i.proteinG;
      carbs += i.carbsG;
      f += i.fatG;
    }
    _totalCalories = c;
    _totalProtein = p;
    _totalCarbs = carbs;
    _totalFat = f;
  }

  Future<void> _saveMeal() async {
    final slotLog = MealSlotLog(
      photoPath: _selectedImage?.path,
      items: _items,
      totalCalories: _totalCalories,
      totalProtein: _totalProtein,
      totalCarbs: _totalCarbs,
      totalFat: _totalFat,
      confidence: _confidence,
    );
    await ref.read(dailyMealLogProvider.notifier).saveMealSlot(widget.slotId, slotLog);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Logged $_totalCalories Kcal for ${widget.slotDisplayName}! 🥗'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.center_focus_strong_rounded, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Log ${widget.slotDisplayName}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                    const Text('Snap a food picture to count calories & macros', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          if (_selectedImage == null && !widget.isManualEntry) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.lavender,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  const Icon(Icons.camera_alt_rounded, size: 48, color: AppColors.primary),
                  const SizedBox(height: 12),
                  const Text('Upload or Take a Food Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.camera_rounded, size: 18),
                        label: const Text('Camera'),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: const Icon(Icons.photo_library_rounded, size: 18),
                        label: const Text('Gallery'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (_selectedImage != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  kIsWeb
                      ? Image.network(_selectedImage!.path, height: 160, width: double.infinity, fit: BoxFit.cover)
                      : Image.file(_selectedImage!, height: 160, width: double.infinity, fit: BoxFit.cover),
                  if (_isAnalyzing)
                    Container(
                      height: 160,
                      color: Colors.black.withValues(alpha: 0.65),
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: AppColors.white, strokeWidth: 3),
                            SizedBox(height: 16),
                            Text('AI Analyzing Food Picture...', style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10, right: 10,
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedImage = null;
                        _analysisComplete = false;
                      }),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, color: AppColors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          if (_analysisComplete) ...[
            const SizedBox(height: 16),
            if (_confidence == 'low')
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.orange.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: AppColors.orange, size: 20),
                    SizedBox(width: 8),
                    Expanded(child: Text('Low confidence estimate — please check portions.', style: TextStyle(color: AppColors.orange, fontSize: 13, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, index) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              Text('${item.portion} • ${item.calories} Kcal', style: const TextStyle(fontSize: 13, color: AppColors.textMedium)),
                              Text('P: ${item.proteinG}g  C: ${item.carbsG}g  F: ${item.fatG}g', style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
                            ],
                          ),
                        ),
                        IconButton(icon: const Icon(Icons.edit_rounded, size: 20, color: AppColors.primary), onPressed: () => _editItem(index)),
                        IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.red), onPressed: () => _removeItem(index)),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.lavender, borderRadius: BorderRadius.circular(12)),
                    child: Column(
                      children: [
                        const Text('TOTAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        Text('$_totalCalories Kcal', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(onPressed: _addItem, icon: const Icon(Icons.add), label: const Text('Add Item')),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _saveMeal,
                icon: const Icon(Icons.check_circle_rounded, color: AppColors.white),
                label: const Text('Save Log', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
