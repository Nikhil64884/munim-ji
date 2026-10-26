import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import 'ledger_page.dart';
import 'ui_kit.dart';

class KhataPage extends StatefulWidget {
  const KhataPage({super.key});
  @override
  State<KhataPage> createState() => _KhataPageState();
}

class _KhataPageState extends State<KhataPage> {
  List _all = [];
  bool _loading = true;
  String? _err;
  String _q = '';
  String _filter = 'all'; // all, due, advance, zero
  final String _sort = 'Highest Due'; // Highest Due, Name A-Z

  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    dataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    dataVersion.removeListener(_load);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _err = null;
    });
    final r = await ApiService.getCustomers();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (r['success'] == true && r['data'] is Map) {
        _all = ((r['data'] as Map)['customers'] as List?) ?? [];
      } else {
        _err = r['error']?.toString();
      }
    });
  }

  int _bal(dynamic c) => ((c['balance_paise'] as num?) ?? 0).toInt();

  List get _filteredCustomers {
    var l = _all.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final phone = (c['phone'] ?? '').toString().toLowerCase();
      final query = _q.toLowerCase();
      return name.contains(query) || phone.contains(query);
    }).toList();

    if (_filter == 'due') {
      l = l.where((c) => _bal(c) > 0).toList();
    } else if (_filter == 'advance') {
      l = l.where((c) => _bal(c) < 0).toList();
    } else if (_filter == 'zero') {
      l = l.where((c) => _bal(c) == 0).toList();
    }

    if (_sort == 'Name A-Z') {
      l.sort((a, b) => a['name'].toString().toLowerCase().compareTo(b['name'].toString().toLowerCase()));
    } else if (_filter == 'advance') {
      l.sort((a, b) => _bal(a).compareTo(_bal(b)));
    } else {
      l.sort((a, b) => _bal(b).compareTo(_bal(a)));
    }
    return l;
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
        final found = _all.firstWhere(
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

  Future<void> _merge() async {
    if (_all.length < 2) {
      toast(context, 'Merge ke liye kam se kam 2 customers chahiye');
      return;
    }
    int? from;
    int? into;
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(
            'Do Naam Ek Sath Merge Karein',
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800),
          ),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Ye naam hatao (entries aage chali jayengi)'),
              items: [for (final c in _all) DropdownMenuItem(value: (c['id'] as num).toInt(), child: Text(c['name'].toString()))],
              onChanged: (v) => setD(() => from = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Is naam me jodo'),
              items: [for (final c in _all) DropdownMenuItem(value: (c['id'] as num).toInt(), child: Text(c['name'].toString()))],
              onChanged: (v) => setD(() => into = v),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: (from != null && into != null && from != into) ? () => Navigator.pop(ctx, true) : null,
              child: const Text('Merge karein', style: TextStyle(color: C.green, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
    if (go != true || from == null || into == null) return;
    final r = await ApiService.mergeCustomers(from!, into!);
    if (!mounted) return;
    toast(context, r['success'] == true ? 'Safalta se merge ho gaya! âœ…' : r['error'].toString(), error: r['success'] != true);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = _filteredCustomers;

    return Scaffold(
      backgroundColor: isDark ? C.darkBg : C.bg,
      body: Column(
        children: [
          // Top Header Bar
          const MunimHeader(),

          // Main Khata Directory
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              color: C.green,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                children: [
                  if (_loading)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: C.green,
                        backgroundColor: Color(0xFFE2E8E5),
                      ),
                    ),
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

                  // Khata Title & Actions Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tr('customer_directory'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: isDark ? C.darkInk : C.ink,
                            ),
                          ),
                          Text(
                            '${_all.length} ${tr('customers_connected')}',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? C.darkMuted : C.muted,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _addCustomer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: C.green,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(
                          tr('new_customer'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Search Box
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? C.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? C.darkBorder : const Color(0xFFE2E8E5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _q = v),
                      style: GoogleFonts.plusJakartaSans(
                        color: isDark ? C.darkInk : C.ink,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        hintText: tr('search_placeholder'),
                        hintStyle: GoogleFonts.plusJakartaSans(
                          color: isDark ? C.darkMuted : const Color(0xFFA0ACA5),
                          fontSize: 12.5,
                        ),
                        prefixIcon: const Icon(Icons.search_rounded, size: 20, color: C.muted),
                        suffixIcon: _q.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded, size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  setState(() => _q = '');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Filter Chips Row
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _filterChip(label: tr('filter_all'), filterKey: 'all', isDark: isDark),
                        const SizedBox(width: 8),
                        _filterChip(label: tr('filter_due'), filterKey: 'due', isDark: isDark),
                        const SizedBox(width: 8),
                        _filterChip(label: tr('filter_advance'), filterKey: 'advance', isDark: isDark),
                        const SizedBox(width: 8),
                        _filterChip(label: tr('filter_settled'), filterKey: 'zero', isDark: isDark),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  if (_loading && _all.isEmpty)
                    Column(
                      children: List.generate(
                        4,
                        (_) => Container(
                          height: 72,
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isDark ? C.darkCard : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                    )
                  else if (list.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(28),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? C.darkCard : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.person_search_rounded, size: 48, color: isDark ? C.darkMuted : C.muted),
                          const SizedBox(height: 12),
                          Text(
                            tr('no_customer_found'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? C.darkInk : C.ink,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr('add_customer_instruction'),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: isDark ? C.darkMuted : C.muted,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  else
                    ...list.map((c) => CustRow(
                          c: c as Map,
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

                  const SizedBox(height: 12),

                  // Duplicate Customer Merge Helper
                  Center(
                    child: TextButton.icon(
                      onPressed: _merge,
                      icon: const Icon(Icons.call_merge_rounded, size: 16, color: C.muted),
                      label: Text(
                        'Do Naam Same Hain? Customers Merge Karein',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: C.muted,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required String filterKey,
    required bool isDark,
  }) {
    final isSelected = _filter == filterKey;
    return GestureDetector(
      onTap: () => setState(() => _filter = filterKey),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? C.green
              : (isDark ? C.darkCard : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? C.green
                : (isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: C.green.withValues(alpha: 0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : (isDark ? C.darkMuted : C.muted),
          ),
        ),
      ),
    );
  }
}
