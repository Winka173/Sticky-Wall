import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'note_storage.dart';

/// Asks for a store rating with the platform's own in-app review sheet, at a
/// moment the wall has just been useful: a checklist finished, a board saved
/// as a picture. Never from a button, never on the first days, never often.
/// The store decides whether the sheet really shows (it has its own quota)
/// and says nothing either way, so this never waits on it.
class ReviewPrompt {
  ReviewPrompt(this._storage, {InAppReview? review})
    : _review = review ?? InAppReview.instance;

  final NoteStorage _storage;
  final InAppReview _review;

  /// Days since install before the first ask.
  static const minDays = 3;

  /// Notes on the walls before the first ask: someone who really uses it.
  static const minNotes = 5;

  /// Days between two asks.
  static const gapDays = 120;

  /// Whether now is a fair moment to ask.
  bool due({required DateTime installedAt, required int notes, DateTime? now}) {
    final at = now ?? DateTime.now();
    if (at.difference(installedAt).inDays < minDays) return false;
    if (notes < minNotes) return false;
    final last = _storage.lastReviewAsk;
    return last == null || at.difference(last).inDays >= gapDays;
  }

  /// Asks when [due]; quietly does nothing anywhere the store cannot.
  Future<void> maybeAsk({
    required DateTime installedAt,
    required int notes,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;
    if (!due(installedAt: installedAt, notes: notes)) return;
    // Counted as asked even if the store keeps the sheet back, so the app
    // never tries again on every finished list.
    await _storage.setLastReviewAsk(DateTime.now());
    try {
      if (await _review.isAvailable()) await _review.requestReview();
    } catch (e) {
      debugPrint('In-app review unavailable: $e');
    }
  }
}
