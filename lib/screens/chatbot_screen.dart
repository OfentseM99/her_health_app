import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/design_a.dart';
import 'appointments_screen.dart';
import 'messages_screen.dart';
import 'health_profile_screen.dart';
import 'settings_screen.dart';
import 'reminders_screen.dart';
import 'articles_screen.dart';
import 'health_tracking_screen.dart';
import 'health_history_screen.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  List<Map<String, String>> messages = [];
  List<Map<String, dynamic>> _topics = [];

  Map<String, dynamic>? _selectedTopic;

  bool _isLoadingHistory = true;
  bool _isLoadingTopics = true;
  bool _isSending = false;
  bool _showComposer = false;
  bool _showFollowUpActions = false;

  String? _topicsError;

  @override
  void initState() {
    super.initState();
    _loadHistory();
    _loadTopics();
  }

  @override
  void dispose() {
    messageController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await AuthService.getChatHistory();

      if (!mounted) return;

      setState(() {
        if (history.isNotEmpty) {
          messages = history.map<Map<String, String>>((item) {
            final map = Map<String, dynamic>.from(item as Map);
            return {
              'sender': map['sender']?.toString() ?? 'ai',
              'message': map['message']?.toString() ?? '',
              'created_at': map['created_at']?.toString() ?? '',
            };
          }).toList();
        } else {
          messages = [
            {
              'sender': 'ai',
              'message': "Hello! ðŸŒ¸ I'm Nia, your Her Health assistant.\n\n"
                  "I'm here to help you explore women's health information, "
                  "understand your health journey and find answers to "
                  "common questions.\n\n"
                  "Choose one of the topics below to get started. "
                  "You can also type your own question if you cannot find "
                  "what you're looking for.\n\n"
                  "Please remember that I provide general information "
                  "and cannot diagnose or replace advice from a qualified "
                  "healthcare professional."
            }
          ];
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        messages = [
          {
            'sender': 'ai',
            'message': "Hello! ðŸŒ¸ I'm Nia, your Her Health assistant.\n\n"
                "Choose a topic below to explore women's health information. "
                "You can also type your own question."
          }
        ];
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingHistory = false);
        _scrollToBottom();
      }
    }
  }

  Future<void> _loadTopics() async {
    try {
      final result = await AuthService.getNiaTopics();

      if (!mounted) return;

      final loadedTopics = result.map<Map<String, dynamic>>((item) {
        return Map<String, dynamic>.from(item as Map);
      }).toList();

      setState(() {
        _topics = loadedTopics;
        _topicsError = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _topicsError = 'Unable to load Nia topics. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingTopics = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !scrollController.hasClients) return;

      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _selectTopic(Map<String, dynamic> topic) {
    setState(() {
      _selectedTopic = topic;
      _showComposer = false;
      _showFollowUpActions = false;
      messageController.clear();
    });
    _scrollToBottom();
  }

  void _showAllTopics() {
    setState(() {
      _selectedTopic = null;
      _showComposer = false;
      _showFollowUpActions = false;
      messageController.clear();
    });
    _scrollToBottom();
  }

  void _startOwnQuestion() {
    setState(() {
      _selectedTopic = null;
      _showFollowUpActions = false;
      _showComposer = true;
    });
  }

  Future<void> _sendQuestion(String question) async {
    final text = question.trim();

    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);

    try {
      final saved = await AuthService.sendChatMessage(text);

      if (!mounted) return;

      setState(() {
        _showFollowUpActions = true;
        _showComposer = false;
        messageController.clear();

        for (final item in saved) {
          final map = Map<String, dynamic>.from(item as Map);

          messages.add({
            'sender': map['sender']?.toString() ?? 'ai',
            'message': map['message']?.toString() ?? '',
            'created_at': map['created_at']?.toString() ?? '',
          });
        }
      });

      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Nia could not send your question. Please try again.'),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();

    if (text.isEmpty || _isSending) return;

    messageController.clear();
    await _sendQuestion(text);
  }

  String? _formatMessageTimestamp(String? rawTimestamp) {
    if (rawTimestamp == null || rawTimestamp.trim().isEmpty) {
      return null;
    }

    final parsed = DateTime.tryParse(rawTimestamp.trim());

    if (parsed == null) return null;

    final local = parsed.toLocal();

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final day = local.day.toString().padLeft(2, '0');
    final month = months[local.month - 1];
    final year = local.year;
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$day $month $year · $hour:$minute';
  }

  Widget _messageBubble(Map<String, String> message) {
    final isUser = message['sender'] == 'user';
    final timestamp = _formatMessageTimestamp(message['created_at']);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 320),
            margin: const EdgeInsets.symmetric(vertical: 6),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: isUser ? DA.rose : DA.surface,
              border: isUser ? null : Border.all(color: DA.divider),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 20),
              ),
            ),
            child: Text(
              message['message'] ?? '',
              style: DA.body(
                15,
                color: isUser ? Colors.white : DA.ink,
                height: 1.5,
              ),
            ),
          ),
          if (timestamp != null)
            Padding(
              padding: const EdgeInsets.only(
                left: 4,
                right: 4,
                bottom: 5,
              ),
              child: Text(
                timestamp,
                style: DA.body(11, color: DA.quiet),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTopicList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text('How can I help you today?', style: DA.heading(19)),
        const SizedBox(height: 6),
        Text(
          'Select a topic to explore its questions.',
          style: DA.body(14, color: DA.quiet),
        ),
        const SizedBox(height: 14),
        if (_isLoadingTopics)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(color: DA.rose),
            ),
          )
        else if (_topicsError != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: DA.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DA.divider),
            ),
            child: Column(
              children: [
                const Icon(Icons.cloud_off_outlined, color: DA.rose, size: 30),
                const SizedBox(height: 8),
                Text(_topicsError!, style: DA.body(14)),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _isLoadingTopics = true;
                      _topicsError = null;
                    });
                    _loadTopics();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          )
        else if (_topics.isEmpty)
          Text(
            'No topics are currently available. Please try again later.',
            style: DA.body(14, color: DA.quiet),
          )
        else
          ..._topics.map(_topicCard),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: _startOwnQuestion,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Type out my own question'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DA.rose,
            side: const BorderSide(color: DA.rose),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _topicCard(Map<String, dynamic> topic) {
    final id = topic['id']?.toString() ?? '';
    final title = topic['title']?.toString() ?? 'Health topic';

    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: DA.surface,
        border: Border.all(color: DA.divider),
        borderRadius: BorderRadius.circular(15),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 5,
        ),
        leading: Container(
          width: 38,
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: DA.blush,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            id,
            style: DA.body(
              16,
              color: DA.rose,
              weight: FontWeight.w700,
            ),
          ),
        ),
        title: Text(
          title,
          style: DA.body(14, weight: FontWeight.w700),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: DA.rose,
        ),
        onTap: () => _selectTopic(topic),
      ),
    );
  }

  Widget _buildQuestionList() {
    final topic = _selectedTopic!;
    final title = topic['title']?.toString() ?? 'Questions';
    final questions = (topic['questions'] as List?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              tooltip: 'Back to topics',
              onPressed: _showAllTopics,
              icon: const Icon(Icons.arrow_back_rounded, color: DA.rose),
            ),
            Expanded(
              child: Text(title, style: DA.heading(18)),
            ),
          ],
        ),
        Text(
          'Choose a question below and Nia will provide an answer.',
          style: DA.body(14, color: DA.quiet),
        ),
        const SizedBox(height: 14),
        if (questions.isEmpty)
          Text(
            'There are no questions listed for this topic yet.',
            style: DA.body(14, color: DA.quiet),
          )
        else
          ...questions.map((item) {
            final question = Map<String, dynamic>.from(item as Map);
            final questionText = question['question']?.toString() ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 9),
              decoration: BoxDecoration(
                color: DA.surface,
                border: Border.all(color: DA.divider),
                borderRadius: BorderRadius.circular(14),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                title: Text(
                  questionText,
                  style: DA.body(14, weight: FontWeight.w600),
                ),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 15,
                  color: DA.rose,
                ),
                onTap: _isSending ? null : () => _sendQuestion(questionText),
              ),
            );
          }),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: _startOwnQuestion,
          icon: const Icon(Icons.edit_outlined),
          label: const Text('Type out my own question'),
          style: OutlinedButton.styleFrom(
            foregroundColor: DA.rose,
            side: const BorderSide(color: DA.rose),
            minimumSize: const Size(double.infinity, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        TextButton.icon(
          onPressed: _showAllTopics,
          icon: const Icon(Icons.grid_view_rounded, size: 17),
          label: const Text('Choose another topic'),
          style: TextButton.styleFrom(foregroundColor: DA.sage),
        ),
      ],
    );
  }

  Widget _buildFollowUpActions() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DA.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DA.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What would you like to do next?',
            style: DA.body(15, weight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (_selectedTopic != null)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _showFollowUpActions = false;
                    _showComposer = false;
                  });
                },
                icon: const Icon(Icons.list_alt_rounded),
                label: const Text('More questions in this topic'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DA.rose,
                  side: const BorderSide(color: DA.rose),
                  minimumSize: const Size(double.infinity, 46),
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _showAllTopics,
              icon: const Icon(Icons.grid_view_rounded),
              label: const Text('Choose another topic'),
              style: OutlinedButton.styleFrom(
                foregroundColor: DA.rose,
                side: const BorderSide(color: DA.rose),
                minimumSize: const Size(double.infinity, 46),
              ),
            ),
          ),
          TextButton.icon(
            onPressed: _startOwnQuestion,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Ask my own question'),
            style: TextButton.styleFrom(
              foregroundColor: DA.sage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    if (!_showComposer) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: const BoxDecoration(
        color: DA.surface,
        border: Border(top: BorderSide(color: DA.divider)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: messageController,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => sendMessage(),
              style: DA.body(15),
              decoration: InputDecoration(
                hintText: 'Type your question for Nia...',
                hintStyle: DA.body(14, color: DA.quiet),
                filled: true,
                fillColor: DA.ground,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 17,
                  vertical: 13,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: DA.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: DA.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: const BorderSide(color: DA.rose, width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(width: 9),
          SizedBox(
            width: 48,
            height: 48,
            child: IconButton(
              tooltip: 'Send question',
              onPressed: _isSending ? null : sendMessage,
              style: IconButton.styleFrom(
                backgroundColor: DA.rose,
                foregroundColor: Colors.white,
                disabledBackgroundColor: DA.rose.withValues(alpha: 0.5),
              ),
              icon: _isSending
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send_rounded, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DA.ground,
      drawer: buildDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(8, 10, 20, 10),
              decoration: const BoxDecoration(
                color: DA.surface,
                border: Border(bottom: BorderSide(color: DA.divider)),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (context) => IconButton(
                      tooltip: 'Menu',
                      icon: const Icon(Icons.menu_rounded, color: DA.ink),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: DA.blush,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: DA.rose,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nia', style: DA.heading(18)),
                        Text(
                          'Her Health assistant Â· Not a doctor',
                          style: DA.body(12, color: DA.quiet),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DA.emergencyNotice(),
            if (_isLoadingHistory)
              const LinearProgressIndicator(
                minHeight: 2,
                color: DA.rose,
                backgroundColor: DA.blush,
              ),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                children: [
                  ...messages.map(_messageBubble),
                  if (_isSending)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: DA.surface,
                          border: Border.all(color: DA.divider),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: DA.rose,
                          ),
                        ),
                      ),
                    ),
                  if (_showFollowUpActions)
                    _buildFollowUpActions()
                  else if (_selectedTopic != null)
                    _buildQuestionList()
                  else
                    _buildTopicList(),
                ],
              ),
            ),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Drawer buildDrawer() {
    final name = AuthService.firstName ?? '';

    return Drawer(
      backgroundColor: DA.ground,
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: DA.blush,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Image.asset('assets/images/logo/logo.png'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Her Health', style: DA.heading(20)),
                        if (name.isNotEmpty)
                          Text(
                            'Hi, $name',
                            style: DA.body(14, color: DA.muted),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            _drawerTile(
              Icons.auto_awesome_outlined,
              'AI Assistant',
              null,
            ),
            _drawerTile(
              Icons.calendar_month_outlined,
              'Appointments',
              const AppointmentsScreen(),
            ),
            _drawerTile(
              Icons.medical_services_outlined,
              'Contact Doctor',
              const MessagesScreen(),
            ),
            _drawerTile(
              Icons.favorite_border_rounded,
              'Health Profile',
              const HealthProfileScreen(),
            ),
            _drawerTile(
              Icons.monitor_heart_outlined,
              'Health Tracking',
              const HealthTrackingScreen(),
            ),
            _drawerTile(
              Icons.history_rounded,
              'Health History',
              const HealthHistoryScreen(),
            ),
            _drawerTile(
              Icons.notifications_none_rounded,
              'Reminders',
              const RemindersScreen(),
            ),
            _drawerTile(
              Icons.article_outlined,
              'Health Articles',
              const ArticlesScreen(),
            ),
            _drawerTile(
              Icons.settings_outlined,
              'Settings',
              const SettingsScreen(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _drawerTile(IconData icon, String title, Widget? screen) {
    final current = screen == null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        tileColor: current ? DA.blush : null,
        leading: Icon(icon, color: current ? DA.rose : DA.sage),
        title: Text(
          title,
          style: DA.body(
            16,
            weight: current ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        onTap: () {
          Navigator.pop(context);
          if (screen != null) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => screen),
            );
          }
        },
      ),
    );
  }
}
