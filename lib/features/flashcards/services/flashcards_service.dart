import 'package:aether/core/database/database.dart';
import 'package:aether/core/services/supabase_service.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Offline-first flashcards data layer with SM-2 spaced repetition.
class FlashcardsService {
  final AppDatabase _db;
  final _supabase = SupabaseService.instance.client;

  FlashcardsService(this._db);

  String? get _userId => _supabase.auth.currentUser?.id;

  // ── Deck Reads ─────────────────────────────────────

  Stream<List<FlashcardDeck>> watchDecks() {
    final userId = _userId;
    if (userId == null) return Stream.value(const []);
    return (_db.select(_db.flashcardDecks)
          ..where((d) => d.userId.equals(userId))
          ..orderBy([(d) => OrderingTerm.desc(d.updatedAt)]))
        .watch();
  }

  Future<void> syncDecks() async {
    final userId = _userId;
    if (userId == null) return;
    final remote =
        await _supabase.from('flashcard_decks').select().eq('user_id', userId);
    for (final row in remote) {
      await _db
          .into(_db.flashcardDecks)
          .insertOnConflictUpdate(_deckFromRow(row, userId));
    }
  }

  Future<int> cardCountForDeck(String deckId) async {
    final rows = await (_db.select(_db.flashcards)
          ..where((c) => c.deckId.equals(deckId)))
        .get();
    return rows.length;
  }

  // ── Card Reads ─────────────────────────────────────

  Stream<List<Flashcard>> watchCardsForDeck(String deckId) {
    return (_db.select(_db.flashcards)
          ..where((c) => c.deckId.equals(deckId))
          ..orderBy([(c) => OrderingTerm(c.position)]))
        .watch();
  }

  /// Cards in [deckId] that are due for review right now.
  Stream<List<Flashcard>> watchDueCards(String deckId) {
    final now = DateTime.now();
    return (_db.select(_db.flashcards)
          ..where((c) =>
              c.deckId.equals(deckId) &
              c.nextReviewAt.isSmallerOrEqualValue(now))
          ..orderBy([(c) => OrderingTerm(c.position)]))
        .watch();
  }

  Future<void> syncCards() async {
    final userId = _userId;
    if (userId == null) return;
    final remote =
        await _supabase.from('flashcards').select().eq('user_id', userId);
    for (final row in remote) {
      await _db
          .into(_db.flashcards)
          .insertOnConflictUpdate(_cardFromRow(row, userId));
    }
  }

  // ── Deck Writes ────────────────────────────────────

