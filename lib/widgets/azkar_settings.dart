import 'package:adhan/adhan.dart' show Madhab;
import 'package:flutter/material.dart';

import '../models/azkar.dart';
import '../state/prayer_times.dart';
import '../theme/app_theme.dart';

/// Ort, Berechnungsmethode, Maḏhab, Versatz und Stufe.
///
/// Alles an einer Stelle, erreichbar über das Zahnrad im Azkar-Reiter — wie
/// die Lerneinstellungen hinter dem Zahnrad der Kurzrunde.
class AzkarSettingsSheet extends StatelessWidget {
  const AzkarSettingsSheet({super.key});

  static Future<void> open(BuildContext context) => showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (BuildContext context) => const AzkarSettingsSheet(),
      );

  @override
  Widget build(BuildContext context) {
    final AzkarSettings settings = AzkarSettingsScope.of(context);
    final ThemeData theme = Theme.of(context);

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Azkar', style: theme.textTheme.titleLarge),
            const SizedBox(height: Insets.lg),

            // ---- Stufe ---------------------------------------------------
            Text('Wie viel', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Eine Voreinstellung, keine Mauer: Was nicht dazugehört, steht '
              'trotzdem unten und lässt sich antippen.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: Insets.sm),
            RadioGroup<AzkarLevel>(
              groupValue: settings.level,
              onChanged: (AzkarLevel? wahl) {
                if (wahl != null) settings.setLevel(wahl);
              },
              child: Column(
                children: <Widget>[
                  for (final AzkarLevel l in AzkarLevel.values)
                    RadioListTile<AzkarLevel>(
                      contentPadding: EdgeInsets.zero,
                      value: l,
                      title: Text(l.label),
                      subtitle: Text(l.hint),
                    ),
                ],
              ),
            ),

            const Divider(height: Insets.xl),

            // ---- Ort -----------------------------------------------------
            Text('Ort', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Nur für die Gebetszeiten. Die App fragt nicht nach deinem '
              'Standort — einmal einstellen genügt, danach rechnet sie '
              'offline.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: Insets.sm),
            DropdownButtonFormField<Ort>(
              initialValue: kOrte.contains(settings.ort) ? settings.ort : null,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Stadt',
              ),
              items: <DropdownMenuItem<Ort>>[
                for (final Ort o in kOrte)
                  DropdownMenuItem<Ort>(value: o, child: Text(o.name)),
              ],
              onChanged: (Ort? o) {
                if (o != null) settings.setOrt(o);
              },
            ),
            if (settings.ort case final Ort o)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  '${o.name} · ${o.lat.toStringAsFixed(3)}, '
                  '${o.lon.toStringAsFixed(3)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.hintColor),
                ),
              ),

            const Divider(height: Insets.xl),

            // ---- Methode und Maḏhab --------------------------------------
            Text('Berechnung', style: theme.textTheme.titleSmall),
            const SizedBox(height: Insets.sm),
            DropdownButtonFormField<AzkarMethod>(
              initialValue: settings.methode,
              isExpanded: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Methode',
              ),
              items: <DropdownMenuItem<AzkarMethod>>[
                for (final AzkarMethod m in AzkarMethod.values)
                  DropdownMenuItem<AzkarMethod>(
                      value: m, child: Text(m.label)),
              ],
              onChanged: (AzkarMethod? m) {
                if (m != null) settings.setMethode(m);
              },
            ),
            const SizedBox(height: Insets.md),
            SegmentedButton<Madhab>(
              segments: const <ButtonSegment<Madhab>>[
                ButtonSegment<Madhab>(
                    value: Madhab.shafi, label: Text('Šāfiʿī')),
                ButtonSegment<Madhab>(
                    value: Madhab.hanafi, label: Text('Ḥanafī')),
              ],
              selected: <Madhab>{settings.madhab},
              onSelectionChanged: (Set<Madhab> auswahl) =>
                  settings.setMadhab(auswahl.first),
            ),
            const SizedBox(height: 6),
            Text(
              'Der Maḏhab verschiebt ʿAsr — und damit den Beginn der '
              'Abend-Azkar.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),

            const Divider(height: Insets.xl),

            // ---- Versatz -------------------------------------------------
            Text('Erinnerung', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'Wie lange nach Fajr beziehungsweise ʿAsr die Erinnerung kommt.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.hintColor),
            ),
            const SizedBox(height: Insets.sm),
            Wrap(
              spacing: Insets.sm,
              children: <Widget>[
                for (final int m in <int>[0, 10, 20, 30, 45, 60])
                  ChoiceChip(
                    label: Text(m == 0 ? 'sofort' : '+$m Min.'),
                    selected: settings.versatz == m,
                    onSelected: (_) => settings.setVersatz(m),
                  ),
              ],
            ),
            const SizedBox(height: Insets.lg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fertig'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
