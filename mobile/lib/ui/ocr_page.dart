import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'ui_kit.dart';

class OcrPage extends StatefulWidget {
  const OcrPage({super.key});
  @override
  State<OcrPage> createState() => _OcrPageState();
}

class _OcrPageState extends State<OcrPage> with SingleTickerProviderStateMixin {
  final List<Map<String, dynamic>> _cash = [];

  bool _isScanning = false;
  Map<String, dynamic>? _extractedBill;
  late AnimationController _laserCtrl;

  @override
  void initState() {
    super.initState();
    _laserCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
  }

  @override
  void dispose() {
    _laserCtrl.dispose();
    super.dispose();
  }

  int get _inTotalPaise => _cash
      .where((e) => e['type'] == 'in')
      .fold(0, (s, e) => s + ((e['amount_paise'] as num?)?.toInt() ?? 0));
  int get _outTotalPaise => _cash
      .where((e) => e['type'] == 'out')
      .fold(0, (s, e) => s + ((e['amount_paise'] as num?)?.toInt() ?? 0));

  void _triggerScan() {
    _laserCtrl.repeat(reverse: true);
    setState(() {
      _isScanning = true;
      _extractedBill = null;
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) {
        _laserCtrl.stop();
        return;
      }
      _laserCtrl.stop();
      setState(() {
        _isScanning = false;
        _extractedBill = null;
      });
      toast(context, 'Bill OCR abhi server se connected nahi hai', error: true);
    });
  }

  void _commitOcrExpense() {
    if (_extractedBill == null) return;
    final amtPaise = (_extractedBill!['amount_paise'] as num?)?.toInt() ?? 0;
    final sup = _extractedBill!['supplier'].toString();

    setState(() {
      _cash.insert(0, {
        'desc': 'Bill: $sup',
        'amount_paise': amtPaise,
        'type': 'out',
        'time': 'Just Now',
      });
      _extractedBill = null;
    });
    toast(context, '${inr(amtPaise)} Cashbook expense me jud gaya! 🧾');
  }

  void _addEntry() {
    showMunimSheet(
      context,
      _AddCashEntrySheet(
        onSave: (desc, amtPaise, type) {
          setState(() {
            _cash.insert(0, {
              'desc': desc,
              'amount_paise': amtPaise,
              'type': type,
              'time': 'Abhi',
            });
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final netCashPaise = _inTotalPaise - _outTotalPaise;

    return Scaffold(
      backgroundColor: isDark ? C.darkBg : C.bg,
      body: Column(
        children: [
          // Header Bar
          const MunimHeader(titleOverride: 'Bill OCR & Daily Cashbook'),

          // Main Scrollable Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                // Preview Mode Banner
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: C.gold.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: C.gold.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF8A6D1F)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Preview Mode: Cashbook & OCR abhi demo par hain. Server sync jald aa raha hai.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF8A6D1F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Daily Cash Register Cards
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF132B20) : const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? const Color(0xFF234C38) : const Color(0xFFA5D6A7),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cash IN (Aaya)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: C.jama,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              inr(_inTotalPaise),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: C.jama,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF331614) : const Color(0xFFFDECEA),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark ? const Color(0xFF552320) : const Color(0xFFEF9A9A),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Cash OUT (Gaya)',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: C.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              inr(_outTotalPaise),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: C.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Net Cash in Hand Strip
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? C.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Net Daily Cash in Hand:',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? C.darkMuted : C.muted,
                        ),
                      ),
                      Text(
                        inr(netCashPaise, preserveSign: true),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: netCashPaise >= 0 ? C.green : C.red,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= BILL OCR SCANNER CARD =================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: isDark ? C.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? C.darkBorder : const Color(0xFFE2E8E5),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      )
                    ],
                  ),
                  child: Column(
                    children: [
                      // Scanner Viewport
                      Container(
                        height: 160,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.white12),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.document_scanner_rounded, size: 44, color: C.gold),
                                const SizedBox(height: 10),
                                Text(
                                  _isScanning ? 'Bill Scan Ho Raha Hai...' : 'Supplier Invoice / Bill Camera',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Photo upload karein ya live camera se lein',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    color: Colors.white60,
                                  ),
                                ),
                              ],
                            ),
                            // Laser scan animation bar
                            if (_isScanning)
                              AnimatedBuilder(
                                animation: _laserCtrl,
                                builder: (context, _) => Positioned(
                                  top: 15 + (_laserCtrl.value * 120),
                                  left: 20,
                                  right: 20,
                                  child: Container(
                                    height: 3,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Colors.transparent, C.gold, Colors.white, C.gold, Colors.transparent],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: C.gold.withValues(alpha: 0.8),
                                          blurRadius: 10,
                                        )
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 14),

                      // Trigger Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isScanning ? null : _triggerScan,
                          icon: _isScanning
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.camera_alt_rounded, size: 18),
                          label: Text(
                            _isScanning ? 'AI Scanning...' : 'Scan Bill With AI',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1D5FD1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ================= EXTRACTED OCR RESULT BOX =================
                if (_extractedBill != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF132B20) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF86EFAC), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.check_circle_rounded, color: C.jama, size: 18),
                                const SizedBox(width: 6),
                                Text(
                                  'Bill Extracted Safalta Se!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w800,
                                    color: C.jama,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: C.jamaBg,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _extractedBill!['accuracy'].toString(),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: C.jama,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Supplier:',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: C.muted),
                            ),
                            Text(
                              _extractedBill!['supplier'].toString(),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : C.ink,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Invoice Amount:',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: C.muted),
                            ),
                            Text(
                              inr((_extractedBill!['amount_paise'] as num?)?.toInt() ?? 0),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: C.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: PBtn(
                            '+ Cashbook Expense Me Jodein',
                            icon: Icons.add_task_rounded,
                            kind: BK.primary,
                            onPressed: _commitOcrExpense,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // ================= DAILY CASHBOOK LOGS =================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'AAJ KI CASH ENTRIES',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: isDark ? C.darkMuted : C.muted,
                        letterSpacing: 0.5,
                      ),
                    ),
                    GestureDetector(
                      onTap: _addEntry,
                      child: Text(
                        '+ Cash Entry',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: C.green,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                if (_cash.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(20),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? C.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                    ),
                    child: Text(
                      'Aaj koi cash entry nahi hui',
                      style: GoogleFonts.plusJakartaSans(color: C.muted),
                    ),
                  )
                else
                  ..._cash.map((e) {
                    final isIn = e['type'] == 'in';
                    final col = isIn ? C.jama : C.red;
                    final amtPaise = (e['amount_paise'] as num?)?.toInt() ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? C.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? C.darkBorder : const Color(0xFFE8EDE9),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: isIn ? C.jamaBg : C.redBg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(
                              isIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
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
                                  e['desc'].toString(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? C.darkInk : C.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  e['time'].toString(),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    color: isDark ? C.darkMuted : C.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${isIn ? '+' : '-'}${inr(amtPaise)}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: col,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCashEntrySheet extends StatefulWidget {
  final Function(String desc, int amountPaise, String type) onSave;

  const _AddCashEntrySheet({required this.onSave});

  @override
  State<_AddCashEntrySheet> createState() => _AddCashEntrySheetState();
}

class _AddCashEntrySheetState extends State<_AddCashEntrySheet> {
  final _descCtrl = TextEditingController();
  final _amtCtrl = TextEditingController();
  String _type = 'in';

  @override
  void dispose() {
    _descCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final raw = _amtCtrl.text.trim().replaceAll(',', '');
    final parsedVal = double.tryParse(raw);
    if (parsedVal == null || parsedVal <= 0) {
      toast(context, 'Kripya sahi amount daalein (jaise: 500 ya 250.50)', error: true);
      return;
    }
    final amtPaise = (parsedVal * 100).round();
    final desc = _descCtrl.text.trim().isEmpty ? 'Cash Entry' : _descCtrl.text.trim();
    widget.onSave(desc, amtPaise, _type);
    Navigator.pop(context);
    toast(context, 'Cash entry darj ho gayi!');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '+ Cash Entry Jodein',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _type = 'in'),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _type == 'in' ? C.jama : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _type == 'in' ? C.jama : C.line),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '+ Cash IN',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: _type == 'in' ? Colors.white : C.muted,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _type = 'out'),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: _type == 'out' ? C.red : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _type == 'out' ? C.red : C.line),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '- Cash OUT',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w800,
                      color: _type == 'out' ? Colors.white : C.muted,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        TextField(
          controller: _amtCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
          decoration: InputDecoration(
            labelText: 'Amount (₹)',
            prefixText: '₹ ',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _descCtrl,
          decoration: InputDecoration(
            labelText: 'Description (Kiski entry hai)',
            hintText: 'Jaise: Doodh ka bill, Counter sale',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: PBtn(
            'Entry Save Karein',
            icon: Icons.check_rounded,
            onPressed: _submit,
          ),
        ),
      ],
    );
  }
}
