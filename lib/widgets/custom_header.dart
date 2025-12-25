import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/theme/design_system.dart';
import 'package:varim_app/providers/user_provider.dart';
import 'package:varim_app/screens/store_screen.dart';

/// Custom header with V logo and user VP badge
/// Shows real-time balance from UserProvider
class CustomHeader extends StatelessWidget {
  final String? userAvatarUrl;

  const CustomHeader({
    super.key,
    this.userAvatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);
    // Listen to changes - this will rebuild when UserProvider notifies listeners
    final userProvider = Provider.of<UserProvider>(context, listen: true);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceLight,
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.1), // Subtle white border
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // V Logo
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  varimColors.headerAccent,
                  varimColors.headerAccentDark,
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: varimColors.headerAccent.withValues(alpha: 0.3),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                'V',
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          
          // Daily Streak Button & Store Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Daily Streak Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showStreakDialog(context, theme, varimColors),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: Colors.orange,
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '5',
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Store Button (Wallet Icon)
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _navigateToStore(context),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DesignSystem.primaryAccent.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: DesignSystem.primaryAccent.withValues(alpha: 0.5),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: DesignSystem.primaryAccent,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // User Avatar and VP Badge with real-time balance from Provider
          if (userProvider.currentUser != null)
            Row(
              children: [
                // User Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: varimColors.varimColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    image: userAvatarUrl != null
                        ? DecorationImage(
                            image: NetworkImage(userAvatarUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: userAvatarUrl == null
                      ? Icon(
                          Icons.person,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 24,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // VP Badge with real balance from Provider
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        varimColors.headerAccent.withValues(alpha: 0.2),
                        varimColors.headerAccentDark.withValues(alpha: 0.2),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: varimColors.headerAccent.withValues(alpha: 0.5),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: varimColors.headerAccent.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (userProvider.isLoading)
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              varimColors.headerAccent,
                            ),
                          ),
                        )
                      else if (userProvider.error != null && !userProvider.error!.contains('creating'))
                        Text(
                          'Hata',
                          style: TextStyle(
                            color: varimColors.yokumColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      else
                        Text(
                          _formatVP(userProvider.balance),
                          style: TextStyle(
                            color: varimColors.headerAccent,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      const SizedBox(width: 4),
                      Text(
                        'VP',
                        style: TextStyle(
                          color: varimColors.headerAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            // Fallback if user is not logged in
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                'Giriş Yap',
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatVP(int vp) {
    if (vp >= 1000000) {
      return '${(vp / 1000000).toStringAsFixed(1)}M';
    } else if (vp >= 1000) {
      return '${(vp / 1000).toStringAsFixed(1)}K';
    }
    return vp.toString();
  }

  void _showStreakDialog(BuildContext context, ThemeData theme, VarimColors varimColors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: DesignSystem.surfaceLight,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            const Icon(
              Icons.local_fire_department,
              color: Colors.orange,
              size: 32,
            ),
            const SizedBox(width: 12),
            Text(
              'Günlük Seri',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          '5 Gündür serin devam ediyor! Yarın gel 500 VP kap.',
          style: theme.textTheme.bodyLarge,
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
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

  void _navigateToStore(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StoreScreen(),
      ),
    );
  }
}
