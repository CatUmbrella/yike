import 'package:flutter/material.dart';
import 'screens/arrange_page.dart';
import 'screens/pomodoro_page.dart';
import 'screens/template_page.dart';
import 'screens/data_page.dart';

void main() => runApp(const YiKeApp());

class YiKeApp extends StatelessWidget {
  const YiKeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '一刻',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF5DADE2),
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFEBF5FB),
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
    const pages = [
      ArrangePage(),
      PomodoroPage(),
      TemplatePage(),
      DataPage(),
    ];
    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Colors.grey.shade400)),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (i) {
                final labels = ['安排', '番茄钟', '模板', '数据'];
                final selected = i == _index;
                return GestureDetector(
                  onTap: () => setState(() => _index = i),
                  child: Container(
                    width: 62,
                    height: 34,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected
                          ? Colors.grey.shade300
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
