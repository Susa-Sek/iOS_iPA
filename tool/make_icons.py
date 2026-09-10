#!/usr/bin/env python3
"""Erzeugt alle App-Symbole von „Täglich Klüger" aus einer einzigen Zeichnung.

Motiv: ein fast geschlossener Ring — die Tagesrunde, die sich füllt — und ein
Funke darin. Der Ring ist dasselbe Bild wie die Fortschrittsanzeige in der App.

Warum dieses Skript im Repository liegt: Das Symbol der ersten Version wurde
mit einem Skript erzeugt, das nur in einem Arbeitsverzeichnis lag. Es ist weg,
und damit ließe sich jenes Symbol nicht mehr nachbauen. Das soll sich nicht
wiederholen.

    python3 tool/make_icons.py            # schreibt alle Symbole
    python3 tool/make_icons.py --preview  # nur eine Vorschau nach /tmp

Braucht Pillow (`pip install pillow`).
"""

from __future__ import annotations

import argparse
import math
import pathlib
import sys

from PIL import Image, ImageDraw

ROOT = pathlib.Path(__file__).resolve().parent.parent

# Das Türkis der App: derselbe Ton wie `ic_launcher_background.xml` und der
# Startfarbton des Themas.
TOP = (31, 122, 108)
BOTTOM = (16, 78, 69)
INK = (255, 255, 255, 255)

# Überabtastung: erst groß zeichnen, dann verkleinern. Pillow kann keine
# weichen Kanten, LANCZOS beim Verkleinern schon.
SS = 4


def _gradient(size: int) -> Image.Image:
    img = Image.new("RGB", (size, size), TOP)
    d = ImageDraw.Draw(img)
    for y in range(size):
        t = y / max(1, size - 1)
        d.line(
            [(0, y), (size, y)],
            fill=tuple(round(TOP[i] + (BOTTOM[i] - TOP[i]) * t) for i in range(3)),
        )
    return img


def _sparkle(d: ImageDraw.ImageDraw, cx: float, cy: float, r: float,
             fill=INK) -> None:
    """Ein vierzackiger Funke: lange Spitzen, tief eingezogene Flanken."""
    punkte = []
    for i in range(8):
        winkel = math.radians(i * 45 - 90)
        radius = r if i % 2 == 0 else r * 0.34
        punkte.append((cx + radius * math.cos(winkel),
                       cy + radius * math.sin(winkel)))
    d.polygon(punkte, fill=fill)


def _mark(d: ImageDraw.ImageDraw, size: int, fill=INK) -> None:
    """Ring mit Lücke plus Funke, mittig auf einer Fläche der Kantenlänge size."""
    mitte = size / 2
    radius = size * 0.335
    strich = max(1, round(size * 0.078))

    kasten = [mitte - radius, mitte - radius, mitte + radius, mitte + radius]
    # Die Lücke sitzt oben rechts: ein Ring, der noch nicht ganz zu ist —
    # der heutige Tag fehlt eben noch.
    d.arc(kasten, start=-58, end=298, fill=fill, width=strich)

    # Der Punkt am Anfang des Rings gibt der Lücke eine saubere Kante.
    kopf = math.radians(298)
    d.ellipse(
        [mitte + radius * math.cos(kopf) - strich / 2,
         mitte + radius * math.sin(kopf) - strich / 2,
         mitte + radius * math.cos(kopf) + strich / 2,
         mitte + radius * math.sin(kopf) + strich / 2],
        fill=fill,
    )

    _sparkle(d, mitte, mitte, size * 0.165, fill=fill)


def voll(size: int, ecken: bool = False) -> Image.Image:
    """Das volle Symbol: Farbverlauf und Zeichen, randfüllend."""
    s = size * SS
    img = _gradient(s).convert("RGBA")
    d = ImageDraw.Draw(img)
    _mark(d, s)
    if ecken:
        # Abgerundetes Quadrat für die alten, nicht adaptiven Größen.
        maske = Image.new("L", (s, s), 0)
        ImageDraw.Draw(maske).rounded_rectangle(
            [0, 0, s - 1, s - 1], radius=round(s * 0.22), fill=255)
        img.putalpha(maske)
    return img.resize((size, size), Image.LANCZOS)


def vordergrund(size: int) -> Image.Image:
    """Adaptives Vordergrundbild: durchsichtig, Zeichen in der Sicherheitszone.

    Android schneidet vom 108-dp-Feld je nach Hersteller einen Kreis, ein
    Quadrat oder eine Blüte heraus. Sicher ist nur die mittlere Fläche von
    72 dp — deshalb sitzt das Zeichen auf zwei Dritteln der Kantenlänge.
    """
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    innen = Image.new("RGBA", (round(s * 2 / 3), round(s * 2 / 3)), (0, 0, 0, 0))
    di = ImageDraw.Draw(innen)
    _mark(di, innen.width)
    img.alpha_composite(innen, (round(s / 6), round(s / 6)))
    del d
    return img.resize((size, size), Image.LANCZOS)