  Future<FlashcardDeck> createDeck({
    required String name,
    String? description,
    String? courseId,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final deck = FlashcardDeck(
      id: const Uuid().v4(),
      userId: userId,
      courseId: courseId,
      name: name,
      description: description,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.flashcardDecks).insert(deck);
    await _push(() => _supabase.from('flashcard_decks').insert(_deckToRow(deck)));
    return deck;
  }

  Future<void> updateDeck(FlashcardDeck deck) async {
    final updated = deck.copyWith(updatedAt: DateTime.now());
    await (_db.update(_db.flashcardDecks)
          ..where((d) => d.id.equals(deck.id)))
        .replace(updated);
    await _push(() => _supabase
        .from('flashcard_decks')
        .update(_deckToRow(updated))
        .eq('id', updated.id));
  }

  Future<void> deleteDeck(String deckId) async {
    await (_db.delete(_db.flashcardDecks)..where((d) => d.id.equals(deckId))).go();
    await _push(() => _supabase.from('flashcard_decks').delete().eq('id', deckId));
  }

  // ── Card Writes ────────────────────────────────────

  Future<Flashcard> createCard({
    required String deckId,
    required String front,
    required String back,
  }) async {
    final userId = _userId;
    if (userId == null) throw Exception('Not authenticated');

    final now = DateTime.now();
    final card = Flashcard(
      id: const Uuid().v4(),
      deckId: deckId,
      userId: userId,
      front: front,
      back: back,
      position: 0,
      intervalDays: 1,
      easeFactor: 250,
      repetitions: 0,
      nextReviewAt: now,
      createdAt: now,
      updatedAt: now,
    );

    await _db.into(_db.flashcards).insert(card);
    await _push(() => _supabase.from('flashcards').insert(_cardToRow(card)));
    return card;
  }

  /// Apply SM-2 spaced repetition update after the user rates a card.
  /// [quality] 0=Again, 3=Hard, 4=Good, 5=Easy.
  Future<void> reviewCard(String cardId, int quality) async {
    final card = await (_db.select(_db.flashcards)
          ..where((c) => c.id.equals(cardId)))
        .getSingleOrNull();
    if (card == null) return;

    final updated = _applySm2(card, quality);

    await (_db.update(_db.flashcards)..where((c) => c.id.equals(cardId)))
        .replace(updated);
    await _push(() => _supabase.from('flashcards').update(_cardToRow(updated)).eq('id', updated.id));
  }

  /// SM-2 algorithm variant. Storage uses integer day intervals and
  /// `easeFactor * 100` (avoids floating point in the DB).
  Flashcard _applySm2(Flashcard c, int q) {
    final now = DateTime.now();
    int reps = c.repetitions;
    int intervalDays = c.intervalDays;
    int ef = c.easeFactor; // 250 = 2.50

    if (q < 3) {
      // Failure: reset repetitions, re-show tomorrow.
      reps = 0;
      intervalDays = 1;
    } else {
      // Update ease factor: EF' = EF + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
      ef = ef + ((5 - q) * (8 + (5 - q) * 2));
      if (ef < 130) ef = 130; // floor at 1.30
      reps += 1;
      if (reps == 1) {
        intervalDays = 1;
      } else if (reps == 2) {
        intervalDays = 6;
      } else {
        // intervalDays * (ef / 100) — using integer math then rounding
        intervalDays = ((intervalDays * ef) / 100).round();
        if (intervalDays < 1) intervalDays = 1;
      }
    }

    return c.copyWith(
      repetitions: reps,
      intervalDays: intervalDays,
      easeFactor: ef,
      nextReviewAt: now.add(Duration(days: intervalDays)),
    );
  }

  Future<void> deleteCard(String cardId) async {
    await (_db.delete(_db.flashcards)..where((c) => c.id.equals(cardId))).go();
    await _push(() => _supabase.from('flashcards').delete().eq('id', cardId));
  }

  // ── Helpers ──────────────────────────────────────────

  Future<void> _push(Future<void> Function() op) async {
    try {
      await op();
    } catch (_) {
      // Offline-first: ignore transient errors.
    }
  }

  FlashcardDeck _deckFromRow(Map<String, dynamic> r, String userId) =>
      FlashcardDeck(
        id: r['id'] as String,
        userId: r['user_id'] as String? ?? userId,
        courseId: r['course_id'] as String?,
        name: r['name'] as String? ?? '',
        description: r['description'] as String?,
        createdAt: _parseDate(r['created_at']),
        updatedAt: _parseDate(r['updated_at']),
      );

  Map<String, dynamic> _deckToRow(FlashcardDeck d) => {
        'id': d.id,
        'user_id': d.userId,
        'course_id': d.courseId,
        'name': d.name,
        'description': d.description,
        'created_at': d.createdAt.toIso8601String(),
        'updated_at': d.updatedAt.toIso8601String(),
      };

  Flashcard _cardFromRow(Map<String, dynamic> r, String userId) => Flashcard(
        id: r['id'] as String,
        deckId: r['deck_id'] as String,
        userId: r['user_id'] as String? ?? userId,
        front: r['front'] as String? ?? '',
        back: r['back'] as String? ?? '',
        position: r['position'] as int? ?? 0,
        intervalDays: r['interval_days'] as int? ?? 1,
        easeFactor: r['ease_factor'] as int? ?? 250,
        repetitions: r['repetitions'] as int? ?? 0,
        nextReviewAt: _parseDate(r['next_review_at']),
        createdAt: _parseDate(r['created_at']),
        updatedAt: _parseDate(r['updated_at']),
      );

  Map<String, dynamic> _cardToRow(Flashcard c) => {
        'id': c.id,
        'deck_id': c.deckId,
        'user_id': c.userId,
        'front': c.front,
        'back': c.back,
        'position': c.position,
        'interval_days': c.intervalDays,
        'ease_factor': c.easeFactor,
        'repetitions': c.repetitions,
        'next_review_at': c.nextReviewAt.toIso8601String(),
        'created_at': c.createdAt.toIso8601String(),
        'updated_at': c.updatedAt.toIso8601String(),
      };

  DateTime _parseDate(dynamic v) =>
      v is String ? DateTime.parse(v) : DateTime.now();
}
