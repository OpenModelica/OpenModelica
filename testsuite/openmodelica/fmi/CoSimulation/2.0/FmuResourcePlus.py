"""Run FMI 2.0 and 3.0 FMUs extracted into a directory with '+' and '%' in its
name. FMI 2.0 gets the resources as a URI that keeps the '+', FMI 3.0 as a path.

usage: FmuResourcePlus.py <fmi2_fmu> <fmi3_fmu> <output_txt>
"""
import os
import sys
from ctypes import byref

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Slave, defaultCallbacks, fmi2CoSimulation
from fmpy.fmi3 import FMU3Slave


class FMU2RawUriSlave(FMU2Slave):  # fmpy picks the FMI version by the class name
    def instantiate(self):
        uri = "file://" + os.path.join(self.unzipDirectory, "resources").replace("%", "%25")
        self.callbacks = defaultCallbacks
        self.component = self.fmi2Instantiate(self.instanceName.encode(), fmi2CoSimulation,
                                              self.guid.encode(), uri.encode(), byref(self.callbacks), 0, 0)
        if self.component is None:
            raise Exception("Failed to instantiate model")


def run(cls, fmu, d):
    md = read_model_description(fmu)
    s = cls(guid=md.guid, unzipDirectory=extract(fmu, unzipdir=os.path.abspath(d)),
            modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    s.instantiate()
    if cls is FMU3Slave:
        s.enterInitializationMode(startTime=0.0)
    else:
        s.setupExperiment(startTime=0.0)
        s.enterInitializationMode()
    s.exitInitializationMode()
    s.doStep(currentCommunicationPoint=0.0, communicationStepSize=0.1)
    vr = {v.name: v.valueReference for v in md.modelVariables}
    k = (s.getFloat64 if cls is FMU3Slave else s.getReal)([vr["k"], vr["k1"]])
    s.terminate()
    s.freeInstance()
    return k


def main(fmi2, fmi3, output):
    lines = []
    for cls, fmu, d in [(FMU2RawUriSlave, fmi2, "fmi2 x+y%41"), (FMU3Slave, fmi3, "fmi3 x+y%41")]:
        try:
            lines.append("%s: k = %g, k1 = %g" % ((d,) + tuple(run(cls, fmu, d))))
        except Exception as e:
            lines.append("%s: %s" % (d, e))
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2], sys.argv[3])
