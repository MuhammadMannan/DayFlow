import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/tokens.dart';
import 'add_task.dart';
import 'analytics.dart';
import 'calendar.dart';
import 'home.dart';
import 'tasks.dart';

/// The four tabs and the centre add button. Tabs keep their state.
class Shell extends StatefulWidget {
  const Shell({super.key});

  static ShellState of(BuildContext context) =>
      context.findAncestorStateOfType<ShellState>()!;

  @override
  State<Shell> createState() => ShellState();
}

class ShellState extends State<Shell> {
  int _index = 0;

  void goTo(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final dark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        extendBody: true,
        body: IndexedStack(
          index: _index,
          children: const [
            HomeScreen(),
            CalendarScreen(),
            TasksScreen(),
            AnalyticsScreen(),
          ],
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: DfSpace.s4),
            child: SizedBox(
              height: 72,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: c.surface,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: c.border),
                      boxShadow: DfShadow.card,
                    ),
                    child: Row(
                      children: [
                        _Tab(LucideIcons.house, 'Home', 0, _index, goTo),
                        _Tab(LucideIcons.calendar, 'Calendar', 1, _index, goTo),
                        const SizedBox(width: 64),
                        _Tab(LucideIcons.listChecks, 'Tasks', 2, _index, goTo),
                        _Tab(LucideIcons.chartColumn, 'Analytics', 3, _index,
                            goTo),
                      ],
                    ),
                  ),
                  Semantics(
                    button: true,
                    label: 'Add task',
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        showAddTask(context);
                      },
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: c.primary,
                          shape: BoxShape.circle,
                          boxShadow: DfShadow.floating,
                        ),
                        child: const Icon(LucideIcons.plus,
                            color: Colors.white, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab(this.icon, this.label, this.index, this.current, this.onTap);

  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.df;
    final active = index == current;
    final color = active ? c.primary : c.textMuted;
    return Expanded(
      child: Semantics(
        selected: active,
        button: true,
        child: InkResponse(
          onTap: () => onTap(index),
          radius: 36,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 4),
              Text(
                label,
                style: DfText.overline.copyWith(
                  color: color,
                  letterSpacing: 0,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom padding so scrolling content clears the floating tab bar.
const double kTabBarClearance = 112;
