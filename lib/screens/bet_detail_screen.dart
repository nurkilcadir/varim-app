import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/theme/design_system.dart';
import 'package:varim_app/providers/user_provider.dart';
import 'package:varim_app/models/event_model.dart';

/// Betting detail screen for placing bets on predictions
class BetDetailScreen extends StatefulWidget {
  final EventModel event;

  const BetDetailScreen({
    super.key,
    required this.event,
  });

  @override
  State<BetDetailScreen> createState() => _BetDetailScreenState();
}

class _BetDetailScreenState extends State<BetDetailScreen>
    with SingleTickerProviderStateMixin {
  // State variables
  double _wagerAmount = 50.0; // Default starting value
  final double _minBet = 10.0;
  String _selectedSide = 'VARIM'; // 'VARIM' or 'YOKUM'
  bool _isPlacingBet = false; // Loading state for placing bet

  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _updateWager(double newValue, double userBalance) {
    setState(() {
      _wagerAmount = newValue.clamp(_minBet, userBalance);
    });
  }

  void _addToWager(double amount, double userBalance) {
    setState(() {
      _wagerAmount = (_wagerAmount + amount).clamp(_minBet, userBalance);
    });
  }

  void _setMaxWager(double userBalance) {
    setState(() {
      _wagerAmount = userBalance;
    });
  }

  /// Get current odd based on selected side
  double get currentOdd {
    return _selectedSide == 'VARIM'
        ? widget.event.yesRatio
        : widget.event.noRatio;
  }

  /// Calculate potential win: wagerAmount * currentOdd
  int get potentialWin {
    return (_wagerAmount * currentOdd).toInt();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);
    // Listen to changes - this will rebuild when UserProvider notifies listeners
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final userBalance = userProvider.balance.toDouble();
    
    // Update wager amount if balance changed
    if (_wagerAmount > userBalance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _wagerAmount = userBalance.clamp(_minBet, userBalance);
        });
      });
    }

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
          'Betting Page',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 600),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                  // Event Image (if available)
                  if (widget.event.imageUrl.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(
                        widget.event.imageUrl,
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: theme.colorScheme.surfaceContainer,
                            child: Icon(
                              Icons.image_not_supported,
                              size: 64,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          );
                        },
                      ),
                    ),
                  if (widget.event.imageUrl.isNotEmpty) const SizedBox(height: 24),

                  // Event Title
                  Text(
                    widget.event.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                          height: 1.3,
                          letterSpacing: -0.5,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // Settlement Rule Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.gavel,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Sonuçlandırma Kuralı & Kaynak',
                                style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: theme.colorScheme.onSurface,
                                    ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                widget.event.rule?.isNotEmpty == true
                                    ? widget.event.rule!
                                    : 'Bu etkinlik resmi sonuçlara göre yönetici tarafından sonuçlandırılacaktır.',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      height: 1.5,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Chart Placeholder with Neon Wavy Line
                  _NeonChartPlaceholder(
                    varimPercentage: widget.event.varimPercentage,
                    yokumPercentage: widget.event.yokumPercentage,
                  ),
                  const SizedBox(height: 32),

                  // Side Selection Toggle
                  Row(
                    children: [
                      Expanded(
                        child: _SideToggleChip(
                          label: 'VARIM',
                          multiplier: widget.event.yesRatio,
                          isSelected: _selectedSide == 'VARIM',
                          color: varimColors.varimColor,
                          textColor: theme.colorScheme.onPrimary,
                          onTap: () {
                            setState(() {
                              _selectedSide = 'VARIM';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SideToggleChip(
                          label: 'YOKUM',
                          multiplier: widget.event.noRatio,
                          isSelected: _selectedSide == 'YOKUM',
                          color: varimColors.yokumColor,
                          textColor: theme.colorScheme.onSecondary,
                          onTap: () {
                            setState(() {
                              _selectedSide = 'YOKUM';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Large Wager Amount Display
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      children: [
                        Text(
                          'Yatırılan',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_wagerAmount.toStringAsFixed(0)} VP',
                          style: TextStyle(
                            color: varimColors.headerAccent,
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bakiye: ${userBalance.toStringAsFixed(0)} VP',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 12,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Circular Slider
                  Center(
                    child: _CircularBetSlider(
                      value: _wagerAmount,
                      min: _minBet,
                      max: userBalance,
                      headerAccent: varimColors.headerAccent,
                      surfaceColor: theme.colorScheme.surface,
                      onSurfaceVariant: theme.colorScheme.onSurfaceVariant,
                      onChanged: (value) => _updateWager(value, userBalance),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Linear Slider (Alternative input method)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        SliderTheme(
                          data: SliderTheme.of(context).copyWith(
                            activeTrackColor: varimColors.headerAccent,
                            inactiveTrackColor: theme.colorScheme.surfaceContainerHighest,
                            thumbColor: varimColors.headerAccent,
                            overlayColor: varimColors.headerAccent.withValues(alpha: 0.2),
                            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
                            trackHeight: 4,
                          ),
                          child: Slider(
                            value: _wagerAmount,
                            min: _minBet,
                            max: userBalance,
                            onChanged: (value) => _updateWager(value, userBalance),
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${_minBet.toInt()} VP',
                              style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                            ),
                            Text(
                              '${userBalance.toInt()} VP',
                              style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _QuickActionButton(
                        label: '+100',
                        onTap: () => _addToWager(100, userBalance),
                        theme: theme,
                        varimColors: varimColors,
                      ),
                      const SizedBox(width: 12),
                      _QuickActionButton(
                        label: '+500',
                        onTap: () => _addToWager(500, userBalance),
                        theme: theme,
                        varimColors: varimColors,
                      ),
                      const SizedBox(width: 12),
                      _QuickActionButton(
                        label: 'MAX',
                        onTap: () => _setMaxWager(userBalance),
                        theme: theme,
                        varimColors: varimColors,
                        isMax: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Potential Win Display (BIG and BOLD)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (_selectedSide == 'VARIM'
                              ? varimColors.varimColor
                              : varimColors.yokumColor)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: (_selectedSide == 'VARIM'
                                ? varimColors.varimColor
                                : varimColors.yokumColor)
                            .withValues(alpha: 0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (_selectedSide == 'VARIM'
                                  ? varimColors.varimColor
                                  : varimColors.yokumColor)
                              .withValues(alpha: 0.2),
                          blurRadius: 16,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Tahmini Kazanç',
                          style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 14,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$potentialWin VP',
                          style: TextStyle(
                            color: _selectedSide == 'VARIM'
                                ? varimColors.varimColor
                                : varimColors.yokumColor,
                            fontSize: 48,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Action Button (Single button that changes based on selection)
                  _BetActionButton(
                    label: '$_selectedSide OYNA (${_wagerAmount.toInt()} VP)',
                    color: _selectedSide == 'VARIM'
                        ? varimColors.varimColor
                        : varimColors.yokumColor,
                    textColor: _selectedSide == 'VARIM'
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSecondary,
                    icon: _selectedSide == 'VARIM'
                        ? Icons.thumb_up
                        : Icons.thumb_down,
                    isSelected: true,
                    isLoading: _isPlacingBet,
                    onPressed: _isPlacingBet
                        ? null
                        : () {
                            _placeBet(_selectedSide == 'VARIM');
                          },
                  ),
                    ],
                  ),
                ),
              ),
            ),
            // Loading overlay
            if (_isPlacingBet)
              Container(
                color: theme.colorScheme.surface.withValues(alpha: 0.8),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          varimColors.varimColor,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Bahis yerleştiriliyor...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _placeBet(bool isVarim) async {
    final theme = Theme.of(context);
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

    // Check if user has enough balance
    if (_wagerAmount > userProvider.balance) {
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
    if (_wagerAmount < _minBet) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Minimum bahis tutarı: ${_minBet.toInt()} VP'),
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
      final wagerAmountInt = _wagerAmount.toInt();
      
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

      // Success - show dialog
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: theme.colorScheme.surfaceContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: varimColors.varimColor,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Text(
                  'Bahis Alındı!',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_wagerAmount.toStringAsFixed(0)} VP $choice bahsi başarıyla yerleştirildi.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Tahmini Kazanç:',
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        '$potentialWin VP',
                        style: theme.textTheme.bodyLarge?.copyWith(
                              color: varimColors.varimColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to home
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: varimColors.varimColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      // Error handling
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().replaceAll('Exception: ', ''),
            ),
            backgroundColor: varimColors.yokumColor,
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

/// Side toggle chip widget
class _SideToggleChip extends StatelessWidget {
  final String label;
  final double multiplier;
  final bool isSelected;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _SideToggleChip({
    required this.label,
    required this.multiplier,
    required this.isSelected,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: isSelected ? color : color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? color
                  : color.withValues(alpha: 0.3),
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: color.withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? textColor : color,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${multiplier}x',
                style: TextStyle(
                  color: isSelected
                      ? textColor.withValues(alpha: 0.9)
                      : color,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Quick action button for wager adjustments
class _QuickActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final ThemeData theme;
  final VarimColors varimColors;
  final bool isMax;

  const _QuickActionButton({
    required this.label,
    required this.onTap,
    required this.theme,
    required this.varimColors,
    this.isMax = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isMax
                ? varimColors.varimColor.withValues(alpha: 0.2)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isMax
                  ? varimColors.varimColor.withValues(alpha: 0.5)
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isMax
                  ? varimColors.varimColor
                  : theme.colorScheme.onSurface,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

/// Neon chart placeholder with wavy line effect
class _NeonChartPlaceholder extends StatelessWidget {
  final double varimPercentage;
  final double yokumPercentage;

  const _NeonChartPlaceholder({
    required this.varimPercentage,
    required this.yokumPercentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: DesignSystem.surfaceLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: DesignSystem.border,
                        width: 1,
                      ),
                    ),
      child: CustomPaint(
        painter: _NeonLineChartPainter(
          varimPercentage: varimPercentage,
          yokumPercentage: yokumPercentage,
        ),
        child: Container(),
      ),
    );
  }
}

/// Custom painter for neon wavy line chart
class _NeonLineChartPainter extends CustomPainter {
  final double varimPercentage;
  final double yokumPercentage;

  _NeonLineChartPainter({
    required this.varimPercentage,
    required this.yokumPercentage,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Using DesignSystem colors
    final paint1 = Paint()
      ..color = DesignSystem.successGreen // VARIM color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final paint2 = Paint()
      ..color = DesignSystem.errorRose // YOKUM color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    final path1 = Path();
    final path2 = Path();

    final points = 20;
    final stepX = size.width / points;

    for (int i = 0; i <= points; i++) {
      final x = i * stepX;
      final baseY = size.height * 0.5;
      
      // Wavy line for VARIM (green)
      final y1 = baseY +
          (size.height * 0.3) *
              (0.5 + 0.5 * (varimPercentage * 2 - 1)) *
              (1 + 0.3 * (i % 3 - 1) / 3) *
              (1 + 0.2 * (i % 5 - 2) / 5);
      
      // Wavy line for YOKUM (pink)
      final y2 = baseY +
          (size.height * 0.3) *
              (0.5 + 0.5 * (yokumPercentage * 2 - 1)) *
              (1 + 0.3 * (i % 4 - 1.5) / 4) *
              (1 + 0.2 * (i % 6 - 3) / 6);

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

/// Circular bet slider widget - Fully interactive
class _CircularBetSlider extends StatefulWidget {
  final double value;
  final double min;
  final double max;
  final Color headerAccent;
  final Color surfaceColor;
  final Color onSurfaceVariant;
  final ValueChanged<double> onChanged;

  const _CircularBetSlider({
    required this.value,
    required this.min,
    required this.max,
    required this.headerAccent,
    required this.surfaceColor,
    required this.onSurfaceVariant,
    required this.onChanged,
  });

  @override
  State<_CircularBetSlider> createState() => _CircularBetSliderState();
}

class _CircularBetSliderState extends State<_CircularBetSlider>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  void _updateValue(Offset localPosition) {
    final size = 200.0;
    final center = Offset(size / 2, size / 2);
    final offset = localPosition - center;
    final distance = offset.distance;
    
    // Only update if touch is within the circle radius (more forgiving)
    if (distance > size / 2 - 40 && distance < size / 2 + 20) {
      // Calculate angle from top (0 degrees)
      var angle = offset.direction;
      // Convert from -π to π range to 0 to 2π
      if (angle < 0) angle += 2 * 3.14159;
      // Start from top (-π/2) and normalize to 0-1
      angle = (angle + 3.14159 / 2) % (2 * 3.14159);
      final normalizedAngle = angle / (2 * 3.14159);
      final newValue = widget.min + (normalizedAngle * (widget.max - widget.min));
      widget.onChanged(newValue.clamp(widget.min, widget.max));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = 200.0;
    final normalizedValue = (widget.value - widget.min) / (widget.max - widget.min);

    return GestureDetector(
      onPanStart: (details) {
        setState(() {
          _isDragging = true;
        });
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPosition = box.globalToLocal(details.globalPosition);
          _updateValue(localPosition);
        }
      },
      onPanUpdate: (details) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPosition = box.globalToLocal(details.globalPosition);
          _updateValue(localPosition);
        }
      },
      onPanEnd: (details) {
        setState(() {
          _isDragging = false;
        });
      },
      onTapDown: (details) {
        final RenderBox? box = context.findRenderObject() as RenderBox?;
        if (box != null) {
          final localPosition = box.globalToLocal(details.globalPosition);
          _updateValue(localPosition);
        }
      },
      child: AnimatedBuilder(
        animation: _glowController,
        builder: (context, child) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.headerAccent
                      .withValues(alpha: _isDragging ? 0.6 : 0.3 + 0.2 * _glowController.value),
                  blurRadius: _isDragging ? 30 : 20 + 10 * _glowController.value,
                  spreadRadius: _isDragging ? 8 : 5 + 3 * _glowController.value,
                ),
              ],
            ),
            child: CustomPaint(
              painter: _CircularSliderPainter(
                value: normalizedValue,
                glowIntensity: _isDragging ? 1.0 : _glowController.value,
                headerAccent: widget.headerAccent,
                surfaceColor: widget.surfaceColor,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet,
                      color: widget.headerAccent,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yatırılan:',
                      style: TextStyle(
                        color: widget.onSurfaceVariant,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${widget.value.toStringAsFixed(0)} VP',
                      style: TextStyle(
                        color: widget.headerAccent,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Custom painter for circular slider
class _CircularSliderPainter extends CustomPainter {
  final double value;
  final double glowIntensity;
  final Color headerAccent;
  final Color surfaceColor;

  _CircularSliderPainter({
    required this.value,
    required this.glowIntensity,
    required this.headerAccent,
    required this.surfaceColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Background circle
    final backgroundPaint = Paint()
      ..color = surfaceColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = headerAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(
        BlurStyle.normal,
        8 + 4 * glowIntensity,
      );

    final sweepAngle = 2 * 3.14159 * value;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect
    final glowPaint = Paint()
      ..color = headerAccent
          .withValues(alpha: 0.3 * glowIntensity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is! _CircularSliderPainter ||
        oldDelegate.value != value ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.headerAccent != headerAccent ||
        oldDelegate.surfaceColor != surfaceColor;
  }
}

/// Bet action button with glow effect
class _BetActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;
  final bool isSelected;
  final bool isLoading;
  final VoidCallback? onPressed;

  const _BetActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.isSelected,
    this.isLoading = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isLoading
              ? color.withValues(alpha: 0.6)
              : color,
          foregroundColor: textColor,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? color.withValues(alpha: 0.8)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          elevation: isSelected ? 8 : 2,
          disabledBackgroundColor: color.withValues(alpha: 0.6),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(textColor),
                ),
              )
            else
              Icon(icon, size: 24),
            const SizedBox(width: 12),
            Text(
              isLoading ? 'İşleniyor...' : label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
