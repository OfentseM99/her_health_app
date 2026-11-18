import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/design_a.dart';

class HealthHistoryScreen extends StatefulWidget {
  const HealthHistoryScreen({super.key});

  @override
  State<HealthHistoryScreen> createState() => _HealthHistoryScreenState();
}

class _HealthHistoryScreenState extends State<HealthHistoryScreen> {
  List<dynamic> _journeys = [];
  final Map<int, Future<List<dynamic>>> _entryRequests = {};

  bool _loading = true;
  bool _switching = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  String _journeyName(String type) {
    const names = {
      'pregnancy_care': 'Pregnancy Care',
      'menstrual_health': 'Menstrual Health',
      'postpartum_recovery': 'Postpartum Recovery',
      'general_health': "General Women's Health",
      'cosmetic_gynecology': 'Cosmetic Gynaecology',
    };

    return names[type] ?? type.replaceAll('_', ' ');
  }

  IconData _journeyIcon(String type) {
    switch (type) {
      case 'pregnancy_care':
        return Icons.pregnant_woman_rounded;
      case 'menstrual_health':
        return Icons.calendar_month_rounded;
      case 'postpartum_recovery':
        return Icons.child_friendly_rounded;
      case 'general_health':
        return Icons.favorite_border_rounded;
      case 'cosmetic_gynecology':
        return Icons.spa_outlined;
      default:
        return Icons.health_and_safety_outlined;
    }
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Date unavailable';

    final parsed = DateTime.tryParse(value.toString());
    if (parsed == null) return value.toString();

    final day = parsed.day.toString().padLeft(2, '0');
    final month = parsed.month.toString().padLeft(2, '0');

    return '$day/$month/${parsed.year}';
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final journeys = await AuthService.getHealthJourneyHistory();

      if (!mounted) return;

      setState(() {
        _journeys = journeys;
        _entryRequests.clear();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _loadEntries(int journeyId) {
    if (_entryRequests.containsKey(journeyId)) return;

    setState(() {
      _entryRequests[journeyId] =
          AuthService.getHealthTrackingEntries(journeyId: journeyId);
    });
  }

  Future<void> _activateJourney(int journeyId) async {
    if (_switching) return;

    setState(() => _switching = true);

    try {
      await AuthService.activateHealthJourney(journeyId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your active health journey has been changed.'),
        ),
      );

      await _loadHistory();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not switch journey: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _switching = false);
      }
    }
  }

  Widget _buildEntryList(int journeyId) {
    final request = _entryRequests[journeyId];

    if (request == null) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Text('Open this section to view its tracking entries.'),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: request,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Could not load entries: ${snapshot.error}'),
          );
        }

        final entries = snapshot.data ?? [];

        if (entries.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child:
                Text('No tracking entries have been saved for this journey.'),
          );
        }

        return Column(
          children: entries.map((entry) {
            final data = entry is Map ? entry['data'] : null;
            final details = data is Map ? data : <dynamic, dynamic>{};

            final symptoms = details['symptoms'];
            final journal = details['journal'];

            return ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 4,
              ),
              leading: const Icon(
                Icons.event_note_outlined,
                color: DA.sage,
              ),
              title: Text(
                _formatDate(entry['entry_date']),
                style: DA.body(14, weight: FontWeight.w700),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry['mood'] != null) Text('Mood: ${entry['mood']}'),
                  if (entry['pain_level'] != null)
                    Text('Pain: ${entry['pain_level']}'),
                  if (symptoms != null)
                    Text(
                        'Symptoms: ${symptoms is List ? symptoms.join(', ') : symptoms}'),
                  if (journal != null && journal.toString().trim().isNotEmpty)
                    Text('Journal: $journal'),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildJourneyCard(Map journey) {
    final type = journey['journey_type']?.toString() ?? '';
    final id = int.tryParse(journey['id'].toString());
    final isActive = journey['is_active'] == true;

    return Card(
      color: DA.surface,
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: isActive ? DA.rose : DA.blush,
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            leading: CircleAvatar(
              backgroundColor: DA.blush,
              child: Icon(_journeyIcon(type), color: DA.rose),
            ),
            title: Text(
              _journeyName(type),
              style: DA.body(16, weight: FontWeight.w700),
            ),
            subtitle: Text(
              'Saved: ${_formatDate(journey['created_at'])}',
              style: DA.body(12, color: DA.quiet),
            ),
            trailing: isActive
                ? const Chip(
                    label: Text('Active'),
                    visualDensity: VisualDensity.compact,
                  )
                : null,
          ),
          if (!isActive && id != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _switching ? null : () => _activateJourney(id),
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('Make active'),
                ),
              ),
            ),
          if (id != null)
            ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 16),
              title: Text(
                'Tracking history',
                style: DA.body(14, weight: FontWeight.w600),
              ),
              onExpansionChanged: (expanded) {
                if (expanded) _loadEntries(id);
              },
              children: [_buildEntryList(id)],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DA.ground,
      appBar: AppBar(
        title: Text('Health History', style: DA.heading(20)),
        backgroundColor: DA.ground,
        foregroundColor: DA.ink,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Refresh history',
            onPressed: _loading ? null : _loadHistory,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, size: 42),
                        const SizedBox(height: 12),
                        Text(
                          'Could not load your health history.',
                          style: DA.body(16, weight: FontWeight.w700),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _loadHistory,
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  ),
                )
              : _journeys.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.history_rounded,
                              size: 52,
                              color: DA.sage,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No saved journeys yet',
                              style: DA.heading(18),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Your previous and current health journeys will appear here.',
                              style: DA.body(14, color: DA.quiet),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadHistory,
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          Text(
                            'Your health journeys',
                            style: DA.heading(20),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'View your saved journeys and their tracking entries. You can switch back to a previous journey at any time.',
                            style: DA.body(14, color: DA.quiet),
                          ),
                          const SizedBox(height: 18),
                          ..._journeys.whereType<Map>().map(_buildJourneyCard),
                        ],
                      ),
                    ),
    );
  }
}
