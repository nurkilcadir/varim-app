import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:varim_app/widgets/portfolio_card.dart';
import 'package:varim_app/widgets/custom_header.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/theme/design_system.dart';
import 'package:varim_app/providers/user_provider.dart';

/// Portfolio screen showing user's active bets and history
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen>
    with SingleTickerProviderStateMixin {
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

    return Scaffold(
      backgroundColor: DesignSystem.backgroundDeep,
      body: SafeArea(
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            // Get real balance from UserProvider
            final totalBalance = userProvider.balance.toDouble();
            // Locked balance will be calculated in the active bets stream
            final availableBalance = totalBalance; // Will be updated when bets load

            return Column(
              children: [
                // Custom Header
                const CustomHeader(),

                // Total Balance Card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DesignSystem.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: DesignSystem.successGreen.withValues(alpha: 0.2),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: DesignSystem.successGreen.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Toplam Bakiye',
                        style: DesignSystem.bodySmall.copyWith(
                              fontSize: 12,
                            ),
                      ),
                      const SizedBox(height: 8),
                      if (userProvider.isLoading)
                        SizedBox(
                          height: 40,
                          child: Center(
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                varimColors.varimColor,
                              ),
                            ),
                          ),
                        )
                      else
                        Text(
                          '${totalBalance.toStringAsFixed(0)} VP',
                          style: TextStyle(
                            color: DesignSystem.successGreen,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _BalanceItem(
                              label: 'Kullanılabilir',
                              amount: availableBalance,
                              theme: theme,
                              varimColors: varimColors,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _LockedBalanceItem(
                              userId: FirebaseAuth.instance.currentUser?.uid,
                              theme: theme,
                              varimColors: varimColors,
                            ),
                          ),
                        ],
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
                    Tab(text: 'Devam Edenler'),
                    Tab(text: 'Geçmiş'),
                  ],
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      // Active Bets Tab
                      _buildActiveBetsTab(theme, varimColors, userProvider),

                      // History Tab
                      _buildHistoryBetsTab(theme, varimColors),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildActiveBetsTab(
    ThemeData theme,
    VarimColors varimColors,
    UserProvider userProvider,
  ) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return _buildEmptyState(
        'Giriş yapmanız gerekiyor',
        theme,
        showButton: false,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bets')
          .orderBy('timestamp', descending: true)
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
          return _buildEmptyState(
            'Henüz tahminin yok',
            theme,
            showButton: true,
          );
        }

        // Filter active bets in the app (to avoid composite index requirement)
        final allBets = snapshot.data!.docs;
        final activeBets = allBets.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return (data['status'] as String? ?? 'active') == 'active';
        }).toList();

        if (activeBets.isEmpty) {
          return _buildEmptyState(
            'Henüz tahminin yok',
            theme,
            showButton: true,
          );
        }

        // Data State
        final bets = activeBets;
        return RefreshIndicator(
          onRefresh: _refreshBets,
          color: varimColors.varimColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: bets.length,
            itemBuilder: (context, index) {
              final doc = bets[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final eventId = data['eventId'] as String?;
              final eventTitle = data['eventTitle'] as String? ?? 'Bilinmeyen Etkinlik';
              final choice = data['choice'] as String? ?? 'VARIM';
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              final potentialWin = (data['potentialWin'] as num?)?.toDouble() ?? 0.0;
              
              // Get entry ratio from odds field (stored as probability)
              final entryRatio = (data['odds'] as num?)?.toDouble();

              return PortfolioCard(
                title: eventTitle,
                position: choice,
                invested: amount,
                potentialWin: potentialWin,
                eventId: eventId, // Required for live stream
                entryRatio: entryRatio, // Entry probability at betting time
                onTap: () {
                  // TODO: Navigate to bet details
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildHistoryBetsTab(ThemeData theme, VarimColors varimColors) {
    final user = FirebaseAuth.instance.currentUser;
    
    if (user == null) {
      return _buildEmptyState(
        'Giriş yapmanız gerekiyor',
        theme,
        showButton: false,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bets')
          .orderBy('timestamp', descending: true)
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
          return _buildEmptyState(
            'Geçmiş bahis yok',
            theme,
            showButton: false,
          );
        }

        // Filter history bets in the app (to avoid composite index requirement)
        final allBets = snapshot.data!.docs;
        final historyBets = allBets.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = data['status'] as String? ?? 'active';
          return status != 'active';
        }).toList();

        if (historyBets.isEmpty) {
          return _buildEmptyState(
            'Geçmiş bahis yok',
            theme,
            showButton: false,
          );
        }

        // Data State
        final bets = historyBets;
        return RefreshIndicator(
          onRefresh: _refreshBets,
          color: varimColors.varimColor,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: bets.length,
            itemBuilder: (context, index) {
              final doc = bets[index];
              final data = doc.data() as Map<String, dynamic>;
              
              final eventTitle = data['eventTitle'] as String? ?? 'Bilinmeyen Etkinlik';
              final choice = data['choice'] as String? ?? 'VARIM';
              final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
              final status = data['status'] as String? ?? 'resolved';
              final potentialWin = (data['potentialWin'] as num?)?.toDouble() ?? 0.0;
              final payout = (data['payout'] as num?)?.toDouble();
              
              // Determine result
              String? result;
              double finalPayout = 0.0;
              if (status == 'won') {
                result = 'Won';
                finalPayout = payout ?? potentialWin;
              } else if (status == 'lost') {
                result = 'Lost';
                finalPayout = 0.0;
              } else {
                // For resolved but unknown outcome, show potential win
                finalPayout = potentialWin;
              }

              return PortfolioCard(
                title: eventTitle,
                position: choice,
                invested: amount,
                potentialWin: finalPayout,
                isHistory: true,
                result: result,
                onTap: () {
                  // TODO: Navigate to bet details
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(
    String message,
    ThemeData theme, {
    bool showButton = false,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inbox,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: theme.textTheme.headlineSmall,
          ),
          if (showButton) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to Home tab by finding MainScreen and changing index
                // Since MainScreen uses IndexedStack, we need to access it
                // For now, we'll just show a message or use a simpler approach
                Navigator.of(context).popUntil((route) => route.isFirst);
                // The user will need to manually switch to Home tab
                // Alternatively, we could use a callback pattern
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ana sayfaya geçmek için alt menüden Home sekmesine tıklayın'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.home),
              label: const Text('Ana Sayfaya Git'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _refreshBets() async {
    // StreamBuilder automatically refreshes, but we can trigger a manual refresh
    // by showing a snackbar
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bahisler yenilendi'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }
}

class _BalanceItem extends StatelessWidget {
  final String label;
  final double amount;
  final ThemeData theme;
  final VarimColors varimColors;

  const _BalanceItem({
    required this.label,
    required this.amount,
    required this.theme,
    required this.varimColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${amount.toStringAsFixed(0)} VP',
            style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

/// Locked balance item that fetches from Firestore
class _LockedBalanceItem extends StatelessWidget {
  final String? userId;
  final ThemeData theme;
  final VarimColors varimColors;

  const _LockedBalanceItem({
    required this.userId,
    required this.theme,
    required this.varimColors,
  });

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock,
                  size: 14,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 4),
                Text(
                  'Kilitli / Oyunda',
                  style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '0 VP',
              style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('bets')
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, snapshot) {
        double lockedBalance = 0.0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            lockedBalance += amount;
          }
        }

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.lock,
                    size: 14,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Kilitli / Oyunda',
                    style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${lockedBalance.toStringAsFixed(0)} VP',
                style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        );
      },
    );
  }
}

