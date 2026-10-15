import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_chat.dart';
import 'quiz_store.dart';

void main() => runApp(const AmanSarthiApp());

const navy = Color(0xFF0B1020);
const blue = Color(0xFF6385FF);
const violet = Color(0xFFA78BFA);
const bg = Color(0xFF090D19);
const ink = Color(0xFFF2F3FF);
const muted = Color(0xFF9AA7C4);
const line = Color(0xFF29334D);
const green = Color(0xFF42D6AE);

const featuredSubjects = [
  ('Physics', Icons.science_rounded, Color(0xFF3A70E8)),
  ('Chemistry', Icons.biotech_rounded, Color(0xFFE08C35)),
  ('Maths', Icons.functions_rounded, Color(0xFF7658D9)),
  ('English', Icons.translate_rounded, Color(0xFF168B75)),
  ('Biology', Icons.eco_rounded, Color(0xFF4B9B60)),
  ('Hindi', Icons.menu_book_rounded, Color(0xFFD45C68)),
  ('SST', Icons.public_rounded, Color(0xFF4680A8)),
];
const schoolSubjects = [
  'Mathematics',
  'Science',
  'English',
  'Social Science',
  'Physics',
  'Chemistry',
  'Maths',
  'Biology',
  'Hindi',
  'SST',
];
const examSubjects = [
  'Mathematics',
  'Reasoning',
  'General Knowledge',
  'English',
];
const schoolClasses = [
  'Class 6',
  'Class 7',
  'Class 8',
  'Class 9',
  'Class 10',
  'Class 11',
  'Class 12',
];
const graduationSubjects = [
  'Computer Science',
  'Commerce',
  'Arts and Humanities',
  'Mathematics',
  'English',
];
const competitiveExams = ['SSC', 'Railway', 'Police'];

