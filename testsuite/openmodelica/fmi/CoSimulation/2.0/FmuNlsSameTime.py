"""Step the FMU from t = 4096 and start step 4 three ulps after the previous end.

usage: FmuNlsSameTime.py <fmu> <output_txt>
"""
import math
import sys

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Slave


def main(fmu, output):
    md = read_model_description(fmu)
    vr = {v.name: v.valueReference for v in md.modelVariables}
    s = FMU2Slave(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    s.instantiate()
    s.setupExperiment(startTime=4096.0)
    s.enterInitializationMode()
    s.exitInitializationMode()
    t = 4096.0
    result = "all 12 steps fmi2OK"
    for k in range(12):
        if k == 4:
            s.setReal([vr["u"]], [1.0])
            t += 3 * math.ulp(t)
        try:
            s.doStep(currentCommunicationPoint=t, communicationStepSize=0.25)
        except Exception as e:
            result = "step %d failed: %s" % (k, e)
            break
        t += 0.25
    with open(output, "w") as f:
        f.write(result + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
