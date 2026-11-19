import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class AiAssistantDialog extends StatefulWidget {
  const AiAssistantDialog({super.key});

  @override
  State<AiAssistantDialog> createState() => _AiAssistantDialogState();
}

class _AiAssistantDialogState extends State<AiAssistantDialog> {
  final _controller = TextEditingController();

  final List<Map<String, String>> _messages = [
    {
      'sender': 'ai',
      'text':
          'Olá! Sou o Assistente Farmacêutico FarmaJá Angola 🇦🇴. Como posso ajudar com os seus medicamentos, dosagens ou genéricos hoje?',
    }
  ];

  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sendQuery(String queryText) async {
    if (queryText.trim().isEmpty || _loading) return;

    setState(() {
      _messages.add({
        'sender': 'user',
        'text': queryText,
      });
      _loading = true;
    });

    _controller.clear();

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    setState(() {
      _loading = false;
      _messages.add({
        'sender': 'ai',
        'text':
            'O Coartem é o antimalárico de primeira escolha em Angola para malária por Plasmodium falciparum. Deve ser tomado com alimentos gordurosos (ex: leite) para melhor absorção.',
      });
    });
  }

  Widget _buildMessage(Map<String, String> message) {
    final isUser = message['sender'] == 'user';

    return Align(
      alignment:
          isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 290),
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.primary
              : const Color(0xFFF1F6F2),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(17),
            topRight: const Radius.circular(17),
            bottomLeft: Radius.circular(isUser ? 17 : 5),
            bottomRight: Radius.circular(isUser ? 5 : 17),
          ),
        ),
        child: Text(
          message['text']!,
          style: TextStyle(
            color: isUser
                ? Colors.white
                : const Color(0xFF34483C),
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 12,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
          SizedBox(width: 10),
          Text(
            'A analisar pergunta...',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        height: 550,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 43,
                  height: 43,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FarmaJá AI Assistant',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: Color(0xFF173B57),
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'Orientação Médica e Farmacêutica em Angola',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF3F7F4),
                  ),
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(
              height: 1,
              color: Color(0xFFEDF1EE),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 2,
                  vertical: 5,
                ),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  return _buildMessage(_messages[index]);
                },
              ),
            ),
            if (_loading) _buildLoadingIndicator(),
            const SizedBox(height: 9),
            Container(
              padding: const EdgeInsets.only(
                left: 13,
                right: 5,
                top: 5,
                bottom: 5,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF7FAF8),
                borderRadius: BorderRadius.circular(17),
                border: Border.all(
                  color: const Color(0xFFE4ECE6),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _sendQuery,
                      decoration: const InputDecoration(
                        hintText: 'Pergunte sobre medicamentos...',
                        hintStyle: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  IconButton.filled(
                    tooltip: 'Enviar pergunta',
                    icon: const Icon(
                      Icons.send_rounded,
                      size: 19,
                    ),
                    onPressed: () => _sendQuery(_controller.text),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}O 
