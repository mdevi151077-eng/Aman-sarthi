import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  static const _historyKey = 'aman_sarthi_chat_history_v1';
  static const _systemPrompt =
      'You are Aman Sarthi, a helpful AI study assistant. Reply simply and clearly.';

  final _picker = ImagePicker();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _aiService = AiService.fromEnvironment();
  final _preferences = SharedPreferencesAsync();
  List<_ChatMessage> _messages = _welcomeMessages();
  final List<_SavedConversation> _history = [];
  String _conversationId = _newConversationId();
  _SelectedImage? _selectedImage;
  bool _loading = false;
  bool _checkingConnection = false;
  bool _historyReady = false;

  static List<_ChatMessage> _welcomeMessages() => [
    _ChatMessage(
      role: 'assistant',
      text: 'Namaste! Apna sawaal likhein, main madad karunga.',
      includeInContext: false,
    ),
  ];

  static String _newConversationId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';

  @override
  void initState() {
    super.initState();
    unawaited(_loadHistory());
  }

  Future<void> _loadHistory() async {
    try {
      final saved = await _preferences.getString(_historyKey);
      if (saved != null) {
        final decoded = jsonDecode(saved);
        if (decoded is! List) {
          throw const FormatException('Conversation history is not a list.');
        }
        final conversations = decoded
            .whereType<Map<String, dynamic>>()
            .map(_SavedConversation.fromJson)
            .toList();
        if (mounted) {
          setState(() {
            _history
              ..clear()
              ..addAll(conversations);
            if (_history.isNotEmpty) {
              _conversationId = _history.first.id;
              _messages = List<_ChatMessage>.of(_history.first.messages);
            }
          });
        }
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Chat history load nahi ho saki: $error');
      }
    } finally {
      if (mounted) setState(() => _historyReady = true);
    }
  }

  Future<void> _persistHistory() async {
    try {
      await _preferences.setString(
        _historyKey,
        jsonEncode(
          _history.map((conversation) => conversation.toJson()).toList(),
        ),
      );
    } catch (error) {
      if (mounted) _showMessage('Chat history save nahi ho saki: $error');
    }
  }

  void _saveCurrentConversation() {
    final userMessages = _messages.where(
      (message) => message.role == 'user' && message.text.trim().isNotEmpty,
    );
    if (userMessages.isEmpty) return;

    final title = userMessages.first.text.trim();
    final storedMessages = _messages
        .where((message) => message.imageBytes == null)
        .map(
          (message) => _ChatMessage(
            role: message.role,
            text: message.text,
            includeInContext: message.includeInContext,
            failed: message.failed,
          ),
        )
        .toList();
    if (storedMessages.length > 50) {
      storedMessages.removeRange(0, storedMessages.length - 50);
    }
    _history.removeWhere((conversation) => conversation.id == _conversationId);
    _history.insert(
      0,
      _SavedConversation(
        id: _conversationId,
        title: title.length > 60 ? '${title.substring(0, 60)}…' : title,
        messages: storedMessages,
        updatedAt: DateTime.now(),
      ),
    );
    if (_history.length > 20) _history.removeRange(20, _history.length);
    unawaited(_persistHistory());
  }

  void _newConversation() {
    if (_loading || !_historyReady) return;
    _saveCurrentConversation();
    setState(() {
      _conversationId = _newConversationId();
      _messages = _welcomeMessages();
      _selectedImage = null;
      _controller.clear();
    });
  }

  Future<void> _openHistory() async {
    if (!_historyReady) return;
    _saveCurrentConversation();
    final selectedId = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: _history.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(28),
                  child: Text('Abhi tak koi saved conversation nahi hai.'),
                )
              : ListView(
                  shrinkWrap: true,
                  children: [
                    for (final conversation in _history)
                      ListTile(
                        leading: const Icon(Icons.chat_bubble_outline_rounded),
                        title: Text(
                          conversation.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        subtitle: Text(_formatDate(conversation.updatedAt)),
                        onTap: () =>
                            Navigator.pop(sheetContext, conversation.id),
                      ),
                    ListTile(
                      leading: const Icon(Icons.delete_outline_rounded),
                      title: const Text('Clear saved chat history'),
                      onTap: () => Navigator.pop(sheetContext, '__clear__'),
                    ),
                  ],
                ),
        ),
      ),
    );
    if (!mounted || selectedId == null) return;
    if (selectedId == '__clear__') {
      _history.clear();
      _conversationId = _newConversationId();
      setState(() => _messages = _welcomeMessages());
      try {
        await _preferences.remove(_historyKey);
      } catch (error) {
        if (mounted) _showMessage('Saved history delete nahi ho saki: $error');
      }
      return;
    }
    _saveCurrentConversation();
    final conversation = _history.cast<_SavedConversation?>().firstWhere(
      (item) => item?.id == selectedId,
      orElse: () => null,
    );
    if (conversation == null) return;
    setState(() {
      _conversationId = conversation.id;
      _messages = List<_ChatMessage>.of(conversation.messages);
      _selectedImage = null;
    });
    _scrollToBottom();
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today · ${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    }
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _pickImage() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
        imageQuality: 85,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _selectedImage = _SelectedImage(image.name, bytes));
    } catch (error) {
      if (!mounted) return;
      _showMessage('Photo select nahi ho saki: $error');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    final image = _selectedImage;
    if ((text.isEmpty && image == null) ||
        _loading ||
        !_historyReady ||
        text.length > 8000) {
      return;
    }

    setState(() {
      _messages.add(
        _ChatMessage(
          role: 'user',
          text: text,
          imageBytes: image?.bytes,
          includeInContext: image == null,
        ),
      );
      _controller.clear();
      _selectedImage = null;
      _loading = image == null;
    });
    _saveCurrentConversation();
    _scrollToBottom();

    if (image != null) {
      setState(() {
        _messages.add(
          _ChatMessage(
            role: 'assistant',
            text:
                'Photo chat mein attach ho gayi hai. Is version mein photo AI '
                'service ko upload nahi hui, isliye use dekha ya solve nahi '
                'kiya gaya. Tasveer ka text yahan likh dein, ya secure '
                'vision-capable backend configure karein.',
            includeInContext: false,
          ),
        );
      });
      _saveCurrentConversation();
      _scrollToBottom();
      return;
    }

    final replyIndex = _messages.length;
    setState(() {
      _messages.add(
        _ChatMessage(role: 'assistant', text: '', includeInContext: false),
      );
    });
    await _requestAssistantReply(replyIndex);
  }

  Future<void> _requestAssistantReply(int replyIndex) async {
    final responseStartedAt = DateTime.now();
    final stopwatch = Stopwatch()..start();
    final reply = StringBuffer();
    Duration? firstTokenTime;
    var lastRenderMilliseconds = 0;

    try {
      final turns = [
        if (_aiService.provider == 'ollama')
          const ChatTurn(role: 'system', content: _systemPrompt),
        ..._messages
            .where((message) => message.includeInContext)
            .map(
              (message) => ChatTurn(role: message.role, content: message.text),
            ),
      ];
      await for (final content in _aiService.streamReply(turns)) {
        if (content.isEmpty) continue;
        firstTokenTime ??= stopwatch.elapsed;
        reply.write(content);
        final elapsedMilliseconds = stopwatch.elapsedMilliseconds;
        if (elapsedMilliseconds - lastRenderMilliseconds >= 50) {
          lastRenderMilliseconds = elapsedMilliseconds;
          _replaceAssistantMessage(
            replyIndex,
            _ChatMessage(
              role: 'assistant',
              text: reply.toString(),
              includeInContext: false,
              firstTokenTime: firstTokenTime,
              createdAt: responseStartedAt,
            ),
            animateScroll: false,
          );
        }
      }

      stopwatch.stop();
      final completeReply = reply.toString();
      _replaceAssistantMessage(
        replyIndex,
        _ChatMessage(
          role: 'assistant',
          text: completeReply.isEmpty
              ? 'AI se khaali reply mila.'
              : completeReply,
          includeInContext: completeReply.isNotEmpty,
          totalTime: stopwatch.elapsed,
          firstTokenTime: firstTokenTime,
          createdAt: responseStartedAt,
        ),
      );
      _saveCurrentConversation();
    } catch (error) {
      stopwatch.stop();
      if (mounted) {
        final errorMessage = error is AiServiceException
            ? error.message
            : 'AI reply could not be completed. Check your connection and '
                  'try again.';
        final partialReply = reply.toString();
        _replaceAssistantMessage(
          replyIndex,
          _ChatMessage(
            role: 'assistant',
            text: partialReply.isEmpty
                ? errorMessage
                : '$partialReply\n\nResponse stream ruk gaya: $errorMessage',
            includeInContext: false,
            totalTime: stopwatch.elapsed,
            firstTokenTime: firstTokenTime,
            failed: true,
            createdAt: responseStartedAt,
          ),
        );
        _saveCurrentConversation();
      }
    } finally {
      if (mounted) setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  Future<void> _retryMessage(int index) async {
    if (_loading || index < 0 || index >= _messages.length) return;
    setState(() {
      _messages[index] = _ChatMessage(
        role: 'assistant',
        text: '',
        includeInContext: false,
      );
      _loading = true;
    });
    await _requestAssistantReply(index);
  }

  Future<void> _copyMessage(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _showMessage('Reply copied.');
  }

  Future<void> _regenerateMessage(int index) async {
    if (_loading ||
        index != _messages.length - 1 ||
        !_messages[index].includeInContext) {
      return;
    }
    setState(() {
      _messages.removeAt(index);
      _messages.add(
        _ChatMessage(role: 'assistant', text: '', includeInContext: false),
      );
      _loading = true;
    });
    await _requestAssistantReply(_messages.length - 1);
  }

  void _replaceAssistantMessage(
    int index,
    _ChatMessage message, {
    bool animateScroll = true,
  }) {
    if (!mounted) return;
    setState(() => _messages[index] = message);
    _scrollToBottom(animate: animateScroll);
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _testConnection() async {
    if (_checkingConnection) return;
    setState(() => _checkingConnection = true);
    try {
      await _aiService.testConnection();
      if (mounted) _showMessage('AI backend is ready.');
    } on AiServiceException catch (error) {
      if (mounted) _showMessage(error.message);
    } finally {
      if (mounted) setState(() => _checkingConnection = false);
    }
  }

  bool _scrollScheduled = false;

  void _scrollToBottom({bool animate = true}) {
    if (_scrollScheduled) return;
    _scrollScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollScheduled = false;
      if (_scrollController.hasClients) {
        final bottom = _scrollController.position.maxScrollExtent;
        if (animate) {
          _scrollController.animateTo(
            bottom,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.jumpTo(bottom);
        }
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _aiService.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6678FF), Color(0xFFAA7BFF)],
              ),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 11),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Aman Sarthi AI',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              Text(
                'Your study companion',
                style: TextStyle(fontSize: 11, color: Color(0xFF9AA7C4)),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: _checkingConnection ? null : _testConnection,
          tooltip: 'Test AI connection',
          icon: _checkingConnection
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.wifi_tethering_rounded),
        ),
        IconButton(
          onPressed: _historyReady ? _openHistory : null,
          tooltip: 'Conversation history',
          icon: const Icon(Icons.history_rounded),
        ),
        IconButton(
          onPressed: _loading || !_historyReady ? null : _newConversation,
          tooltip: 'New conversation',
          icon: const Icon(Icons.add_comment_outlined),
        ),
      ],
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
                itemCount: _messages.length,
                itemBuilder: (context, index) => AnimatedSize(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: _buildMessage(_messages[index], index),
                ),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _loading
                  ? Padding(
                      key: const ValueKey('thinking'),
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Soch raha hoon…',
                                  style: Theme.of(context).textTheme.labelLarge
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('idle')),
            ),
            SafeArea(
              top: false,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: .18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_selectedImage case final image?)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(8, 4, 8, 2),
                        child: _buildImagePreview(image),
                      ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        IconButton(
                          onPressed: _loading || !_historyReady
                              ? null
                              : _pickImage,
                          tooltip: 'Photo attach karein',
                          style: IconButton.styleFrom(
                            foregroundColor: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                        ),
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            enabled: !_loading && _historyReady,
                            minLines: 1,
                            maxLines: 5,
                            maxLength: 8000,
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendMessage(),
                            decoration: const InputDecoration(
                              hintText: 'Apna sawaal likhein…',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                              counterText: '',
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: IconButton.filled(
                            onPressed: _loading || !_historyReady
                                ? null
                                : _sendMessage,
                            tooltip: 'Send',
                            icon: const Icon(Icons.arrow_upward_rounded),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _buildImagePreview(_SelectedImage image) => Align(
    alignment: Alignment.centerLeft,
    child: Container(
      width: 168,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            child: Image.memory(
              image.bytes,
              width: 168,
              height: 110,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => const SizedBox(
                width: 168,
                height: 110,
                child: Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 10),
                  child: Text(
                    image.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _selectedImage = null),
                tooltip: 'Photo hataein',
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _buildMessage(_ChatMessage message, int index) {
    final isUser = message.role == 'user';
    final totalTime = message.totalTime;
    final firstTokenTime = message.firstTokenTime;
    final String? timingLabel;
    if (totalTime == null) {
      timingLabel = null;
    } else {
      final totalLabel =
          '${(totalTime.inMilliseconds / 1000).toStringAsFixed(1)}s total';
      final firstTokenLabel = firstTokenTime == null
          ? null
          : 'first text '
                '${(firstTokenTime.inMilliseconds / 1000).toStringAsFixed(1)}s';
      timingLabel = firstTokenLabel == null
          ? totalLabel
          : '$totalLabel · $firstTokenLabel';
    }
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width < 600
              ? MediaQuery.sizeOf(context).width * .86
              : 680,
        ),
        margin: const EdgeInsets.symmetric(vertical: 7),
        padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
        decoration: BoxDecoration(
          gradient: isUser
              ? const LinearGradient(
                  colors: [Color(0xFF6558DA), Color(0xFF456FE5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: isUser ? null : colors.surfaceContainerHighest,
          border: isUser ? null : Border.all(color: colors.outlineVariant),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 6),
            bottomRight: Radius.circular(isUser ? 6 : 20),
          ),
          boxShadow: isUser
              ? [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: .12),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6678FF), Color(0xFFAA7BFF)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Aman Sarthi',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colors.onSurface,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ] else
                  Text(
                    'You',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: Colors.white.withValues(alpha: .88),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
            if (message.text.isNotEmpty) const SizedBox(height: 8),
            if (message.imageBytes case final bytes?)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.memory(
                    bytes,
                    width: 240,
                    height: 180,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            if (message.text.isNotEmpty)
              if (isUser)
                SelectableText(
                  message.text,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white,
                    height: 1.45,
                  ),
                )
              else
                MarkdownBody(
                  data: message.text,
                  selectable: true,
                  styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                    p: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.onSurface,
                      height: 1.55,
                    ),
                    codeblockDecoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
            if (!isUser && message.text.isNotEmpty)
              Wrap(
                spacing: 2,
                children: [
                  IconButton(
                    onPressed: () => _copyMessage(message.text),
                    tooltip: 'Copy reply',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.copy_rounded, size: 18),
                  ),
                  if (message.failed)
                    IconButton(
                      onPressed: _loading ? null : () => _retryMessage(index),
                      tooltip: 'Retry response',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.refresh_rounded, size: 19),
                    )
                  else if (index == _messages.length - 1 &&
                      message.includeInContext)
                    IconButton(
                      onPressed: _loading
                          ? null
                          : () => _regenerateMessage(index),
                      tooltip: 'Regenerate response',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.autorenew_rounded, size: 19),
                    ),
                ],
              ),
            if (!isUser && timingLabel != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  timingLabel,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                TimeOfDay.fromDateTime(message.createdAt).format(context),
                style: Theme.of(context).textTheme.labelSmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessage {
  _ChatMessage({
    required this.role,
    required this.text,
    this.imageBytes,
    this.includeInContext = true,
    this.totalTime,
    this.firstTokenTime,
    this.failed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    final role = json['role'];
    final text = json['text'];
    if ((role != 'user' && role != 'assistant') || text is! String) {
      throw const FormatException('Saved chat message is invalid.');
    }
    return _ChatMessage(
      role: role as String,
      text: text,
      includeInContext: json['includeInContext'] == true,
      failed: json['failed'] == true,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    );
  }

  final String role;
  final String text;
  final Uint8List? imageBytes;
  final bool includeInContext;
  final Duration? totalTime;
  final Duration? firstTokenTime;
  final bool failed;
  final DateTime createdAt;

  Map<String, Object?> toJson() => {
    'role': role,
    'text': text,
    'includeInContext': includeInContext,
    'failed': failed,
    'createdAt': createdAt.toIso8601String(),
  };
}

class _SelectedImage {
  const _SelectedImage(this.name, this.bytes);

  final String name;
  final Uint8List bytes;
}

class _SavedConversation {
  const _SavedConversation({
    required this.id,
    required this.title,
    required this.messages,
    required this.updatedAt,
  });

  factory _SavedConversation.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final messages = json['messages'];
    final updatedAt = DateTime.tryParse(json['updatedAt'] as String? ?? '');
    if (id is! String ||
        title is! String ||
        messages is! List ||
        updatedAt == null) {
      throw const FormatException('Saved conversation is invalid.');
    }
    return _SavedConversation(
      id: id,
      title: title,
      messages: messages
          .whereType<Map<String, dynamic>>()
          .map(_ChatMessage.fromJson)
          .toList(),
      updatedAt: updatedAt,
    );
  }

  final String id;
  final String title;
  final List<_ChatMessage> messages;
  final DateTime updatedAt;

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'messages': messages.map((message) => message.toJson()).toList(),
    'updatedAt': updatedAt.toIso8601String(),
  };
}
