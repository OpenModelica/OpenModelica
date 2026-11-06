"""Write the status of fmi3ExitInitializationMode and of the fmi3DoStep after it.

usage: fmi3_cs_exitinit_assert.py <fmu> <output_txt>
"""
import sys

from fmpy import extract, read_model_description
from fmpy.fmi3 import FMU3Slave

NAMES = ["fmi3OK", "fmi3Warning", "fmi3Discard", "fmi3Error", "fmi3Fatal"]


def status(call, *args, **kw):
    try:
        call(*args, **kw)
        return NAMES[0]
    except Exception as e:
        return NAMES[e.status] if isinstance(getattr(e, "status", None), int) else type(e).__name__


def main(fmu, output):
    md = read_model_description(fmu)
    s = FMU3Slave(guid=md.instantiationToken, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    s.instantiate()
    s.enterInitializationMode(startTime=0.0)
    lines = ["fmi3ExitInitializationMode: " + status(s.exitInitializationMode),
             "fmi3DoStep: " + status(s.doStep, currentCommunicationPoint=0.0, communicationStepSize=0.1)]
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
