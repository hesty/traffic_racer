import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../game/traffic_racer_game.dart';
import '../progression/car_catalog.dart';
import '../progression/subscription.dart';
import '../services/purchase_service.dart';
import '../services/store_links.dart';
import 'car_preview.dart';
import 'ui_theme.dart';

/// Turbo Pass paywall: what the pass unlocks, the plans on sale, and the
/// buttons and links both stores require on a subscription screen.
///
/// Shown over the menu, the result screen or the garage;
/// [TrafficRacerGame.closePaywall] puts the previous one back. With no store
/// reachable it still lays out, in its "unavailable" state.
class PaywallOverlay extends StatefulWidget {
  const PaywallOverlay({super.key, required this.game});

  final TrafficRacerGame game;

  @override
  State<PaywallOverlay> createState() => _PaywallOverlayState();
}

class _PaywallOverlayState extends State<PaywallOverlay> {
  String? _pickedId;

  PurchaseService get _purchases => widget.game.progression.purchases;

  /// The plan the buy button acts on: the player's pick, else the annual plan
  /// as the better deal, else whatever the store listed first.
  SubscriptionOffer? get _selected {
    final offers = _purchases.offers;
    if (offers.isEmpty) return null;
    for (final offer in offers) {
      if (offer.id == _pickedId) return offer;
    }
    for (final offer in offers) {
      if (offer.period == PassPeriod.annual) return offer;
    }
    return offers.first;
  }

  void _buy() {
    final offer = _selected;
    if (offer == null) return;
    widget.game.buyPass(offer.id);
  }

  void _restore() {
    widget.game.restorePass();
  }

  Future<void> _open(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not open $url: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: const Color(0xF205071A),
      child: SafeArea(
        child: ListenableBuilder(
          listenable: _purchases,
          builder: (context, _) => FillOrScroll(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 14),
            child: _body(),
          ),
        ),
      ),
    );
  }

  Widget _body() {
    final offers = _purchases.offers;
    final selected = _selected;
    final busy = _purchases.busy;
    final error = _purchases.lastError;
    final savings = _purchases.annualSavings;

    return Column(
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: IconButton(
            onPressed: widget.game.closePaywall,
            iconSize: 26,
            color: Colors.white70,
            tooltip: 'Close',
            icon: const Icon(Icons.close_rounded),
          ),
        ),
        ShaderMask(
          shaderCallback: (b) => const LinearGradient(
            colors: [UiTheme.pass, UiTheme.passDark],
          ).createShader(b),
          child: Text('TURBO PASS',
              textAlign: TextAlign.center, style: UiTheme.title(32)),
        ),
        const SizedBox(height: 8),
        Text(
          _purchases.isActive
              ? 'Your pass is active. Every car below is yours to drive.'
              : '${CarCatalog.premium.length} cars nobody else on the road gets.',
          textAlign: TextAlign.center,
          style: UiTheme.label.copyWith(color: Colors.white, fontSize: 13),
        ),
        const Spacer(),
        const _PremiumCarStrip(),
        const Spacer(),
        if (_purchases.isActive)
          const _ActiveNotice()
        else if (offers.isEmpty)
          _UnavailableNotice(storeReady: _purchases.storeReady)
        else
          for (final offer in offers) ...[
            _PlanCard(
              offer: offer,
              selected: offer.id == selected?.id,
              savingsPercent:
                  offer.period == PassPeriod.annual ? savings : null,
              onTap: busy ? null : () => setState(() => _pickedId = offer.id),
            ),
            const SizedBox(height: 10),
          ],
        const SizedBox(height: 4),
        if (!_purchases.isActive) ...[
          PrimaryButton(
            label: busy ? 'PLEASE WAIT' : 'GET THE PASS',
            icon: Icons.workspace_premium_rounded,
            color: UiTheme.pass,
            foreground: Colors.white,
            onPressed: busy || selected == null ? null : _buy,
          ),
          const SizedBox(height: 8),
          Text(
            'Renews automatically until cancelled. Manage or cancel any time '
            'in your store account.',
            textAlign: TextAlign.center,
            style: UiTheme.label.copyWith(fontSize: 11, color: Colors.white54),
          ),
        ],
        if (error != null) ...[
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: UiTheme.label.copyWith(
                fontSize: 12, color: const Color(0xFFFF8A80)),
          ),
        ],
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          children: [
            if (!_purchases.isActive)
              _FooterLink(label: 'Restore', onTap: busy ? null : _restore),
            _FooterLink(
                label: 'Terms', onTap: () => _open(StoreLinks.terms)),
            _FooterLink(
                label: 'Privacy', onTap: () => _open(StoreLinks.privacy)),
          ],
        ),
      ],
    );
  }
}

/// The pass-only cars, drawn exactly as they appear on the road.
class _PremiumCarStrip extends StatelessWidget {
  const _PremiumCarStrip();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final skin in CarCatalog.premium)
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 52, child: CarPreview(skin: skin)),
                const SizedBox(height: 6),
                Text(
                  skin.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: UiTheme.label.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One selectable plan. Everything sits inside the expanded column so a long
/// price or a wide font ellipsises instead of overflowing.
class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.offer,
    required this.selected,
    required this.savingsPercent,
    required this.onTap,
  });

  final SubscriptionOffer offer;
  final bool selected;
  final int? savingsPercent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final perMonth = offer.period == PassPeriod.annual
        ? offer.pricePerMonthLabel
        : null;
    return Material(
      color: selected ? UiTheme.pass.withValues(alpha: 0.14) : UiTheme.panel,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? UiTheme.pass : Colors.white24,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 22,
                color: selected ? UiTheme.pass : Colors.white38,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            offer.periodLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: UiTheme.label.copyWith(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                        if (savingsPercent != null) ...[
                          const SizedBox(width: 8),
                          _SaveBadge(percent: savingsPercent!),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      perMonth == null
                          ? offer.priceLabel
                          : '${offer.priceLabel}  ·  $perMonth / mo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SaveBadge extends StatelessWidget {
  const _SaveBadge({required this.percent});

  final int percent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: UiTheme.pass.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text('SAVE $percent%',
          style: const TextStyle(
              color: UiTheme.pass, fontSize: 10, fontWeight: FontWeight.w900)),
    );
  }
}

class _ActiveNotice extends StatelessWidget {
  const _ActiveNotice();

  @override
  Widget build(BuildContext context) {
    return const InfoChip(
      icon: Icons.workspace_premium_rounded,
      text: 'PASS ACTIVE',
      color: UiTheme.pass,
      fontSize: 15,
    );
  }
}

/// Shown when the store has nothing to sell: no key on this build, no network,
/// or an offering that has not finished loading.
class _UnavailableNotice extends StatelessWidget {
  const _UnavailableNotice({required this.storeReady});

  final bool storeReady;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: UiTheme.panelDecoration(radius: 18),
      child: Text(
        storeReady
            ? 'Loading plans…'
            : 'The store is not available on this device.',
        textAlign: TextAlign.center,
        style: UiTheme.label.copyWith(color: Colors.white70, fontSize: 12),
      ),
    );
  }
}

class _FooterLink extends StatelessWidget {
  const _FooterLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Colors.white54,
        minimumSize: const Size(0, 36),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label,
          style: UiTheme.label.copyWith(fontSize: 11, color: Colors.white54)),
    );
  }
}
