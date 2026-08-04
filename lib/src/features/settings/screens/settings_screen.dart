import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/purchase_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPremium = ref.watch(premiumStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Developer testing tool
          ListTile(
            leading: Icon(isPremium ? Icons.star : Icons.star_border, color: Colors.orange),
            title: Text(isPremium ? 'Premium Active' : 'Free Version'),
            subtitle: const Text('Tap to toggle (Test Mode)'),
            onTap: () {
              ref.read(premiumStatusProvider.notifier).togglePremiumTest();
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.restore),
            title: const Text('Restore Purchases'),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Restoring purchases...')),
              );
              final success = await ref.read(purchaseServiceProvider).restorePurchases();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(success ? 'Purchases restored' : 'Nothing to restore')),
                );
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            onTap: () {
              // TODO: Open Privacy Policy URL
            },
          ),
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            onTap: () {
              // TODO: Open TOS URL
            },
          ),
          ListTile(
            leading: const Icon(Icons.rate_review),
            title: const Text('Rate the App'),
            onTap: () {
              // TODO: Open App Store / Play Store link
            },
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share App'),
            onTap: () {
              // TODO: Implement share functionality
            },
          ),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text('Contact Support'),
            onTap: () {
              // TODO: Open email client
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'App Version 1.0.0',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }
}
