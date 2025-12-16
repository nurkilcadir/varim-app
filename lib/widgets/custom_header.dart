import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/providers/user_provider.dart';

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
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
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
}
