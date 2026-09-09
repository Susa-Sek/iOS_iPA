import '../models/quran.dart';

/// Kurze Suren, Wort für Wort.
///
/// Der arabische Text stammt unverändert aus der Ausgabe "quran-simple"
/// (Tanzil-Projekt, bezogen über api.alquran.cloud) und wurde nicht von Hand
/// abgetippt. Die deutschen Zeilen sind eine schlichte Verständnishilfe zum
/// Sprachenlernen und ersetzen keine anerkannte Übersetzung.

/// Die Basmala, mit der jede Sure außer at-Tauba eröffnet wird.
const QuranVerse kBasmala = QuranVerse(
  number: 0,
  german: 'Im Namen Allahs, des Allerbarmers, des Barmherzigen.',
  words: <QuranWord>[
      QuranWord('بِسْمِ', 'bismi', 'im Namen'),
      QuranWord('اللَّهِ', 'allahi', 'Allahs'),
      QuranWord('الرَّحْمَٰنِ', 'ar-rahmani', 'des Allerbarmers'),
      QuranWord('الرَّحِيمِ', 'ar-rahimi', 'des Barmherzigen'),
  ],
);

const List<QuranSura> kSuras = <QuranSura>[
  QuranSura(
    number: 1,
    arabicName: 'سُورَةُ ٱلْفَاتِحَةِ',
    name: 'Al-Fātiḥa',
    meaning: 'Die Eröffnende',
    about: 'Die erste Sure des Quran und Teil jedes Gebets. Sie ist zugleich der beste Einstieg: sieben kurze Verse, die viele Grundwörter enthalten.',
    opensWithBasmala: false,
    verses: <QuranVerse>[
      QuranVerse(
        number: 1,
        german: 'Im Namen Allahs, des Allerbarmers, des Barmherzigen.',
        words: <QuranWord>[
          QuranWord('بِسْمِ', 'bismi', 'im Namen'),
          QuranWord('اللَّهِ', 'allahi', 'Allahs'),
          QuranWord('الرَّحْمَٰنِ', 'ar-rahmani', 'des Allerbarmers'),
          QuranWord('الرَّحِيمِ', 'ar-rahimi', 'des Barmherzigen'),
        ],
      ),
      QuranVerse(
        number: 2,
        german: 'Alles Lob gehört Allah, dem Herrn der Welten,',
        words: <QuranWord>[
          QuranWord('الْحَمْدُ', 'al-hamdu', 'das Lob'),
          QuranWord('لِلَّهِ', 'lillahi', 'gehört Allah'),
          QuranWord('رَبِّ', 'rabbi', 'dem Herrn'),
          QuranWord('الْعَالَمِينَ', 'al-\'alamina', 'der Welten'),
        ],
      ),
      QuranVerse(
        number: 3,
        german: 'dem Allerbarmer, dem Barmherzigen,',
        words: <QuranWord>[
          QuranWord('الرَّحْمَٰنِ', 'ar-rahmani', 'dem Allerbarmer'),
          QuranWord('الرَّحِيمِ', 'ar-rahimi', 'dem Barmherzigen'),
        ],
      ),
      QuranVerse(
        number: 4,
        german: 'dem Herrscher über den Tag des Gerichts.',
        words: <QuranWord>[
          QuranWord('مَالِكِ', 'maliki', 'dem Herrscher über'),
          QuranWord('يَوْمِ', 'yawmi', 'den Tag'),
          QuranWord('الدِّينِ', 'ad-dini', 'des Gerichts'),
        ],
      ),
      QuranVerse(
        number: 5,
        german: 'Dir allein dienen wir, und Dich allein bitten wir um Hilfe.',
        words: <QuranWord>[
          QuranWord('إِيَّاكَ', 'iyyaka', 'Dir allein'),
          QuranWord('نَعْبُدُ', 'na\'budu', 'dienen wir'),
          QuranWord('وَإِيَّاكَ', 'wa-iyyaka', 'und Dich allein'),
          QuranWord('نَسْتَعِينُ', 'nasta\'inu', 'bitten wir um Hilfe'),
        ],
      ),
      QuranVerse(
        number: 6,
        german: 'Leite uns den geraden Weg,',
        words: <QuranWord>[
          QuranWord('اهْدِنَا', 'ihdina', 'leite uns'),
          QuranWord('الصِّرَاطَ', 'as-sirata', 'den Weg'),
          QuranWord('الْمُسْتَقِيمَ', 'al-mustaqima', 'den geraden'),
        ],
      ),
      QuranVerse(
        number: 7,
        german: 'den Weg derer, denen Du Gnade erwiesen hast, nicht derer, die Deinen Zorn erregt haben, und nicht der Irrenden.',
        words: <QuranWord>[
          QuranWord('صِرَاطَ', 'sirata', 'den Weg'),
          QuranWord('الَّذِينَ', 'alladhina', 'derer, die'),
          QuranWord('أَنْعَمْتَ', 'an\'amta', 'Du hast begnadet'),
          QuranWord('عَلَيْهِمْ', '\'alayhim', 'ihnen'),
          QuranWord('غَيْرِ', 'ghayri', 'nicht'),
          QuranWord('الْمَغْضُوبِ', 'al-maghdubi', 'derer, denen gezürnt wird'),
          QuranWord('عَلَيْهِمْ', '\'alayhim', 'über sie'),
          QuranWord('وَلَا', 'wa-la', 'und nicht'),
          QuranWord('الضَّالِّينَ', 'ad-dallina', 'der Irrenden'),
        ],
      ),
    ],
  ),
  QuranSura(
    number: 103,
    arabicName: 'سُورَةُ العَصۡرِ',
    name: 'Al-ʿAṣr',
    meaning: 'Die Zeit',
    about: 'Drei Verse, die als eine der kürzesten Suren gelten und dennoch eine vollständige Aussage tragen.',
    opensWithBasmala: true,
    verses: <QuranVerse>[
      QuranVerse(
        number: 1,
        german: 'Bei der Zeit!',
        words: <QuranWord>[
          QuranWord('وَالْعَصْرِ', 'wa-l-\'asri', 'bei der Zeit'),
        ],
      ),
      QuranVerse(
        number: 2,
        german: 'Der Mensch ist wahrlich im Verlust,',
        words: <QuranWord>[
          QuranWord('إِنَّ', 'inna', 'wahrlich'),
          QuranWord('الْإِنْسَانَ', 'al-insana', 'der Mensch'),
          QuranWord('لَفِي', 'la-fi', 'ist wahrlich im'),
          QuranWord('خُسْرٍ', 'khusrin', 'Verlust'),
        ],
      ),
      QuranVerse(
        number: 3,
        german: 'außer denen, die glauben, das Gute tun und einander zur Wahrheit und zur Geduld anhalten.',
        words: <QuranWord>[
          QuranWord('إِلَّا', 'illa', 'außer'),
          QuranWord('الَّذِينَ', 'alladhina', 'denjenigen, die'),
          QuranWord('آمَنُوا', 'amanu', 'glaubten'),
          QuranWord('وَعَمِلُوا', 'wa-\'amilu', 'und taten'),
          QuranWord('الصَّالِحَاتِ', 'as-salihati', 'die guten Werke'),
          QuranWord('وَتَوَاصَوْا', 'wa-tawasaw', 'und einander anhielten'),
          QuranWord('بِالْحَقِّ', 'bi-l-haqqi', 'zur Wahrheit'),
          QuranWord('وَتَوَاصَوْا', 'wa-tawasaw', 'und einander anhielten'),
          QuranWord('بِالصَّبْرِ', 'bi-s-sabri', 'zur Geduld'),
        ],
      ),
    ],
  ),
  QuranSura(
    number: 108,
    arabicName: 'سُورَةُ الكَوۡثَرِ',
    name: 'Al-Kauṯar',
    meaning: 'Die Fülle',
    about: 'Mit drei Versen die kürzeste Sure des Quran.',
    opensWithBasmala: true,
    verses: <QuranVerse>[
      QuranVerse(
        number: 1,
        german: 'Wahrlich, Wir haben dir die Fülle gegeben.',
        words: <QuranWord>[
          QuranWord('إِنَّا', 'inna', 'wahrlich, Wir'),
          QuranWord('أَعْطَيْنَاكَ', 'a\'taynaka', 'haben dir gegeben'),
          QuranWord('الْكَوْثَرَ', 'al-kawthara', 'die Fülle (al-Kauthar)'),
        ],
      ),
      QuranVerse(
        number: 2,
        german: 'So bete zu deinem Herrn und opfere.',
        words: <QuranWord>[
          QuranWord('فَصَلِّ', 'fa-salli', 'so bete'),
          QuranWord('لِرَبِّكَ', 'li-rabbika', 'zu deinem Herrn'),
          QuranWord('وَانْحَرْ', 'wa-nhar', 'und opfere'),
        ],
      ),
      QuranVerse(
        number: 3,
        german: 'Wahrlich, dein Hasser ist derjenige, der abgeschnitten ist.',
        words: <QuranWord>[
          QuranWord('إِنَّ', 'inna', 'wahrlich'),
          QuranWord('شَانِئَكَ', 'shani\'aka', 'dein Hasser'),
          QuranWord('هُوَ', 'huwa', 'er ist'),
          QuranWord('الْأَبْتَرُ', 'al-abtaru', 'der Abgeschnittene'),
        ],
      ),
    ],
  ),
  QuranSura(
    number: 112,
    arabicName: 'سُورَةُ الإِخۡلَاصِ',
    name: 'Al-Iḫlāṣ',
    meaning: 'Der reine Glaube',
    about: 'Vier Verse über die Einheit Gottes, oft eine der ersten Suren, die auswendig gelernt werden.',
    opensWithBasmala: true,
    verses: <QuranVerse>[
      QuranVerse(
        number: 1,
        german: 'Sag: Er ist Allah, ein Einziger.',
        words: <QuranWord>[
          QuranWord('قُلْ', 'qul', 'sag'),
          QuranWord('هُوَ', 'huwa', 'Er ist'),
          QuranWord('اللَّهُ', 'allahu', 'Allah'),
          QuranWord('أَحَدٌ', 'ahadun', 'Einer'),
        ],
      ),
      QuranVerse(
        number: 2,
        german: 'Allah, der Absolute, auf den alles angewiesen ist.',
        words: <QuranWord>[
          QuranWord('اللَّهُ', 'allahu', 'Allah'),
          QuranWord('الصَّمَدُ', 'as-samadu', 'der Absolute'),
        ],
      ),
      QuranVerse(
        number: 3,
        german: 'Er hat nicht gezeugt und ist nicht gezeugt worden,',
        words: <QuranWord>[
          QuranWord('لَمْ', 'lam', 'nicht'),
          QuranWord('يَلِدْ', 'yalid', 'hat Er gezeugt'),
          QuranWord('وَلَمْ', 'wa-lam', 'und nicht'),
          QuranWord('يُولَدْ', 'yulad', 'wurde Er gezeugt'),
        ],
      ),
      QuranVerse(
        number: 4,
        german: 'und niemand ist Ihm ebenbürtig.',
        words: <QuranWord>[
          QuranWord('وَلَمْ', 'wa-lam', 'und nicht'),
          QuranWord('يَكُنْ', 'yakun', 'ist'),
          QuranWord('لَهُ', 'lahu', 'Ihm'),
          QuranWord('كُفُوًا', 'kufuwan', 'ebenbürtig'),
          QuranWord('أَحَدٌ', 'ahadun', 'irgendeiner'),
        ],
      ),
    ],
  ),
  QuranSura(
    number: 113,
    arabicName: 'سُورَةُ الفَلَقِ',
    name: 'Al-Falaq',
    meaning: 'Der Tagesanbruch',
    about: 'Eine der beiden Schutzsuren am Ende des Quran.',
    opensWithBasmala: true,
    verses: <QuranVerse>[
      QuranVerse(
        number: 1,
        german: 'Sag: Ich suche Zuflucht beim Herrn des Tagesanbruchs',
        words: <QuranWord>[
          QuranWord('قُلْ', 'qul', 'sag'),
          QuranWord('أَعُوذُ', 'a\'udhu', 'ich suche Zuflucht'),
          QuranWord('بِرَبِّ', 'bi-rabbi', 'beim Herrn'),
          QuranWord('الْفَلَقِ', 'al-falaqi', 'des Tagesanbruchs'),
        ],
      ),
      QuranVerse(
        number: 2,
        german: 'vor dem Übel dessen, was Er erschaffen hat,',
        words: <QuranWord>[
          QuranWord('مِنْ', 'min', 'vor'),
          QuranWord('شَرِّ', 'sharri', 'dem Übel'),
          QuranWord('مَا', 'ma', 'dessen, was'),
          QuranWord('خَلَقَ', 'khalaqa', 'Er erschaffen hat'),
        ],
      ),
      QuranVerse(
        number: 3,
        german: 'und vor dem Übel der Dunkelheit, wenn sie hereinbricht,',
        words: <QuranWord>[
          QuranWord('وَمِنْ', 'wa-min', 'und vor'),
          QuranWord('شَرِّ', 'sharri', 'dem Übel'),
          QuranWord('غَاسِقٍ', 'ghasiqin', 'der Dunkelheit'),
          QuranWord('إِذَا', 'idha', 'wenn'),
          QuranWord('وَقَبَ', 'waqaba', 'sie hereinbricht'),
        ],
      ),
      QuranVerse(
        number: 4,
        german: 'und vor dem Übel derer, die auf Knoten blasen,',
        words: <QuranWord>[
          QuranWord('وَمِنْ', 'wa-min', 'und vor'),
          QuranWord('شَرِّ', 'sharri', 'dem Übel'),
          QuranWord('النَّفَّاثَاتِ', 'an-naffathati', 'derer, die blasen'),
          QuranWord('فِي', 'fi', 'auf'),
          QuranWord('الْعُقَدِ', 'al-\'uqadi', 'die Knoten'),
        ],
      ),
      QuranVerse(
        number: 5,
        german: 'und vor dem Übel eines Neiders, wenn er neidet.',
        words: <QuranWord>[
          QuranWord('وَمِنْ', 'wa-min', 'und vor'),
          QuranWord('شَرِّ', 'sharri', 'dem Übel'),
          QuranWord('حَاسِدٍ', 'hasidin', 'eines Neiders'),
          QuranWord('إِذَا', 'idha', 'wenn'),
          QuranWord('حَسَدَ', 'hasada', 'er neidet'),
        ],
      ),
    ],
  ),
  QuranSura(
    number: 114,
    arabicName: 'سُورَةُ النَّاسِ',
    name: 'An-Nās',
    meaning: 'Die Menschen',
    about: 'Die letzte Sure des Quran und die zweite der beiden Schutzsuren.',
    opensWithBasmala: true,
    verses: <QuranVerse>[
      QuranVerse(
        number: 1,
        german: 'Sag: Ich suche Zuflucht beim Herrn der Menschen,',
        words: <QuranWord>[
          QuranWord('قُلْ', 'qul', 'sag'),
          QuranWord('أَعُوذُ', 'a\'udhu', 'ich suche Zuflucht'),
          QuranWord('بِرَبِّ', 'bi-rabbi', 'beim Herrn'),
          QuranWord('النَّاسِ', 'an-nasi', 'der Menschen'),
        ],
      ),
      QuranVerse(
        number: 2,
        german: 'dem König der Menschen,',
        words: <QuranWord>[
          QuranWord('مَلِكِ', 'maliki', 'dem König'),
          QuranWord('النَّاسِ', 'an-nasi', 'der Menschen'),
        ],
      ),
      QuranVerse(
        number: 3,
        german: 'dem Gott der Menschen,',
        words: <QuranWord>[
          QuranWord('إِلَٰهِ', 'ilahi', 'dem Gott'),
          QuranWord('النَّاسِ', 'an-nasi', 'der Menschen'),
        ],
      ),
      QuranVerse(
        number: 4,
        german: 'vor dem Übel des Einflüsterers, der sich zurückzieht,',
        words: <QuranWord>[
          QuranWord('مِنْ', 'min', 'vor'),
          QuranWord('شَرِّ', 'sharri', 'dem Übel'),
          QuranWord('الْوَسْوَاسِ', 'al-waswasi', 'des Einflüsterers'),
          QuranWord('الْخَنَّاسِ', 'al-khannasi', 'der sich zurückzieht'),
        ],
      ),
      QuranVerse(
        number: 5,
        german: 'der in die Brust der Menschen einflüstert,',
        words: <QuranWord>[
          QuranWord('الَّذِي', 'alladhi', 'der'),
          QuranWord('يُوَسْوِسُ', 'yuwaswisu', 'einflüstert'),
          QuranWord('فِي', 'fi', 'in'),
          QuranWord('صُدُورِ', 'suduri', 'die Brust'),
          QuranWord('النَّاسِ', 'an-nasi', 'der Menschen'),
        ],
      ),
      QuranVerse(
        number: 6,
        german: 'von den Dschinn und den Menschen.',
        words: <QuranWord>[
          QuranWord('مِنَ', 'mina', 'von'),
          QuranWord('الْجِنَّةِ', 'al-jinnati', 'den Dschinn'),
          QuranWord('وَالنَّاسِ', 'wa-n-nasi', 'und den Menschen'),
        ],
      ),
    ],
  ),
];

