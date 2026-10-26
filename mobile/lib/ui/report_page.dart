import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'login_page.dart';
import 'ui_kit.dart';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});
  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  List _audit = [];
  Map _sum = {};
  bool _exporting = false;
  bool _driveBackupActive = true;

  @override
  void initState() {
    super.initState();
    dataVersion.addListener(_loadAudit);
    _loadAudit();
  }

  @override
  void dispose() {
    dataVersion.removeListener(_loadAudit);
    super.dispose();
  }

  bool _backendOnline = false;

  Future<void> _loadAudit() async {
    final health = await ApiService.checkHealth();
    final r = await ApiService.getAudit(limit: 20);
    final s = await ApiService.getSummary('month');
    if (!mounted) return;
    setState(() {
      _backendOnline = health;
      if (r['success'] == true && r['data'] is Map) {
        _audit = ((r['data'] as Map)['entries'] as List?) ?? [];
      }
      if (s['success'] == true && s['data'] is Map) {
        _sum = s['data'] as Map;
      }
    });
  }

  Future<void> _editServerUrl() async {
    final ctrl = TextEditingController(text: ApiService.baseUrl);
    bool testing = false;
    String? testResult;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (sheetCtx, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.dns_rounded, color: C.green),
                const SizedBox(width: 8),
                Text(tr('backend_server_ip'), style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'FastAPI server ka URL daalein:\n(Jaise http://192.168.0.104:8000 ya http://127.0.0.1:8000)',
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: C.muted),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: ctrl,
                  decoration: InputDecoration(
                    hintText: 'http://192.168.0.104:8000',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                if (testResult != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    testResult!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: testResult!.contains('safal') ? C.green : C.red,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: C.green, foregroundColor: Colors.white),
                onPressed: testing
                    ? null
                    : () async {
                        final url = ApiService.normalizeUrl(ctrl.text);
                        if (url.isEmpty) {
                          setDialogState(() {
                            testResult = 'URL khaali hai';
                          });
                          return;
                        }
                        setDialogState(() {
                          testing = true;
                          testResult = 'Server se connect ho raha hai...';
                        });
                        final ok = await ApiService.checkHealthAt(url);
                        if (ok) {
                          ApiService.setBaseUrl(url);
                          await StorageService.saveServerUrl(url);
                          if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                          if (!mounted) return;
                          setState(() => _backendOnline = true);
                          dataVersion.value++;
                          toast(context, 'Server se safal jod liya! 🟢');
                        } else {
                          setDialogState(() {
                            testing = false;
                            testResult = 'Connect nahi ho paya. IP aur Port check karein.';
                          });
                        }
                      },
                child: testing
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Connect & Save'),
              ),
            ],
          ),
        ),
      );
    } finally {
      ctrl.dispose();
    }
  }

  Future<void> _export() async {
    setState(() => _exporting = true);
    final r = await ApiService.exportExcel();
    if (!mounted) return;
    setState(() => _exporting = false);
    if (r['success'] == true) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Excel Ban Gayi!', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          content: Text('File save ho gayi:\n${r['path'] ?? 'Download complete'}'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Theek Hai', style: TextStyle(color: C.green, fontWeight: FontWeight.bold)),
            )
          ],
        ),
      );
    } else {
      toast(context, r['error'].toString(), error: true);
    }
  }

  void _exportPdf() {
    toast(context, 'PDF export jald aayega! Kripya Excel Export use karein 📄');
  }

  void _toLogin() => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()), (_) => false);

  Future<void> _logout() async {
    shopNameNotifier.value = '';
    upiIdNotifier.value = '';
    await ApiService.logout();
    if (mounted) _toLogin();
  }

  Future<void> _deleteAccount() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Account Delete Karein?', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
        content: const Text('Aapka poora hisaab 30 din tak rehta hai, phir hamesha ke liye hat jata hai.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Nahi')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Haan, Delete Karo', style: TextStyle(color: C.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final r = await ApiService.deleteAccount();
    if (!mounted) return;
    if (r['success'] == true) {
      shopNameNotifier.value = '';
      upiIdNotifier.value = '';
      _toLogin();
    } else {
      toast(context, r['error'].toString(), error: true);
    }
  }

  String _actionLabel(String a) => a == 'update' ? 'Entry badli' : (a == 'delete' ? 'Entry hatayi' : a);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? C.darkBg : C.bg,
      body: Column(
        children: [
          // Header Bar
          const MunimHeader(titleOverride: 'Reports & Settings'),

          // Main Scrollable Area
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
              children: [
                // Store Info & PRO Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ValueListenableBuilder<String>(
                          valueListenable: shopNameNotifier,
                          builder: (context, name, _) {
                            final trimmed = name.trim();
                            return Text(
                              trimmed.isEmpty ? 'Dukan Ka Naam Set Karein' : trimmed,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? C.darkInk : C.ink,
                                fontStyle: trimmed.isEmpty ? FontStyle.italic : FontStyle.normal,
                              ),
                            );
                          },
                        ),
                        Text(
                          _sum['customerCount'] != null
                              ? '${_sum['customerCount']} Grahak judey hain'
                              : 'Verified Khata',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            color: isDark ? C.darkMuted : C.muted,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: C.gold.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: C.gold.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        'PRO',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: C.goldDark,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // ================= STATS SUMMARY CARDS =================
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? C.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MONTHLY SALES',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark ? C.darkMuted : C.muted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _sum['cash_sale_paise'] != null
                                  ? inr((_sum['cash_sale_paise'] as num).toInt())
                                  : '₹ 0',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: isDark ? C.darkInk : C.ink,
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
                          color: isDark ? C.darkCard : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'MONTHLY JAMA',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isDark ? C.darkMuted : C.muted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _sum['jama_paise'] != null
                                  ? inr((_sum['jama_paise'] as num).toInt())
                                  : '₹ 0',
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
                  ],
                ),

                const SizedBox(height: 16),

                // ================= EXPORTS SECTION =================
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? C.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tr('download_reports'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: isDark ? C.darkMuted : C.muted,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _exporting ? null : _export,
                              icon: _exporting
                                  ? const SizedBox(
                                      width: 14,
                                      height: 14,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: C.jama),
                                    )
                                  : const Icon(Icons.table_chart_rounded, size: 16),
                              label: Text(
                                _exporting ? 'Saving...' : tr('excel_export'),
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF132B20) : const Color(0xFFE8F5E9),
                                foregroundColor: C.jama,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _exportPdf,
                              icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                              label: Text(
                                tr('pdf_summary'),
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? const Color(0xFF331614) : const Color(0xFFFDECEA),
                                foregroundColor: C.red,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ================= SETTINGS MENU LIST =================
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? C.darkCard : Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                  ),
                  child: Column(
                    children: [
                      // Google Drive Backup
                      ListTile(
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF3F6F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.cloud_upload_rounded, color: C.green, size: 20),
                        ),
                        title: Text(
                          tr('drive_backup'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          tr('drive_backup_sub'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: C.muted),
                        ),
                        trailing: Switch(
                          value: _driveBackupActive,
                          activeTrackColor: C.jama,
                          onChanged: (v) {
                            setState(() => _driveBackupActive = v);
                            toast(context, v ? 'Google Drive backup sakriya ho gaya ✅' : 'Google Drive backup band ho gaya');
                          },
                        ),
                      ),
                      Divider(height: 1, color: isDark ? C.darkBorder : const Color(0xFFF0F4F2)),

                      // Language Switch
                      ListTile(
                        onTap: () {
                          final cur = langNotifier.value;
                          final next = cur == 'Hinglish'
                              ? 'हिंदी'
                              : (cur == 'हिंदी' ? 'English' : 'Hinglish');
                          langNotifier.value = next;
                          StorageService.saveLanguage(next);
                          toast(context, tr('lang_changed_toast') + next);
                        },
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF3F6F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(Icons.translate_rounded, color: C.goldDark, size: 20),
                        ),
                        title: Text(
                          tr('app_language'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        subtitle: ValueListenableBuilder<String>(
                          valueListenable: langNotifier,
                          builder: (context, lang, _) => Text(
                            'Current: $lang',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: C.muted),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, color: C.muted),
                      ),
                      Divider(height: 1, color: isDark ? C.darkBorder : const Color(0xFFF0F4F2)),

                      // Dark Mode Theme
                      ListTile(
                        onTap: () {
                          themeModeNotifier.value =
                              isDark ? ThemeMode.light : ThemeMode.dark;
                        },
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF3F6F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                            color: isDark ? C.gold : C.muted,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          tr('dark_mode_theme'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          'Raat ke hisaab ke liye aaramdayak',
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: C.muted),
                        ),
                        trailing: Text(
                          isDark ? 'ON' : 'OFF',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isDark ? C.gold : C.muted,
                          ),
                        ),
                      ),
                      Divider(height: 1, color: isDark ? C.darkBorder : const Color(0xFFF0F4F2)),

                      // Backend Server Connection
                      ListTile(
                        onTap: _editServerUrl,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white10 : const Color(0xFFF3F6F4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            Icons.dns_rounded,
                            color: _backendOnline ? C.green : C.goldDark,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          'Backend Server URL',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          ApiService.baseUrl,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11, color: C.muted),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _backendOnline
                                ? (isDark ? const Color(0xFF133827) : const Color(0xFFD5F6E2))
                                : (isDark ? const Color(0xFF3B1F1C) : const Color(0xFFFEE2E2)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _backendOnline ? C.green : C.red,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _backendOnline ? 'Online' : 'Offline',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: _backendOnline ? C.green : C.red,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // ================= AUDIT LOG RECORD =================
                Text(
                  'BADLAV KA RECORD (AUDIT LOG)',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? C.darkMuted : C.muted,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 10),

                if (_audit.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isDark ? C.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                    ),
                    child: Text(
                      'Abhi koi badlav nahi hua',
                      style: GoogleFonts.plusJakartaSans(color: C.muted),
                    ),
                  )
                else
                  ..._audit.take(5).map((a) {
                    final isDel = a['action'] == 'delete';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: isDark ? C.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE8EDE9)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: isDel ? C.redBg : C.jamaBg,
                            child: Icon(
                              isDel ? Icons.delete_outline_rounded : Icons.edit_note_rounded,
                              color: isDel ? C.red : C.jama,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _actionLabel(a['action'].toString()),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? C.darkInk : C.ink,
                                  ),
                                ),
                                Text(
                                  '${a['entity']} #${a['entity_id']} • ${fmtDate(a['created_at'])}',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: C.muted),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),

                const SizedBox(height: 18),

                // ================= ACCOUNT ACTIONS =================
                SizedBox(
                  width: double.infinity,
                  child: PBtn(
                    tr('logout'),
                    icon: Icons.logout_rounded,
                    kind: BK.outline,
                    onPressed: _logout,
                  ),
                ),

                const SizedBox(height: 14),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2B1211) : const Color(0xFFFFF5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFFECACA)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Account Delete Karein',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: C.red,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Aapka hisaab 30 din tak rehta hai, phir hamesha ke liye hat jata hai.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: C.muted),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: PBtn(
                          'Account Delete Karein',
                          icon: Icons.delete_forever_rounded,
                          kind: BK.dangerOutline,
                          onPressed: _deleteAccount,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
