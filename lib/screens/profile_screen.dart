import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:varim_app/widgets/custom_header.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/theme/design_system.dart';
import 'package:varim_app/providers/user_provider.dart';
import 'package:varim_app/screens/admin_screen.dart';

/// Gamified profile screen with stats, badges, and settings
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoadingBalance = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);
    // Listen to changes - this will rebuild when UserProvider notifies listeners
    final userProvider = Provider.of<UserProvider>(context, listen: true);
    final currentUser = userProvider.currentUser;

    return Scaffold(
      backgroundColor: DesignSystem.backgroundDeep,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              const CustomHeader(),

              // Header Section
              Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Large Circular Avatar
                    Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: varimColors.varimColor,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: varimColors.varimColor.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: (currentUser?.username.isNotEmpty ?? false)
                              ? Center(
                                  child: Text(
                                    _getInitials(currentUser!.username),
                                    style: TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.w900,
                                      color: varimColors.varimColor,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  size: 80,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Username or Email
                    Text(
                      (currentUser?.username.isNotEmpty ?? false)
                          ? currentUser!.username
                          : (currentUser?.email ?? 'Yükleniyor...'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w900,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Profili Düzenle Button
                    OutlinedButton.icon(
                      onPressed: () => _showEditProfileDialog(context, theme, varimColors, userProvider),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Profili Düzenle'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: varimColors.varimColor,
                        side: BorderSide(
                          color: varimColors.varimColor.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Big Balance Display
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: varimColors.varimColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: varimColors.varimColor.withValues(alpha: 0.2),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Bakiye',
                            style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 14,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userProvider.isLoading
                                ? 'Yükleniyor...'
                                : '${userProvider.balance.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} VP',
                            style: TextStyle(
                              color: varimColors.varimColor,
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Stats Row (Dynamic)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: varimColors.varimColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.shadow.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: FutureBuilder<int>(
                  future: _getBetCount(),
                  builder: (context, snapshot) {
                    final betCount = snapshot.data ?? 0;
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatCard(
                          label: 'Oynanan',
                          value: betCount.toString(),
                          icon: Icons.casino,
                          theme: theme,
                          varimColors: varimColors,
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        _StatCard(
                          label: 'Kazanma Oranı',
                          value: '%--',
                          icon: Icons.trending_up,
                          theme: theme,
                          varimColors: varimColors,
                          valueColor: varimColors.varimColor,
                        ),
                        Container(
                          width: 1,
                          height: 60,
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        _StatCard(
                          label: 'Sıralama',
                          value: '#120',
                          icon: Icons.leaderboard,
                          theme: theme,
                          varimColors: varimColors,
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // Rozetlerim (Badges) Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.workspace_premium,
                          color: varimColors.varimColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Rozetlerim',
                          style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 120,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: FutureBuilder<int>(
                          future: _getBetCount(),
                          builder: (context, snapshot) {
                            final totalBets = snapshot.data ?? 0;
                            final isFirstBetUnlocked = totalBets > 0;
                            
                            return Row(
                              children: [
                                _BadgeCard(
                                  name: 'İlk Heyecan',
                                  icon: Icons.celebration,
                                  color: Colors.amber,
                                  isUnlocked: isFirstBetUnlocked,
                                  theme: theme,
                                  varimColors: varimColors,
                                ),
                                const SizedBox(width: 12),
                                _BadgeCard(
                                  name: 'Ekonomi Gurusu',
                                  icon: Icons.trending_up,
                                  color: Colors.amber,
                                  isUnlocked: false,
                                  theme: theme,
                                  varimColors: varimColors,
                                ),
                                const SizedBox(width: 12),
                                _BadgeCard(
                                  name: 'Derbi Kralı',
                                  icon: Icons.sports_soccer,
                                  color: Colors.green,
                                  isUnlocked: false,
                                  theme: theme,
                                  varimColors: varimColors,
                                ),
                                const SizedBox(width: 12),
                                _BadgeCard(
                                  name: 'Erken Kalkan',
                                  icon: Icons.wb_sunny,
                                  color: Colors.orange,
                                  isUnlocked: false,
                                  theme: theme,
                                  varimColors: varimColors,
                                ),
                                const SizedBox(width: 12),
                                _BadgeCard(
                                  name: 'Kripto Ustası',
                                  icon: Icons.currency_bitcoin,
                                  color: Colors.blue,
                                  isUnlocked: false,
                                  theme: theme,
                                  varimColors: varimColors,
                                ),
                                const SizedBox(width: 12),
                                _BadgeCard(
                                  name: 'Şampiyon',
                                  icon: Icons.emoji_events,
                                  color: Colors.purple,
                                  isUnlocked: false,
                                  theme: theme,
                                  varimColors: varimColors,
                                ),
                                const SizedBox(width: 12),
                                _BadgeCard(
                                  name: 'Hızlı Karar',
                                  icon: Icons.flash_on,
                                  color: Colors.red,
                                  isUnlocked: false,
                                  theme: theme,
                                  varimColors: varimColors,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Ayarlar (Settings) Section
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ayarlar',
                      style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 16),
                    _SettingsTile(
                      icon: Icons.notifications,
                      title: 'Bildirim Ayarları',
                      trailing: Switch(
                        value: true, // Visual only
                        onChanged: (value) {
                          // Visual only - no action
                        },
                        activeThumbColor: varimColors.varimColor,
                        activeTrackColor: varimColors.varimColor.withValues(alpha: 0.5),
                      ),
                      theme: theme,
                      varimColors: varimColors,
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.dark_mode,
                      title: 'Tema / Karanlık Mod',
                      trailing: Switch(
                        value: true, // Visual only
                        onChanged: (value) {
                          // Visual only - no action
                        },
                        activeThumbColor: varimColors.varimColor,
                        activeTrackColor: varimColors.varimColor.withValues(alpha: 0.5),
                      ),
                      theme: theme,
                      varimColors: varimColors,
                    ),
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.account_balance_wallet,
                      title: 'Test Bakiyesi Yükle',
                      subtitle: '10.000 VP ekle',
                      onTap: () => _loadBalance(context, theme, varimColors, userProvider),
                      isLoading: _isLoadingBalance,
                      theme: theme,
                      varimColors: varimColors,
                    ),
                    // Admin Panel Tile (Conditional)
                    if (currentUser?.email == 'nuriskilcadir@gmail.com') ...[
                      const Divider(height: 1),
                      _SettingsTile(
                        icon: Icons.admin_panel_settings,
                        title: 'Yönetici Paneli 🔒',
                        iconColor: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AdminScreen(),
                            ),
                          );
                        },
                        theme: theme,
                        varimColors: varimColors,
                      ),
                    ],
                    const Divider(height: 1),
                    _SettingsTile(
                      icon: Icons.logout,
                      title: 'Çıkış Yap',
                      iconColor: Colors.red,
                      onTap: () {
                        _showLogoutDialog(context, theme, varimColors);
                      },
                      theme: theme,
                      varimColors: varimColors,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  /// Get initials from username
  String _getInitials(String username) {
    final words = username.trim().split(' ');
    if (words.length >= 2) {
      return (words[0][0] + words[1][0]).toUpperCase();
    } else if (username.isNotEmpty) {
      return username.substring(0, username.length > 2 ? 2 : username.length).toUpperCase();
    }
    return 'U';
  }

  /// Get bet count from Firestore
  Future<int> _getBetCount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('bets')
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      debugPrint('Error getting bet count: $e');
      return 0;
    }
  }

  /// Show edit profile dialog
  Future<void> _showEditProfileDialog(
    BuildContext context,
    ThemeData theme,
    VarimColors varimColors,
    UserProvider userProvider,
  ) async {
    final currentUser = userProvider.currentUser;
    final controller = TextEditingController(
      text: currentUser?.username ?? '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Profili Düzenle',
          style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            labelText: 'Kullanıcı Adı',
            hintText: 'Kullanıcı adınızı girin',
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
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final newUsername = controller.text.trim();
              if (newUsername.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Kullanıcı adı boş olamaz!'),
                    backgroundColor: varimColors.yokumColor,
                  ),
                );
                return;
              }

              final user = FirebaseAuth.instance.currentUser;
              if (user == null) {
                Navigator.pop(context);
                return;
              }

              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .update({'username': newUsername});

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Kullanıcı adı güncellendi!'),
                      backgroundColor: varimColors.varimColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Hata: ${e.toString()}'),
                      backgroundColor: varimColors.yokumColor,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: varimColors.varimColor,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  /// Load balance (Test Feature)
  Future<void> _loadBalance(
    BuildContext context,
    ThemeData theme,
    VarimColors varimColors,
    UserProvider userProvider,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Giriş yapmanız gerekiyor!'),
          backgroundColor: varimColors.yokumColor,
        ),
      );
      return;
    }

    setState(() {
      _isLoadingBalance = true;
    });

    try {
      await FirebaseFirestore.instance.runTransaction(
        (Transaction transaction) async {
          final userDocRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);
          final userDoc = await transaction.get(userDocRef);

          if (!userDoc.exists) {
            throw Exception('Kullanıcı belgesi bulunamadı');
          }

          // Add 10,000 VP to balance
          transaction.update(
            userDocRef,
            {'balance': FieldValue.increment(10000)},
          );
        },
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('10.000 VP başarıyla eklendi!'),
            backgroundColor: varimColors.varimColor,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: ${e.toString()}'),
            backgroundColor: varimColors.yokumColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (context.mounted) {
        setState(() {
          _isLoadingBalance = false;
        });
      }
    }
  }

  void _showLogoutDialog(
    BuildContext context,
    ThemeData theme,
    VarimColors varimColors,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Text(
          'Çıkış Yap',
          style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
        content: Text(
          'Hesabınızdan çıkmak istediğinize emin misiniz?',
          style: theme.textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await FirebaseAuth.instance.signOut();
                // Navigation will be handled by StreamBuilder in main.dart
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Çıkış yapılırken bir hata oluştu: ${e.toString()}'),
                      backgroundColor: varimColors.yokumColor,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }
}

/// Stat card widget
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final ThemeData theme;
  final VarimColors varimColors;
  final Color? valueColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.theme,
    required this.varimColors,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: varimColors.varimColor,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
                  color: valueColor ?? theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Badge card widget with overflow protection
class _BadgeCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final bool isUnlocked;
  final ThemeData theme;
  final VarimColors varimColors;

  const _BadgeCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.isUnlocked,
    required this.theme,
    required this.varimColors,
  });

  @override
  Widget build(BuildContext context) {
    final displayColor = isUnlocked ? color : theme.colorScheme.onSurfaceVariant;
    final displayIconColor = isUnlocked ? color : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return Container(
      width: 90,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: displayColor.withValues(alpha: isUnlocked ? 0.3 : 0.1),
          width: 1.5,
        ),
        boxShadow: isUnlocked
            ? [
                BoxShadow(
                  color: displayColor.withValues(alpha: 0.2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: displayColor.withValues(alpha: isUnlocked ? 0.2 : 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: displayIconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          // Use FittedBox to prevent overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: displayColor,
                  ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Settings tile widget
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isLoading;
  final ThemeData theme;
  final VarimColors varimColors;
  final Color? iconColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.isLoading = false,
    required this.theme,
    required this.varimColors,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final displayIconColor = iconColor ?? varimColors.varimColor;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: displayIconColor.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(displayIconColor),
                ),
              )
            : Icon(
                icon,
                color: displayIconColor,
                size: 20,
              ),
      ),
      title: Text(
        title,
        style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
            )
          : null,
      trailing: trailing ??
          (onTap != null
              ? Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                )
              : null),
      onTap: isLoading ? null : onTap,
    );
  }
}

