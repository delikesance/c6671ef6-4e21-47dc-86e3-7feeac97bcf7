part of 'home.dart';

extension _AppHomePageAds on _AppHomePageState {
  Future<void> _addRuntimeTime() async {
    if (_isAddingTime || _botStarting) {
      return;
    }

    final botId = widget.client.user.id.toString();
    final previousBalance = _freeMinutesBalance;
    _setState(() {
      _isAddingTime = true;
    });

    try {
      final app = await appManager.getApp(botId);
      final botToken = (app['token'] ?? '').toString().trim();

      final unlocked = await _maybeOfferRewardedAd(
        botId: botId,
        botToken: botToken.isNotEmpty ? botToken : null,
        previousBalance: previousBalance,
        force: true,
        successMessage: context.tr.home_time_added,
      );
      if (!unlocked) {
        if (mounted) {
          _setState(() {
            _freeMinutesBalance = previousBalance;
          });
        }
        return;
      }

      final rewardCredited = await _waitForMainApiRewardCredit(
        botId: botId,
        previousBalance: previousBalance,
      );
      await _refreshFreeRuntimeBalance();

      if (!rewardCredited && mounted) {
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(context.tr.rewarded_credit_syncing_title),
            content: Text(context.tr.rewarded_credit_syncing_message),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: Text(context.tr.common_ok),
              ),
            ],
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr.error_with_details(error.toString())),
          ),
        );
      }
    } finally {
      _setState(() {
        _isAddingTime = false;
      });
    }
  }

  Future<bool> _maybeOfferRewardedAd({
    required String botId,
    String? botToken,
    int? previousBalance,
    bool force = false,
    String? successMessage,
  }) async {
    try {
      if (!_supportsForegroundTask || !mounted) {
        return true;
      }

      final isPremium = await _isMainApiPremiumUser(
        botId: botId,
        botToken: botToken,
      );
      if (isPremium) {
        return true;
      }

      if (!force && _displayFreeMinutesBalance() > 0) {
        return true;
      }

      try {
        final remoteRuntime = await _resolveRemoteRuntime(
          getTimeout: const Duration(seconds: 4),
        );
        final remoteClient = remoteRuntime.client;
        if (remoteClient is MainApiClient) {
          final runtime = await remoteClient
              .getBotRuntime(botId)
              .timeout(const Duration(seconds: 4));
          final funding =
              (runtime['funding_mode'] ?? runtime['fundingMode'] ?? '')
                  .toString()
                  .trim()
                  .toLowerCase();
          final expires = _extractSessionExpiresAt(runtime);
          final balance = funding == 'premium'
              ? 0
              : (expires != null && funding == 'free'
                    ? _remainingMinutesUntil(expires)
                    : _extractFreeMinutes(
                        runtime['free_minutes_balance'] ??
                            runtime['freeMinutesBalance'],
                      ));

          _setState(() {
            _fundingMode = funding;
            _sessionExpiresAt = funding == 'free' ? expires : null;
            _freeMinutesBalance = balance;
          });

          if (!force && _hasFreeRuntimeAvailable(runtime, balance)) {
            return true;
          }
        }
      } catch (_) {}

      if (!AdRewardService.hasReadyRewardedAd) {
        final loaded = await AdRewardService.ensureAdLoaded(
          timeout: const Duration(seconds: 4),
        );
        if (!loaded) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.tr.error_with_details(
                    context.tr.rewarded_start_no_ad_available,
                  ),
                ),
              ),
            );
          }
          return false;
        }
      }

      final snapshotReady = await _ensureMainApiBotSnapshotForAd(
        botId,
      ).timeout(const Duration(seconds: 4), onTimeout: () => false);
      if (!snapshotReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr.ad_sync_config_failed,
              ),
            ),
          );
        }
        return false;
      }

      final ssvContext = await _buildMainApiAdSsvContext(
        botId,
      ).timeout(const Duration(seconds: 4), onTimeout: () => null);
      if (ssvContext == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr.ad_context_failed,
              ),
            ),
          );
        }
        return false;
      }

      final shouldOffer = await AdRewardService.shouldOfferRewardedAd(
        checkPremiumCapability: false,
      ).timeout(const Duration(seconds: 2), onTimeout: () => false);
      if (!shouldOffer) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr.ad_limit_or_cooldown,
              ),
            ),
          );
        }
        return false;
      }

      final consentGranted = await _ensureAdsConsent().timeout(
        const Duration(seconds: 4),
        onTimeout: () => false,
      );
      if (!consentGranted && kReleaseMode) {
        return false;
      }
      if (!mounted) {
        return false;
      }

      final effectivePreviousBalance =
          previousBalance ??
          await _fetchMainApiRuntimeBalance(
            botId,
          ).timeout(const Duration(seconds: 4), onTimeout: () => 0);

      var rewardEarned = false;
      final adShown = await AdRewardService.showRewardedAd(
        ssvContext: ssvContext,
        onRewardEarned: () async {
          rewardEarned = true;
        },
      );
      if (!adShown || !rewardEarned) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.tr.error_with_details(
                  context.tr.rewarded_start_complete_ad,
                ),
              ),
            ),
          );
        }
        return false;
      }

      unawaited(() async {
        final rewardCredited = await _waitForMainApiRewardCredit(
          botId: botId,
          previousBalance: effectivePreviousBalance,
        );
        if (!rewardCredited) return;
        await _refreshFreeRuntimeBalance();
      }());

      await SubscriptionService.resolveEffectivePremiumStatus(
        forceRefresh: true,
      ).timeout(const Duration(seconds: 4), onTimeout: () => false);

      if (!mounted) {
        return false;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage ?? context.tr.rewarded_start_thanks),
        ),
      );
      return true;
    } catch (error) {
      appendBotDebugLog('Rewarded ad flow skipped due to error: $error');
      return false;
    }
  }

  Future<bool> _isMainApiPremiumUser({
    required String botId,
    String? botToken,
  }) async {
    try {
      final remoteClient = await _resolveMainApiClientForBot(
        botId: botId,
        botToken: botToken,
        attemptSessionRestore: true,
      ).timeout(const Duration(seconds: 4), onTimeout: () => null);

      return await SubscriptionService.canSkipRewardedAdsWithTimeout(
        client: remoteClient is MainApiClient ? remoteClient : null,
        forceRefresh: true,
        allowStoredManagerSession: false,
      );
    } catch (_) {
      return false;
    }
  }

  Future<bool> _ensureMainApiBotSnapshotForAd(String botId) async {
    final app = await appManager.getApp(botId);
    final botToken = (app['token'] ?? '').toString().trim();
    if (botToken.isEmpty) return false;

    final remoteClient = await _resolveMainApiClientForBot(
      botId: botId,
      botToken: botToken,
      attemptSessionRestore: true,
    );
    if (remoteClient == null) return false;

    final payload = await buildRemotePayload(botId);
    try {
      await remoteClient.saveDiscordBotSnapshot(
        botId: botId,
        botToken: botToken,
        config: payload,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Contexte SSV du flux « bot » — construction partagée avec l'accueil
  /// (`ad_ssv_context.dart`). Ici le propriétaire est résolu via la session
  /// Manager ET les métadonnées Discord de l'application, d'où
  /// `discord_owner_id` en plus ; l'accueil, lui, s'en tient à la session.
  Future<AdRewardSsvContext?> _buildMainApiAdSsvContext(String botId) {
    return buildMainApiAdSsvContext(
      botId: botId,
      resolveOwnerIds: () async {
        final app = await appManager.getApp(botId);
        final botToken = (app['token'] ?? '').toString().trim();
        if (botToken.isEmpty) return null;

        final session = await MainApiSettingsStore.loadSession();
        final ownerIdFromSession = (session?.userId ?? '').trim();
        final ownerMetadata = await getDiscordApplicationOwnerMetadata(botToken);

        final ownerId =
            ownerMetadata?.resolveOwnerId(
              preferredOwnerId: ownerIdFromSession,
            ) ??
            ownerIdFromSession;
        if (ownerId.isEmpty) return null;

        return BotAdSsvOwnerIds(
          ownerId: ownerId,
          discordOwnerId: ownerMetadata?.resolveOwnerId() ?? '',
        );
      },
    );
  }

  Future<bool> _ensureAdsConsent() async {
    final consentGranted = await AdConsentService.ensureCanRequestAds();
    if (!consentGranted && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr.ads_consent_refused_info)),
      );
    }
    return consentGranted;
  }
}
