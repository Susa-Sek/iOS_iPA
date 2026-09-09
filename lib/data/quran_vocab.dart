import 'package:flutter/material.dart';

import '../models/vocabulary.dart';

/// Kurzform, damit die Liste lesbar bleibt.
typedef _W = VocabEntry;

/// Die 100 häufigsten Wortformen des Quran.
///
/// Ermittelt aus dem vollständigen Text (Ausgabe "quran-simple", Tanzil):
/// 78.245 Wörter, davon entfallen 29637 Vorkommen auf diese
/// 100 Formen — rund 38 Prozent des gesamten Textes. Gezählt werden
/// Wortformen, nicht Wurzeln; die Schreibweise ist die im Text häufigste.
const VocabCategory kQuranWords = VocabCategory(
  id: 'quran_woerter',
  name: 'Quran: häufigste Wörter',
  arabicName: 'أَكْثَرُ الْكَلِمَاتِ وُرُودًا',
  icon: Icons.menu_book_outlined,
  color: Color(0xFF1B5E4A),
  softColor: Color(0x241B5E4A),
  entries: <VocabEntry>[
      _W('von, aus', 'مِنْ', 'min'),  // 2763×
      _W('Allah', 'اللَّهِ', 'allahi'),  // 2265×
      _W('in', 'فِي', 'fi'),  // 1185×
      _W('was; nicht', 'مَا', 'ma'),  // 1010×
      _W('wahrlich, gewiss', 'إِنَّ', 'inna'),  // 966×
      _W('nicht, kein', 'لَا', 'la'),  // 812×
      _W('diejenigen, die', 'الَّذِينَ', 'alladhina'),  // 810×
      _W('auf, über', 'عَلَىٰ', '\'ala'),  // 670×
      _W('außer, nur', 'إِلَّا', 'illa'),  // 664×
      _W('und nicht', 'وَلَا', 'wa-la'),  // 658×
      _W('und was; und nicht', 'وَمَا', 'wa-ma'),  // 646×
      _W('dass', 'أَنْ', 'an'),  // 638×
      _W('er sagte', 'قَالَ', 'qala'),  // 416×
      _W('zu, nach', 'إِلَىٰ', 'ila'),  // 405×
      _W('für sie, ihnen', 'لَهُمْ', 'lahum'),  // 373×
      _W('o (Anrede)', 'يَا', 'ya'),  // 350×
      _W('und wer', 'وَمَنْ', 'wa-man'),  // 342×
      _W('dann, danach', 'ثُمَّ', 'thumma'),  // 340×
      _W('für euch', 'لَكُمْ', 'lakum'),  // 337×
      _W('mit ihm, damit', 'بِهِ', 'bihi'),  // 327×
      _W('er war', 'كَانَ', 'kana'),  // 323×
      _W('mit dem, was', 'بِمَا', 'bima'),  // 296×
      _W('sag!', 'قُلْ', 'qul'),  // 294×
      _W('die Erde', 'الْأَرْضِ', 'al-ardi'),  // 287×
      _W('jenes, das da', 'ذَٰلِكَ', 'dhalika'),  // 280×
      _W('oder', 'أَوْ', 'aw'),  // 280×
      _W('für ihn, ihm', 'لَهُ', 'lahu'),  // 275×
      _W('derjenige, der', 'الَّذِي', 'alladhi'),  // 268×
      _W('er', 'هُوَ', 'huwa'),  // 265×
      _W('sie glaubten', 'آمَنُوا', 'amanu'),  // 263×
      _W('sie (Mehrzahl)', 'هُمْ', 'hum'),  // 261×
      _W('und wenn', 'وَإِنْ', 'wa-in'),  // 254×
      _W('sie sagten', 'قَالُوا', 'qalu'),  // 250×
      _W('jeder, alles', 'كُلِّ', 'kulli'),  // 245×
      _W('darin', 'فِيهَا', 'fiha'),  // 241×
      _W('und Allah', 'وَاللَّهُ', 'wa-llahu'),  // 240×
      _W('sie waren', 'كَانُوا', 'kanu'),  // 229×
      _W('von, über', 'عَنْ', '\'an'),  // 223×
      _W('wenn, sobald', 'إِذَا', 'idha'),  // 221×
      _W('dein Herr', 'رَبِّكَ', 'rabbika'),  // 220×
      _W('am Tag', 'يَوْمَ', 'yawma'),  // 217×
      _W('über sie, auf ihnen', 'عَلَيْهِمْ', '\'alayhim'),  // 214×
      _W('eine Sache, etwas', 'شَيْءٍ', 'shay\'in'),  // 190×
      _W('dieser', 'هَٰذَا', 'hadha'),  // 190×
      _W('sie leugneten', 'كَفَرُوا', 'kafaru'),  // 189×
      _W('ihr wart', 'كُنْتُمْ', 'kuntum'),  // 188×
      _W('die Menschen', 'النَّاسِ', 'an-nasi'),  // 182×
      _W('die Himmel', 'السَّمَاوَاتِ', 'as-samawati'),  // 182×
      _W('nicht (Vergangenheit)', 'لَمْ', 'lam'),  // 178×
      _W('und er', 'وَهُوَ', 'wa-huwa'),  // 171×
      _W('wenn nun', 'فَإِنْ', 'fa-in'),  // 168×
      _W('als, damals', 'إِذْ', 'idh'),  // 165×
      _W('und diejenigen, die', 'وَالَّذِينَ', 'wa-lladhina'),  // 164×
      _W('auf euch', 'عَلَيْكُمْ', '\'alaykum'),  // 164×
      _W('das Buch, die Schrift', 'الْكِتَابَ', 'al-kitaba'),  // 163×
      _W('der Allerbarmer', 'الرَّحْمَٰنِ', 'ar-rahmani'),  // 157×
      _W('und die Erde', 'وَالْأَرْضِ', 'wa-l-ardi'),  // 157×
      _W('wahrlich, Wir', 'إِنَّا', 'inna'),  // 156×
      _W('so nicht', 'فَلَا', 'fa-la'),  // 156×
      _W('von ihnen', 'مِنْهُمْ', 'minhum'),  // 153×
      _W('Strafe, Pein', 'عَذَابٌ', '\'adhabun'),  // 150×
      _W('o du, o ihr', 'أَيُّهَا', 'ayyuha'),  // 150×
      _W('wahrlich, er', 'إِنَّهُ', 'innahu'),  // 147×
      _W('der Barmherzige', 'الرَّحِيمِ', 'ar-rahimi'),  // 146×
      _W('nach', 'بَعْدِ', 'ba\'di'),  // 146×
      _W('auf ihm', 'عَلَيْهِ', '\'alayhi'),  // 146×
      _W('bis', 'حَتَّىٰ', 'hatta'),  // 142×
      _W('an Allah', 'بِاللَّهِ', 'billahi'),  // 139×
      _W('und sie', 'وَهُمْ', 'wa-hum'),  // 137×
      _W('und sobald', 'وَإِذَا', 'wa-idha'),  // 134×
      _W('jene', 'أُولَٰئِكَ', 'ula\'ika'),  // 133×
      _W('oder (in Fragen)', 'أَمْ', 'am'),  // 131×
      _W('wahrlich, ich', 'إِنِّي', 'inni'),  // 131×
      _W('Herr', 'رَبِّ', 'rabbi'),  // 130×
      _W('Mose (Mūsā)', 'مُوسَىٰ', 'musa'),  // 129×
      _W('und wahrlich', 'وَلَقَدْ', 'wa-laqad'),  // 129×
      _W('darin (mask.)', 'فِيهِ', 'fihi'),  // 127×
      _W('vielmehr, nein', 'بَلْ', 'bal'),  // 127×
      _W('Volk, Leute', 'قَوْمِ', 'qawmi'),  // 126×
      _W('schon, bereits', 'قَدْ', 'qad'),  // 126×
      _W('bei', 'عِنْدَ', '\'inda'),  // 119×
      _W('vorher', 'قَبْلُ', 'qablu'),  // 118×
      _W('für Allah, Allah gehört', 'لِلَّهِ', 'lillahi'),  // 116×
      _W('besser, Gutes', 'خَيْرٌ', 'khayrun'),  // 116×
      _W('er will', 'يَشَاءُ', 'yasha\'u'),  // 116×
      _W('im Namen', 'بِسْمِ', 'bismi'),  // 115×
      _W('das Diesseits', 'الدُّنْيَا', 'ad-dunya'),  // 115×
      _W('nur, lediglich', 'إِنَّمَا', 'innama'),  // 113×
      _W('aber', 'وَلَٰكِنْ', 'wa-lakin'),  // 112×
      _W('ihr Herr', 'رَبِّهِمْ', 'rabbihim'),  // 111×
      _W('und selbst wenn', 'وَلَوْ', 'wa-law'),  // 111×
      _W('von dem, was', 'مِمَّا', 'mimma'),  // 111×
      _W('der Himmel', 'السَّمَاءِ', 'as-sama\'i'),  // 109×
      _W('die Wahrheit', 'الْحَقُّ', 'al-haqqu'),  // 109×
      _W('von euch', 'مِنْكُمْ', 'minkum'),  // 107×
      _W('allwissend', 'عَلِيمٌ', '\'alimun'),  // 106×
      _W('unser Herr', 'رَبَّنَا', 'rabbana'),  // 106×
      _W('euer Herr', 'رَبِّكُمْ', 'rabbikum'),  // 102×
      _W('das Feuer', 'النَّارِ', 'an-nari'),  // 102×
      _W('als dann', 'فَلَمَّا', 'fa-lamma'),  // 101×
  ],
);
