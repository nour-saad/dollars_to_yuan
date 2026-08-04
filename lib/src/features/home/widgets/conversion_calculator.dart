import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/providers/exchange_rate_provider.dart';
import '../../../core/services/ad_service.dart';
import '../../../core/services/purchase_service.dart';

class ConversionCalculator extends ConsumerStatefulWidget {
  const ConversionCalculator({super.key});

  @override
  ConsumerState<ConversionCalculator> createState() => _ConversionCalculatorState();
}

class _ConversionCalculatorState extends ConsumerState<ConversionCalculator> {
  final TextEditingController _controller = TextEditingController();
  bool _isUsdToCny = true;
  double? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _calculate() {
    FocusScope.of(context).unfocus(); // Dismiss keyboard
    
    final text = _controller.text.replaceAll(',', '.');
    if (text.isEmpty) {
      setState(() => _result = null);
      return;
    }

    final amount = double.tryParse(text);
    if (amount == null) return;

    final rateState = ref.read(exchangeRateProvider);
    
    setState(() {
      if (_isUsdToCny) {
        _result = amount * rateState.rate;
      } else {
        _result = amount / rateState.rate;
      }
    });
    
    // Trigger an interstitial ad every few conversions
    // (premium users are exempt).
    final isPremium = ref.read(premiumStatusProvider);
    if (!isPremium) {
      ref.read(adServiceProvider).showInterstitialIfAppropriate();
    }
  }

  void _swap() {
    setState(() {
      _isUsdToCny = !_isUsdToCny;
      _result = null; // Clear result on swap or recalculate
    });
    if (_controller.text.isNotEmpty) {
      _calculate();
    }
  }

  @override
  Widget build(BuildContext context) {
    final fromLabel = _isUsdToCny ? 'USD (Dollars)' : 'CNY (Yuan)';
    final toLabel = _isUsdToCny ? 'CNY (Yuan)' : 'USD (Dollars)';
    final inputColor = _isUsdToCny ? AppColors.usdBlue : AppColors.cnyRed;
    final resultColor = _isUsdToCny ? AppColors.cnyRed : AppColors.usdBlue;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.centerRight,
              children: [
                TextField(
                  controller: _controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: inputColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    labelText: fromLabel,
                    floatingLabelBehavior: FloatingLabelBehavior.always,
                  ),
                  onSubmitted: (_) => _calculate(),
                ),
                Positioned(
                  right: 8,
                  child: Material(
                    color: AppColors.swapButtonColor.withOpacity(0.15),
                    shape: const CircleBorder(),
                    child: IconButton(
                      icon: const Icon(Icons.swap_horiz, color: AppColors.swapButtonColor),
                      onPressed: _swap,
                      tooltip: 'Swap Currencies',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: _calculate,
                child: Text(
                  'Convert to $toLabel',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            if (_result != null) ...[
              const SizedBox(height: 32),
              Text(
                '${_controller.text} ${_isUsdToCny ? "USD" : "CNY"} =',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_result!.toStringAsFixed(2)} ${_isUsdToCny ? "CNY" : "USD"}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: resultColor,
                ),
                textAlign: TextAlign.center,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
