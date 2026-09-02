/// A deterministic, platform-independent string hash.
///
/// Dart's `String.hashCode` is not guaranteed stable across runs or platforms,
/// which matters wherever a hash must survive a restart — notification ids,
/// the seed for a note's paper colour or tilt, a wall's grime pattern.
int stableHash(String s) =>
    s.codeUnits.fold(0, (acc, c) => (acc * 31 + c) & 0x7fffffff);
