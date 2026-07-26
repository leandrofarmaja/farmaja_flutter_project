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
      'text': 'Olá! Sou o Assistente Farmacêutico FarmaJá Angola 🇦🇴. Como posso ajudar com os seus medicamentos, dosagens ou genéricos hoje?',
    }
  ];
  bool _loading = false;

  void _sendQuery(String queryText) async {
    if (queryText.trim().isEmpty || _loading) return;

    setState(() {
      _messages.add({'sender': 'user', 'text': queryText});
      _loading = true;
    });
    _controller.clear();

    await Future.delayed(const Duration(milliseconds: 1000));

    setState(() {
      _loading = false;
      _messages.add({
        'sender': 'ai',
        'text': 'O Coartem é o antimalárico de primeira escolha em Angola para malária por Plasmodium falciparum. Deve ser tomado com alimentos gordurosos (ex: leite) para melhor absorção.',
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Container(
        height: 550,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FarmaJá AI Assistant',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Orientação Médica & Farmacêutica em Angola',
                        style: TextStyle(color: Colors.grey, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isUser = msg['sender'] == 'user';

                  return Align(
                    alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primary : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        msg['text']!,
                        style: TextStyle(
                          color: isUser ? Colors.white : Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            if (_loading)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    SizedBox(width: 8),
                    Text('A analisar pergunta...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Pergunte sobre medicamentos...',
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onSubmitted: _sendQuery,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.send),
                  onPressed: () => _sendQuery(_controller.text),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
