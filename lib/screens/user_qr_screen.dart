import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

class UserQrScreen extends StatelessWidget {
  final String userId;

  const UserQrScreen({
    super.key,
    this.userId = 'demo-user-001',
  });

  static const Color rose = Color(0xFFB04F6C);
  static const Color blush = Color(0xFFF6DCE2);
  static const Color forestGreen = Color(0xFF2F3A2A);
  static const Color bodyText = Color(0xFF5E5652);
  static const Color borderColor = Color(0xFFEADFDB);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6F3),
      appBar: AppBar(
        title: const Text(
          'My QR Code',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: rose,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Keep the existing Her Health background.
          Image.asset(
            'assets/images/backgrounds/background.jpeg',
            fit: BoxFit.cover,
          ),

          Container(
            color: Colors.white.withValues(alpha: 0.48),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(22),
                child: Column(
                  children: [
                    // QR icon.
                    Container(
                      height: 68,
                      width: 68,
                      decoration: const BoxDecoration(
                        color: blush,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.qr_code_2_rounded,
                        size: 38,
                        color: rose,
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Text(
                      'My Her Health QR Code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: forestGreen,
                      ),
                    ),

                    const SizedBox(height: 10),

                    const Text(
                      'Your account identification code, '
                      'all in one place.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.5,
                        color: bodyText,
                      ),
                    ),

                    const SizedBox(height: 28),

                    // QR code card.
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.96),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: borderColor,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: rose.withValues(alpha: 0.08),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: blush,
                                width: 2,
                              ),
                            ),
                            child: QrImageView(
                              data: userId,
                              version: QrVersions.auto,
                              size: 230,
                              backgroundColor: Colors.white,
                              errorCorrectionLevel: QrErrorCorrectLevel.M,
                            ),
                          ),
                          const SizedBox(height: 24),
                          const Text(
                            'Demo account',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: forestGreen,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF6F3),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: borderColor,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.person_outline,
                                  size: 19,
                                  color: rose,
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    userId,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: bodyText,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          const Divider(
                            color: borderColor,
                          ),
                          const SizedBox(height: 14),
                          const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: rose,
                                size: 21,
                              ),
                              SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'This QR code identifies your demo '
                                  'account only. Backend account '
                                  'integration will be added later.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: bodyText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.security_outlined,
                          size: 17,
                          color: Color(0xFF6E7B5F),
                        ),
                        SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            'Demonstration only — no medical records '
                            'are retrieved or displayed.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: bodyText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
