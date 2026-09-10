import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import '../widgets/word_tile.dart';
import 'build_word_screen.dart';
import 'typing_screen.dart';
import 'flashcard_screen.dart';
import 'matching_screen.dart';
import 'quiz_screen.dart';

/// All words of one category: the four exercises for exactly this list, a
/// filter field and the words themselves.
class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final VocabCategory category;

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  String _query = '';
  bool _onlyOpen = false;

  void _open(Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LearningState state = LearningScope.of(context);
    final List<VocabEntry> entries = widget.category.entries
        .where((VocabEntry e) => e.matches(_query))
        .where((VocabEntry e) => !_onlyOpen || !state.isLearned(e))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.category.name),
        backgroundColor: widget.category.softColor,
      ),
      body: Column(
        children: <Widget>[
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              children: <Widget>[
                _ExerciseChip(
                  icon: Icons.style_outlined,
                  label: 'Karteikarten',
                  onTap: () => _open(
                    FlashcardScreen(
                      entries: widget.category.entries,
                      title: widget.category.name,
                      accent: widget.category.color,
                      accentSoft: widget.category.softColor,
                    ),
                  ),
                ),
                _ExerciseChip(
                  icon: Icons.quiz_outlined,
                  label: 'Quiz',
                  onTap: () => _open(
                    QuizScreen(
                      entries: widget.category.entries,
                      title: widget.category.name,
                    ),
                  ),
                ),
                _ExerciseChip(
                  icon: Icons.compare_arrows,
                  label: 'Zuordnen',
                  onTap: () => _open(
                    MatchingScreen(
                      entries: widget.category.entries,
                      title: widget.category.name,
                      accent: widget.category.color,
                      accentSoft: widget.category.softColor,
                    ),
                  ),
                ),
                if (widget.category.entries.any(TypingScreen.isSuitable))
                  _ExerciseChip(
                    icon: Icons.keyboard_alt_outlined,
                    label: 'Tippen',
                    onTap: () => _open(
                      TypingScreen(
                        entries: widget.category.entries,
                        title: widget.category.name,
                      ),
                    ),
                  ),
                // „Wort bauen" setzt arabische Buchstaben voraus — bei einem
                // Wissensthema gäbe es nichts zu bauen.
                if (widget.category.entries.any(BuildWordScreen.isSuitable))
                  _ExerciseChip(
                    icon: Icons.grid_view,
                    label: 'Wort bauen',
                    onTap: () => _open(
                      BuildWordScreen(
                        entries: widget.category.entries,
                        title: widget.category.name,
                        accent: widget.category.color,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Wort suchen …',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (String value) => setState(() => _query = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: <Widget>[
                Flexible(
                  child: FilterChip(
                    label: const Text(
                      'Nur offene Wörter',
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: _onlyOpen,
                    onSelected: (bool value) =>
                        setState(() => _onlyOpen = value),
                  ),
                ),
                const SizedBox(width: 8),
                Text('${entries.length} Wörter'),
                const SizedBox(width: 8),
              ],
            ),
          ),
          const Divider(height: 16),
          Expanded(
            child: entries.isEmpty
                ? const Center(child: Text('Keine Treffer.'))
                : ListView.separated(
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (BuildContext context, int index) => WordTile(
                      entry: entries[index],
                      accent: widget.category.color,
                      accentSoft: widget.category.softColor,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseChip extends StatelessWidget {
  const _ExerciseChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}
