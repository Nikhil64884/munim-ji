import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'chat_page.dart';
import 'home_page.dart';
import 'khata_page.dart';
import 'ocr_page.dart';
import 'report_page.dart';
import 'ui_kit.dart';

class Shell extends StatefulWidget {
  const Shell({super.key});

  static ShellState? of(BuildContext context) =>
      context.findAncestorStateOfType<ShellState>();

  @override
  State<Shell> createState() => ShellState();
}

class ShellState extends State<Shell> {
  int _i = 0;

  @override
  void initState() {
    super.initState();
    currentTabNotifier.value = _i;
  }

  int get currentTab => _i;

  void setTab(int index) {
    if (index >= 0 && index <= 4) {
      setState(() => _i = index);
      currentTabNotifier.value = index;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pages = <Widget>[
      const HomePage(),
      const KhataPage(),
      const ChatPage(),
      const OcrPage(),
      const ReportPage(),
    ];

    return Scaffold(
      backgroundColor: isDark ? C.darkBg : C.bg,
      extendBody: true,
      body: PopScope(
        canPop: _i == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop && _i != 0) {
            setTab(0);
          }
        },
        child: IndexedStack(
          index: _i,
          children: pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          child: Container(
            height: 66,
            decoration: BoxDecoration(
              color: isDark ? C.darkCard.withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: isDark ? C.darkBorder : const Color(0xFFE2E8E5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(
                  index: 0,
                  icon: Icons.home_rounded,
                  label: tr('nav_home'),
                  isSelected: _i == 0,
                  isDark: isDark,
                ),
                _navItem(
                  index: 1,
                  icon: Icons.menu_book_rounded,
                  label: tr('nav_khata'),
                  isSelected: _i == 1,
                  isDark: isDark,
                ),
                // Center Notched Gold Mic Button
                GestureDetector(
                  onTap: () => setTab(2),
                  child: Transform.translate(
                    offset: const Offset(0, -14),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [C.gold, Color(0xFFFFD166)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? C.darkBg : C.bg,
                          width: 4,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: C.gold.withValues(alpha: 0.5),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.mic_rounded,
                        color: C.greenDark,
                        size: 30,
                      ),
                    ),
                  ),
                ),
                _navItem(
                  index: 3,
                  icon: Icons.camera_alt_rounded,
                  label: tr('nav_scan'),
                  isSelected: _i == 3,
                  isDark: isDark,
                ),
                _navItem(
                  index: 4,
                  icon: Icons.bar_chart_rounded,
                  label: tr('nav_reports'),
                  isSelected: _i == 4,
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
    required bool isSelected,
    required bool isDark,
  }) {
    final activeCol = isDark ? C.gold : C.green;
    final inactiveCol = isDark ? C.darkMuted : const Color(0xFF9EABA4);

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => setTab(index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? activeCol : inactiveCol,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? activeCol : inactiveCol,
              ),
            ),
          ],
        ),
      ),
    );
  }
}