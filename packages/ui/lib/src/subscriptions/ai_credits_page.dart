import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:reicon_flutter/reicon_flutter.dart';

import '../copilot/ai_credit_format.dart';
import '../l10n/tr_extension.dart';
import '../theme/app_theme.dart';
import '../widgets/app_icon.dart';
import 'ai_credits_host.dart';

/// L'écran « Crédits IA » : solde, répartition, packs, roulette et historique.
/// Partagé entre l'app et le Studio ; la roulette, les publicités et l'achat de
/// packs sont des capacités de l'[AiCreditsHost] (l'écran masque ce qui manque).
class AICreditsPage extends StatefulWidget {
  const AICreditsPage({required this.host, super.key});

  final AiCreditsHost host;

  @override
  State<AICreditsPage> createState() => _AICreditsPageState();
}

class _AICreditsPageState extends State<AICreditsPage> {
  Map<String, dynamic>? _wallet;
  String? _error;
  String? _pendingSpinKey;
  Map<String, dynamic>? _result;
  bool _busy = false;
  double _turns = 0;
  List<Map<String, dynamic>> _ledger = [];
  int _offset = 0;
  bool _more = false;
  List<AiCreditsPack> _packs = const [];
  String? _packNotice;
  StreamSubscription<AiCreditsPackEvent>? _packEvents;

  AiCreditsHost get _host => widget.host;

