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
  // Her Health colours
  static const Color rose = Color(0xFFB04F6C);
  static const Color lightRose = Color(0xFFD9879E);
  static const Color blush = Color(0xFFF6DCE2);
  static const Color sage = Color(0xFF6E7B5F);
  static const Color forestGreen = Color(0xFF2F3A2A);
  static const Color warmText = Color(0xFF5E5652);
  static const Color cardBorder = Color(0xFFEADFDB);

  final TextEditingController messageController = TextEditingController();

  final ScrollController scrollController = ScrollController();

  late List<Map<String, String>> messages;

  @override
  void initState() {
    super.initState();

    messages = [
      {
        'sender': 'ai',
        'message': 'Hello! I am your Her Health Assistant.\n\n'
            'I see that your current healthcare journey is '
            '${widget.journey}.\n\n'
            'I am here to offer health information and guidance. '
            'How can I help you today?',
      },
    ];
  }

  void sendMessage() {
    final userMessage = messageController.text.trim();

    if (userMessage.isEmpty) {
      return;
    }

    setState(() {
      messages.add({
        'sender': 'user',
        'message': userMessage,
      });

      messages.add({
        'sender': 'ai',
        'message': 'Thank you for sharing that with me.\n\n'
            'I understand that you are using Her Health for '
            '${widget.journey}.\n\n'
            'I can offer general health information and support '
            'based on what you share. For personal medical advice, '
            'please consult a qualified healthcare professional.',
      });
    });

    messageController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: buildDrawer(),
      appBar: AppBar(
        backgroundColor: rose,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: const Row(
          children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: Colors.white,
              child: Icon(
                Icons.favorite_border,
                color: rose,
                size: 23,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Her Health AI',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Your wellness companion',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Image.asset(
              'assets/images/logo/logo.png',
              height: 38,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.health_and_safety_outlined,
                  color: Colors.white,
                  size: 30,
                );
              },
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Existing background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/background.jpeg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const ColoredBox(
                  color: Color(0xFFFAF6F3),
                );
              },
            ),
          ),

          // Soft background overlay
          Positioned.fill(
            child: Container(
              color: const Color(0xFFFAF6F3).withValues(alpha: 0.78),
            ),
          ),

          Column(
            children: [
              // Journey information
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: cardBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: blush,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.health_and_safety_outlined,
                        color: rose,
                        size: 25,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Your health journey',
                            style: TextStyle(
                              color: warmText,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.journey,
                            style: const TextStyle(
                              color: forestGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Chat messages
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isUser = message['sender'] == 'user';

                    return Align(
                      alignment:
                          isUser ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.78,
                        ),
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (!isUser) ...[
                              Container(
                                height: 32,
                                width: 32,
                                decoration: BoxDecoration(
                                  color: blush,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.favorite_border,
                                  color: rose,
                                  size: 19,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 13,
                                ),
                                decoration: BoxDecoration(
                                  color: isUser ? rose : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(20),
                                    topRight: const Radius.circular(20),
                                    bottomLeft: Radius.circular(
                                      isUser ? 20 : 5,
                                    ),
                                    bottomRight: Radius.circular(
                                      isUser ? 5 : 20,
                                    ),
                                  ),
                                  border: isUser
                                      ? null
                                      : Border.all(color: cardBorder),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x10000000),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  message['message'] ?? '',
                                  style: TextStyle(
                                    color: isUser ? Colors.white : warmText,
                                    fontSize: 14,
                                    height: 1.5,
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

              // Message input area
              SafeArea(
                top: false,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(14, 8, 14, 12),
                  padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: cardBorder),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x12000000),
                        blurRadius: 14,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline,
                        color: sage,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: messageController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 1,
                          maxLines: 4,
                          decoration: const InputDecoration(
                            hintText: 'Ask a health question...',
                            hintStyle: TextStyle(
                              color: warmText,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (_) => sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: rose,
                        shape: const CircleBorder(),
                        child: IconButton(
                          onPressed: sendMessage,
                          tooltip: 'Send message',
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 21,
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

  // Navigation drawer
  Drawer buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFFFFFCFB),
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 24,
              ),
              decoration: const BoxDecoration(
                color: rose,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Image.asset(
                    'assets/images/logo/logo.png',
                    height: 70,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.health_and_safety_outlined,
                        color: Colors.white,
                        size: 60,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Her Health',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'Your wellness journey',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            drawerItem(
              context,
              Icons.dashboard_outlined,
              'Dashboard',
              routeName: '/dashboard',
            ),
            drawerItem(
              context,
              Icons.chat_bubble_outline,
              'AI Assistant',
              selected: true,
            ),
            drawerItem(
              context,
              Icons.calendar_month_outlined,
              'Period Tracker',
              routeName: '/period-tracker',
            ),
            drawerItem(
              context,
              Icons.calendar_today_outlined,
              'Appointments',
            ),
            drawerItem(
              context,
              Icons.medical_services_outlined,
              'Contact Doctor',
            ),
            drawerItem(
              context,
              Icons.person_outline,
              'Personal Information',
              routeName: '/profile',
            ),
            drawerItem(
              context,
              Icons.notifications_none_outlined,
              'Reminders',
            ),
            drawerItem(
              context,
              Icons.article_outlined,
              'Health Articles',
            ),
            drawerItem(
              context,
              Icons.settings_outlined,
              'Settings',
            ),
            const Spacer(),
            const Divider(color: cardBorder),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Your health matters.',
                style: TextStyle(
                  color: warmText,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget drawerItem(
    BuildContext context,
    IconData icon,
    String title, {
    bool selected = false,
    String? routeName,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 3,
      ),
      child: ListTile(
        selected: selected,
        selectedTileColor: blush,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        leading: Icon(
          icon,
          color: selected ? rose : sage,
        ),
        title: Text(
          title,
          style: TextStyle(
            color: selected ? rose : forestGreen,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        onTap: () {
          // Close the drawer before navigating.
          Navigator.pop(context);

          if (routeName != null) {
            Navigator.pushNamed(context, routeName);
          } else if (!selected) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title will be available soon.'),
              ),
            );
          }
        },
      ),
    );
  }
}
