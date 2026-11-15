import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'models.dart';
import 'setup_sheet.dart';
import 'screens/chat_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/home_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/translate_screen.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    // Named app.env (not .env) because web servers often refuse to serve dotfiles.
    await dotenv.load(fileName: 'assets/app.env');
  } catch (_) {
    // Missing file: the app still starts and explains how to add the key.
  }
  runApp(const QuestFriendApp());
}

class QuestFriendApp extends StatelessWidget {
  const QuestFriendApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quest Friend',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      // Keeps a phone-shaped layout when demoing in a wide Chrome window.
      builder: (context, child) => ColoredBox(
        color: QF.border,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ClipRect(child: child),
          ),
        ),
      ),
      home: const SplashGate(),
    );
  }
}

/// Splash first, then the app.
class SplashGate extends StatefulWidget {
  const SplashGate({super.key});

  @override
  State<SplashGate> createState() => _SplashGateState();
}

class _SplashGateState extends State<SplashGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: _ready ? const HomeShell(key: ValueKey('shell')) : const _Splash(key: ValueKey('splash')),
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: QF.primary,
      body: NightScene(
        hillHeight: 150,
        showStar: false,
        child: Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 1000),
            curve: Curves.easeOutCubic,
            builder: (_, t, child) => Opacity(
              opacity: t,
              child: Transform.scale(scale: 0.85 + 0.15 * t, child: child),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const LogoMark(size: 132),
              const SizedBox(height: 22),
              Text('Quest Friend',
                  style: kDisplay.copyWith(fontSize: 34, color: QF.background)),
              const SizedBox(height: 8),
              const Text('A friend for every stretch of the journey',
                  style: TextStyle(color: QF.highlight, fontSize: 15)),
            ]),
          ),
        ),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !TripState.I.isSetUp) showSetupSheet(context);
    });
  }

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(children: [
          const LogoMark(size: 34),
          const SizedBox(width: 10),
          Text('Quest Friend', style: kDisplay.copyWith(fontSize: 20)),
        ]),
        actions: [
          ListenableBuilder(
            listenable: TripState.I,
            builder: (context, _) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: () => showSetupSheet(context),
                icon: const Icon(Icons.public, size: 18),
                label: Text(TripState.I.country ?? 'Set trip'),
              ),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(onNavigate: _go),
          const TranslateScreen(),
          const ScanScreen(),
          const ExploreScreen(),
          const ChatScreen(),
        ],
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : NavigationBar(
              selectedIndex: _tab,
              onDestinationSelected: _go,
              destinations: const [
                NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
                NavigationDestination(icon: Icon(Icons.translate), label: 'Translate'),
                NavigationDestination(icon: Icon(Icons.photo_camera_outlined), selectedIcon: Icon(Icons.photo_camera), label: 'Scan'),
                NavigationDestination(icon: Icon(Icons.map_outlined), selectedIcon: Icon(Icons.map), label: 'Explore'),
                NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Ask'),
              ],
            ),
    );
  }
}
