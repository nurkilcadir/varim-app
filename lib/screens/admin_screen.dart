import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:varim_app/widgets/custom_header.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/models/event_model.dart';
import 'package:varim_app/screens/add_event_screen.dart';

/// Admin screen for resolving events and distributing winnings
class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  final Map<String, bool> _resolvingEvents = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: SafeArea(
          child: Column(
            children: [
              // Custom Header
              const CustomHeader(),

              // Title
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.admin_panel_settings,
                      color: Colors.red,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Yönetici Paneli',
                      style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                          ),
                    ),
                  ],
                ),
              ),

              // Tab Bar
              TabBar(
                controller: _tabController,
                labelColor: varimColors.varimColor,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: varimColors.varimColor,
                indicatorWeight: 3,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Yayında'),
                  Tab(text: 'Sonuçlananlar'),
                ],
              ),

              // Tab Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Aktif Tab - Active Events
                    _buildActiveEventsTab(theme, varimColors),
                    // Geçmiş Tab - Ended Events
                    _buildEndedEventsTab(theme, varimColors),
                  ],
                ),
              ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AddEventScreen(),
              ),
            );
          },
          backgroundColor: varimColors.varimColor,
          foregroundColor: theme.colorScheme.onPrimary,
          icon: const Icon(Icons.add),
          label: const Text(
            'Yeni Etkinlik',
            style: TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  /// Build active events tab
  Widget _buildActiveEventsTab(ThemeData theme, VarimColors varimColors) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('status', isEqualTo: 'active')
          .snapshots(),
                builder: (context, snapshot) {
                  // Loading State
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          varimColors.varimColor,
                        ),
                      ),
                    );
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
                          Text(
                            'Aktif etkinlik yok',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    );
                  }

                  // Data State
                  final events = snapshot.data!.docs
                      .map((doc) => EventModel.fromMap(
                            doc.data() as Map<String, dynamic>,
                            doc.id,
                          ))
                      .toList();

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: events.length,
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final isResolving = _resolvingEvents[event.id] ?? false;

                      return _ActiveEventCard(
                        event: event,
                        isResolving: isResolving,
                        onResolve: (result) => _resolveEvent(event.id, result),
                        theme: theme,
                        varimColors: varimColors,
                      );
                    },
                  );
                },
              );
  }

  /// Build ended events tab
  Widget _buildEndedEventsTab(ThemeData theme, VarimColors varimColors) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('events')
          .where('status', isEqualTo: 'ended')
          .snapshots(),
      builder: (context, snapshot) {
        // Loading State
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                varimColors.varimColor,
              ),
            ),
          );
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 64,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'Geçmiş etkinlik yok',
                  style: theme.textTheme.headlineSmall,
                ),
              ],
            ),
          );
        }

        // Data State - Sort by endDate in app to avoid composite index requirement
        final events = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return {
            'event': EventModel.fromMap(data, doc.id),
            'result': data['result'] as String? ?? '',
            'endDate': (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
          };
        }).toList()
          ..sort((a, b) => (b['endDate'] as DateTime)
              .compareTo(a['endDate'] as DateTime));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final eventData = events[index];
            final event = eventData['event'] as EventModel;
            final result = eventData['result'] as String;

            return _EndedEventCard(
              event: event,
              result: result,
              theme: theme,
              varimColors: varimColors,
            );
          },
        );
      },
    );
  }

  /// Resolve an event and distribute winnings
  Future<void> _resolveEvent(String eventId, String result) async {
    final varimColors = AppTheme.varimColors(context);

    setState(() {
      _resolvingEvents[eventId] = true;
    });

    try {
      // Step A: Update event status and result
      await FirebaseFirestore.instance
          .collection('events')
          .doc(eventId)
          .update({
        'status': 'ended',
        'result': result,
      });

      // Step B: Query all bets for this event using collectionGroup
      final betsSnapshot = await FirebaseFirestore.instance
          .collectionGroup('bets')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'active')
          .get();

      if (betsSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _resolvingEvents[eventId] = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Bu etkinlik için aktif bahis bulunamadı'),
              backgroundColor: varimColors.yokumColor,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Step C: Batch write for bet resolution and balance updates
      final batch = FirebaseFirestore.instance.batch();
      final userBalanceUpdates = <String, int>{};

      for (var betDoc in betsSnapshot.docs) {
        final betData = betDoc.data();
        final choice = betData['choice'] as String? ?? '';
        final potentialWin = (betData['potentialWin'] as num?)?.toInt() ?? 0;
        
        // Get user ID from document path: users/{uid}/bets/{betId}
        final pathParts = betDoc.reference.path.split('/');
        if (pathParts.length >= 2 && pathParts[0] == 'users') {
          final userId = pathParts[1];

          // Update bet status
          if (choice == result) {
            // Winner: set status to 'won'
            batch.update(betDoc.reference, {'status': 'won'});
            
            // Track balance update for this user
            userBalanceUpdates[userId] = 
                (userBalanceUpdates[userId] ?? 0) + potentialWin;
          } else {
            // Loser: set status to 'lost'
            batch.update(betDoc.reference, {'status': 'lost'});
          }
        }
      }

      // Update user balances
      for (var entry in userBalanceUpdates.entries) {
        final userDocRef = FirebaseFirestore.instance
            .collection('users')
            .doc(entry.key);
        batch.update(
          userDocRef,
          {'balance': FieldValue.increment(entry.value)},
        );
      }

      // Commit batch
      await batch.commit();

      if (mounted) {
        setState(() {
          _resolvingEvents[eventId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ödemeler Dağıtıldı'),
            backgroundColor: varimColors.varimColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resolvingEvents[eventId] = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: varimColors.yokumColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

/// Active event card widget with action buttons
class _ActiveEventCard extends StatelessWidget {
  final EventModel event;
  final bool isResolving;
  final Function(String) onResolve;
  final ThemeData theme;
  final VarimColors varimColors;

  const _ActiveEventCard({
    required this.event,
    required this.isResolving,
    required this.onResolve,
    required this.theme,
    required this.varimColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Chip and Title Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Chip
              _CategoryChip(
                category: event.category,
                theme: theme,
              ),
              const SizedBox(width: 8),
              // Event Title
              Expanded(
                child: Text(
                  event.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ratios Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: varimColors.varimColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: varimColors.varimColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'VARIM',
                        style: TextStyle(
                          color: varimColors.varimColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.yesRatio}x',
                        style: TextStyle(
                          color: varimColors.varimColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: varimColors.yokumColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: varimColors.yokumColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'YOKUM',
                        style: TextStyle(
                          color: varimColors.yokumColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.noRatio}x',
                        style: TextStyle(
                          color: varimColors.yokumColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              // VARIM KAZANDI Button
              Expanded(
                child: ElevatedButton(
                  onPressed: isResolving
                      ? null
                      : () => onResolve('VARIM'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: varimColors.varimColor,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: isResolving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onPrimary,
                            ),
                          ),
                        )
                      : const Text(
                          'VARIM KAZANDI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              // YOKUM KAZANDI Button
              Expanded(
                child: ElevatedButton(
                  onPressed: isResolving
                      ? null
                      : () => onResolve('YOKUM'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: varimColors.yokumColor,
                    foregroundColor: theme.colorScheme.onSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 4,
                  ),
                  child: isResolving
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              theme.colorScheme.onSecondary,
                            ),
                          ),
                        )
                      : const Text(
                          'YOKUM KAZANDI',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Ended event card widget with result badge
class _EndedEventCard extends StatelessWidget {
  final EventModel event;
  final String result;
  final ThemeData theme;
  final VarimColors varimColors;

  const _EndedEventCard({
    required this.event,
    required this.result,
    required this.theme,
    required this.varimColors,
  });

  @override
  Widget build(BuildContext context) {
    final isVarim = result == 'VARIM';
    final resultColor = isVarim ? varimColors.varimColor : varimColors.yokumColor;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Chip and Title Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Chip
              _CategoryChip(
                category: event.category,
                theme: theme,
              ),
              const SizedBox(width: 8),
              // Event Title
              Expanded(
                child: Text(
                  event.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Ratios Display
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: varimColors.varimColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: varimColors.varimColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'VARIM',
                        style: TextStyle(
                          color: varimColors.varimColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.yesRatio}x',
                        style: TextStyle(
                          color: varimColors.varimColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: varimColors.yokumColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: varimColors.yokumColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'YOKUM',
                        style: TextStyle(
                          color: varimColors.yokumColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${event.noRatio}x',
                        style: TextStyle(
                          color: varimColors.yokumColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Result Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: resultColor,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: resultColor.withValues(alpha: 0.4),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'SONUÇ: $result',
                style: TextStyle(
                  color: isVarim
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSecondary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Category chip widget
class _CategoryChip extends StatelessWidget {
  final String category;
  final ThemeData theme;

  const _CategoryChip({
    required this.category,
    required this.theme,
  });

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'ekonomi':
        return Colors.blue;
      case 'spor':
        return Colors.green;
      case 'siyaset':
        return Colors.orange;
      case 'teknoloji':
        return Colors.purple;
      case 'kripto':
        return Colors.amber;
      case 'pop kültür':
      case 'pop kultur':
        return Colors.pink;
      default:
        return theme.colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoryColor = _getCategoryColor(category);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: categoryColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: categoryColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        category,
        style: TextStyle(
          color: categoryColor,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
