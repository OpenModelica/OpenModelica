"""Step the FMU 12 times by 0.25 s with all log categories on, and write the step
results, the final x and the number of log messages with status warning or worse.

usage: fmi3_cs_assert_solver_retry.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Slave, fmi3Warning


def main(fmu, output):
    md = read_model_description(fmu)
    vr = {v.name: v.valueReference for v in md.modelVariables}
    s = FMU3Slave(guid=md.instantiationToken, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    warnings = []

    def logger(env, status, category, message):
        if status >= fmi3Warning:
            warnings.append(message)

    s.instantiate(loggingOn=True, logMessage=logger)
    s.enterInitializationMode(startTime=0.0)
    s.exitInitializationMode()
    t = 0.0
    result = "all 12 steps fmi3OK"
    for k in range(12):
        try:
            s.doStep(currentCommunicationPoint=t, communicationStepSize=0.25)
        except Exception as e:
            result = "step %d failed: %s" % (k, e)
            break
        t += 0.25
    with open(output, "w") as f:
        f.write(result + "\n")
        f.write("x = %.6f\n" % s.getFloat64([vr["x"]])[0])
        f.write("warnings = %d\n" % len(warnings))


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
