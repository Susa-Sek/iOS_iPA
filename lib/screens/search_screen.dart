import 'package:flutter/material.dart';

import '../models/vocabulary.dart';
import '../state/learning_state.dart';
import '../widgets/word_tile.dart';

/// Searches the whole vocabulary — German, transliteration or Arabic script.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final List<VocabEntry> results = _query.trim().isEmpty
        ? const <VocabEntry>[]
        : LearningScope.of(context)
            .content
            .entries
            .where((VocabEntry e) => e.matches(_query))
            .toList();

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Deutsch, Lautschrift oder Arabisch …',
            border: InputBorder.none,
          ),
          onChanged: (String value) => setState(() => _query = value),
        ),
      ),
      body: _query.trim().isEmpty
          ? const Center(child: Text('Gib ein Wort ein, um zu suchen.'))
          : results.isEmpty
              ? const Center(child: Text('Keine Treffer.'))
              : ListView.separated(
                  itemCount: results.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (BuildContext context, int index) =>
                      WordTile(entry: results[index]),
                ),
    );
  }
}
