"""Step the FMU until a step fails, once per logging setting, and write how many
log messages with status error the importer got.

usage: fmi3_wasm_logging_off.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Slave, fmi3Error


def errors(fmu, logging_on, categories):
    md = read_model_description(fmu)
    s = FMU3Slave(guid=md.instantiationToken, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    count = [0]

    def logger(env, status, category, message):
        if status >= fmi3Error:
            count[0] += 1

    s.instantiate(loggingOn=logging_on, logMessage=logger)
    if categories:
        s.setDebugLogging(True, categories)
    s.enterInitializationMode(startTime=0.0)
    s.exitInitializationMode()
    t = 0.0
    try:
        while t < 1.0:
            s.doStep(currentCommunicationPoint=t, communicationStepSize=0.1)
            t += 0.1
    except Exception:
        pass
    return count[0]


def main(fmu, output):
    with open(output, "w") as f:
        f.write(f"loggingOn = false: {errors(fmu, False, [])}\n")
        f.write(f"logStatusError only: {errors(fmu, False, ['logStatusError'])}\n")
        f.write(f"loggingOn = true: {errors(fmu, True, [])}\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
