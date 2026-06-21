import 'package:flutter/material.dart';

import 'research_assistant_panel.dart';

/// Floating AI assistant button shown in the bottom-right corner of the
/// Keyword Analyzer dashboard. On narrow screens it collapses to a circular
/// FAB; on wide screens it expands into a pill with label text.
class AiResearchAssistantButton extends StatelessWidget {
  const AiResearchAssistantButton({super.key});

  static const _primaryBlue = Color(0xFF2F6FB0);
  static const _lightBlue = Color(0xFFEAF3FF);

  void _openPanel(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ResearchAssistantPanel(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width >= 600;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openPanel(context),
        borderRadius: BorderRadius.circular(32),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            horizontal: isWide ? 14 : 10,
            vertical: 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: _primaryBlue.withValues(alpha: 0.25), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _primaryBlue.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Avatar ──────────────────────────────────────────────────
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _lightBlue,
                      border: Border.all(color: _primaryBlue, width: 2),
                    ),
                    child: const Center(
                      child: _RobotFace(),
                    ),
                  ),
                  // Online indicator
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF22C55E),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),

              // ── Labels (only on wide screens) ───────────────────────────
              if (isWide) ...[
                const SizedBox(width: 10),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ask AI',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _primaryBlue,
                        height: 1.2,
                      ),
                    ),
                    Text(
                      'Your research assistant',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Simple SVG-free robot face drawn with Flutter primitives
// ---------------------------------------------------------------------------
class _RobotFace extends StatelessWidget {
  const _RobotFace();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(26, 26),
      painter: _RobotPainter(),
    );
  }
}

class _RobotPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const blue = Color(0xFF2F6FB0);
    final paint = Paint()..color = blue;
    final w = size.width;
    final h = size.height;

    // Head (rounded rect)
    final headRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.1, h * 0.18, w * 0.8, h * 0.58),
      Radius.circular(w * 0.18),
    );
    canvas.drawRRect(headRect, paint);

    // Antenna
    final antennaPaint = Paint()
      ..color = blue
      ..strokeWidth = w * 0.1
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(w * 0.5, h * 0.18), Offset(w * 0.5, h * 0.05), antennaPaint);
    canvas.drawCircle(Offset(w * 0.5, h * 0.03), w * 0.08, paint);

    // Eyes (white)
    final eyePaint = Paint()..color = Colors.white;
    canvas.drawCircle(Offset(w * 0.33, h * 0.42), w * 0.1, eyePaint);
    canvas.drawCircle(Offset(w * 0.67, h * 0.42), w * 0.1, eyePaint);

    // Pupils
    final pupilPaint = Paint()..color = const Color(0xFF1E4A7A);
    canvas.drawCircle(Offset(w * 0.33, h * 0.43), w * 0.055, pupilPaint);
    canvas.drawCircle(Offset(w * 0.67, h * 0.43), w * 0.055, pupilPaint);

    // Smile
    final smilePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = w * 0.09
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final smilePath = Path()
      ..moveTo(w * 0.3, h * 0.62)
      ..quadraticBezierTo(w * 0.5, h * 0.74, w * 0.7, h * 0.62);
    canvas.drawPath(smilePath, smilePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
