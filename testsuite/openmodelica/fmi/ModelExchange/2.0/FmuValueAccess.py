"""Set a Boolean and a String parameter, then read the Boolean variables,
parameters and aliases and the String parameter after the initialization.

usage: FmuValueAccess.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Model


def main(fmu, output):
    md = read_model_description(fmu)
    variables = {v.name: v for v in md.modelVariables}
    m = FMU2Model(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.modelExchange.modelIdentifier, instanceName="instance")
    m.instantiate()
    m.setupExperiment(startTime=0.0)
    m.setBoolean([variables["p"].valueReference], [False])
    m.setString([variables["s"].valueReference], ["xyz"])
    m.enterInitializationMode()
    m.exitInitializationMode()
    lines = []
    for name in ["p", "q", "b", "ab", "nb"]:
        v = variables[name]
        lines.append("%s %s" % (name, m.getBoolean([v.valueReference])[0]))
    lines.append("s %s" % m.getString([variables["s"].valueReference])[0].decode())
    m.terminate()
    m.freeInstance()
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