class AmanSarthiApp extends StatelessWidget {
  const AmanSarthiApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Aman Sarthi AI',
    debugShowCheckedModeBanner: false,
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      fontFamily: 'Roboto',
      scaffoldBackgroundColor: bg,
      colorScheme:
          ColorScheme.fromSeed(
            seedColor: violet,
            brightness: Brightness.dark,
            surface: const Color(0xFF11182A),
          ).copyWith(
            primary: const Color(0xFF9C8BFF),
            onPrimary: const Color(0xFF100C26),
            secondary: const Color(0xFF70A5FF),
            surface: const Color(0xFF11182A),
            surfaceContainerHighest: const Color(0xFF192239),
            outline: const Color(0xFF34405D),
            outlineVariant: const Color(0xFF29334D),
          ),
      cardTheme: CardThemeData(
        color: const Color(0xFF11182A),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF11182A),
        hintStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: blue, width: 1.5),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: bg,
        foregroundColor: ink,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF11182A),
        indicatorColor: violet.withValues(alpha: .18),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? violet : muted,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: const Color(0xFF252D43),
        contentTextStyle: const TextStyle(color: ink),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    home: const MainShell(),
  );
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int index = 0;

  final pages = const [
    HomePage(),
    NotesPage(),
    AiTutorPage(),
    TestsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final wide = constraints.maxWidth >= 850;
      final content = AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: KeyedSubtree(key: ValueKey(index), child: pages[index]),
      );
      if (wide) {
        return Scaffold(
          body: Row(
            children: [
              Container(
                width: 260,
                color: Theme.of(context).colorScheme.surface,
                child: SafeArea(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(24, 24, 16, 28),
                        child: _BrandLockup(),
                      ),
                      Expanded(
                        child: NavigationRail(
                          extended: true,
                          selectedIndex: index,
                          onDestinationSelected: (value) =>
                              setState(() => index = value),
                          backgroundColor: Theme.of(context)
                              .colorScheme
                              .surface,
                          indicatorColor: violet.withValues(alpha: .18),
                          destinations: _railDestinations,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              VerticalDivider(
                width: 1,
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              Expanded(child: content),
            ],
          ),
        );
      }
      return Scaffold(
        body: content,
        bottomNavigationBar: NavigationBar(
          selectedIndex: index,
          onDestinationSelected: (value) => setState(() => index = value),
          backgroundColor: Theme.of(context).colorScheme.surface,
          indicatorColor: violet.withValues(alpha: .18),
          destinations: _navigationDestinations,
        ),
      );
    },
  );
}

const _navigationDestinations = [
  NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
  NavigationDestination(icon: Icon(Icons.menu_book_rounded), label: 'Notes'),
  NavigationDestination(
    icon: Icon(Icons.auto_awesome_rounded),
    label: 'AI Tutor',
  ),
  NavigationDestination(icon: Icon(Icons.quiz_rounded), label: 'Tests'),
  NavigationDestination(icon: Icon(Icons.person_rounded), label: 'Profile'),
];

const _railDestinations = [
  NavigationRailDestination(
    icon: Icon(Icons.home_rounded),
    label: Text('Home'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.menu_book_rounded),
    label: Text('Notes'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.auto_awesome_rounded),
    label: Text('AI Tutor'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.quiz_rounded),
    label: Text('Tests'),
  ),
  NavigationRailDestination(
    icon: Icon(Icons.person_rounded),
    label: Text('Profile'),
  ),
];

class _BrandLockup extends StatelessWidget {
  const _BrandLockup();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [blue, violet]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.school_rounded, color: Colors.white),
      ),
      const SizedBox(width: 11),
      const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aman Sarthi AI',
            style: TextStyle(fontWeight: FontWeight.w900, color: ink),
          ),
          Text(
            'LEARN • PRACTICE • GROW',
            style: TextStyle(fontSize: 9, color: muted, letterSpacing: .7),
          ),
        ],
      ),
    ],
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final searchController = TextEditingController();
  String query = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1120),
          child: ListView(
            key: const ValueKey('home-dashboard-scroll'),
            padding: EdgeInsets.symmetric(
              horizontal: constraints.maxWidth > 700 ? 36 : 18,
              vertical: 22,
            ),
            children: [
              Row(
                children: [
                  if (constraints.maxWidth < 850) const _BrandLockup(),
                  if (constraints.maxWidth >= 850)
                    const Expanded(
                      child: Text(
                        'Your learning dashboard',
                        style: TextStyle(color: muted),
                      ),
                    )
                  else
                    const Spacer(),
                  IconButton(
                    onPressed: () => toast(context, 'You are all caught up!'),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.surface,
                      foregroundColor: violet,
                    ),
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: ink,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              Container(
                padding: EdgeInsets.all(constraints.maxWidth > 650 ? 32 : 23),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3730A3), Color(0xFF2563EB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: [
                    BoxShadow(
                      color: blue.withValues(alpha: .16),
                      blurRadius: 26,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 0,
                      bottom: -18,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white.withValues(alpha: .12),
                        size: constraints.maxWidth > 650 ? 150 : 96,
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'YOUR NEXT BIG STEP STARTS HERE',
                          style: TextStyle(
                            color: Color(0xFFDCE4FF),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          constraints.maxWidth > 650
                              ? 'Welcome back, learner!'
                              : 'Welcome back,\nlearner!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: constraints.maxWidth > 650 ? 34 : 29,
                            height: 1.12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Build strong concepts. Make every study session count.',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              TextField(
                controller: searchController,
                onChanged: (value) =>
                    setState(() => query = value.trim().toLowerCase()),
                decoration: const InputDecoration(
                  hintText: 'Search subjects',
                  prefixIcon: Icon(Icons.search_rounded, color: muted),
                ),
              ),
              const SizedBox(height: 27),
              _SectionHeading(
                title: 'Pick up where you left off',
                action: 'View all',
                onAction: () => openPage(context, 1),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _QuickActionCard(
                    icon: Icons.menu_book_rounded,
                    title: 'Study Notes',
                    subtitle: 'Boards & subjects',
                    color: blue,
                    onTap: () => openPage(context, 1),
                  ),
                  _QuickActionCard(
                    icon: Icons.auto_awesome_rounded,
                    title: 'AI Tutor',
                    subtitle: 'Ask and learn',
                    color: violet,
                    onTap: () => openPage(context, 2),
                  ),
                  _QuickActionCard(
                    icon: Icons.quiz_rounded,
                    title: 'Practice Tests',
                    subtitle: 'Check your progress',
                    color: green,
                    onTap: () => openPage(context, 3),
                  ),
                  _QuickActionCard(
                    icon: Icons.bookmark_rounded,
                    title: 'Bookmarks',
                    subtitle: 'Saved chapters',
                    color: const Color(0xFFE08C35),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const BookmarksPage()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              _SectionHeading(
                title: 'Explore subjects',
                subtitle: 'Choose a subject to explore chapters and lessons',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: featuredSubjects
                    .where(
                      (subject) => subject.$1.toLowerCase().contains(query),
                    )
                    .map(
                      (subject) => _SubjectCard(
                        name: subject.$1,
                        icon: subject.$2,
                        color: subject.$3,
                        width: constraints.maxWidth > 850
                            ? 145
                            : constraints.maxWidth > 480
                            ? 145
                            : (constraints.maxWidth - 50) / 2,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TopicPage(
                              subject: subject.$1,
                              className: 'All Classes',
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (featuredSubjects
                  .where((subject) => subject.$1.toLowerCase().contains(query))
                  .isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    'No subjects found. Try another search.',
                    style: TextStyle(color: muted),
                  ),
                ),
              const SizedBox(height: 28),
              const _SectionHeading(
                title: 'School classes',
                subtitle: 'Choose a class to explore school subjects',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: schoolClasses
                    .map(
                      (className) => _QuickActionCard(
                        icon: Icons.school_rounded,
                        title: className,
                        subtitle: 'CBSE • UP Board',
                        color: blue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubjectPage(title: className),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 26),
              const _SectionHeading(
                title: 'Graduation',
                subtitle: 'Sample learning paths for undergraduate study',
              ),
              const SizedBox(height: 14),
              KeyedSubtree(
                key: const ValueKey('home-graduation-card'),
                child: _QuickActionCard(
                  icon: Icons.account_balance_rounded,
                  title: 'Graduation',
                  subtitle: 'Local demo subjects',
                  color: violet,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SubjectPage(title: 'Graduation'),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 26),
              const _SectionHeading(
                title: 'Competitive exams',
                subtitle: 'Prepare for your next goal',
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                children: competitiveExams
                    .map(
                      (exam) => _QuickActionCard(
                        icon: Icons.workspace_premium_rounded,
                        title: exam,
                        subtitle: 'Exam preparation',
                        color: const Color(0xFFD68223),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubjectPage(title: exam),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF102A2B),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lightbulb_rounded, color: green, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Small steps every day lead to big achievements.',
                        style: TextStyle(
                          color: ink,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? action;
  final VoidCallback? onAction;

  const _SectionHeading({
    required this.title,
    this.subtitle,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: const TextStyle(color: muted, fontSize: 13),
              ),
            ],
          ],
        ),
      ),
      if (action != null) TextButton(onPressed: onAction, child: Text(action!)),
    ],
  );
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: MediaQuery.sizeOf(context).width > 850 ? 260 : null,
    child: Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(15),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: ink,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: const TextStyle(color: muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded, color: muted, size: 18),
            ],
          ),
        ),
      ),
    ),
  );
}

class _SubjectCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color color;
  final double width;
  final VoidCallback onTap;

  const _SubjectCard({
    required this.name,
    required this.icon,
    required this.color,
    required this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 15),
              Text(
                name,
                style: const TextStyle(color: ink, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              const Text(
                'Explore lessons',
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

void openPage(BuildContext context, int page) {
  switch (page) {
    case 1:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const NotesPage()),
      );
      break;
    case 2:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AiTutorPage()),
      );
      break;
    case 3:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const TestsPage()),
      );
      break;
    case 4:
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
      break;
  }
}

void toast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

class NotesPage extends StatelessWidget {
  const NotesPage({super.key});

  final groups = const {
    'CBSE': schoolClasses,
    'UP Board': schoolClasses,
    'Graduation': ['Graduation'],
    'Competitive Exams': ['SSC', 'Railway', 'Police', 'General Knowledge'],
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Study Notes')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Your study library',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Choose a learning path to find your courses and notes.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 20),
            ...groups.entries.map(
              (group) => Card(
                margin: const EdgeInsets.only(bottom: 14),
                child: ExpansionTile(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: group.key == 'Competitive Exams'
                        ? const Color(0xFFFFF1DF)
                        : const Color(0xFFE9F1FF),
                    child: Icon(
                      group.key == 'Competitive Exams'
                          ? Icons.workspace_premium_rounded
                          : Icons.school_rounded,
                      color: group.key == 'Competitive Exams'
                          ? const Color(0xFFD68223)
                          : blue,
                    ),
                  ),
                  title: Text(
                    group.key,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  subtitle: Text(switch (group.key) {
                    'Competitive Exams' => 'Prepare for your next goal',
                    'Graduation' => 'Sample learning path',
                    _ => 'Classes 6 to 12',
                  }, style: const TextStyle(color: muted, fontSize: 12)),
                  children: group.value.map((item) {
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 22,
                        vertical: 2,
                      ),
                      leading: const Icon(Icons.menu_book_rounded, color: blue),
                      title: Text(item),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 15,
                        color: muted,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SubjectPage(title: item),
                          ),
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class SubjectPage extends StatelessWidget {
  final String title;

  const SubjectPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    final isGraduation = title == 'Graduation';
    final isExam = !title.contains('Class') && !isGraduation;
    final subjects = title.contains('Class')
        ? schoolSubjects
        : isGraduation
        ? graduationSubjects
        : examSubjects;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: LayoutBuilder(
            builder: (context, constraints) => ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  isGraduation
                      ? 'Demo learning path'
                      : isExam
                      ? 'Exam preparation'
                      : 'Your courses',
                  style: const TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isGraduation
                      ? 'Local sample content • ${subjects.length} subjects'
                      : '$title • ${subjects.length} subjects to explore',
                  style: const TextStyle(color: muted),
                ),
                const SizedBox(height: 20),
                ...subjects.map((subject) {
                  final style = _subjectStyle(subject);
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      leading: CircleAvatar(
                        radius: 25,
                        backgroundColor: style.$2.withValues(alpha: .1),
                        child: Icon(style.$1, color: style.$2),
                      ),
                      title: Text(
                        subject,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      subtitle: const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Text(
                          'Chapters • Notes • Practice',
                          style: TextStyle(color: muted, fontSize: 12),
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: muted,
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                TopicPage(subject: subject, className: title),
                          ),
                        );
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class TopicPage extends StatelessWidget {
  final String subject;
  final String className;

  const TopicPage({super.key, required this.subject, required this.className});

  @override
  Widget build(BuildContext context) {
    final topics = _chaptersFor(subject);

    return Scaffold(
      appBar: AppBar(title: Text(subject)),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                '$className  /  $subject',
                style: const TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 7),
              Text(
                '$subject course',
                style: const TextStyle(
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  color: ink,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Select a chapter to open notes and video lessons.',
                style: TextStyle(color: muted),
              ),
              const SizedBox(height: 20),
              ...topics.asMap().entries.map(
                (entry) => Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0xFFEAF0FF),
                      child: Text(
                        '${entry.key + 1}'.padLeft(2, '0'),
                        style: const TextStyle(
                          color: blue,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    title: Text(
                      entry.value,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: ink,
                      ),
                    ),
                    subtitle: const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Lesson notes • Video lecture',
                        style: TextStyle(color: muted, fontSize: 12),
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: muted,
                    ),
                    onTap: () {
                      if (entry.value == 'Practice Quiz') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TestsPage(
                              subject: subject,
                              chapter: entry.value,
                            ),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LessonPage(
                              subject: subject,
                              chapter: entry.value,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BookmarkStore {
  static const _storageKey = 'aman_sarthi_bookmarks_v1';
  static final _preferences = SharedPreferencesAsync();

  static String id(String subject, String chapter) => '$subject::$chapter';

  static (String, String)? parse(String value) {
    final separator = value.indexOf('::');
    if (separator <= 0 || separator + 2 >= value.length) return null;
    return (value.substring(0, separator), value.substring(separator + 2));
  }

  static Future<List<String>> all() async =>
      await _preferences.getStringList(_storageKey) ?? <String>[];

  static Future<bool> contains(String subject, String chapter) async =>
      (await all()).contains(id(subject, chapter));

  static Future<bool> toggle(String subject, String chapter) async {
    final bookmarks = await all();
    final bookmarkId = id(subject, chapter);
    final saved = !bookmarks.remove(bookmarkId);
    if (saved) bookmarks.insert(0, bookmarkId);
    await _preferences.setStringList(_storageKey, bookmarks);
    return saved;
  }

  static Future<void> remove(String bookmarkId) async {
    final bookmarks = await all()
      ..remove(bookmarkId);
    await _preferences.setStringList(_storageKey, bookmarks);
  }
}

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> {
  List<String> _bookmarks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBookmarks());
  }

  Future<void> _loadBookmarks() async {
    final bookmarks = await BookmarkStore.all();
    if (mounted) {
      setState(() {
        _bookmarks = bookmarks;
        _loading = false;
      });
    }
  }

  Future<void> _remove(String bookmarkId) async {
    await BookmarkStore.remove(bookmarkId);
    if (mounted) {
      setState(() => _bookmarks.remove(bookmarkId));
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Bookmarks')),
    body: _loading
        ? const Center(child: CircularProgressIndicator())
        : _bookmarks.isEmpty
        ? const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 48, color: muted),
                  SizedBox(height: 12),
                  Text(
                    'No saved chapters yet',
                    style: TextStyle(
                      color: ink,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Open a lesson and tap the bookmark icon to save it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
            ),
          )
        : Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _bookmarks.length,
                itemBuilder: (context, index) {
                  final bookmarkId = _bookmarks[index];
                  final bookmark = BookmarkStore.parse(bookmarkId);
                  if (bookmark == null) return const SizedBox.shrink();
                  final (subject, chapter) = bookmark;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const Icon(Icons.bookmark_rounded, color: blue),
                      title: Text(chapter),
                      subtitle: Text(subject),
                      onTap: () => Navigator.push<void>(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              LessonPage(subject: subject, chapter: chapter),
                        ),
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove bookmark',
                        onPressed: () => _remove(bookmarkId),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
  );
}

List<String> _chaptersFor(String subject) {
  switch (subject) {
    case 'Mathematics':
    case 'Maths':
      return ['Number System', 'Algebra', 'Geometry', 'Practice Questions'];
    case 'Science':
      return ['Physics', 'Chemistry', 'Biology', 'Practice Questions'];
    case 'Physics':
      return ['Motion', 'Force and Laws of Motion', 'Work and Energy', 'Sound'];
    case 'Chemistry':
      return [
        'Matter in Our Surroundings',
        'Atoms and Molecules',
        'Structure of Atom',
        'Chemical Reactions',
      ];
    case 'Biology':
      return [
        'The Fundamental Unit of Life',
        'Tissues',
        'Diversity in Living Organisms',
        'Life Processes',
      ];
    case 'English':
      return [
        'Grammar',
        'Tenses',
        'Active and Passive Voice',
        'Direct and Indirect Speech',
        'Vocabulary',
        'Reading Comprehension',
        'Practice Quiz',
      ];
    case 'Hindi':
      return ['व्याकरण', 'अपठित गद्यांश', 'शब्द-भंडार', 'अभ्यास प्रश्न'];
    case 'SST':
    case 'Social Science':
      return ['History', 'Geography', 'Political Science', 'Economics'];
    default:
      return [
        'Introduction',
        'Important Concepts',
        'Revision',
        'Practice Questions',
      ];
  }
}

(IconData, Color) _subjectStyle(String subject) {
  for (final item in featuredSubjects) {
    if (item.$1 == subject) return (item.$2, item.$3);
  }
  return switch (subject) {
    'Mathematics' => (Icons.functions_rounded, violet),
    'Science' => (Icons.science_rounded, blue),
    'Social Science' => (Icons.public_rounded, const Color(0xFF4680A8)),
    'Reasoning' => (Icons.psychology_rounded, violet),
    _ => (Icons.menu_book_rounded, blue),
  };
}

class LessonPage extends StatefulWidget {
  final String subject;
  final String chapter;

  const LessonPage({super.key, required this.subject, required this.chapter});

  @override
  State<LessonPage> createState() => _LessonPageState();
}

class _LessonPageState extends State<LessonPage> {
  int tab = 0;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadBookmark());
  }

  Future<void> _loadBookmark() async {
    final isBookmarked = await BookmarkStore.contains(
      widget.subject,
      widget.chapter,
    );
    if (mounted) setState(() => _isBookmarked = isBookmarked);
  }

  Future<void> _toggleBookmark() async {
    try {
      final saved = await BookmarkStore.toggle(widget.subject, widget.chapter);
      if (!mounted) return;
      setState(() => _isBookmarked = saved);
      toast(
        context,
        saved ? 'Chapter saved to Bookmarks.' : 'Bookmark removed.',
      );
    } catch (_) {
      if (mounted) toast(context, 'Bookmark could not be saved. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.chapter),
      actions: [
        IconButton(
          tooltip: _isBookmarked ? 'Remove bookmark' : 'Save bookmark',
          onPressed: _toggleBookmark,
          icon: Icon(
            _isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
          ),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              widget.subject.toUpperCase(),
              style: const TextStyle(
                color: blue,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.chapter,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: ink,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Learn at your pace with chapter notes and lessons.',
              style: TextStyle(color: muted),
            ),
            const SizedBox(height: 20),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(
                  value: 0,
                  label: Text('Chapter notes'),
                  icon: Icon(Icons.notes_rounded),
                ),
                ButtonSegment(
                  value: 1,
                  label: Text('Video lecture'),
                  icon: Icon(Icons.play_circle_outline_rounded),
                ),
              ],
              selected: {tab},
              onSelectionChanged: (selection) =>
                  setState(() => tab = selection.first),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => TestsPage(
                      subject: widget.subject,
                      chapter: widget.chapter,
                    ),
                  ),
                ),
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('Chapter practice tests'),
              ),
            ),
            const SizedBox(height: 18),
            if (tab == 0)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_stories_rounded, color: blue),
                          SizedBox(width: 9),
                          Text(
                            'Chapter notes',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'No notes have been published for this chapter yet.',
                        style: TextStyle(height: 1.65, color: muted),
                      ),
                      const SizedBox(height: 18),
                      OutlinedButton.icon(
                        onPressed: () => setState(() => tab = 1),
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        label: const Text('Go to video lecture'),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                height: 310,
                decoration: BoxDecoration(
                  color: const Color(0xFF17233D),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.ondemand_video_rounded,
                      size: 62,
                      color: Colors.white70,
                    ),
                    SizedBox(height: 14),
                    Text(
                      'No video lecture published',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Check back when a lecture is added to this chapter.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );

}

class AiTutorPage extends StatelessWidget {
  const AiTutorPage({super.key});

  void _openChat(BuildContext context) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => const AiChatPage()),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('AI Tutor')),
    body: Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 38,
                    color: violet,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Your learning companion',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: ink,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sawaal poochhein aur study concepts samjhein. Online AI '
                    'ke liye secure HTTPS backend configure hona zaroori hai. '
                    'Photo picker available hai, lekin abhi image analysis '
                    'enable nahi hai.',
                    style: TextStyle(color: muted, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => _openChat(context),
                    icon: const Icon(Icons.chat_rounded),
                    label: const Text('Chat shuru karein'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class TestsPage extends StatefulWidget {
  const TestsPage({super.key, this.subject, this.chapter});

  final String? subject;
  final String? chapter;

  @override
  State<TestsPage> createState() => _TestsPageState();
}

class _TestsPageState extends State<TestsPage> {
  final _store = QuizStore();
  List<StudyQuiz> _quizzes = [];
  List<QuizAttempt> _attempts = [];
  bool _loading = true;
  String? _loadError;

  List<StudyQuiz> get _visibleQuizzes => _quizzes.where((quiz) {
    return (widget.subject == null ||
            quiz.subject.toLowerCase() == widget.subject!.toLowerCase()) &&
        (widget.chapter == null ||
            quiz.chapter.toLowerCase() == widget.chapter!.toLowerCase());
  }).toList();

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final quizzes = await _store.loadQuizzes();
      final attempts = await _store.loadAttempts();
      if (!mounted) return;
      setState(() {
        _quizzes = quizzes;
        _attempts = attempts;
        _loading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Saved tests could not be loaded: $error';
      });
    }
  }

  Future<void> _createQuiz([StudyQuiz? existing]) async {
    final quiz = await Navigator.push<StudyQuiz>(
      context,
      MaterialPageRoute(
        builder: (_) => QuizEditorPage(
          quiz: existing,
          defaultSubject: widget.subject,
          defaultChapter: widget.chapter,
        ),
      ),
    );
    if (quiz == null || !mounted) return;
    try {
      await _store.saveQuiz(quiz);
      await _load();
      if (mounted) toast(context, 'Test saved on this device.');
    } catch (error) {
      if (mounted) toast(context, 'Test could not be saved: $error');
    }
  }

  Future<void> _importJson() async {
    final source = await showDialog<String>(
      context: context,
      builder: (_) => const _ImportQuizDialog(),
    );
    if (source == null || !mounted) return;
    try {
      final imported = decodeQuizImport(source);
      for (final quiz in imported) {
        await _store.saveQuiz(quiz);
      }
      await _load();
      if (mounted) toast(context, '${imported.length} test(s) imported.');
    } catch (error) {
      if (mounted) toast(context, 'Import rejected: $error');
    }
  }

  Future<void> _deleteQuiz(StudyQuiz quiz) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this test?'),
        content: Text(
          '"${quiz.title}" and its saved progress will be removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _store.deleteQuiz(quiz.id);
      await _load();
    } catch (error) {
      if (mounted) toast(context, 'Test could not be deleted: $error');
    }
  }

  Future<void> _openQuiz(StudyQuiz quiz) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => QuizAttemptPage(quiz: quiz)),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.chapter == null ? 'Practice Tests' : '${widget.chapter} tests',
      ),
      actions: [
        IconButton(
          tooltip: 'Import test JSON',
          onPressed: _importJson,
          icon: const Icon(Icons.data_object_rounded),
        ),
        IconButton(
          tooltip: 'Create test',
          onPressed: () => _createQuiz(),
          icon: const Icon(Icons.add_rounded),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: violet),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Create or import your own question sets. Tests and answer keys are stored only on this device for private practice; results are not server-verified or published.',
                              style: TextStyle(color: muted, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_loadError != null)
                    Card(
                      child: ListTile(
                        leading: const Icon(
                          Icons.error_outline,
                          color: Colors.redAccent,
                        ),
                        title: Text(_loadError!),
                        trailing: IconButton(
                          onPressed: () => setState(() {
                            _loading = true;
                            _loadError = null;
                          }),
                          icon: const Icon(Icons.refresh_rounded),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'My tests',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: ink,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _createQuiz(),
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Create'),
                      ),
                    ],
                  ),
                  if (_visibleQuizzes.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(22),
                        child: Text(
                          'No matching tests yet. Create a question set manually or import validated JSON. No sample questions are pre-filled.',
                          style: TextStyle(color: muted),
                        ),
                      ),
                    ),
                  ..._visibleQuizzes.map((quiz) {
                    final quizAttempts = _attempts
                        .where((attempt) => attempt.quizId == quiz.id)
                        .toList();
                    final hasAttempts = quizAttempts.isNotEmpty;
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFEAF0FF),
                                child: Icon(Icons.quiz_rounded, color: blue),
                              ),
                              title: Text(
                                quiz.title,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (quiz.course.isNotEmpty) quiz.course,
                                  if (quiz.subject.isNotEmpty) quiz.subject,
                                  if (quiz.chapter.isNotEmpty) quiz.chapter,
                                  '${quiz.questions.length} questions',
                                  quiz.durationMinutes == 0
                                      ? 'Untimed'
                                      : '${quiz.durationMinutes} min',
                                ].join(' • '),
                              ),
                              onTap: () => _openQuiz(quiz),
                            ),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _openQuiz(quiz),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Start / resume'),
                                ),
                                TextButton.icon(
                                  onPressed: () => _createQuiz(quiz),
                                  icon: const Icon(Icons.edit_outlined),
                                  label: const Text('Edit'),
                                ),
                                const Spacer(),
                                IconButton(
                                  tooltip: 'Attempt history',
                                  onPressed: () => _showHistory(quiz),
                                  icon: const Icon(Icons.history_rounded),
                                ),
                                IconButton(
                                  tooltip: 'Delete test',
                                  onPressed: () => _deleteQuiz(quiz),
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                              ],
                            ),
                            if (hasAttempts)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${quizAttempts.length} completed attempt(s)',
                                  style: const TextStyle(
                                    color: muted,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 20),
                  const Text(
                    'Recent attempts',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: ink,
                    ),
                  ),
                  if (_attempts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'Completed test attempts will appear here.',
                        style: TextStyle(color: muted),
                      ),
                    ),
                  ..._attempts
                      .take(10)
                      .map(
                        (attempt) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.task_alt_rounded,
                            color: green,
                          ),
                          title: Text(attempt.quizTitle),
                          subtitle: Text(
                            '${attempt.completedAt.toLocal()} • ${attempt.accuracy.toStringAsFixed(0)}% accuracy',
                          ),
                          trailing: Text(
                            '${attempt.score.toStringAsFixed(1)} / ${attempt.totalMarks.toStringAsFixed(1)}',
                          ),
                        ),
                      ),
                ],
              ),
      ),
    ),
    floatingActionButton: FloatingActionButton.extended(
      onPressed: () => _createQuiz(),
      icon: const Icon(Icons.add_rounded),
      label: const Text('Create test'),
    ),
  );

  Future<void> _showHistory(StudyQuiz quiz) async {
    final attempts = await _store.loadAttempts(quizId: quiz.id);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: 420,
          child: attempts.isEmpty
              ? const Center(child: Text('No completed attempts yet.'))
              : ListView(
                  children: [
                    for (final (index, attempt) in attempts.indexed)
                      ListTile(
                        leading: CircleAvatar(child: Text('${index + 1}')),
                        title: Text(
                          '${attempt.score.toStringAsFixed(1)} / ${attempt.totalMarks.toStringAsFixed(1)}',
                        ),
                        subtitle: Text(
                          '${attempt.accuracy.toStringAsFixed(0)}% accuracy • ${attempt.completedAt.toLocal()}',
                        ),
                      ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ImportQuizDialog extends StatefulWidget {
  const _ImportQuizDialog();

  @override
  State<_ImportQuizDialog> createState() => _ImportQuizDialogState();
}

class _ImportQuizDialogState extends State<_ImportQuizDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Import test JSON'),
    content: SizedBox(
      width: 520,
      child: TextField(
        controller: _controller,
        minLines: 8,
        maxLines: 16,
        decoration: const InputDecoration(
          hintText: '{"title":"Chapter test","questions":[{"prompt":"...","options":["A","B"],"answerIndex":0}]}',
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: () => Navigator.pop(context, _controller.text),
        child: const Text('Validate and import'),
      ),
    ],
  );
}

class QuizEditorPage extends StatefulWidget {
  const QuizEditorPage({
    super.key,
    this.quiz,
    this.defaultSubject,
    this.defaultChapter,
  });

  final StudyQuiz? quiz;
  final String? defaultSubject;
  final String? defaultChapter;

  @override
  State<QuizEditorPage> createState() => _QuizEditorPageState();
}

class _QuizEditorPageState extends State<QuizEditorPage> {
  late final TextEditingController _title;
  late final TextEditingController _course;
  late final TextEditingController _subject;
  late final TextEditingController _chapter;
  late final TextEditingController _duration;
  late List<QuizQuestion> _questions;
  String? _error;

  @override
  void initState() {
    super.initState();
    final quiz = widget.quiz;
    _title = TextEditingController(text: quiz?.title ?? '');
    _course = TextEditingController(text: quiz?.course ?? '');
    _subject = TextEditingController(
      text: quiz?.subject ?? widget.defaultSubject ?? '',
    );
    _chapter = TextEditingController(
      text: quiz?.chapter ?? widget.defaultChapter ?? '',
    );
    _duration = TextEditingController(
      text: (quiz?.durationMinutes ?? 30).toString(),
    );
    _questions = List.of(quiz?.questions ?? const []);
  }

  @override
  void dispose() {
    _title.dispose();
    _course.dispose();
    _subject.dispose();
    _chapter.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _addQuestion([QuizQuestion? existing]) async {
    final question = await showDialog<QuizQuestion>(
      context: context,
      builder: (_) => QuestionEditorDialog(question: existing),
    );
    if (question == null || !mounted) return;
    setState(() {
      if (existing == null) {
        _questions.add(question);
      } else {
        final index = _questions.indexOf(existing);
        if (index != -1) _questions[index] = question;
      }
      _error = null;
    });
  }

  void _save() {
    try {
      final duration = int.parse(_duration.text.trim());
      final quiz = StudyQuiz(
        id: widget.quiz?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        title: _title.text.trim(),
        course: _course.text.trim(),
        subject: _subject.text.trim(),
        chapter: _chapter.text.trim(),
        durationMinutes: duration,
        questions: _questions,
      );
      quiz.validate();
      Navigator.pop(context, quiz);
    } catch (error) {
      setState(() => _error = 'Check the test details: $error');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.quiz == null ? 'Create test' : 'Edit test'),
      actions: [
        IconButton(
          tooltip: 'Save test',
          onPressed: _save,
          icon: const Icon(Icons.save_outlined),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Test details',
              style: TextStyle(fontSize: 23, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Test title *'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _course,
              decoration: const InputDecoration(labelText: 'Course / class'),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _subject,
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _chapter,
                    decoration: const InputDecoration(labelText: 'Chapter'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _duration,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Duration in minutes',
                helperText: 'Enter 0 for an untimed practice set.',
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Questions (${_questions.length}/100)',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _questions.length == 100
                      ? null
                      : () => _addQuestion(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_questions.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(18),
                  child: Text(
                    'Add your own questions. No sample questions will be inserted.',
                    style: TextStyle(color: muted),
                  ),
                ),
              ),
            ..._questions.indexed.map(
              (entry) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Text('${entry.$1 + 1}')),
                  title: Text(
                    entry.$2.prompt,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    '${entry.$2.difficulty} • ${entry.$2.marks} marks • −${entry.$2.negativeMarks} wrong answer',
                  ),
                  onTap: () => _addQuestion(entry.$2),
                  trailing: IconButton(
                    tooltip: 'Delete question',
                    onPressed: () =>
                        setState(() => _questions.removeAt(entry.$1)),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                ),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save test on this device'),
            ),
          ],
        ),
      ),
    ),
  );
}

class QuestionEditorDialog extends StatefulWidget {
  const QuestionEditorDialog({super.key, this.question});

  final QuizQuestion? question;

  @override
  State<QuestionEditorDialog> createState() => _QuestionEditorDialogState();
}

class _QuestionEditorDialogState extends State<QuestionEditorDialog> {
  late final TextEditingController _prompt;
  late final TextEditingController _explanation;
  late final TextEditingController _marks;
  late final TextEditingController _negativeMarks;
  late final TextEditingController _difficulty;
  late List<TextEditingController> _options;
  late int _answerIndex;
  String? _error;

  @override
  void initState() {
    super.initState();
    final question = widget.question;
    _prompt = TextEditingController(text: question?.prompt ?? '');
    _explanation = TextEditingController(text: question?.explanation ?? '');
    _marks = TextEditingController(text: '${question?.marks ?? 1}');
    _negativeMarks = TextEditingController(
      text: '${question?.negativeMarks ?? 0}',
    );
    _difficulty = TextEditingController(text: question?.difficulty ?? 'Medium');
    _options = (question?.options ?? const <String>[])
        .map((option) => TextEditingController(text: option))
        .toList();
    if (_options.isEmpty) {
      _options = List.generate(4, (_) => TextEditingController());
    }
    _answerIndex = question?.answerIndex ?? 0;
  }

  @override
  void dispose() {
    _prompt.dispose();
    _explanation.dispose();
    _marks.dispose();
    _negativeMarks.dispose();
    _difficulty.dispose();
    for (final option in _options) {
      option.dispose();
    }
    super.dispose();
  }

  void _save() {
    try {
      final question = QuizQuestion(
        prompt: _prompt.text.trim(),
        options: _options.map((option) => option.text.trim()).toList(),
        answerIndex: _answerIndex,
        explanation: _explanation.text.trim(),
        difficulty: _difficulty.text.trim(),
        marks: double.parse(_marks.text.trim()),
        negativeMarks: double.parse(_negativeMarks.text.trim()),
      );
      question.validate();
      Navigator.pop(context, question);
    } catch (error) {
      setState(() => _error = 'Please check this question: $error');
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.question == null ? 'Add question' : 'Edit question'),
    content: SizedBox(
      width: 520,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _prompt,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Question *'),
            ),
            const SizedBox(height: 12),
            for (final (index, option) in _options.indexed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: option,
                        decoration: InputDecoration(
                          labelText: 'Option ${index + 1} *',
                        ),
                      ),
                    ),
                    if (_options.length > 2)
                      IconButton(
                        tooltip: 'Remove option',
                        onPressed: () => setState(() {
                          _options.removeAt(index).dispose();
                          if (_answerIndex >= _options.length) {
                            _answerIndex = _options.length - 1;
                          }
                        }),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                  ],
                ),
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _options.length >= 8
                    ? null
                    : () =>
                          setState(() => _options.add(TextEditingController())),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add option'),
              ),
            ),
            DropdownButtonFormField<int>(
              initialValue: _answerIndex,
              decoration: const InputDecoration(labelText: 'Correct option'),
              items: List.generate(
                _options.length,
                (index) => DropdownMenuItem(
                  value: index,
                  child: Text('Option ${index + 1}'),
                ),
              ),
              onChanged: (value) {
                if (value != null) setState(() => _answerIndex = value);
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _explanation,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Solution / explanation',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _difficulty,
                    decoration: const InputDecoration(labelText: 'Difficulty'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _marks,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Marks'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _negativeMarks,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Wrong penalty',
                    ),
                  ),
                ),
              ],
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _save, child: const Text('Save question')),
    ],
  );
}

