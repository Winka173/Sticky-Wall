import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sticky_wall/services/note_storage.dart';
import 'package:sticky_wall/services/review_prompt.dart';

void main() {
  late NoteStorage storage;
  late ReviewPrompt prompt;
  final installed = DateTime(2026, 11, 1);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    storage = await NoteStorage.create();
    prompt = ReviewPrompt(storage);
  });

  test('not in the first days, not with a near-empty wall', () {
    expect(
      prompt.due(installedAt: installed, notes: 20, now: DateTime(2026, 11, 2)),
      isFalse,
    );
    expect(
      prompt.due(installedAt: installed, notes: 4, now: DateTime(2026, 11, 9)),
      isFalse,
    );
    expect(
      prompt.due(installedAt: installed, notes: 5, now: DateTime(2026, 11, 4)),
      isTrue,
    );
  });

  test('once asked, not again for four months', () async {
    await storage.setLastReviewAsk(DateTime(2026, 11, 10));
    expect(
      prompt.due(installedAt: installed, notes: 30, now: DateTime(2027, 1, 10)),
      isFalse,
    );
    expect(
      prompt.due(installedAt: installed, notes: 30, now: DateTime(2027, 3, 11)),
      isTrue,
    );
  });
}
