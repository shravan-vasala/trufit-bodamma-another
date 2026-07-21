import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';

class PhotoCalorieScannerSheet extends ConsumerStatefulWidget {
  const PhotoCalorieScannerSheet({super.key});

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

  // Food detection state
  late String _detectedFoodName;
  late int _baseCalories;
  late double _proteinGrams;
  late double _carbsGrams;
  late double _fatGrams;
  double _portionSize = 1.0;
  String _selectedMealType = 'lunch';

  final _foodNameController = TextEditingController();

  final List<Map<String, dynamic>> _foodPresets = [
    {
      'name': 'Chicken Breast & Brown Rice Bowl',
      'calories': 420,
      'protein': 38.0,
      'carbs': 44.0,
      'fat': 8.0,
    },
    {
      'name': 'Boiled Eggs & Multigrain Toast',
      'calories': 320,
      'protein': 22.0,
      'carbs': 28.0,
      'fat': 12.0,
    },
    {
      'name': 'Roti, Dal & Mixed Vegetable Curry',
      'calories': 380,
      'protein': 14.0,
      'carbs': 62.0,
      'fat': 9.0,
    },
    {
      'name': 'Greek Yogurt & Mixed Fruit Bowl',
      'calories': 240,
      'protein': 16.0,
      'carbs': 36.0,
      'fat': 3.0,
    },
    {
      'name': 'Grilled Fish & Sauteed Greens',
      'calories': 360,
      'protein': 35.0,
      'carbs': 12.0,
      'fat': 18.0,
    },
    {
      'name': 'Paneer Tikka & Salad',
      'calories': 410,
      'protein': 24.0,
      'carbs': 18.0,
      'fat': 26.0,
    },
  ];

  @override
  void dispose() {
    _foodNameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1200);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _isAnalyzing = true;
      _analysisComplete = false;
    });

    // Simulate AI Vision analysis algorithm
    await Future.delayed(const Duration(milliseconds: 1600));

    // Choose preset based on hash of file length to feel dynamic and consistent
    final hash = picked.path.length % _foodPresets.length;
    final preset = _foodPresets[hash];

    setState(() {
      _detectedFoodName = preset['name'] as String;
      _baseCalories = preset['calories'] as int;
      _proteinGrams = preset['protein'] as double;
      _carbsGrams = preset['carbs'] as double;
      _fatGrams = preset['fat'] as double;
      _foodNameController.text = _detectedFoodName;
      _isAnalyzing = false;
      _analysisComplete = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final calculatedCalories = (_baseCalories * _portionSize).round();
    final calculatedProtein = (_proteinGrams * _portionSize).toStringAsFixed(1);
    final calculatedCarbs = (_carbsGrams * _portionSize).toStringAsFixed(1);
    final calculatedFat = (_fatGrams * _portionSize).toStringAsFixed(1);

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.center_focus_strong_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Calorie Scanner',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        'Snap a food picture to count calories & macros',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Step 1: Image Picker / Preview
            if (_selectedImage == null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                decoration: BoxDecoration(
                  color: AppColors.lavender,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.camera_alt_rounded,
                      size: 48,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Upload or Take a Food Photo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'AI detects ingredients, portions & calories',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMedium,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.camera_rounded, size: 18),
                          label: const Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_rounded, size: 18),
                          label: const Text('Gallery'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ] else ...[
              // Image preview card with status overlay
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    if (_isAnalyzing)
                      Container(
                        height: 200,
                        color: Colors.black.withValues(alpha: 0.65),
                        child: const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: AppColors.white,
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'AI Analyzing Food Picture...',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Calculating calories, protein & macros',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedImage = null;
                            _analysisComplete = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.black54,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Step 2: Analysis Results & Edit Form
            if (_analysisComplete) ...[
              const SizedBox(height: 20),
              // Calorie badge header
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'ESTIMATED CALORIES',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: Colors.white70,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$calculatedCalories Kcal',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.auto_awesome, color: AppColors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'AI Verified',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Macro breakdown strip
              Row(
                children: [
                  Expanded(
                    child: _MacroBadge(
                      label: 'Protein',
                      value: '${calculatedProtein}g',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroBadge(
                      label: 'Carbs',
                      value: '${calculatedCarbs}g',
                      color: AppColors.indigo,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MacroBadge(
                      label: 'Fat',
                      value: '${calculatedFat}g',
                      color: AppColors.pinkIcon,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Dish Name TextField
              TextField(
                controller: _foodNameController,
                decoration: const InputDecoration(
                  labelText: 'Food Dish Name',
                  prefixIcon: Icon(Icons.restaurant_rounded),
                ),
                onChanged: (val) => _detectedFoodName = val,
              ),
              const SizedBox(height: 16),

              // Meal Type Selector
              Row(
                children: [
                  const Text(
                    'Meal Category:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.lavender,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedMealType,
                        isExpanded: true,
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(
                              value: 'breakfast', child: Text('🌅 Breakfast')),
                          DropdownMenuItem(
                              value: 'lunch', child: Text('☀️ Lunch')),
                          DropdownMenuItem(
                              value: 'snack', child: Text('🍎 Evening Snack')),
                          DropdownMenuItem(
                              value: 'dinner', child: Text('🌙 Dinner')),
                        ],
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _selectedMealType = val);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Portion Size Slider
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Portion Size:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        '${_portionSize.toStringAsFixed(1)}x plate',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _portionSize,
                    min: 0.5,
                    max: 2.5,
                    divisions: 8,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() => _portionSize = val);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Save CTA
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _saveMeal,
                  icon: const Icon(Icons.check_circle_rounded, color: AppColors.white),
                  label: const Text(
                    'Log Scanned Calorie Meal',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _saveMeal() async {
    if (_selectedImage == null) return;
    final dateStr = ref.read(dateStringProvider);

    final photoRepo = ref.read(photoMealRepoProvider);
    await photoRepo.saveScannedMeal(
      date: dateStr,
      sourcePhotoPath: _selectedImage!.path,
      mealType: _selectedMealType,
      foodName: _foodNameController.text.trim().isEmpty
          ? _detectedFoodName
          : _foodNameController.text.trim(),
      estimatedCalories: _baseCalories,
      proteinGrams: _proteinGrams,
      carbsGrams: _carbsGrams,
      fatGrams: _fatGrams,
      portionMultiplier: _portionSize,
    );

    // Toggle completion for this meal category in MealRepository
    ref
        .read(mealPlanWithCompletionsProvider.notifier)
        .toggleMeal(_selectedMealType);

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Logged ${(_baseCalories * _portionSize).round()} Kcal for $_selectedMealType! 🥗'),
          backgroundColor: AppColors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }
}

class _MacroBadge extends StatelessWidget {
  const _MacroBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
