import 'package:material_ui/material_ui.dart';

class CompactHeader extends StatelessWidget {
  final int level;
  final int xp;
  final int xpToNext;
  final double progress;
  final int streak;

  const CompactHeader({
    super.key,
    required this.level,
    required this.xp,
    required this.xpToNext,
    required this.streak,
  }) : progress = xp / xpToNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
      ),
      child: Row(
        children: [
          CircleAvatar(child: Text(level.toString())),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'XP: $xp / $xpToNext',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(value: progress.clamp(0, 1)),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              const Icon(
                Icons.local_fire_department,
                size: 18,
                color: Colors.orange,
              ),
              const SizedBox(width: 4),
              Text(streak.toString()),
            ],
          ),
        ],
      ),
    );
  }
}
