import '../models/vocabulary.dart';

/// Wie eine selbst abgelegte Karte auf dem Gerät geschrieben wird.
///
/// Herausgezogen, als der zweite Speicher dazukam (`DailyCardStore` neben
/// `CustomCardStore`): Zwei Stellen, die dasselbe Format lesen und schreiben,
/// laufen früher oder später auseinander — und dann sind Karten weg, die
/// noch da sind.
///
/// **Das Format darf sich nicht ändern.** Es steckt im Speicher bestehender
/// Installationen; ein anderer Feldname heißt, dass eine gemerkte Karte beim
/// nächsten Update verschwindet.
abstract final class CardCodec {
  static Map<String, Object?> toJson(VocabEntry card) => <String, Object?>{
        'term': card.german,
        'answer': card.answer,
        if (card.question != null) 'question': card.question,
        if (card.distractors.isNotEmpty) 'distractors': card.distractors,
        if (card.explanation != null) 'explanation': card.explanation,
        if (card.source != null) 'source': card.source,
      };

  /// `null`, wenn der Eintrag unbrauchbar ist — das kostet diese eine Karte,
  /// nicht die ganze Sammlung.
  static VocabEntry? fromJson(Object? json) {
    if (json is! Map) return null;
    final Object? term = json['term'];
    final Object? answer = json['answer'];
    if (term is! String || answer is! String) return null;
    if (term.trim().isEmpty || answer.trim().isEmpty) return null;
    final Object? question = json['question'];
    final Object? distractors = json['distractors'];
    return VocabEntry(
      term,
      answer,
      '',
      question: question is String ? question : null,
      distractors: distractors is List
          ? <String>[
              for (final Object? d in distractors)
                if (d is String) d,
            ]
          : const <String>[],
      explanation: json['explanation'] is String
          ? json['explanation'] as String
          : null,
      source: json['source'] is String ? json['source'] as String : null,
      script: TextScript.latin,
    );
  }
}
