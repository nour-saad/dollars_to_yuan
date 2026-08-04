import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/purchase_service.dart';
import '../../../core/providers/exchange_rate_provider.dart';
import '../../settings/screens/settings_screen.dart';
import '../widgets/exchange_rate_card.dart';
import '../widgets/conversion_calculator.dart';
import '../widgets/premium_promotion_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  @override
  void initState() {
    super.initState();
    // After widget builds, load ads if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadAdsIfNeeded();
    });
  }

  void _loadAdsIfNeeded() {
    final isPremium = ref.read(premiumStatusProvider);
    if (!isPremium) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    final adService = ref.read(adServiceProvider);
    
    _bannerAd = BannerAd(
      adUnitId: adService.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          setState(() {
            _isBannerAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          setState(() {
            _isBannerAdLoaded = false;
          });
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await ref.read(exchangeRateProvider.notifier).refreshRate();
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(premiumStatusProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dollars to Yuan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: _refresh,
            builder: (context, refreshState, pulledExtent, refreshTriggerPullDistance, refreshIndicatorExtent) {
              final rateState = ref.watch(exchangeRateProvider);
              final isOffline = rateState.isOffline;
              
              String text = isOffline ? 'Offline mode' : 'Pull down to refresh';
              if (refreshState == RefreshIndicatorMode.refresh || refreshState == RefreshIndicatorMode.armed) {
                text = isOffline ? 'Offline mode' : 'Refreshing...';
              }
              
              return Container(
                alignment: Alignment.center,
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              );
            },
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const ExchangeRateCard(),
                const ConversionCalculator(),
                if (!isPremium) const PremiumPromotionCard(),
                const SizedBox(height: 80), // padding for banner ad
              ]),
            ),
          ),
        ],
      ),
      bottomNavigationBar: (!isPremium && _isBannerAdLoaded && _bannerAd != null)
          ? Container(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              alignment: Alignment.center,
              child: AdWidget(ad: _bannerAd!),
            )
          : null,
    );
  }
}