class QuizAttemptPage extends StatefulWidget {
  const QuizAttemptPage({super.key, required this.quiz});

  final StudyQuiz quiz;

  @override
  State<QuizAttemptPage> createState() => _QuizAttemptPageState();
}

class _QuizAttemptPageState extends State<QuizAttemptPage> {
  final _store = QuizStore();
  late List<int?> _answers;
  final Set<int> _reviewed = {};
  int _current = 0;
  int _remainingSeconds = 0;
  bool _loading = true;
  bool _finished = false;
  bool _submitting = false;
  QuizAttempt? _result;
  Timer? _timer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.quiz.durationMinutes * 60;
    _answers = List<int?>.filled(widget.quiz.questions.length, null);
    unawaited(_restore());
  }

  Future<void> _restore() async {
    try {
      final draft = await _store.loadDraft(
        widget.quiz.id,
        widget.quiz.questions.length,
        widget.quiz.durationMinutes * 60,
      );
      for (var index = 0; index < draft.answers.length; index++) {
        final answer = draft.answers[index];
        if (answer != null &&
            answer >= widget.quiz.questions[index].options.length) {
          throw const FormatException(
            'Saved answer no longer matches the test options.',
          );
        }
      }
      if (!mounted) return;
      setState(() {
        _answers = draft.answers;
        _reviewed
          ..clear()
          ..addAll(draft.reviewedQuestions);
        _remainingSeconds = draft.remainingSeconds;
        _loading = false;
      });
      if (widget.quiz.durationMinutes > 0) _startTimer();
    } catch (error) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Saved progress could not be restored: $error';
        });
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_remainingSeconds <= 0) {
      unawaited(_submit());
      return;
    }
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || _finished) {
        timer.cancel();
        return;
      }
      setState(() => _remainingSeconds--);
      if (_remainingSeconds <= 0) {
        timer.cancel();
        unawaited(_submit());
      } else if (_remainingSeconds % 5 == 0) {
        unawaited(_persistDraft());
      }
    });
  }

  Future<void> _persistDraft() =>
      _store.saveDraft(widget.quiz.id, _answers, _reviewed, _remainingSeconds);

  void _selectAnswer(int? value) {
    setState(() => _answers[_current] = value);
    unawaited(_persistDraft());
  }

  void _toggleReview() {
    setState(() {
      if (!_reviewed.add(_current)) _reviewed.remove(_current);
    });
    unawaited(_persistDraft());
  }

  Future<void> _submit() async {
    if (_finished || _loading || _submitting) return;
    setState(() => _submitting = true);
    _timer?.cancel();
    var correctCount = 0;
    var answeredCount = 0;
    var score = 0.0;
    for (var index = 0; index < widget.quiz.questions.length; index++) {
      final question = widget.quiz.questions[index];
      final answer = _answers[index];
      if (answer == null) continue;
      answeredCount++;
      if (answer == question.answerIndex) {
        correctCount++;
        score += question.marks;
      } else {
        score -= question.negativeMarks;
      }
    }
    final attempt = QuizAttempt(
      quizId: widget.quiz.id,
      quizTitle: widget.quiz.title,
      answers: List.of(_answers),
      correctCount: correctCount,
      answeredCount: answeredCount,
      score: score.clamp(0, widget.quiz.totalMarks).toDouble(),
      totalMarks: widget.quiz.totalMarks,
      completedAt: DateTime.now(),
    );
    try {
      await _store.saveAttempt(attempt);
      await _store.clearDraft(widget.quiz.id);
      if (mounted) {
        setState(() {
          _result = attempt;
          _finished = true;
          _submitting = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = 'Result could not be saved: $error';
          _submitting = false;
        });
      }
    }
  }

  String get _timerLabel {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _timer?.cancel();
    if (!_finished && !_loading) unawaited(_persistDraft());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.quiz.title)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_finished && _result != null) return _buildResults(_result!);
    final question = widget.quiz.questions[_current];
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.quiz.title),
        actions: [
          if (widget.quiz.durationMinutes > 0)
            Padding(
              padding: const EdgeInsets.only(right: 18),
              child: Center(
                child: Text(
                  _timerLabel,
                  style: TextStyle(
                    color: _remainingSeconds < 60 ? Colors.redAccent : ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${widget.quiz.chapter.isEmpty ? 'Question' : widget.quiz.chapter} • ${_current + 1}/${widget.quiz.questions.length}',
                              style: const TextStyle(color: muted),
                            ),
                          ),
                          Text('${question.marks} marks'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: (_current + 1) / widget.quiz.questions.length,
                        color: blue,
                      ),
                      const SizedBox(height: 22),
                      Text(
                        question.prompt,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${question.difficulty} • Wrong answer: −${question.negativeMarks}',
                        style: const TextStyle(color: muted),
                      ),
                      const SizedBox(height: 14),
                      RadioGroup<int>(
                        groupValue: _answers[_current],
                        onChanged: _selectAnswer,
                        child: Column(
                          children: List.generate(
                            question.options.length,
                            (index) => Card(
                              color: _answers[_current] == index
                                  ? const Color(0xFFEAF0FF)
                                  : Theme.of(context).colorScheme.surface,
                              child: RadioListTile<int>(
                                value: index,
                                activeColor: blue,
                                title: Text(question.options[index]),
                              ),
                            ),
                          ),
                        ),
                      ),
                      if (_error != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            _error!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ),
                      Wrap(
                        spacing: 8,
                        children: [
                          OutlinedButton.icon(
                            onPressed: _toggleReview,
                            icon: Icon(
                              _reviewed.contains(_current)
                                  ? Icons.flag_rounded
                                  : Icons.outlined_flag_rounded,
                            ),
                            label: Text(
                              _reviewed.contains(_current)
                                  ? 'Marked for review'
                                  : 'Mark for review',
                            ),
                          ),
                          if (_answers[_current] != null)
                            TextButton(
                              onPressed: () => _selectAnswer(null),
                              child: const Text('Clear answer'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Question palette',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: List.generate(
                          widget.quiz.questions.length,
                          (index) => Badge(
                            isLabelVisible: _reviewed.contains(index),
                            label: const Text('!'),
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                backgroundColor: _answers[index] != null
                                    ? green.withValues(alpha: .2)
                                    : null,
                                side: BorderSide(
                                  color: _current == index ? violet : line,
                                  width: _current == index ? 2 : 1,
                                ),
                                minimumSize: const Size(44, 42),
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () => setState(() => _current = index),
                              child: Text('${index + 1}'),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  OutlinedButton(
                    onPressed: _current == 0
                        ? null
                        : () => setState(() => _current--),
                    child: const Text('Previous'),
                  ),
                  const Spacer(),
                  if (_current < widget.quiz.questions.length - 1)
                    FilledButton(
                      onPressed: () => setState(() => _current++),
                      child: const Text('Next'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check_rounded),
                      label: Text(
                        _submitting ? 'Saving result' : 'Submit test',
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResults(QuizAttempt result) => Scaffold(
    appBar: AppBar(title: const Text('Test results')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    const Icon(
                      Icons.emoji_events_rounded,
                      size: 58,
                      color: Color(0xFFFFB800),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${result.score.toStringAsFixed(1)} / ${result.totalMarks.toStringAsFixed(1)} marks',
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${result.correctCount} correct • ${result.answeredCount} answered • ${result.accuracy.toStringAsFixed(1)}% accuracy',
                      style: const TextStyle(color: muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            for (final (index, question) in widget.quiz.questions.indexed)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. ${question.prompt}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.answers[index] == null
                            ? 'Not answered'
                            : 'Your answer: ${question.options[result.answers[index]!]}',
                        style: TextStyle(
                          color: result.answers[index] == question.answerIndex
                              ? green
                              : Colors.redAccent,
                        ),
                      ),
                      Text(
                        'Correct answer: ${question.options[question.answerIndex]}',
                      ),
                      if (question.explanation.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            question.explanation,
                            style: const TextStyle(color: muted),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to tests'),
            ),
          ],
        ),
      ),
    ),
  );
}

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('My Profile')),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 760),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 43,
                      backgroundColor: Color(0xFFEAF0FF),
                      child: Icon(Icons.person_rounded, size: 48, color: blue),
                    ),
                    SizedBox(height: 14),
                    Text(
                      'Student',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: ink,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Welcome to Aman Sarthi',
                      style: TextStyle(color: muted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.bookmarks_rounded, color: blue),
                title: const Text('Bookmarks'),
                subtitle: const Text('Your saved chapters'),
                trailing: const Icon(Icons.chevron_right_rounded, color: muted),
                onTap: () => Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const BookmarksPage(),
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.settings_rounded, color: blue),
                title: const Text('Settings'),
                trailing: const Icon(Icons.chevron_right_rounded, color: muted),
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Settings'),
                    content: const Text(
                      'Online AI backend ka address app build ke waqt set hota '
                      'hai. Provider API keys sirf backend par rakhein; '
                      'Flutter app mein kabhi nahi.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.privacy_tip_outlined, color: violet),
                title: const Text('Privacy'),
                subtitle: const Text('How chat messages are handled'),
                trailing: const Icon(Icons.chevron_right_rounded, color: muted),
                onTap: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Privacy notice'),
                    content: const SingleChildScrollView(
                      child: Text(
                        'When online AI is configured, recent text messages '
                        'are sent to the configured backend and forwarded to '
                        'its AI provider to generate a reply. That provider '
                        'may process messages under its own privacy and '
                        'retention terms. Up to 20 conversations are saved '
                        'locally in app preferences; this local history is '
                        'not encrypted and can be cleared from the chat '
                        'history menu. Selected photos are shown in the chat '
                        'but are not uploaded or analyzed. No end-to-end '
                        'encryption is claimed.',
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline_rounded, color: violet),
                title: const Text('About Aman Sarthi'),
                trailing: const Icon(Icons.chevron_right_rounded, color: muted),
                onTap: () => showAboutDialog(
                  context: context,
                  applicationName: 'Aman Sarthi AI',
                  applicationVersion: '1.0.1',
                  applicationLegalese: 'Learn • Practice • Grow',
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Center(
              child: Text(
                'Made for learners ❤️',
                style: TextStyle(color: muted),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
