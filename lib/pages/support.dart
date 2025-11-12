import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({Key? key}) : super(key: key);

  static const _phone = '07000000000';
  static const _email = 'support@example.com';
  static const _emailSubject = 'App Support Request';
  static const _emailBody = 'Please describe your issue here...';

  Future<void> _launchPhone(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _phone);
    final launched = await launchUrl(uri);
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open phone dialer.')),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context) async {
    final uri = Uri(
      scheme: 'mailto',
      path: _email,
      queryParameters: {
        'subject': _emailSubject,
        'body': _emailBody,
      },
    );
    final launched = await launchUrl(uri);
    if (!launched) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open email client.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [theme.colorScheme.primary.withOpacity(0.06), Colors.white],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: accent.withOpacity(0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.support_agent_rounded,
                            size: 40,
                            color: accent,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Need help?',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Contact our support team — we\'re happy to help you 24/7.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Contact card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                    child: Column(
                      children: [
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE8F5E9),
                            child: Icon(Icons.phone, color: Color(0xFF2E7D32)),
                          ),
                          title: const Text('Call support'),
                          subtitle: Text(_phone),
                          trailing: ElevatedButton.icon(
                            onPressed: () => _launchPhone(context),
                            icon: const Icon(Icons.call),
                            label: const Text('Call'),
                            style: ElevatedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                          ),
                        ),
                        const Divider(height: 1),
                        ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFFE3F2FD),
                            child: Icon(Icons.email, color: Color(0xFF1565C0)),
                          ),
                          title: const Text('Email support'),
                          subtitle: Text(_email),
                          trailing: OutlinedButton.icon(
                            onPressed: () => _launchEmail(context),
                            icon: const Icon(Icons.send),
                            label: const Text('Email'),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Helpful tips
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                  color: theme.colorScheme.primary.withOpacity(0.04),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.blueAccent),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'When contacting support, please include your account email and a short description of the issue. This helps us resolve it faster.',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: Colors.grey[800],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: () => _launchEmail(context),
                            child: const Text('Compose email with suggested details'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}