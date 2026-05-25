import 'package:flutter/material.dart';

/// About screen containing app details and legal notices.
class LegalNoticesScreen extends StatelessWidget {
  /// Creates a new [LegalNoticesScreen].
  const LegalNoticesScreen({super.key});

  static const String _aboutText =
      'Brick Timer is a companion for tracking LEGO build sessions. '
      'Search sets, start builds, and keep progress in one place.';

  static const String _disclaimer =
      'This app is a fan-made tool and is not affiliated with, authorized, '
      'or endorsed by the LEGO Group.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Brick Timer',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _aboutText,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legal notices',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _disclaimer,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.article_outlined),
                  title: const Text('Open source licenses'),
                  subtitle: const Text(
                    'View licenses for third-party software',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    showLicensePage(
                      context: context,
                      applicationName: 'Brick Timer',
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
