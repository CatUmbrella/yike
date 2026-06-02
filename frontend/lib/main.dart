import 'package:flutter/material.dart';

import 'screens/arrange/arrange_style.dart';
import 'screens/arrange_page.dart';
import 'screens/data_page.dart';
import 'screens/pomodoro_page.dart';
import 'screens/template_page.dart';

void main() => runApp(const YiKeApp());

class YiKeApp extends StatelessWidget {
  const YiKeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '一刻',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: ArrangeStyle.accent,
        useMaterial3: true,
        scaffoldBackgroundColor: ArrangeStyle.background,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    const pages = [ArrangePage(), PomodoroPage(), TemplatePage(), DataPage()];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 390;
    const labels = ['安排', '番茄钟', '模板', '数据'];

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          compact ? 14 : 24,
          6,
          compact ? 14 : 24,
          8,
        ),
        child: Container(
          height: compact ? 52 : 56,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: ArrangeStyle.surface,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: ArrangeStyle.border),
            boxShadow: ArrangeStyle.panelShadow,
          ),
          child: Row(
            children: List.generate(labels.length, (i) {
              final selected = i == _index;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _index = i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    curve: Curves.easeOut,
                    height: compact ? 38 : 42,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: selected
                          ? ArrangeStyle.accentSoft
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: compact ? 15 : 17,
                            fontWeight: selected
                                ? FontWeight.w700
                                : FontWeight.w600,
                            color: selected
                                ? ArrangeStyle.accent
                                : ArrangeStyle.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
