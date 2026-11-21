"""Simulate FMI 3.0 Model Exchange FMUs that have time events (sample() or a
periodic Clock) with two importers and write the output y at some times:

- FMPy simulate_fmu: it reads the outputs at the time of a time event before
  it calls fmi3EnterEventMode.
- A forward Euler loop: it calls fmi3SetTime, fmi3SetContinuousStates and
  fmi3CompletedIntegratorStep, and then fmi3EnterEventMode without a getter.
  At each time event it calls fmi3UpdateDiscreteStates a second time and checks
  that the second call does not change y.

usage: fmi3TimeEventsCpp.py <output_txt> <fmu>...
"""
import sys
from ctypes import c_double

from fmpy import extract, read_model_description, simulate_fmu
from fmpy.fmi3 import FMU3Model

TIMES = [0.0, 0.1, 0.15, 0.3, 0.5, 0.95]
STOP = 1.0
H = 0.05


def fmpy_values(fmu):
    r = simulate_fmu(fmu, fmi_type="ModelExchange", stop_time=STOP,
                     output_interval=H, output=["y"])
    return [r["y"][r["time"] <= t + 1e-9][-1] for t in TIMES]


def event_update(m):
    """Do the event iteration, return the next event time."""
    while True:
        needed, terminate, _, _, defined, nxt = m.updateDiscreteStates()
        if not needed:
            return nxt if defined else float("inf")


def euler_values(fmu, lines):
    md = read_model_description(fmu)
    vr = [v.valueReference for v in md.modelVariables if v.name == "y"]
    nx = len(md.derivatives)
    m = FMU3Model(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.modelExchange.modelIdentifier,
                  instanceName="euler")
    m.instantiate()
    m.enterInitializationMode(startTime=0.0)
    m.exitInitializationMode()
    nxt = event_update(m)
    m.enterContinuousTimeMode()
    x = (c_double * max(nx, 1))()
    dx = (c_double * max(nx, 1))()
    m.getContinuousStates(x, nx)
    t = 0.0
    y = {0.0: m.getFloat64(vr)[0]}
    while t < STOP - 1e-9:
        m.getContinuousStateDerivatives(dx, nx)
        tn = t + H
        if nxt <= tn + 1e-9:
            tn = nxt
        for i in range(nx):
            x[i] += (tn - t) * dx[i]
        m.setTime(tn)
        m.setContinuousStates(x, nx)
        m.completedIntegratorStep()
        t = tn
        if t == nxt:
            m.enterEventMode()
            nxt = event_update(m)
            y1 = m.getFloat64(vr)[0]
            event_update(m)
            y2 = m.getFloat64(vr)[0]
            if y2 != y1:
                lines.append("  euler t = %.2f: second fmi3UpdateDiscreteStates changed y from %g to %g"
                             % (t, y1, y2))
            m.enterContinuousTimeMode()
            m.getContinuousStates(x, nx)
        y[round(t, 6)] = m.getFloat64(vr)[0]
    m.terminate()
    m.freeInstance()
    return [y[round(t, 6)] for t in TIMES]


def main(output, fmus):
    lines = []
    for fmu in fmus:
        lines.append(fmu + ":")
        for name, f in [("fmpy ", lambda: fmpy_values(fmu)),
                        ("euler", lambda: euler_values(fmu, lines))]:
            try:
                v = f()
                lines.append("  %s %s" % (name, ", ".join(
                    "y(%g) = %g" % (t, round(y, 6)) for t, y in zip(TIMES, v))))
            except Exception as e:
                lines.append("  %s failed: %s" % (name, e))
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
