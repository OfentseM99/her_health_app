import 'package:flutter/material.dart';

class BillingScreen extends StatelessWidget {
  const BillingScreen({super.key});

  static const Color rose = Color(0xFFB04F6C);
  static const Color blush = Color(0xFFF6DCE2);
  static const Color forest = Color(0xFF2F3A2A);
  static const Color bodyText = Color(0xFF5E5652);

  void showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/backgrounds/background.jpeg',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              color: const Color(0xFFFAF6F3).withValues(alpha: 0.94),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.arrow_back),
                        color: forest,
                      ),
                      const Expanded(
                        child: Text(
                          'Billing',
                          style: TextStyle(
                            fontSize: 27,
                            fontWeight: FontWeight.bold,
                            color: forest,
                          ),
                        ),
                      ),
                      Image.asset(
                        'assets/images/logo/logo.png',
                        height: 48,
                        width: 48,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                          Icons.favorite,
                          color: rose,
                          size: 32,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Your payments and invoices',
                    style: TextStyle(fontSize: 15, color: bodyText),
                  ),
                  const SizedBox(height: 20),

                  // Example balance card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: rose,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Outstanding balance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'R 0.00',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No live account balance is connected yet.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Invoices',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: forest,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _billingCard(
                    icon: Icons.receipt_long_outlined,
                    title: 'Your invoices',
                    subtitle:
                        'View invoices issued by your healthcare provider',
                    trailing: Icons.chevron_right,
                    onTap: () => showMessage(
                      context,
                      'Invoices will appear here when billing is connected.',
                    ),
                  ),
                  const SizedBox(height: 12),
                  _billingCard(
                    icon: Icons.history,
                    title: 'Payment history',
                    subtitle: 'Review payments made to your provider',
                    trailing: Icons.chevron_right,
                    onTap: () => showMessage(
                      context,
                      'Payment history will appear here when connected.',
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Payment options',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: forest,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _billingCard(
                    icon: Icons.credit_card_outlined,
                    title: 'Payment methods',
                    subtitle: 'Payment methods are not set up yet',
                    trailing: Icons.chevron_right,
                    onTap: () => showMessage(
                      context,
                      'Online payments are not connected yet.',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: blush.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.lock_outline, color: rose),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Your billing information should only be visible '
                            'to you and authorised practice staff.',
                            style: TextStyle(
                              color: forest,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _billingCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required IconData trailing,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFEADFDB)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: blush,
          child: Icon(icon, color: rose),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: forest,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            subtitle,
            style: const TextStyle(color: bodyText, fontSize: 12),
          ),
        ),
        trailing: Icon(trailing, color: rose),
        onTap: onTap,
      ),
    );
  }
}
