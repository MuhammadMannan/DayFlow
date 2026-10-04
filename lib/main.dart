import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'data/app_state.dart';
import 'data/notifications.dart';
import 'firebase_options.dart';
import 'screens/auth/auth.dart';
import 'screens/onboarding.dart';
import 'screens/shell.dart';
import 'theme/tokens.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Notifications.init();
  runApp(const DayFlowApp());
}

class DayFlowApp extends StatefulWidget {
  const DayFlowApp({super.key});

  @override
  State<DayFlowApp> createState() => _DayFlowAppState();
}

class _DayFlowAppState extends State<DayFlowApp> with WidgetsBindingObserver {
  AppState? _state;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FirebaseAuth.instance.userChanges().listen(_onUser);
  }

  void _onUser(User? user) {
    _ready = true;
    if (user?.uid == _state?.user.uid && user != null) {
      // Same account (e.g. display name updated): keep the live state.
      setState(() {});
      return;
    }
    _state?.removeListener(_rebuild);
    _state?.dispose();
    // Reminders belong to the account, so drop them when it changes.
    if (user == null) Notifications.clear();
    _state = user == null ? null : (AppState(user)..addListener(_rebuild));
    setState(() {});
  }

  // Theme lives in settings, so the app root follows state changes.
  void _rebuild() => setState(() {});

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Pick up calendar changes and a new day when returning to the app.
    if (state == AppLifecycleState.resumed) {
      _state?.refreshCalendar();
      _state?.syncNotifications();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _state;
    final mode = switch (state?.settings.theme) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
    return MaterialApp(
      title: 'DayFlow',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: mode,
      home: !_ready
          ? const Scaffold(body: SizedBox.shrink())
          : state == null
              ? const WelcomeScreen()
              : AppScope(
                  key: ValueKey(state.user.uid),
                  state: state,
                  child: !state.settingsLoaded
                      ? const Scaffold(body: SizedBox.shrink())
                      : state.settings.onboarded
                          ? const Shell()
                          : const OnboardingScreen(),
                ),
    );
  }
}
