#!/usr/bin/env python3
"""Writes the <prefix>_init.bin test inputs of the read_input tests.

The format is described in
OMCompiler/SimulationRuntime/rust/openmodelica_init_file/include/omc_init_file.h.
The CTest build runs it in the directory the files go to.
"""
import struct

CLASS = {"rSta": 0, "rDer": 1, "rAlg": 2, "rPar": 3, "rAli": 4, "iAlg": 5, "iPar": 6}
REAL, INTEGER = 0, 1
CONTINUOUS, PARAMETER = 0, 2
DISCRETE, CHANGEABLE, FIXED, FILE_WRITABLE, ARRAY = 1, 2, 32, 128, 256
COUNTS = ["numberOfContinuousStates", "numberOfRealAlgebraicVariables", "numberOfRealAlgebraicAliasVariables",
          "numberOfRealParameters", "numberOfIntegerAlgebraicVariables", "numberOfIntegerAliasVariables",
          "numberOfIntegerParameters", "numberOfBooleanAlgebraicVariables", "numberOfBooleanAliasVariables",
          "numberOfBooleanParameters", "numberOfStringAlgebraicVariables", "numberOfStringAliasVariables",
          "numberOfStringParameters", "numberOfEventIndicators", "numberOfTimeEvents", "numberOfInputVariables",
          "numberOfOutputVariables", "numberOfExternalObjects", "numberOfFunctions"]


def write(path, counts, variables):
    strings, offsets = bytearray(b"\0"), {"": 0}
    reals, integers = [], []

    def s(text):
        if text not in offsets:
            offsets[text] = len(strings)
            strings.extend(text.encode() + b"\0")
        return offsets[text]

    def values(base, vs):
        pool = reals if base == REAL else integers
        index = len(pool)
        pool.extend(vs)
        return (len(vs), index if vs else 0)

    model = struct.pack("<7I", *(s(x) for x in ["RealArrayVariable", "RealArrayVariable", "", "test-guid", "", "", ""]))
    model += struct.pack("<19i", *(counts.get(c, 0) for c in COUNTS))
    experiment = struct.pack("<4d4I", 0.0, 1.0, 0.002, 1e-6, s("dassl"), s("mat"), s(".*"), 0)
    records = bytearray()
    for v in variables:
        dims = values(INTEGER, [x for d in v.get("dims", []) for x in d])
        records += struct.pack("<7I7i6BHII", s(v["name"]), 0, 0, 0, 0, 0, 0, v["vr"], -1, v["ci"], 0, 0, 0, 0,
                               CLASS[v["class"]], v["base"], v["variability"], 0, 0, 1, v["flags"],
                               len(v.get("dims", [])), dims[1])
        for attr in ["start", "min", "max", "nominal"]:
            records += struct.pack("<II", *values(v["base"], v.get(attr, [])))
    sections = [(1, len(strings), bytes(strings)), (2, 1, model), (3, 1, experiment), (4, 0, b""),
                (5, len(variables), bytes(records)), (6, len(reals), struct.pack("<%dd" % len(reals), *reals)),
                (7, len(integers), struct.pack("<%dq" % len(integers), *integers))]
    pad = lambda n: (8 - n % 8) % 8
    offset = 16 + 24 * len(sections)
    table, body = bytearray(), bytearray()
    for sid, count, data in sections:
        table += struct.pack("<IIQQ", sid, count, offset + len(body), len(data))
        body += data + b"\0" * pad(len(data))
    with open(path, "wb") as f:
        f.write(b"OMCINIT\0" + struct.pack("<II", 1, len(sections)) + table + body)


write("01_RealArrayVariable_init.bin", {"numberOfRealAlgebraicVariables": 1, "numberOfIntegerParameters": 1}, [
    dict(name="x", vr=1000, ci=0, **{"class": "rAlg"}, base=REAL, variability=CONTINUOUS, flags=FILE_WRITABLE | ARRAY,
         dims=[(4, -1)], start=[7.0], min=[-0.2], max=[13.3]),
    dict(name="p", vr=1001, ci=0, **{"class": "iPar"}, base=INTEGER, variability=PARAMETER,
         flags=DISCRETE | CHANGEABLE | FIXED | FILE_WRITABLE, start=[5]),
])
write("02_RealMatrixVariable_init.bin", {"numberOfRealAlgebraicVariables": 1}, [
    dict(name="A", vr=1000, ci=0, **{"class": "rAlg"}, base=REAL, variability=CONTINUOUS, flags=FILE_WRITABLE | ARRAY,
         dims=[(3, -1), (2, -1)], start=[0.0, 0.1, 1.0, 1.1, 2.0, 2.1],
         nominal=[10.1, 10.2, 10.3, 10.4, 10.5, 10.6], min=[-0.01, 0.02, 0.03, 0.04, 0.05, 0.06],
         max=[100.1, 100.2, 100.3, 100.4, 100.5, 100.6]),
])
write("03_IntTensorVariable_init.bin", {"numberOfIntegerParameters": 2}, [
    dict(name="T", vr=1000, ci=0, **{"class": "iPar"}, base=INTEGER, variability=PARAMETER,
         flags=DISCRETE | CHANGEABLE | FIXED | FILE_WRITABLE | ARRAY, dims=[(-1, 1001), (3, -1), (4, -1)],
         start=list(range(1, 25))),
    dict(name="dim1", vr=1001, ci=1, **{"class": "iPar"}, base=INTEGER, variability=PARAMETER,
         flags=DISCRETE | FIXED | FILE_WRITABLE, start=[2]),
])
