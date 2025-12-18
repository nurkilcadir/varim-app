import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:varim_app/widgets/custom_header.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/theme/design_system.dart';
import 'package:varim_app/models/user_model.dart';

/// Gamified leaderboard screen with podium and rankings
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  String _formatBalance(int balance) {
    // Format with dots for thousands separator
    return balance.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundDeep,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .orderBy('balance', descending: true)
              .limit(50)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                children: [
                  const CustomHeader(),
                  Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(
                          varimColors.varimColor,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  const CustomHeader(),
                  Expanded(
                    child: Center(
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
                    ),
                  ),
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Column(
                children: [
                  const CustomHeader(),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.leaderboard,
                            size: 64,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Henüz liderlik tablosu yok',
                            style: theme.textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            // Parse users from Firestore
            final users = snapshot.data!.docs
                .asMap()
                .entries
                .map((entry) {
                  final index = entry.key;
                  final doc = entry.value;
                  final user = UserModel.fromMap(doc.data() as Map<String, dynamic>);
                  return {
                    'uid': user.uid,
                    'username': user.username,
                    'balance': user.balance,
                    'rank': index + 1,
                  };
                })
                .toList();

            final top3 = users.take(3).toList();
            final rest = users.skip(3).toList();

            // Find current user in leaderboard
            int? currentUserRank;
            Map<String, dynamic>? currentUserData;
            if (currentUser != null) {
              final currentUserIndex = users.indexWhere(
                (user) => user['uid'] == currentUser.uid,
              );
              if (currentUserIndex != -1) {
                currentUserRank = currentUserIndex + 1;
                currentUserData = users[currentUserIndex];
              } else {
                // Current user not in top 50, fetch their data separately
                currentUserData = {
                  'uid': currentUser.uid,
                  'username': currentUser.displayName ?? currentUser.email?.split('@')[0] ?? 'Kullanıcı',
                  'balance': 0, // Will be fetched
                  'rank': null,
                };
              }
            }

            return Column(
              children: [
                const CustomHeader(),

                // Title
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.emoji_events,
                        color: varimColors.varimColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Liderlik Tablosu',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                // Content
                Expanded(
                  child: _buildLeaderboardContent(
                    top3,
                    rest,
                    currentUser?.uid,
                    theme,
                    varimColors,
                  ),
                ),

                // Sticky Bottom Bar - My Rank (only if not in top 50)
                if (currentUser != null && currentUserRank == null)
                  _buildStickyBottomBar(
                    currentUserData!,
                    theme,
                    varimColors,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLeaderboardContent(
    List<Map<String, dynamic>> top3,
    List<Map<String, dynamic>> rest,
    String? currentUserId,
    ThemeData theme,
    VarimColors varimColors,
  ) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Podium Section
          if (top3.length >= 3)
            _PodiumWidget(
              top3: top3,
              currentUserId: currentUserId,
              theme: theme,
              varimColors: varimColors,
              formatBalance: _formatBalance,
            ),
          const SizedBox(height: 24),

          // Rest of the Rankings
          ...rest.map((user) {
            final isCurrentUser = user['uid'] == currentUserId;
            return _LeaderboardRow(
              rank: user['rank'] as int,
              username: user['username'] as String,
              balance: user['balance'] as int,
              theme: theme,
              varimColors: varimColors,
              isEven: user['rank'] % 2 == 0,
              isCurrentUser: isCurrentUser,
              formatBalance: _formatBalance,
            );
          }),
          const SizedBox(height: 80), // Space for sticky bottom bar
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(
    Map<String, dynamic> currentUserData,
    ThemeData theme,
    VarimColors varimColors,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceLight,
        border: Border(
          top: BorderSide(
            color: DesignSystem.successGreen.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.successGreen.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUserData['uid'] as String)
            .snapshots(),
        builder: (context, snapshot) {
          int balance = 0;
          if (snapshot.hasData && snapshot.data!.exists) {
            final data = snapshot.data!.data() as Map<String, dynamic>?;
            balance = (data?['balance'] as num?)?.toInt() ?? 0;
          }

          return Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: varimColors.varimColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '>50',
                  style: TextStyle(
                    color: varimColors.varimColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sen: ${currentUserData['username']}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${_formatBalance(balance)} VP',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: varimColors.varimColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Podium widget for top 3
class _PodiumWidget extends StatelessWidget {
  final List<Map<String, dynamic>> top3;
  final String? currentUserId;
  final ThemeData theme;
  final VarimColors varimColors;
  final String Function(int) formatBalance;

  const _PodiumWidget({
    required this.top3,
    this.currentUserId,
    required this.theme,
    required this.varimColors,
    required this.formatBalance,
  });

  @override
  Widget build(BuildContext context) {
    if (top3.length < 3) return const SizedBox.shrink();

    final first = top3[0]; // 1st place (center)
    final second = top3[1]; // 2nd place (left)
    final third = top3[2]; // 3rd place (right)

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DesignSystem.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: DesignSystem.primaryAccent.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Podium Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // 2nd Place (Left)
              _PodiumPlace(
                rank: 2,
                user: second,
                size: 80,
                borderColor: const Color(0xFFC0C0C0), // Silver
                theme: theme,
                varimColors: varimColors,
                formatBalance: formatBalance,
                isCurrentUser: second['uid'] == currentUserId,
              ),
              // 1st Place (Center) - Largest with glow
              Stack(
                alignment: Alignment.topCenter,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: _PodiumPlace(
                      rank: 1,
                      user: first,
                      size: 100,
                      borderColor: const Color(0xFFFFD700), // Gold
                      theme: theme,
                      varimColors: varimColors,
                      formatBalance: formatBalance,
                      isCurrentUser: first['uid'] == currentUserId,
                    ),
                  ),
                  // Crown Icon
                  Positioned(
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFD700),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFFD700).withValues(alpha: 0.6),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.emoji_events,
                        color: Colors.black,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
              // 3rd Place (Right)
              _PodiumPlace(
                rank: 3,
                user: third,
                size: 70,
                borderColor: const Color(0xFFCD7F32), // Bronze
                theme: theme,
                varimColors: varimColors,
                formatBalance: formatBalance,
                isCurrentUser: third['uid'] == currentUserId,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PodiumPlace extends StatelessWidget {
  final int rank;
  final Map<String, dynamic> user;
  final double size;
  final Color borderColor;
  final ThemeData theme;
  final VarimColors varimColors;
  final String Function(int) formatBalance;
  final bool isCurrentUser;

  const _PodiumPlace({
    required this.rank,
    required this.user,
    required this.size,
    required this.borderColor,
    required this.theme,
    required this.varimColors,
    required this.formatBalance,
    this.isCurrentUser = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Rank Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: borderColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor,
              width: 2,
            ),
          ),
          child: Text(
            '#$rank',
            style: TextStyle(
              color: borderColor,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Avatar
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: isCurrentUser
                  ? varimColors.varimColor
                  : borderColor,
              width: isCurrentUser ? 4 : 3,
            ),
            boxShadow: [
              BoxShadow(
                color: (isCurrentUser
                        ? varimColors.varimColor
                        : borderColor)
                    .withValues(alpha: isCurrentUser ? 0.6 : 0.4),
                blurRadius: isCurrentUser ? 16 : 12,
                spreadRadius: isCurrentUser ? 3 : 2,
              ),
            ],
          ),
          child: ClipOval(
            child: Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: user['avatar'] != null
                  ? Image.network(
                      user['avatar'] as String,
                      fit: BoxFit.cover,
                    )
                  : Icon(
                      Icons.person,
                      size: size * 0.6,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Username
        SizedBox(
          width: size + 20,
          child: Text(
            user['username'] as String,
            style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(height: 4),
        // Balance
        Text(
          '${formatBalance(user['balance'] as int)} VP',
          style: TextStyle(
            color: varimColors.varimColor,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// Leaderboard row for ranks 4+
class _LeaderboardRow extends StatelessWidget {
  final int rank;
  final String username;
  final int balance;
  final ThemeData theme;
  final VarimColors varimColors;
  final bool isEven;
  final bool isCurrentUser;
  final String Function(int) formatBalance;

  const _LeaderboardRow({
    required this.rank,
    required this.username,
    required this.balance,
    required this.theme,
    required this.varimColors,
    required this.isEven,
    this.isCurrentUser = false,
    required this.formatBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? varimColors.varimColor.withValues(alpha: 0.15)
            : isEven
                ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2)
                : theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: isCurrentUser
            ? Border.all(
                color: varimColors.varimColor.withValues(alpha: 0.5),
                width: 2,
              )
            : null,
      ),
      child: Row(
        children: [
          // Rank Number
          Container(
            width: 40,
            alignment: Alignment.center,
            child: Text(
              '#$rank',
              style: theme.textTheme.titleMedium?.copyWith(
                    color: rank <= 10
                        ? varimColors.varimColor
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
            ),
          ),
          const SizedBox(width: 12),
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.colorScheme.surfaceContainerHighest,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.person,
                  size: 24,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Username
          Expanded(
            child: Text(
              username,
              style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Balance
          Text(
            '${formatBalance(balance)} VP',
            style: theme.textTheme.titleSmall?.copyWith(
              color: varimColors.varimColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
