"""Общее для портов текстовых утилит: кодовая таблица шрифта 4FONT.FNT (4TEXT/4TSKTXT2), чтение/запись, центровка строк.

Исходные тексты автора (DOC/*.TXT) - cp866 с CRLF; здесь тексты UTF-8 с LF (в порте строки обрабатываются
как последовательности символов, один символ = один байт cp866: преобразование взаимно однозначное).
"""
import os
import sys

TOOLS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if TOOLS not in sys.path:
    sys.path.insert(0, TOOLS)

ROOT = os.path.dirname(TOOLS)


for _s in (sys.stdout, sys.stderr):         # сообщения по-русски в консоли cp866/cp1251 без ошибок кодировки
    try:
        _s.reconfigure(encoding='utf-8', errors='replace')
    except (AttributeError, ValueError):
        pass
ARCH = os.path.join(ROOT, 'archive', 'unz', 'BR2_DEMO')
OUT = os.path.join(ROOT, 'build', 'author_out')      # куда порты пишут по умолчанию (архив только читается)

# code[] из 4TEXT.CPP / 4TSKTXT2.CPP: символ <-> номер знака шрифта 4FONT.FNT (114 знаков по 6 в строке листа)
CODE = ("012345"
        "6789 _"
        "АБВГДЕ"
        "ЖЗИЙКЛ"
        "МНОПРС"
        "ТУФХЦЧ"
        "ШЩЬЫЭЮ"
        "Я:?.,!"
        "абвгде"
        "жзийкл"
        "мнопрс"
        "туфхцч"
        "шщьыъэ"
        "юяёNRS"
        "IFY()%"
        "/-^^^^"
        "^*'abc"
        "Ddefgh"
        "<>GJLU")
SPACE = 10                                      # код пробела (#define SPACE 10)
# abc[] автора: при повторах ('^' - 5 раз) побеждает последний номер
ABC = {}
for _i, _c in enumerate(CODE):
    ABC[_c] = _i
CANON = {i for i, c in enumerate(CODE) if ABC[c] == i}      # номера, которые текст -> код даёт обратно


class TextError(Exception):
    pass


def rd(*p):
    with open(os.path.join(*p), 'rb') as f:
        return f.read()


def wr(path, data):
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    with open(path, 'wb') as f:
        f.write(data)


def rdcp866(path):
    """файл автора (cp866, CRLF) -> str (CRLF сохраняются: порты разбирают строки так же, как исходники)"""
    return rd(path).decode('cp866')


def rdutf8(path):
    """UTF-8 текст (BOM допустим) -> str с CRLF, как в файлах автора"""
    s = rd(path).decode('utf-8-sig').replace('\r\n', '\n').replace('\r', '\n')
    return s.replace('\n', '\r\n')


def to_utf8(s):
    """str с CRLF -> bytes UTF-8 с LF"""
    return s.replace('\r\n', '\n').encode('utf-8')


def conv_s(c, line=None):
    """символ -> код знака; {NN} обрабатывается выше (см. enc_line)"""
    if c not in ABC:
        raise TextError('Unknown symbol %r%s' % (c, ' in line %d' % line if line else ''))
    return ABC[c]


def dec_code(b):
    """код знака -> текст ('{NN}', если у знака нет однозначного символа)"""
    return CODE[b] if b in CANON else '{%d}' % b


def enc_text(s, line=None):
    """строка текста -> список кодов знаков. Поддерживает {NN} для кодов без однозначного символа (см. dec_code)."""
    out = []
    i = 0
    while i < len(s):
        if s[i] == '{' and s.find('}', i) > i:
            j = s.index('}', i)
            try:
                out.append(int(s[i + 1:j]))
                i = j + 1
                continue
            except ValueError:
                pass
        out.append(conv_s(s[i], line))
        i += 1
    return out


def center_span(first, last, total):
    """Как восстановить (смещение, длина) для центровки автора: (total-k)//2.
    Нужна строка s длиной k (может содержать пробелы по краям), чтобы s начиналась с (total-k)//2, покрывала [first, last]."""
    for k in range(last - first + 1, total + 1):
        a = (total - k) // 2
        if a <= first and a + k > last:
            return a, k
    raise TextError('строка не получена центровкой')


def dec_row(codes):
    """строка кодов (ширина total, пробел - SPACE) -> текст так, чтобы центровка автора дала ту же строку"""
    nb = [i for i, c in enumerate(codes) if c != SPACE]
    if not nb:
        return ''
    a, k = center_span(nb[0], nb[-1], len(codes))
    return ''.join(dec_code(c) for c in codes[a:a + k])