/// Wurzeln und was aus ihnen wächst.
///
/// Fast jedes arabische Wort geht auf drei Konsonanten zurück, die eine
/// Grundbedeutung tragen. Wer die Wurzel erkennt, versteht Wörter, die er nie
/// gelernt hat — das ist der eigentliche Schlüssel zur Quran-Sprache.
const List<ArabicRoot> kRoots = <ArabicRoot>[
  ArabicRoot(
    letters: 'ك · ت · ب',
    meaning: 'schreiben',
    derivations: <QuranWord>[
      QuranWord('كَتَبَ', 'kataba', 'er schrieb'),
      QuranWord('كِتَاب', 'kitab', 'Buch, Schrift'),
      QuranWord('كَاتِب', 'katib', 'Schreiber'),
      QuranWord('مَكْتُوب', 'maktub', 'geschrieben'),
      QuranWord('مَكْتَبَة', 'maktaba', 'Bibliothek'),
    ],
  ),
  ArabicRoot(
    letters: 'ع · ل · م',
    meaning: 'wissen',
    derivations: <QuranWord>[
      QuranWord('عَلِمَ', "'alima", 'er wusste'),
      QuranWord('عِلْم', "'ilm", 'Wissen'),
      QuranWord('عَالِم', "'alim", 'Gelehrter'),
      QuranWord('عَلِيم', "'alim", 'allwissend'),
      QuranWord('مُعَلِّم', "mu'allim", 'Lehrer'),
      QuranWord('تَعْلِيم', "ta'lim", 'Unterricht'),
    ],
  ),
  ArabicRoot(
    letters: 'س · ل · م',
    meaning: 'heil sein, Frieden',
    derivations: <QuranWord>[
      QuranWord('سَلَام', 'salam', 'Frieden'),
      QuranWord('إِسْلَام', 'islam', 'Islam, Hingabe'),
      QuranWord('مُسْلِم', 'muslim', 'Muslim, Hingegebener'),
      QuranWord('سَلِيم', 'salim', 'heil, unversehrt'),
      QuranWord('سَلَّمَ', 'sallama', 'er grüßte'),
    ],
  ),
  ArabicRoot(
    letters: 'ح · م · د',
    meaning: 'loben',
    derivations: <QuranWord>[
      QuranWord('حَمِدَ', 'hamida', 'er lobte'),
      QuranWord('الْحَمْدُ', 'al-hamdu', 'das Lob'),
      QuranWord('مَحْمُود', 'mahmud', 'gelobt'),
      QuranWord('مُحَمَّد', 'muhammad', 'der viel Gelobte'),
      QuranWord('أَحْمَد', 'ahmad', 'der Lobenswerteste'),
    ],
  ),
  ArabicRoot(
    letters: 'ر · ح · م',
    meaning: 'sich erbarmen',
    derivations: <QuranWord>[
      QuranWord('رَحِمَ', 'rahima', 'er erbarmte sich'),
      QuranWord('رَحْمَة', 'rahma', 'Barmherzigkeit'),
      QuranWord('الرَّحْمَٰن', 'ar-rahman', 'der Allerbarmer'),
      QuranWord('الرَّحِيم', 'ar-rahim', 'der Barmherzige'),
      QuranWord('رَحِم', 'rahim', 'Mutterleib'),
    ],
  ),
  ArabicRoot(
    letters: 'ء · م · ن',
    meaning: 'sicher sein, vertrauen',
    derivations: <QuranWord>[
      QuranWord('آمَنَ', 'amana', 'er glaubte'),
      QuranWord('إِيمَان', 'iman', 'Glaube'),
      QuranWord('مُؤْمِن', "mu'min", 'Gläubiger'),
      QuranWord('أَمْن', 'amn', 'Sicherheit'),
      QuranWord('أَمَانَة', 'amana', 'Anvertrautes'),
    ],
  ),
  ArabicRoot(
    letters: 'ع · ب · د',
    meaning: 'dienen',
    derivations: <QuranWord>[
      QuranWord('عَبَدَ', "'abada", 'er diente'),
      QuranWord('عِبَادَة', "'ibada", 'Gottesdienst'),
      QuranWord('عَبْد', "'abd", 'Diener'),
      QuranWord('نَعْبُدُ', "na'budu", 'wir dienen'),
    ],
  ),
  ArabicRoot(
    letters: 'خ · ل · ق',
    meaning: 'erschaffen',
    derivations: <QuranWord>[
      QuranWord('خَلَقَ', 'khalaqa', 'er erschuf'),
      QuranWord('خَلْق', 'khalq', 'Schöpfung'),
      QuranWord('خَالِق', 'khaliq', 'Schöpfer'),
      QuranWord('مَخْلُوق', 'makhluq', 'Geschöpf'),
      QuranWord('أَخْلَاق', 'akhlaq', 'Charakter, Sitten'),
    ],
  ),
  ArabicRoot(
    letters: 'ك · ف · ر',
    meaning: 'verdecken, leugnen',
    derivations: <QuranWord>[
      QuranWord('كَفَرَ', 'kafara', 'er leugnete'),
      QuranWord('كُفْر', 'kufr', 'Leugnung'),
      QuranWord('كَافِر', 'kafir', 'Leugnender'),
      QuranWord('كَفَّارَة', 'kaffara', 'Sühne'),
    ],
  ),
  ArabicRoot(
    letters: 'ص · ل · و',
    meaning: 'beten',
    derivations: <QuranWord>[
      QuranWord('صَلَّى', 'salla', 'er betete'),
      QuranWord('صَلَاة', 'salat', 'Gebet'),
      QuranWord('مُصَلِّي', 'musalli', 'Betender'),
      QuranWord('فَصَلِّ', 'fa-salli', 'so bete'),
    ],
  ),
  ArabicRoot(
    letters: 'ق · و · ل',
    meaning: 'sagen',
    derivations: <QuranWord>[
      QuranWord('قَالَ', 'qala', 'er sagte'),
      QuranWord('قَوْل', 'qawl', 'Wort, Aussage'),
      QuranWord('قُلْ', 'qul', 'sag!'),
      QuranWord('قَالُوا', 'qalu', 'sie sagten'),
      QuranWord('مَقَالَة', 'maqala', 'Aufsatz'),
    ],
  ),
  ArabicRoot(
    letters: 'ن · ز · ل',
    meaning: 'herabsteigen',
    derivations: <QuranWord>[
      QuranWord('نَزَلَ', 'nazala', 'er stieg herab'),
      QuranWord('أَنْزَلَ', 'anzala', 'er sandte herab'),
      QuranWord('تَنْزِيل', 'tanzil', 'Herabsendung, Offenbarung'),
      QuranWord('مَنْزِل', 'manzil', 'Haus, Station'),
    ],
  ),
];
