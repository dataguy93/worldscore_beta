import 'package:flutter/material.dart';

import '../controllers/session_controller.dart';
import 'worldscore_header.dart';

/// Compact PRO | GM segmented toggle shown to GM-tier users so they can switch
/// which dashboard they're viewing. Switching calls
/// [SessionController.setActiveMode], which causes the auth gate to swap the
/// home screen.
class ModeToggle extends StatelessWidget {
  const ModeToggle({required this.sessionController, super.key});

  final SessionController sessionController;

  @override
  Widget build(BuildContext context) {
    final mode = sessionController.activeMode;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFF072E21),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF1E8F5C)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _segment('PRO', WorldScoreRole.pro, mode),
          _segment('GM', WorldScoreRole.gm, mode),
        ],
      ),
    );
  }

  Widget _segment(String label, WorldScoreRole value, WorldScoreRole current) {
    final selected = value == current;
    return GestureDetector(
      onTap: () => sessionController.setActiveMode(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0F5A3F) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF3CE081) : const Color(0xFF7EA699),
            fontWeight: FontWeight.w800,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}
