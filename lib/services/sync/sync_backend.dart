import 'dart:typed_data';

/// Why a sync could not finish, in terms the settings screen can explain.
enum SyncFailure {
  /// No network, or the provider did not answer.
  offline,

  /// The provider needs the user to sign in or grant access again.
  authNeeded,

  /// The provider's storage is full.
  quota,

  /// A file from another device was written by a newer app version.
  newerVersion,

  /// Anything else; the details go to the log, never the user's data.
  other,
}

class SyncException implements Exception {
  const SyncException(this.failure, [this.detail = '']);

  final SyncFailure failure;
  final String detail;

  @override
  String toString() =>
      'SyncException($failure${detail.isEmpty ? '' : ': $detail'})';
}

/// Storage the sync writes to: one file per device, and media blobs named
/// by their SHA-256. Each device only ever writes its own file, so two
/// devices syncing at the same moment never overwrite each other.
abstract class SyncBackend {
  /// A short name for the settings screen ("Google Drive").
  String get name;

  /// Every device file: device id → the provider's version tag (anything
  /// that changes when the file does), so unchanged files are not
  /// downloaded again.
  Future<Map<String, String>> listDevices();

  Future<String?> readDevice(String deviceId);

  Future<void> writeDevice(String deviceId, String document);

  /// The SHA-256 names of every blob stored.
  Future<Set<String>> listBlobs();

  Future<void> putBlob(String sha, Uint8List bytes);

  Future<Uint8List?> getBlob(String sha);
}

/// A backend in memory, shared by several simulated devices in tests. Not
/// a sync provider: nothing leaves the process.
class MemorySyncBackend extends SyncBackend {
  final devices = <String, String>{};
  final blobs = <String, Uint8List>{};
  var _version = 0;
  final _versions = <String, String>{};

  /// Set to make every call fail, as an offline phone would.
  SyncFailure? failWith;

  void _check() {
    final f = failWith;
    if (f != null) throw SyncException(f);
  }

  @override
  String get name => 'Memory';

  @override
  Future<Map<String, String>> listDevices() async {
    _check();
    return Map.of(_versions);
  }

  @override
  Future<String?> readDevice(String deviceId) async {
    _check();
    return devices[deviceId];
  }

  @override
  Future<void> writeDevice(String deviceId, String document) async {
    _check();
    devices[deviceId] = document;
    _versions[deviceId] = '${++_version}';
  }

  @override
  Future<Set<String>> listBlobs() async {
    _check();
    return blobs.keys.toSet();
  }

  @override
  Future<void> putBlob(String sha, Uint8List bytes) async {
    _check();
    blobs[sha] = bytes;
  }

  @override
  Future<Uint8List?> getBlob(String sha) async {
    _check();
    return blobs[sha];
  }
}
