import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/theme/design_system.dart';
import 'package:varim_app/providers/user_provider.dart';
import 'package:varim_app/models/event_model.dart';

/// Trading terminal style betting screen
class BetDetailScreen extends StatefulWidget {
  final EventModel event;

  const BetDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<BetDetailScreen> createState() => _BetDetailScreenState();
}

class _BetDetailScreenState extends State<BetDetailScreen> with TickerProviderStateMixin {
  // State variables - PRESERVED
  bool _isPlacingBet = false;
  String _selectedSide = 'VARIM'; // 'VARIM' or 'YOKUM'
  int _quantity = 1; // Share count instead of slider value
  final TextEditingController _quantityController = TextEditingController(text: '1');
  late TabController _tabController;
  
  // Animation controllers for gamification
  late AnimationController _stampAnimationController;
  late Animation<double> _stampScaleAnimation;
  late Animation<double> _stampGlowAnimation;
  
  // Audio players for sound effects
  final AudioPlayer _tickPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedSide = _tabController.index == 0 ? 'VARIM' : 'YOKUM';
        });
      }
    });
    
    // Initialize stamp animation controller
    _stampAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // Scale animation with overshoot effect
    _stampScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _stampAnimationController,
        curve: Curves.elasticOut,
      ),
    );
    
    // Glow pulse animation
    _stampGlowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _stampAnimationController,
        curve: Curves.easeInOut,
      ),
    );
    
    // Configure audio players for sound effects
    _tickPlayer.setReleaseMode(ReleaseMode.release);
    _successPlayer.setReleaseMode(ReleaseMode.release);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _quantityController.dispose();
    _stampAnimationController.dispose();
    _tickPlayer.dispose();
    _successPlayer.dispose();
    super.dispose();
  }
  
  // Sound effect methods
  void _playTickSound() {
    // Use unawaited to avoid blocking UI
    _tickPlayer.play(AssetSource('sounds/click.wav'), volume: 0.3).catchError((e) {
      debugPrint('Error playing tick sound: $e');
    });
  }
  
  void _playChachingSound() {
    // Use unawaited to avoid blocking UI
    _successPlayer.play(AssetSource('sounds/success.wav'), volume: 0.7).catchError((e) {
      debugPrint('Error playing success sound: $e');
    });
  }

  // Calculate price per share based on probability (YES percentage)
  int get pricePerShare {
    // Convert probability to VP price (e.g., 55% = 55 VP per share)
    if (_selectedSide == 'VARIM') {
      return (widget.event.varimPercentage * 100).toInt();
    } else {
      return (widget.event.yokumPercentage * 100).toInt();
    }
  }

  // Calculate total cost (this becomes _wagerAmount for betting logic)
  int get totalCost {
    return pricePerShare * _quantity;
  }

  // Calculate estimated payout (100 VP per share if win)
  int get estimatedPayout {
    return 100 * _quantity;
  }

  // Get current odd - PRESERVED for betting logic
  double get currentOdd {
    return _selectedSide == 'VARIM' ? widget.event.yesRatio : widget.event.noRatio;
  }

  void _incrementQuantity() {
    HapticFeedback.selectionClick(); // Tick feeling
    _playTickSound();
    setState(() {
      _quantity++;
      _quantityController.text = _quantity.toString();
    });
  }

  void _decrementQuantity() {
    if (_quantity > 1) {
      HapticFeedback.selectionClick(); // Tick feeling
      _playTickSound();
      setState(() {
        _quantity--;
        _quantityController.text = _quantity.toString();
      });
    }
  }

  void _updateQuantityFromText() {
    final rawValue = int.tryParse(_quantityController.text) ?? 1;
    // Clamp the value first to get the actual final value
    final clampedValue = rawValue < 1 ? 1 : (rawValue > 999 ? 999 : rawValue);
    
    // Only trigger feedback if the clamped value actually changed
    if (clampedValue != _quantity) {
      HapticFeedback.selectionClick(); // Tick feeling
      _playTickSound();
    }
    
    setState(() {
      _quantity = clampedValue;
      _quantityController.text = _quantity.toString();
    });
  }
  
  // Calculate max affordable quantity based on user balance
  int _getMaxQuantity(int userBalance) {
    if (pricePerShare == 0) return 1;
    return (userBalance / pricePerShare).floor().clamp(1, 999);
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final userBalance = userProvider.balance;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep Slate - Strict color
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
          color: DesignSystem.textHeading,
        ),
        title: Text(
          'İşlem Ekranı',
          style: TextStyle(
            color: DesignSystem.textHeading,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Event Image & Title Header
                if (widget.event.imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(24),
                      bottomRight: Radius.circular(24),
                    ),
                    child: Image.network(
                      widget.event.imageUrl,
                      height: 180,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: DesignSystem.surfaceLight,
                          child: Icon(
                            Icons.image_not_supported,
                            size: 48,
                            color: DesignSystem.textBody,
                          ),
                        );
                      },
                    ),
                  ),
                
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Event Title
                      Text(
                        widget.event.title,
                        style: DesignSystem.headingLarge.copyWith(
                          fontSize: 22,
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Settlement Rule Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DesignSystem.primaryAccentLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DesignSystem.primaryAccent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: DesignSystem.primaryAccent,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sonuçlandırma Kuralı',
                                    style: DesignSystem.headingSmall.copyWith(
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    (widget.event.rule?.isNotEmpty == true)
                                        ? widget.event.rule!
                                        : 'Bu etkinlik resmi sonuçlara göre yönetici tarafından sonuçlandırılacaktır.',
                                    style: DesignSystem.bodySmall.copyWith(
                                      fontSize: 12,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Chart Section
                      Container(
                        height: 160,
                        decoration: BoxDecoration(
                          color: DesignSystem.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: DesignSystem.border,
                            width: 1,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _TrendChartPainter(
                            yesPercentage: widget.event.varimPercentage,
                            noPercentage: widget.event.yokumPercentage,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Current Price Display (Dynamic)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: DesignSystem.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DesignSystem.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Güncel Fiyat (${_selectedSide == 'VARIM' ? 'EVET' : 'HAYIR'})',
                                  style: DesignSystem.bodyMedium,
                                ),
                                Text(
                                  '$pricePerShare VP',
                                  style: DesignSystem.headingMedium.copyWith(
                                    color: _selectedSide == 'VARIM' 
                                      ? DesignSystem.successGreen 
                                      : DesignSystem.errorRose,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Kullanılabilir Bakiye',
                                  style: DesignSystem.bodySmall.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  '${userBalance.toStringAsFixed(0)} VP',
                                  style: DesignSystem.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: DesignSystem.textHeading,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Trading Panel Header
                      Text(
                        'İşlem Paneli',
                        style: DesignSystem.headingMedium.copyWith(
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // YES / NO Tab Selector
                      Container(
                        decoration: BoxDecoration(
                          color: DesignSystem.surfaceLight,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: DesignSystem.border,
                            width: 1,
                          ),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: _tabController.index == 0
                                ? DesignSystem.successGreen
                                : DesignSystem.errorRose,
                          ),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerColor: Colors.transparent,
                          labelColor: Colors.black,
                          unselectedLabelColor: DesignSystem.textBody,
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                          tabs: [
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('EVET'),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(widget.event.varimPercentage * 100).toInt()}%',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            Tab(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text('HAYIR'),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${(widget.event.yokumPercentage * 100).toInt()}%',
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Quantity Input Section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: DesignSystem.surfaceLight,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: DesignSystem.border,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            // Quantity Label
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Adet (Hisse)',
                                  style: DesignSystem.bodyMedium.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Maks: ${_getMaxQuantity(userBalance)} adet',
                                  style: DesignSystem.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: DesignSystem.textBody,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Quantity Input with +/- buttons
                            Row(
                              children: [
                                // Minus Button
                                _QuantityButton(
                                  icon: Icons.remove,
                                  onPressed: _decrementQuantity,
                                  color: DesignSystem.errorRose,
                                ),
                                const SizedBox(width: 12),

                                // Quantity Text Field
                                Expanded(
                                  child: Container(
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: DesignSystem.backgroundDeep,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: DesignSystem.primaryAccent.withValues(alpha: 0.3),
                                        width: 1.5,
                                      ),
                                    ),
                                    child: TextField(
                                      controller: _quantityController,
                                      textAlign: TextAlign.center,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                                      style: DesignSystem.headingLarge.copyWith(
                                        fontSize: 28,
                                      ),
                                      decoration: const InputDecoration(
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.zero,
                                      ),
                                      onChanged: (value) => _updateQuantityFromText(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // Plus Button
                                _QuantityButton(
                                  icon: Icons.add,
                                  onPressed: _incrementQuantity,
                                  color: DesignSystem.successGreen,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // Calculation Breakdown
                            _CalculationRow(
                              label: 'Fiyat',
                              value: '$pricePerShare VP',
                            ),
                            const SizedBox(height: 12),
                            _CalculationRow(
                              label: 'Adet',
                              value: 'x $_quantity',
                            ),
                            const Divider(height: 24, color: DesignSystem.border),
                            _CalculationRow(
                              label: 'Toplam Maliyet',
                              value: '$totalCost VP',
                              isTotal: true,
                              color: DesignSystem.primaryAccent,
                            ),
                            const SizedBox(height: 12),
                            _CalculationRow(
                              label: 'Tahmini Ödeme',
                              value: '$estimatedPayout VP',
                              isTotal: true,
                              color: DesignSystem.successGreen,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100), // Space for bottom button
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Fixed Bottom Confirm Button
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: DesignSystem.backgroundDeep,
                border: Border(
                  top: BorderSide(
                    color: DesignSystem.border,
                    width: 1,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: ElevatedButton(
                  onPressed: _isPlacingBet
                      ? null
                      : () {
                          if (totalCost > userBalance) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Yetersiz bakiye! Mevcut: $userBalance VP'),
                                backgroundColor: DesignSystem.errorRose,
                              ),
                            );
                            return;
                          }
                          _placeBet(_selectedSide == 'VARIM');
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedSide == 'VARIM'
                        ? DesignSystem.successGreen
                        : DesignSystem.errorRose,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    disabledBackgroundColor: DesignSystem.textBody,
                  ),
                  child: _isPlacingBet
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle, size: 24),
                            const SizedBox(width: 12),
                            Text(
                              'EMRİ ONAYLA ($totalCost VP)',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),

          // Loading Overlay
          if (_isPlacingBet)
            Container(
              color: const Color(0xFF0F172A).withValues(alpha: 0.9),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        DesignSystem.successGreen,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Emir işleniyor...',
                      style: DesignSystem.bodyLarge.copyWith(
                        color: DesignSystem.textHeading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ========== PRESERVED BETTING LOGIC ==========
  void _placeBet(bool isVarim) async {
    final varimColors = AppTheme.varimColors(context);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;

    // Check if user is authenticated
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Giriş yapmanız gerekiyor!'),
          backgroundColor: varimColors.yokumColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Convert totalCost to wagerAmount for betting logic
    final wagerAmountInt = totalCost;

    // Check if user has enough balance
    if (wagerAmountInt > userProvider.balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Yetersiz bakiye! Mevcut bakiye: ${userProvider.balance} VP',
          ),
          backgroundColor: varimColors.yokumColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Validate wager amount
    if (wagerAmountInt < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Minimum bahis tutarı: 10 VP'),
          backgroundColor: varimColors.yokumColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Set loading state
    setState(() {
      _isPlacingBet = true;
    });

    try {
      // Use the event ID from the EventModel
      final eventId = widget.event.id;
      final choice = isVarim ? 'VARIM' : 'YOKUM';
      
      // Get the current odds for the selected choice
      final currentOdds = isVarim ? widget.event.yesRatio : widget.event.noRatio;
      
      // Calculate potential win: amount * odds
      final potentialWin = (wagerAmountInt * currentOdds).toInt();

      // Run Firestore transaction
      await FirebaseFirestore.instance.runTransaction(
        (Transaction transaction) async {
          // Step 1: Read the latest user document
          final userDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);
          final userDoc = await transaction.get(userDocRef);

          if (!userDoc.exists) {
            throw Exception('Kullanıcı belgesi bulunamadı');
          }

          final currentBalance = (userDoc.data()?['balance'] as num?)?.toInt() ?? 0;

          // Step 2: Double-check balance
          if (currentBalance < wagerAmountInt) {
            throw Exception('Yetersiz bakiye! Mevcut bakiye: $currentBalance VP');
          }

          // Step 3: Deduct balance using FieldValue.increment
          transaction.update(
            userDocRef,
            {'balance': FieldValue.increment(-wagerAmountInt)},
          );

          // Step 4: Create bet document in users/{uid}/bets/ subcollection
          final betDocRef = userDocRef
              .collection('bets')
              .doc(); // Auto-generate document ID

          transaction.set(
            betDocRef,
            {
              'eventId': eventId,
              'eventTitle': widget.event.title,
              'choice': choice,
              'amount': wagerAmountInt,
              'odds': currentOdds, // Save the odds at the time of bet
              'potentialWin': potentialWin, // Save calculated potential win (amount * odds)
              'timestamp': FieldValue.serverTimestamp(),
              'status': 'active',
              'varimPercentage': widget.event.varimPercentage,
              'yokumPercentage': widget.event.yokumPercentage,
              'poolSize': widget.event.poolSize,
            },
          );
        },
      );

      // Success - show animated dialog with haptics and sound
      if (!mounted) return; // Early return if disposed
      
      // Trigger haptic feedback (The 'Stamp' feeling)
      HapticFeedback.heavyImpact();
      
      // Play success sound
      _playChachingSound();
      
      // Reset and start stamp animation (with mounted check to prevent crash)
      if (mounted) {
        _stampAnimationController.reset();
        _stampAnimationController.forward();
      }
      
      // Check mounted again before showing dialog
      if (!mounted) return;
      
      await showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (context) => _SuccessStampDialog(
          wagerAmount: wagerAmountInt,
          selectedSide: _selectedSide,
          potentialWin: potentialWin,
          stampScaleAnimation: _stampScaleAnimation,
          stampGlowAnimation: _stampGlowAnimation,
          onClose: () {
            if (mounted) {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to home
            }
          },
        ),
      );
    } catch (e) {
      // Error handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: DesignSystem.errorRose,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      // Reset loading state
      if (mounted) {
        setState(() {
          _isPlacingBet = false;
        });
      }
    }
  }
}

// ========== UI COMPONENTS ==========

/// Quantity adjustment button
class _QuantityButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  const _QuantityButton({
    required this.icon,
    required this.onPressed,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
      ),
    );
  }
}

/// Calculation row display
class _CalculationRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isTotal;
  final Color? color;

  const _CalculationRow({
    required this.label,
    required this.value,
    this.isTotal = false,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: (isTotal ? DesignSystem.headingSmall : DesignSystem.bodyMedium).copyWith(
            fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: (isTotal ? DesignSystem.headingMedium : DesignSystem.bodyLarge).copyWith(
            color: color ?? (isTotal ? DesignSystem.textHeading : DesignSystem.textBody),
            fontWeight: isTotal ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// Trend chart painter for visual effect
class _TrendChartPainter extends CustomPainter {
  final double yesPercentage;
  final double noPercentage;

  _TrendChartPainter({
    required this.yesPercentage,
    required this.noPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = DesignSystem.successGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final paint2 = Paint()
      ..color = DesignSystem.errorRose
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    final path1 = Path();
    final path2 = Path();

    final points = 30;
    final stepX = size.width / points;

    for (int i = 0; i <= points; i++) {
      final x = i * stepX;
      final baseY = size.height * 0.5;
      
      // YES line
      final y1 = baseY +
          (size.height * 0.25) *
              (0.5 + 0.5 * (yesPercentage * 2 - 1)) *
              (1 + 0.2 * (i % 4 - 1.5) / 4);
      
      // NO line
      final y2 = baseY +
          (size.height * 0.25) *
              (0.5 + 0.5 * (noPercentage * 2 - 1)) *
              (1 + 0.2 * (i % 5 - 2) / 5);

      if (i == 0) {
        path1.moveTo(x, y1);
        path2.moveTo(x, y2);
      } else {
        path1.lineTo(x, y1);
        path2.lineTo(x, y2);
      }
    }

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Animated Success Stamp Dialog with Gamification
class _SuccessStampDialog extends StatelessWidget {
  final int wagerAmount;
  final String selectedSide;
  final int potentialWin;
  final Animation<double> stampScaleAnimation;
  final Animation<double> stampGlowAnimation;
  final VoidCallback onClose;

  const _SuccessStampDialog({
    required this.wagerAmount,
    required this.selectedSide,
    required this.potentialWin,
    required this.stampScaleAnimation,
    required this.stampGlowAnimation,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: AnimatedBuilder(
        // Listen to both animations so the shadow updates properly
        animation: Listenable.merge([stampScaleAnimation, stampGlowAnimation]),
        builder: (context, child) {
          return Transform.scale(
            scale: stampScaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: DesignSystem.surfaceLight,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: DesignSystem.border,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: DesignSystem.successGreen.withValues(
                      alpha: 0.3 * stampGlowAnimation.value,
                    ),
                    blurRadius: 30 * stampGlowAnimation.value,
                    spreadRadius: 5 * stampGlowAnimation.value,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Massive Glowing Stamp Icon
                  AnimatedBuilder(
                    animation: stampGlowAnimation,
                    builder: (context, child) {
                      return Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              DesignSystem.successGreen.withValues(
                                alpha: 0.3 * stampGlowAnimation.value,
                              ),
                              DesignSystem.successGreen.withValues(
                                alpha: 0.1 * stampGlowAnimation.value,
                              ),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: DesignSystem.successGreen.withValues(
                                alpha: 0.6 * stampGlowAnimation.value,
                              ),
                              blurRadius: 40 * stampGlowAnimation.value,
                              spreadRadius: 10 * stampGlowAnimation.value,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 60,
                          backgroundColor: DesignSystem.successGreen,
                          child: const Icon(
                            Icons.check,
                            size: 64,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // Success Text with Neon Glow
                  Text(
                    'BAŞARIYLA POZİSYON ALINDI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: DesignSystem.successGreen,
                      letterSpacing: 1.2,
                      shadows: [
                        Shadow(
                          color: DesignSystem.successGreen.withValues(alpha: 0.8),
                          blurRadius: 20,
                          offset: const Offset(0, 0),
                        ),
                        Shadow(
                          color: DesignSystem.successGreen.withValues(alpha: 0.4),
                          blurRadius: 40,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transaction Details
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: DesignSystem.backgroundDeep,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DesignSystem.border,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Emir Tutarı:',
                              style: DesignSystem.bodyMedium,
                            ),
                            Text(
                              '$wagerAmount VP',
                              style: DesignSystem.headingSmall.copyWith(
                                color: DesignSystem.textHeading,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Tahmini Kazanç:',
                              style: DesignSystem.bodyMedium,
                            ),
                            Text(
                              '$potentialWin VP',
                              style: DesignSystem.headingMedium.copyWith(
                                color: DesignSystem.successGreen,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Leaderboard Hype Banner
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: DesignSystem.backgroundDeep,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: Colors.amber,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Bu işlem seni Liderlik Tablosunda üst sıralara taşıyabilir!',
                            style: DesignSystem.bodyMedium.copyWith(
                              color: Colors.amber.withValues(alpha: 0.9),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Close Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onClose,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DesignSystem.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                      ),
                      child: const Text(
                        'TAMAM',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