  /// L'appareil fait-il tourner la roulette et diffuse-t-il des publicités ?
  bool get _mobile => _host.rewardsPlatform != null;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
    unawaited(_loadPacks());
    _packEvents = _host.packEvents.listen((event) {
      if (!mounted) return;
      switch (event) {
        case AiCreditsPackEvent.credited:
          setState(() => _packNotice = context.tr.ai_credits_pack_credited);
          unawaited(_load());
        case AiCreditsPackEvent.failed:
          setState(() => _packNotice = context.tr.ai_credits_pack_failed);
        case AiCreditsPackEvent.pending:
          setState(() => _packNotice = context.tr.ai_credits_pack_pending);
      }
    });
  }

  @override
  void dispose() {
    unawaited(_packEvents?.cancel());
    super.dispose();
  }

  Future<void> _loadPacks() async {
    try {
      final packs = await _host.loadPacks(
        Localizations.localeOf(context).toString(),
      );
      if (mounted) setState(() => _packs = packs);
    } catch (_) {
      // Pas de pack affiche plutot qu'un ecran en erreur : le reste de la page
      // (solde, roulette) reste utilisable.
    }
  }

  Future<void> _buyPack(AiCreditsPack pack) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _packNotice = null;
    });
    try {
      final started = await _host.buyPack(pack);
      if (!started && mounted) {
        setState(() => _packNotice = context.tr.ai_credits_pack_failed);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _packNotice = context.tr.ai_credits_pack_failed);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _packsSection() {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr.ai_credits_packs_title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        for (final pack in _packs)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.homeCard,
              border: Border.all(color: AppTheme.homeCardBorder),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pack.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (pack.credits > 0)
                        Text(
                          _credits(pack.credits),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _busy ? null : () => _buyPack(pack),
                  child: Text(pack.price),
                ),
              ],
            ),
          ),
        if (_packNotice != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _packNotice!,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
            ),
          ),
      ],
    );
  }

  Future<void> _load() async {
    try {
      final wallet = await _host.wallet();
      await _loadLedger();
      if (mounted) {
        setState(() {
          _wallet = wallet;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.tr.ai_credits_unavailable);
      }
    }
  }

  Future<void> _loadLedger() async {
    final d = await _host.ledger(offset: _offset);
    if (mounted) {
      setState(() {
        _ledger = (d['entries'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        _more = d['has_more'] == true;
      });
    }
  }

  String _origin(BuildContext context, String source) => switch (source) {
    'kofi' => context.tr.ai_credits_origin_kofi,
    'apple' => context.tr.ai_credits_origin_apple,
    'google' => context.tr.ai_credits_origin_google,
    'roulette' => context.tr.ai_credits_origin_roulette,
    'admin_grant' => context.tr.ai_credits_origin_admin_grant,
    'admin_correction' => context.tr.ai_credits_origin_admin_correction,
    'copilot' => context.tr.ai_credits_origin_copilot,
    _ => source,
  };

  Future<void> _ad() async {
    if (!_mobile || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      switch (await _host.watchRewardAd()) {
        case AiRewardAdOutcome.credited:
          await _load();
        case AiRewardAdOutcome.abandoned:
          break;
        case AiRewardAdOutcome.pending:
          if (mounted) {
            setState(() => _error = context.tr.ai_credits_ad_pending);
          }
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = context.tr.ai_credits_ad_unavailable);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  Future<void> _spin(List<Map<String, dynamic>> prizes) async {
    if (!_mobile || _busy) {
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    _pendingSpinKey ??= _newSpinKey();
    try {
      final result = await _host.spin(_pendingSpinKey!);
      final index = prizes.indexWhere(
        (p) =>
            (p['credits'] ?? 0) == result['credits'] &&
            (p['bonus_spins'] ?? 0) == result['bonus_spins'],
      );
      if (mounted) {
        setState(
          () => _turns =
              _turns.floor() +
              6 -
              (math.max(0, index) + .5) / math.max(1, prizes.length),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 4400));
      _pendingSpinKey = null;
      if (mounted) {
        setState(() => _result = result);
      }
      await _load();
    } catch (_) {
      // Reuse the key on retry: an ambiguous network failure must never consume two spins.
      if (mounted) {
        setState(() => _error = context.tr.ai_credits_spin_failed);
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  /// Clé d'idempotence d'un tour (UUID v4) : rejouée tant que le tour n'a pas
  /// abouti.
  String _newSpinKey() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    String hex(int from, int to) => bytes
        .sublist(from, to)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex(0, 4)}-${hex(4, 6)}-${hex(6, 8)}-${hex(8, 10)}-${hex(10, 16)}';
  }

  String _credits(Object? value) => formatAiCredits(
    value,
    locale: Localizations.localeOf(context).toString(),
  );

  /// "Today, 23:02" / "Yesterday, 23:02" / "4 Oct, 23:02" in the user's timezone.
  String _when(Object? raw) {
    final parsed = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (parsed == null) return raw?.toString() ?? '';
    final tr = context.tr;
    final locale = Localizations.localeOf(context);
    final now = DateTime.now();
    final day = DateTime(parsed.year, parsed.month, parsed.day);
    final today = DateTime(now.year, now.month, now.day);
    final time = DateFormat.Hm(locale.toString()).format(parsed);
    final diff = today.difference(day).inDays;
    if (diff == 0) return tr.ai_credits_when_today(time);
    if (diff == 1) return tr.ai_credits_when_yesterday(time);
    final date = parsed.year == now.year
        ? DateFormat.MMMd(locale.toString())
        : DateFormat.yMMMd(locale.toString());
    return '${date.format(parsed)}, $time';
  }

  Widget _balanceCard() {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1A2E), AppTheme.homeCard],
          stops: [0, .7],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: AppTheme.homeClusterBorder),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr.ai_credits_wallet_card_title,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppTheme.homeMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppTheme.actionViolet.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: AppIcon(
                    Reicon.outline.coin,
                    size: 30,
                    color: AppTheme.actionVioletSoft,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _credits(_wallet!['available'] ?? _wallet!['balance']),
                    maxLines: 1,
                    style: Theme.of(context).textTheme.displayMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1.5,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
          if (((_wallet!['reserved'] as num?) ?? 0) > 0) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppTheme.actionVioletSoft,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.actionVioletSoft.withValues(alpha: .2),
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    context.tr.ai_credits_reserved(
                      _credits(_wallet!['reserved']),
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (_wallet!['blocked'] == true) ...[
            const SizedBox(height: 18),
            Row(
              children: [
                AppIcon.fromMaterial(
                  Icons.pause_circle_outline_rounded,
                  size: 17,
                  color: colors.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr.ai_credits_spending_blocked,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: colors.error),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final config = _wallet?['roulette'] as Map? ?? const {};
    final mobile = _mobile;
    final prizes = (mobile ? config['prizes'] as List? ?? const [] : const [])
        .whereType<Map>()
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    final spins = (_wallet?['spins'] as num? ?? 0).toInt();
    final remaining = (_wallet?['remaining_ads'] as num? ?? 0).toInt();
    final adUnits = config['ad_units'] as Map? ?? const {};
    final platform = _host.rewardsPlatform;
    final supportsAds =
        platform != null &&
        config['enabled'] == true &&
        ((adUnits[platform] ?? config['ad_unit'] ?? '').toString().isNotEmpty);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr.ai_credits_title),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const AppIcon.fromMaterial(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
          children: [
            if (_wallet == null && _error == null)
              const Center(child: CircularProgressIndicator()),
            if (_wallet != null) ...[
              _balanceCard(),
              const SizedBox(height: 18),
              Row(
                children: [
                  for (final (index, item) in [
                    (
                      Reicon.outline.bag,
                      context.tr.ai_credits_label_purchased,
                      _wallet!['purchased'],
                    ),
                    (
                      Reicon.outline.wheel,
                      context.tr.ai_credits_label_rewarded,
                      _wallet!['rewarded'],
                    ),
                    (
                      Reicon.outline.gift,
                      context.tr.ai_credits_label_granted,
                      _wallet!['granted'],
                    ),
                  ].indexed) ...[
                    if (index > 0) const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(12, 12, 12, 13),
                        decoration: BoxDecoration(
                          color: AppTheme.homeCard,
                          border: Border.all(color: AppTheme.homeCardBorder),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                AppIcon(
                                  item.$1,
                                  size: 15,
                                  color: AppTheme.actionVioletSoft,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    item.$2,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppTheme.homeMuted,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                _credits(item.$3),
                                maxLines: 1,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.homeCard,
                  border: Border.all(color: AppTheme.homeCardBorder),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (mobile)
                      Text(
                        context.tr.ai_credits_spins_available(spins),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    if (mobile) const SizedBox(height: 6),
                    Text(
                      context.tr.ai_credits_usage_hint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (mobile)
                      Text(
                        context.tr.ai_credits_daily_ad_limit_hint,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (_packs.isNotEmpty) ...[
                const SizedBox(height: 28),
                _packsSection(),
              ],
              const SizedBox(height: 28),
              if (prizes.isNotEmpty)
                Center(
                  child: SizedBox(
                    width: 350,
                    height: 366,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 40,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.actionViolet.withValues(
                                    alpha: .12,
                                  ),
                                  blurRadius: 56,
                                ),
                              ],
                            ),
                            child: const SizedBox(width: 320, height: 320),
                          ),
                        ),
                        Positioned(
                          top: 40,
                          child: AnimatedRotation(
                            turns: _turns,
                            duration: const Duration(milliseconds: 4400),
                            curve: const Cubic(.12, .72, .08, 1),
                            child: CustomPaint(
                              size: const Size(320, 320),
                              painter: _RoulettePainter(
                                prizes,
                                Localizations.localeOf(context).toString(),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: 40 + 160 - 28,
                          child: Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.scaffoldDark,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppTheme.actionViolet,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: AppIcon(
                                Reicon.outline.coin,
                                size: 24,
                                color: AppTheme.actionVioletSoft,
                              ),
                            ),
                          ),
                        ),
                        const Positioned(top: 4, child: _WheelPointer()),
                      ],
                    ),
                  ),
                ),
              if (_result != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.homeCard,
                    border: Border.all(color: AppTheme.homeGhostBorder),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      AppIcon(
                        Reicon.outline.coin,
                        size: 26,
                        color: AppTheme.actionVioletSoft,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          (_result!['bonus_spins'] as num) > 0
                              ? context.tr.ai_credits_result_spins(
                                  (_result!['bonus_spins'] as num).toInt(),
                                )
                              : context.tr.ai_credits_result_credits(
                                  _credits(_result!['credits']),
                                ),
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              if (mobile)
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppTheme.actionViolet,
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const AppIcon.fromMaterial(Icons.casino_outlined),
                  onPressed:
                      _busy ||
                          (spins <= 0 && _pendingSpinKey == null) ||
                          prizes.isEmpty
                      ? null
                      : () => _spin(prizes),
                  label: Text(context.tr.ai_credits_button_spin),
                ),
              if (mobile) const SizedBox(height: 14),
              if (mobile)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.homeGhostBorder),
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const AppIcon.fromMaterial(
                    Icons.play_circle_outline_rounded,
                  ),
                  onPressed: _busy || !supportsAds || remaining <= 0
                      ? null
                      : _ad,
                  label: Text(context.tr.ai_credits_button_watch_ad(remaining)),
                ),
              if (_busy) const Center(child: CircularProgressIndicator()),
            ],
            if (_wallet != null) ...[
              const SizedBox(height: 28),
              Text(
                context.tr.ai_credits_history_title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              if (_ledger.isEmpty) Text(context.tr.ai_credits_history_empty),
              for (final e in _ledger)
                DecoratedBox(
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF1B1E26)),
                    ),
                  ),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    shape: const Border(),
                    collapsedShape: const Border(),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: (e['delta'] as num) > 0
                            ? AppTheme.statusOnline.withValues(alpha: .12)
                            : AppTheme.homeMuted.withValues(alpha: .1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: AppIcon(
                          Reicon.outline.coin,
                          size: 20,
                          color: (e['delta'] as num) > 0
                              ? AppTheme.statusOnline
                              : AppTheme.homeMuted,
                        ),
                      ),
                    ),
                    title: Text(
                      _origin(context, e['source'] as String),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      _when(e['created_at']),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.homeMuted,
                      ),
                    ),
                    trailing: Text(
                      '${(e['delta'] as num) > 0 ? '+' : ''}${_credits(e['delta']).replaceFirst('-', '−')}',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: (e['delta'] as num) > 0
                            ? AppTheme.statusOnline
                            : null,
                      ),
                    ),
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: SelectableText(
                          '${context.tr.ai_credits_reference} : ${e['reference']}',
                        ),
                      ),
                      if ((e['reason'] ?? '') != '')
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(e['reason'] as String),
                        ),
                      if (_host.canOpenConversation &&
                          (e['conversation_id'] ?? '') != '')
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton(
                            onPressed: () => _host.openConversation(
                              context,
                              e['conversation_id'] as String,
                            ),
                            child: Text(
                              context.tr.ai_credits_open_conversation,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              if (_offset > 0 || _more)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _offset == 0
                          ? null
                          : () async {
                              _offset = (_offset - 50).clamp(0, 1 << 30);
                              await _loadLedger();
                            },
                      child: Text(context.tr.ai_credits_previous),
                    ),
                    TextButton(
                      onPressed: !_more
                          ? null
                          : () async {
                              _offset += 50;
                              await _loadLedger();
                            },
                      child: Text(context.tr.ai_credits_next),
                    ),
                  ],
                ),
            ],
            if (_error != null)
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}

class _WheelPointer extends StatelessWidget {
  const _WheelPointer();
  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: const Size(44, 58), painter: _PointerPainter());
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width / 44, h = size.height / 58;
    final path = Path()
      ..moveTo(22 * w, 56 * h)
      ..lineTo(5 * w, 20 * h)
      ..quadraticBezierTo(22 * w, -4 * h, 39 * w, 20 * h)
      ..close();
    canvas.drawPath(path, Paint()..color = AppTheme.actionVioletSoft);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeJoin = StrokeJoin.round
        ..color = AppTheme.scaffoldDark,
    );
    canvas.drawCircle(
      Offset(22 * w, 21 * h),
      6,
      Paint()..color = AppTheme.scaffoldDark,
    );
    canvas.drawCircle(
      Offset(22 * w, 21 * h),
      2.5,
      Paint()..color = AppTheme.actionVioletSoft,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) => false;
}

class _RoulettePainter extends CustomPainter {
  _RoulettePainter(this.prizes, this.locale);
  final List<Map<String, dynamic>> prizes;
  final String locale;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outer = size.width / 2;
    final radius = outer * .8;
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = 2 * math.pi / prizes.length;
    // Thin flat ring, like the app's cards.
    canvas.drawCircle(
      center,
      outer - 4,
      Paint()..color = AppTheme.homeContainerLowest,
    );
    canvas.drawCircle(
      center,
      outer - 4,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppTheme.homeGhostBorder,
    );
    for (var i = 0; i < prizes.length; i++) {
      final angle = -math.pi / 2 + i * sweep;
      final isSpin = prizes[i]['kind'] == 'spins';
      final edge = i % 2 == 0
          ? const Color(0xFF1D2029)
          : const Color(0xFF252935);
      canvas.drawArc(
        rect,
        angle,
        sweep,
        true,
        Paint()
          ..shader = RadialGradient(
            colors: isSpin
                ? [const Color(0xFF5B3FD0), AppTheme.actionViolet]
                : [const Color(0xFF0F1116), edge],
            stops: const [.2, 1],
          ).createShader(rect),
      );
    }
    // Separators.
    for (var i = 0; i < prizes.length; i++) {
      final angle = -math.pi / 2 + i * sweep;
      canvas.drawLine(
        center,
        center + Offset(math.cos(angle), math.sin(angle)) * radius,
        Paint()
          ..strokeWidth = 2
          ..color = AppTheme.homeContainerLowest,
      );
    }
    for (var i = 0; i < prizes.length; i++) {
      final angle = -math.pi / 2 + i * sweep;
      final prize = prizes[i];
      final isSpin = prize['kind'] == 'spins';
      final label = isSpin
          ? '+${prize['bonus_spins']} ↻'
          : formatAiCredits(prize['credits'], locale: locale);
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: TextStyle(
            color: isSpin ? Colors.white : AppTheme.dataAccent,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final mid = angle + sweep / 2;
      canvas.save();
      canvas.translate(
        center.dx + math.cos(mid) * radius * .69,
        center.dy + math.sin(mid) * radius * .69,
      );
      // Read along the radius, flipped on the left half so it is never upside down.
      canvas.rotate(math.cos(mid) < 0 ? mid + math.pi : mid);
      text.paint(canvas, Offset(-text.width / 2, -text.height / 2));
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_RoulettePainter oldDelegate) =>
      oldDelegate.prizes != prizes || oldDelegate.locale != locale;
}
