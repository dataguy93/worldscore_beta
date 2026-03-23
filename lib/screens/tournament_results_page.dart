import 'package:flutter/material.dart';

class TournamentResultsPage extends StatelessWidget {
  const TournamentResultsPage({super.key});

  static const _cardsSubmitted = 34;
  static const _totalCards = 48;

  @override
  Widget build(BuildContext context) {
    final progress = _cardsSubmitted / _totalCards;

    return Scaffold(
      backgroundColor: const Color(0xFF021A12),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _HeaderSection(),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const _LiveBadge(),
                          const SizedBox(width: 22),
                          Text(
                            '$_cardsSubmitted / $_totalCards',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 42,
                              fontWeight: FontWeight.w700,
                              height: 0.95,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Cards submitted',
                            style: TextStyle(
                              color: Color(0xFF83A49A),
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 18),
                          SizedBox(
                            width: 220,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(100),
                              child: LinearProgressIndicator(
                                value: progress,
                                minHeight: 12,
                                backgroundColor: const Color(0xFF1A3B2F),
                                valueColor: const AlwaysStoppedAnimation(
                                  Color(0xFF3CE081),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              const Divider(color: Color(0xFF114834), height: 1),
              const SizedBox(height: 22),
              const SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _DashboardChip(
                      label: 'Overview',
                      icon: Icons.grid_view_rounded,
                      selected: true,
                    ),
                    SizedBox(width: 16),
                    _DashboardChip(
                      label: 'Anomalies',
                      icon: Icons.warning_amber_rounded,
                      badge: '3',
                    ),
                    SizedBox(width: 16),
                    _DashboardChip(
                      label: 'Audit Trail',
                      icon: Icons.shield_outlined,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const _RoleToggle(),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFF114834), height: 1),
              const SizedBox(height: 28),
              const _MetricsGrid(),
              const SizedBox(height: 24),
              const _TrendsCard(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'WorldScore',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 52,
                  letterSpacing: -0.5,
                ),
              ),
              Text(
                ' AI',
                style: TextStyle(
                  color: Color(0xFF3CE081),
                  fontWeight: FontWeight.w800,
                  fontSize: 52,
                  letterSpacing: -0.5,
                ),
              ),
              SizedBox(width: 20),
              Text(
                '|  Tournament Dashboard',
                style: TextStyle(
                  color: Color(0xFF9AC3B7),
                  fontSize: 34,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 20),
              _DirectorPill(),
            ],
          ),
        ),
        SizedBox(height: 10),
        Text(
          '📄  Pebble Beach Pro-Am     Round 2 of 4     Pebble Beach Golf Links',
          style: TextStyle(
            color: Color(0xFF7EA699),
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _DirectorPill extends StatelessWidget {
  const _DirectorPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF083F2A),
        border: Border.all(color: const Color(0xFF1D8E5B)),
      ),
      child: const Text(
        '🚀 Director',
        style: TextStyle(
          color: Color(0xFF4BE58F),
          fontWeight: FontWeight.w700,
          fontSize: 30,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: const Color(0xFF083A28),
        border: Border.all(color: const Color(0xFF1E8F5C)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 14, color: Color(0xFF35DD7F)),
          SizedBox(width: 10),
          Text(
            'LIVE',
            style: TextStyle(
              color: Color(0xFF3CE081),
              fontWeight: FontWeight.w800,
              fontSize: 24,
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardChip extends StatelessWidget {
  const _DashboardChip({
    required this.label,
    required this.icon,
    this.badge,
    this.selected = false,
  });

  final String label;
  final IconData icon;
  final String? badge;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: selected ? const Color(0xFF0D3B29) : Colors.transparent,
        border: Border.all(
          color: selected ? const Color(0xFF1A8052) : Colors.transparent,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 30, color: selected ? const Color(0xFF4BE58F) : const Color(0xFF6F8E84)),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: selected ? const Color(0xFF4BE58F) : const Color(0xFF7B958D),
              fontSize: 40,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4D3D12),
                border: Border.all(color: const Color(0xFF8A6A12)),
              ),
              child: Text(
                badge!,
                style: const TextStyle(
                  color: Color(0xFFF1BD2F),
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _RoleToggle extends StatelessWidget {
  const _RoleToggle();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
      children: [
        const Text(
          'Demo role:',
          style: TextStyle(color: Color(0xFF789A8E), fontSize: 38, fontWeight: FontWeight.w500),
        ),
        const SizedBox(width: 18),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF102B21),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF284E40)),
          ),
          child: const Row(
            children: [
              _RoleChip(label: '🏆 Pro'),
              SizedBox(width: 8),
              _RoleChip(label: '🚀 Director', active: true),
            ],
          ),
        ),
        const SizedBox(width: 18),
        const Text(
          '← Pricing',
          style: TextStyle(color: Color(0xFF5E7D72), fontSize: 36),
        ),
      ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.label, this.active = false});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: active ? const Color(0xFF1A6A43) : Colors.transparent,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? const Color(0xFF59E89A) : const Color(0xFF778F88),
          fontSize: 34,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricsGrid extends StatelessWidget {
  const _MetricsGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                borderColor: Color(0xFF12598A),
                background: Color(0xFF082538),
                icon: Icons.groups_outlined,
                iconColor: Color(0xFF62A9FF),
                value: '8',
                label: 'Players',
                sublabel: '5 finished',
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _MetricCard(
                borderColor: Color(0xFF137A48),
                background: Color(0xFF093823),
                icon: Icons.trending_down_rounded,
                iconColor: Color(0xFF3EE483),
                value: '72.4',
                label: 'Avg Score',
                sublabel: 'vs par 72',
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                borderColor: Color(0xFF7C5E1A),
                background: Color(0xFF25220D),
                icon: Icons.warning_amber_rounded,
                iconColor: Color(0xFFF7C132),
                value: '3',
                label: 'Anomalies',
                sublabel: 'require review',
              ),
            ),
            SizedBox(width: 18),
            Expanded(
              child: _MetricCard(
                borderColor: Color(0xFF4B3287),
                background: Color(0xFF1C1E35),
                icon: Icons.check_circle_outline,
                iconColor: Color(0xFFAA80FF),
                value: '2',
                label: 'Overrides',
                sublabel: 'this round',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.borderColor,
    required this.background,
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.sublabel,
  });

  final Color borderColor;
  final Color background;
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String sublabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 32),
          const SizedBox(width: 18),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: iconColor,
                  fontSize: 50,
                  fontWeight: FontWeight.w800,
                  height: 0.95,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFFD7E5DE),
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                sublabel,
                style: const TextStyle(
                  color: Color(0xFF80998F),
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendsCard extends StatelessWidget {
  const _TrendsCard();

  @override
  Widget build(BuildContext context) {
    const barValues = [2.2, 6.0, 10.5, 16.8, 21.5, 27.0, 34.0];
    const labels = ['8:00', '8:30', '9:00', '9:30', '10:00', '10:30', '11:00'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF032A1A),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF0F5D39)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Live Tournament Trends',
                      style: TextStyle(
                        color: Color(0xFFE6F1EC),
                        fontSize: 46,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Real-time scoring data',
                      style: TextStyle(
                        color: Color(0xFF6F9183),
                        fontSize: 34,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _TrendTabs(),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 380,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < barValues.length; i++)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: _TrendBar(
                        value: barValues[i],
                        maxValue: 36,
                        label: labels[i],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendTabs extends StatelessWidget {
  const _TrendTabs();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A3127),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF275343)),
      ),
      padding: const EdgeInsets.all(6),
      child: const Row(
        children: [
          _TrendTab(label: 'Card Flow', selected: true),
          _TrendTab(label: 'Avg Score'),
          _TrendTab(label: 'Hole Analysis'),
        ],
      ),
    );
  }
}

class _TrendTab extends StatelessWidget {
  const _TrendTab({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFF195D3D) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? const Color(0xFF299A65) : Colors.transparent,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? const Color(0xFF58EB9D) : const Color(0xFF778E84),
          fontWeight: FontWeight.w700,
          fontSize: 32,
        ),
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({
    required this.value,
    required this.maxValue,
    required this.label,
  });

  final double value;
  final double maxValue;
  final String label;

  @override
  Widget build(BuildContext context) {
    final heightFactor = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: FractionallySizedBox(
              heightFactor: heightFactor,
              widthFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF48C97A),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF749488),
            fontSize: 30,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
