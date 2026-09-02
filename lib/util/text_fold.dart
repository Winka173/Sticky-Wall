/// Lower-cases and strips Vietnamese diacritics so search is tolerant of
/// how the user typed: "tuoi cay" matches "Tưới cây", "dang" matches "Đặng".
String foldText(String input) {
  final out = StringBuffer();
  for (final rune in input.toLowerCase().runes) {
    final ch = String.fromCharCode(rune);
    out.write(_fold[ch] ?? ch);
  }
  return out.toString();
}

final Map<String, String> _fold = _build();

Map<String, String> _build() {
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  final map = <String, String>{};
  for (final entry in groups.entries) {
    for (final rune in entry.value.runes) {
      map[String.fromCharCode(rune)] = entry.key;
    }
  }
  return map;
}
