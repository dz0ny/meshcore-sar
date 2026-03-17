import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';

class MapLegend extends StatelessWidget {
  final int teamMemberCount;
  final int foundPersonCount;
  final int fireCount;
  final int stagingAreaCount;
  final int objectCount;

  const MapLegend({
    super.key,
    required this.teamMemberCount,
    required this.foundPersonCount,
    required this.fireCount,
    required this.stagingAreaCount,
    required this.objectCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Legend',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _LegendItem(
              icon: Icons.person,
              color: Theme.of(context).colorScheme.primary,
              label: AppLocalizations.of(context)!.team,
              count: teamMemberCount,
            ),
            _LegendItem(
              icon: Icons.person_pin,
              color: Colors.green,
              label: AppLocalizations.of(context)!.found,
              count: foundPersonCount,
            ),
            _LegendItem(
              icon: Icons.local_fire_department,
              color: Colors.red,
              label: AppLocalizations.of(context)!.fire,
              count: fireCount,
            ),
            _LegendItem(
              icon: Icons.home_work,
              color: Colors.orange,
              label: AppLocalizations.of(context)!.staging,
              count: stagingAreaCount,
            ),
            _LegendItem(
              icon: Icons.inventory_2,
              color: Colors.purple,
              label: AppLocalizations.of(context)!.object,
              count: objectCount,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final int count;

  const _LegendItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              count.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
