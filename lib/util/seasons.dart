/// The occasions that have a Sticky Wall Pro pack. A pack's wall and
/// stickers can be picked only around its occasion; whatever is already on
/// a wall stays there all year.
enum Season { tet, christmas, midAutumn, valentine }

/// What "now" is for the seasons; tests set it to a fixed day.
DateTime Function() seasonClock = DateTime.now;

/// Tết (the first day of the lunar year) and the Mid-Autumn Festival (the
/// 15th of the 8th lunar month), from the Vietnamese lunar calendar. Past
/// the last year listed, a pack simply stays open: better than locking it
/// away for good.
const _tet = {
  2026: (2, 17),
  2027: (2, 6),
  2028: (1, 26),
  2029: (2, 13),
  2030: (2, 3),
  2031: (1, 23),
  2032: (2, 11),
  2033: (1, 31),
  2034: (2, 19),
  2035: (2, 8),
  2036: (1, 28),
};

const _midAutumn = {
  2026: (9, 25),
  2027: (9, 15),
  2028: (10, 3),
  2029: (9, 22),
  2030: (9, 12),
  2031: (10, 1),
  2032: (9, 19),
  2033: (9, 8),
  2034: (9, 27),
  2035: (9, 16),
  2036: (10, 4),
};

/// The days a pack is open: [start] through the whole of [end].
typedef SeasonWindow = ({DateTime start, DateTime end});

/// [season]'s window around its occasion in [year] (Christmas runs into
/// the next January), or null when that year's date is not known.
SeasonWindow? seasonWindow(Season season, int year) {
  DateTime day((int, int)? md) => DateTime(year, md!.$1, md.$2);
  switch (season) {
    case Season.tet:
      // From the run-up (Ông Công Ông Táo, the market days) until after
      // the holiday weeks.
      if (!_tet.containsKey(year)) return null;
      final tet = day(_tet[year]);
      return (
        start: tet.subtract(const Duration(days: 25)),
        end: tet.add(const Duration(days: 15)),
      );
    case Season.midAutumn:
      if (!_midAutumn.containsKey(year)) return null;
      final full = day(_midAutumn[year]);
      return (
        start: full.subtract(const Duration(days: 21)),
        end: full.add(const Duration(days: 3)),
      );
    case Season.christmas:
      return (start: DateTime(year, 12, 1), end: DateTime(year + 1, 1, 6));
    case Season.valentine:
      return (start: DateTime(year, 2, 1), end: DateTime(year, 2, 15));
  }
}

bool _within(SeasonWindow w, DateTime at) {
  final day = DateTime(at.year, at.month, at.day);
  return !day.isBefore(w.start) && !day.isAfter(w.end);
}

/// Whether [season]'s pack can be picked now.
bool seasonOpen(Season season, {DateTime? now}) {
  final at = now ?? seasonClock();
  // Christmas that started last December is still on in early January.
  for (final year in [at.year - 1, at.year]) {
    final w = seasonWindow(season, year);
    if (w != null && _within(w, at)) return true;
  }
  // Beyond the calendar above, keep it open.
  return seasonWindow(season, at.year) == null &&
      seasonWindow(season, at.year + 1) == null;
}

/// The window [season] is in now, or the next one; null when unknown.
SeasonWindow? currentOrNextSeason(Season season, {DateTime? now}) {
  final at = now ?? seasonClock();
  for (final year in [at.year - 1, at.year, at.year + 1]) {
    final w = seasonWindow(season, year);
    if (w == null) continue;
    final today = DateTime(at.year, at.month, at.day);
    if (!w.end.isBefore(today)) return w;
  }
  return null;
}
