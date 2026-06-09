import 'package:flutter/material.dart';

import '../config/tier_config.dart';
import '../controllers/session_controller.dart';

/// Mock subscription screen. Lets a user switch between the PRO and GM plans.
/// No real charges happen yet — `SessionController.changeTier` just updates the
/// `tier` field. A real billing provider would be integrated at the marked seam.
class ManagePlanPage extends StatefulWidget {
  const ManagePlanPage({required this.sessionController, super.key});

  final SessionController sessionController;

  @override
  State<ManagePlanPage> createState() => _ManagePlanPageState();
}

class _ManagePlanPageState extends State<ManagePlanPage> {
  bool _busy = false;

  static const Map<AppFeature, String> _featureLabels = {
    AppFeature.performance: 'Performance stats & trends',
    AppFeature.personalRoundHistory: 'Personal round history',
    AppFeature.personalUpload: 'Upload your own scorecards',
    AppFeature.tournaments: 'Create & manage tournaments',
    AppFeature.leaderboard: 'Tournament leaderboards',
    AppFeature.admin: 'Admin tools & divisions',
  };

  Future<void> _switchTo(AppTier target) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final upgrading = target == AppTier.gm;
        return AlertDialog(
          backgroundColor: const Color(0xFF072E21),
          title: Text(
            upgrading ? 'Upgrade to GM?' : 'Switch to PRO?',
            style: const TextStyle(color: Colors.white),
          ),
          content: Text(
            upgrading
                ? 'You\'ll be billed ${target.monthlyPrice} and unlock all '
                    'tournament management features.'
                : 'You\'ll move to the ${target.monthlyPrice} plan and lose '
                    'access to tournament management features.',
            style: const TextStyle(color: Color(0xFF7EA699)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF7EA699))),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1E8F5C),
              ),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(upgrading ? 'Upgrade' : 'Switch'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      // TODO: integrate billing provider here (start/modify subscription) before
      // updating the entitlement. For now this just writes the tier field.
      await widget.sessionController.changeTier(target);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('You\'re now on the ${target.label} plan.')),
        );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Could not change plan: $error')),
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF031C14),
      appBar: AppBar(
        backgroundColor: const Color(0xFF083A28),
        foregroundColor: Colors.white,
        title: const Text('Manage Plan'),
      ),
      body: ListenableBuilder(
        listenable: widget.sessionController,
        builder: (context, _) {
          final currentTier = widget.sessionController.tier;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Choose your monthly plan',
                  style: TextStyle(
                    color: Color(0xFF3CE081),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                for (final tier in AppTier.values) ...[
                  _PlanCard(
                    info: tier.info,
                    featureLabels: _featureLabels,
                    isCurrent: tier == currentTier,
                    busy: _busy,
                    onSelect: () => _switchTo(tier),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.info,
    required this.featureLabels,
    required this.isCurrent,
    required this.busy,
    required this.onSelect,
  });

  final TierInfo info;
  final Map<AppFeature, String> featureLabels;
  final bool isCurrent;
  final bool busy;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF072E21),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent ? const Color(0xFF3CE081) : const Color(0xFF165D43),
          width: isCurrent ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${info.label} Plan',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.tagline,
                      style: const TextStyle(
                        color: Color(0xFF7EA699),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                info.monthlyPrice,
                style: const TextStyle(
                  color: Color(0xFF3CE081),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (final feature in info.features)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      color: Color(0xFF3CE081), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      featureLabels[feature] ?? feature.name,
                      style: const TextStyle(
                        color: Color(0xFFB8D4C8),
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: isCurrent
                ? OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      disabledForegroundColor: const Color(0xFF3CE081),
                      side: const BorderSide(color: Color(0xFF1E8F5C)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Current Plan'),
                  )
                : FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1E8F5C),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFF1F4734),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: busy ? null : onSelect,
                    child: Text(
                      info.tier == AppTier.gm ? 'Upgrade to GM' : 'Switch to PRO',
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
