import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class RegistrationLinkService {
  const RegistrationLinkService();

  static const String _defaultBaseUrl = 'https://worldscore-ai.web.app';

  String buildRegistrationLink({
    required String slug,
    String? configuredBaseUrl,
  }) {
    final fromDefine = const String.fromEnvironment('PUBLIC_APP_BASE_URL');
    final baseUrl = configuredBaseUrl ??
        (fromDefine.isNotEmpty ? fromDefine : _defaultBaseUrl);
    final uri = Uri.parse(baseUrl);
    return uri
        .replace(pathSegments: <String>['tournaments', slug, 'register'])
        .toString();
  }

  Future<void> copyToClipboard(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
  }

  @visibleForTesting
  String get defaultBaseUrl => _defaultBaseUrl;
}
