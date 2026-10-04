import '../models/azkar.dart';
import '../models/quran.dart';
import 'quran_data.dart';

/// Die Azkar für Morgen und Abend.
///
/// ## Woher die Texte kommen
///
/// **Der quranische Teil wird nicht abgetippt.** Āyat al-Kursī steht unten
/// unverändert in der Tanzil-Ausgabe „quran-simple" (bezogen über
/// api.alquran.cloud), aus derselben Quelle wie der übrige Quran-Text dieser
/// App. Al-Iḫlāṣ, Al-Falaq und An-Nās kommen direkt aus [kSuras] — sie liegen
/// bereits im Repository, und sie hier ein zweites Mal hinzuschreiben hieße,
/// zwei Fassungen zu pflegen, die irgendwann auseinanderlaufen.
///
/// **Die Hadith-Azkar sind von Hand geschrieben**, nach dem Bestand, wie ihn
/// „Ḥiṣn al-Muslim" zusammenstellt, jeweils mit Sammlung und Nummer am
/// Eintrag.
///
/// > **Vor dem Verlassen prüfen lassen.** Bei Tashkīl von Hand sind Fehler
/// > möglich, und bei einem Gebetstext wiegt ein falsches Zeichen schwerer
/// > als anderswo. Jeder Eintrag trägt seine Quelle, damit sich das
/// > nachschlagen lässt; Korrekturen sind hier eine Zeile.
///
/// Die deutschen Zeilen sind — wie beim Quran-Teil — eine Verständnishilfe
/// und ersetzen keine anerkannte Übersetzung.

/// Āyat al-Kursī, Sure 2, Vers 255.
///
/// Unverändert aus der Tanzil-Ausgabe „quran-simple".
const String _ayatAlKursi =
    'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ '
    'وَلَا نَوْمٌ ۚ لَهُ مَا فِي السَّمَاوَاتِ وَمَا فِي الْأَرْضِ ۗ مَنْ ذَا '
    'الَّذِي يَشْفَعُ عِنْدَهُ إِلَّا بِإِذْنِهِ ۚ يَعْلَمُ مَا بَيْنَ أَيْدِيهِمْ '
    'وَمَا خَلْفَهُمْ ۖ وَلَا يُحِيطُونَ بِشَيْءٍ مِنْ عِلْمِهِ إِلَّا بِمَا شَاءَ ۚ '
    'وَسِعَ كُرْسِيُّهُ السَّمَاوَاتِ وَالْأَرْضَ ۖ وَلَا يَئُودُهُ حِفْظُهُمَا ۚ '
    'وَهُوَ الْعَلِيُّ الْعَظِيمُ';

/// Der Text einer Sure aus [kSuras], Vers für Vers zusammengesetzt.
///
/// Genau deshalb steht er nicht noch einmal hier: Eine zweite Fassung wäre
/// eine zweite Wahrheit.
String suraText(int number) {
  final QuranSura sura =
      kSuras.firstWhere((QuranSura s) => s.number == number);
  return sura.verses.map((QuranVerse v) => v.arabic).join(' ');
}

const Set<AzkarTime> _beide = <AzkarTime>{AzkarTime.morgens, AzkarTime.abends};
const Set<AzkarTime> _nurMorgens = <AzkarTime>{AzkarTime.morgens};
const Set<AzkarTime> _nurAbends = <AzkarTime>{AzkarTime.abends};

