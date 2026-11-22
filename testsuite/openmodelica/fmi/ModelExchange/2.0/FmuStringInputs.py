"""Set String and Boolean inputs before the initialization and again after
it, in an event (ME) or between two steps (CS), and read the outputs.

usage: FmuStringInputs.py <fmi2_fmu> <fmi3_fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Model, FMU2Slave
from fmpy.fmi3 import FMU3Model, FMU3Slave


def run(fmu, version, kind, lines):
    md = read_model_description(fmu)
    vr = {v.name: v.valueReference for v in md.modelVariables}
    iface = md.modelExchange if kind == "me" else md.coSimulation
    cls = {("2", "me"): FMU2Model, ("2", "cs"): FMU2Slave,
           ("3", "me"): FMU3Model, ("3", "cs"): FMU3Slave}[(version, kind)]
    token = md.guid if version == "2" else md.instantiationToken
    f = cls(guid=token, unzipDirectory=extract(fmu),
            modelIdentifier=iface.modelIdentifier, instanceName="instance")
    f.instantiate()

    def get_string(name):
        s = f.getString([vr[name]])[0]
        return s.decode() if isinstance(s, bytes) else s

    def show(when):
        lines.append("FMI %s %s %s: t=%s nb=%d isInit=%d" % (
            version, kind, when, get_string("t"),
            bool(f.getBoolean([vr["nb"]])[0]), bool(f.getBoolean([vr["isInit"]])[0])))

    if version == "2":
        f.setupExperiment(startTime=0.0)
    f.setString([vr["s"]], ["hello"])
    f.setBoolean([vr["b"]], [True])
    if version == "2":
        f.enterInitializationMode()
    else:
        f.enterInitializationMode(startTime=0.0)
    f.exitInitializationMode()
    show("init")
    if kind == "cs":
        f.doStep(currentCommunicationPoint=0.0, communicationStepSize=0.1)
        f.setString([vr["s"]], ["world"])
        f.setBoolean([vr["b"]], [False])
        f.doStep(currentCommunicationPoint=0.1, communicationStepSize=0.1)
    else:
        update = f.newDiscreteStates if version == "2" else f.updateDiscreteStates
        while update()[0]:
            pass
        f.enterContinuousTimeMode()
        f.setTime(0.1)
        f.enterEventMode()
        f.setString([vr["s"]], ["world"])
        f.setBoolean([vr["b"]], [False])
        while update()[0]:
            pass
        f.enterContinuousTimeMode()
    show("after")
    f.terminate()
    f.freeInstance()


def main(fmu2, fmu3, output):
    lines = []
    for version, fmu in (("2", fmu2), ("3", fmu3)):
        for kind in ("me", "cs"):
            run(fmu, version, kind, lines)
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
