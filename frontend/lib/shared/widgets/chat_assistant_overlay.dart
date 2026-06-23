import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class ChatMessage {
  ChatMessage({
    required this.text,
    required this.isUser,
    this.isStreaming = false,
  });

  final String text;
  final bool isUser;
  final bool isStreaming;
}

/// Botón flotante con panel de chat que mantiene la conversación al abrir/cerrar.
class ChatAssistantOverlay extends StatefulWidget {
  const ChatAssistantOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<ChatAssistantOverlay> createState() => _ChatAssistantOverlayState();
}

class _ChatAssistantOverlayState extends State<ChatAssistantOverlay> {
  final _authService = AuthService();
  final _chatService = ChatService();
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
          'Hola, soy el asistente de CleanPool. Puedo ayudarte a encontrar '
          'funciones de la app. ¿En qué te ayudo?',
      isUser: false,
    ),
  ];

  bool _isOpen = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final question = _inputController.text.trim();
    if (question.isEmpty || _isLoading) return;

    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      _showSnack('Debes iniciar sesión para usar el asistente.');
      return;
    }

    setState(() {
      _messages.add(ChatMessage(text: question, isUser: true));
      _messages.add(ChatMessage(text: '', isUser: false, isStreaming: true));
      _isLoading = true;
      _inputController.clear();
    });
    _scrollToBottom();

    final assistantIndex = _messages.length - 1;
    var buffer = '';

    final result = await _chatService.askStreaming(
      message: question,
      token: token,
      onChunk: (chunk) {
        buffer += chunk;
        if (!mounted) return;
        setState(() {
          _messages[assistantIndex] = ChatMessage(
            text: buffer,
            isUser: false,
            isStreaming: true,
          );
        });
        _scrollToBottom();
      },
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (!result.success) {
        _messages[assistantIndex] = ChatMessage(
          text: result.errorMessage ?? 'No se pudo obtener respuesta.',
          isUser: false,
        );
      } else if (buffer.isEmpty) {
        _messages[assistantIndex] = ChatMessage(
          text: 'No recibí respuesta del asistente.',
          isUser: false,
        );
      } else {
        _messages[assistantIndex] = ChatMessage(
          text: buffer,
          isUser: false,
        );
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _togglePanel() {
    setState(() => _isOpen = !_isOpen);
    if (_isOpen) _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_isOpen) _buildBackdrop(),
        if (_isOpen) _buildPanel(context),
        _buildFab(),
      ],
    );
  }

  Widget _buildBackdrop() {
    return Positioned.fill(
      child: GestureDetector(
        onTap: _togglePanel,
        child: Container(color: Colors.black.withValues(alpha: 0.35)),
      ),
    );
  }

  Widget _buildFab() {
    return Positioned(
      right: 16,
      bottom: 88,
      child: FloatingActionButton(
        onPressed: _togglePanel,
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textPrimary,
        elevation: 4,
        child: Icon(_isOpen ? Icons.close_rounded : Icons.chat_bubble_outline_rounded),
      ),
    );
  }

  Widget _buildPanel(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final panelWidth = width > 520 ? 380.0 : width - 32;

    return Positioned(
      right: 16,
      bottom: 152,
      child: Material(
        elevation: 12,
        borderRadius: BorderRadius.circular(16),
        color: AppColors.surfaceElevated,
        child: Container(
          width: panelWidth,
          height: 420,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _buildHeader(),
              const Divider(height: 1, color: AppColors.border),
              Expanded(child: _buildMessages()),
              const Divider(height: 1, color: AppColors.border),
              _buildInput(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.support_agent_rounded, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Asistente CleanPool',
                  style: GoogleFonts.syne(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Ayuda para usar la app',
                  style: GoogleFonts.interTight(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _togglePanel,
            icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        return _MessageBubble(message: msg);
      },
    );
  }

  Widget _buildInput() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !_isLoading,
              maxLength: 500,
              style: GoogleFonts.interTight(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                counterText: '',
                hintText: 'Pregunta sobre la app...',
                hintStyle: GoogleFonts.interTight(color: AppColors.textMuted, fontSize: 14),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.primary),
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: _isLoading ? null : _sendMessage,
            style: IconButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textPrimary,
              disabledBackgroundColor: AppColors.border,
            ),
            icon: _isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimary),
                  )
                : const Icon(Icons.send_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final alignment = isUser ? Alignment.centerRight : Alignment.centerLeft;
    final bg = isUser ? AppColors.primary.withValues(alpha: 0.22) : AppColors.surface;
    final borderColor = isUser ? AppColors.primary.withValues(alpha: 0.35) : AppColors.border;

    return Align(
      alignment: alignment,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Flexible(
              child: Text(
                message.text.isEmpty && message.isStreaming ? '...' : message.text,
                style: GoogleFonts.interTight(
                  color: AppColors.textPrimary,
                  fontSize: 13.5,
                  height: 1.35,
                ),
              ),
            ),
            if (message.isStreaming && message.text.isNotEmpty)
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 2),
                child: SizedBox(
                  width: 6,
                  height: 6,
                  child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
