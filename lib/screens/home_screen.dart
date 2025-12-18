import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:varim_app/widgets/mobile_prediction_card.dart';
import 'package:varim_app/widgets/custom_header.dart';
import 'package:varim_app/screens/bet_detail_screen.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/theme/design_system.dart';
import 'package:varim_app/models/event_model.dart';

/// Home screen with mobile-first Kalshi-style layout
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'Trendler';
  String _selectedSort = 'volume'; // 'volume', 'endDate', 'createdDate', 'yesRatio_desc', 'yesRatio_asc'

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Trendler', 'icon': Icons.local_fire_department},
    {'label': 'Canlı', 'icon': Icons.flash_on},
    {'label': 'Spor', 'icon': Icons.sports_soccer},
    {'label': 'Kripto', 'icon': Icons.rocket_launch},
    {'label': 'Ekonomi', 'icon': Icons.attach_money},
    {'label': 'Magazin', 'icon': Icons.tv},
    {'label': 'E-Spor', 'icon': Icons.gamepad},
    {'label': 'Dünya', 'icon': Icons.public},
  ];

  final Map<String, Map<String, String>> _sortOptions = {
    'volume': {'label': '💎 Hacim', 'description': 'En çok işlem gören'},
    'endDate': {'label': '⏳ Bitiyor', 'description': 'En yakın bitiş'},
    'createdDate': {'label': '🆕 Yeni', 'description': 'En yeni eklenen'},
    'yesRatio_desc': {'label': '🎲 Sürpriz', 'description': 'Yüksek risk/ödül'},
    'yesRatio_asc': {'label': '🔒 Banko', 'description': 'Düşük risk/güvenli'},
  };
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

            // Category Chips (Horizontal Scroll)
            _buildCategoryChips(theme, varimColors),

            // The Feed (With Sort Bar and Content)
            Expanded(
              child: _buildFeedWithSortBar(theme, varimColors),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedWithSortBar(ThemeData theme, VarimColors varimColors) {
    return StreamBuilder<QuerySnapshot>(
      stream: _buildQuery().snapshots(),
      builder: (context, snapshot) {
        // Calculate result count for sort bar
        int resultCount = 0;
        if (snapshot.hasData) {
          resultCount = snapshot.data!.docs.length;
        }

        return Column(
          children: [
            // Sort Bar
            _buildSortBar(theme, varimColors, resultCount),

            // Feed Content
            Expanded(
              child: _buildFeedContent(snapshot, theme, varimColors),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryChips(ThemeData theme, VarimColors varimColors) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: DesignSystem.backgroundDeep,
        border: Border(
          bottom: BorderSide(
            color: DesignSystem.border,
            width: 1,
          ),
        ),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category['label'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    category['icon'] as IconData,
                    size: 18,
                    color: isSelected ? Colors.black : DesignSystem.textBody,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    category['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.black : DesignSystem.textBody,
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = category['label'] as String;
                    if (_selectedCategory == 'Trendler') {
                      _selectedSort = 'volume';
                    }
                  });
                }
              },
              selectedColor: DesignSystem.successGreen,
              backgroundColor: DesignSystem.surfaceLight,
              side: BorderSide(
                color: isSelected ? DesignSystem.successGreen : DesignSystem.border,
                width: isSelected ? 2 : 1,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSortBar(ThemeData theme, VarimColors varimColors, int resultCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Result Count
          Text(
            '$resultCount Piyasa Bulundu',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          // Sort Menu
          PopupMenuButton<String>(
            initialValue: _selectedSort,
            onSelected: (value) {
              setState(() {
                _selectedSort = value;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: varimColors.varimColor.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.sort,
                    size: 18,
                    color: varimColors.varimColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Sırala',
                    style: TextStyle(
                      color: varimColors.varimColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: 20,
                    color: varimColors.varimColor,
                  ),
                ],
              ),
            ),
            itemBuilder: (context) {
              return _sortOptions.entries.map((entry) {
                return PopupMenuItem<String>(
                  value: entry.key,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        entry.value['label']!,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _selectedSort == entry.key
                              ? varimColors.varimColor
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        entry.value['description']!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          ),
        ],
      ),
    );
  }

  Query _buildQuery() {
    Query query = FirebaseFirestore.instance
        .collection('events')
        .where('status', isEqualTo: 'active');

    // Category filtering
    if (_selectedCategory == 'Trendler') {
      // Trending - no category filter, sort by volume
      query = query.orderBy('volume', descending: true);
    } else if (_selectedCategory == 'Canlı') {
      // Live events - for now, just show all active events sorted by selected sort
      query = _applySorting(query);
    } else {
      // Specific category
      query = query.where('category', isEqualTo: _selectedCategory);
      query = _applySorting(query);
    }

    return query;
  }

  Query _applySorting(Query query) {
    switch (_selectedSort) {
      case 'volume':
        return query.orderBy('volume', descending: true);
      case 'endDate':
        return query.orderBy('endDate');
      case 'createdDate':
        return query.orderBy('endDate'); // Using endDate as proxy for now
      case 'yesRatio_desc':
        return query.orderBy('yesRatio', descending: true);
      case 'yesRatio_asc':
        return query.orderBy('yesRatio');
      default:
        return query.orderBy('volume', descending: true);
    }
  }

  Widget _buildFeedContent(
    AsyncSnapshot<QuerySnapshot> snapshot,
    ThemeData theme,
    VarimColors varimColors,
  ) {
    // Loading State
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildShimmerLoading();
    }

    // Error State
    if (snapshot.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
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
                'Bir hata oluştu',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                '${snapshot.error}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Bu sorgu için Firestore Index gerekebilir. Firebase Console\'dan oluşturun.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Empty State
    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
      return _buildEmptyState(_selectedCategory == 'Trendler' || _selectedCategory == 'Canlı'
          ? 'Şu an aktif bahis yok'
          : 'Bu kategoride henüz bahis yok.');
    }

    // Data State - Parse all events
    final events = snapshot.data!.docs
        .map((doc) => EventModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            ))
        .toList();

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
