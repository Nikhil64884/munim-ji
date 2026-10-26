import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import '../services/localization_service.dart';
import 'shell.dart';

export '../services/localization_service.dart';

// Global state notifiers for responsive UI updates
final ValueNotifier<ThemeMode> themeModeNotifier = ValueNotifier<ThemeMode>(ThemeMode.light);
final ValueNotifier<String> shopNameNotifier = ValueNotifier<String>('');
final ValueNotifier<String> upiIdNotifier = ValueNotifier<String>('');
final ValueNotifier<String> langNotifier = ValueNotifier<String>('Hinglish');
final ValueNotifier<int> syncCountNotifier = ValueNotifier<int>(0);
final ValueNotifier<int> currentTabNotifier = ValueNotifier<int>(0);
final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

String tr(String key) => LocalizationService.tr(key, langNotifier.value);

void notifyDataChanged() {
  dataVersion.value++;
}

class C {
  // Brand Emerald & Gold Palette
  static const Color brand50 = Color(0xFFEEFBF4);
  static const Color brand100 = Color(0xFFD5F6E2);
  static const Color green = Color(0xFF0F6B4F); // Deep Indian Emerald
  static const Color greenDark = Color(0xFF08402E);
  static const Color greenLight = Color(0xFF138A66);

  static const Color gold = Color(0xFFF2B84B); // Festive Indian Gold
  static const Color goldDark = Color(0xFFD99F32);
  static const Color goldLight = Color(0xFFFDF4E3);

  // Financial Semantics
  static const Color red = Color(0xFFD1382C); // Udhaar Red
  static const Color redBg = Color(0xFFFDECEA);
  static const Color jama = Color(0xFF0D8A58); // Jama Green
  static const Color jamaBg = Color(0xFFE3F4EA);
  static const Color blue = Color(0xFF1D5FD1);
  static const Color blueBg = Color(0xFFE8F0FE);
  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleBg = Color(0xFFF3E8FF);

  // Neutrals
  static const Color bg = Color(0xFFF8FAF9);
  static const Color card = Colors.white;
  static const Color ink = Color(0xFF0F1E19);
  static const Color muted = Color(0xFF6B7D75);
  static const Color line = Color(0xFFE2E8E5);

  // Dark Mode Palette
  static const Color darkBg = Color(0xFF0D1412);
  static const Color darkCard = Color(0xFF16221E);
  static const Color darkBorder = Color(0xFF23352F);
  static const Color darkInk = Color(0xFFF4F7F5);
  static const Color darkMuted = Color(0xFF8FA199);
}

ThemeData munimTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: C.bg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.green,
      primary: C.green,
      secondary: C.gold,
      surface: C.card,
      brightness: Brightness.light,
    ),
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
  );
}

ThemeData munimDarkTheme() {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: C.darkBg,
    colorScheme: ColorScheme.fromSeed(
      seedColor: C.green,
      primary: C.green,
      secondary: C.gold,
      surface: C.darkCard,
      brightness: Brightness.dark,
    ),
    cardColor: C.darkCard,
  );
  return base.copyWith(
    textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
  );
}

String inr(int paise, {bool preserveSign = false}) {
  final f = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: paise.abs() % 100 == 0 ? 0 : 2,
  );
  final formatted = f.format(paise.abs() / 100);
  if (preserveSign && paise < 0) return '-$formatted';
  return formatted;
}

String fmtDate(dynamic iso) {
  if (iso == null) return '';
  final s = iso.toString().trim();
  final hasTimezone = s.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(s);
  final d = DateTime.tryParse(hasTimezone ? s : '${s}Z');
  if (d == null) return s;
  return DateFormat('d MMM, h:mm a').format(d.toLocal());
}

void toast(BuildContext context, String msg, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(
        msg,
        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600, color: Colors.white),
      ),
      backgroundColor: error ? C.red : C.greenDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
}

Future<T?> showMunimSheet<T>(BuildContext context, Widget child) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? C.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            )
          ],
        ),
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child,
          ],
        ),
      ),
    ),
  );
}

