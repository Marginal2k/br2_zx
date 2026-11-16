#!/usr/bin/env python3
"""Общие мелочи для конвертеров ресурсов Чёрного Ворона (tools/gfx.py, text.py, maps.py, assets.py)."""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def rd(*p):
    with open(os.path.join(*p), 'rb') as f:
        return f.read()


def wr(path, data):
    """Записать bytes (двоичный) или str (UTF-8, перевод строки LF)."""
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    if isinstance(data, str):
        with open(path, 'w', encoding='utf-8', newline='\n') as f:
            f.write(data)
    else:
        with open(path, 'wb') as f:
            f.write(data)


def rdtext(path):
    """Текст UTF-8 (допускается BOM и CRLF) -> str с '\\n'."""
    with open(path, 'r', encoding='utf-8-sig', newline='') as f:
        return f.read().replace('\r\n', '\n').replace('\r', '\n')
