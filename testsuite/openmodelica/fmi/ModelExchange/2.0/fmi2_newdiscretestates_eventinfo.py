"""Call fmi2NewDiscreteStates after the initialization with an fmi2EventInfo
that holds old values, and write the fields that the FMU returns.
usage: fmi2_newdiscretestates_eventinfo.py <output_txt> <fmu>...
"""
import sys
from ctypes import byref

from fmpy import extract, read_model_description
from fmpy.fmi2 import FMU2Model, fmi2EventInfo, fmi2False, fmi2True


def event_iteration(fmu):
    md = read_model_description(fmu)
    m = FMU2Model(guid=md.guid, unzipDirectory=extract(fmu), instanceName="i",
                  modelIdentifier=md.modelExchange.modelIdentifier)
    m.instantiate()
    m.setupExperiment(startTime=0.0)
    m.enterInitializationMode()
    m.exitInitializationMode()
    lines = []
    while True:
        ei = fmi2EventInfo(fmi2True, fmi2True, fmi2True, fmi2True, fmi2True, 0.5)
        m.fmi2NewDiscreteStates(m.component, byref(ei))
        lines.append("nominalsChanged=%d valuesChanged=%d terminate=%d nextEventTimeDefined=%d%s" % (
            ei.nominalsOfContinuousStatesChanged, ei.valuesOfContinuousStatesChanged,
            ei.terminateSimulation, ei.nextEventTimeDefined,
            " nextEventTime=%g" % ei.nextEventTime if ei.nextEventTimeDefined else ""))
        if ei.newDiscreteStatesNeeded == fmi2False or len(lines) == 10:
            break
    m.terminate()
    m.freeInstance()
    return lines


def main(output, fmus):
    with open(output, "w") as out:
        for fmu in fmus:
            out.write(fmu + "\n")
            for line in event_iteration(fmu):
                out.write("  " + line + "\n")


if __name__ == "__main__":
    main(sys.argv[1], sys.argv[2:])
