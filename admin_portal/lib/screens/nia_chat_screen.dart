import 'package:flutter/material.dart';

class NiaChatScreen extends StatefulWidget {
  const NiaChatScreen({super.key});

  @override
  State<NiaChatScreen> createState() => _NiaChatScreenState();
}

class _NiaChatScreenState extends State<NiaChatScreen> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];

  final examples = [
    'Show missed appointments.',
    'Summarise today\'s consultations.',
    'Patients due this week.',
    'Generate attendance report.',
  ];

  void _send(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _messages.add({'text': text, 'isUser': true});
      _messageController.clear();
      _messages.add({'text': 'This is a placeholder response — Nia connects to real data once the backend is ready.', 'isUser': false});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Ask Nia'), backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Column(
        children: [
          if (_messages.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Text('Hello Dr. Mbokota.', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('How can I assist you today?'),
                  const SizedBox(height: 24),
                  const Text('Examples', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...examples.map((e) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: GestureDetector(
                          onTap: () => _send(e),
                          child: Text('• $e', style: const TextStyle(color: Colors.pink)),
                        ),
                      )),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg['isUser'] ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: msg['isUser'] ? Colors.teal : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(msg['text'], style: TextStyle(color: msg['isUser'] ? Colors.white : Colors.black87)),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(hintText: 'Ask Nia...', border: OutlineInputBorder()),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.teal),
                    onPressed: () => _send(_messageController.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}