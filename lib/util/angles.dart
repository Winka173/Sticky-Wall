import 'dart:math' as math;

/// Brings [angle] (radians) into (-π, π], so a card spun round several times
/// stores — and animates from — the short way round.
double normalizeAngle(double angle) {
  var a = angle % (2 * math.pi);
  if (a > math.pi) a -= 2 * math.pi;
  if (a <= -math.pi) a += 2 * math.pi;
  return a;
}

/// How close (radians) a card has to be to upright or a quarter turn before
/// the rotate handle snaps it there.
const snapAngle = 0.06;

/// Snaps [angle] to the nearest multiple of a quarter turn when it is within
/// [snapAngle] of one; else returns it unchanged. Both in (-π, π].
double snapQuarterTurns(double angle) {
  final a = normalizeAngle(angle);
  final quarter = (a / (math.pi / 2)).round() * (math.pi / 2);
  return (a - quarter).abs() <= snapAngle ? normalizeAngle(quarter) : a;
}
