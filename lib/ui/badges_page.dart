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

  IconData _iconForBadge(String key) {
    switch (key) {
      case 'tipid_master':
        return Icons.pie_chart;
      case 'debt_slayer':
        return Icons.content_cut;
      case 'consistent_saver':
        return Icons.check_circle_outline;
      case 'no_impulse_week':
        return Icons.stop_circle_outlined;
      case 'perfect_streak':
        return Icons.star;
      default:
        return Icons.star_border;
    }
  }

  String _descriptionForBadge(String key) {
    switch (key) {
      case 'tipid_master':
        return 'Saved at least 40% of spending for a full 30-day cycle with no debt.';
      case 'debt_slayer':
        return 'Paid off all debt by the end of a 30-day cycle.';
      case 'consistent_saver':
        return 'Saved money on at least 4 different days in a week.';
      case 'no_impulse_week':
        return 'Kept “wants” spending under 20% of total spending for a week.';
      case 'perfect_streak':
        return 'Played every day for 30 days straight.';
      default:
        return 'Special achievement in your money journey.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_badges.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No badges yet.\nKeep practicing daily to unlock achievements!',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBadges,
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.1,
        ),
        itemCount: _badges.length,
        itemBuilder: (_, index) {
          final badge = _badges[index];
          final key = badge['badge_key'] as String;
          final label = badge['label'] as String;
          final icon = _iconForBadge(key);
          final desc = _descriptionForBadge(key);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 36, color: Colors.amber[700]),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

