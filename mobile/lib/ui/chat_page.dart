import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import '../services/api_service.dart';
import 'ui_kit.dart';

class ChatPage extends StatefulWidget {
  const ChatPage({super.key});
  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late final List<Map<String, dynamic>> _msgs;
  bool _busy = false;
  bool _isListening = false;
  late AnimationController _waveAnim;
  AudioRecorder? _audioRecorder;

  List<String> get _quickPrompts => [
    tr('quick_p1'),
    tr('quick_p2'),
    tr('quick_p3'),
    tr('quick_p4'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final name = shopNameNotifier.value.trim();
    final greeting = name.isNotEmpty ? 'Namaste $name! 🙏' : 'Namaste! 🙏';
    _msgs = [
      {
        'text': '$greeting\n${tr('chat_greeting')}',
        'isUser': false,
        'time': 'Abhi',
      }
    ];
    _waveAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _audioRecorder = AudioRecorder();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isListening) {
        _isListening = false;
        _waveAnim.stop();
        _audioRecorder?.stop().then((path) {
          if (path != null && path.isNotEmpty) {
            ApiService.deleteLocalFile(path);
          }
        });
        if (mounted) setState(() {});
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _waveAnim.dispose();
    _audioRecorder?.dispose();
    _input.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendText(String text) async {
    if (text.trim().isEmpty || _busy) return;
    final query = text.trim();
    setState(() {
      _msgs.add({
        'text': query,
        'isUser': true,
        'time': 'Abhi',
      });
      _busy = true;
      _input.clear();
      _isListening = false;
    });
    _waveAnim.stop();
    _scrollToBottom();

    final r = await ApiService.chat(query);
    if (!mounted) return;
    setState(() {
      _busy = false;
      if (r['success'] == true) {
        notifyDataChanged();
        final reply = (r['data'] is Map ? (r['data'] as Map)['reply']?.toString() : null) ?? 'Hisaab darj ho gaya!';
        _msgs.add({
          'text': reply,
          'isUser': false,
          'time': 'Abhi',
        });
      } else {
        _msgs.add({
          'text': 'Khed hai: ${r['error']}',
          'isUser': false,
          'time': 'Abhi',
        });
      }
    });
    _scrollToBottom();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      // User tapped to stop recording
      setState(() => _isListening = false);
      _waveAnim.stop();
      try {
        final path = await _audioRecorder?.stop();
        if (path != null && mounted) {
          toast(context, 'Awaaz process ho rahi hai... ⏳');
          final r = await ApiService.voice(path);
          await ApiService.deleteLocalFile(path);

          if (!mounted) return;
          if (r['success'] == true && r['data'] is Map) {
            notifyDataChanged();
            final data = r['data'] as Map;
            final transcript = data['transcript']?.toString();
            final reply = data['reply']?.toString() ?? 'Hisaab darj ho gaya!';
            setState(() {
              if (transcript != null && transcript.isNotEmpty) {
                _msgs.add({'text': transcript, 'isUser': true, 'time': 'Abhi'});
              }
              _msgs.add({'text': reply, 'isUser': false, 'time': 'Abhi'});
            });
            _scrollToBottom();
          } else {
            toast(context, r['error']?.toString() ?? 'Awaaz samajh nahi aayi', error: true);
          }
        }
      } catch (e) {
        debugPrint('[ChatPage] Audio stop error: $e');
      }
    } else {
      // Start real recording without any hardcoded mock data
      try {
        final hasPerm = await _audioRecorder?.hasPermission() ?? false;
        if (!hasPerm) {
          if (mounted) toast(context, 'Mic permission nahi mili', error: true);
          return;
        }
        final tempDir = await getTemporaryDirectory();
        final filePath = '${tempDir.path}/munim_voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder?.start(const RecordConfig(encoder: AudioEncoder.aacLc), path: filePath);
        if (!mounted) return;
        setState(() => _isListening = true);
        _waveAnim.repeat(reverse: true);
        toast(context, 'Sun raha hoon... Bol kar mic dubara dabayein 🎙️');
      } catch (e) {
        debugPrint('[ChatPage] Audio start error: $e');
        if (mounted) toast(context, 'Mic shuru nahi ho paya', error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? C.darkBg : C.bg,
      body: Column(
        children: [
          // Header Bar
          const MunimHeader(titleOverride: 'Munim AI Voice Assistant'),

          // Animated Listening Status Bar (Only expands when listening)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            height: _isListening ? 46 : 0,
            curve: Curves.easeInOut,
            child: _isListening
                ? Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? [const Color(0xFF2E1A0F), const Color(0xFF1C2B22)]
                            : [const Color(0xFFFEF3C7), const Color(0xFFD1FAE5)],
                      ),
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? C.darkBorder : const Color(0xFFE2E8E5),
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.graphic_eq_rounded, color: C.goldDark, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Sun raha hoon... Bol kar neeche mic dabayein',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                              color: isDark ? Colors.white : C.ink,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _waveAnim,
                          builder: (context, _) => Row(
                            children: List.generate(
                              5,
                              (i) => Container(
                                width: 3,
                                height: 8 + (16 * ((_waveAnim.value + (i * 0.2)) % 1)),
                                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                                decoration: BoxDecoration(
                                  color: C.goldDark,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Messages List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              itemCount: _msgs.length + (_busy ? 1 : 0),
              itemBuilder: (context, i) {
                if (i == _msgs.length && _busy) {
                  return _typingBubble(isDark);
                }
                final m = _msgs[i];
                final isUser = m['isUser'] == true;
                final text = m['text'].toString();
                // Only show action buttons on the latest bot message so past contexts aren't accidentally triggered
                final bool isLastBotMsg = !isUser && (i == _msgs.length - 1);
                final actions = (isUser || !isLastBotMsg) ? <MapEntry<String, String>>[] : replyActions(text);

                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUser
                          ? C.green
                          : (isDark ? C.darkCard : Colors.white),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(20),
                        topRight: const Radius.circular(20),
                        bottomLeft: Radius.circular(isUser ? 20 : 4),
                        bottomRight: Radius.circular(isUser ? 4 : 20),
                      ),
                      border: isUser
                          ? null
                          : Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment:
                          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      children: [
                        Text(
                          text,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: isUser ? Colors.white : (isDark ? C.darkInk : C.ink),
                            height: 1.35,
                          ),
                        ),
                        if (actions.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: actions.map((act) {
                              return ElevatedButton(
                                onPressed: () => _sendText(act.value),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: act.value == 'HAAN' ? C.jama : C.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  minimumSize: const Size(0, 32),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  act.key,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Quick Suggestion Chips (fill text field instead of immediate auto-send)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: Row(
              children: _quickPrompts.map((p) {
                return GestureDetector(
                  onTap: () {
                    _input.text = p;
                    _input.selection = TextSelection.fromPosition(TextPosition(offset: p.length));
                  },
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? C.darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? C.darkBorder : const Color(0xFFE0E5E2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.bolt_rounded, size: 14, color: C.gold),
                        const SizedBox(width: 4),
                        Text(
                          p,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isDark ? C.darkInk : C.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 6),

          // Bottom Input Bar with Corner Premium Mic
          Container(
            padding: EdgeInsets.fromLTRB(
              14,
              8,
              14,
              MediaQuery.of(context).viewInsets.bottom > 0 ? 8.0 : 88.0,
            ),
            decoration: BoxDecoration(
              color: isDark ? C.darkCard : Colors.white,
              border: Border(
                top: BorderSide(
                  color: isDark ? C.darkBorder : const Color(0xFFE2E8E5),
                ),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Text input container
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? C.darkBg : const Color(0xFFF3F6F4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: isDark ? C.darkBorder : const Color(0xFFE0E6E2),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            onSubmitted: _sendText,
                            style: GoogleFonts.plusJakartaSans(
                              color: isDark ? C.darkInk : C.ink,
                              fontSize: 13,
                            ),
                            decoration: InputDecoration(
                              hintText: tr('chat_placeholder'),
                              hintStyle: GoogleFonts.plusJakartaSans(
                                color: isDark ? C.darkMuted : const Color(0xFFA0ACA5),
                                fontSize: 12.5,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                        // Quick Send Arrow when text is present
                        ValueListenableBuilder<TextEditingValue>(
                          valueListenable: _input,
                          builder: (context, val, _) {
                            if (val.text.trim().isEmpty) return const SizedBox.shrink();
                            return GestureDetector(
                              onTap: () => _sendText(_input.text),
                              child: Container(
                                margin: const EdgeInsets.only(right: 6),
                                width: 34,
                                height: 34,
                                decoration: const BoxDecoration(
                                  color: C.green,
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 18),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // ================= CORNER PREMIUM AI MIC BUTTON =================
                GestureDetector(
                  onTap: _toggleListening,
                  child: AnimatedBuilder(
                    animation: _waveAnim,
                    builder: (context, _) {
                      final pulseScale = _isListening ? (1.0 + (_waveAnim.value * 0.08)) : 1.0;
                      return Transform.scale(
                        scale: pulseScale,
                        child: Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: _isListening
                                  ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                  : [const Color(0xFFF59E0B), const Color(0xFFD97706)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _isListening ? Colors.white : const Color(0xFFFFE082),
                              width: 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening ? const Color(0xFFEF4444) : const Color(0xFFF59E0B))
                                    .withValues(alpha: _isListening ? 0.65 : 0.45),
                                blurRadius: _isListening ? 18 : 12,
                                spreadRadius: _isListening ? 3 : 1,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                _isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                                color: Colors.white,
                                size: 26,
                              ),
                              // Tiny "AI" badge on mic corner
                              Positioned(
                                top: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: _isListening ? Colors.black87 : const Color(0xFF1B4332),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(
                                      color: const Color(0xFFFFD54F),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: const Text(
                                    'AI',
                                    style: TextStyle(
                                      color: Color(0xFFFFD54F),
                                      fontSize: 7.5,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _typingBubble(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? C.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? C.darkBorder : const Color(0xFFE2E8E5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Munim Ji hisaab jod rahe hain',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? C.darkMuted : C.muted,
              ),
            ),
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: C.green),
            ),
          ],
        ),
      ),
    );
  }
}