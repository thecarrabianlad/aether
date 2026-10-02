import 'package:aether/core/database/database.dart';
import 'package:aether/core/theme/app_theme.dart';
import 'package:aether/features/flashcards/providers/flashcards_providers.dart';
import 'package:aether/widgets/common/glass_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FlashcardsScreen extends ConsumerStatefulWidget {
  const FlashcardsScreen({super.key});

  @override
  ConsumerState<FlashcardsScreen> createState() => _FlashcardsScreenState();
}

class _FlashcardsScreenState extends ConsumerState<FlashcardsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(flashcardsServiceProvider).syncDecks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final decksAsync = ref.watch(decksProvider);

    return Scaffold(
      backgroundColor: aether.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: aether.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Flashcards',
            style: TextStyle(
                color: aether.text, fontSize: 18, fontWeight: FontWeight.w600)),
      ),
      body: decksAsync.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: aether.accent)),
        error: (e, _) => Center(
          child: Text('Could not load decks',
              style: TextStyle(color: aether.textMuted)),
        ),
        data: (decks) {
          if (decks.isEmpty) return _buildEmpty(aether);
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
            itemCount: decks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => _DeckCard(
              deck: decks[i],
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => _DeckDetailScreen(deck: decks[i]),
                ),
              ),
              onDelete: () => _deleteDeck(decks[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _createDeck(aether),
        backgroundColor: aether.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  Widget _buildEmpty(AetherTheme aether) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_rounded,
                color: aether.textMuted, size: 48),
            const SizedBox(height: 12),
            Text('No decks yet',
                style: TextStyle(color: aether.textMuted, fontSize: 16)),
            const SizedBox(height: 4),
            Text('Tap + to create your first deck',
                style: TextStyle(color: aether.textMuted, fontSize: 13)),
          ],
        ),
      );

  void _createDeck(AetherTheme aether) {
    final nameCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: aether.surface,
        title: Text('New Deck', style: TextStyle(color: aether.text)),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          style: TextStyle(color: aether.text),
          decoration: InputDecoration(
            hintText: 'Deck name',
            hintStyle: TextStyle(color: aether.textMuted),
            filled: true,
            fillColor: aether.surfaceAlt,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final name = nameCtrl.text.trim();
              if (name.isNotEmpty) {
                ref.read(flashcardsServiceProvider).createDeck(name: name);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _deleteDeck(FlashcardDeck deck) {
    final aether = context.aether;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: aether.surface,
        title: Text('Delete Deck', style: TextStyle(color: aether.text)),
        content: Text('Delete "${deck.name}" and all its cards?',
            style: TextStyle(color: aether.textMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(flashcardsServiceProvider).deleteDeck(deck.id);
            },
            child: Text('Delete', style: TextStyle(color: aether.danger)),
          ),
        ],
      ),
    );
  }
}

// ── Deck Card ────────────────────────────────────────

class _DeckCard extends ConsumerWidget {
  final FlashcardDeck deck;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DeckCard({
    required this.deck,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aether = context.aether;
    final cardCount = ref.watch(cardsForDeckProvider(deck.id));

    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: GlassCard(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: aether.accent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.auto_stories_rounded,
                  color: aether.accent, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(deck.name,
                      style: TextStyle(
                          color: aether.text,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  cardCount.when(
                    data: (cards) => Text(
                      '${cards.length} card${cards.length == 1 ? '' : 's'}',
                      style:
                          TextStyle(color: aether.textMuted, fontSize: 12),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    loading: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: aether.textMuted, size: 22),
          ],
        ),
      ),
    );
  }
}

// ── Deck Detail (Card List) ──────────────────────────

class _DeckDetailScreen extends ConsumerStatefulWidget {
  final FlashcardDeck deck;

  const _DeckDetailScreen({required this.deck});

  @override
  ConsumerState<_DeckDetailScreen> createState() => _DeckDetailScreenState();
}

class _DeckDetailScreenState extends ConsumerState<_DeckDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    final cardsAsync = ref.watch(cardsForDeckProvider(widget.deck.id));
    final dueAsync = ref.watch(dueCardsProvider(widget.deck.id));

