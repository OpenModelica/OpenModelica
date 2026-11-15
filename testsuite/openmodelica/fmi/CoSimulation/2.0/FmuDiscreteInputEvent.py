"""Change discrete inputs between steps; set the same values again after.

usage: FmuDiscreteInputEvent.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Slave


def main(fmu, output):
    md = read_model_description(fmu)
    vr = {v.name: v.valueReference for v in md.modelVariables}
    s = FMU2Slave(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    s.instantiate()
    s.setupExperiment(startTime=0.0)
    s.enterInitializationMode()
    s.exitInitializationMode()
    lines = []
    for i in range(6):
        k = 1 if i >= 2 else 0
        b = i >= 4
        s.setInteger([vr["k"]], [k])
        s.setBoolean([vr["b"]], [b])
        s.setReal([vr["u"]], [float(i)])
        s.doStep(currentCommunicationPoint=0.1 * i, communicationStepSize=0.1)
        nk, nb = s.getInteger([vr["nk"], vr["nb"]])
        lines.append("%d: nk=%d nb=%d" % (i, nk, nb))
    s.terminate()
    s.freeInstance()
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
