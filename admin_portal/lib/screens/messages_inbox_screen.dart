import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'message_thread_screen.dart';

class MessagesInboxScreen extends StatefulWidget {
  const MessagesInboxScreen({super.key});

  @override
  State<MessagesInboxScreen> createState() => _MessagesInboxScreenState();
}

class _MessagesInboxScreenState extends State<MessagesInboxScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _threads = [];

  @override
  void initState() {
    super.initState();
    _loadThreads();
  }

  Future<void> _loadThreads() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.authorizedGet('/messages/threads');

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleSessionExpired();
        return;
      }

      if (response.statusCode != 200) {
        setState(() {
          _errorMessage = 'Failed to load messages (${response.statusCode}).';
          _isLoading = false;
        });
        return;
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      setState(() {
        _threads = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Could not reach the server.';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSessionExpired() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  Future<void> _openThread(int patientId, String patientName) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MessageThreadScreen(
          patientId: patientId,
          patientName: patientName,
        ),
      ),
    );
    // Refresh the list on return, in case a reply changed the unread count.
    _loadThreads();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Messages'),
        backgroundColor: Colors.pink.shade100,
      ),
      body: RefreshIndicator(
        onRefresh: _loadThreads,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadThreads,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_threads.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(child: Text('No messages yet.')),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _threads.length,
      itemBuilder: (context, index) {
        final thread = _threads[index] as Map<String, dynamic>;
        final patientId = thread['patient_id'] as int;
        final firstName = thread['first_name'] as String? ?? '';
        final lastName = thread['last_name'] as String? ?? '';
        final lastMessage = thread['last_message'] as String? ?? '';
        final unreadCount = thread['unread_count'] as int? ?? 0;
        final fullName = '$firstName $lastName'.trim();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              fullName.isEmpty ? 'Patient #$patientId' : fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: unreadCount > 0
                ? CircleAvatar(
                    radius: 12,
                    backgroundColor: Colors.pink.shade300,
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                : null,
            onTap: () => _openThread(patientId, fullName),
          ),
        );
      },
    );
  }
}
