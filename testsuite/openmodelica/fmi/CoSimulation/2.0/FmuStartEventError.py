"""Write the status of fmi2ExitInitializationMode and of the fmi2DoStep after it.
usage: FmuStartEventError.py <fmu> <output_txt>
"""
import sys
from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Slave
NAMES = ["fmi2OK", "fmi2Warning", "fmi2Discard", "fmi2Error", "fmi2Fatal", "fmi2Pending"]
def status(call, *args, **kw):
    try:
        res = call(*args, **kw)
        return NAMES[res if isinstance(res, int) else 0]
    except Exception as e:
        return NAMES[e.status] if isinstance(getattr(e, "status", None), int) else type(e).__name__
def main(fmu, output):
    md = read_model_description(fmu)
    s = FMU2Slave(guid=md.guid, unzipDirectory=extract(fmu),
                  modelIdentifier=md.coSimulation.modelIdentifier, instanceName="instance")
    s.instantiate()
    s.setupExperiment(startTime=0.0)
    s.enterInitializationMode()
    lines = ["fmi2ExitInitializationMode: " + status(s.exitInitializationMode),
             "fmi2DoStep: " + status(s.doStep, currentCommunicationPoint=0.0, communicationStepSize=0.1)]
    with open(output, "w") as f:
        f.write("\n".join(lines) + "\n")
if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2])
