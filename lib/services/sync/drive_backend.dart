import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import 'sync_backend.dart';

/// Google Drive's hidden app folder (`appDataFolder`): only Sticky Wall can
/// see the files there, the user's own Drive files are never listed or
/// touched, and the user can delete the data from Drive's settings
/// ("Manage apps"). The only scope asked for is `drive.appdata`.
///
/// Needs an Android OAuth client for this app's package name and signing
/// certificates in the Google Cloud project (see
/// docs/sticky-final/SYNC_DESIGN_AND_LIMITATIONS.md).
class DriveSyncBackend extends SyncBackend {
  DriveSyncBackend({http.Client? client}) : _http = client ?? http.Client();

  static const scope = 'https://www.googleapis.com/auth/drive.appdata';
  static const _api = 'https://www.googleapis.com/drive/v3/files';
  static const _upload = 'https://www.googleapis.com/upload/drive/v3/files';
  static const _devicePrefix = 'sw-dev-';
  static const _blobPrefix = 'sw-blob-';

  final http.Client _http;
  String? _token;

  /// Drive file ids by name, learned from listings.
  final _ids = <String, String>{};

  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  @override
  String get name => 'Google Drive';

  /// Asks the user to let Sticky Wall use its Drive app folder. Returns
  /// false when they say no or the device cannot do it.
  static Future<bool> authorize() async {
    try {
      await _init();
      await GoogleSignIn.instance.authorizationClient.authorizeScopes([scope]);
      return true;
    } catch (e) {
      debugPrint('Drive authorization failed: $e');
      return false;
    }
  }

  /// Gives Drive access back (sync switched off and the user asked to).
  static Future<void> revoke() async {
    try {
      await _init();
      await GoogleSignIn.instance.disconnect();
    } catch (e) {
      debugPrint('Drive revoke failed: $e');
    }
  }

  Future<String> _accessToken({bool fresh = false}) async {
    if (_token != null && !fresh) return _token!;
    try {
      await _init();
      final auth = await GoogleSignIn.instance.authorizationClient
          .authorizationForScopes([scope]);
      if (auth == null) throw const SyncException(SyncFailure.authNeeded);
      return _token = auth.accessToken;
    } on SyncException {
      rethrow;
    } catch (e) {
      throw SyncException(SyncFailure.authNeeded, '$e');
    }
  }

  Future<http.Response> _send(
    Future<http.Response> Function(Map<String, String> headers) call,
  ) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      final token = await _accessToken(fresh: attempt > 0);
      final http.Response res;
      try {
        res = await call({'Authorization': 'Bearer $token'});
      } on SocketException catch (e) {
        throw SyncException(SyncFailure.offline, '$e');
      } on http.ClientException catch (e) {
        throw SyncException(SyncFailure.offline, '$e');
      }
      if (res.statusCode == 401 && attempt == 0) {
        // A stale token: drop it and ask for a fresh one once.
        try {
          await GoogleSignIn.instance.authorizationClient
              .clearAuthorizationToken(accessToken: token);
        } catch (_) {}
        _token = null;
        continue;
      }
      if (res.statusCode >= 200 && res.statusCode < 300) return res;
      if (res.statusCode == 401) {
        throw const SyncException(SyncFailure.authNeeded);
      }
      if (res.statusCode == 403 && res.body.contains('storageQuotaExceeded')) {
        throw const SyncException(SyncFailure.quota);
      }
      if (res.statusCode >= 500 || res.statusCode == 429) {
        throw SyncException(SyncFailure.offline, 'HTTP ${res.statusCode}');
      }
      throw SyncException(SyncFailure.other, 'HTTP ${res.statusCode}');
    }
    throw const SyncException(SyncFailure.authNeeded);
  }

  /// Every file whose name starts with [prefix]: name → (id, version).
  Future<Map<String, (String, String)>> _list(String prefix) async {
    final out = <String, (String, String)>{};
    String? page;
    do {
      final uri = Uri.parse(_api).replace(
        queryParameters: {
          'spaces': 'appDataFolder',
          'q': "name contains '$prefix' and trashed = false",
          'fields': 'nextPageToken, files(id, name, version, md5Checksum)',
          'pageSize': '1000',
          'pageToken': ?page,
        },
      );
      final res = await _send((h) => _http.get(uri, headers: h));
      final json = jsonDecode(res.body) as Map<String, dynamic>;
      for (final f in (json['files'] as List<dynamic>? ?? [])) {
        final m = f as Map<String, dynamic>;
        final name = m['name'] as String;
        if (!name.startsWith(prefix)) continue;
        _ids[name] = m['id'] as String;
        out[name] = (m['id'] as String, '${m['version'] ?? m['md5Checksum']}');
      }
      page = json['nextPageToken'] as String?;
    } while (page != null);
    return out;
  }

  Future<Uint8List?> _download(String name) async {
    final id = _ids[name];
    if (id == null) return null;
    final res = await _send(
      (h) => _http.get(Uri.parse('$_api/$id?alt=media'), headers: h),
    );
    return res.bodyBytes;
  }

  Future<void> _write(String name, Uint8List bytes, String type) async {
    final id = _ids[name];
    if (id != null) {
      await _send(
        (h) => _http.patch(
          Uri.parse('$_upload/$id?uploadType=media'),
          headers: {...h, 'Content-Type': type},
          body: bytes,
        ),
      );
      return;
    }
    const boundary = 'sticky-wall-sync-boundary';
    final meta = jsonEncode({
      'name': name,
      'parents': ['appDataFolder'],
    });
    final body = BytesBuilder()
      ..add(
        utf8.encode(
          '--$boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n'
          '$meta\r\n'
          '--$boundary\r\n'
          'Content-Type: $type\r\n\r\n',
        ),
      )
      ..add(bytes)
      ..add(utf8.encode('\r\n--$boundary--\r\n'));
    final res = await _send(
      (h) => _http.post(
        Uri.parse('$_upload?uploadType=multipart&fields=id'),
        headers: {
          ...h,
          'Content-Type': 'multipart/related; boundary=$boundary',
        },
        body: body.takeBytes(),
      ),
    );
    final created = jsonDecode(res.body) as Map<String, dynamic>;
    _ids[name] = created['id'] as String;
  }

  @override
  Future<Map<String, String>> listDevices() async {
    final files = await _list(_devicePrefix);
    return {
      for (final e in files.entries)
        e.key.substring(_devicePrefix.length).replaceAll('.json', ''):
            e.value.$2,
    };
  }

  @override
  Future<String?> readDevice(String deviceId) async {
    final bytes = await _download('$_devicePrefix$deviceId.json');
    return bytes == null ? null : utf8.decode(bytes);
  }

  @override
  Future<void> writeDevice(String deviceId, String document) => _write(
    '$_devicePrefix$deviceId.json',
    utf8.encode(document),
    'application/json',
  );

  @override
  Future<Set<String>> listBlobs() async {
    final files = await _list(_blobPrefix);
    return {for (final n in files.keys) n.substring(_blobPrefix.length)};
  }

  @override
  Future<void> putBlob(String sha, Uint8List bytes) =>
      _write('$_blobPrefix$sha', bytes, 'application/octet-stream');

  @override
  Future<Uint8List?> getBlob(String sha) async {
    if (!_ids.containsKey('$_blobPrefix$sha')) await _list(_blobPrefix);
    return _download('$_blobPrefix$sha');
  }
}
