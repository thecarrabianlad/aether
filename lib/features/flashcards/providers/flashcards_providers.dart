import 'package:aether/core/database/database.dart';
import 'package:aether/core/providers.dart';
import 'package:aether/features/flashcards/services/flashcards_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final flashcardsServiceProvider = Provider<FlashcardsService>((ref) {
  final db = ref.watch(databaseProvider);
  return FlashcardsService(db);
});

final decksProvider = StreamProvider<List<FlashcardDeck>>((ref) {
  final service = ref.watch(flashcardsServiceProvider);
  return service.watchDecks();
});

final cardsForDeckProvider =
    StreamProvider.family<List<Flashcard>, String>((ref, deckId) {
  final service = ref.watch(flashcardsServiceProvider);
  return service.watchCardsForDeck(deckId);
});

final dueCardsProvider =
    StreamProvider.family<List<Flashcard>, String>((ref, deckId) {
  final service = ref.watch(flashcardsServiceProvider);
  return service.watchDueCards(deckId);
});