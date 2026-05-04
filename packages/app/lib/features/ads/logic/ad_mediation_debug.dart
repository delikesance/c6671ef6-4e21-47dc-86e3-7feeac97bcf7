import 'dart:async';

import 'package:bot_creator/core/diagnostics/app_diagnostics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdMediationDebug {
  AdMediationDebug._();

  static Future<void> logInitializationStatus() async {
    try {
      final status = await MobileAds.instance.initialize();
      final adapterStatuses = status.adapterStatuses;
      final allEntries = adapterStatuses.entries
          .map(
            (entry) => {
              'adapter': entry.key,
              'state': entry.value.state.name,
              'description': entry.value.description,
              'latencyMs': entry.value.latency,
            },
          )
          .toList(growable: false);

      unawaited(
        AppDiagnostics.logInfo(
          'Mobile Ads mediation init status',
          data: {
            'adapterCount': adapterStatuses.length,
            'allAdapters': allEntries,
          },
        ),
      );
    } catch (error, stack) {
      unawaited(
        AppDiagnostics.logError(
          'Failed to read mediation initialization status',
          error,
          stack,
          fatal: false,
        ),
      );
    }
  }

  static Future<void> openAdInspector() async {
    final completer = Completer<void>();

    MobileAds.instance.openAdInspector((error) {
      if (error != null) {
        unawaited(
          AppDiagnostics.logInfo(
            'Ad Inspector closed with error',
            data: {
              'code': error.code,
              'domain': error.domain,
              'message': error.message,
            },
          ),
        );
      } else {
        unawaited(AppDiagnostics.logInfo('Ad Inspector closed successfully'));
      }
      completer.complete();
    });

    return completer.future;
  }

  static void logResponseInfo({
    required String format,
    required String placement,
    required ResponseInfo? responseInfo,
  }) {
    final info = responseInfo;
    final adapters =
        info?.adapterResponses
            ?.map(
              (entry) => {
                'adapterClassName': entry.adapterClassName,
                'sourceName': entry.adSourceName,
                'sourceInstance': entry.adSourceInstanceName,
                'latencyMs': entry.latencyMillis,
                'errorCode': entry.adError?.code,
              },
            )
            .toList(growable: false) ??
        const <Map<String, dynamic>>[];

    unawaited(
      AppDiagnostics.logInfo(
        'Ad response info',
        data: {
          'format': format,
          'placement': placement,
          'responseId': info?.responseId,
          'mediationAdapterClassName': info?.mediationAdapterClassName,
          'loadedAdapterClassName':
              info?.loadedAdapterResponseInfo?.adapterClassName,
          'loadedSourceName': info?.loadedAdapterResponseInfo?.adSourceName,
          'adapterResponses': adapters,
        },
      ),
    );
  }
}
