# Prints the number of variables with dimensions in resources/<name>_init.bin
# of <name>.fmu (format: OMCompiler/SimulationRuntime/c/util/omc_fmu_init.h).
import struct, sys, zipfile

name = sys.argv[1]
d = zipfile.ZipFile(name + ".fmu").read("resources/" + name + "_init.bin")
pos = 0

def byte():
    global pos
    pos += 1
    return d[pos - 1]

def varint():
    v, shift = 0, 0
    while True:
        b = byte()
        v |= (b & 127) << shift
        shift += 7
        if not b & 128:
            return v

def integer():
    b = byte()
    return (varint() << 6 if b & 128 else 0) | (b >> 1) & 63

def string():
    global pos
    n = varint()
    pos += n

counts = struct.unpack_from("<8I", d, 12)
pos = 12 + 32 + 32
string()
for _ in range(varint()):
    string()
dimensioned = 0
for kind, count in zip("RRIIBBSS", counts):
    for _ in range(count):
        flags = byte()
        string()
        varint()
        for _ in range(4):
            integer()
        if flags & 8:
            dimensioned += 1
            for _ in range(varint()):
                integer()
        for attribute in range(4):
            if flags & (16 << attribute):
                for _ in range(varint()):
                    if kind == "R":
                        pos += 8
                    elif kind == "I":
                        integer()
                    elif kind == "B":
                        pos += 1
                    else:
                        string()
print(dimensioned)
