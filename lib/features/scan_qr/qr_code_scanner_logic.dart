import 'dart:convert';

import 'package:convert/convert.dart';
import 'package:flutter/foundation.dart';
import 'package:kibisis/constants/constants.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';

class QRCodeScannerLogic {
  final AccountFlow accountFlow;
  final ScanMode scanMode;

  QRCodeScannerLogic({
    this.accountFlow = AccountFlow.general,
    this.scanMode = ScanMode.catchAll,
  });
  Future<dynamic> handleBarcode(BarcodeCapture capture) async {
    try {
      String rawData = capture.barcodes.first.rawValue ?? '';
      if (rawData.isEmpty) throw Exception('Invalid QR code data');

      await _handleVibration();

      switch (scanMode) {
        case ScanMode.privateKey:
          if (isPublicKeyFormat(rawData)) {
            throw Exception(
                'Expected a private key QR code but found a public key.');
          } else if (isSupportedWalletConnectUri(rawData)) {
            throw Exception(
                'Expected a private key QR code but found a WalletConnect URI.');
          }
          return await _handleImportAccountUri(rawData);

        case ScanMode.publicKey:
          if (!isPublicKeyFormat(rawData)) {
            throw Exception(
                'Expected a public key QR code but found something else.');
          }
          return _handlePublicKey(rawData);

        case ScanMode.session:
          if (!isSupportedWalletConnectUri(rawData)) {
            throw Exception(
                'Expected a WalletConnect session QR code but found something else.');
          }
          return Uri.parse(rawData);

        case ScanMode.catchAll:
          if (isPublicKeyFormat(rawData)) {
            return _handlePublicKey(rawData);
          } else if (isImportAccountUri(rawData)) {
            return await _handleImportAccountUri(rawData);
          } else if (isSupportedWalletConnectUri(rawData)) {
            return Uri.parse(rawData);
          } else {
            throw Exception('Unknown QR Code type');
          }
      }
    } catch (e) {
      rethrow;
    }
  }

  bool isSupportedWalletConnectUri(String rawData) {
    if (!rawData.startsWith('wc:')) return false;
    try {
      Uri uri = Uri.parse(rawData);
      final segments = uri.toString().split('@');
      if (segments.length > 1) {
        final version = int.tryParse(segments[1].substring(0, 1));
        if (version == 1) {
          throw UnsupportedError('WalletConnect V1 URIs are not supported.');
        } else if (version == 2) {
          return true;
        } else {
          throw UnsupportedError(
              'Unknown WalletConnect version. Unable to pair.');
        }
      } else {
        throw UnsupportedError('Invalid WalletConnect URI format.');
      }
    } catch (e) {
      throw UnsupportedError('Failed to parse WalletConnect URI: $e');
    }
  }

  bool isImportAccountUri(String uriString) {
    if (!uriString.startsWith('avm://account/import')) return false;
    Uri? uri = Uri.tryParse(uriString);
    if (uri == null) return false;
    return uri.hasAbsolutePath && uriString.contains('import');
  }

  String _handlePublicKey(String rawData) {
    if (isPublicKeyFormat(rawData)) {
      return rawData;
    } else {
      throw Exception('Invalid Public Key Format');
    }
  }

  Future<void> _handleVibration() async {
    if (await Vibration.hasVibrator() ?? false) {
      Vibration.vibrate(duration: 100);
    }
  }

  Future<Set<Map<String, dynamic>>> _handleImportAccountUri(String uri) async {
    Uri? parsedUri = Uri.tryParse(uri);
    if (parsedUri == null) {
      throw Exception('Invalid URI format');
    }

    // Extract query parameters
    Map<String, List<String>> params = getQueryParameters(parsedUri.query);

    if (params.containsKey('encoding') && params['encoding']?.first == 'hex') {
      // If the URI contains the "encoding=hex", it's a legacy format
      return handleLegacyUri(params);
    } else if (params.containsKey('privatekey')) {
      // If the URI contains "privatekey" but no encoding, it's a modern format
      return handleModernUri(params);
    } else {
      throw Exception('Unknown import account URI format');
    }
  }

  bool isPublicKeyFormat(String data) {
    return data.length == 58 && RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(data);
  }

  Map<String, List<String>> getQueryParameters(String query) {
    List<String> names = [];
    List<String> privateKeys = [];
    int importedAccountCounter = 1;
    String? lastName;

    var queryString = query.split('?').last;
    var parts = queryString.split('&');

    for (var part in parts) {
      var index = part.indexOf('=');
      if (index != -1) {
        var key = Uri.decodeComponent(part.substring(0, index));
        var value = Uri.decodeComponent(part.substring(index + 1));

        if (key == 'name') {
          lastName = value;
        } else if (key == 'privatekey') {
          if (lastName != null) {
            names.add(lastName);
            lastName = null;
          } else {
            names.add('Imported Account $importedAccountCounter');
            importedAccountCounter++;
          }
          privateKeys.add(value);
        }
      }
    }

    return {'name': names, 'privatekey': privateKeys};
  }

  Set<Map<String, dynamic>> handleModernUri(Map<String, List<String>> params) {
    Set<Map<String, dynamic>> result = {};

    List<String> names = params['name'] ?? [];
    List<String> privateKeys = params['privatekey'] ?? [];
    int importedAccountCounter = 1;

    for (int i = 0; i < privateKeys.length; i++) {
      String name;

      if (i < names.length) {
        name = names[i];
      } else {
        name = 'Imported Account $importedAccountCounter';
        importedAccountCounter++;
      }

      Uint8List? seed = _decodePrivateKey(privateKeys[i]);

      if (seed == null || seed.length != 32) {
        throw Exception('Invalid private key');
      }

      result.add({'name': name, 'seed': seed});
    }

    return result;
  }

  Set<Map<String, dynamic>> handleLegacyUri(Map<String, List<String>> params) {
    Set<Map<String, dynamic>> result = {};

    const String name = 'Imported Account';
    final String key = params['privatekey']?.first ?? '';
    Uint8List? seed = _decodePrivateKey(key);

    if (seed == null || seed.length != 32) {
      throw Exception('Invalid private key');
    }

    result.add({'name': name, 'seed': seed});

    return result;
  }

  Uint8List? _decodePrivateKey(String key) {
    try {
      if (key.length == 44 && RegExp(r'^[A-Za-z0-9\-_]+=*$').hasMatch(key)) {
        return base64Url.decode(key);
      } else if (RegExp(r'^[0-9a-fA-F]+$').hasMatch(key)) {
        if (key.length == 128) {
          final privateKeyHex = key.substring(0, 64);
          return Uint8List.fromList(hex.decode(privateKeyHex));
        } else if (key.length == 64) {
          return Uint8List.fromList(hex.decode(key));
        } else {
          debugPrint('Invalid private key length');
        }
      } else {
        debugPrint('Key is neither valid Base64 nor valid Hex: $key');
      }
    } catch (e) {
      debugPrint('Failed to decode private key: $e');
    }
    return null;
  }
}
