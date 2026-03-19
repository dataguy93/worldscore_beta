import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../models/ocr_scorecard_response.dart';

class OcrService {
  static final Uri _ocrServiceUri = Uri.parse(
    'https://worldscore-985255509017.us-east1.run.app/ocr',
  );
  static const String _mockResponseAssetPath = 'assets/mock/ocr_response.json';

  final bool useMockData;
  final AssetBundle _assetBundle;
  final http.Client _client;

  OcrService({
    this.useMockData = true,
    AssetBundle? assetBundle,
    http.Client? client,
  }) : _assetBundle = assetBundle ?? rootBundle,
       _client = client ?? http.Client();

  Future<OcrScorecardResponse> fetchScorecardResults(
    Uint8List imageData,
    String fileName,
  ) async {
    final jsonBody = useMockData
        ? await _loadMockResponseJson()
        : await _loadCloudRunResponseJson(imageData, fileName);

    return OcrScorecardResponse.fromJson(jsonBody);
  }

  Future<Map<String, dynamic>> _loadMockResponseJson() async {
    final mockJsonString = await _assetBundle.loadString(_mockResponseAssetPath);
    final decodedBody = jsonDecode(mockJsonString);
    return _normalizeJsonMap(decodedBody);
  }

  Future<Map<String, dynamic>> _loadCloudRunResponseJson(
    Uint8List imageData,
    String fileName,
  ) async {
    final request = http.MultipartRequest('POST', _ocrServiceUri)
      ..headers['Accept'] = 'application/json'
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          imageData,
          filename: fileName,
        ),
      );

    final streamedResponse = await _client.send(request);
    final responseBody = await streamedResponse.stream.bytesToString();

    if (streamedResponse.statusCode < 200 || streamedResponse.statusCode >= 300) {
      throw Exception(
        'OCR request failed (${streamedResponse.statusCode}): $responseBody',
      );
    }

    final decodedBody = jsonDecode(responseBody);
    return _normalizeJsonMap(decodedBody);
  }

  Map<String, dynamic> _normalizeJsonMap(dynamic decodedBody) {
    if (decodedBody is Map<String, dynamic>) {
      return decodedBody;
    }

    if (decodedBody is Map) {
      return Map<String, dynamic>.from(decodedBody);
    }

    return {'result': decodedBody};
  }
}