/// Alle Azkar, in der Reihenfolge, in der sie gesprochen werden.
List<Dhikr> get kAzkar => <Dhikr>[
      // ---- Leicht: die fünf, die auch an einem schlechten Tag gehen ------
      const Dhikr(
        id: 'ayat-al-kursi',
        arabic: _ayatAlKursi,
        transliteration:
            'Allāhu lā ilāha illā huwa l-ḥayyu l-qayyūm. Lā taʾḫuḏuhū sinatun '
            'wa-lā naum. Lahū mā fī s-samāwāti wa-mā fī l-arḍ. Man ḏā llaḏī '
            'yašfaʿu ʿindahū illā bi-iḏnih. Yaʿlamu mā baina aidīhim wa-mā '
            'ḫalfahum, wa-lā yuḥīṭūna bi-šaiʾin min ʿilmihī illā bi-mā šāʾ. '
            'Wasiʿa kursiyyuhu s-samāwāti wa-l-arḍ, wa-lā yaʾūduhū ḥifẓuhumā, '
            'wa-huwa l-ʿaliyyu l-ʿaẓīm.',
        german:
            'Allah — es gibt keinen Gott außer Ihm, dem Lebendigen, dem '
            'Beständigen. Ihn überkommt weder Schlummer noch Schlaf. Ihm '
            'gehört, was in den Himmeln und was auf der Erde ist. Wer ist es, '
            'der bei Ihm Fürsprache einlegen könnte, außer mit Seiner '
            'Erlaubnis? Er weiß, was vor ihnen und was hinter ihnen liegt, '
            'sie aber umfassen nichts von Seinem Wissen außer, was Er will. '
            'Sein Thronschemel umfasst die Himmel und die Erde, und ihre '
            'Behütung beschwert Ihn nicht. Er ist der Erhabene, der '
            'Gewaltige.',
        source: 'Quran 2:255',
        times: _beide,
        level: AzkarLevel.leicht,
        note: 'Wer sie am Morgen spricht, steht bis zum Abend unter Schutz '
            '(an-Nasāʾī, ʿAmal al-Yaum wa-l-Laila 961).',
      ),
      Dhikr(
        id: 'sura-ikhlas',
        arabic: suraText(112),
        transliteration:
            'Qul huwa llāhu aḥad. Allāhu ṣ-ṣamad. Lam yalid wa-lam yūlad. '
            'Wa-lam yakun lahū kufuwan aḥad.',
        german:
            'Sag: Er ist Allah, ein Einziger. Allah, der Absolute, auf den '
            'alles angewiesen ist. Er hat nicht gezeugt und ist nicht gezeugt '
            'worden, und niemand ist Ihm ebenbürtig.',
        source: 'Quran 112',
        count: 3,
        times: _beide,
        level: AzkarLevel.leicht,
      ),
      Dhikr(
        id: 'sura-falaq',
        arabic: suraText(113),
        transliteration:
            'Qul aʿūḏu bi-rabbi l-falaq. Min šarri mā ḫalaq. Wa-min šarri '
            'ġāsiqin iḏā waqab. Wa-min šarri n-naffāṯāti fī l-ʿuqad. Wa-min '
            'šarri ḥāsidin iḏā ḥasad.',
        german:
            'Sag: Ich suche Zuflucht beim Herrn des Tagesanbruchs vor dem '
            'Übel dessen, was Er erschaffen hat, vor dem Übel der Dunkelheit, '
            'wenn sie hereinbricht, vor dem Übel derer, die in die Knoten '
            'blasen, und vor dem Übel eines Neiders, wenn er neidet.',
        source: 'Quran 113',
        count: 3,
        times: _beide,
        level: AzkarLevel.leicht,
      ),
      Dhikr(
        id: 'sura-nas',
        arabic: suraText(114),
        transliteration:
            'Qul aʿūḏu bi-rabbi n-nās. Maliki n-nās. Ilāhi n-nās. Min šarri '
            'l-waswāsi l-ḫannās. Allaḏī yuwaswisu fī ṣudūri n-nās. Mina '
            'l-ǧinnati wa-n-nās.',
        german:
            'Sag: Ich suche Zuflucht beim Herrn der Menschen, dem König der '
            'Menschen, dem Gott der Menschen, vor dem Übel des Einflüsterers, '
            'der sich zurückzieht, der in die Brust der Menschen einflüstert, '
            'von den Dschinn und den Menschen.',
        source: 'Quran 114',
        count: 3,
        times: _beide,
        level: AzkarLevel.leicht,
        note: 'Die drei Suren je dreimal, morgens und abends '
            '(Abū Dāwūd 5082, at-Tirmiḏī 3575).',
      ),
      const Dhikr(
        id: 'sayyid-al-istighfar',
        arabic:
            'اللَّهُمَّ أَنْتَ رَبِّي لَا إِلَهَ إِلَّا أَنْتَ، خَلَقْتَنِي وَأَنَا '
            'عَبْدُكَ، وَأَنَا عَلَى عَهْدِكَ وَوَعْدِكَ مَا اسْتَطَعْتُ، أَعُوذُ '
            'بِكَ مِنْ شَرِّ مَا صَنَعْتُ، أَبُوءُ لَكَ بِنِعْمَتِكَ عَلَيَّ، '
            'وَأَبُوءُ بِذَنْبِي فَاغْفِرْ لِي فَإِنَّهُ لَا يَغْفِرُ الذُّنُوبَ '
            'إِلَّا أَنْتَ',
        transliteration:
            'Allāhumma anta rabbī, lā ilāha illā anta, ḫalaqtanī wa-anā '
            'ʿabduk, wa-anā ʿalā ʿahdika wa-waʿdika mā staṭaʿt. Aʿūḏu bika min '
            'šarri mā ṣanaʿt. Abūʾu laka bi-niʿmatika ʿalayya, wa-abūʾu '
            'bi-ḏanbī fa-ġfir lī, fa-innahū lā yaġfiru ḏ-ḏunūba illā anta.',
        german:
            'O Allah, Du bist mein Herr, es gibt keinen Gott außer Dir. Du '
            'hast mich erschaffen, und ich bin Dein Diener. Ich halte mich an '
            'Deinen Bund und Dein Versprechen, so gut ich kann. Ich suche '
            'Zuflucht bei Dir vor dem Übel dessen, was ich getan habe. Ich '
            'bekenne Dir Deine Gnade an mir, und ich bekenne meine Schuld — '
            'so vergib mir, denn niemand vergibt die Sünden außer Dir.',
        source: 'al-Buḫārī 6306',
        times: _beide,
        level: AzkarLevel.leicht,
        note: 'Der „Herr der Vergebungsbitten".',
      ),

      // ---- Voll ----------------------------------------------------------
      const Dhikr(
        id: 'asbahna-morgens',
        arabic:
            'أَصْبَحْنَا وَأَصْبَحَ الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا '
            'إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ '
            'وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        transliteration:
            'Aṣbaḥnā wa-aṣbaḥa l-mulku li-llāh, wa-l-ḥamdu li-llāh, lā ilāha '
            'illā llāhu waḥdahū lā šarīka lah, lahu l-mulku wa-lahu l-ḥamd, '
            'wa-huwa ʿalā kulli šaiʾin qadīr.',
        german:
            'Wir sind in den Morgen getreten, und die Herrschaft ist Allahs '
            'geworden. Alles Lob gebührt Allah. Es gibt keinen Gott außer '
            'Allah allein, Er hat keinen Teilhaber. Sein ist die Herrschaft, '
            'Sein ist das Lob, und Er hat Macht über alle Dinge.',
        source: 'Muslim 2723',
        times: _nurMorgens,
        level: AzkarLevel.voll,
      ),
      const Dhikr(
        id: 'amsayna-abends',
        arabic:
            'أَمْسَيْنَا وَأَمْسَى الْمُلْكُ لِلَّهِ، وَالْحَمْدُ لِلَّهِ، لَا '
            'إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ '
            'وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        transliteration:
            'Amsainā wa-amsā l-mulku li-llāh, wa-l-ḥamdu li-llāh, lā ilāha '
            'illā llāhu waḥdahū lā šarīka lah, lahu l-mulku wa-lahu l-ḥamd, '
            'wa-huwa ʿalā kulli šaiʾin qadīr.',
        german:
            'Wir sind in den Abend getreten, und die Herrschaft ist Allahs '
            'geworden. Alles Lob gebührt Allah. Es gibt keinen Gott außer '
            'Allah allein, Er hat keinen Teilhaber. Sein ist die Herrschaft, '
            'Sein ist das Lob, und Er hat Macht über alle Dinge.',
        source: 'Muslim 2723',
        times: _nurAbends,
        level: AzkarLevel.voll,
      ),
      const Dhikr(
        id: 'bismillah-la-yadurru',
        arabic:
            'بِسْمِ اللَّهِ الَّذِي لَا يَضُرُّ مَعَ اسْمِهِ شَيْءٌ فِي الْأَرْضِ '
            'وَلَا فِي السَّمَاءِ وَهُوَ السَّمِيعُ الْعَلِيمُ',
        transliteration:
            'Bismi llāhi llaḏī lā yaḍurru maʿa smihī šaiʾun fī l-arḍi wa-lā fī '
            's-samāʾ, wa-huwa s-samīʿu l-ʿalīm.',
        german:
            'Im Namen Allahs, mit dessen Namen nichts auf der Erde und nichts '
            'im Himmel Schaden zufügen kann. Er ist der Allhörende, der '
            'Allwissende.',
        source: 'Abū Dāwūd 5088, at-Tirmiḏī 3388',
        count: 3,
        times: _beide,
        level: AzkarLevel.voll,
      ),
      const Dhikr(
        id: 'radeetu-billah',
        arabic:
            'رَضِيتُ بِاللَّهِ رَبًّا، وَبِالْإِسْلَامِ دِينًا، وَبِمُحَمَّدٍ '
            'صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ نَبِيًّا',
        transliteration:
            'Raḍītu bi-llāhi rabban, wa-bi-l-islāmi dīnan, wa-bi-Muḥammadin '
            'ṣallā llāhu ʿalaihi wa-sallama nabiyyan.',
        german:
            'Ich bin zufrieden mit Allah als Herrn, mit dem Islam als Religion '
            'und mit Muhammad — Allah segne ihn und schenke ihm Frieden — als '
            'Prophet.',
        source: 'Abū Dāwūd 5072, at-Tirmiḏī 3389',
        count: 3,
        times: _beide,
        level: AzkarLevel.voll,
      ),
      const Dhikr(
        id: 'hasbiyallah',
        arabic:
            'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ، عَلَيْهِ تَوَكَّلْتُ، '
            'وَهُوَ رَبُّ الْعَرْشِ الْعَظِيمِ',
        transliteration:
            'Ḥasbiya llāhu lā ilāha illā huwa, ʿalaihi tawakkaltu, wa-huwa '
            'rabbu l-ʿarši l-ʿaẓīm.',
        german:
            'Allah genügt mir. Es gibt keinen Gott außer Ihm. Auf Ihn vertraue '
            'ich, und Er ist der Herr des gewaltigen Thrones.',
        source: 'Abū Dāwūd 5081',
        count: 7,
        times: _beide,
        level: AzkarLevel.voll,
      ),
      const Dhikr(
        id: 'audhu-kalimat',
        arabic:
            'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
        transliteration:
            'Aʿūḏu bi-kalimāti llāhi t-tāmmāti min šarri mā ḫalaq.',
        german:
            'Ich suche Zuflucht bei den vollkommenen Worten Allahs vor dem '
            'Übel dessen, was Er erschaffen hat.',
        source: 'Muslim 2709',
        count: 3,
        times: _beide,
        level: AzkarLevel.voll,
      ),
      const Dhikr(
        id: 'subhanallah-bihamdihi-100',
        arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
        transliteration: 'Subḥāna llāhi wa-bi-ḥamdih.',
        german: 'Gepriesen sei Allah, und Ihm gebührt das Lob.',
        source: 'Muslim 2691',
        count: 100,
        times: _beide,
        level: AzkarLevel.voll,
        note: 'Hundertmal — das dauert, und es ist so gemeint.',
      ),

      // ---- Vollständig ---------------------------------------------------
      const Dhikr(
        id: 'fitrah-morgens',
        arabic:
            'أَصْبَحْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ '
            'الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ '
            'عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا '
            'مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ',
        transliteration:
            'Aṣbaḥnā ʿalā fiṭrati l-islām, wa-ʿalā kalimati l-iḫlāṣ, wa-ʿalā '
            'dīni nabiyyinā Muḥammadin ṣallā llāhu ʿalaihi wa-sallam, wa-ʿalā '
            'millati abīnā Ibrāhīma ḥanīfan musliman wa-mā kāna mina '
            'l-mušrikīn.',
        german:
            'Wir sind in den Morgen getreten auf der ursprünglichen Anlage des '
            'Islam, auf dem Wort der Aufrichtigkeit, auf der Religion unseres '
            'Propheten Muhammad — Allah segne ihn und schenke ihm Frieden — '
            'und auf dem Weg unseres Vaters Ibrāhīm, der lauter und ergeben '
            'war und nicht zu den Götzendienern gehörte.',
        source: 'Aḥmad 15360',
        times: _nurMorgens,
        level: AzkarLevel.vollstaendig,
      ),
      const Dhikr(
        id: 'fitrah-abends',
        arabic:
            'أَمْسَيْنَا عَلَى فِطْرَةِ الْإِسْلَامِ، وَعَلَى كَلِمَةِ '
            'الْإِخْلَاصِ، وَعَلَى دِينِ نَبِيِّنَا مُحَمَّدٍ صَلَّى اللَّهُ '
            'عَلَيْهِ وَسَلَّمَ، وَعَلَى مِلَّةِ أَبِينَا إِبْرَاهِيمَ حَنِيفًا '
            'مُسْلِمًا وَمَا كَانَ مِنَ الْمُشْرِكِينَ',
        transliteration:
            'Amsainā ʿalā fiṭrati l-islām, wa-ʿalā kalimati l-iḫlāṣ, wa-ʿalā '
            'dīni nabiyyinā Muḥammadin ṣallā llāhu ʿalaihi wa-sallam, wa-ʿalā '
            'millati abīnā Ibrāhīma ḥanīfan musliman wa-mā kāna mina '
            'l-mušrikīn.',
        german:
            'Wir sind in den Abend getreten auf der ursprünglichen Anlage des '
            'Islam, auf dem Wort der Aufrichtigkeit, auf der Religion unseres '
            'Propheten Muhammad — Allah segne ihn und schenke ihm Frieden — '
            'und auf dem Weg unseres Vaters Ibrāhīm, der lauter und ergeben '
            'war und nicht zu den Götzendienern gehörte.',
        source: 'Aḥmad 15360',
        times: _nurAbends,
        level: AzkarLevel.vollstaendig,
      ),
      const Dhikr(
        id: 'ma-asbaha-bi-nimah',
        arabic:
            'اللَّهُمَّ مَا أَصْبَحَ بِي مِنْ نِعْمَةٍ أَوْ بِأَحَدٍ مِنْ '
            'خَلْقِكَ فَمِنْكَ وَحْدَكَ لَا شَرِيكَ لَكَ، فَلَكَ الْحَمْدُ '
            'وَلَكَ الشُّكْرُ',
        transliteration:
            'Allāhumma mā aṣbaḥa bī min niʿmatin au bi-aḥadin min ḫalqika '
            'fa-minka waḥdaka lā šarīka lak, fa-laka l-ḥamdu wa-laka š-šukr.',
        german:
            'O Allah, welche Gabe auch immer mir oder einem Deiner Geschöpfe '
            'an diesem Morgen zuteilwird — sie kommt von Dir allein, Du hast '
            'keinen Teilhaber. Dir gebührt das Lob und Dir der Dank.',
        source: 'Abū Dāwūd 5073',
        times: _nurMorgens,
        level: AzkarLevel.vollstaendig,
        note: 'Am Abend „amsā bī" statt „aṣbaḥa bī".',
      ),
      const Dhikr(
        id: 'afwa-wal-afiyah',
        arabic:
            'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ وَالْعَافِيَةَ فِي '
            'الدُّنْيَا وَالْآخِرَةِ، اللَّهُمَّ إِنِّي أَسْأَلُكَ الْعَفْوَ '
            'وَالْعَافِيَةَ فِي دِينِي وَدُنْيَايَ وَأَهْلِي وَمَالِي',
        transliteration:
            'Allāhumma innī asʾaluka l-ʿafwa wa-l-ʿāfiyata fī d-dunyā '
            'wa-l-āḫira. Allāhumma innī asʾaluka l-ʿafwa wa-l-ʿāfiyata fī dīnī '
            'wa-dunyāya wa-ahlī wa-mālī.',
        german:
            'O Allah, ich bitte Dich um Verzeihung und Wohlergehen in dieser '
            'Welt und im Jenseits. O Allah, ich bitte Dich um Verzeihung und '
            'Wohlergehen in meiner Religion, meinem Leben, bei meiner Familie '
            'und meinem Besitz.',
        source: 'Abū Dāwūd 5074, Ibn Māǧa 3871',
        times: _beide,
        level: AzkarLevel.vollstaendig,
      ),
      const Dhikr(
        id: 'afini-fi-badani',
        arabic:
            'اللَّهُمَّ عَافِنِي فِي بَدَنِي، اللَّهُمَّ عَافِنِي فِي سَمْعِي، '
            'اللَّهُمَّ عَافِنِي فِي بَصَرِي، لَا إِلَهَ إِلَّا أَنْتَ',
        transliteration:
            'Allāhumma ʿāfinī fī badanī. Allāhumma ʿāfinī fī samʿī. Allāhumma '
            'ʿāfinī fī baṣarī. Lā ilāha illā anta.',
        german:
            'O Allah, schenke meinem Körper Wohlergehen. O Allah, schenke '
            'meinem Gehör Wohlergehen. O Allah, schenke meinem Augenlicht '
            'Wohlergehen. Es gibt keinen Gott außer Dir.',
        source: 'Abū Dāwūd 5090',
        count: 3,
        times: _beide,
        level: AzkarLevel.vollstaendig,
      ),
      const Dhikr(
        id: 'alim-al-ghayb',
        arabic:
            'اللَّهُمَّ عَالِمَ الْغَيْبِ وَالشَّهَادَةِ، فَاطِرَ السَّمَاوَاتِ '
            'وَالْأَرْضِ، رَبَّ كُلِّ شَيْءٍ وَمَلِيكَهُ، أَشْهَدُ أَنْ لَا '
            'إِلَهَ إِلَّا أَنْتَ، أَعُوذُ بِكَ مِنْ شَرِّ نَفْسِي وَمِنْ شَرِّ '
            'الشَّيْطَانِ وَشِرْكِهِ',
        transliteration:
            'Allāhumma ʿālima l-ġaibi wa-š-šahāda, fāṭira s-samāwāti wa-l-arḍ, '
            'rabba kulli šaiʾin wa-malīkah, ašhadu an lā ilāha illā anta. '
            'Aʿūḏu bika min šarri nafsī wa-min šarri š-šaiṭāni wa-širkih.',
        german:
            'O Allah, Kenner des Verborgenen und des Sichtbaren, Schöpfer der '
            'Himmel und der Erde, Herr und Eigner aller Dinge: Ich bezeuge, '
            'dass es keinen Gott gibt außer Dir. Ich suche Zuflucht bei Dir '
            'vor dem Übel meiner selbst und vor dem Übel des Satans und seiner '
            'Verführung zum Götzendienst.',
        source: 'at-Tirmiḏī 3392',
        times: _beide,
        level: AzkarLevel.vollstaendig,
      ),
      const Dhikr(
        id: 'la-ilaha-illallah-100',
        arabic:
            'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ '
            'الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        transliteration:
            'Lā ilāha illā llāhu waḥdahū lā šarīka lah, lahu l-mulku wa-lahu '
            'l-ḥamd, wa-huwa ʿalā kulli šaiʾin qadīr.',
        german:
            'Es gibt keinen Gott außer Allah allein, Er hat keinen Teilhaber. '
            'Sein ist die Herrschaft, Sein ist das Lob, und Er hat Macht über '
            'alle Dinge.',
        source: 'al-Buḫārī 3293, Muslim 2691',
        count: 100,
        times: _nurMorgens,
        level: AzkarLevel.vollstaendig,
      ),
      const Dhikr(
        id: 'subhanallah-adada-khalqihi',
        arabic:
            'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ عَدَدَ خَلْقِهِ، وَرِضَا نَفْسِهِ، '
            'وَزِنَةَ عَرْشِهِ، وَمِدَادَ كَلِمَاتِهِ',
        transliteration:
            'Subḥāna llāhi wa-bi-ḥamdihī ʿadada ḫalqih, wa-riḍā nafsih, '
            'wa-zinata ʿarših, wa-midāda kalimātih.',
        german:
            'Gepriesen sei Allah und Ihm gebührt das Lob — so viel wie die '
            'Zahl Seiner Geschöpfe, so viel wie Sein Wohlgefallen, so schwer '
            'wie Sein Thron und so viel wie die Tinte Seiner Worte.',
        source: 'Muslim 2726',
        count: 3,
        times: _nurMorgens,
        level: AzkarLevel.vollstaendig,
      ),
      const Dhikr(
        id: 'astaghfirullah-100',
        arabic: 'أَسْتَغْفِرُ اللَّهَ وَأَتُوبُ إِلَيْهِ',
        transliteration: 'Astaġfiru llāha wa-atūbu ilaih.',
        german: 'Ich bitte Allah um Vergebung und wende mich Ihm reuig zu.',
        source: 'al-Buḫārī 6307, Muslim 2702',
        count: 100,
        times: _beide,
        level: AzkarLevel.vollstaendig,
      ),
      const Dhikr(
        id: 'ya-hayyu-ya-qayyum',
        arabic:
            'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ، أَصْلِحْ لِي '
            'شَأْنِي كُلَّهُ، وَلَا تَكِلْنِي إِلَى نَفْسِي طَرْفَةَ عَيْنٍ',
        transliteration:
            'Yā Ḥayyu yā Qayyūm, bi-raḥmatika astaġīṯ, aṣliḥ lī šaʾnī kullah, '
            'wa-lā takilnī ilā nafsī ṭarfata ʿain.',
        german:
            'O Lebendiger, o Beständiger, um Deiner Barmherzigkeit willen rufe '
            'ich um Hilfe: Bring meine ganze Angelegenheit in Ordnung und '
            'überlass mich nicht mir selbst, nicht einen Wimpernschlag lang.',
        source: 'an-Nasāʾī, ʿAmal al-Yaum wa-l-Laila 575',
        times: _beide,
        level: AzkarLevel.vollstaendig,
      ),
    ];

/// Die Azkar einer Tageshälfte für eine Stufe.
List<Dhikr> azkarFor({required AzkarTime time, required AzkarLevel level}) =>
    <Dhikr>[
      for (final Dhikr d in kAzkar)
        if (d.giltFuer(time) && level.umfasst(d.level)) d,
    ];

/// Was auf dieser Stufe **nicht** dabei ist — die Liste unter „Mehr, wenn du
/// magst". Eine Stufe ist eine Voreinstellung, keine Mauer.
List<Dhikr> azkarDarueberHinaus({
  required AzkarTime time,
  required AzkarLevel level,
}) =>
    <Dhikr>[
      for (final Dhikr d in kAzkar)
        if (d.giltFuer(time) && !level.umfasst(d.level)) d,
    ];
