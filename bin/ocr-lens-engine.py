#!/usr/bin/env python3
"""One-shot Japanese OCR using Google Lens.

Drives owocr's GoogleLens engine -- the same Google Lens
(lensfrontend-pa.googleapis.com) backend that GameSentenceMiner uses as its
default OCR engine ("glens") -- and applies GSM's Japanese post-processing
(jaconv width normalization, ellipsis and dash fixes).

Usage: ocr-lens-engine.py IMAGE
Prints the recognized Japanese text to stdout; diagnostics go to stderr.

Run it with an interpreter that has the owocr package with the "lens" extra
(plus `regex` for the Japanese dash normalization), e.g. installed with:
    uv tool install --python 3.13 --with regex 'owocr[lens]'
"""

import re
import sys
from pathlib import Path

import jaconv
import regex
from owocr.ocr import GoogleLens

_HAN = r"\p{Script=Han}々〆〇〻"
_KANA = r"\p{Script=Hiragana}\p{Script=Katakana}ヶヵ"
_DASHES = regex.escape("-－―—–−ｰ─━")
_OPENERS = regex.escape("「『【（〈《〔［｛〘〚")
_TRAILERS = regex.escape("」』】）〉》〕］｝〙〛、。！？…・!?,.，．")

_LEADING_HAN_DASH = regex.compile(rf"(^|[\n{_OPENERS}])([{_DASHES}])(?=[{_HAN}])")
_LEADING_KANA_DASH = regex.compile(rf"(^|[\n{_OPENERS}])([{_DASHES}]+)(?=[{_KANA}])")
_CONTEXTUAL_KANA_DASH = regex.compile(rf"(?<=[{_KANA}])[{_DASHES}]+(?=(?:[{_KANA}{_TRAILERS}\n])|$)")
_ELLIPSIS_DOTS = str.maketrans({"･": "・", "·": "・", "•": "・", "∙": "・", "⋅": "・"})
_ELLIPSIS_SEQUENCE = re.compile(r"[・.．]{2,}")


def _normalize_dashes(text):
    text = _LEADING_HAN_DASH.sub(lambda m: f"{m.group(1)}一", text)
    text = _LEADING_KANA_DASH.sub(lambda m: f"{m.group(1)}{'ー' * len(m.group(2))}", text)
    return _CONTEXTUAL_KANA_DASH.sub(lambda m: "ー" * len(m.group(0)), text)


def _normalize_ellipses(text):
    text = text.replace("…", "・・・").replace("‥", "・・").replace("⋯", "・・・")
    text = text.translate(_ELLIPSIS_DOTS)
    return _ELLIPSIS_SEQUENCE.sub(lambda m: "・・・" if len(m.group(0)) >= 3 else "・・", text)


def post_process(text):
    # Mirrors GameSentenceMiner's owocr post_process (keep_newline=False):
    # drop spaces per line, join the lines, then fix Japanese OCR artifacts.
    text = text.replace('"', "")
    text = "".join("".join(line.split()) for line in text.splitlines())
    text = _normalize_ellipses(text)
    text = jaconv.h2z(text, ascii=True, digit=True)
    return _normalize_dashes(text)


def _line_text(line):
    if line.text is not None:
        return line.text
    parts = []
    for i, word in enumerate(line.words):
        parts.append(word.text)
        if i < len(line.words) - 1:
            parts.append(word.separator if word.separator is not None else " ")
    return "".join(parts)


def main():
    if len(sys.argv) != 2:
        print("usage: ocr-lens-engine.py IMAGE", file=sys.stderr)
        return 2

    engine = GoogleLens()
    ok, result = engine(Path(sys.argv[1]))
    if not ok:
        print(result, file=sys.stderr)
        return 1

    raw = "\n".join(_line_text(line) for paragraph in result.paragraphs for line in paragraph.lines)
    print(post_process(raw))
    return 0


if __name__ == "__main__":
    sys.exit(main())
