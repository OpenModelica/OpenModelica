"""Validate an FMI 2.0 FMU against the schema, step it as Co-Simulation and
read the variable time with fmi2GetReal.

usage: Fmi2NoVariables.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Slave
from fmpy.validation import validate_fmu


def main(fmu, output):
    problems = validate_fmu(fmu)
    md = read_model_description(fmu)
    vr = {v.name: v.valueReference for v in md.modelVariables}
    s = FMU2Slave(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    s.instantiate()
    s.setupExperiment(startTime=0.0)
    s.enterInitializationMode()
    s.exitInitializationMode()
    s.doStep(currentCommunicationPoint=0.0, communicationStepSize=0.5)
    with open(output, "w") as f:
        f.write("problems = %d\n" % len(problems))
        f.write("time = %g\n" % s.getReal([vr["time"]])[0])


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