class _EditShopNameDialog extends StatefulWidget {
  const _EditShopNameDialog();
  @override
  State<_EditShopNameDialog> createState() => _EditShopNameDialogState();
}

class _EditShopNameDialogState extends State<_EditShopNameDialog> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: shopNameNotifier.value);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          tr('edit_shop_title'),
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: tr('edit_shop_title'),
            hintText: tr('shop_name_hint'),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            prefixIcon: const Icon(Icons.store_rounded),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: PBtn(
            tr('save'),
            icon: Icons.check_rounded,
            onPressed: () {
              final t = _ctrl.text.trim();
              if (t.isNotEmpty) {
                shopNameNotifier.value = t;
                StorageService.saveShopName(t);
                Navigator.pop(context);
              }
            },
          ),
        ),
      ],
    );
  }
}

/// Premium Top Header Matching the HTML Prototype
class MunimHeader extends StatelessWidget {
  final VoidCallback? onBack;
  final String? titleOverride;
  const MunimHeader({super.key, this.onBack, this.titleOverride});

  void _cycleLanguage() {
    final cur = langNotifier.value;
    final next = cur == 'Hinglish' ? 'हिंदी' : (cur == 'हिंदी' ? 'English' : 'Hinglish');
    langNotifier.value = next;
    StorageService.saveLanguage(next);
  }

  void _toggleDarkMode() {
    final next = themeModeNotifier.value == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    themeModeNotifier.value = next;
    StorageService.saveThemeMode(next == ThemeMode.dark ? 'dark' : 'light');
  }