    return Scaffold(
      backgroundColor: aether.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: aether.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.deck.name,
            style: TextStyle(
                color: aether.text,
                fontSize: 18,
                fontWeight: FontWeight.w600)),
      ),
      body: Column(
        children: [
          // Study Now banner
          dueAsync.when(
            data: (due) {
              if (due.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: GlassCard(
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: aether.success, size: 20),
                        const SizedBox(width: 10),
                        Text('All caught up!',
                            style: TextStyle(
                                color: aether.textMuted, fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          _StudyScreen(deckId: widget.deck.id, cards: due),
                    ),
                  ),
                  child: GlassCard(
                    borderColor: aether.accent,
                    child: Row(
                      children: [
                        Icon(Icons.play_circle_rounded,
                            color: aether.accent, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${due.length} card${due.length == 1 ? '' : 's'} due for review',
                                  style: TextStyle(
                                      color: aether.text,
                                      fontWeight: FontWeight.w600)),
                              Text('Tap to study',
                                  style: TextStyle(
                                      color: aether.textMuted, fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward_rounded,
                            color: aether.textMuted, size: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
          // Card list
          Expanded(
            child: cardsAsync.when(
              loading: () => Center(
                  child: CircularProgressIndicator(color: aether.accent)),
              error: (e, _) => Center(
                  child: Text('Could not load cards',
                      style: TextStyle(color: aether.textMuted))),
              data: (cards) {
                if (cards.isEmpty) {
                  return Center(
                    child: Text('No cards yet. Tap + to add one.',
                        style:
                            TextStyle(color: aether.textMuted, fontSize: 13)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                  itemCount: cards.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _CardTile(
                    card: cards[i],
                    onTap: () => _editCard(cards[i]),
                    onDelete: () => _deleteCard(cards[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addCard(aether),
        backgroundColor: aether.accent,
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
    );
  }

  void _addCard(AetherTheme aether) {
    final frontCtrl = TextEditingController();
    final backCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: aether.surface,
        title: Text('Add Card', style: TextStyle(color: aether.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: frontCtrl,
              autofocus: true,
              maxLines: 3,
              style: TextStyle(color: aether.text),
              decoration: InputDecoration(
                hintText: 'Front (question)',
                hintStyle: TextStyle(color: aether.textMuted),
                filled: true,
                fillColor: aether.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: backCtrl,
              maxLines: 3,
              style: TextStyle(color: aether.text),
              decoration: InputDecoration(
                hintText: 'Back (answer)',
                hintStyle: TextStyle(color: aether.textMuted),
                filled: true,
                fillColor: aether.surfaceAlt,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              final front = frontCtrl.text.trim();
              final back = backCtrl.text.trim();
              if (front.isNotEmpty && back.isNotEmpty) {
                ref
                    .read(flashcardsServiceProvider)
                    .createCard(deckId: widget.deck.id, front: front, back: back);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _editCard(Flashcard card) {
    // For v1, just show the content in a dialog
    final aether = context.aether;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: aether.surface,
        title: Text('Card', style: TextStyle(color: aether.text)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: aether.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Front',
                      style: TextStyle(
                          color: aether.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(card.front, style: TextStyle(color: aether.text)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: aether.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Back',
                      style: TextStyle(
                          color: aether.success,
                          fontSize: 11,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(card.back, style: TextStyle(color: aether.text)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteCard(card);
            },
            child: Text('Delete', style: TextStyle(color: aether.danger)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _deleteCard(Flashcard card) {
    ref.read(flashcardsServiceProvider).deleteCard(card.id);
  }
}

// ── Card Tile ────────────────────────────────────────

class _CardTile extends StatelessWidget {
  final Flashcard card;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _CardTile({
    required this.card,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return GestureDetector(
      onTap: onTap,
      onLongPress: onDelete,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(card.front,
                  style: TextStyle(color: aether.text, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_rounded,
                size: 16, color: aether.textMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(card.back,
                  style: TextStyle(
                      color: aether.textMuted, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Study Screen ─────────────────────────────────────

class _StudyScreen extends ConsumerStatefulWidget {
  final String deckId;
  final List<Flashcard> cards;

  const _StudyScreen({
    required this.deckId,
    required this.cards,
  });

  @override
  ConsumerState<_StudyScreen> createState() => _StudyScreenState();
}

class _StudyScreenState extends ConsumerState<_StudyScreen>
    with SingleTickerProviderStateMixin {
  int _index = 0;
  bool _showBack = false;

  late AnimationController _flipController;
  late Animation<double> _flipAnimation;
  bool _isFront = true;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    _flipAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _flipController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _flipController.dispose();
    super.dispose();
  }

  bool get _isDone => _index >= widget.cards.length;

  void _flipCard() {
    if (_flipController.isCompleted) {
      _flipController.reverse();
      _showBack = false;
    } else {
      _flipController.forward();
      _showBack = true;
    }
    _isFront = !_isFront;
  }

  void _rateCard(int quality) async {
    await ref
        .read(flashcardsServiceProvider)
        .reviewCard(widget.cards[_index].id, quality);

    _flipController.reset();
    _showBack = false;
    _isFront = true;

    setState(() {
      _index++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;

    if (_isDone) {
      return Scaffold(
        backgroundColor: aether.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: aether.text),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text('Study Complete!',
              style: TextStyle(
                  color: aether.text,
                  fontSize: 18,
                  fontWeight: FontWeight.w600)),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.celebration_rounded,
                  color: aether.accent, size: 64),
              const SizedBox(height: 16),
              Text('All cards reviewed!',
                  style: TextStyle(
                      color: aether.text,
                      fontSize: 20,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text('Come back later for more reviews.',
                  style:
                      TextStyle(color: aether.textMuted, fontSize: 14)),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: aether.accent,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      );
    }

    final card = widget.cards[_index];
    final remaining = widget.cards.length - _index - 1;

    return Scaffold(
      backgroundColor: aether.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded, color: aether.text),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
            '${_index + 1} / ${widget.cards.length}',
            style: TextStyle(color: aether.text, fontSize: 16)),
      ),
      body: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _flipCard,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: AnimatedBuilder(
                  animation: _flipAnimation,
                  builder: (context, child) {
                    final angle = _flipAnimation.value * 3.14159265;
                    final isFrontHalf = _flipAnimation.value < 0.5;

                    return Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.identity()
                        ..setEntry(3, 2, 0.001)
                        ..rotateY(angle),
                      child: isFrontHalf
                          ? _buildCardFace(
                              aether, card.front, 'Front', aether.accent)
                          : Transform(
                              alignment: Alignment.center,
                              transform: Matrix4.identity()..rotateY(3.14159265),
                              child: _buildCardFace(
                                  aether, card.back, 'Back', aether.success),
                            ),
                    );
                  },
                ),
              ),
            ),
          ),
          // Rating buttons
          if (_showBack)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Row(
                children: [
                  Expanded(
                    child: _RateButton(
                      label: 'Again',
                      emoji: '😅',
                      color: const Color(0xFFFF3B30),
                      onTap: () => _rateCard(1),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RateButton(
                      label: 'Hard',
                      emoji: '🤔',
                      color: const Color(0xFFE08A2E),
                      onTap: () => _rateCard(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RateButton(
                      label: 'Good',
                      emoji: '😊',
                      color: const Color(0xFF34C759),
                      onTap: () => _rateCard(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RateButton(
                      label: 'Easy',
                      emoji: '😎',
                      color: const Color(0xFF3B82F6),
                      onTap: () => _rateCard(5),
                    ),
                  ),
                ],
              ),
            ),
          if (!_showBack)
            Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: Text('Tap card to flip',
                  style: TextStyle(color: aether.textMuted, fontSize: 13)),
            ),
          if (remaining > 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text('$remaining remaining',
                  style: TextStyle(color: aether.textMuted, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Widget _buildCardFace(AetherTheme aether, String text, String label, Color labelColor) {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label,
              style: TextStyle(
                  color: labelColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5)),
          const SizedBox(height: 16),
          Text(text,
              style: TextStyle(
                  color: aether.text,
                  fontSize: 20,
                  fontWeight: FontWeight.w400),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _RateButton extends StatelessWidget {
  final String label;
  final String emoji;
  final Color color;
  final VoidCallback onTap;

  const _RateButton({
    required this.label,
    required this.emoji,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final aether = context.aether;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    color: aether.text, fontSize: 11, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
