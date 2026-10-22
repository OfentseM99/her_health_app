import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import '../services/passkey_service.dart';
import '../theme/design_a.dart';
import 'billing_screen.dart';
import 'health_profile_screen.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Log out?'),
        content: const Text(
          'You will need to log in again to use Her Health.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  Future<void> _enableDeviceUnlock(
    BuildContext context,
  ) async {
    try {
      final available =
          await PasskeyService.isAvailable();

      if (!available) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Device unlock is not available on this device or browser.',
            ),
          ),
        );
        return;
      }

      if (!context.mounted) return;

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          backgroundColor: DA.ground,
          title: Text(
            'Enable device unlock?',
            style: DA.heading(22),
          ),
          content: Text(
            'Her Health can use your device security, such as '
            'Face ID, Touch ID, fingerprint or device PIN, '
            'to help you sign in faster.\n\n'
            'Her Health never receives or stores your fingerprint, '
            'face scan or device PIN.',
            style: DA.body(15),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext, true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Follow your device prompt to enable device unlock.',
          ),
        ),
      );

      final options =
          await AuthService.beginPasskeyRegistration(
        portal: 'patient',
      );

      final credentialJson =
          await PasskeyService.register(
        jsonEncode(options),
      );

      final decoded = jsonDecode(credentialJson);

      if (decoded is! Map) {
        throw AuthException(
          'The device returned an invalid credential.',
        );
      }

      final credential =
          Map<String, dynamic>.from(decoded);

      await AuthService.finishPasskeyRegistration(
        portal: 'patient',
        credential: credential,
        deviceName: 'Patient device',
      );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Device unlock enabled successfully.',
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message),
          backgroundColor: Colors.red.shade400,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      final message = e.toString().toLowerCase();

      final cancelled =
          message.contains('notallowed') ||
          message.contains('cancel');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            cancelled
                ? 'Device unlock setup was cancelled.'
                : 'Could not enable device unlock. Please try again.',
          ),
          backgroundColor: Colors.red.shade400,
        ),
      );
    }
  }

  /// Shows everything the app holds about the patient,
  /// with a Copy button.
  Future<void> _showMyData(
    BuildContext context,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: DA.ground,
        title: Text(
          'Your data',
          style: DA.heading(22),
        ),
        content: SizedBox(
          width: 560,
          height: 420,
          child: FutureBuilder<Map<String, dynamic>>(
            future: AuthService.exportMyData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState !=
                  ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: DA.rose,
                  ),
                );
              }

              if (snapshot.hasError) {
                return Text(
                  snapshot.error.toString(),
                  style: DA.body(
                    15,
                    color: DA.rejectedInk,
                  ),
                );
              }

              final pretty =
                  const JsonEncoder.withIndent('  ')
                      .convert(snapshot.data);

              return Column(
                crossAxisAlignment:
                    CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'This is everything Her Health holds about you. '
                    'Copy it to keep a record.',
                    style: DA.body(
                      14,
                      color: DA.muted,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: DA.card(
                        radius: 12,
                      ),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          pretty,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: DA.outline(),
                    icon:
                        const Icon(Icons.copy_rounded),
                    label: const Text('Copy all'),
                    onPressed: () async {
                      await Clipboard.setData(
                        ClipboardData(text: pretty),
                      );

                      if (!context.mounted) return;

                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Copied to clipboard.',
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(
    BuildContext context,
  ) async {
    final deleted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) =>
          const _DeleteAccountDialog(),
    );

    if (deleted != true) return;

    await AuthService.logout();

    if (!context.mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = AuthService.firstName ?? '';

    return Scaffold(
      backgroundColor: DA.ground,
      body: SafeArea(
        child: ListView(
          padding:
              const EdgeInsets.fromLTRB(
            24,
            16,
            24,
            32,
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: DA.backButton(context),
            ),

            const SizedBox(height: 16),

            Text(
              'Settings',
              style: DA.heading(30),
            ),

            if (name.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                'Signed in as $name',
                style:
                    DA.body(15, color: DA.muted),
              ),
            ],

            const SizedBox(height: 28),

            Container(
              decoration: DA.card(),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: const Icon(
                      Icons.favorite_border_rounded,
                      color: DA.sage,
                    ),
                    title: Text(
                      'Health profile',
                      style: DA.body(
                        16,
                        weight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Your details, contacts and health info',
                      style: DA.body(
                        14,
                        color: DA.quiet,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: DA.quiet,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const HealthProfileScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(
                    height: 1,
                    color: DA.divider,
                  ),

                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: const Icon(
                      Icons.receipt_long_outlined,
                      color: DA.sage,
                    ),
                    title: Text(
                      'Billing',
                      style: DA.body(
                        16,
                        weight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'View your bills and payment status',
                      style: DA.body(
                        14,
                        color: DA.quiet,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: DA.quiet,
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const BillingScreen(),
                        ),
                      );
                    },
                  ),

                  const Divider(
                    height: 1,
                    color: DA.divider,
                  ),

                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: const Icon(
                      Icons.fingerprint_rounded,
                      color: DA.sage,
                    ),
                    title: Text(
                      'Enable device unlock',
                      style: DA.body(
                        16,
                        weight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Use Face ID, Touch ID, fingerprint or device PIN',
                      style: DA.body(
                        14,
                        color: DA.quiet,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: DA.quiet,
                    ),
                    onTap: () =>
                        _enableDeviceUnlock(context),
                  ),

                  const Divider(
                    height: 1,
                    color: DA.divider,
                  ),

                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: DA.rose,
                    ),
                    title: Text(
                      'Log out',
                      style: DA.body(
                        16,
                        color: DA.rose,
                        weight: FontWeight.w700,
                      ),
                    ),
                    onTap: () =>
                        _confirmLogout(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            Text(
              'Your data',
              style: DA.heading(
                19,
                color: DA.sage,
              ),
            ),

            const SizedBox(height: 12),

            Container(
              decoration: DA.card(),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: const Icon(
                      Icons.download_rounded,
                      color: DA.sage,
                    ),
                    title: Text(
                      'Download my data',
                      style: DA.body(
                        16,
                        weight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'See and copy everything we hold about you',
                      style: DA.body(
                        14,
                        color: DA.quiet,
                      ),
                    ),
                    onTap: () =>
                        _showMyData(context),
                  ),

                  const Divider(
                    height: 1,
                    color: DA.divider,
                  ),

                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 6,
                    ),
                    leading: const Icon(
                      Icons.delete_outline_rounded,
                      color: DA.rejectedInk,
                    ),
                    title: Text(
                      'Delete my account',
                      style: DA.body(
                        16,
                        color: DA.rejectedInk,
                        weight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      'Permanently remove your account and data',
                      style: DA.body(
                        14,
                        color: DA.quiet,
                      ),
                    ),
                    onTap: () =>
                        _deleteAccount(context),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Asks for the password before permanently
/// deleting the account.
class _DeleteAccountDialog
    extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState
    extends State<_DeleteAccountDialog> {
  final passwordController =
      TextEditingController();

  bool _isDeleting = false;
  String? _error;

  @override
  void dispose() {
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (passwordController.text.isEmpty) {
      setState(() {
        _error =
            'Enter your password to confirm.';
      });
      return;
    }

    setState(() {
      _isDeleting = true;
      _error = null;
    });

    try {
      await AuthService.deleteMyAccount(
        passwordController.text,
      );

      if (!mounted) return;

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: DA.ground,
      title: Text(
        'Delete your account?',
        style: DA.heading(22),
      ),
      content: SizedBox(
        width: 420,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.stretch,
          children: [
            Text(
              'This permanently deletes your account, health profile, '
              'journey answers, appointments, messages, chats and reminders. '
              'It cannot be undone.',
              style: DA.body(
                15,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 16),

            DA.label('Your password'),

            TextField(
              controller: passwordController,
              obscureText: true,
              style: DA.body(16),
              decoration: DA.input(),
              onSubmitted: (_) {
                if (!_isDeleting) {
                  _delete();
                }
              },
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: DA.body(
                  14,
                  color: DA.rejectedInk,
                  weight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting
              ? null
              : () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
          child: const Text('Cancel'),
        ),

        TextButton(
          onPressed:
              _isDeleting ? null : _delete,
          child: _isDeleting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2,
                    color: DA.rejectedInk,
                  ),
                )
              : Text(
                  'Delete permanently',
                  style: DA.body(
                    15,
                    color: DA.rejectedInk,
                    weight: FontWeight.w700,
                  ),
                ),
        ),
      ],
    );
  }
}