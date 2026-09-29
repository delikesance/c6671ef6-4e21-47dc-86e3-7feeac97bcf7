import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:bot_creator/core/network/main_api_client.dart';
import 'package:bot_creator/core/network/main_api_settings.dart';
import 'package:bot_creator/features/subscriptions/logic/ai_reward_ad.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class AICreditsPage extends StatefulWidget {
  const AICreditsPage({super.key});
  @override
  State<AICreditsPage> createState() => _AICreditsPageState();
}

class _AICreditsPageState extends State<AICreditsPage> {
  MainApiClient? _client;
  String? _owner;
  Map<String, dynamic>? _wallet;
  String? _error;
  String? _pendingSpinKey;
  Map<String, dynamic>? _result;
  bool _busy = false;
  double _turns = 0;

  String _text(String fr, String en) =>
      Localizations.localeOf(context).languageCode == 'fr' ? fr : en;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final config = await MainApiSettingsStore.loadConfig();
      final session = await MainApiSettingsStore.loadSession();
      if (!config.isConfigured ||
          session == null ||
          session.isExpired ||
          session.userId == null) {
        throw StateError('Sign in to your Bot Creator account');
      }
      _client = MainApiClient(
        baseUrl: config.baseUrl,
        accessToken: session.accessToken,
      );
      _owner = session.userId;
      final wallet = await _client!.getAIWallet();
      if (mounted) {
        setState(() {
          _wallet = wallet;
          _error = null;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _text(
            'Crédits IA indisponibles. Réessayez.',
            'AI credits unavailable. Try again.',
          ),
        );
      }
    }
  }

  Future<void> _ad() async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_busy || _client == null || _owner == null) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final ticket = await _client!.createAIRewardTicket(
        Platform.isIOS ? 'ios' : 'android',
      );
      final id = ticket['id'] as String;
      final completed = await showAIRewardAd(
        adUnit: ticket['ad_unit'] as String,
        owner: _owner!,
        ticket: id,
      );
      if (!completed) return;
      for (var attempt = 0; attempt < 20; attempt++) {
        final state = await _client!.getAIRewardTicket(id);
        if ((state['spins'] as num? ?? 0) > 0) {
          await _load();
          return;
        }
        if (!mounted) return;
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      if (mounted) {
        setState(
          () => _error = _text(
            'Validation de la publicité en attente. Actualisez le solde.',
            'Ad verification pending. Refresh your balance.',
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = _text(
            'Publicité indisponible ou non validée.',
            'Ad unavailable or not verified.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _spin(List<Map<String, dynamic>> prizes) async {
    if (!Platform.isAndroid && !Platform.isIOS) return;
    if (_busy || _client == null) return;
    setState(() {
      _busy = true;
      _error = null;
      _result = null;
    });
    _pendingSpinKey ??= const Uuid().v4();
    try {
      final result = await _client!.spinAIRoulette(_pendingSpinKey!);
      final index = prizes.indexWhere(
        (p) =>
            (p['credits'] ?? 0) == result['credits'] &&
            (p['bonus_spins'] ?? 0) == result['bonus_spins'],
      );
      if (mounted) {
        setState(
          () => _turns =
              _turns.floor() +
              5 -
              (math.max(0, index) + .5) / math.max(1, prizes.length),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 2400));
      _pendingSpinKey = null;
      if (mounted) setState(() => _result = result);
      await _load();
    } catch (_) {
      // Reuse the key on retry: an ambiguous network failure must never consume two spins.
      if (mounted) {
        setState(
          () => _error = _text(
            'Résultat indisponible. Réessayez pour récupérer ce tour.',
            'Result unavailable. Retry to recover this spin.',
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = _wallet?['roulette'] as Map? ?? const {};
    final mobile = Platform.isAndroid || Platform.isIOS;
    final prizes = (mobile ? config['prizes'] as List? ?? const [] : const [])
        .whereType<Map>()
        .map((p) => Map<String, dynamic>.from(p))
        .toList();
    final spins = (_wallet?['spins'] as num? ?? 0).toInt();
    final remaining = (_wallet?['remaining_ads'] as num? ?? 0).toInt();
    final adUnits = config['ad_units'] as Map? ?? const {};
    final platform = Platform.isIOS ? 'ios' : 'android';
    final supportsAds =
        (Platform.isIOS || Platform.isAndroid) &&
        config['enabled'] == true &&
        ((adUnits[platform] ?? config['ad_unit'] ?? '').toString().isNotEmpty);
    final totalWeight = prizes.fold<num>(
      0,
      (sum, p) => sum + (p['weight'] as num? ?? 0),
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(_text('Crédits IA', 'AI credits')),
        actions: [
          IconButton(
            onPressed: _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          if (_wallet == null && _error == null)
            const Center(child: CircularProgressIndicator()),
          if (_wallet != null) ...[
            Text(
              '${_wallet!['available'] ?? _wallet!['balance']} ${_text('tokens IA disponibles', 'AI tokens available')}',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (mobile)
              Text('$spins ${_text('tours disponibles', 'available spins')}'),
            Text(
              _text(
                '1 crédit IA = 1 token utilisable.',
                '1 AI credit = 1 usable token.',
              ),
            ),
            if (mobile)
              Text(
                _text(
                  '3 publicités maximum par jour (UTC). Les tours bonus et inutilisés sont conservés.',
                  'Up to 3 ads per day (UTC). Bonus and unused spins are kept.',
                ),
              ),
            const SizedBox(height: 24),
            if (prizes.isNotEmpty)
              Center(
                child: SizedBox(
                  width: 260,
                  height: 280,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      AnimatedRotation(
                        turns: _turns,
                        duration: const Duration(milliseconds: 2400),
                        curve: Curves.easeOutCubic,
                        child: CustomPaint(
                          size: const Size(260, 260),
                          painter: _RoulettePainter(prizes),
                        ),
                      ),
                      const Positioned(
                        top: 0,
                        child: Icon(Icons.arrow_drop_down, size: 40),
                      ),
                    ],
                  ),
                ),
              ),
            if (_result != null)
              Text(
                (_result!['bonus_spins'] as num) > 0
                    ? '+${_result!['bonus_spins']} ${_text('tours !', 'spins!')}'
                    : '+${_result!['credits']} ${_text('crédits !', 'credits!')}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            if (mobile)
              FilledButton(
                onPressed:
                    _busy ||
                        (spins <= 0 && _pendingSpinKey == null) ||
                        prizes.isEmpty
                    ? null
                    : () => _spin(prizes),
                child: Text(_text('Tourner la roulette', 'Spin the wheel')),
              ),
            if (mobile)
              OutlinedButton(
                onPressed: _busy || !supportsAds || remaining <= 0 ? null : _ad,
                child: Text(
                  _text(
                    'Regarder une publicité (+1 tour) — $remaining restantes',
                    'Watch an ad (+1 spin) — $remaining left',
                  ),
                ),
              ),
            if (_busy) const Center(child: CircularProgressIndicator()),
            for (final prize in prizes)
              Text(
                '${prize['kind'] == 'spins' ? '+${prize['bonus_spins']} ${_text('tours', 'spins')}' : '${prize['credits']} ${_text('crédits', 'credits')}'} : ${totalWeight > 0 ? ((prize['weight'] as num) * 100 / totalWeight).toStringAsFixed(2) : '0'} %',
              ),
          ],
          if (_error != null)
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

class _RoulettePainter extends CustomPainter {
  _RoulettePainter(this.prizes);
  final List<Map<String, dynamic>> prizes;
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final sweep = 2 * math.pi / prizes.length;
    for (var i = 0; i < prizes.length; i++) {
      final angle = -math.pi / 2 + i * sweep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        sweep,
        true,
        Paint()..color = Colors.primaries[i % Colors.primaries.length].shade700,
      );
      final prize = prizes[i];
      final label = prize['kind'] == 'spins'
          ? '+${prize['bonus_spins']} ↻'
          : '${prize['credits']}';
      final text = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      final position =
          center +
          Offset(math.cos(angle + sweep / 2), math.sin(angle + sweep / 2)) *
              radius *
              .65;
      text.paint(canvas, position - Offset(text.width / 2, text.height / 2));
    }
  }

  @override
  bool shouldRepaint(_RoulettePainter oldDelegate) =>
      oldDelegate.prizes != prizes;
}
