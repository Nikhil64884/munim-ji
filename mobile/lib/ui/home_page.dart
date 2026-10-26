import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'ledger_page.dart';
import 'shell.dart';
import 'ui_kit.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  String _getPeriodLabel(String k) {
    if (k == 'Today') return tr('period_today');
    if (k == 'Yesterday') return tr('period_yesterday');
    if (k == 'This Week') return tr('period_week');
    if (k == 'This Month') return tr('period_month');
    return k;
  }
  static const _periods = {
    'Today': 'today',
    'Yesterday': 'yesterday',
    'This Week': 'week',
    'This Month': 'month'
  };
  String _label = 'Today';
  bool _loading = true;
  String? _err;
  Map _sum = {};
  List _cust = [];
  int _loadRequestId = 0;

  @override
  void initState() {
    super.initState();
    dataVersion.addListener(_onDataVersionChanged);
    _load();
  }

  void _onDataVersionChanged() {
    if (mounted) _load();
  }

  @override
  void dispose() {
    dataVersion.removeListener(_onDataVersionChanged);
    super.dispose();
  }

  Future<void> _load() async {
    final currentId = ++_loadRequestId;
    setState(() {
      _loading = true;
      _err = null;
    });
    final s = await ApiService.getSummary(_periods[_label]!);
    final c = await ApiService.getCustomers();
    if (!mounted || currentId != _loadRequestId) return;
    setState(() {
      _loading = false;
      if (s['success'] == true && s['data'] is Map) {
        _sum = s['data'] as Map;
      } else {
        _err = s['error']?.toString();
      }
      if (c['success'] == true && c['data'] is Map) {
        _cust = ((c['data'] as Map)['customers'] as List?) ?? [];
      } else if (c['success'] != true && _err == null) {
        _err = c['error']?.toString();
      }
    });
  }


  Widget _buildAnimatedCounter(int paise, {required TextStyle style, String prefix = ''}) {
    return TweenAnimationBuilder<double>(
      key: ValueKey('${_label}_$paise'),
      tween: Tween<double>(begin: 0, end: paise.toDouble()),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Text('$prefix${inr(value.round())}', style: style),
    );
  }

  Future<void> _addCustomer() async {
    final res = await showAddCustomerSheet(context);
    if (res != null && mounted) {
      await _load();
      final id = res['id'];
      final name = res['name']?.toString() ?? '';
      final phone = res['phone']?.toString() ?? '';
      int newId = 0;
      if (id is num) {
        newId = id.toInt();
      } else {
        final found = _cust.firstWhere(
          (c) => c['name'].toString().trim().toLowerCase() == name.toLowerCase(),
          orElse: () => null,
        );
        if (found != null && found['id'] != null) {
          newId = (found['id'] as num).toInt();
        }
      }

      if (newId > 0 && mounted) {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LedgerPage(customerId: newId, name: name, phone: phone),
          ),
        );
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final totalDuePaise = ApiService.totalBaakiPaise(_cust);
    final totalAdvancePaise = _cust
        .where((c) => ((c['balance_paise'] as num?) ?? 0) < 0)
        .fold(0, (sum, c) => sum + ((c['balance_paise'] as num?) ?? 0).abs().toInt());

    final topOwing = _cust.where((c) => ((c['balance_paise'] as num?) ?? 0) > 0).toList()
      ..sort((a, b) => (((b['balance_paise'] as num?) ?? 0)).compareTo(((a['balance_paise'] as num?) ?? 0)));

    final jamaPaise = (_sum['jama_paise'] as num?)?.toInt() ?? 0;
    final salesPaise = (_sum['cash_sale_paise'] as num?)?.toInt() ?? 0;
    final udhaarPeriodPaise = (_sum['udhaar_paise'] as num?)?.toInt() ?? 0;
    final vasooliPct = (totalDuePaise + jamaPaise > 0)
        ? ((jamaPaise / (totalDuePaise + jamaPaise)) * 100).clamp(0, 100).round()
        : 100;

    return Scaffold(
      backgroundColor: isDark ? C.darkBg : C.bg,
      body: Column(
        children: [
          // Sticky Top Header
          const MunimHeader(),
          if (_loading)
            const LinearProgressIndicator(
              minHeight: 2,
              color: C.green,
              backgroundColor: Colors.transparent,
            ),

          // Main Scrollable Canvas
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: C.green,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  // Error Banner
                  if (_err != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: C.redBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: C.red.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: C.red, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _err!,
                              style: GoogleFonts.plusJakartaSans(
                                color: C.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.refresh_rounded, color: C.red, size: 18),
                            onPressed: _load,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),

                  // Period Selector Chips
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: isDark ? C.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? C.darkBorder : const Color(0xFFE2E8E5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        for (final k in _periods.keys)
                          Expanded(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() => _label = k);
                                _load();
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 38,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: k == _label ? C.green : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: k == _label
                                      ? [
                                          BoxShadow(
                                            color: C.green.withValues(alpha: 0.35),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          )
                                        ]
                                      : null,
                                ),
                                child: Text(
                                  _getPeriodLabel(k),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: k == _label ? FontWeight.w800 : FontWeight.w600,
                                    color: k == _label ? Colors.white : (isDark ? C.darkMuted : C.muted),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ================= MARKET DUES SUMMARY CARD =================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF0B543D), Color(0xFF0F6B4F), Color(0xFF08402E)],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF0F6B4F).withValues(alpha: 0.35),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  tr('total_udhaar_receive'),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFA7F3D0),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _buildAnimatedCounter(
                                  totalDuePaise,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  tr('total_advance_give'),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFA7F3D0),
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  inr(totalAdvancePaise),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: C.gold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 18),

                        // Vasooli Target Progress Bar (Dynamic)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white12),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${_getPeriodLabel(_label)} ${tr('vasooli_target')}',
                                    style: GoogleFonts.plusJakartaSans(
                                      color: const Color(0xFFD1FAE5),
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        '$vasooliPct%',
                                        style: GoogleFonts.plusJakartaSans(
                                          color: C.gold,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      const Icon(Icons.trending_up_rounded, color: C.gold, size: 14),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 7),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  height: 6,
                                  width: double.infinity,
                                  color: Colors.black38,
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: (vasooliPct / 100.0).clamp(0.04, 1.0),
                                    child: Container(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [C.gold, Color(0xFF34D399)],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Period Metrics Card (Bikri, Jama, Naya Udhaar)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? C.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_getPeriodLabel(_label)} ${tr('today_bikri')}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? C.darkMuted : C.muted,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                inr(salesPaise),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: C.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(width: 1, height: 26, color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_getPeriodLabel(_label)} ${tr('today_jama')}',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? C.darkMuted : C.muted,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  inr(jamaPaise),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: C.jama,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(width: 1, height: 26, color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${_getPeriodLabel(_label)} ${tr('today_udhaar')}',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? C.darkMuted : C.muted,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                inr(udhaarPeriodPaise),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: C.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ================= QUICK ACTIONS GRID =================
                  Row(
                    children: [
                      _actionCard(
                        icon: Icons.person_add_alt_1_rounded,
                        label: tr('action_add_customer'),
                        bgColor: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F5E9),
                        iconColor: C.green,
                        onTap: _addCustomer,
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _actionCard(
                        icon: Icons.mic_rounded,
                        label: tr('action_voice_entry'),
                        bgColor: isDark ? const Color(0xFF3B2E16) : const Color(0xFFFEF3C7),
                        iconColor: C.goldDark,
                        onTap: () => Shell.of(context)?.setTab(2),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _actionCard(
                        icon: Icons.camera_alt_rounded,
                        label: tr('action_bill_scan'),
                        bgColor: isDark ? const Color(0xFF162947) : const Color(0xFFE0F2FE),
                        iconColor: const Color(0xFF0284C7),
                        onTap: () => Shell.of(context)?.setTab(3),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      _actionCard(
                        icon: Icons.qr_code_2_rounded,
                        label: tr('action_my_qr'),
                        bgColor: isDark ? const Color(0xFF2E1C44) : const Color(0xFFF3E8FF),
                        iconColor: const Color(0xFF9333EA),
                        onTap: () => showMeraQrDialog(context),
                        isDark: isDark,
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // ================= AI SMART INSIGHT BANNER =================
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF3B2E16), const Color(0xFF221A0F)]
                            : [const Color(0xFFFEF9C3), const Color(0xFFFFFBEB)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: C.gold.withValues(alpha: isDark ? 0.4 : 0.6),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: C.gold,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: C.gold.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.psychology_rounded, color: C.greenDark, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                tr('smart_alert_title'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF78350F),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                topOwing.isNotEmpty
                                    ? '${topOwing.first['name']} par ${inr(((topOwing.first['balance_paise'] as num?) ?? 0).toInt())} baaki hai. WhatsApp reminder bhejein?'
                                    : tr('smart_alert_msg'),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  color: isDark ? C.darkMuted : const Color(0xFF92400E),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            if (topOwing.isNotEmpty) {
                              showWhatsAppReminderModal(
                                context,
                                name: topOwing.first['name'].toString(),
                                paise: ((topOwing.first['balance_paise'] as num?) ?? 0).toInt(),
                                phone: topOwing.first['phone']?.toString(),
                              );
                            } else {
                              Shell.of(context)?.setTab(2);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: C.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            minimumSize: const Size(0, 36),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: Text(
                            tr('remind_btn'),
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w700),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // ================= TOP DUES CAROUSEL =================
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tr('top_dues_title'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? C.darkMuted : C.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      TextButton(
                        onPressed: () => Shell.of(context)?.setTab(1),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Row(
                          children: [
                            Text(
                              tr('view_all'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: isDark ? C.gold : C.green,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(Icons.arrow_forward_rounded, size: 14, color: isDark ? C.gold : C.green),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (topOwing.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? C.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tr('no_dues'),
                        style: GoogleFonts.plusJakartaSans(color: C.jama, fontWeight: FontWeight.w700),
                      ),
                    )
                  else
                    SizedBox(
                      height: 125,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: topOwing.take(5).length,
                        itemBuilder: (context, idx) {
                          final c = topOwing[idx];
                          final name = c['name'] ?? '?';
                          final paise = ((c['balance_paise'] as num?) ?? 0).toInt();
                          final letter = name.toString().isNotEmpty ? name.toString()[0].toUpperCase() : '?';

                          return Container(
                            width: 170,
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? C.darkCard : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isDark ? C.darkBorder : const Color(0xFFE8EDE9),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.03),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    CircleAvatar(
                                      radius: 16,
                                      backgroundColor: C.redBg,
                                      child: Text(
                                        letter,
                                        style: GoogleFonts.plusJakartaSans(
                                          color: C.red,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () => showWhatsAppReminderModal(
                                        context,
                                        name: name.toString(),
                                        paise: paise,
                                        phone: c['phone']?.toString(),
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE8F5E9),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.mark_chat_unread_rounded, size: 12, color: Color(0xFF2E7D32)),
                                            const SizedBox(width: 3),
                                            Text(
                                              'Taqaza',
                                              style: GoogleFonts.plusJakartaSans(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w800,
                                                color: const Color(0xFF2E7D32),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.toString(),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: isDark ? C.darkInk : C.ink,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      inr(paise),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        color: C.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  const SizedBox(height: 20),

                  // ================= HAAL HI KI ENTRIES / ACTIVITY =================
                  Builder(builder: (context) {
                  final recentList = (_sum['recent_activity'] is List)
                      ? (_sum['recent_activity'] as List)
                      : [];
                  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        recentList.isNotEmpty ? 'HAAL HI KI ACTIVITY' : tr('customer_khata_title'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: isDark ? C.darkMuted : C.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E3A2F) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          tr('live_sync'),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: C.jama,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  if (recentList.isNotEmpty)
                    ...recentList.take(4).map((act) {
                      final isJama = act['type'] == 'jama';
                      final isUdhaar = act['type'] == 'udhaar';
                      final col = isJama ? C.jama : (isUdhaar ? C.red : C.goldDark);
                      final amt = act['amount'] is num ? (act['amount'] as num).toInt() : 0;
                      final amtPaise = act['amount_paise'] is num
                          ? (act['amount_paise'] as num).toInt()
                          : (amt * 100);
                      final name = act['name']?.toString() ?? 'Entry';
                      final time = act['time']?.toString() ?? 'Abhi';
                      final typeLabel = isJama ? 'Jama' : (isUdhaar ? 'Udhaar' : 'Cash');

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isDark ? C.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark ? C.darkBorder : const Color(0xFFE8EDE9),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: col.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Icon(
                                isJama
                                    ? Icons.arrow_downward_rounded
                                    : (isUdhaar
                                        ? Icons.arrow_upward_rounded
                                        : Icons.payments_rounded),
                                color: col,
                                size: 18,
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
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: isDark ? C.darkInk : C.ink,
                                    ),
                                  ),
                                  Text(
                                    '$typeLabel • $time',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 11,
                                      color: isDark ? C.darkMuted : C.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isUdhaar ? '+' : '-'}${inr(amtPaise)}',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w900,
                                fontSize: 14,
                                color: col,
                              ),
                            ),
                          ],
                        ),
                      );
                    })
                  else if (_cust.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? C.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        tr('no_customers_found'),
                        style: GoogleFonts.plusJakartaSans(color: C.muted),
                      ),
                    )
                  else
                    ..._cust.take(4).map((c) => CustRow(
                          c: c,
                          onTap: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => LedgerPage(
                                  customerId: (c['id'] as num).toInt(),
                                  name: c['name'].toString(),
                                  phone: c['phone']?.toString(),
                                ),
                              ),
                            );
                            _load();
                          },
                        )),
                  ]); // end Builder Column children
                  }), // end Builder
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard({
    required IconData icon,
    required String label,
    required Color bgColor,
    required Color iconColor,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? C.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isDark ? C.darkBorder : const Color(0xFFE5ECE8),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? C.darkInk : C.ink,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}