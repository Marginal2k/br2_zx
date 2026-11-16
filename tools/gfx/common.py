"""Общее для портов графических утилит: пути, TIF автора, 1-битные PNG, "следы" (plan) для обратного преобразования.

Все исходные картинки автора - TIFF без сжатия (заголовок 194 байта, потом строки по W/8 байт, инвертированные:
чёрный = 0). Конвертеры делают ``^= 0xFF`` (1 = чернила) и забирают из листа прямоугольники.

Обратный ход (DAT -> лист) сделан без второй копии алгоритма: порт запускается на "листе" из номеров ячеек
(``trace``), результат - таблица "байт файла <- ячейка листа" (plan); по ней файл раскладывается обратно в лист.
Поэтому прямое и обратное преобразования всегда согласованы с портом (а порт - с исходником автора).
"""
import os
import sys

TOOLS = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if TOOLS not in sys.path:               # python -I не добавляет каталог скрипта
    sys.path.insert(0, TOOLS)

from PIL import Image  # noqa: E402


for _s in (sys.stdout, sys.stderr):         # сообщения по-русски в консоли cp866/cp1251 без ошибок кодировки
    try:
        _s.reconfigure(encoding='utf-8', errors='replace')
    except (AttributeError, ValueError):
        pass

ROOT = os.path.dirname(TOOLS)
ARCH = os.path.join(ROOT, 'archive', 'unz', 'BR2_DEMO')
OUT = os.path.join(ROOT, 'build', 'author_out')      # куда порты пишут по умолчанию (архив только читается)
TIFF = 194                               # длина заголовка TIF у автора (константа в каждом исходнике)


def rd(*p):
    with open(os.path.join(*p), 'rb') as f:
        return f.read()


def wr(path, data):
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    with open(path, 'wb') as f:
        f.write(data)


def ci_path(*parts):
    """путь без учёта регистра (архив автора - DOS, имена в верхнем регистре)"""
    p = parts[0]
    for part in parts[1:]:
        want = part.lower()
        hit = None
        if os.path.isdir(p):
            for f in os.listdir(p):
                if f.lower() == want:
                    hit = f
                    break
        p = os.path.join(p, hit or part)
    return p


def read_tif(path, n):
    """как у автора: read(h,buf,194); read(h,buf,n); buf ^= 0xFF  ->  bytearray (1 = чернила)"""
    d = rd(path)
    if len(d) < TIFF + n:
        raise ValueError('%s: короткий TIF (%d байт)' % (path, len(d)))
    return bytearray(b ^ 0xFF for b in d[TIFF:TIFF + n])


# ----------------------------------------------------------------------------- PNG 1 бит (чёрный = чернила = 1)
def save_mono(path, buf, wb, h):
    """байты листа (wb байт в строке, h строк) -> 1-битный PNG"""
    im = Image.new('P', (wb * 8, h))
    im.putpalette([255, 255, 255, 0, 0, 0] + [0, 0, 0] * 254)
    px = []
    for b in bytes(buf[:wb * h]):
        px.extend(((b >> 7) & 1, (b >> 6) & 1, (b >> 5) & 1, (b >> 4) & 1, (b >> 3) & 1, (b >> 2) & 1, (b >> 1) & 1, b & 1))
    im.putdata(px)
    d = os.path.dirname(path)
    if d:
        os.makedirs(d, exist_ok=True)
    im.save(path, optimize=True)


def load_mono(path, wb, h):
    """PNG (любой режим; тёмное = чернила) -> bytearray листа. Размер должен совпасть."""
    im = Image.open(path)
    if im.size != (wb * 8, h):
        raise ValueError('%s: размер %s, нужен %s' % (path, im.size, (wb * 8, h)))
    if im.mode == 'P':
        pal = im.getpalette()
        ink = [1 if (pal[3 * i] + pal[3 * i + 1] + pal[3 * i + 2]) / 3 < 128 else 0 for i in range(256)]
        px = [ink[v] for v in im.getdata()]
    else:
        px = [1 if (p[0] + p[1] + p[2]) / 3 < 128 and p[3] >= 128 else 0 for p in im.convert('RGBA').getdata()]
    out = bytearray(wb * h)
    for i in range(wb * h):
        v = 0
        for b in px[i * 8:i * 8 + 8]:
            v = (v << 1) | b
        out[i] = v
    return out


