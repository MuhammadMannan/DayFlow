import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../data/app_state.dart';
import '../data/notifications.dart';
import '../theme/tokens.dart';
import '../widgets/common.dart';

/// Three steps shown once after sign-up: daily goal, calendar, reminders.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _step = 0;
  int _goal = 1;
  bool _reminders = true;
  bool _nudge = true;
  bool _busy = false;

  Future<void> _finish({bool askPermission = false}) async {
    if (_busy) return;
    setState(() => _busy = true);
    final state = AppScope.read(context);
    if (askPermission) await Notifications.requestPermission();
    try {
      await state.updateSettings({
        // Skipping leaves the goal off; any completed task still counts.
        'dailyGoal': _step == 0 ? 0 : _goal,
        'remindersOn': _reminders,
        'nudgeOn': _nudge,
        'onboarded': true,
      });
    } catch (_) {
      if (mounted) {
        setState(() => _busy = false);
        showMessage(context, 'Could not save. Check your connection.');
      }
    }
  }

  void _next() => setState(() => _step++);

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              DfSpace.s6, DfSpace.s3, DfSpace.s6, DfSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: i == _step ? 40 : 22,
                      height: 6,
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: i <= _step ? c.primary : c.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _busy ? null : _finish,
                    child: Text('Skip',
                        style: DfText.body.copyWith(color: c.textMuted)),
                  ),
                ],
              ),
              const SizedBox(height: DfSpace.s3),
              Expanded(
                child: SingleChildScrollView(
                  child: switch (_step) {
                    0 => _goalStep(c),
                    1 => _calendarStep(c),
                    _ => _remindersStep(c),
                  },
                ),
              ),
              ...switch (_step) {
                0 => [DfButton(label: 'Continue', onPressed: _next)],
                1 => [
                    DfButton(
                      label: 'Connect calendars',
                      onPressed: () async {
                        await AppScope.read(context).connectCalendar();
                        if (mounted) _next();
                      },
                    ),
                    const SizedBox(height: DfSpace.s2),
                    Center(
                      child: TextButton(
                        onPressed: _next,
                        child: Text('Not now',
                            style: DfText.bodyStrong
                                .copyWith(color: c.primary)),
                      ),
                    ),
                  ],
                _ => [
                    DfButton(
                      label: 'Turn on notifications',
                      loading: _busy,
                      onPressed: (_reminders || _nudge)
                          ? () => _finish(askPermission: true)
                          : null,
                    ),
                    const SizedBox(height: DfSpace.s2),
                    Center(
                      child: TextButton(
                        onPressed: _busy ? null : _finish,
                        child: Text('Maybe later',
                            style: DfText.bodyStrong
                                .copyWith(color: c.primary)),
                      ),
                    ),
                  ],
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _heading(DfColors c, String title, String body) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DfText.h1.copyWith(color: c.text)),
          const SizedBox(height: DfSpace.s2),
          Text(body, style: DfText.body.copyWith(color: c.textSecondary)),
        ],
      );

  Widget _goalStep(DfColors c) {
    const options = [
      (1, '1 task', 'Recommended. Easy to keep going.'),
      (3, '3 tasks', 'A solid, focused day.'),
      (5, '5 tasks', 'For busy, list-heavy days.'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration:
              BoxDecoration(color: c.flameSoft, shape: BoxShape.circle),
          child: Icon(LucideIcons.flame, size: 36, color: c.flame),
        ),
        const SizedBox(height: DfSpace.s5),
        _heading(c, 'What counts as a good day?',
            'Finish at least one task and the day joins your streak. Want a bigger target? Pick a daily goal.'),
        const SizedBox(height: DfSpace.s4),
        for (final (value, title, body) in options)
          Padding(
            padding: const EdgeInsets.only(bottom: DfSpace.s3),
            child: Semantics(
              selected: _goal == value,
              button: true,
              child: GestureDetector(
                onTap: () => setState(() => _goal = value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  padding: const EdgeInsets.all(DfSpace.s4),
                  decoration: BoxDecoration(
                    color: _goal == value ? c.primarySoft : c.surface,
                    borderRadius: BorderRadius.circular(DfRadius.lg),
                    border: Border.all(
                      color: _goal == value ? c.primary : c.border,
                      width: _goal == value ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(title,
                                style:
                                    DfText.bodyStrong.copyWith(color: c.text)),
                            Text(body,
                                style: DfText.small
                                    .copyWith(color: c.textSecondary)),
                          ],
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _goal == value ? c.primary : Colors.transparent,
                          border: Border.all(
                            color:
                                _goal == value ? c.primary : c.borderStrong,
                            width: 2,
                          ),
                        ),
                        child: _goal == value
                            ? Center(
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surfaceMuted,
            borderRadius: BorderRadius.circular(DfRadius.md),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.snowflake, size: 18, color: c.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'You get one streak freeze a week, so one missed day won’t reset you.',
                  style: DfText.small.copyWith(color: c.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _calendarStep(DfColors c) {
    Widget event(String title, String detail) => Container(
          margin: const EdgeInsets.only(bottom: DfSpace.s2),
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          decoration: BoxDecoration(
            color: c.eventSoft,
            borderRadius: BorderRadius.circular(DfRadius.lg),
          ),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 36,
                decoration: BoxDecoration(
                    color: c.event, borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: DfText.bodyStrong.copyWith(color: c.text)),
                    Text(detail,
                        style:
                            DfText.small.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
              Icon(LucideIcons.calendar, size: 18, color: c.event),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // An example day, not the user's data.
        ExcludeSemantics(
          child: DfCard(
            radius: DfRadius.xl,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Monday',
                    style: DfText.bodyStrong.copyWith(color: c.text)),
                const SizedBox(height: DfSpace.s3),
                event('Sprint planning', '11:00 AM · from Google Calendar'),
                event('Lunch with Sara', '12:30 PM · from iCloud'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 0, 4),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: c.borderStrong, width: 2),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Pay rent',
                              style:
                                  DfText.bodyStrong.copyWith(color: c.text)),
                          Text('Anytime',
                              style:
                                  DfText.small.copyWith(color: c.textMuted)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: DfSpace.s5),
        _heading(c, 'See your day in one place',
            'DayFlow shows events from the calendars on your phone, including iCloud, Google and Outlook, next to your tasks.'),
        const SizedBox(height: DfSpace.s3),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(LucideIcons.lock, size: 16, color: c.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Read-only. DayFlow never edits or deletes your events.',
                style: DfText.small.copyWith(color: c.textSecondary),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _remindersStep(DfColors c) {
    Widget sample(String title, String body, String time) => Container(
          margin: const EdgeInsets.only(bottom: DfSpace.s2),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: c.surface,
            borderRadius: BorderRadius.circular(DfRadius.lg),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(DfRadius.sm),
                ),
                child: const Icon(LucideIcons.check,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(title,
                              style: DfText.smallStrong
                                  .copyWith(color: c.text)),
                        ),
                        Text(time,
                            style: DfText.caption
                                .copyWith(color: c.textMuted)),
                      ],
                    ),
                    Text(body,
                        style: DfText.small.copyWith(color: c.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ExcludeSemantics(
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
            decoration: BoxDecoration(
              color: c.primary,
              borderRadius: BorderRadius.circular(DfRadius.xl),
            ),
            child: Column(
              children: [
                sample('Call mom', 'At 6:00 PM · Personal', 'now'),
                sample(
                    'Keep your 12-day streak',
                    'You haven’t finished a task today. One quick win keeps it going.',
                    '8:00 PM'),
              ],
            ),
          ),
        ),
        const SizedBox(height: DfSpace.s5),
        _heading(c, 'Get reminded at the right time',
            'Tasks with a time can nudge you. We’ll also give one gentle evening heads-up if your streak is at risk.'),
        const SizedBox(height: DfSpace.s4),
        DfCard(
          borderColor: c.border,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              _toggle(c, 'Task reminders', 'At the time you set', _reminders,
                  (v) => setState(() => _reminders = v)),
              Divider(color: c.border),
              _toggle(c, 'Streak-at-risk nudge', '8:00 PM, only if needed',
                  _nudge, (v) => setState(() => _nudge = v)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _toggle(DfColors c, String title, String body, bool value,
          ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: DfText.bodyStrong.copyWith(color: c.text)),
                  Text(body,
                      style: DfText.small.copyWith(color: c.textMuted)),
                ],
              ),
            ),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
      );
}
