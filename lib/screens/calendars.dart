import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../models/models.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// Lets the user pick which of the phone's calendars appear in DayFlow.
class CalendarsScreen extends StatefulWidget {
  const CalendarsScreen({super.key});

  @override
  State<CalendarsScreen> createState() => _CalendarsScreenState();
}

class _CalendarsScreenState extends State<CalendarsScreen> {
  late Set<String> _hidden;
  late bool _show;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final state = AppScope.read(context);
    _hidden = {...state.settings.hiddenCalendars};
    _show = state.settings.showCalendar;
    // Calendars may have been added in the system app since launch.
    state.refreshCalendar();
  }

  Future<void> _done() async {
    final state = AppScope.read(context);
    setState(() => _saving = true);
    try {
      // Drop ids of calendars that no longer exist on this phone.
      final known = state.calendars.map((c) => c.id).toSet();
      await state.updateSettings({
        'showCalendar': _show,
        'hiddenCalendars': _hidden.where(known.contains).toList()..sort(),
      });
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, 'Could not save. Check your connection.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final state = AppScope.of(context);

    // Group by account, keeping the bridge's alphabetical order.
    final groups = <String, List<DeviceCal>>{};
    for (final cal in state.calendars) {
      groups.putIfAbsent(cal.source.isEmpty ? 'Other' : cal.source, () => [])
          .add(cal);
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  DfSpace.s3, DfSpace.s2, DfSpace.s3, 0),
              child: Row(
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel',
                        style: DfText.body.copyWith(color: c.textSecondary)),
                  ),
                  Expanded(
                    child: Text('Calendars',
                        textAlign: TextAlign.center,
                        style: DfText.h3.copyWith(color: c.text)),
                  ),
                  TextButton(
                    onPressed: _saving ? null : _done,
                    child: Text('Done',
                        style: DfText.bodyStrong.copyWith(color: c.primary)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                    DfSpace.s5, DfSpace.s2, DfSpace.s5, DfSpace.s8),
                children: [
                  Text(
                    'Pick which calendars appear in DayFlow. Events are read-only and never leave your phone.',
                    style: DfText.small.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: DfSpace.s4),
                  DfCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Row(
                      children: [
                        Icon(LucideIcons.calendar, size: 20, color: c.event),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text('Show calendar events',
                              style: DfText.body.copyWith(color: c.text)),
                        ),
                        Switch(
                          value: _show,
                          onChanged: (v) => setState(() => _show = v),
                        ),
                      ],
                    ),
                  ),
                  if (state.calendars.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: DfSpace.s6),
                      child: Text(
                        'No calendars found on this phone. Add an account in Settings › Calendar › Accounts and it will appear here.',
                        textAlign: TextAlign.center,
                        style: DfText.small.copyWith(color: c.textMuted),
                      ),
                    ),
                  for (final entry in groups.entries) ...[
                    Padding(
                      padding: const EdgeInsets.only(
                          top: DfSpace.s5, bottom: DfSpace.s2),
                      child: Overline(entry.key),
                    ),
                    // Greyed out while the master switch is off.
                    Opacity(
                      opacity: _show ? 1 : 0.5,
                      child: DfCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Column(
                          children: [
                            for (var i = 0; i < entry.value.length; i++) ...[
                              if (i > 0) Divider(color: c.border),
                              _CalendarRow(
                                cal: entry.value[i],
                                checked: !_hidden.contains(entry.value[i].id),
                                onChanged: !_show
                                    ? null
                                    : (on) => setState(() {
                                          final id = entry.value[i].id;
                                          on
                                              ? _hidden.remove(id)
                                              : _hidden.add(id);
                                        }),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CalendarRow extends StatelessWidget {
  const _CalendarRow({
    required this.cal,
    required this.checked,
    required this.onChanged,
  });

  final DeviceCal cal;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Semantics(
      checked: checked,
      label: cal.title,
      child: InkWell(
        onTap: onChanged == null ? null : () => onChanged!(!checked),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 52),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                    color: Color(cal.color), shape: BoxShape.circle),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(cal.title.isEmpty ? 'Untitled' : cal.title,
                    style: DfText.body.copyWith(color: c.text)),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: checked ? c.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: checked ? c.primary : c.borderStrong,
                    width: 2,
                  ),
                ),
                child: checked
                    ? const Icon(LucideIcons.check,
                        size: 15, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
