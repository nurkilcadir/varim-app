import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:varim_app/theme/app_theme.dart';

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
    'Magazin',
    'Siyaset',
    'Kripto',
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

  Future<void> _submitEvent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final title = _titleController.text.trim();
      final imageUrl = _imageUrlController.text.trim();
      final yesRatio = double.tryParse(_yesRatioController.text) ?? 1.85;
      final noRatio = double.tryParse(_noRatioController.text) ?? 1.85;
      final rule = _ruleController.text.trim();
      final endDate = Timestamp.fromDate(_getCombinedDateTime());

      // Validate ratios
      if (yesRatio <= 0 || noRatio <= 0) {
        throw Exception('Oranlar 0\'dan büyük olmalıdır');
      }

      // Create event document
      await FirebaseFirestore.instance.collection('events').add({
        'title': title,
        'category': _selectedCategory,
        'imageUrl': imageUrl,
        'yesRatio': yesRatio,
        'noRatio': noRatio,
        'endDate': endDate,
        'volume': 0,
        'status': 'active',
        if (rule.isNotEmpty) 'rule': rule,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Etkinlik başarıyla oluşturuldu!'),
            backgroundColor: AppTheme.varimColors(context).varimColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: AppTheme.varimColors(context).yokumColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
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
      backgroundColor: theme.colorScheme.surface,
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
                  value: _selectedCategory,
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
                    labelText: 'Görsel URL',
                    hintText: 'https://example.com/image.jpg',
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
                ),
                if (_imageUrlController.text.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      _imageUrlController.text,
                      height: 150,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 150,
                          color: theme.colorScheme.surfaceContainer,
                          child: Center(
                            child: Text(
                              'Görsel yüklenemedi',
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 150,
                          color: theme.colorScheme.surfaceContainer,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                varimColors.varimColor,
                              ),
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
                  ),
                  child: _isSubmitting
                      ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
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
