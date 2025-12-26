import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/theme/design_system.dart';

/// Screen for creating new events (Admin only)
class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _yesRatioController = TextEditingController(text: '1.85');
  final _noRatioController = TextEditingController(text: '1.85');
  final _ruleController = TextEditingController();

  String _selectedCategory = 'Spor';
  DateTime _selectedEndDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 23, minute: 59);
  bool _isSubmitting = false;

  final List<String> _categories = [
    'Spor',
    'Ekonomi',
    'TV & Magazin',
    'Kripto',
    'E-Spor',
    'Gündem',
  ];

  @override
  void initState() {
    super.initState();
    // Listen to image URL changes for preview
    _imageUrlController.addListener(() {
      setState(() {}); // Rebuild to show/hide preview
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _imageUrlController.dispose();
    _yesRatioController.dispose();
    _noRatioController.dispose();
    _ruleController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedEndDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedEndDate = picked;
      });
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  DateTime _getCombinedDateTime() {
    return DateTime(
      _selectedEndDate.year,
      _selectedEndDate.month,
      _selectedEndDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
  }

  bool _isValidImageUrl(String url) {
    if (url.trim().isEmpty) return false;
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate image URL
    final imageUrl = _imageUrlController.text.trim();
    if (imageUrl.isEmpty || !_isValidImageUrl(imageUrl)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen geçerli bir görsel URL\'si girin'),
          backgroundColor: AppTheme.varimColors(context).yokumColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final title = _titleController.text.trim();
      final rule = _ruleController.text.trim();
      final closingDate = _getCombinedDateTime();
      
      // Get VARIM ratio input (e.g., "1.85" - decimal odds)
      final varimRateText = _yesRatioController.text.trim();
      final varimRate = double.tryParse(varimRateText);
      
      if (varimRate == null || varimRate <= 0) {
        throw Exception('VARIM oranı geçerli bir sayı olmalıdır');
      }

      // Calculate yesRatio for Firestore: yesRatio = 1.0 / input
      // Example: If input is 1.85, yesRatio = 1.0 / 1.85 ≈ 0.54
      // This stores the probability, not the decimal odds
      final yesRatio = 1.0 / varimRate;
      
      // Calculate noRatio similarly
      final noRatioText = _noRatioController.text.trim();
      final noRatioInput = double.tryParse(noRatioText);
      final noRatio = noRatioInput != null && noRatioInput > 0 
          ? 1.0 / noRatioInput 
          : (1.0 - yesRatio); // Fallback to complementary probability

      // Create event document with all required fields
      await FirebaseFirestore.instance.collection('events').add({
        'title': title,
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'yesRatio': yesRatio, // Probability (1.0 / input odds)
        'noRatio': noRatio, // Probability (1.0 / input odds)
        'rule': rule.isNotEmpty ? rule : 'Bu etkinlik resmi sonuçlara göre yönetici tarafından sonuçlandırılacaktır.',
        'endDate': Timestamp.fromDate(closingDate),
        'volume': 0,
        'poolYes': 0,
        'poolNo': 0,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Etkinlik başarıyla oluşturuldu!'),
            backgroundColor: AppTheme.varimColors(context).varimColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // Extract error message
        String errorMessage = 'Bilinmeyen bir hata oluştu';
        if (e is Exception) {
          errorMessage = e.toString().replaceFirst('Exception: ', '');
        } else {
          errorMessage = e.toString();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $errorMessage'),
            backgroundColor: AppTheme.varimColors(context).yokumColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5), // Longer duration for error messages
            action: SnackBarAction(
              label: 'Tamam',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } finally {
      // Always reset loading state, even if there's an error
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);

    return Scaffold(
      backgroundColor: DesignSystem.backgroundDeep,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: theme.colorScheme.onSurface,
        ),
        title: Text(
          'Yeni Etkinlik Oluştur',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Title Field
                TextFormField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Etkinlik Başlığı *',
                    hintText: 'Örn: Fenerbahçe vs Galatasaray',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: varimColors.varimColor,
                        width: 2,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Başlık gereklidir';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Category Dropdown
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Kategori *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: varimColors.varimColor,
                        width: 2,
                      ),
                    ),
                  ),
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 20),

                // Image URL Field with Preview
                TextFormField(
                  controller: _imageUrlController,
                  decoration: InputDecoration(
                    labelText: 'Görsel URL *',
                    hintText: 'https://example.com/image.jpg',
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: varimColors.varimColor,
                        width: 2,
                      ),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: varimColors.yokumColor,
                        width: 1,
                      ),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Görsel URL\'si gereklidir';
                    }
                    if (!_isValidImageUrl(value)) {
                      return 'Geçerli bir URL girin (http:// veya https://)';
                    }
                    return null;
                  },
                ),
                if (_imageUrlController.text.isNotEmpty && _isValidImageUrl(_imageUrlController.text)) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _imageUrlController.text,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: DesignSystem.surfaceLight,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  color: varimColors.yokumColor,
                                  size: 48,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Görsel yüklenemedi',
                                  style: theme.textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'URL\'yi kontrol edin',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: DesignSystem.textBody,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          color: DesignSystem.surfaceLight,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    varimColors.varimColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Görsel yükleniyor...',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Ratios Row
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _yesRatioController,
                        decoration: InputDecoration(
                          labelText: 'VARIM Oranı *',
                          hintText: '1.85',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: varimColors.varimColor,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final ratio = double.tryParse(value ?? '');
                          if (ratio == null || ratio <= 0) {
                            return 'Geçerli bir oran girin';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _noRatioController,
                        decoration: InputDecoration(
                          labelText: 'YOKUM Oranı *',
                          hintText: '1.85',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                              color: varimColors.yokumColor,
                              width: 2,
                            ),
                          ),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final ratio = double.tryParse(value ?? '');
                          if (ratio == null || ratio <= 0) {
                            return 'Geçerli bir oran girin';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Rule Field (Multiline)
                TextFormField(
                  controller: _ruleController,
                  decoration: InputDecoration(
                    labelText: 'Sonuçlandırma Kuralı & Kaynak',
                    hintText: 'Örn: Merkez Bankası\'nın resmi açıklamasına göre...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: varimColors.varimColor,
                        width: 2,
                      ),
                    ),
                  ),
                  maxLines: 4,
                ),
                const SizedBox(height: 20),

                // End Date & Time Picker
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: theme.colorScheme.surfaceContainerHighest,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bitiş Tarihi ve Saati *',
                        style: theme.textTheme.labelLarge,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _selectDate,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      size: 20,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_selectedEndDate.day}/${_selectedEndDate.month}/${_selectedEndDate.year}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: InkWell(
                              onTap: _selectTime,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 20,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedTime.format(context),
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitEvent,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: varimColors.varimColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    disabledBackgroundColor: varimColors.varimColor.withValues(alpha: 0.6),
                  ),
                  child: _isSubmitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Yükleniyor...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Etkinlik Oluştur',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
