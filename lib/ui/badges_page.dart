import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BadgesPage extends StatefulWidget {
  const BadgesPage({super.key});

  @override
  State<BadgesPage> createState() => _BadgesPageState();
}

class _BadgesPageState extends State<BadgesPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _badges = [];

  static const _primaryGreen = Color(0xFF22C55E);
  static const _darkNavy = Color(0xFF0F172A);

  static const _allBadges = [
    (
      'tipid_master',
      'Tipid Master',
      '💰',
      'Saved at least 40% of spending for a full 30-day cycle with no debt.'
    ),
    (
      'debt_slayer',
      'Debt Slayer',
      '⚔️',
      'Paid off all debt by the end of a 30-day cycle.'
    ),
    (
      'consistent_saver',
      'Consistent Saver',
      '✅',
      'Saved money on at least 4 different days in a week.'
    ),
    (
      'no_impulse_week',
      'No Impulse Week',
      '🛑',
      'Kept "wants" spending under 20% of total spending for a week.'
    ),
    (
      'perfect_streak',
      'Perfect Streak',
      '⭐',
      'Played every day for 30 days straight.'
    ),
    (
      'weekly_saver',
      'Weekly Saver',
      '🏆',
      'Saved at least 30% of what you spent this week.'
    ),
    (
      'weekly_spender',
      'Lesson Learned',
      '📚',
      'Big spender week — you reflected and learned.'
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadBadges();
  }

  Future<void> _loadBadges() async {
    setState(() => _loading = true);

    final client = Supabase.instance.client;
    final userId = client.auth.currentUser!.id;

    final data = await client
        .from('badges')
        .select()
        .eq('user_id', userId)
        .order('earned_at', ascending: false);

    if (!mounted) return;
    setState(() {
      _badges = List<Map<String, dynamic>>.from(data);
      _loading = false;
    });
  }

  bool _hasBadge(String key) {
    return _badges.any((b) => (b['badge_key'] as String) == key);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF22C55E)),
      );
    }

    final earnedCount = _badges.length;

    return RefreshIndicator(
      onRefresh: _loadBadges,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Dark purple hero: Spendly Score + rank chip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF5B21B6),
                  Color(0xFF4C1D95),
                  Color(0xFF3B0764),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              children: [
                Text(
                  'Spendly Score',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.emoji_events_outlined,
                      color: Color(0xFFFDE047),
                      size: 64,
                    ),
                    SizedBox(width: 20),
                    Text(
                      '72',
                      style: TextStyle(
                        color: Color(0xFFFDE047),
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        height: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE047).withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'Rising Saver',
                    style: TextStyle(
                      color: Color(0xFFFDE047),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // GridView 3 columns: badge cards, locked with reduced opacity
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.65,
            children: _allBadges.map((b) {
              final key = b.$1;
              final name = b.$2;
              final emoji = b.$3;
              final desc = b.$4;
              final unlocked = _hasBadge(key);
              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: unlocked
                        ? _primaryGreen.withValues(alpha: 0.4)
                        : const Color(0xFFE5E7EB),
                  ),
                ),
                child: Opacity(
                  opacity: unlocked ? 1.0 : 0.5,
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(
                          name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            color: unlocked ? _darkNavy : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          desc,
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8.5,
                            color: Colors.grey.shade600,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          // Weekly progress card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Weekly progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _darkNavy,
                        ),
                      ),
                      Text(
                        '$earnedCount / ${_allBadges.length} badges',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: earnedCount / _allBadges.length,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(_primaryGreen),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Keep playing daily to unlock more!',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
