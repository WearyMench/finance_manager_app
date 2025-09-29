import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class SessionStatusWidget extends StatelessWidget {
  const SessionStatusWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (!authProvider.isAuthenticated) {
          return const SizedBox.shrink();
        }

        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.green.withValues(alpha: 0.2)
                : Colors.green[800]!.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.green.withValues(alpha: 0.4)
                  : Colors.green[700]!,
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isDark ? Colors.green[400] : Colors.green[100],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'Conectado',
                style: TextStyle(
                  color: isDark ? Colors.green[300] : Colors.green[100],
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
