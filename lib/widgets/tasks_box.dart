import 'dart:ui'; // Required for ImageFilter (BackdropFilter)
import 'package:flutter/material.dart';

class TaskBox extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const TaskBox({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        // Blurs the background directly behind this specific widget
        filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
        child: Material(
          // A semi-transparent color for the glass effect
          color: Colors.white.withValues(alpha: 0.15),
          child: InkWell(
            onTap: onTap,
            // The color of the splash ripple when tapped
            splashColor: Colors.white.withValues(alpha: 0.3),
            highlightColor: Colors.white.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}