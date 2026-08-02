import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_colors.dart';
import '../../../providers/app_providers.dart';
import '../../../services/gemini_food_service.dart';
import '../../../models/daily_meal_log.dart';
import 'package:path_provider/path_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../../widgets/app_bottom_sheet.dart';
import '../../../widgets/async_error_card.dart';
import '../../../widgets/offline_banner.dart';
import '../../../widgets/primary_button.dart';

/// Opens with photo-first capture, or describe-in-text when [isManualEntry] is true.
class PhotoCalorieScannerSheet extends ConsumerStatefulWidget {
  final String slotId;
  final String slotDisplayName;
  final bool isManualEntry;

  const PhotoCalorieScannerSheet({
    super.key,
    required this.slotId,
    required this.slotDisplayName,
    this.isManualEntry = false,
  });

  @override
  ConsumerState<PhotoCalorieScannerSheet> createState() =>
      _PhotoCalorieScannerSheetState();
}

class _PhotoCalorieScannerSheetState
    extends ConsumerState<PhotoCalorieScannerSheet> {
  final _picker = ImagePicker();
  final _descriptionCtrl = TextEditingController();

  File? _selectedImage;
  bool _isAnalyzing = false;
  bool _analysisComplete = false;
  bool _describeMode = false;
  String? _confidence;
  String? _errorMessage;
  bool _isOffline = false;

  List<MealItemLog> _items = [];
  int _totalCalories = 0;
  double _totalProtein = 0.0;
  double _totalCarbs = 0.0;
  double _totalFat = 0.0;

  @override
  void initState() {
    super.initState();
    _describeMode = widget.isManualEntry;
    if (_describeMode) {
      // Stay on describe form until she estimates or adds items herself.
      _analysisComplete = false;
    }
    _checkConnectivity();
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    setState(() {
      _isOffline = connectivityResult.contains(ConnectivityResult.none);
    });
  }

  void _applyResult(Map<String, dynamic> result) {
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
      _errorMessage = null;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, maxWidth: 1200);
    if (picked == null) return;

    setState(() {
      _selectedImage = File(picked.path);
      _describeMode = false;
      _isAnalyzing = true;
      _analysisComplete = false;
      _errorMessage = null;
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

      final result = await ref
          .read(geminiFoodServiceProvider)
          .analyzeFoodImage(imageBytes, mimeType);

      if (result != null) {
        _applyResult(result);
      } else {
        _showError('AI could not analyze the image.');
      }
    } catch (e) {
      _handleAnalyzeError(e);
    }
  }

  Future<void> _analyzeDescription() async {
    final text = _descriptionCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Type what you ate first — e.g. rice, sambar, curd')),
      );
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _analysisComplete = false;
      _errorMessage = null;
      _items = [];
      _selectedImage = null;
    });

    try {
      final result =
          await ref.read(geminiFoodServiceProvider).analyzeFoodText(text);
      if (result != null) {
        _applyResult(result);
      } else {
        _showError('AI could not estimate from that description.');
      }
    } catch (e) {
      _handleAnalyzeError(e);
    }
  }

  void _handleAnalyzeError(Object e) {
    final msg = e.toString();
    if (msg.contains('FormatException') || msg.contains('json')) {
      _showError('Couldn\'t analyze — try again or add items yourself.');
    } else if (msg.contains('api key') || msg.contains('API key')) {
      _showError('Invalid API key. Add it in Profile → AI Settings.');
    } else if (msg.contains('SocketException') || msg.contains('network')) {
      _showError('Network error. Please check your connection.');
    } else {
      _showError(msg.replaceAll('Exception: ', ''));
    }
  }

  void _showError(String message) {
    setState(() {
      _isAnalyzing = false;
      _errorMessage = message;
    });
  }

  void _switchToDescribe() {
    setState(() {
      _describeMode = true;
      _selectedImage = null;
      _analysisComplete = false;
      _errorMessage = null;
      _isAnalyzing = false;
      _items = [];
    });
  }

  void _switchToPhoto() {
    setState(() {
      _describeMode = false;
      _analysisComplete = false;
      _errorMessage = null;
      _isAnalyzing = false;
      _items = [];
    });
  }

  void _enterManualItems() {
    setState(() {
      _errorMessage = null;
      _isAnalyzing = false;
      _analysisComplete = true;
      if (_items.isEmpty) {
        _items = [
          MealItemLog(
            name: 'Home cooked meal',
            portion: '1 serving',
            calories: 0,
            proteinG: 0,
            carbsG: 0,
            fatG: 0,
          ),
        ];
      }
    });
    if (_items.length == 1 && _items.first.calories == 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _editItem(0));
    }
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
        title: Text('Edit Item'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(labelText: 'Name'),
              ),
              TextField(
                controller: portionCtrl,
                decoration: InputDecoration(labelText: 'Portion'),
              ),
              TextField(
                controller: calsCtrl,
                decoration: InputDecoration(labelText: 'Calories'),
                keyboardType: TextInputType.number,
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: pCtrl,
                      decoration: InputDecoration(labelText: 'Protein (g)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: cCtrl,
                      decoration: InputDecoration(labelText: 'Carbs (g)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: fCtrl,
                      decoration: InputDecoration(labelText: 'Fat (g)'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
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
            child: Text('Save'),
          ),
        ],
      ),
    );
  }

  void _addItem() {
    _items.add(
      MealItemLog(
        name: 'New Item',
        portion: '1 serving',
        calories: 0,
        proteinG: 0,
        carbsG: 0,
        fatG: 0,
      ),
    );
    _editItem(_items.length - 1);
  }

  void _recalculateTotals() {
    int c = 0;
    double p = 0;
    double carbs = 0;
    double f = 0;
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
    String? finalPhotoPath;
    if (_selectedImage != null) {
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'meal_photo_$timestamp.jpg';
        final savedImage =
            await _selectedImage!.copy('${appDir.path}/$fileName');
        finalPhotoPath = savedImage.path;
      } else {
        finalPhotoPath = _selectedImage!.path;
      }
    }

    final slotLog = MealSlotLog(
      name: widget.slotDisplayName,
      photoPath: finalPhotoPath,
      items: _items,
      totalCalories: _totalCalories,
      totalProtein: _totalProtein,
      totalCarbs: _totalCarbs,
      totalFat: _totalFat,
      confidence: _confidence,
    );
    await ref.read(dailyMealLogProvider.notifier).saveMealSlot(widget.slotId, slotLog);

    if (mounted) {
      HapticFeedback.mediumImpact();
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Logged $_totalCalories kcal for ${widget.slotDisplayName}!',
          ),
          backgroundColor: context.colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final showChooser = !_analysisComplete &&
        !_isAnalyzing &&
        _errorMessage == null &&
        _selectedImage == null;

    return AppSheet(
      scrollable: _analysisComplete,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_isOffline && !_analysisComplete)
            Padding(
              padding: EdgeInsets.only(bottom: 12.0),
              child: OfflineBanner(),
            ),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: context.colors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _describeMode
                      ? Icons.edit_note_rounded
                      : Icons.camera_alt_rounded,
                  color: context.colors.primary,
                  size: 24,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Log ${widget.slotDisplayName}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: context.colors.textDark,
                      ),
                    ),
                    Text(
                      _describeMode
                          ? 'Describe home cooking — AI estimates macros'
                          : 'Photo of your plate works best for home meals',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.colors.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          if (showChooser && !_describeMode) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: context.colors.lavenderCard,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: context.colors.primary.withValues(alpha: 0.2),
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.camera_alt_rounded,
                    size: 48,
                    color: context.colors.primary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Snap what you ate',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: context.colors.textDark,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Best for home-cooked plates',
                    style: TextStyle(
                      fontSize: 12,
                      color: context.colors.textMedium,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _pickImage(ImageSource.camera),
                        icon: Icon(Icons.camera_rounded, size: 18),
                        label: Text('Camera'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.colors.primary,
                        ),
                      ),
                      SizedBox(width: 12),
                      OutlinedButton.icon(
                        onPressed: () => _pickImage(ImageSource.gallery),
                        icon: Icon(Icons.photo_library_rounded, size: 18),
                        label: Text('Gallery'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _switchToDescribe,
                icon: Icon(Icons.notes_rounded, size: 18),
                label: Text('Or describe in text'),
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _enterManualItems,
                child: Text(
                  'Enter macros yourself',
                  style: TextStyle(
                    fontSize: 13,
                    color: context.colors.textMedium,
                  ),
                ),
              ),
            ),
          ] else if (showChooser && _describeMode) ...[
            Text(
              'What did you eat?',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: context.colors.textDark,
              ),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _descriptionCtrl,
              maxLines: 4,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                hintText:
                    'e.g. 1 cup rice, chicken curry, beans fry, curd',
                alignLabelWithHint: true,
              ),
            ),
            SizedBox(height: 14),
            PrimaryButton(
              label: 'Estimate macros',
              icon: Icons.auto_awesome_rounded,
              onPressed: _isOffline ? null : _analyzeDescription,
              isLoading: _isAnalyzing,
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _switchToPhoto,
                    icon: Icon(Icons.camera_alt_rounded, size: 18),
                    label: Text('Use photo'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: TextButton(
                    onPressed: _enterManualItems,
                    child: Text('Enter yourself'),
                  ),
                ),
              ],
            ),
          ] else if (_errorMessage != null) ...[
            AsyncErrorCard(
              title: 'Analysis Failed',
              message: _errorMessage!,
              onRetry: () {
                setState(() => _errorMessage = null);
                if (_describeMode) {
                  _analyzeDescription();
                } else {
                  _pickImage(ImageSource.gallery);
                }
              },
              actionText: _describeMode ? 'Try again' : 'Try another photo',
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _errorMessage = null);
                      _switchToDescribe();
                    },
                    child: Text('Describe instead'),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _enterManualItems,
                    child: Text('Enter yourself'),
                  ),
                ),
              ],
            ),
          ] else if (_selectedImage != null || _isAnalyzing) ...[
            if (_selectedImage != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    kIsWeb
                        ? Image.network(
                            _selectedImage!.path,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            _selectedImage!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                    if (_isAnalyzing)
                      Container(
                        height: 160,
                        color: Colors.black.withValues(alpha: 0.65),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(
                                color: context.colors.card,
                                strokeWidth: 3,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Reading your plate…',
                                style: TextStyle(
                                  color: context.colors.onPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (!_isAnalyzing)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedImage = null;
                            _analysisComplete = false;
                          }),
                          child: Container(
                            padding: EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close_rounded,
                              color: context.colors.onPrimary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              )
            else if (_isAnalyzing)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Estimating from your description…',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: context.colors.textMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],

          if (_analysisComplete) ...[
            SizedBox(height: 16),
            if (_confidence == 'low')
              Container(
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: context.colors.orange,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Low confidence estimate — please check portions.',
                        style: TextStyle(
                          color: context.colors.orange,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: ListView.separated(
                physics: BouncingScrollPhysics(),
                itemCount: _items.length,
                separatorBuilder: (_, index) => SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${item.portion} • ${item.calories} kcal',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.colors.textMedium,
                                ),
                              ),
                              Text(
                                'P: ${item.proteinG}g  C: ${item.carbsG}g  F: ${item.fatG}g',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: context.colors.textMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.edit_rounded,
                            size: 20,
                            color: context.colors.primary,
                          ),
                          onPressed: () => _editItem(index),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: context.colors.red,
                          ),
                          onPressed: () => _removeItem(index),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.colors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'TOTAL',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: context.colors.primary,
                          ),
                        ),
                        Text(
                          '$_totalCalories kcal',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.colors.textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: Icon(Icons.add),
                  label: Text('Add Item'),
                ),
              ],
            ),
            SizedBox(height: 16),
            PrimaryButton(
              label: 'Save Log',
              icon: Icons.check_circle_rounded,
              onPressed: _saveMeal,
            ),
          ],
        ],
      ),
    );
  }
}