def benachrichtigung(size: int) -> Image.Image:
    """Flache weiße Silhouette.

    Android färbt das Benachrichtigungssymbol selbst ein und benutzt nur den
    Alphakanal. Alles mit Farbverlauf wird dort zu einem grauen Klecks.
    """
    s = size * SS
    img = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    innen = Image.new("RGBA", (round(s * 0.86), round(s * 0.86)), (0, 0, 0, 0))
    di = ImageDraw.Draw(innen)
    _mark(di, innen.width)
    img.alpha_composite(innen, (round(s * 0.07), round(s * 0.07)))
    del d
    return img.resize((size, size), Image.LANCZOS)


def undurchsichtig(size: int) -> Image.Image:
    """Für iOS: randfüllend und ohne Alphakanal — das System maskiert selbst."""
    return voll(size).convert("RGB")


ANDROID_MIPMAP = {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144,
                  "xxxhdpi": 192}
ANDROID_FOREGROUND = {"mdpi": 108, "hdpi": 162, "xhdpi": 216, "xxhdpi": 324,
                      "xxxhdpi": 432}
ANDROID_NOTIFICATION = {"mdpi": 24, "hdpi": 36, "xhdpi": 48, "xxhdpi": 72,
                        "xxxhdpi": 96}

IOS = {
    "Icon-App-20x20@1x.png": 20, "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60, "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58, "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40, "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120, "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180, "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152, "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


def schreiben(img: Image.Image, ziel: pathlib.Path, geschrieben: list) -> None:
    ziel.parent.mkdir(parents=True, exist_ok=True)
    img.save(ziel)
    geschrieben.append(ziel.relative_to(ROOT))


def alles() -> list:
    geschrieben: list = []

    for dichte, groesse in ANDROID_MIPMAP.items():
        schreiben(voll(groesse, ecken=True),
                  ROOT / f"android/app/src/main/res/mipmap-{dichte}/ic_launcher.png",
                  geschrieben)
    for dichte, groesse in ANDROID_FOREGROUND.items():
        schreiben(vordergrund(groesse),
                  ROOT / f"android/app/src/main/res/mipmap-{dichte}/ic_launcher_foreground.png",
                  geschrieben)
    for dichte, groesse in ANDROID_NOTIFICATION.items():
        schreiben(benachrichtigung(groesse),
                  ROOT / f"android/app/src/main/res/drawable-{dichte}/ic_notification.png",
                  geschrieben)

    for name, groesse in IOS.items():
        schreiben(undurchsichtig(groesse),
                  ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset" / name,
                  geschrieben)

    for groesse in (192, 512):
        schreiben(voll(groesse, ecken=True),
                  ROOT / f"web/icons/Icon-{groesse}.png", geschrieben)
        # „maskable" heißt: Der Browser darf beschneiden — also randfüllend
        # und mit Luft am Rand.
        schreiben(voll(groesse), ROOT / f"web/icons/Icon-maskable-{groesse}.png",
                  geschrieben)
    schreiben(voll(64, ecken=True), ROOT / "web/favicon.png", geschrieben)

    return geschrieben


def vorschau(ziel: pathlib.Path) -> None:
    """Ein Blatt mit allen Spielarten, um es einmal anzusehen."""
    felder = [("Symbol", voll(256, ecken=True)),
              ("adaptiv", vordergrund(256)),
              ("klein (48)", voll(48, ecken=True).resize((256, 256), Image.NEAREST)),
              ("Benachrichtigung", benachrichtigung(96).resize((256, 256), Image.NEAREST))]
    blatt = Image.new("RGB", (256 * len(felder), 256), (90, 90, 90))
    for i, (_, bild) in enumerate(felder):
        blatt.paste(bild, (256 * i, 0), bild if bild.mode == "RGBA" else None)
    ziel.parent.mkdir(parents=True, exist_ok=True)
    blatt.save(ziel)


if __name__ == "__main__":
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("--preview", metavar="PFAD", nargs="?",
                   const="/tmp/taeglich-klueger-symbol.png",
                   help="nur eine Vorschau schreiben, nichts im Projekt ändern")
    args = p.parse_args()

    if args.preview:
        vorschau(pathlib.Path(args.preview))
        print(f"Vorschau: {args.preview}")
        sys.exit(0)

    for pfad in alles():
        print(pfad)
