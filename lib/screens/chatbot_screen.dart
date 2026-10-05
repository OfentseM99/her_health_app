import 'package:flutter/material.dart';

class ChatbotScreen extends StatefulWidget {
  final String journey;

  const ChatbotScreen({
    super.key,
    required this.journey,
  });

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController messageController = TextEditingController();

  late List<Map<String, String>> messages;

  @override
  void initState() {
    super.initState();

    messages = [
      {
        "sender": "ai",
        "message": "Hi 🌸 I am Her Health Assistant.\n\n"
            "I see that your current healthcare journey is "
            "${widget.journey}.\n\n"
            "I am here to support you with health information "
            "and guidance. How can I help you today?"
      }
    ];
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty) {
      return;
    }

    final String userMessage = messageController.text.trim();

    setState(() {
      messages.add({
        "sender": "user",
        "message": userMessage,
      });

      messages.add({
        "sender": "ai",
        "message": "Thank you for sharing that with me 🌿.\n\n"
            "I understand that you are using Her Health for "
            "${widget.journey}.\n\n"
            "I will guide you with health information and "
            "support based on the information you provide."
      });
    });

    messageController.clear();
  }

  @override
  void dispose() {
    messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE89CB0),
        title: const Text(
          "Her Health AI 🌸",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.white,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Image.asset(
              'assets/images/logo/logo.png',
              height: 35,
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),

          // Background overlay
          Container(
            color: Colors.white.withValues(alpha: 0.30),
          ),

          Column(
            children: [
              // Chat messages
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(15),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final bool isUser = messages[index]["sender"] == "user";

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          vertical: 8,
                        ),
                        padding: const EdgeInsets.all(15),
                        constraints: const BoxConstraints(
                          maxWidth: 300,
                        ),
                        decoration: BoxDecoration(
                          color: isUser
                              ? const Color(0xFFE89CB0)
                              : const Color(0xFF959B7D),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          messages[index]["message"]!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Message input
              Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.only(
                    left: 20,
                    right: 20,
                    bottom: 25,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(
                      alpha: 0.92,
                    ),
                    borderRadius: BorderRadius.circular(35),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF959B7D),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          decoration: const InputDecoration(
                            hintText: "Ask Her Health anything 🌸",
                            border: InputBorder.none,
                          ),
                          onSubmitted: (_) {
                            sendMessage();
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: sendMessage,
                        child: Container(
                          height: 45,
                          width: 45,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE89CB0),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Drawer buildDrawer() {
    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: Color(0xFFE89CB0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo/logo.png',
                  height: 70,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Her Health",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          drawerItem(
            Icons.chat,
            "AI Assistant",
          ),
          drawerItem(
            Icons.calendar_month,
            "Appointments",
          ),
          drawerItem(
            Icons.medical_services,
            "Contact Doctor",
          ),
          drawerItem(
            Icons.favorite,
            "Health Profile",
          ),
          drawerItem(
            Icons.notifications,
            "Reminders",
          ),
          drawerItem(
            Icons.article,
            "Health Articles",
          ),
          drawerItem(
            Icons.settings,
            "Settings",
          ),
        ],
      ),
    );
  }

  Widget drawerItem(
    IconData icon,
    String title,
  ) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xFF959B7D),
      ),
      title: Text(title),
      onTap: () {},
    );
  }
}
