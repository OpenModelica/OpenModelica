"""Step as the master example of the FMI specification does, t += h while
t < stopTime, then one step more, and write the status of each step and the
error messages the logger got.

usage: fmi3_cs_step_past_stop.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Slave, fmi3Error


def main(fmu, output):
    md = read_model_description(fmu)
    s = FMU3Slave(guid=md.instantiationToken, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    lines = []

    def logger(env, status, category, message):
        if status >= fmi3Error:
            lines.append("status %d: %s" % (status, message.decode()))

    s.instantiate(loggingOn=True, logMessage=logger)
    s.enterInitializationMode(startTime=0.0, stopTime=0.3)
    s.exitInitializationMode()
    def step(t, h):
        try:
            s.doStep(currentCommunicationPoint=t, communicationStepSize=h)
            lines.append("doStep(%r, %r): OK" % (t, h))
        except Exception as e:
            lines.append("doStep(%r, %r): %s" % (t, h, e))

    t, h = 0.0, 0.1
    while t < 0.3:
        step(t, h)
        t += h
    step(t, h)
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
