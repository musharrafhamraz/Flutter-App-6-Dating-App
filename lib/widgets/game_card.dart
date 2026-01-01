import 'package:flutter/material.dart';
import 'package:datingapp/models/game_model.dart';
import 'package:datingapp/core/theme/app_theme.dart';

class GameCard extends StatelessWidget {
  final GameType gameType;
  final String title;
  final String description;
  final IconData icon;
  final VoidCallback onTap;

  const GameCard({
    super.key,
    required this.gameType,
    required this.title,
    required this.description,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Gradient gradient;
    
    switch (gameType) {
      case GameType.icebreaker:
        gradient = AppTheme.primaryGradient;
        break;
      case GameType.poll:
        gradient = const LinearGradient(
          colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
        );
        break;
      case GameType.challenge:
        gradient = const LinearGradient(
          colors: [Color(0xFFEC4899), Color(0xFFF43F5E)],
        );
        break;
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: gradient.scale(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
