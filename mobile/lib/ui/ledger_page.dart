import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'ui_kit.dart';

class LedgerPage extends StatefulWidget {
  final int customerId;
  final String name;
  final String? phone;
  const LedgerPage({super.key, required this.customerId, required this.name, this.phone});
  @override
  State<LedgerPage> createState() => _LedgerPageState();
}

class _LedgerPageState extends State<LedgerPage> {
  bool _loading = true;
  String? _err;
  int _balance = 0;
  List _entries = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    final r = await ApiService.getLedger(widget.customerId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success'] == true && r['data'] is Map) {
        final d = r['data'] as Map;
        _balance = (d['balance_paise'] is num) ? (d['balance_paise'] as num).toInt() : 0;
        _entries = (d['entries'] is List) ? (d['entries'] as List) : [];
      } else {
        _err = r['error']?.toString();
      }
    });
  }

  Future<void> _addViaChat(String word, String title, {bool item = false}) async {
    final a = await askEntry(context, title, showItem: item);
    if (a == null || !mounted) return;
    final it = a['item']!.isEmpty ? '' : ' ${a['item']}';
    await chatDialog(context, '${widget.name} ${a['amt']} $word$it');
    notifyDataChanged();
    if (mounted) _load();
  }

  Future<void> _edit(Map e) async {
    final id = (e['id'] is num) ? (e['id'] as num).toInt() : 0;
    if (id <= 0) {
      toast(context, 'Invalid transaction ID', error: true);
      return;
    }
    final amtPaise = (e['amount_paise'] is num) ? (e['amount_paise'] as num).toInt() : 0;
    final cur = amtPaise / 100;
    final a = await askEntry(context, 'Edit Amount',
        amount: cur == cur.roundToDouble() ? cur.round().toString() : cur.toString());
    if (a == null || !mounted) return;
    final paise = (double.parse(a['amt']!) * 100).round();
    final r = await ApiService.patchTransaction(id, amountPaise: paise);
    if (!mounted) return;
    toast(context, r['success'] == true ? 'Entry updated!' : r['error'].toString(),
        error: r['success'] != true);
    if (r['success'] == true) notifyDataChanged();
    _load();
  }

  Future<void> _delete(Map e) async {
    final id = (e['id'] is num) ? (e['id'] as num).toInt() : 0;
    if (id <= 0) {
      toast(context, 'Invalid transaction ID', error: true);
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Entry?'),
        content: const Text('This entry will be removed from the ledger. It will still be in the audit record.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Yes, Delete', style: TextStyle(color: C.red))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final r = await ApiService.deleteTransaction(id);
    if (!mounted) return;
    toast(context, r['success'] == true ? 'Entry deleted' : r['error'].toString(),
        error: r['success'] != true);
    if (r['success'] == true) notifyDataChanged();
    _load();
  }

  Future<void> _reminder() async {
    if (_balance <= 0) {
      toast(context, 'No pending dues for this customer');
      return;
    }
    showWhatsAppReminderModal(context, name: widget.name, paise: _balance, phone: widget.phone);
  }

  // WhatsApp-style chat bubble entry
  Widget _bubble(Map e) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final t = (e['transaction_type'] ?? '').toString();
    final isDebit = t == 'Debit';   // udhaar given — right side (red)
    final isCredit = t == 'Credit'; // jama received — left side (green)
    
    final Color bubbleColor;
    final Color textColor;
    final Color amountColor;
    final String label;
    final IconData icon;

    if (isDebit) {
      bubbleColor = isDark ? const Color(0xFF3B1B1B) : const Color(0xFFFFF0F0);
      textColor = isDark ? const Color(0xFFFFB4B4) : const Color(0xFF7A0000);
      amountColor = C.red;
      label = 'Udhaar (Credit Given)';
      icon = Icons.arrow_upward_rounded;
    } else if (isCredit) {
      bubbleColor = isDark ? const Color(0xFF143525) : const Color(0xFFEDFBF3);
      textColor = isDark ? const Color(0xFFA7F3D0) : const Color(0xFF004D26);
      amountColor = C.jama;
      label = 'Jama (Received)';
      icon = Icons.arrow_downward_rounded;
    } else {
      bubbleColor = isDark ? const Color(0xFF192942) : const Color(0xFFEFF4FF);
      textColor = isDark ? const Color(0xFFBFDBFE) : const Color(0xFF0D2F6B);
      amountColor = C.blue;
      label = 'Cash Sale';
      icon = Icons.payments_rounded;
    }

    final item = (e['item_desc'] ?? '').toString();
    final paise = (e['amount_paise'] is num)
        ? (e['amount_paise'] as num).toInt()
        : (((e['amount'] as num?) ?? 0) * 100).round();
    final dateStr = fmtDate(e['date']);

    return Align(
      // Debit (udhaar) on right, credit (jama) on left
      alignment: isDebit ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: 10,
          left: isDebit ? 48 : 0,
          right: isDebit ? 0 : 48,
        ),
        child: GestureDetector(
          onLongPress: () async {
            final action = await showModalBottomSheet<String>(
              context: context,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    ListTile(
                      leading: const Icon(Icons.edit_outlined, color: C.green),
                      title: const Text('Edit Amount', style: TextStyle(fontWeight: FontWeight.w600)),
                      onTap: () => Navigator.pop(ctx, 'edit'),
                    ),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: C.red),
                      title: const Text('Delete Entry', style: TextStyle(color: C.red, fontWeight: FontWeight.w600)),
                      onTap: () => Navigator.pop(ctx, 'delete'),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
            if (!mounted) return;
            if (action == 'edit') _edit(e);
            if (action == 'delete') _delete(e);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isDebit ? 18 : 4),
                bottomRight: Radius.circular(isDebit ? 4 : 18),
              ),
              border: Border.all(
                color: amountColor.withValues(alpha: 0.15),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: amountColor.withValues(alpha: 0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: isDebit ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Label row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (!isDebit) ...[
                      Icon(icon, size: 13, color: amountColor),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: textColor.withValues(alpha: 0.6),
                        letterSpacing: 0.3,
                      ),
                    ),
                    if (isDebit) ...[
                      const SizedBox(width: 4),
                      Icon(icon, size: 13, color: amountColor),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                // Amount — big & bold
                Text(
                  inr(paise),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: amountColor,
                    letterSpacing: -0.5,
                  ),
                ),
                if (item.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: textColor.withValues(alpha: 0.75),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 11,
                    color: textColor.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _statusBadgeLabel() {
    if (_entries.isEmpty) return 'New Customer';
    if (_balance == 0) return '✅ Settled';
    if (_balance < 0) return '💰 Advance Paid';

    // FIFO Debit Matching:
    // Sort debits from oldest to newest. Sum all credits.
    // Apply credits to oldest debits first.
    // The oldest debit that still has an unpaid portion determines overdue.
    final debits = <Map<String, dynamic>>[];
    int totalCreditsPaise = 0;

    for (final e in _entries) {
      if (e is! Map) continue;
      final t = (e['transaction_type'] ?? '').toString();
      final paise = (e['amount_paise'] is num)
          ? (e['amount_paise'] as num).toInt()
          : (((e['amount'] as num?) ?? 0) * 100).round();

      if (t == 'Credit') {
        totalCreditsPaise += paise;
      } else if (t == 'Debit') {
        final dateStr = e['date']?.toString().trim() ?? '';
        final hasTz = dateStr.endsWith('Z') || RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(dateStr);
        final d = DateTime.tryParse(hasTz ? dateStr : '${dateStr}Z');
        debits.add({
          'paise': paise,
          'date': d,
        });
      }
    }

    // Sort debits ascending by date
    debits.sort((a, b) {
      final da = a['date'] as DateTime?;
      final db = b['date'] as DateTime?;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

    int remainingCredit = totalCreditsPaise;
    DateTime? oldestUnpaidDate;

    for (final deb in debits) {
      final debAmt = deb['paise'] as int;
      if (remainingCredit >= debAmt) {
        remainingCredit -= debAmt;
      } else {
        // This debit is unpaid (partially or fully)
        oldestUnpaidDate = deb['date'] as DateTime?;
        break;
      }
    }

    if (oldestUnpaidDate != null) {
      final daysOld = DateTime.now().difference(oldestUnpaidDate.toLocal()).inDays;
      if (daysOld > 30) return '⚠️ Overdue (${daysOld}d)';
    }

    return '🔴 Due (Udhaar)';
  }

  Color _statusBadgeColor() {
    final label = _statusBadgeLabel();
    if (label.contains('Settled')) return C.jama;
    if (label.contains('Advance')) return C.blue;
    if (label.contains('Overdue')) return const Color(0xFFD4921E);
    if (label.contains('New')) return C.muted;
    return C.red;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final letter = widget.name.isEmpty ? '?' : widget.name[0].toUpperCase();

    return Scaffold(
      backgroundColor: isDark ? C.darkBg : const Color(0xFFF0F2F0),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ── PREMIUM HEADER ─────────────────────────────────────────
          Container(
            padding: EdgeInsets.fromLTRB(
              16,
              MediaQuery.of(context).padding.top + 12,
              16,
              20,
            ),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF094D36), Color(0xFF0F6B4F), Color(0xFF16805F)],
              ),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 24),
                      tooltip: 'Wapas / Home',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                    ),
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white38, width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: const Color(0xFF133B2B),
                          child: Text(letter,
                              style: const TextStyle(
                                color: Color(0xFFF2B84B),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              )),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.name,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            // Status Badge
                            Container(
                              margin: const EdgeInsets.only(top: 3),
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _statusBadgeColor().withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _statusBadgeColor().withValues(alpha: 0.5),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                _statusBadgeLabel(),
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Direct Home Screen Shortcut (WhatsApp Style)
                    IconButton(
                      tooltip: 'Home Screen Par Jayein',
                      icon: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.popUntil(context, (r) => r.isFirst);
                      },
                    ),
                    // Reminder button in header with contrasting badge
                    Container(
                      margin: const EdgeInsets.only(left: 4),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        tooltip: 'WhatsApp Reminder Bhejein',
                        icon: const Icon(Icons.message_rounded, color: Color(0xFF25D366), size: 18),
                        onPressed: _reminder,
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // ── Balance summary row ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _balance < 0
                                ? 'Advance Paid'
                                : _balance == 0
                                    ? 'Account Settled'
                                    : 'Amount Due (Baaki)',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            inr(_balance.abs()),
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: _balance == 0
                                  ? Colors.white70
                                  : _balance > 0
                                      ? const Color(0xFFFFB3B0)
                                      : const Color(0xFF9BFFC9),
                              letterSpacing: -1,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${_entries.length}',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'Transactions',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── CHAT TIMELINE ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                const Icon(Icons.history_rounded, size: 16, color: C.muted),
                const SizedBox(width: 6),
                const Text(
                  'Transaction History',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: C.muted,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '⬅️ Jama    Udhaar ➡️',
                    style: TextStyle(fontSize: 10, color: C.muted, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_err != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: C.redBg, borderRadius: BorderRadius.circular(12)),
                    child: Text(_err!, style: const TextStyle(color: C.red)),
                  ),
                if (_loading && _entries.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(40),
                      child: CircularProgressIndicator(color: C.green),
                    ),
                  )
                else if (_entries.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: const BoxDecoration(
                              color: Color(0xFFE8F5E9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.receipt_long_outlined, color: C.green, size: 36),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            tr('no_transactions'),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: C.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            tr('add_transaction_hint'),
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: C.muted),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  for (final e in _entries) _bubble(e as Map),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // ── BOTTOM ACTION BAR ──────────────────────────────────────────
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 14)],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Drag indicator
            Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.red,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  label: Text(tr('gave_credit'),
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  onPressed: () => _addViaChat('udhaar', 'Credit Given (Udhaar)', item: true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: C.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 50),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  label: Text(tr('got_payment'),
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  onPressed: () => _addViaChat('jama', 'Payment Received (Jama)'),
                ),
              ),
            ]),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: C.ink,
                  minimumSize: const Size(0, 46),
                  side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.message_rounded, color: Color(0xFF25D366), size: 20),
                label: Text(tr('whatsapp_reminder'),
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                onPressed: _reminder,
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
