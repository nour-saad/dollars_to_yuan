import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/constants/colors.dart';
import '../../../core/config/app_config.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  bool _isLoading = false;
  List<Package> _packages = [];
  Package? _selected;

  @override
  void initState() {
    super.initState();
    _loadOfferings();
  }

  Future<void> _loadOfferings() async {
    setState(() => _isLoading = true);
    final packages =
        await ref.read(purchaseServiceProvider).getOfferings();
    if (mounted) {
      setState(() {
        _packages = packages;
        // Prefer the yearly package as the default selection.
        _selected = packages.isNotEmpty
            ? (packages.firstWhere(
                (p) => p.identifier == AppConfig.yearlyPackageId,
                orElse: () => packages.first,
              ))
            : null;
        _isLoading = false;
      });
    }
  }

  Package? _packageById(String id) {
    try {
      return _packages.firstWhere((p) => p.identifier == id);
    } catch (_) {
      return null;
    }
  }

  String _priceFor(Package? package) {
    if (package == null) return '';
    final store = package.storeProduct;
    return store.priceString;
  }

  String _titleFor(Package package) {
    if (package.identifier == AppConfig.monthlyPackageId) return 'Monthly';
    if (package.identifier == AppConfig.yearlyPackageId) return 'Yearly';
    return package.storeProduct.title.isNotEmpty
        ? package.storeProduct.title
        : 'Subscription';
  }

  void _purchase() async {
    if (_selected == null) return;
    setState(() => _isLoading = true);
    final success =
        await ref.read(purchaseServiceProvider).purchasePackage(_selected!);
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Purchase failed or cancelled')),
        );
      }
    }
  }

  void _restore() async {
    setState(() => _isLoading = true);
    final success = await ref.read(purchaseServiceProvider).restorePurchases();
    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No previous purchases found')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final monthly = _packageById(AppConfig.monthlyPackageId);
    final yearly = _packageById(AppConfig.yearlyPackageId);

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.primaryContainer,
                  Theme.of(context).scaffoldBackgroundColor,
                ],
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 80),
                        const SizedBox(height: 24),
                        Text(
                          'Upgrade to Premium',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enjoy a faster experience with live exchange rates.',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withOpacity(0.7),
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 48),
                        _buildBenefitRow(Icons.block, 'No ads'),
                        _buildBenefitRow(Icons.bolt, 'Live rates'),
                        _buildBenefitRow(Icons.autorenew, 'Background updates'),
                        _buildBenefitRow(Icons.do_not_disturb, 'No interruptions'),
                        _buildBenefitRow(Icons.favorite, 'Support development'),
                        const SizedBox(height: 48),

                        // Live pricing cards
                        if (_packages.isEmpty && _isLoading)
                          const CircularProgressIndicator()
                        else if (_packages.isEmpty)
                          const Text('Unable to load offers. Check your connection.')
                        else
                          Row(
                            children: [
                              if (monthly != null)
                                Expanded(
                                  child: _buildPricingCard(
                                    monthly,
                                    _titleFor(monthly),
                                    _priceFor(monthly),
                                    _selected == monthly,
                                  ),
                                ),
                              if (monthly != null && yearly != null)
                                const SizedBox(width: 16),
                              if (yearly != null)
                                Expanded(
                                  child: _buildPricingCard(
                                    yearly,
                                    _titleFor(yearly),
                                    _priceFor(yearly),
                                    _selected == yearly,
                                    'Best value',
                                  ),
                                ),
                            ],
                          ),
                        const SizedBox(height: 32),

                        if (_isLoading)
                          const CircularProgressIndicator()
                        else
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: _selected == null ? null : _purchase,
                              child: const Text(
                                'Continue',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _restore,
                          child: const Text('Restore Purchases'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
      child: Row(
        children: [
          Icon(icon, color: AppColors.usdBlue, size: 24),
          const SizedBox(width: 16),
          Text(
            text,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildPricingCard(
    Package package,
    String title,
    String price,
    bool isSelected, [
    String? badge,
  ]) {
    return GestureDetector(
      onTap: () => setState(() => _selected = package),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
              : Colors.transparent,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.withOpacity(0.3),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            if (badge != null)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cnyRed,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              )
            else
              const SizedBox(height: 20),
            const SizedBox(height: 8),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              price,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
