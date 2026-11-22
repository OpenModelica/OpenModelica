"""Set start values, initialize, reset, and read the values after each step.
After fmi3Reset the FMU must hold the start values of the modelDescription.xml.

usage: fmi3_cs_reset.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Slave


def main(fmu, output):
    md = read_model_description(fmu)
    vr = {v.name: v.valueReference for v in md.modelVariables}
    s = FMU3Slave(guid=md.instantiationToken, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    lines = []

    def show(when):
        lines.append("%s: p=%g x=%g q=%d b=%d" % (
            when, s.getFloat64([vr["p"]])[0], s.getFloat64([vr["x"]])[0],
            s.getBoolean([vr["q"]])[0], s.getBoolean([vr["b"]])[0]))

    def init():
        s.enterInitializationMode(startTime=0.0)
        s.exitInitializationMode()

    s.instantiate()
    show("instantiated")
    s.setFloat64([vr["p"], vr["x"]], [5.0, 3.0])
    s.setBoolean([vr["q"], vr["b"]], [True, True])
    init()
    show("initialized")
    s.reset()
    show("reset")
    init()
    show("initialized")
    s.terminate()
    s.freeInstance()
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
