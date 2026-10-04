import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ArticlesManageScreen extends StatefulWidget {
  const ArticlesManageScreen({super.key});

  @override
  State<ArticlesManageScreen> createState() => _ArticlesManageScreenState();
}

class _ArticlesManageScreenState extends State<ArticlesManageScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _articles = [];

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await ApiService.authorizedGet('/articles');

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleSessionExpired();
        return;
      }

      if (response.statusCode != 200) {
        setState(() {
          _errorMessage = 'Failed to load articles (${response.statusCode}).';
          _isLoading = false;
        });
        return;
      }

      final data = jsonDecode(response.body) as List<dynamic>;
      setState(() {
        _articles = data;
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

  Future<void> _openEditor([Map<String, dynamic>? article]) async {
    final saved = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => ArticleEditorScreen(article: article),
      ),
    );
    if (saved == true) {
      _loadArticles();
    }
  }

  Future<void> _delete(Map<String, dynamic> article) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete article?'),
        content: Text('"${article['title']}" will be removed for all patients.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response =
          await ApiService.authorizedDelete('/articles/${article['id']}');

      if (response.statusCode == 401 || response.statusCode == 403) {
        await _handleSessionExpired();
        return;
      }

      if (!mounted) return;

      if (response.statusCode == 200) {
        _loadArticles();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete (${response.statusCode}).')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Health Articles'),
        backgroundColor: Colors.pink.shade100,
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.pink.shade200,
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('New article'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadArticles,
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
              onPressed: _loadArticles,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_articles.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(child: Text('No articles yet. Tap "New article" to write one.')),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
      itemCount: _articles.length,
      itemBuilder: (context, index) {
        final article = _articles[index] as Map<String, dynamic>;
        final title = article['title'] as String? ?? '';
        final category = article['category'] as String?;
        final body = article['body'] as String? ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(12),
            title: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category != null && category.isNotEmpty)
                  Text(
                    category,
                    style: TextStyle(color: Colors.pink.shade300, fontSize: 12),
                  ),
                Text(body, maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  tooltip: 'Edit',
                  onPressed: () => _openEditor(article),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete',
                  onPressed: () => _delete(article),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Write a new article, or edit an existing one when [article] is given.
class ArticleEditorScreen extends StatefulWidget {
  final Map<String, dynamic>? article;

  const ArticleEditorScreen({super.key, this.article});

  @override
  State<ArticleEditorScreen> createState() => _ArticleEditorScreenState();
}

class _ArticleEditorScreenState extends State<ArticleEditorScreen> {
  late final TextEditingController titleController;
  late final TextEditingController categoryController;
  late final TextEditingController bodyController;
  bool _isSaving = false;

  bool get _isEditing => widget.article != null;

  @override
  void initState() {
    super.initState();
    titleController =
        TextEditingController(text: widget.article?['title'] as String? ?? '');
    categoryController = TextEditingController(
        text: widget.article?['category'] as String? ?? '');
    bodyController =
        TextEditingController(text: widget.article?['body'] as String? ?? '');
  }

  Future<void> _save() async {
    if (titleController.text.trim().isEmpty ||
        bodyController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title and the article text.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final payload = {
      'title': titleController.text.trim(),
      'category': categoryController.text.trim(),
      'body': bodyController.text.trim(),
    };

    try {
      final response = _isEditing
          ? await ApiService.authorizedPut(
              '/articles/${widget.article!['id']}', payload)
          : await ApiService.authorizedPost('/articles', payload);

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save (${response.statusCode}).')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not reach the server.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _decoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: true,
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Article' : 'New Article'),
        backgroundColor: Colors.pink.shade100,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: _decoration('Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: _decoration(
                'Category (optional)',
                hint: 'e.g. Pregnancy, Menstrual Health, Wellness',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: bodyController,
              minLines: 10,
              maxLines: 25,
              decoration: _decoration('Article text'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isEditing ? 'Save changes' : 'Publish'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
