"""tiny disassembler wrapper over skoolkit"""
from types import SimpleNamespace
from skoolkit.disassembler import Disassembler
class Ins:
    def __init__(s, address, operation, data): s.address, s.operation, s.bytes = address, operation, data
def dis(mem, start, end):
    cfg = SimpleNamespace(asm_hex=True, asm_lower=True, defb_size=8, defm_size=66, defw_size=1, handle_rst=False,
                          imaker=Ins, opcodes='ALL', wrap=False)
    return Disassembler(mem, cfg).disassemble(start, end, 'h')
def show(mem, start, end):
    for i in dis(mem, start, end):
        print('%04X  %-12s %s' % (i.address, bytes(i.bytes).hex(), i.operation))
if __name__ == '__main__':
    import sys
    d = open(sys.argv[1], 'rb').read(); org = int(sys.argv[2], 16)
    mem = [0] * 65536; mem[org:org + len(d)] = d
    a = int(sys.argv[3], 16) if len(sys.argv) > 3 else org
    b = int(sys.argv[4], 16) if len(sys.argv) > 4 else org + len(d)
    show(mem, a, b)
