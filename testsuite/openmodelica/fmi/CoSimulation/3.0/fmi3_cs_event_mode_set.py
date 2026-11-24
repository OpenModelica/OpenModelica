"""Set an input and a tunable parameter in Event Mode, after initialization
and during the run. In Step Mode with Event Mode used, only continuous inputs
may change; without Event Mode, all of them may.

usage: fmi3_cs_event_mode_set.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Slave


def try_set(lines, what, f):
    try:
        f()
        lines.append("%s: set" % what)
    except Exception:
        lines.append("%s: refused" % what)


def main(fmu, output):
    md = read_model_description(fmu)
    vr = {v.name: v.valueReference for v in md.modelVariables}
    unzipped = extract(fmu)
    lines = []
    for event_mode_used in [True, False]:
        s = FMU3Slave(guid=md.guid, unzipDirectory=unzipped,
                      modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
        s.instantiate(eventModeUsed=event_mode_used)
        s.enterInitializationMode(startTime=0.0)
        s.exitInitializationMode()
        if event_mode_used:
            for t, k, p in [(0.0, 1, 2.0), (0.1, 2, 3.0)]:
                if t > 0:
                    s.enterEventMode()
                s.setInt32([vr["k"]], [k])
                s.setFloat64([vr["p"]], [p])
                while s.updateDiscreteStates()[0]:
                    pass
                s.enterStepMode()
                s.doStep(currentCommunicationPoint=t, communicationStepSize=0.1)
                nk = s.getInt32([vr["nk"]])[0]
                x = s.getFloat64([vr["x"]])[0]
                lines.append("t=%g: nk=%d x=%.6f" % (t + 0.1, nk, x))
        else:
            s.doStep(currentCommunicationPoint=0.0, communicationStepSize=0.1)
        mode = "Step Mode, eventModeUsed=%s" % event_mode_used
        try_set(lines, mode + ", k", lambda: s.setInt32([vr["k"]], [5]))
        try_set(lines, mode + ", p", lambda: s.setFloat64([vr["p"]], [5.0]))
        try_set(lines, mode + ", u", lambda: s.setFloat64([vr["u"]], [5.0]))
        s.freeInstance()
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
