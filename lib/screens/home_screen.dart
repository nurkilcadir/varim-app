import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:varim_app/widgets/mobile_prediction_card.dart';
import 'package:varim_app/widgets/custom_header.dart';
import 'package:varim_app/screens/bet_detail_screen.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/models/event_model.dart';

/// Home screen with mobile-first Kalshi-style layout
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Hepsi';

  final List<String> _categories = [
    'Hepsi',
    'Spor',
    'Ekonomi',
    'Magazin',
    'Siyaset',
    'Kripto',
  ];
  /// Get icon based on category
  IconData? _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'spor':
        return Icons.sports_soccer;
      case 'siyaset':
        return Icons.gavel;
      case 'ekonomi':
        return Icons.trending_up;
      case 'teknoloji':
        return Icons.phone_iphone;
      case 'kripto':
        return Icons.currency_bitcoin;
      case 'yapay zeka':
      case 'ai':
        return Icons.smart_toy;
      case 'enerji':
        return Icons.eco;
      default:
        return Icons.event_note;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            const CustomHeader(),

            // Section 1: Trending
            _buildTrendingSection(theme, varimColors),

            // Section 2: Category Chips
            _buildCategoryChips(theme, varimColors),

            // Section 3: The Feed
            Expanded(
              child: _buildFeed(theme, varimColors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingSection(ThemeData theme, VarimColors varimColors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                'Trendler 🔥',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('events')
                .where('status', isEqualTo: 'active')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 32,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Hata: ${snapshot.error}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'Henüz trend yok',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              // Sort by volume client-side and take top 5 (to avoid composite index)
              final events = snapshot.data!.docs
                  .map((doc) => EventModel.fromMap(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ))
                  .toList()
                ..sort((a, b) => b.volume.compareTo(a.volume));

              final topEvents = events.take(5).toList();

              if (topEvents.isEmpty) {
                return Center(
                  child: Text(
                    'Henüz trend yok',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: topEvents.length,
                itemBuilder: (context, index) {
                  final event = topEvents[index];
                  return _TrendingCard(
                    event: event,
                    theme: theme,
                    varimColors: varimColors,
                    icon: _getCategoryIcon(event.category),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => BetDetailScreen(event: event),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCategoryChips(ThemeData theme, VarimColors varimColors) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? varimColors.varimColor.withValues(alpha: 0.2)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(
                        color: varimColors.varimColor.withValues(alpha: 0.6),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected
                        ? varimColors.varimColor
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFeed(ThemeData theme, VarimColors varimColors) {
    // Build query based on selected category
    // We avoid orderBy in Firestore to prevent composite index requirement
    // Sorting will be done client-side
    Query query = FirebaseFirestore.instance
        .collection('events')
        .where('status', isEqualTo: 'active');

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerLoading();
        }

        // Error State
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 64,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  'Bir hata oluştu: ${snapshot.error}',
                  style: theme.textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        // Empty State
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState(_selectedCategory == 'Hepsi' 
              ? 'Şu an aktif bahis yok'
              : 'Bu kategoride henüz bahis yok.');
        }

        // Data State
        var events = snapshot.data!.docs
            .map((doc) => EventModel.fromMap(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList();

        // Filter by category client-side if not 'Hepsi' (to avoid composite index)
        if (_selectedCategory != 'Hepsi') {
          events = events
              .where((event) => event.category == _selectedCategory)
              .toList();
        }

        // Sort by endDate client-side (to avoid composite index requirement)
        events.sort((a, b) {
          return a.endDate.compareTo(b.endDate);
        });

        return RefreshIndicator(
          onRefresh: _refreshEvents,
          color: varimColors.varimColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return MobilePredictionCard(
                title: event.title,
                icon: _getCategoryIcon(event.category),
                varimPercentage: event.varimPercentage,
                yokumPercentage: event.yokumPercentage,
                poolSize: event.poolSize,
                onCardTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BetDetailScreen(
                        event: event,
                      ),
                    ),
                  );
                },
                onVarimTap: () {
                  _showQuickBetDialog(
                    context,
                    event,
                    true,
                  );
                },
                onYokumTap: () {
                  _showQuickBetDialog(
                    context,
                    event,
                    false,
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_note,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Yeni bahisler eklendiğinde burada görünecek',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Shimmer loading effect
  Widget _buildShimmerLoading() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 3, // Show 3 shimmer cards
      itemBuilder: (context, index) {
        return _ShimmerCard();
      },
    );
  }

  Future<void> _refreshEvents() async {
    // StreamBuilder automatically refreshes, but we can trigger a manual refresh
    // by showing a snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Etkinlikler yenilendi'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  void _showQuickBetDialog(
    BuildContext context,
    EventModel event,
    bool isVarim,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final varimColors = AppTheme.varimColors(context);
        
        return AlertDialog(
          backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
          title: Text(
            isVarim ? 'VARIM Bahsi' : 'YOKUM Bahsi',
            style: TextStyle(
              color: isVarim ? varimColors.varimColor : varimColors.yokumColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event.title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Detaylı bahis için kartı tıklayın',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kapat'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BetDetailScreen(
                      event: event,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isVarim ? varimColors.varimColor : varimColors.yokumColor,
                foregroundColor:
                    isVarim ? theme.colorScheme.onPrimary : theme.colorScheme.onSecondary,
              ),
              child: const Text('Bahis Yap'),
            ),
          ],
        );
      },
    );
  }
}

/// Compact trending card widget
class _TrendingCard extends StatelessWidget {
  final EventModel event;
  final ThemeData theme;
  final VarimColors varimColors;
  final IconData? icon;
  final VoidCallback onTap;

  const _TrendingCard({
    required this.event,
    required this.theme,
    required this.varimColors,
    this.icon,
    required this.onTap,
  });

  String _formatVolume(int volume) {
    if (volume >= 1000000) {
      return '${(volume / 1000000).toStringAsFixed(1)}M';
    } else if (volume >= 1000) {
      return '${(volume / 1000).toStringAsFixed(0)}K';
    }
    return volume.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: varimColors.varimColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: varimColors.varimColor.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon + Title
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: varimColors.varimColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      icon,
                      size: 16,
                      color: varimColors.varimColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    event.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Ratios
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: varimColors.varimColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'VARIM ${event.yesRatio.toStringAsFixed(2)}x',
                        style: TextStyle(
                          color: varimColors.varimColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                    decoration: BoxDecoration(
                      color: varimColors.yokumColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'YOKUM ${event.noRatio.toStringAsFixed(2)}x',
                        style: TextStyle(
                          color: varimColors.yokumColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Volume
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  size: 14,
                  color: varimColors.varimColor,
                ),
                const SizedBox(width: 4),
                Text(
                  '${_formatVolume(event.volume)} VP',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Shimmer loading card widget
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();

  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title shimmer
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _getShimmerColor(theme),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 20,
                      decoration: BoxDecoration(
                        color: _getShimmerColor(theme),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Buttons shimmer
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getShimmerColor(theme),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 60,
                      decoration: BoxDecoration(
                        color: _getShimmerColor(theme),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Pool size shimmer
              Container(
                width: 100,
                height: 14,
                decoration: BoxDecoration(
                  color: _getShimmerColor(theme),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getShimmerColor(ThemeData theme) {
    final value = _animation.value;
    if (value < 0 || value > 1) {
      return theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.1);
    }
    // Create a shimmer effect
    final opacity = 0.1 + (0.3 * (1 - (value - 0.5).abs() * 2));
    return theme.colorScheme.surfaceContainerHighest.withValues(alpha: opacity);
  }
}
