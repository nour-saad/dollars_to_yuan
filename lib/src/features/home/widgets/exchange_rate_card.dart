import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/providers/exchange_rate_provider.dart';

class ExchangeRateCard extends ConsumerStatefulWidget {
  const ExchangeRateCard({super.key});

  @override
  ConsumerState<ExchangeRateCard> createState() => _ExchangeRateCardState();
}

class _ExchangeRateCardState extends ConsumerState<ExchangeRateCard> with SingleTickerProviderStateMixin {
  bool _isUsdToCny = true;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleDirection() {
    setState(() {
      _isUsdToCny = !_isUsdToCny;
      if (_isUsdToCny) {
        _controller.reverse();
      } else {
        _controller.forward();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final rateState = ref.watch(exchangeRateProvider);
    final rateNotifier = ref.read(exchangeRateProvider.notifier);

    final displayRate = _isUsdToCny ? rateState.rate : (1 / rateState.rate);
    final fromCurrency = _isUsdToCny ? '1 USD' : '1 CNY';
    final toCurrency = _isUsdToCny 
        ? '${displayRate.toStringAsFixed(4)} CNY' 
        : '${displayRate.toStringAsFixed(4)} USD';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$fromCurrency =',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        toCurrency,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _isUsdToCny ? AppColors.usdBlue : AppColors.cnyRed,
                        ),
                      ),
                    ],
                  ),
                ),
                RotationTransition(
                  turns: _animation,
                  child: Material(
                    color: AppColors.swapButtonColor.withOpacity(0.15),
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _toggleDirection,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.swapButtonColor.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.swap_vert,
                          size: 32,
                          color: AppColors.swapButtonColor,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  'Updated: ${rateNotifier.getFormattedLastUpdated()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                if (rateState.isLoading) ...[
                  const Spacer(),
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ]
              ],
            ),
          ],
        ),
      ),
    );
  }
}
