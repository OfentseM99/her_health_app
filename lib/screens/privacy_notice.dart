import 'package:flutter/material.dart';

import '../theme/design_a.dart';

/// IMPORTANT:
/// This notice is suitable for staging/testing, but the practice must confirm:
/// - its registered/legal practice name
/// - Information Officer details
/// - final retention periods
/// - production hosting / service providers
/// - whether any external AI provider processes patient information
///
/// Before real patients use the app, the practice or its legal/POPIA adviser
/// should approve the final wording.
///
/// Keep this version in sync with PRIVACY_NOTICE_VERSION in:
/// womens_health_backend/routers/auth.py
const String kPrivacyNoticeVersion = 'draft-2026-10';

const List<(String, String)> _sections = [
  (
    'Who is responsible for your information?',
    'Her Health is provided by [PRACTICE LEGAL NAME] ("the practice"). '
        'The practice is responsible for deciding why and how your personal '
        'information is processed through Her Health.\n\n'
        'Information Officer: [FULL NAME]\n'
        'Email: [EMAIL ADDRESS]\n'
        'Telephone: [PHONE NUMBER]',
  ),
  (
    'What information do we collect?',
    'Depending on how you use Her Health, we may collect your name, email '
        'address, telephone number, date of birth, emergency contact details, '
        'address and other profile information.\n\n'
        'Because Her Health supports healthcare services, you may also choose '
        'to provide health information such as your blood type, allergies, '
        'medical conditions, medication, pregnancy or postpartum information, '
        'health journey answers, symptoms, mood, pain levels, journal entries '
        'and other health-tracking information.\n\n'
        'We may also process appointment requests, billing information, '
        'messages exchanged with the practice, reminders and your chats with '
        'Nia.',
  ),
  (
    'Why do we process your information?',
    'We process your information so that the practice can provide and support '
        'healthcare-related services, maintain your patient profile, manage '
        'appointments, communicate with you, manage billing, provide relevant '
        'health information, support health tracking and operate Her Health '
        'safely and securely.\n\n'
        'We will not use your health information for unrelated advertising or '
        'sell your personal information.',
  ),
  (
    'Health information',
    'Health and medical information is sensitive information and receives '
        'additional protection under South African privacy law. The practice '
        'will only process this information where there is a lawful basis to '
        'do so and for purposes connected with the services described in this '
        'notice.',
  ),
  (
    'Who can access your information?',
    'Access is limited to authorised members of the practice who require the '
        'information to perform their duties.\n\n'
        'The practice may also use technology service providers to host, store '
        'or process information on its behalf. These providers must only '
        'process information as authorised by the practice and must apply '
        'appropriate security safeguards.\n\n'
        'Before production launch, the practice will confirm the final list '
        'of hosting, database, infrastructure and any AI service providers '
        'used by Her Health.',
  ),
  (
    'Nia',
    'Nia is a digital support feature intended to provide general information '
        'and help you navigate Her Health. Nia is not a replacement for a '
        'doctor, nurse, diagnosis, treatment or emergency medical care.\n\n'
        '[BEFORE PRODUCTION: Confirm whether Nia sends information to any '
        'external AI service. If it does, identify the provider, explain what '
        'information may be shared and document the applicable safeguards.]',
  ),
  (
    'Device unlock and biometrics',
    'Her Health may allow you to sign in using your device security, such as '
        'Touch ID, Face ID, fingerprint recognition or your device PIN.\n\n'
        'Her Health does not receive or store your fingerprint, facial scan '
        'or device PIN. Your device or browser performs the verification and '
        'Her Health receives a secure public-key credential confirming that '
        'the device authentication succeeded.',
  ),
  (
    'How we protect your information',
    'The practice uses reasonable technical and organisational measures '
        'designed to protect personal information from loss, unauthorised '
        'access, alteration, disclosure or destruction.\n\n'
        'These measures include authenticated access, role-based permissions, '
        'secure password handling, device authentication where enabled and '
        'restricted access to patient information.\n\n'
        'Security measures are reviewed and updated as risks and the system '
        'change.',
  ),
  (
    'How long do we keep your information?',
    'Personal and health information is retained only for as long as required '
        'for the purpose for which it was collected, the practice\'s lawful '
        'record-keeping obligations, professional requirements and any other '
        'applicable legal requirements.\n\n'
        '[PRACTICE TO CONFIRM FINAL PATIENT RECORD RETENTION PERIOD BEFORE '
        'PRODUCTION.]',
  ),
  (
    'Your choices and rights',
    'Subject to applicable law, you may ask the practice to provide access to '
        'personal information it holds about you, correct inaccurate or '
        'incomplete information, or consider a request for deletion or '
        'restriction where legally permitted.\n\n'
        'Her Health also provides tools that allow you to view or copy data '
        'associated with your account and request account deletion.\n\n'
        'Some information may need to be retained where the practice has a '
        'legal or professional obligation to keep it.',
  ),
  (
    'Security incidents',
    'If personal information is accessed or acquired by an unauthorised '
        'person, the practice will handle the incident in accordance with '
        'applicable legal requirements, including required notifications to '
        'affected people and the Information Regulator.',
  ),
  (
    'Complaints',
    'If you have a privacy concern, please contact the practice\'s Information '
        'Officer first using the contact details above.\n\n'
        'You may also lodge a complaint with the Information Regulator of '
        'South Africa if you believe your personal information has been '
        'processed unlawfully.',
  ),
  (
    'Not for emergencies',
    'Her Health, Nia and practice messages are not emergency services and may '
        'not be monitored continuously.\n\n'
        'If you have a medical emergency, contact emergency medical services '
        'or go to the nearest appropriate emergency facility.',
  ),
];

Future<void> showPrivacyNotice(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: DA.ground,
    constraints: const BoxConstraints(
      maxWidth: 640,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (
          context,
          scrollController,
        ) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(
              24,
              24,
              24,
              32,
            ),
            children: [
              Text(
                'Privacy notice',
                style: DA.heading(24),
              ),
              const SizedBox(height: 6),
              Text(
                'Version: $kPrivacyNoticeVersion',
                style: DA.body(
                  13,
                  color: DA.quiet,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DA.pendingBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Testing version: the practice must confirm the '
                  'Information Officer, retention period, service providers '
                  'and final legal wording before real patient use.',
                  style: DA.body(
                    13,
                    color: DA.pendingInk,
                    weight: FontWeight.w700,
                  ),
                ),
              ),
              for (final (title, text) in _sections) ...[
                const SizedBox(height: 20),
                Text(
                  title,
                  style: DA.heading(
                    17,
                    color: DA.sage,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  text,
                  style: DA.body(
                    15,
                    height: 1.55,
                  ),
                ),
              ],
              const SizedBox(height: 28),
              ElevatedButton(
                style: DA.primary(),
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      );
    },
  );
}
