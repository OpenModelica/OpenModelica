"""Check that fmi2GetEventIndicators of an FMI 2.0 Model Exchange FMU sets
all values. The buffer is filled with NaN before each call.

usage: fmi2SampleEventIndicatorsCpp.py <output_txt> <fmu>
"""
import math
import sys
from ctypes import c_double

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Model


def event_update(m):
    while True:
        needed, _, _, _, defined, nxt = m.newDiscreteStates()
        if not needed:
            return nxt if defined else float("inf")


def main(output, fmu):
    md = read_model_description(fmu)
    nz = md.numberOfEventIndicators
    nx = len(md.derivatives)
    m = FMU2Model(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.modelExchange.modelIdentifier,
                  instanceName="m")
    z = (c_double * max(nz, 1))()
    x = (c_double * max(nx, 1))()
    bad = []

    def check(where):
        for i in range(nz):
            z[i] = float("nan")
        m.getEventIndicators(z, nz)
        if any(math.isnan(z[i]) for i in range(nz)):
            bad.append(where)

    m.instantiate()
    m.setupExperiment(startTime=0.0)
    m.enterInitializationMode()
    m.exitInitializationMode()
    check("after initialization")
    nxt = event_update(m)
    m.enterContinuousTimeMode()
    m.getContinuousStates(x, nx)
    t = 0.0
    for _ in range(3):
        for tn in [0.5 * (t + nxt), nxt]:
            m.setTime(tn)
            m.setContinuousStates(x, nx)
            check("t = %g" % tn)
        t = nxt
        m.enterEventMode()
        nxt = event_update(m)
        check("after event at t = %g" % t)
        m.enterContinuousTimeMode()
    m.terminate()
    m.freeInstance()
    with open(output, "w") as f:
        f.write("event indicators: %d\n" % nz)
        f.write("values not set: %s\n" % (", ".join(bad) if bad else "none"))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