  void _editShopName(BuildContext context) {
    showMunimSheet(
      context,
      const _EditShopNameDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16, topPad + 12, 16, 14),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [C.greenDark, C.green],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Store profile avatar + Store name & greeting + WhatsApp-style Back/Home button
          Expanded(
            child: Row(
              children: [
                ValueListenableBuilder<int>(
                  valueListenable: currentTabNotifier,
                  builder: (context, currentTab, _) {
                    final shell = Shell.of(context);
                    final isNotHome = (currentTab != 0);
                    final canGoBack = onBack != null || isNotHome || Navigator.canPop(context);
                    final VoidCallback? goBack = onBack ??
                        (isNotHome
                            ? () {
                                HapticFeedback.lightImpact();
                                shell?.setTab(0);
                              }
                            : (Navigator.canPop(context)
                                ? () {
                                    HapticFeedback.lightImpact();
                                    Navigator.maybePop(context);
                                  }
                                : null));

                    if (!canGoBack || goBack == null) {
                      return const SizedBox.shrink();
                    }

                    return Tooltip(
                      message: 'Home Page Par Jayein',
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: goBack,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.22),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white30, width: 1.2),
                            ),
                            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                GestureDetector(
                  onTap: () {
                    final shell = Shell.of(context);
                    if (currentTabNotifier.value != 0 && shell != null) {
                      HapticFeedback.lightImpact();
                      shell.setTab(0);
                    } else if (Navigator.canPop(context)) {
                      HapticFeedback.lightImpact();
                      Navigator.maybePop(context);
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: C.gold,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'M',
                          style: GoogleFonts.plusJakartaSans(
                            color: C.greenDark,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF34D399),
                            shape: BoxShape.circle,
                            border: Border.all(color: C.greenDark, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (titleOverride != null)
                        Text(
                          titleOverride!,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        )
                      else
                        GestureDetector(
                          onTap: () => _editShopName(context),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: ValueListenableBuilder<String>(
                                  valueListenable: shopNameNotifier,
                                  builder: (context, name, _) => Text(
                                    name.trim().isEmpty ? tr('set_shop_name') : name,
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      fontStyle: name.trim().isEmpty ? FontStyle.italic : FontStyle.normal,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.keyboard_arrow_down_rounded, color: C.gold, size: 16),
                            ],
                          ),
                        ),
                      ValueListenableBuilder<String>(
                        valueListenable: shopNameNotifier,
                        builder: (context, name, _) {
                          final trimmed = name.trim();
                          final greeting = trimmed.isEmpty
                              ? tr('welcome_merchant')
                              : 'Namaste ${trimmed.split(' ').first} Ji 🙏';
                          return Text(
                            greeting,
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Right: Action Pills (Sync, Lang, Theme)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Sync Status Pill
              ValueListenableBuilder<int>(
                valueListenable: syncCountNotifier,
                builder: (context, count, _) => GestureDetector(
                  onTap: () => toast(context, 'Sab data cloud par sync hai ✅'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF34D399),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${tr('sync')} ($count)',
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Language Cycle Pill
              ValueListenableBuilder<String>(
                valueListenable: langNotifier,
                builder: (context, lang, _) => GestureDetector(
                  onTap: _cycleLanguage,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.translate_rounded, color: C.gold, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          lang,
                          style: GoogleFonts.plusJakartaSans(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Dark Mode Toggle
              GestureDetector(
                onTap: _toggleDarkMode,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    color: isDark ? C.gold : Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

enum BK { primary, gold, outline, danger, dangerOutline, ghost }

class PBtn extends StatelessWidget {
  final String label;
  final IconData? icon;
  final BK kind;
  final VoidCallback? onPressed;
  const PBtn(this.label, {super.key, this.icon, this.kind = BK.primary, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final Color bg = switch (kind) {
      BK.primary => C.green,
      BK.gold => C.gold,
      BK.danger => C.red,
      BK.ghost => Colors.transparent,
      _ => Colors.white,
    };
    final Color fg = switch (kind) {
      BK.primary || BK.danger => Colors.white,
      BK.gold => C.greenDark,
      BK.outline => C.ink,
      BK.dangerOutline => C.red,
      BK.ghost => C.green,
    };
    final BorderSide side = kind == BK.outline
        ? const BorderSide(color: C.line, width: 1.5)
        : kind == BK.dangerOutline ? const BorderSide(color: C.red, width: 1.5) : BorderSide.none;

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        elevation: 0,
        minimumSize: const Size(0, 48),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: side),
        textStyle: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ]),
    );
  }
}

class CustRow extends StatelessWidget {
  final Map c;
  final VoidCallback onTap;
  const CustRow({super.key, required this.c, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = (c['name'] ?? '?').toString();
    final phone = (c['phone'] ?? '').toString();
    final paise = (c['balance_paise'] as num?)?.toInt() ?? 0;
    final owes = paise > 0;
    final color = paise == 0 ? C.muted : (owes ? C.red : C.jama);
    final letter = name.isEmpty ? '?' : name[0].toUpperCase();
    final colors = [
      const Color(0xFFE8F5E9),
      const Color(0xFFE3F2FD),
      const Color(0xFFFFF3E0),
      const Color(0xFFF3E5F5),
      const Color(0xFFE0F7FA)
    ];
    final avatarBg = colors[name.hashCode.abs() % colors.length];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? C.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFECEFEF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 23,
                  backgroundColor: isDark ? C.greenDark : avatarBg,
                  child: Text(
                    letter,
                    style: GoogleFonts.plusJakartaSans(
                      color: isDark ? C.gold : C.greenDark,
                      fontWeight: FontWeight.w800,
                      fontSize: 17,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? C.darkInk : C.ink,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          if (phone.isNotEmpty) ...[
                            Text(
                              phone,
                              style: GoogleFonts.plusJakartaSans(fontSize: 11, color: C.muted),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              paise == 0 ? tr('settled_tag') : (paise < 0 ? tr('advance_tag') : tr('due_tag')),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: color,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      paise == 0 ? '₹0' : inr(paise.abs()),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      paise == 0 ? tr('settled') : (paise > 0 ? tr('to_receive') : tr('to_pay')),
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: C.muted),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Mera QR" Modal for Instant UPI Payments with Real UPI Validation
void showMeraQrDialog(BuildContext context) {
  showMunimSheet(
    context,
    const _MeraQrSheet(),
  );
}

class _MeraQrSheet extends StatefulWidget {
  const _MeraQrSheet();
  @override
  State<_MeraQrSheet> createState() => _MeraQrSheetState();
}

class _MeraQrSheetState extends State<_MeraQrSheet> {
  late final TextEditingController _amtCtrl;
  late final TextEditingController _upiCtrl;
  bool _isEditingUpi = false;
  String? _upiError;

  @override
  void initState() {
    super.initState();
    _amtCtrl = TextEditingController();
    _upiCtrl = TextEditingController(text: upiIdNotifier.value);
    _isEditingUpi = upiIdNotifier.value.trim().isEmpty;
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  void _saveUpi() {
    final val = _upiCtrl.text.trim();
    final upiRegex = RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$');
    if (!upiRegex.hasMatch(val)) {
      setState(() {
        _upiError = 'Kripya sahi UPI ID daalein (jaise: 9876543210@paytm ya dukan@okhdfcbank)';
      });
      return;
    }
    setState(() {
      _upiError = null;
      _isEditingUpi = false;
    });
    upiIdNotifier.value = val;
    StorageService.saveUpiId(val);
    toast(context, 'UPI ID safalta se save ho gayi! ✅');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shop = shopNameNotifier.value.trim().isNotEmpty ? shopNameNotifier.value : 'Hamari Dukan';
    final upiId = upiIdNotifier.value.trim();
    final hasValidUpi = upiId.isNotEmpty && RegExp(r'^[\w.\-]{2,}@[a-zA-Z]{2,}$').hasMatch(upiId);

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mera Dukan QR Code',
                style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              )
            ],
          ),
          const SizedBox(height: 12),
          if (!hasValidUpi || _isEditingUpi) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? C.darkCard : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: C.gold.withValues(alpha: 0.5)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded, color: C.goldDark, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Apna Asli UPI ID Darj Karein',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: isDark ? Colors.white : C.ink,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Grahak se seedhe dukan ke bank account me paise lene ke liye apna asli UPI VPA daalein.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: C.muted),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _upiCtrl,
                    autofocus: true,
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Shopkeeper UPI ID',
                      hintText: 'e.g. 9876543210@paytm, dukan@okhdfcbank',
                      prefixIcon: const Icon(Icons.qr_code_scanner_rounded),
                      errorText: _upiError,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: PBtn(
                      'UPI ID Save Karein & QR Kholein',
                      icon: Icons.check_circle_rounded,
                      kind: BK.primary,
                      onPressed: _saveUpi,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Builder(builder: (context) {
              String amtParam = '';
              final amtText = _amtCtrl.text.trim();
              if (amtText.isNotEmpty) {
                final parsed = double.tryParse(amtText.replaceAll(',', ''));
                if (parsed != null && parsed > 0) {
                  amtParam = '&am=${parsed.toStringAsFixed(2)}';
                }
              }
              final upiUrl = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(shop)}$amtParam&cu=INR';

              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: C.gold.withValues(alpha: 0.4), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: C.gold.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: C.brand50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.verified_rounded, color: C.green, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                shop,
                                style: GoogleFonts.plusJakartaSans(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                  color: C.greenDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        // Real dynamic QR Code
                        Container(
                          width: 175,
                          height: 175,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.black12),
                          ),
                          child: Center(
                            child: QrImageView(
                              data: upiUrl,
                              version: QrVersions.auto,
                              size: 165.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'UPI ID: $upiId',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => setState(() => _isEditingUpi = true),
                              child: const Icon(Icons.edit_note_rounded, size: 18, color: C.green),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _amtCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
                    decoration: InputDecoration(
                      labelText: 'Custom Amount (Optional)',
                      prefixText: '₹ ',
                      hintText: 'Jaise: 500 ya 250.50',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: PBtn(
                      'Share QR WhatsApp Par',
                      icon: Icons.share_rounded,
                      kind: BK.gold,
                      onPressed: () async {
                        Navigator.pop(context);
                        final shareText = 'Namaste! $shop ka UPI Payment Link: $upiUrl';
                        await Clipboard.setData(ClipboardData(text: shareText));
                        final waUri = Uri.parse('https://wa.me/?text=${Uri.encodeComponent(shareText)}');
                        try {
                          await launchUrl(waUri, mode: LaunchMode.externalApplication);
                        } catch (_) {}
                        if (context.mounted) {
                          toast(context, 'Payment Link copy ho gaya & WhatsApp khol diya! 📲');
                        }
                      },
                    ),
                  ),
                ],
              );
            }),
          ],
        ],
      ),
    );
  }
}

/// WhatsApp Reminder Message Dialog
void showWhatsAppReminderModal(BuildContext context, {required String name, required int paise, String? phone}) {
  final amt = inr(paise);
  final shop = shopNameNotifier.value.trim().isNotEmpty ? shopNameNotifier.value : 'Hamari Dukan';
  // amt already contains '₹' symbol, so do not add an extra ₹
  final msg = 'Namaste $name ji! $shop par aapka $amt ka hisaab baki hai. Kripya samay par jama karwayein. Dhanyawaad 🙏';

  showMunimSheet(
    context,
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.mark_chat_unread_rounded, color: Color(0xFF25D366), size: 24),
                const SizedBox(width: 8),
                Text(
                  'WhatsApp Taqaza Bhejein',
                  style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800),
                ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              onPressed: () => Navigator.pop(context),
            )
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F5E9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF81C784)),
          ),
          child: Text(
            msg,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1B5E20),
              height: 1.4,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: PBtn(
                'Copy Text',
                icon: Icons.copy_rounded,
                kind: BK.outline,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: msg));
                  if (context.mounted) {
                    Navigator.pop(context);
                    toast(context, 'Reminder message copy ho gaya! 📋');
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: PBtn(
                'WhatsApp Kholein',
                icon: Icons.send_rounded,
                kind: BK.primary,
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: msg));
                  final digits = phone?.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
                  final tenDigits = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
                  final waUrl = tenDigits.length == 10
                      ? 'https://wa.me/91$tenDigits?text=${Uri.encodeComponent(msg)}'
                      : 'https://wa.me/?text=${Uri.encodeComponent(msg)}';
                  bool ok = false;
                  try {
                    ok = await launchUrl(Uri.parse(waUrl), mode: LaunchMode.externalApplication);
                  } catch (_) {}
                  if (context.mounted) {
                    Navigator.pop(context);
                    if (ok) {
                      toast(context, 'WhatsApp khola ja raha hai 💬');
                    } else {
                      toast(context, 'WhatsApp nahi khul paya. Kripya app check karein.', error: true);
                    }
                  }
                },
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

List<MapEntry<String, String>> replyActions(String reply) {
  final up = reply.toUpperCase();
  if (up.contains('HAAN') && up.contains('NAHI')) {
    return const [MapEntry('HAAN, likho', 'HAAN'), MapEntry('NAHI', 'NAHI')];
  }
  // Only convert numbered lines if bot is asking user to select/pick between choices
  final isPicker = up.contains('CHUN') || up.contains('KAUN') || up.contains('SELECT') || up.contains('OPTION') || up.contains('NAYA');
  if (!isPicker) return const [];

  final out = <MapEntry<String, String>>[];
  final re = RegExp(r'^\s*[*_]*(\d+)[.)]\s*(.+?)[*_]*\s*$');
  for (final line in reply.split('\n')) {
    final m = re.firstMatch(line);
    if (m != null) out.add(MapEntry('${m[1]}. ${m[2]}', m[1]!));
  }
  if (out.isNotEmpty && up.contains('NAYA')) out.add(const MapEntry('NAYA grahak', 'NAYA'));
  return out;
}

Future<void> chatDialog(BuildContext context, String text) async {
  var send = text;
  while (true) {
    final r = await ApiService.chat(send);
    if (!context.mounted) return;
    if (r['success'] != true) { toast(context, r['error'].toString(), error: true); return; }
    final d = r['data'];
    final reply = (d is Map ? d['reply'] : null)?.toString() ?? '';
    final acts = replyActions(reply);
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Munim Ji'),
        content: SingleChildScrollView(child: Text(reply.replaceAll('*', ''))),
        actions: acts.isEmpty ? [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Theek hai'))] : [for (final a in acts) TextButton(onPressed: () => Navigator.pop(ctx, a.value), child: Text(a.key))],
      ),
    );
    if (choice == null) return;
    send = choice;
  }
}

/// Shared Stateful Add Customer Sheet with 10-Digit Phone Validation
Future<Map<String, dynamic>?> showAddCustomerSheet(BuildContext context) {
  return showMunimSheet<Map<String, dynamic>?>(
    context,
    const _AddCustomerSheet(),
  );
}

class _AddCustomerSheet extends StatefulWidget {
  const _AddCustomerSheet();
  @override
  State<_AddCustomerSheet> createState() => _AddCustomerSheetState();
}

class _AddCustomerSheetState extends State<_AddCustomerSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  String? _phoneError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final rawPhone = _phoneCtrl.text.trim();
    final cleanPhone = rawPhone.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.isNotEmpty && cleanPhone.length != 10) {
      setState(() => _phoneError = 'Mobile number 10 digit ka hona chahiye');
      return;
    }
    setState(() {
      _phoneError = null;
      _saving = true;
    });

    final res = await ApiService.addCustomer(name, cleanPhone.isNotEmpty ? cleanPhone : '');
    if (!mounted) return;
    setState(() => _saving = false);

    if (res['success'] == true) {
      notifyDataChanged();
      Navigator.pop(context, {
        'id': res['data'] is Map ? (res['data'] as Map)['id'] : null,
        'name': name,
        'phone': cleanPhone,
      });
      toast(context, 'Grahak "$name" safalta se jud gaya! 🎉');
    } else {
      toast(context, res['error']?.toString() ?? 'Grahak jodna asafal raha', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+ Naya Grahak Jodein',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: 'Grahak Ka Naam *',
              hintText: 'e.g. Ramesh Kumar',
              prefixIcon: const Icon(Icons.person_outline_rounded),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Mobile Number (Optional)',
              hintText: '10 digit number',
              prefixIcon: const Icon(Icons.phone_outlined),
              errorText: _phoneError,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: PBtn(
              _saving ? 'Save Ho Raha Hai...' : 'Save & Turant Hisaab Kholein',
              icon: Icons.check_circle_rounded,
              onPressed: _saving ? null : _submit,
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog for entering and editing transaction amounts safely with managed controllers
Future<Map<String, String>?> askEntry(BuildContext context, String title, {String? amount, bool showItem = false}) {
  return showDialog<Map<String, String>>(
    context: context,
    builder: (ctx) => _AskEntryDialog(title: title, initialAmount: amount, showItem: showItem),
  );
}

class _AskEntryDialog extends StatefulWidget {
  final String title;
  final String? initialAmount;
  final bool showItem;
  const _AskEntryDialog({required this.title, this.initialAmount, required this.showItem});

  @override
  State<_AskEntryDialog> createState() => _AskEntryDialogState();
}

class _AskEntryDialogState extends State<_AskEntryDialog> {
  late final TextEditingController _a;
  late final TextEditingController _i;

  @override
  void initState() {
    super.initState();
    _a = TextEditingController(text: widget.initialAmount ?? '');
    _i = TextEditingController();
  }

  @override
  void dispose() {
    _a.dispose();
    _i.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _a,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(prefixText: '₹ ', labelText: 'Amount'),
          ),
          if (widget.showItem)
            TextField(
              controller: _i,
              decoration: const InputDecoration(labelText: 'Saman (optional)'),
            ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final v = double.tryParse(_a.text.replaceAll(',', '').trim());
            if (v == null || v <= 0) return;
            Navigator.pop(context, {
              'amt': v == v.roundToDouble() ? v.round().toString() : v.toString(),
              'item': _i.text.trim(),
            });
          },
          child: const Text('Aage badhein'),
        ),
      ],
    );
  }
}
/// Dedicated AI Voice Assistant Trigger: Routes directly to full-featured Chat page
void showMunimAiVoiceModal(BuildContext context) {
  Shell.of(context)?.setTab(2);
}