# ----------------------------------------------------------------------------- следы (plan)
class Conflict(Exception):
    pass


class Inverter:
    """Раскладывает файлы обратно в общий лист. Одна ячейка листа не может нести два разных байта (Conflict).
    plan[i] - номер ячейки для байта i файла (None - байт не из листа); pairs[k] - (ячейка маски, ячейка картинки)."""

    def __init__(self, nsrc, fill=0):
        self.sheet = bytearray([fill]) * nsrc
        self.seen = {}

    def put(self, cell, v, what=''):
        if cell in self.seen and self.seen[cell] != v:
            raise Conflict('ячейка %d (%s): байты %02X и %02X' % (cell, what, self.seen[cell], v))
        self.seen[cell] = v
        self.sheet[cell] = v

    def add_copy(self, plan, data, what=''):
        """-> остаток {смещение: байт} (байты файла вне листа)"""
        rest = {}
        for i in range(len(data)):
            s = plan[i] if i < len(plan) else None
            if s is None:
                rest[i] = data[i]
            else:
                self.put(s, data[i], what)
        return rest

    def add_pairs(self, pairs, data, what=''):
        rest = {}
        for k, (mi, ii) in enumerate(pairs):
            if 2 * k + 1 >= len(data):
                break
            self.put(mi, data[2 * k], what + ' маска')
            self.put(ii, data[2 * k] ^ data[2 * k + 1], what + ' картинка')
        for i in range(2 * len(pairs), len(data)):
            rest[i] = data[i]
        return rest


def invert_plan(plan, data, nsrc, fill=0):
    inv = Inverter(nsrc, fill)
    rest = inv.add_copy(plan, data)
    return inv.sheet, rest


def apply_plan(plan, sheet, n, fill=0xA5, rest=None):
    out = bytearray([fill]) * n
    for i, s in enumerate(plan[:n]):
        if s is not None:
            out[i] = sheet[s]
    for i, b in (rest or {}).items():
        out[i] = b
    return bytes(out)


def runs(rest):
    """{смещение: байт} -> [[смещение, 'hex'], ...] (подряд идущие склеены) для JSON"""
    res = []
    for i in sorted(rest):
        if res and res[-1][0] + len(res[-1][1]) // 2 == i:
            res[-1][1] += '%02x' % rest[i]
        else:
            res.append([i, '%02x' % rest[i]])
    return res


def unruns(lst):
    rest = {}
    for off, hx in lst:
        for k in range(len(hx) // 2):
            rest[off + k] = int(hx[2 * k:2 * k + 2], 16)
    return rest


# ----------------------------------------------------------------------------- пары (маска, маска^картинка)
def invert_pairs(pairs, data, nsrc, fill=0):
    inv = Inverter(nsrc, fill)
    rest = inv.add_pairs(pairs, data)
    return inv.sheet, rest


def apply_pairs(pairs, sheet, n, rest=None):
    out = bytearray(n)
    for k, (mi, ii) in enumerate(pairs):
        if 2 * k + 1 < n:
            out[2 * k] = sheet[mi]
            out[2 * k + 1] = sheet[mi] ^ sheet[ii]
    for i, b in (rest or {}).items():
        out[i] = b
    return bytes(out)


def strip_pairs(nbytes, h, per_row=32):
    """Раскладка для данных с неизвестной геометрией: пары (M, M^I) столбцами по h строк; столбец c - в клетке (c % per_row) полосы
    c // per_row; в полосе сверху маска (h строк), под ней картинка (h строк). Возвращает (pairs, ширина в байтах, высота в строках)."""
    ncols = nbytes // (2 * h)
    wb = min(ncols, per_row)
    bands = (ncols + per_row - 1) // per_row
    pairs = []
    for c in range(ncols):
        x, b = c % per_row, c // per_row
        for r in range(h):
            pairs.append(((b * 2 * h + r) * wb + x, (b * 2 * h + h + r) * wb + x))
    return pairs, wb, bands * 2 * h
