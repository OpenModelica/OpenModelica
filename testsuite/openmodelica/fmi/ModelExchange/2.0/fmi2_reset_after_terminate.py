"""Run one instance of an FMI 2.0 Model Exchange FMU many times with
fmi2Terminate and fmi2Reset. Write if the heap in use grows by less than
1 MB, and the state after the last reset. The heap is measured with
mallinfo2 of glibc; without it the check is skipped.
usage: fmi2_reset_after_terminate.py <fmu> <output_txt>
"""
import ctypes
import ctypes.util
import sys

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Model


class Mallinfo2(ctypes.Structure):
    _fields_ = [(name, ctypes.c_size_t) for name in (
        "arena", "ordblks", "smblks", "hblks", "hblkhd", "usmblks",
        "fsmblks", "uordblks", "fordblks", "keepcost")]


def heap_in_use():
    libc = ctypes.CDLL(ctypes.util.find_library("c"))
    if not hasattr(libc, "mallinfo2"):
        return None
    libc.mallinfo2.restype = Mallinfo2
    return libc.mallinfo2().uordblks


def initialize(m):
    m.setupExperiment(startTime=0.0)
    m.enterInitializationMode()
    m.exitInitializationMode()


def cycle(m):
    initialize(m)
    m.terminate()
    m.reset()


def main(fmu, output):
    md = read_model_description(fmu)
    vr = [v.valueReference for v in md.modelVariables if v.name == "x[1]"]
    m = FMU2Model(guid=md.guid, unzipDirectory=extract(fmu), instanceName="i",
                  modelIdentifier=md.modelExchange.modelIdentifier)
    m.instantiate()
    for _ in range(20):
        cycle(m)
    before = heap_in_use()
    for _ in range(200):
        cycle(m)
    after = heap_in_use()
    initialize(m)
    x1 = m.getReal(vr)[0]
    m.terminate()
    m.freeInstance()
    growth = 0 if before is None else after - before
    with open(output, "w") as out:
        out.write("heap growth after 200 fmi2Terminate and fmi2Reset is below 1 MB: %s\n" % (growth < 1 << 20))
        if growth >= 1 << 20:
            out.write("growth: %d bytes\n" % growth)
        out.write("x[1] after the last reset: %g\n" % x1)


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
